import os
import sys
import re
import collections as col
from datetime import datetime
from dateutil import tz
from jinja2 import Environment, FileSystemLoader
from shutil import copy2
import logging
from PIL import Image

from graphic import css
from tools import parser, scanner, reader, exporter 
from library.phone import identifiers

logger = logging.getLogger(__name__)

def get_file_prefix(study, subject):
    return '{STUDY}_{SUBJECT}_DPreport_day'.format(STUDY=study,SUBJECT=subject)

def get_file_suffix(day):
    day_from = day * 100 + 1
    day_to = day * 100 + 100
    return '{day_from}to{day_to}.html'.format(day_from=day_from, day_to=day_to)

def generate_now(timezone):
    return datetime.now().replace(tzinfo=tz.gettz(timezone)).strftime('%Y-%m-%d %H:%M:%S')

def generate(measurement_info, study, subject, timezone, output_dir, root_dir):
    subject_metadata = get_metadata(study, subject, output_dir, root_dir)
    subject_data, pages, images = get_data(measurement_info, study, subject, output_dir, root_dir)

    gen_time = generate_now(timezone)
    html_dir = get_processed_path(output_dir, root_dir, study, subject, 'phone')
    if not html_dir:
        logger.error('{PATH} does not exist. Skipping html generation.'.format(PATH=html_dir))

    fetch_imgs(images, html_dir)
    img_width, img_height = check_dimensions(images)

    file_prefix = get_file_prefix(study, subject)
    generate_html(study, subject, subject_metadata, subject_data, gen_time, html_dir, file_prefix, pages, img_width, img_height)

    return

def get_dimensions(image_path):
    im = Image.open(image_path)
    width, height = im.size
    return width, height

# Goes through every image, and returns the highest width and length
def check_dimensions(images):
    max_width = 0
    max_height = 0
    for image in images:
        width, height = get_dimensions(image)
        if width > max_width:
            max_width = width

        if height > max_height:
            max_height = height

    return max_width, max_height

# Copy all png files to the export path
def fetch_imgs(images, write_path):
    try:
        for img in images:
            copy2(img, write_path)
    except Exception as e:
        logger.error(e)

def generate_html(study, subject, identifier, subject_data, gen_time, html_dir, file_prefix, page_num, img_width, img_height):
    lib_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
    template_dir = os.path.join(lib_dir, 'graphic', 'html')
    j2_env = Environment(loader=FileSystemLoader(template_dir), trim_blocks=True)

    for page in range(0, page_num + 1):
        file_suffix = get_file_suffix(page)
        page_path = os.path.join(html_dir, file_prefix + file_suffix)
        page_rendered = j2_env.get_template('dpreport.template').render(
            gen_time=gen_time,
            study = study,
            subject_id = subject,
            diagnosis = identifier['diagnosis'] if 'diagnosis' in identifier else '',
            age = identifier['age'] if 'age' in identifier else '',
            gender = identifier['gender'] if 'gender' in identifier else '',
            race = identifier['race'] if 'race' in identifier else '',
            beiwe_id = identifier['patient_id'] if 'patient_id' in identifier else '',
            beiwe_version = identifier['beiwe_version'] if 'beiwe_version' in identifier else '',
            manufacturer = identifier['manufacturer'] if 'manufacturer' in identifier else '',
            model = identifier['model'] if 'model' in identifier else '',
            os = identifier['device_os'] if 'device_os' in identifier else '',
            os_version = identifier['os_version'] if 'os_version' in identifier else '',
            categories=subject_data,
            page=str(page),
            width=img_width,
            height=img_height
        )
        exporter.export_html(page_path, page_rendered)

