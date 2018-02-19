import os
import re
import sys
import csv
import pdb
import pprint
import logging
import datetime as dt
import collections as col

logger = logging.getLogger(__name__)

META = {
    'Subject Properties': {
        'alias': 'SubjectProperties',
        'orientation': 'row',
        'key_index': 0
    },
    'Actiwatch Data Properties': {
        'alias': 'DataProperties',
        'orientation': 'row',
        'key_index': 0
    },
    'Analysis Inputs': {
        'alias': 'AnalysisInputs',
        'orientation': 'row',
        'key_index': 0
    },
    'Statistics': {
        'alias': 'Statistics',
        'orientation': 'column',
        'key_index': 0
    },
    'Marker/Score List': {
        'alias': 'MarkerScoreList',
        'orientation': 'column',
        'key_index': 7
    },
    'Epoch-by-Epoch Data': {
        'alias': 'EpochByEpochData',
        'orientation': 'column',
        'key_index': 10
    }
}
   
def parse(f, match, assessment_prefix, output_dir, timestamp):
    logger.debug('beginning dividing {0}'.format(f))
    timestamp = get_timestamp(match)
    sid = match.group('subject')

    _process(f, timestamp, sid, assessment_prefix, output_dir)
    logger.debug('dividing complete for {0}'.format(f))

def _process(f, timestamp, sid, assessment_prefix, output_dir):
    data = col.defaultdict(dict)
    headers = _get_headers(f)
    num_headers = len(headers)

    for i,header in enumerate(headers):
        section = _get_section(f, header)
        _name = '_' + re.sub('[\W]+', '_', header.lower().strip())
        fun = _get_function(_name)

        metadata = META[header]
        filename = sid + '_' + assessment_prefix + metadata['alias'] + '_' + timestamp + '.csv'
        logger.debug('calling function {0} for {1}'.format(_name, header))

        fun(section, metadata, filename, output_dir)
        logger.debug('processing complete for {0}'.format(header))

def generate_csv(data, headers, filename, output_dir):
    try:
        output_file = os.path.join(output_dir, filename)
        with open(output_file, 'wb') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            writer.writeheader()
            for item in data:
                writer.writerow(item)
    except Exception as e:
        logger.error(e)
        return

def _get_section(f, header, last=False):
    section = list()
    with open(f, 'rb') as fp:
        for line in fp:
            start = re.search('"-+\s?(?!"){0}(?!")\s?-+"'.format(header), line)
            if start:
                for line in fp:
                    if not line.strip():
                        continue
                    end = re.search('"-+\s?(?!")(.*?)(?!")\s?-+"', line)
                    if end and end.group(1):
                        return section
                    section.append(line)
    return section

def _default(section, metadata, filename, output_dir):
    logger.debug('calling default function')
    orientation = metadata['orientation']
    if orientation == 'row':
        return _parse_row_orient(section, filename, output_dir)
    elif orientation == 'column':
        return _parse_col_orient(section, filename, output_dir)
    else:
        raise OrientationError('unknown orientation {0}'.format(orientation))    

class OrientationError(Exception):
    pass

def _parse_col_orient(section, filename, output_dir):
    reader = csv.DictReader(section)
    headers = reader.fieldnames
    data = [row for row in reader]

    generate_csv(data, headers, filename, output_dir)

def _parse_row_orient(section, filename, output_dir):
    d = {}
    headers = []

    reader = csv.reader(section)
    for row in reader:
        header_element = row[0].lstrip()
        if header_element.endswith(':'):
            header_element = header_element[:-1]
        d[header_element] = ' '.join(row[1:])
        headers.append(header_element)

    data = [d]

    generate_csv(data, headers, filename, output_dir)
    
def _epoch_by_epoch_data(section, metadata, filename, output_dir):
    logger.debug('calling epoch-by-epoch function')
    return _sub_metadata_handler(section, filename, output_dir)

def _marker_score_list(section, metadata, filename, output_dir):
    logger.debug('caling marker/score list function')
    return _sub_metadata_handler(section, filename, output_dir)

def _sub_metadata_handler(section, filename, output_dir):
    metadata_marker = 0
    csv_header = []
    data = []

    #Philips software adds '' at the end of each row
    csv_header.append('')

    reader = csv.reader(section)
    for row in reader:
        #Find the sub_metadata
        if metadata_marker == 0 and row[0] == 'Column Title':
            metadata_marker = metadata_marker + 1
            continue
        #Skip the divider
        elif metadata_marker == 1:
            metadata_marker = metadata_marker + 1
            continue
        #Get headers from sub_metadata
        elif metadata_marker == 2:
            if csv_header != row:
                csv_header.pop(-1)

                header_element = row[0].lstrip()
                if header_element.endswith(':'):
                    csv_header.append(header_element[:-1])
                else:
                    csv_header.append(header_element)

                csv_header.append('')
            else:
                metadata_marker = metadata_marker + 1
                continue
        #Process data
        elif metadata_marker == 3:
            data_piece = col.defaultdict()
            for data_index, data_value in enumerate(row):
                data_key = csv_header[data_index]
                data_piece[data_key] = data_value
            data.append(data_piece)

    generate_csv(data, csv_header, filename, output_dir)

def _get_headers(f):
    headers = []
    with open(f, 'rb') as fo:
        for line in fo:
            match = re.search('"-+\s?(?!")(.*?)(?!")\s?-+"', line)
            if match and match.group(1):
                headers.append(match.group(1))
    return headers

def _get_function(h):
    if h in globals():
        return globals()[h]
    return globals()['_default']

def get_timestamp(match):
    time_stamp = '{YEAR}-{MONTH}-{DAY} {HOUR}:{MIN}:{SEC} {PERIOD}'
    time_stamp = time_stamp.format(YEAR=match.group('year'),
                                   MONTH=match.group('month'),
                                   DAY=match.group('day'),
                                   HOUR=match.group('hour'),
                                   MIN=match.group('minute'),
                                   SEC=match.group('second'),
                                   PERIOD=match.group('time_period'))
    time_stamp = dt.datetime.strptime(time_stamp, '%Y-%m-%d %I:%M:%S %p')
    return dt.datetime.strftime(time_stamp, '%Y%m%dT%H%M%S')

def _epoch_by_epoch(fp):
    pass
    
