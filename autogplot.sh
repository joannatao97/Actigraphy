#!/bin/bash

studydir=$1

for file in ${studydir}DIA*.csv
    do
      	gplot.sh "${studydir}$file" 0 1
    done

convert -fill black -undercolor white -pointsize 36 -gravity SouthWest -annotate +10+10 %t ${studydir}/DIA_*.png ${studydir}/DIA_combined.pdf
