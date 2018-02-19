import os
import re
import logging
import math
from datetime import datetime
from dateutil import tz
import collections as col
from operator import itemgetter

from tools import parser, scanner, exporter, decrypter
from graphic import gplot

logger = logging.getLogger(__name__)

FILE_TIMEZONE = 'UTC'
FILE_REGEX = re.compile(r'(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2})\s(?P<hour>[0-9]{2})_(?P<minute>[0-9]{2})_(?P<second>[0-9]{2})(?P<extension>\..*)')
EXPORT_FILE_PREFIX_DAILY = 'DpreportGpsDaily'
EXPORT_FILE_PREFIX_HOURLY = 'DpreportGpsHourly'

VALUES_TO_PLOT = ['dist_from_home']
VALUES_RANGE = {
    'dist_from_home' : {
        'min' : 0,
        'max' : 10
    }
}

# variable : alias_to_use
VARIABLES = {
    'latitude' : 'latitude',
    'longitude': 'longitude'
}

# Verify the file based on its filename
def verify(file_name, subject):
    match = FILE_REGEX.match(file_name)
    
    if match and match.group('extension') == '.csv.lock':
        return match
    else:
        return None

def process_datetime(datetime_string, timezone):
    return datetime.strptime(datetime_string, '%Y-%m-%dT%H:%M:%S.%f').replace(tzinfo=tz.gettz(FILE_TIMEZONE)).astimezone(tz.gettz(timezone))

def parse(file_path, date_from, timezone, passphrase):
    if not passphrase:
        logger.error('This module requires a passphrase. Exiting module')
        return

    file_data = decrypter.unlock(file_path, passphrase)
    if file_data is None:
        logger.error('Could not decrypt file {}'.format(file_path))
        return

    for row in parser.string_to_dataframe(file_data):
        if row['accuracy'] >= 50:
            continue

        date_to_datetime = row['UTC time']
        date_to = process_datetime(date_to_datetime, timezone)

        parsed_items = col.defaultdict()
        parsed_items['day'] = process_date(date_from, date_to)
        parsed_items['hour'] = process_time(date_to)
        parsed_items['weekday'] = process_weekday(date_to)

        for key, alias in VARIABLES.iteritems():
            parsed_items[alias] = row[key]

        yield parsed_items

def generate_gplot_data(processed_path, study, subject, frequency):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY
    for variable in VALUES_TO_PLOT:
        if frequency == 'daily':
            gplot.gplot_data_daily(study, subject, processed_path, data_type, variable, variable)
        else:
            gplot.gplot_data_hourly(study, subject, processed_path, data_type, variable, variable)

# Gplot
def plot_gplot(processed_path, study, subject, frequency):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY

    for variable in VALUES_TO_PLOT:
        if not variable in VALUES_RANGE:
            logger.error('Range not defined for {VAR}. Skipping gplot'.format(VAR=variable))
            continue
        else:
            min_value = VALUES_RANGE[variable]['min']
            max_value = VALUES_RANGE[variable]['max']
        if frequency == 'daily':
            gplot.gplot_daily(study, subject, processed_path, data_type, variable, variable, min_value, max_value)
        else:
            gplot.gplot_hourly(study, subject, processed_path, data_type, variable, variable, min_value, max_value)

# Export the data as a csv file.
def export_csv(data, write_path, study, subject, frequency, headers):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY
    day_from = data['day'].min()
    day_to = data['day'].max()
    return exporter.export_csv_pandas(data, data_type, write_path, study, subject, day_from, day_to, headers)

def process(data_array):
    dataframe_object = parser.list_to_df(data_array).fillna(0)
    new_df = get_home(dataframe_object)    
    new_df['dist_from_home'] = new_df.apply(lambda row: haversine(row['longitude_home'], row['latitude_home'], row['longitude'], row['latitude']), axis=1)

    return new_df

def get_home(df):
    for key, alias in VARIABLES.iteritems():
        df_key = str(key) + '_home'
        df[df_key] = df[key].value_counts().idxmax()

    return df

# Haversine Formula
def haversine(longitude_home, latitude_home, new_longitude, new_latitude):
    lon1 = longitude_home
    lat1 = latitude_home
    lon2 = new_longitude
    lat2 = new_latitude

    # convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(math.radians, [lon1, lat1, lon2, lat2])

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    a = math.sin(dlat / 2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)**2
    c = 2 * math.asin(math.sqrt(a))
    earth_radius = 6371
    
    return c * earth_radius

# Takes in a dataframe object, average values across the hour for each day, and return the dataframe
def get_hourly_data(df):
    hourly_average = df.groupby(['day','weekday','hour'], as_index=False).mean()
    return hourly_average

def get_hourly_headers(df):
    return VALUES_TO_PLOT

# Takes in a dataframe object, average values for each day, and return the dataframe
def get_daily_data(df):
    daily_average = df.groupby(['day', 'weekday'], as_index=False).mean()
    return daily_average

def get_daily_headers(df):
    return VALUES_TO_PLOT

def put_timeofday(df):
    df['timeofday'] = df['hour'].apply(lambda row: parser.get_timeofday_from_hour(row))
    return df

def process_date(date_from, date_to):
    date_from = date_from.date()
    date_to = date_to.date()

    # The consent date should count as 1, not 0
    day = parser.diff_date(date_from, date_to) + 1

    return day

# Get the hour information for the time column
def process_time(datetime_object):
    return parser.get_hour(datetime_object)

# Get day of week
def process_weekday(datetime_object):
    return parser.get_weekday(datetime_object)

# Get the right header for the data type
def get_headers():
    module_path = scanner.get_module_dir()
    header_file = os.path.join(module_path, 'metadata', 'hourheaders.csv')
    headers =  parser.read_csv_header(header_file)
    return headers

