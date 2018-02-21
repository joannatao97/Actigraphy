#!/bin/bash

studydir=$1

# Run gplot on all CSV files in directory
echo "Running gplot..."
for file in ${studydir}/DIA*.csv
    do
        gplot.sh "$file" 0 1
    done

# Combine PNGs from gplot.sh into single PDF with annotations
echo "Converting to PDF..."
convert -fill black -undercolor white -pointsize 36 -gravity SouthWest -annotate +10+10 %t ${studydir}/DIA_*.png ${studydir}/DIA_combined.pdf

# Convert PDF to PNG
echo "Converting to PNG..."
convert -append -density 150 ${studydir}/DIA_combined.pdf -quality 90 ${studydir}/DIA_combined.png
