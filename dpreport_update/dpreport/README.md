DPreport
=========

## Table of contents
1. [Requirements](#requirements)
2. [Setup for DPreport](#setup-for-dpreport)
3. [Generate reports](#generate-reports)

## Requirements
miniconda2 (Python 2.7)
https://conda.io/miniconda.html

pandas (>= 0.20.0)
https://pandas.pydata.org/pandas-docs/stable/

NRG encrypt library
https://ncfcode.rc.fas.harvard.edu/nrg/encrypt

jinja2
http://jinja.pocoo.org/docs/2.10/

On NCF, you can simply:
```bash
module load miniconda2
```

## Setup for DPreport
For security reasons, dpreport does not accept passphrases for locked files as an argument.
To decrypt locked files, please export a path to your passphrase file as an environment variable 'dpreport_pp'.

```bash
export dpreport_pp=/path/to/passphrase/file.csv
```

The format of the file must be:

| study         | passphrase         |
|---------------|--------------------|
| StA           | PH123              |
| StB           | PH3210987654       |
| ST#3          | Placeholder12      |


## Generate reports
By default, dpreport will process data, png, and html files for all subjects in all studies.
To specify options:

```bash
# Generate files under each subject's processed directory
./dpreport 

# Generate files under ~/dp_test1 directory
./dpreport --output-dir ~/dp_test1

# Run for STUDY A's subject B
./dpreport --output-dir ~/dp_test1/ --study STUDY_A --subject B

# Process png files again for all subjects for all studies
./dpreport --process png

# Process data and html files
./dpreport --process data html
```


For more information, please run:
```bash
./dpreport -h
```


