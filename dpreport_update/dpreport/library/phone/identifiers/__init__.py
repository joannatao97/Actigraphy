import os
import re
import logging
from datetime import datetime
from dateutil import tz
import collections as col
from operator import itemgetter

from tools import parser, scanner, exporter

logger = logging.getLogger(__name__)

FILE_TIMEZONE = 'UTC'
FILE_REGEX = re.compile(r'(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2})\s(?P<hour>[0-9]{2})_(?P<minute>[0-9]{2})_(?P<second>[0-9]{2})(?P<extension>\..*)')
EXPORT_FILE_PREFIX = 'DpreportIdentifiers'

VARIABLES = {
    'beiwe_version' : 'beiwe_version',
    'os_version' : 'os_version',
    'device_os' : 'os_name',
    'patient_id' : 'subject_id',
    'manufacturer' : 'device_manufacturer',
    'model' : 'device_model'
}

# Verify the file based on its filename
def verify(file_name, subject):
    match = FILE_REGEX.match(file_name)

    if match and match.group('extension') == '.csv':
        return match
    else:
        return None

def process_datetime(datetime_string, timezone):
    try: 
        return datetime.strptime(datetime_string, '%Y-%m-%dT%H:%M:%S.%f').replace(tzinfo=tz.gettz(FILE_TIMEZONE)).astimezone(tz.gettz(timezone))
    except Exception as e:
        logger.error(e)
        return None

def parse(file_path, date_from, timezone, passphrase):
    for row in parser.read_csv_vanilla(file_path):
        date_to_datetime = row['UTC time']
        date_to = process_datetime(date_to_datetime, timezone)
        
        if date_to is None:
            continue

        parsed_items = col.defaultdict()
        parsed_items['day'] = process_date(date_from, date_to)
        parsed_items['timeofday'] = str(process_time(date_to)) + ':00:00'

        for key, alias in VARIABLES.iteritems():
            if key in row:
                parsed_items[alias] = row[key]

        yield parsed_items

# Export the data as a csv file.
def export_csv(data, write_path, study, subject, requency, headers):
    if data is None or len(data) == 0:
        return
    exporter.export_csv(data, EXPORT_FILE_PREFIX, write_path, study, subject)
    return

def generate_gplot_data(processed_path, study, subject, frequency):
    return

# Gplot
def plot_gplot(processed_path, study, subject, frequency):
    return

def get_hourly_data(data_array):
    return None

def get_hourly_headers(df):
    return None

def put_timeofday(df):
    return None

def get_daily_data(data_array):
    return data_array 

def get_daily_headers(df):
    return []

def process(data_array):
    return data_array

def process_visual(data_array, sample_array, write_path, study, subject, data_type):
    return

def process_date(date_from, date_to):
    date_from = date_from.date()
    date_to = date_to.date()

    # The consent date should count as 1, not 0
    day = parser.diff_date(date_from, date_to) + 1

    return day

def get_file_prefix():
    return 'DpreportIdentifiers'

# Get the hour information for the time column
def process_time(datetime_object):
    return parser.get_hour(datetime_object)

# Get the right header for the data type
def get_headers():
    return []
