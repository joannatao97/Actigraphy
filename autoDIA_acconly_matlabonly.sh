#!/bin/bash

parentdir=$1        # study directory e.g. /eris/sbdp/PHOENIX/GENERAL/DIA
binSize=$2          # bin size in SECONDS
scriptsdir="/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi"

for subdir in ${parentdir}/*
    do
        echo ${subdir}

        # Run matlab analysis to generate MAT file and CSVs
        echo "MATLAB analysis..."
        /usr/local/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('${scriptsdir}'); extractRawActData_acconly('${subdir}',$binSize,'$(basename $subdir)');quit()"
        
    done
