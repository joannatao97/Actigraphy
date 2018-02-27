#!/bin/bash

studydir=$1

# Run gplot on all CSV files in directory
echo "Running gplot..."
for file in ${studydir}/DIA*ALL.csv
    do
        if [ -f "$file" ]; then
            gplot.sh "$file" 0 1
        fi
    done

for file in ${studydir}/DIA*PSD.csv
    do
        if [ -f "$file" ]; then
            gplot.sh "$file" 0 1
        fi
    done

# Combine PNGs from gplot.sh into single PDF with annotations
echo "Converting to PDF..."
mkdir ${studydir}/reports
convert -fill black -undercolor white -pointsize 36 -gravity SouthWest -annotate +10+10 %t ${studydir}/DIA_*.png ${studydir}/reports/DIA_combined.pdf
# fi

# Convert PDF to PNG
echo "Converting to PNG..."
convert -append -density 150 ${studydir}/reports/DIA_combined.pdf -quality 90 ${studydir}/reports/DIA_combined.png
# convert -append -density 150 ${studydir}/DIA_combined.pdf -quality 90 ${studydir}/DIA_combined.gif

