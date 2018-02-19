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

import divide

logger = logging.getLogger(__name__)

FILE_TIMEZONE = 'America/New_York'
FILE_REGEX = re.compile(r'(?P<subject>\w+)_(?P<month>[0-9]+)_(?P<day>[0-9]+)_(?P<year>[0-9]{4})_(?P<hour>[0-9]+)_(?P<minute>[0-9]+)_(?P<second>[0-9]+)_(?P<time_period>\w\w)_New_Analysis(?P<extension>\..*)')
PARSED_FILENAME_PREFIX = 'DPReportPhilipsNewAnalysis'
PARSED_FILE_REGEX = '{subject}_{file_prefix}EpochByEpochData_{timestamp}.csv'
SKIP_TO_DATA_ROW_NUM = 0
FILE_HEADERS = 'infer'

# Variables to extract : alias
VARIABLES = {
    'Activity' : 'activity',
    'White Light' : 'light' 
}

# Verify the file based on its filename
def verify(file_name, subject):
    match = FILE_REGEX.match(file_name)
    if match:
        if match.group('subject') == subject and match.group('extension') == '.csv':
            return match
    else:
        return None

# Establishing the timezone of the watch data as ET
def process_datetime(row_date, row_time, timezone):
    datetime_string = row_date + ' ' + row_time
    return datetime.strptime(datetime_string, '%m/%d/%Y %I:%M:%S %p').replace(tzinfo=tz.gettz(FILE_TIMEZONE)).astimezone(tz.gettz(timezone))

def divide_file(file_path, matched_regex, write_path, timestamp):
    divide.parse(file_path, matched_regex, PARSED_FILENAME_PREFIX, write_path, timestamp)
    return

# Parse the file
def parse(subject, file_path, date_from, timezone, matched_file, write_path):
    # Divide the raw philips into multiple files with one section each
    timestamp = divide.get_timestamp(matched_file)
    divide_file(file_path, matched_file, write_path, timestamp)
    divided_file_dir = write_path

    # Find the epoc by epoc file
    new_file_name = PARSED_FILE_REGEX.format(subject=subject, file_prefix=PARSED_FILENAME_PREFIX, timestamp=timestamp)
    new_file_path = os.path.join(divided_file_dir, new_file_name)

    try:
        with open(new_file_path) as f:
            return process_data(f, date_from, timezone)
    except Exception as e:
        logger.error(e)
        return None

def process_data(file_object, date_from, timezone):
    df = parser.csv_to_df(file_object, SKIP_TO_DATA_ROW_NUM, FILE_HEADERS)
    df['date_to'] = df.apply(lambda row: process_datetime(row['Date'], row['Time'], timezone), axis=1)
    df['day'] = df.apply(lambda row: process_date(date_from, row['date_to']), axis=1)
    df['hour'] = df.apply(lambda row: process_time(row['date_to']), axis=1)
    df['weekday'] = df.apply(lambda row: process_weekday(row['date_to']), axis=1)
    return df.rename(columns=VARIABLES)

def process_visual(data_array, sample_array, csv_file, write_path, study, subject, data_type):
    last_day = data_array[-1]['day']
    # Visual files will be divided into multiple files for each 100 days
    part_num = math.ceil(last_day / 100.0)

    variables = VARIABLES

    # Process hourly report
    part = 1
    while part <= part_num:
        day_to = part * 100
        day_from = (part - 1) * 100 + 1

        full_html_string = ''

        for key, value in variables.iteritems():
            png_filename = exporter.get_filename(study, subject, value, day_from, day_to, 'png')
            png_path = os.path.join(write_path, png_filename)

            png_relative_path = './' + png_filename
            gplot.process(csv_file[value], png_path, 0, 1000, day_from, day_to, data_type)
            png_html = component.render_image(data_type, png_relative_path)

            '''
            png_mean_filename = exporter.get_filename(study, subject, data_type + 'Mean', day_from, day_to, 'png')
            png_mean_path = os.path.join(write_path, png_mean_filename)
            gplot.process(png_mean_path)
            png_mean_html = component.render_image(data_type, png_mean_path)
            '''

            full_png_html = png_html
            full_html_string += component.process(csv_file[value], value, data_type, full_png_html, last_day, day_from, day_to, 'hour')

        html_filename = exporter.get_filename(study, subject, data_type, day_from, day_to, 'html')
        html_path = os.path.join(write_path, html_filename)
        exporter.export_html(html_path, full_html_string)

        part += 1

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
