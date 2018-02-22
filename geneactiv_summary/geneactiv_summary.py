#!/usr/bin/env python
import os
import argparse as ap
import logging
import re
import collections as col
from dateutil import tz
from datetime import datetime
import csv
import pandas
import glob
from operator import itemgetter
import gzip

logger = logging.getLogger(os.path.basename(__file__))
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

GENEACTIV_FILE_REGEX = re.compile(r'(?P<subject>\w+)_(?P<serialnum>\w+)_(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2})\s(?P<hour>[0-9]{2})-(?P<minute>[0-9]{2})-(?P<second>[0-9]{2}).csv')

def main():
    parser = ap.ArgumentParser('Geneactiv Summary Pipeline')
    # Input and output parameters
    parser.add_argument('--root-dir', default='/eris/sbdp/PHOENIX',
        help='Path to the input directory (default: /eris/sbdp/PHOENIX)')
    parser.add_argument('--output-dir', help='Path to the output directory (optional)')
    parser.add_argument('--default-folder', default='GENERAL')

    # Basic targeting parameters
    parser.add_argument('--day-from', type = int, default = 1, help='(optional; default: 1)')
    parser.add_argument('--day-to', type = int, default = -1, help='(optional)')
    parser.add_argument('--study', nargs='+', help='Study name', default=['FRESH_17'])
    parser.add_argument('--subject', nargs='+', help='Subject ID')
    parser.add_argument('--data-row', type = int, default = 101, help='The first line of the data. default: 101')
    parser.add_argument('--columns', nargs='+', help='An array of column names', default=['timestamp', 'x', 'y', 'z', 'lux', 'button', 'temp', 'vector_magnitudes', 'x_sd', 'y_sd', 'z_sd', 'peak_lux'])
    parser.add_argument('--hand', help='right or left')
    parser.add_argument('--position', help='Position of the watch. Default: wrist', default='wrist')
    parser.add_argument('--timezone-from', default = 'UTC')
    parser.add_argument('--timezone-to', default = 'America/New_York')

    args = parser.parse_args()

    # Scan root directory to find all studies
    default_path = os.path.join(args.root_dir, args.default_folder)
    studies = args.study if args.study else scan_dir(default_path)

    # Loop through directories
    for study in studies:
        study_path = os.path.join(default_path, study)
        subjects = args.subject if args.subject else scan_dir(study_path)

        # Read in metadata file for the study
        logger.info('Reading in metadata file for study {STUDY}'.format(STUDY=study))
        study_metadata_path = os.path.join(study_path, '{STUDY}.csv'.format(STUDY=study))
        consents = []

        # Grab consent date from the metadata
        try:
            with open(study_metadata_path) as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    consents.append(row)
        except Exception as e:
            logger.error(e)
            continue

        if not consents:
            logger.error('Consent information for {STUDY} is not available. Skipping the study.'.format(STUDY=study))
            continue

        for subject in subjects:
            logger.info('Processing {SUBJECT} in {STUDY}'.format(SUBJECT=subject, STUDY=study))
            subject_path = os.path.join(study_path, subject)

            # Check the format of the consent date
            consent_date = ''
            for item in consents:
                if item['Subject ID'] == subject:
                    consent_date = item['Consent']
            if consent_date == '':
                logger.error('The consent date is not available for {SUBJECT} in {STUDY}. Aborting the mission.'.format(SUBJECT=subject, STUDY=study))
                continue
            else:
                try:
                    date_from = datetime.strptime(consent_date, '%Y-%m-%d').replace(tzinfo=tz.gettz(args.timezone_to)).date()
                except Exception as e:
                    logger.error(e)
                    continue

            # Get path to the processed folder to write the output into
            write_path = os.path.join(subject_path, 'actigraphy', 'processed')
            if not os.path.isdir(write_path):
                logger.error('The output directory {DIR} does not exist. Skipping subject {SUBJECT} in {STUDY}.'.format(DIR=write_path, SUBJECT=study, STUDY=study))
                continue 

            read_path = os.path.join(subject_path, 'actigraphy', 'raw')
            data = col.defaultdict()

            for root_dir, dirs, files in os.walk(read_path):
                for name in sorted(files):
                    matched = GENEACTIV_FILE_REGEX.match(name)
                    logger.info('name {0} REGEX match {1}'.format(name, matched)) 
                    if matched and matched.group('subject') in [subject]:
                        assessment_name = 'Geneactiv'
                        if not assessment_name in data:
                            data[assessment_name] = []
                        for row in parse_geneactiv(os.path.join(root_dir, name), args.data_row, date_from, args.timezone_to, args.columns):
                            data[assessment_name].append(dict(row))
                    else:
                        logger.warn('{FILE} is not a geneactiv file or does not belong to the subject {SUBJECT}.'.format(FILE=name, SUBJECT=subject))

            # Check if it has valid data entry
            if not data:
                logger.error('Data not found for {SUBJECT} in {STUDY}.'.format(STUDY=study,SUBJECT=subject))
                continue

            # Get output directory
            output_dir = args.output_dir if args.output_dir else write_path

            for key, value in data.iteritems():
                file_suffix = ''.join(x for x in key.title() if not x.isspace())
                purge_dir(output_dir, subject, file_suffix)
                generate_csv(sorted(value, key=itemgetter('day')), output_dir, subject, file_suffix, args.day_from, args.day_to)

            logger.info('Process complete for {SUBJECT} in {STUDY}'.format(STUDY=study,SUBJECT=subject))

