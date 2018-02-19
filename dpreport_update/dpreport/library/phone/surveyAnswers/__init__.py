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
EXPORT_FILE_PREFIX_HOURLY = 'DpreportSurveyanswersHourly'
EXPORT_FILE_PREFIX_DAILY = 'DpreportSurveyanswersDaily'
VALUES_RANGE = {
    'surveyAnswers' : {
        'min' : 0,
        'max' : 4
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
    return datetime.strptime(datetime_string, '%Y-%m-%d %H_%M_%S').replace(tzinfo=tz.gettz(FILE_TIMEZONE)).astimezone(tz.gettz(timezone))

def parse(file_path, date_from, timezone, passphrase):
    for row in parser.read_csv(file_path):
        # surveyTimings is unreliable, so we'll extract the datetime from its filename
        file_date = re.search('(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2})\s(?P<hour>[0-9]{2})_(?P<minute>[0-9]{2})_(?P<second>[0-9]{2})', file_path)
        date_to_datetime = file_date.group(0)
        date_to = process_datetime(date_to_datetime, timezone)

        parsed_items = col.defaultdict()
        parsed_items['day'] = process_date(date_from, date_to)
        parsed_items['hour'] = process_time(date_to)
        parsed_items['weekday'] = process_weekday(date_to)

        # Left here to allow filtering the question type
        # question_type = row['question type'].strip()

        key = row['question text'].strip()
        parsed_items['question'] = key

        row_answer = row['answer']
        if str(row['question answer options']) == 'nan' and str(row_answer) == 'nan':
            parsed_items['answer'] = ''
        elif type(row_answer) is not int and type(row_answer) is not float:
            row_answer = row_answer.strip()

            options_text = row['question answer options'][1:-1]
            options = [ x.strip() for x in options_text.split(';') ]
            options = process_surveyOptions(options)

            # Ensures the answer option starts with an uppercase
            value = row_answer[0].upper() + row_answer[1:]

            if value in ['NOT_PRESENTED','NO_ANSWER_SELECTED']:
                parsed_items['answer'] = ''
            elif value in options:
                parsed_items['answer'] = options.index(value)
            else:
                parsed_items['answer'] = value
        else:
            parsed_items['answer'] = row_answer

        yield parsed_items

def process_surveyOptions(options):
    if options[0] == 'NA' or options[0] == 'N/A':
        options[0:2] = ['; '.join(options[0:2])]

    index = 0
    while index < len(options):
        if index == 0:
            index += 1
            continue

        # Handles weird cases where the first character of the option is not an upper case
        if options[index].strip()[0:2] == 'or' and index < len(options) - 1:
            options[index + 1] = options[index + 1].strip()[0].upper() + options[index + 1].strip()[1:]

        if options[index].strip()[0].islower():
            options[index - 1: index + 1] = ['; '.join(options[index - 1: index + 1])]
            index -= 1
        else:
            index += 1

    return options

def generate_gplot_data(processed_path, study, subject, frequency):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY
    if frequency == 'daily':
        gplot.gplot_data_daily(study, subject, processed_path, data_type, None, 'surveyAnswers')
    else:
        gplot.gplot_data_hourly(study, subject, processed_path, data_type, None, 'surveyAnswers')

# Gplot
def plot_gplot(processed_path, study, subject, frequency):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY

    for variable in ['surveyAnswers']:
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
    if data is None or len(data) == 0:
        return
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY
    data = put_timeofday(data)
    day_from = data['day'].min()
    day_to = data['day'].max()
    return exporter.export_csv_pandas(data, data_type, write_path, study, subject, day_from, day_to, headers)

def get_hourly_data(df):
    return None

def get_hourly_headers(df):
    return None

def put_timeofday(df):
    if df is None:
        return None
    else:
        df.reset_index(inplace=True)
        df['timeofday'] = df['hour'].apply(lambda row: parser.get_timeofday_from_hour(row))
        return df

def get_daily_data(df):
    df = df.sort_values(['day', 'weekday', 'hour'])
    return df.pivot_table(index=['day','weekday','hour'],columns='question',values='answer',aggfunc='first', fill_value='')

def get_daily_headers(df):
    return df.columns.tolist()

def process(data_array):
    return parser.list_to_df(data_array)

def process_date(date_from, date_to):
    date_from = date_from.date()
    date_to = date_to.date()

    # The consent date should count as 1, not 0
    day = parser.diff_date(date_from, date_to) + 1
    return day

# Get day of week
def process_weekday(datetime_object):
    return parser.get_weekday(datetime_object)

# Get the hour information for the time column
def process_time(datetime_object):
    return parser.get_hour(datetime_object)
