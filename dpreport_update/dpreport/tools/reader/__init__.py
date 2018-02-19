import os
import logging
import pandas
import csv

logger = logging.getLogger(__name__)
NCF_HEADERS = ['reftime', 'day', 'timeofday', 'weekday']

def read_file(file_path):
    try:
        with open(file_path) as f:
            return f.read()
    except Exception as e:
        logger.error(e)
        return None

def read_csv_column_values(file_path, columns):
    if columns is not None:
        headers = list(NCF_HEADERS)
        columns = [columns]
        for item in columns:
            if item not in headers:
                headers.append(item)

    try:
        data = []
        if columns is None:
            df = pandas.read_csv(file_path, memory_map=True, engine='c', skipinitialspace=True, na_values='')
        else:
            df = pandas.read_csv(file_path, memory_map=True, engine='c', skipinitialspace=True, usecols=headers, na_values='')
        return df
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
def read_csv(file_obj, skip_rows):
    if hasattr(file_obj, 'read') or os.path.isfile(file_obj):
        try:
            df = pandas.read_csv(file_obj, memory_map=True, engine='c', skipinitialspace=True, skiprows=skip_rows)
            for row in df.to_dict(orient='records'):
                yield row
        except Exception as e:
            logger.error(e)

def read_csv_with_headers(file_obj, skip_rows, headers):
    if hasattr(file_obj, 'read') or os.path.isfile(file_obj):
        try:
            df = pandas.read_csv(file_obj, memory_map=True, engine='c', skipinitialspace=True, skiprows=skip_rows, names=headers)
            for row in df.to_dict(orient='records'):
                yield row
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