# Generate data in NCF standard format
def generate_csv(data, output_dir, subject, data_type, day_from, day_to):
    result = []
    days = data[-1]['day'] if day_to == -1 else day_to
    day = day_from
    
    index = 0
    while day <= days:
        if (data[index]['day'] < 1):
            logger.warn('Data exists for day(s) before the consent date. Please check the metadata.')
            index += 1

        if (data[index]['day'] == day):
            element = {}
            element['day'] = day
            while(index < len(data) and data[index]['day'] == day):
                for key, value in data[index].iteritems():
                    if key != 'day':
                        if key not in element:
                            element[key] = data[index][key]
                        else:
                            element[key] += data[index][key]
                index += 1
            result.append(element)
        else:
            element = {}
            element['day'] = day
            result.append(element)

        day += 1

    final_data = bin_data(result)

    return export_file(final_data, data_type, output_dir, subject, day_from, days)

def bin_data(data):
    final_data = []

    for row in data:
        data_row = {}
        data_row['day'] = row['day']
        data_row['button'] = row['button'] if 'button' in row else ''
        data_row['lux_0000_0559'] = row['lux_0000_0559'] / row['count_0000_0559'] if 'lux_0000_0559' in row and 'count_0000_0559' in row else ''
        data_row['vector_0000_0559'] = row['vector_0000_0559'] / row['count_0000_0559'] if 'vector_0000_0559' in row and 'count_0000_0559' in row else ''

        data_row['lux_0600_1159'] = row['lux_0600_1159'] / row['count_0600_1159'] if 'lux_0600_1159' in row and 'count_0600_1159' in row else ''
        data_row['vector_0600_1159'] = row['vector_0600_1159'] / row['count_0600_1159'] if 'vector_0600_1159' in row and 'count_0600_1159' in row else ''

        data_row['lux_1200_1759'] = row['lux_1200_1759'] / row['count_1200_1759'] if 'lux_1200_1759' in row and 'count_1200_1759' in row else ''
        data_row['vector_1200_1759'] = row['vector_1200_1759'] / row['count_1200_1759'] if 'vector_1200_1759' in row and 'count_1200_1759' in row else ''

        data_row['lux_1800_2359'] = row['lux_1800_2359'] / row['count_1800_2359'] if 'lux_1800_2359' in row and 'count_1800_2359' in row else ''
        data_row['vector_1800_2359'] = row['vector_1800_2359'] / row['count_1800_2359'] if 'vector_1800_2359' in row and 'count_1800_2359' in row else ''

        final_data.append(dict(data_row))

    return final_data