# Gets metadata for subject
def get_metadata(study, subject, output_dir, root_dir):
    metadata = []

    metadata_file_prefix = identifiers.get_file_prefix()
    metadata_filename = exporter.get_file_prefix(study, subject, metadata_file_prefix)
   
    if output_dir:
        metadata_path = output_dir
    else:
        metadata_path = os.path.join(root_dir, 'GENERAL', study, subject, 'phone', 'processed')

    if not os.path.isdir(metadata_path):
        logger.error('{PATH} does not exist. skipping.'.format(PATH=metadata_path))
        return metadata
    else:
        metadata_filepath = os.path.join(metadata_path, metadata_filename)
        for row in reader.read_csv(metadata_filepath, 0):
            metadata.append(row)
        return metadata

# Gets paths of gplot images for each variable for each measurement key
def get_data(measurement_info, study, subject, output_dir, root_dir):
    subject_data = col.defaultdict()
    subject_page_num = 0
    subject_images = []
    for measurement_key, measure_values in measurement_info.iteritems():
        subject_data[measurement_key] = []

        for item in measure_values:
            match = parser.parse_measurement_info(item)
            if not match:
                logger.error('Skipping variable {item}'.format(item=item))
                continue

            dt = match.group('data_type')
            variable = match.group('variable')

            processed_data_path = get_processed_path(output_dir, root_dir, study, subject, dt)
            if not processed_data_path:
                logger.error('Directory for {MI} not found.'.format(MI=item))
                continue

            measured_data, page_num, images = get_processed_files(study, subject, processed_data_path, variable)
            if len(measured_data) > 0:
                measured_data['name'] = variable
                subject_data[measurement_key].append(measured_data)
                subject_images.extend(images)
                # Count the maximum number of pages available for the subject
                if page_num > subject_page_num:
                    subject_page_num = page_num

    return subject_data, subject_page_num, subject_images

# Gets processed path to find a processed file from
def get_processed_path(output_dir, root_dir, study, subject, data_type):
    processed_data_path = None
    if not output_dir:
        directories = scanner.scan_dir(root_dir)
        for directory in sorted(directories):
            subject_path = os.path.join(root_dir, directory, study, subject)
            if not os.path.isdir(subject_path):
                logger.error('{PATH} does not exist. skipping.'.format(PATH=subject_path))
                continue

            data_types = scanner.scan_dir(subject_path)
            if data_type not in data_types:
                continue
            else:
                processed_data_path = os.path.join(subject_path, data_type, 'processed')
                break
    else:
        processed_data_path = output_dir

    return processed_data_path

# Gets processed files (gplot images)
def get_processed_files(study, subject, processed_path, variable):
    measurement_data = col.defaultdict()
    page_num = 0
    images = []
    for root_dir, dirs, files in os.walk(processed_path):
        files = [f for f in files if not f[0] == '.']
        dirs[:] = [d for d in dirs if not d[0] == '.']

        for file_name in sorted(files):
            matched_img = exporter.verify_gplot_img(file_name, study, subject, variable, 'png')
            if matched_img is None:
                continue

            file_path = os.path.join(root_dir, file_name)
            if matched_img.group('datatype').endswith('Hourly'):
                if 'hourly' not in measurement_data:
                    measurement_data['hourly'] = col.defaultdict()
                img_part = matched_img.group('part')
                measurement_data['hourly'][img_part] = col.defaultdict()
                measurement_data['hourly'][img_part]['name'] = file_name
                width, height = get_dimensions(file_path)
                measurement_data['hourly'][img_part]['width'] = width
                measurement_data['hourly'][img_part]['height'] = height
                
                images.append(file_path)
                if int(img_part) > page_num:
                    page_num = int(img_part)
            elif matched_img.group('datatype').endswith('Daily'):
                if 'daily' not in measurement_data:
                    measurement_data['daily'] = col.defaultdict()
                img_part = matched_img.group('part')
                measurement_data['daily'][img_part] = col.defaultdict()
                measurement_data['daily'][img_part]['name'] = file_name
                width, height = get_dimensions(file_path)
                measurement_data['daily'][img_part]['width'] = width
                measurement_data['daily'][img_part]['height'] = height
                images.append(file_path)
                if int(img_part) > page_num:
                    page_num = int(img_part)

    return measurement_data, page_num, images
