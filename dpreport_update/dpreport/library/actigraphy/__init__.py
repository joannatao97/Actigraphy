import os
import logging
from operator import itemgetter

from tools import scanner, parser, exporter
from graphic import gplot
from graphic import html as report

logger = logging.getLogger(__name__)

EXPORT_FILE_PREFIX_HOURLY = 'DpreportActigraphyHourly'
EXPORT_FILE_PREFIX_DAILY = 'DpreportActigraphyDaily'
VALUES_TO_PLOT = ['light', 'activity']
VALUES_RANGE = {
    'light' : {
        'min' : 0,
        'max' : 1000
    },
    'activity' : {
        'min' : 0,
        'max' : 250
    }
}

# For speed, this library will read in and parse all data as dataframe
def process(study, subject, data_type, data_path, date_from, timezone, write_path, passphrase):
    raw_dir = os.path.join(data_path, 'raw')

    sub_types = ['ActiWatch2']
    #sub_types = ['ActiWatch2', 'GENEActiv'] # Placeholder until all files are in the right directories

    df = parser.list_to_df([]) #Instantiate an empty dataframe

    # This loop will aggregate data from all actigraphy files
    for sub_type in sorted(sub_types):
        logger.info('Processing {DATATYPE}'.format(DATATYPE=sub_type))

        # Get the module for the actigraphy type
        mod = scanner.scan_library_module(data_type, sub_type)
        if mod is None:
            return

        actigraphy_data_dir = raw_dir

        for root_dir, dirs, files in os.walk(actigraphy_data_dir):
            files = [f for f in files if not f[0] == '.']
            dirs[:] = [d for d in dirs if not d[0] == '.']

            for file_name in sorted(files):

                matched_file = mod.verify(file_name, subject)

                if matched_file is not None:
                    file_path = os.path.join(root_dir, file_name)
                    logger.info('Valid file found. Parsing {FILE}'.format(FILE=file_path))
                    parsed_file_df = mod.parse(subject, file_path, date_from, timezone, matched_file, write_path)
                    df = df.append(parsed_file_df, ignore_index=True)
                else:
                    logger.warn('{FILE} is not a valid file. Skipping this one.'.format(FILE=file_name))

    if len(df) == 0:
        logger.error('Data not found.')
        return

    logger.info('Data parsing complete for the subject {SUBJECT}'.format(SUBJECT=subject))

    logger.info('Final data processing')
    processed_data = final_process(df)

    logger.info('Exporting the data')
    process_hourly(processed_data, study, subject, write_path)
    process_daily(processed_data, study, subject, write_path)

def run_gplot(write_path, study, subject, data_path, data_type):
    generate_gplot_data(write_path, study, subject, 'hourly')
    plot_gplot(write_path, study, subject, 'hourly')
    generate_gplot_data(write_path, study, subject, 'daily')
    plot_gplot(write_path, study, subject, 'daily')

def process_daily(data, study, subject, write_path):
    daily_data = get_daily_data(data)
    daily_headers = get_daily_headers(daily_data)
    export_csv(daily_data, write_path, study, subject, 'daily', daily_headers)

def process_hourly(data, study, subject, write_path):
    hourly_data = get_hourly_data(data)
    hourly_data = put_timeofday(hourly_data)
    hourly_headers = get_hourly_headers(hourly_data)
    export_csv(hourly_data, write_path, study, subject, 'hourly', hourly_headers)

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

#Generate gplot-compatible data
def generate_gplot_data(processed_path, study, subject, frequency):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY
    
    for variable in VALUES_TO_PLOT:
        if frequency == 'daily':
            gplot.gplot_data_daily(study, subject, processed_path, data_type, variable, variable)
        else:
            gplot.gplot_data_hourly(study, subject, processed_path, data_type, variable, variable)

# Sorts data
def final_process(df):
    return df.sort_values(['day', 'hour'])

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

# Export the data as a csv file.
def export_csv(data, write_path, study, subject, frequency, headers):
    data_type = EXPORT_FILE_PREFIX_DAILY if frequency == 'daily' else EXPORT_FILE_PREFIX_HOURLY
    day_from = data['day'].min()
    day_to = data['day'].max()
    return exporter.export_csv_pandas(data, data_type, write_path, study, subject, day_from, day_to, headers)