def export_file(data, data_type, output_dir, subject, day_from, day_to):
    header = ['reftime', 'day', 'timeofday', 'weekday', 'button', 'lux_0000_0559', 'lux_0600_1159', 'lux_1200_1759', 'lux_1800_2359', 'vector_0000_0559', 'vector_0600_1159', 'vector_1200_1759', 'vector_1800_2359']

    output_filename = '{SUBJECT}_{DATA_TYPE}_day{FROM}to{TO}.csv'.format(SUBJECT=subject, DATA_TYPE=data_type, FROM=day_from, TO=day_to)
    try:
        output_file = os.path.join(output_dir, output_filename)
        logger.info('Exporting {FILE}'.format(FILE=output_file))
        with open(output_file, 'wb') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=header)
            writer.writeheader()
            for item in data:
                writer.writerow(item)
    except Exception as e:
        logger.error('export error')
        logger.error(e)
        return


# Remove all previous analysis done by parse.py
def purge_dir(path, subject, data_type):
    if os.path.isdir(path):
        file_pattern = os.path.join(path, '{SUBJECT}_{DATA_TYPE}_day*.csv'.format(SUBJECT=subject, DATA_TYPE=data_type))
        for match in glob.glob(file_pattern):
            os.remove(match)
        old_pattern = os.path.join(path, '{SUBJECT}.Geneactiv'.format(SUBJECT=subject))
        for match in glob.glob(old_pattern):
            os.remove(match)

def parse_geneactiv(file_path, data_row, date_from, timezone_to, columns):
    logger.info('Processing {FILE}'.format(FILE=file_path))

    parsed_row = col.defaultdict()
    parsed_row['day'] = 0

    skip_rows = data_row - 2
    
    try:
        #with gzip.open(file_path, 'rb') as f:
        with open(file_path, 'r') as f:
            tfr = pandas.read_csv(f, memory_map=True, keep_default_na=False, engine='c', chunksize=1, skipinitialspace=True, skiprows=skip_rows, header=None, names=columns)
            for df in tfr:
                for row in df.to_dict(orient='records'):
                    date_to = datetime.strptime(row['timestamp'], '%Y-%m-%d %H:%M:%S:%f').replace(tzinfo=tz.gettz(timezone_to))
                    day = (date_to.date() - date_from).days + 1
                    hour = date_to.hour
    
                    hour_key = get_hour_key(hour)

                    if parsed_row['day'] is not day:
                        if parsed_row['day'] is not 0:
                            yield parsed_row

                        parsed_row['count' + hour_key] = 1
                        parsed_row['day'] = day
                        parsed_row['button'] = 1 if row['button'] > 0 else 0
                    
                        parsed_row['vector' + hour_key] = row['vector_magnitudes']
                        parsed_row['lux' + hour_key] = row['lux']
                    else:
                        if 'count' + hour_key not in parsed_row:
                            parsed_row['count' + hour_key] = 0

                        parsed_row['count' + hour_key] += 1

                        if row['button'] > 0:
                            parsed_row['button'] += 1
                        if 'vector' + hour_key not in parsed_row:
                            parsed_row['vector' + hour_key] = 0
                        if 'lux' + hour_key not in parsed_row:
                            parsed_row['lux' + hour_key] = 0

                        parsed_row['vector' + hour_key] += row['vector_magnitudes']
                        parsed_row['lux' + hour_key] += row['lux']

            yield parsed_row

    except Exception as e:
        logger.error(e)

def get_hour_key(hour):
    if hour >= 0 and hour < 6:
        return '_0000_0559'
    elif hour >= 6 and hour < 12:
        return '_0600_1159'
    elif hour >= 12 and hour < 18:
        return '_1200_1759'
    else:
        return '_1800_2359'


# Check if a directory is valid, then return its child directories
def scan_dir(path):
    if os.path.isdir(path):
        try:
            return os.listdir(path)
        except Exception as e:
            logger.error(e)
            return []
    else:
        return []

if __name__ == '__main__':
    main()
