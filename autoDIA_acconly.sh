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
        
        # Run gplot on all newly-generated CSVs, convert PNGs into a single PDF and PNG 
        echo "Auto gplot..."
        echo "${subdir}/actigraphy/processed/binned/binSize${binSize}"
        ${scriptsdir}/autogplot_acconly.sh "${subdir}/actigraphy/processed/binned/binSize${binSize}" 60

        # Generate report
        echo "Generating report..."
        module load miniconda2/3.19.0
        module load pylib/6.5.2
        python ${scriptsdir}/dpreport_embrace/report_gen_acconly.py $(basename $subdir) ${binSize}
    
        # Create PDF with wkhtmltopdf
        for file in ${subdir}/actigraphy/processed/binned/$binSize{binSize}/reports/*.html
            do
                wkhtmltopdf -d 650 --page-width 1000px ${file} ${file}.pdf
            done
    done
