#!/bin/bash

# Inputs
mainfile=$1         # filename
splitsize=$2    # number of lines in each subfile
min=$3          # minimum value for gplot
max=$4          # maximum value for gplot

# Remove old files
find . -type f -name '*split*' -delete

# Split the file into subfiles
tail -n +2 $mainfile | split -l $splitsize - ${mainfile}_split_

for splitfile in ${mainfile}_split_*
    do
        head -n 1 $mainfile > tmp_file
        cat $splitfile >> tmp_file
        mv -f tmp_file ${splitfile}.csv
    done

for file in ${mainfile}_split_*.csv
    do
        head -1 ${file} > ${file}.hdr
        n=`wc -l ${file} | awk '{print $1-1}'`
        tail -$n $file | pcut -cs , -cd , -t -c 1-max > ${file}.array

        # Replace the missing values with NaN before input into matlab
        awk -F , '{ OFS=","; for (i=0; i<=NF; i++) if (length($i)<1) $i="NaN"; print $0}' ${file}.array > ${file}.NaNarray

        # Call matlab to generate EPS
        matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('/eris/sbdp/GSP_Subject_Data/SCRIPTS'); gplot('${file}.NaNarray','${file}.hdr',$min,$max);quit()"

        # Convert to PNG
        convert -density 300 ${file}.NaNarray.eps -background white -flatten ${file}_scale${min}to${max}.png
    done

# Clean up. Remove all split files and intermediate files
find . -type f -not -name '*.png' -name '*split*' -delete