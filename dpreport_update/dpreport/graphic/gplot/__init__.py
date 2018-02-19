import os
import sys
import logging
import subprocess as sp

from tools import exporter, reader, parser

logger = logging.getLogger(__name__)

# Converts NCF-standard files to gplot-compatible files
# Expects variable to be a string
def gplot_data_hourly(study, subject, read_path, file_prefix, variable, file_suffix):
    logger.info('Converting hourly data to gplot-compatible files')
    if type(variable) != str:
        logger.error('Variable name must be a string.')
        return
    for root_dir, dirs, files in os.walk(read_path):
        files = [f for f in files if not f[0] == '.']
        dirs[:] = [d for d in dirs if not d[0] == '.']

        for file_name in sorted(files):
            match = exporter.verify_processed_file(file_name, study, subject, file_prefix, 'csv')
            if match:
                file_path = os.path.join(root_dir, file_name)
                logger.info('Found a matching file {FILE}. Processing.'.format(FILE=file_path))
                variable_data = reader.read_csv_column_values(file_path, variable)
                variable_data = variable_data.pivot_table(index=['day','weekday'],
                                                        columns='timeofday',
                                                        values=variable,
                                                        aggfunc='first', 
                                                        fill_value='')
                variable_data = sanitize_dataframe_hourly(variable_data)
                columns = fill_missing_hours(variable_data)
                exporter.export_gplot_csv(variable_data, variable, file_name, read_path, columns, file_suffix)

# Converts NCF-standard files to gplot-compatible files
# Expects variable to be a string
# If variable is None object, then imports everything
def gplot_data_daily(study, subject, read_path, file_prefix, variable, file_suffix):
    logger.info('Converting daily data to gplot-compatible files')
    if type(variable) != str and variable is not None:
        logger.error('Variable name must be a string.')
        return
    for root_dir, dirs, files in os.walk(read_path):
        files = [f for f in files if not f[0] == '.']
        dirs[:] = [d for d in dirs if not d[0] == '.']

        for file_name in sorted(files):
            match = exporter.verify_processed_file(file_name, study, subject, file_prefix, 'csv')
            if match:
                file_path = os.path.join(root_dir, file_name)
                logger.info('Found a matching file {FILE}. Processing.'.format(FILE=file_path))
                variable_data = reader.read_csv_column_values(file_path, variable)
                variable_data = sanitize_dataframe_daily(variable_data)
                columns = variable_data.columns.tolist()
                exporter.export_gplot_csv(variable_data, variable, file_name, read_path, columns, file_suffix)

# gplot the values for each day
def gplot_daily(study, subject, read_path, file_prefix, variable, file_suffix, min_value, max_value):
    logger.info('Plotting daily gplot for {VAR}'.format(VAR=file_suffix))
    if type(variable) != str and variable is not None:
        logger.error('Variable name must be a string.')
        return

    gplot_path = get_gplot()
    pcut_dir = get_pcut_dir()
    if not gplot_path or not pcut_dir:
        return

    for root_dir, dirs, files in os.walk(read_path):
        files = [f for f in files if not f[0] == '.']
        dirs[:] = [d for d in dirs if not d[0] == '.']

        for file_name in sorted(files):
            match = exporter.verify_gplot_data(file_name, study, subject, file_prefix, 'csv', file_suffix)
            if match:
                file_path = os.path.join(root_dir, file_name)
                logger.info('Found a matching file {FILE}. Processing.'.format(FILE=file_path))
                run_gplot(gplot_path, file_path, min_value, max_value, match.group('variable'), pcut_dir)

def get_pcut_dir():
    lib_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
    return os.path.join(lib_dir, 'graphic', 'gplot')

# gplot for each hour for each day
def gplot_hourly(study, subject, read_path, file_prefix, variable, file_suffix, min_value, max_value):
    logger.info('Plotting hourly gplot for {VAR}'.format(VAR=file_suffix))
    if type(variable) != str:
        logger.error('Variable name must be a string.')
        return

    gplot_path = get_gplot()
    pcut_dir = get_pcut_dir()
    if not gplot_path or not pcut_dir:
        return

    for root_dir, dirs, files in os.walk(read_path):
        files = [f for f in files if not f[0] == '.']
        dirs[:] = [d for d in dirs if not d[0] == '.']

        for file_name in sorted(files):
            match = exporter.verify_gplot_data(file_name, study, subject, file_prefix, 'csv', file_suffix)
            if match:
                file_path = os.path.join(root_dir, file_name)
                logger.info('Found a matching file {FILE}. Processing.'.format(FILE=file_path))
                run_gplot(gplot_path, file_path, min_value, max_value, match.group('variable'), pcut_dir)

def get_gplot():
    # Finding the gplot script file
    lib_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
    gplot_path = os.path.join(lib_dir, 'graphic', 'gplot', 'gplot.sh')

    if os.path.isfile(gplot_path):
        return gplot_path
    else:
        logger.error('Gplot script not found.')
        return None

def run_gplot(gplot_path, file_path, min_value, max_value, variable, pcut_dir):
    try:
        min_value = str(min_value)
        max_value = str(max_value)
        print 'gplot path {0}'.format(gplot_path)
        print 'file path {0}'.format(file_path)
        cmd = [gplot_path, file_path, min_value, max_value, '', pcut_dir]
        print 'cmd {0}'.format(cmd)
        sp.check_call(cmd, stderr=sp.PIPE, stdout=sp.PIPE)
        logger.info('gplot complete. removing {FILE}'.format(FILE=file_path))
        os.remove(file_path)
    except Exception as e:
        logger.error(e)
        return None

def sanitize_dataframe_hourly(df):
    df.reset_index(inplace=True)
    df = remove_duplicate_day(df)
    df = fill_missing_days(df)
    return df.sort_values(['day'])

def fill_missing_hours(df):
    columns = df.columns.tolist()

    all_hours = range(0,24)
    all_hours = [parser.get_timeofday_from_hour(hour) for hour in all_hours]

    for timestamp in all_hours:
        if not timestamp in columns:
            columns.append(timestamp)

    return sorted(columns)

def sanitize_dataframe_daily(df):
    df = remove_duplicate_day(df)
    df = fill_missing_days(df)
    return df.sort_values(['day'])

# Force-fill-in the rest of the 100 day period
def fill_missing_days(df):
    day_to = df['day'].max()
    if day_to % 100 > 0:
        day_to = day_to - (day_to % 100) + 99

    filled_df = parser.get_df({'day': range(1, day_to + 1)})
    new_df = parser.merge(filled_df, df, 'day', 'left')
    return new_df

# If there are more than one entry for each day, this function will remove everything but the last entry of the day
def remove_duplicate_day(df):
    return df.drop_duplicates(subset='day', keep='last')
