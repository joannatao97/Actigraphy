import os
import logging
import collections as col

from tools import scanner, parser

logger = logging.getLogger(__name__)

def process(study, subject, data_type, data_path, date_from, timezone, write_path, passphrase):
    raw_dir = os.path.join(data_path, 'raw')
    
    # Get all beiwe ids from the raw directory
    beiwe_ids = scanner.scan_dir(raw_dir)
    beiwe_data_types = set()

    # Get beiwe data types available for the subject
    for beiwe_id in beiwe_ids:
        beiwe_dir = os.path.join(raw_dir, beiwe_id)
        sub_types = scanner.scan_dir(beiwe_dir) # Or get the list from user input
        for sub_type in sub_types:
            beiwe_data_types.add(sub_type)

    # This loop will aggregate data from all beiwe ids
    for beiwe_data_type in sorted(beiwe_data_types):
        # Get the module for the beiwe data type
        mod = scanner.scan_library_module(data_type, beiwe_data_type)
        if mod is None:
            continue

        data_array = []

        for beiwe_id in beiwe_ids:
            logger.info('Processing {BEIWE_DT} for beiwe id {BEIWE}'.format(BEIWE=beiwe_id, BEIWE_DT=beiwe_data_type))    
            beiwe_data_dir = os.path.join(raw_dir, beiwe_id, beiwe_data_type)

            for root_dir, dirs, files in os.walk(beiwe_data_dir):
                # Exclude hidden files and directories
                files = [f for f in files if not f[0] == '.']
                dirs[:] = [d for d in dirs if not d[0] == '.']

                for file_name in sorted(files):
                    matched_file = mod.verify(file_name, subject)
                    if matched_file is not None:
                        file_path = os.path.join(root_dir, file_name)
                        logger.info('Valid file found. Parsing {FILE}'.format(FILE=file_path))
                        
                        for line in mod.parse(file_path, date_from, timezone, passphrase):
                            data_array.append(line)
                    else:
                        logger.warn('{FILE} is not a valid file. Skipping this one.'.format(FILE=file_name))

        if len(data_array) == 0:
            logger.error('Data not found.')
            continue

        logger.info('Data parsing complete for the subject {SUBJECT}'.format(SUBJECT=subject))

        logger.info('Final data processing')
        processed_data = mod.process(data_array)

        logger.info('Exporting the data')
        hourly_data = mod.get_hourly_data(processed_data)
        hourly_headers = mod.get_hourly_headers(hourly_data)
        hourly_data = mod.put_timeofday(hourly_data)
        mod.export_csv(hourly_data, write_path, study, subject, 'hourly', hourly_headers)

        daily_data = mod.get_daily_data(processed_data)
        daily_headers = mod.get_daily_headers(daily_data)
        mod.export_csv(daily_data, write_path, study, subject, 'daily', daily_headers)


def run_gplot(write_path, study, subject, data_path, data_type):
    raw_dir = os.path.join(data_path, 'raw')

    # Get all beiwe ids from the raw directory
    beiwe_ids = scanner.scan_dir(raw_dir)
    beiwe_data_types = set()

    # Get beiwe data types available for the subject
    for beiwe_id in beiwe_ids:
        beiwe_dir = os.path.join(raw_dir, beiwe_id)
        sub_types = scanner.scan_dir(beiwe_dir) # Or get the list from user input
        for sub_type in sub_types:
            beiwe_data_types.add(sub_type)

    # This loop will aggregate data from all beiwe ids
    for beiwe_data_type in sorted(beiwe_data_types):
        # Get the module for the beiwe data type
        mod = scanner.scan_library_module(data_type, beiwe_data_type)
        if mod is None:
            continue

        mod.generate_gplot_data(write_path, study, subject, 'hourly')
        mod.plot_gplot(write_path, study, subject, 'hourly')
        mod.generate_gplot_data(write_path, study, subject, 'daily')
        mod.plot_gplot(write_path, study, subject, 'daily')
