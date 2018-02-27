#!/bin/bash

parentdir=$1
binSize=$2
scriptsdir="/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi"

for subdir in ${parentdir}/*
    do
        echo ${subdir}

        # Unzip the embrace data
        echo "Unzipping..."
        for file in ${subdir}/actigraphy/raw/*zip
            do
                echo "$file"
                unzip -j -o "$file" -d "${subdir}/actigraphy/raw/"
            done

        # Remove old files
        echo "Removing ${subdir}/actigraphy/processed/binned/binSize${binSize}"
        mkdir ${subdir}/actigraphy/processed/binned
        rm -R ${subdir}/actigraphy/processed/binned/binSize${binSize}
        mkdir ${subdir}/actigraphy/processed/binned/binSize${binSize}

        # Run matlab analysis to generate MAT file and CSVs
        echo "MATLAB analysis..."
        /usr/local/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('${scriptsdir}'); extractRawActData_acconly('${subdir}',$binSize,'$(basename $subdir)');quit()"
        
    done
