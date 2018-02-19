import os
from tools import parser

FILE_REGEX = '{subject}_{file_prefix}EpochByEpochData_{timestamp}.csv'

def parse(read_path, file_prefix, timestamp, subject):
    file_name = FILE_REGEX.format(subject=subject, file_prefix=file_prefix, timestamp=timestamp)
    f = os.path.join(read_path, file_name)
    return parser.csv_to_df(f)
