#!/bin/bash

# Parent directory
parentdir="/Users/joshsalvi/Documents/Lab/Lab/Baker/geneactiv/Technical/example_run_data"

# Loop through each raw CSV file. Ensure that each CSV file has the appropriate format, "*_raw.csv"
for file in ${parentdir}/*_raw.csv
    do
        echo $file

        # Create empty CSV containers
        touch ${file}_metadata.csv
        touch ${file}_rawdata.csv

        # Export metadata as first 100 rows, raw data values as all but the first 100 rows
        head -n 100 $file > ${file}_metadata.csv
        tail -n +101 $file > ${file}_rawdata.csv
    done
