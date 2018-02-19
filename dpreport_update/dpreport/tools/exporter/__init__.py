import os
import re
import logging
import csv
import collections as col
from tools import parser
from math import ceil as math_ceil

NCF_HEADERS = ['reftime', 'day', 'timeofday', 'weekday']
logger = logging.getLogger(__name__)

# Sets filename uniformly for all export types
def get_filename(study, subject, data_type, day_from, day_to, extension):
    if extension == 'png':
        postfix = 'DPImage'
        time_unit = 'day'
    elif extension == 'html':
        postfix = 'DPReport'
        time_unit = 'day'
    else:
        postfix = 'UNDEFINED'
        time_unit = 'day'

    return study + '_' + subject + '_' + data_type + postfix + '_' + time_unit + str(day_from) + 'to' + str(day_to) + '.' + extension

def export_html(file_path, html_string):
    try:
        with open(file_path, 'wb') as html_file:
            logger.info('Writing {FILE}'.format(FILE=file_path))
            html_file.write(html_string)
    except Exception as e:
        logger.error(e)

    return

def verify_processed_file(file_name, study, subject, datatype, extension):
    FILE_REGEX = re.compile(r'^(?P<study>\w+)_(?P<subject>\w+)_(?P<datatype>\w+)_day(?P<day_from>[0-9]+)to(?P<day_to>[0-9]+)\.(?P<extension>\w+)$')
    match = FILE_REGEX.match(file_name)
    if not match:
        return None
    elif match.group('subject') != subject:
        return None
    elif match.group('extension') != extension:
        return None
    elif match.group('datatype') != datatype:
        return None
    elif match.group('study') != study:
        return None
    else:
        return match

def verify_gplot_data(file_name, study, subject, datatype, extension, variable):
    FILE_REGEX = re.compile(r'^(?P<study>\w+)_(?P<subject>\w+)_(?P<datatype>\w+)_day(?P<day_from>[0-9]+)to(?P<day_to>[0-9]+)\.(?P<extension>\w+)\.(?P<variable>\w+)\.(?P<part>[0-9]+)$')
    match = FILE_REGEX.match(file_name)
    if not match:
        return None
    elif match.group('subject') != subject:
        return None
    elif match.group('variable') != variable:
        return None
    elif match.group('extension') != extension:
        return None
    elif match.group('datatype') != datatype:
        return None
    elif match.group('study') != study:
        return None
    else:
        return match

def verify_gplot_img(file_name, study, subject, variable, extension):
    FILE_REGEX = re.compile(r'^(?P<study>\w+)_(?P<subject>\w+)_(?P<datatype>\w+)_day(?P<day_from>[0-9]+)to(?P<day_to>[0-9]+)\.(?P<variable>\w+)\.(?P<part>[0-9]+)*')
    match = FILE_REGEX.match(file_name)
    if not match:
        return None
    elif match.group('subject') != subject:
        return None
    elif match.group('variable') != variable:
        return None
    elif not file_name.endswith(extension):
        return None
    elif match.group('study') != study:
        return None
    else:
        return match

def get_file_prefix(study, subject, data_type):
    file_name = '{STUDY}_{SUBJECT}_{DATA_TYPE}_day'.format(STUDY=study, SUBJECT=subject, DATA_TYPE=data_type)
    return file_name

# Do not use NCF headers
def export_gplot_csv(data, variable, file_name, write_path, columns, file_suffix):
    try:
        columns = remove_ncf_headers(columns)
        segment_files_100days(data, write_path, file_name, file_suffix, columns)
        return 0
    except Exception as e:
        logger.error(e)
        return 1

def remove_ncf_headers(columns):
    for item in NCF_HEADERS:
        if item in columns:
            columns.remove(item)

    return columns

# The dataframe will be divided into chunks, and exported
def segment_files_100days(df, write_path, file_name, file_suffix, columns):
    last_day = df['day'].max()
    num_segments = int(math_ceil(last_day / 100))

    for x in range(0, num_segments + 1):
        day_from = x * 100 + 1
        day_to = x * 100 + 100

        file_path = os.path.join(write_path, file_name + '.' + str(file_suffix) + '.' + str(x))
        logger.info('Writing {FILE}'.format(FILE=file_path))
        filtered_df = df[(df['day'] <= day_to) & (df['day'] >= day_from)]
        filtered_df.sort_values(['day']).to_csv(path_or_buf=file_path,index=False,columns=columns,na_rep="NaN")

# Pandas DataFrame csv export
def export_csv_pandas(data, data_type, write_path, study, subject, day_from, day_to, headers):
    csv_headers = list(NCF_HEADERS)
    for item in headers:
        if item not in csv_headers:
            csv_headers.append(item)

    try:
        file_suffix = '{DAY_FROM}to{DAY_TO}.csv'.format(DAY_FROM=day_from, DAY_TO=day_to)
        file_prefix = get_file_prefix(study, subject, data_type)
        file_name = file_prefix + file_suffix
        file_path = os.path.join(write_path, file_name)
        logger.info('Writing {FILE}'.format(FILE=file_path))
        data.to_csv(path_or_buf=file_path,index=False,columns=csv_headers)
        return 0
    except Exception as e:
        logger.error(e)
        return 1

# Generic csv export
def export_csv(data, data_type, write_path, study, subject):
    headers = list(set().union(*(d.keys() for d in data)))
    csv_headers = list(NCF_HEADERS)
    for item in headers:
        if item not in csv_headers:
            csv_headers.append(item)

    try:
        day_from = data[0]['day']
        day_to = data[-1]['day']
        file_suffix = '{DAY_FROM}to{DAY_TO}.csv'.format(DAY_FROM=day_from, DAY_TO=day_to)
        file_prefix = get_file_prefix(study, subject, data_type)
        file_name = file_prefix + file_suffix
        file_path = os.path.join(write_path, file_name)

        with open(file_path, 'wb') as csvfile:
            logger.info('Writing {FILE}'.format(FILE=file_path))
            csvwriter = csv.DictWriter(csvfile, fieldnames=csv_headers)
            csvwriter.writeheader()

            for item in data:
                csvwriter.writerow(item)

        return 0
    except Exception as e:
        logger.error(e)
        return 1

