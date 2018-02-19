import os
import logging
from importlib import import_module

logger = logging.getLogger(__name__)

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

# Import and return module for each data type
def scan_library(data_type):
    try:
        return import_module('library.{DT}'.format(DT=data_type), __name__)
    except Exception as e:
        logger.error(e)
        return None

# Import and return module for each sub data type
def scan_library_module(data_type, sub_type):
    try:
        return import_module('library.{DT}.{ST}'.format(DT=data_type, ST=sub_type), __name__)
    except Exception as e:
        logger.error(e)
        return None

# Return the root directory of the module
def get_module_dir():
    scanner_dir = os.path.dirname(__file__)
    tools_dir = os.path.dirname(scanner_dir)
    root_dir = os.path.dirname(tools_dir)
    return root_dir
