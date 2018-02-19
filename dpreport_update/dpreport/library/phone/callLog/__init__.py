import os
import re
import logging
from datetime import datetime
from dateutil import tz
import collections as col
from operator import itemgetter

import math
from tools import parser, scanner, exporter
from graphic import gplot

logger = logging.getLogger(__name__)

FILE_TIMEZONE = 'UTC'
FILE_REGEX = re.compile(r'(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2})\s(?P<hour>[0-9]{2})_(?P<minute>[0-9]{2})_(?P<second>[0-9]{2})(?P<extension>\..*)')
EXPORT_FILE_PREFIX_DAILY = 'DpreportCalllogDaily'
EXPORT_FILE_PREFIX_HOURLY = 'DpreportCalllogHourly'
VARIABLES = {
    'duration in seconds' : 'Totalduration'
}
VALUES_TO_PLOT = ['Totalduration']
VALUES_RANGE = {
    'Totalduration' : {
        'min' : 0,
        'max' : 300
    }
}

# Verify the file based on its filename
def verify(file_name, subject):
    match = FILE_REGEX.match(file_name)

    if match and match.group('extension') == '.csv':
        return match
    else:
        return None

def process_datetime(datetime_string, timezone):
    return datetime.strptime(datetime_string, '%Y-%m-%dT%H:%M:%S.%f').replace(tzinfo=tz.gettz(FILE_TIMEZONE)).astimezone(tz.gettz(timezone))

def parse(file_path, date_from, timezone, passphrase):
    for row in parser.read_csv(file_path):
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
    return parser.list_to_df(data_array)

def get_hourly_data(df):
    hourly_data = df.groupby(['day', 'weekday', 'hour'], as_index=False).sum()
    return hourly_data

def get_daily_data(df):
    daily_data = df.groupby(['day', 'weekday'], as_index=False).sum()
    return daily_data

def get_hourly_headers(df):
    return VALUES_TO_PLOT

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
