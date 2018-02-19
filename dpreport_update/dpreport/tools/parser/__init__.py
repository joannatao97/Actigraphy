import os
import re
from io import StringIO
import logging
import pandas
import csv
from datetime import datetime
from dateutil import tz

logger = logging.getLogger(__name__)

def read_file(file_path):
    try:
        with open(file_path) as f:
            return f.read()
    except Exception as e:
        logger.error(e)
        return None

# Read in the file from the path, and yield each row as a list of values
def read_csv_list(file_path):
    try:
        df = pandas.read_csv(file_path, memory_map=True, engine='c', skipinitialspace=True)
        for index, row in enumerate(df.values.tolist()):
            yield index, row
 
    except Exception as e:
        logger.error(e)

def read_csv_vanilla(file_path):
    try:
        with open(file_path, 'rb') as csvfile:
            csvreader = csv.DictReader(csvfile)
            for row in csvreader:
                yield row
    except Exception as e:
        logger.error(e)

# Read in the file from the file path, and yield each row as a list of dictionary
def read_csv(file_path):
    try:
        df = pandas.read_csv(file_path, memory_map=True, engine='c', skipinitialspace=True)
        for row in df.to_dict(orient='records'):
            yield row

    except Exception as e:
        logger.error(e)

# Read in the file from the file path, and yield each row as a list of dictionary
def csv_to_df(file_obj, skip_rows, headers):
    if hasattr(file_obj, 'read') or os.path.isfile(file_obj):
        try:
            if headers == 'infer':
                df = pandas.read_csv(file_obj, memory_map=True, engine='c', skipinitialspace=True, skiprows=skip_rows)
                return df
            else:
                df = pandas.read_csv(file_obj, memory_map=True, engine='c',names = headers, skipinitialspace=True, skiprows=skip_rows)
                return df
        except Exception as e:
            logger.error(e)

# Read the csv header template file, and return the headers in an array.
def read_csv_header(file_path):
    try:
        df = pandas.read_csv(file_path, memory_map=True, keep_default_na=False, engine='c', header = None, skipinitialspace=True)
        return df.values[0].tolist()
    except Exception as e:
        logger.error(e)
        return None

def parse_measurement_info(measurement_value):
    MEASUREMENT = re.compile(r'^(?P<data_type>\w+).(?P<sub_type>\w+).(?P<variable>\w+)$')
    match = MEASUREMENT.match(measurement_value)
    if match:
        return match
    else:
        logger.error('MEASUREMENT_INFO is not written in the right format.')
        return None

def get_df(dataframe_obj):
    return pandas.DataFrame(dataframe_obj)

def merge(left_df, right_df, on, how):
    return pandas.merge(left_df, right_df, on=on, how=how)

# Gets the list of dictionaries, and returns a dataframe
def list_to_df(data_array):
    return pandas.DataFrame.from_records(data_array)

def pivot(df, index, column, value):
    return df.pivot(index=index, columns=column, values=value)

def transpose_dataframe(dataframe):
    return pandas.DataFrame(dataframe).T.values.tolist()

def join_dataframes(old_list, new_list):
    d1 = pandas.DataFrame(old_list).fillna('')
    d2 = pandas.DataFrame(new_list).fillna('')

    if len(old_list) == 0:
        return d2
    else:
        return pandas.concat([d1, d2]).drop_duplicates().fillna('')

# Convert a comma-separated-string object to pandas csv dataframe
def string_to_dataframe(string_object):
    try:
        data_buffer = StringIO(unicode(string_object))
        df = pandas.read_csv(data_buffer, keep_default_na=False, engine='c', skipinitialspace=True)
        for row in df.to_dict(orient='records'):
            yield row
    except Exception as e:
        logger.error(e)

# Parse the list of dictionary objects, and get the mode value from the column specified.
def get_mode_from_list(data, column):
    df = pandas.DataFrame(data)
    if column in df:
        return df[column].mode()[0]
    else:
        return None

# Add hour by 1
def add_hour(day, hour):
    if hour == 23:
        day += 1
        hour = 0
    else:
        hour += 1

    return day,hour

# Add weekday by 1 until it reaches 7
def add_weekday(weekday):
    if weekday == 6:
        return 0
    else:
        return weekday + 1

# Extract the hour information in 24hr format from a datetime object
def get_hour(datetime_object):
    return datetime_object.hour

# Get the number of days between two datetime objects
def diff_date(date_from, date_to):
    date_to = date_to
    date_from = date_from

    return (date_to - date_from).days

# NCF-standard timeofday variable
def get_timeofday(datetime_object):
    hour = str(datetime_object.hour) if datetime_object.hour > 9 else '0' + str(datetime_object.hour)
    minute = str(datetime_object.minute) if datetime_object.minute > 9 else '0' + str(datetime_object.minute)
    second = str(datetime_object.second) if datetime_object.second > 9 else '0' + str(datetime_object.second)

    return hour + ':' + minute + ':' + second

def get_timeofday_from_hour(hour):
    return str(hour) + ':00:00' if hour > 9 else '0' + str(hour) + ':00:00'

# Return weekday
# Monday is 0
def get_weekday(datetime_object):
    return datetime_object.weekday()

def get_days_until_sunday(weekday):
    return 7 - weekday

# Get the number of 'NaN' values
def calculate_nan(csv_file, day_from, day_to, time_unit):
    num_nan = 0
    day_from = int(day_from)
    day_to = int(day_to)
    try:
        df = pandas.read_csv(csv_file, memory_map=True, engine='c', keep_default_na=False, skipinitialspace=True)
        headers = df.columns.get_values().tolist()
        custom_headers = [x for x in headers if x not in ['reftime', 'day', 'weekday', 'timeofday']]
        for index, value in enumerate(df.to_dict(orient='records')):
            if value['day'] >= day_from and value['day'] <= day_to:
                for column_index, column_value in value.iteritems():
                    if column_index in ['day', 'weekday', 'timeofday', 'reftime']:
                        continue
                    elif column_value in ['NaN', '']:
                        num_nan += 1
        return num_nan,custom_headers
    except Exception as e:
        logger.error(e)
        return None
