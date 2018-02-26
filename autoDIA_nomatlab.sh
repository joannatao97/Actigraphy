#!/bin/bash

parentdir=$1
scriptsdir="/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi"

# Run DIA Summary file to process REDCap annotations
${scriptsdir}/DIA_summ_phoenix.sh

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

        # Run gplot on all newly-generated CSVs, convert PNGs into a single PDF and PNG 
        echo "Auto gplot..."
        ${scriptsdir}/autogplot.sh "${subdir}/actigraphy/processed/binned-hour"

        # Generate report
        echo "Generating report..."
        echo "${subdir}/actigraphy/processed/binned-hour"
        module load miniconda2/3.19.0
        module load pylib/6.5.2
        python ${scriptsdir}/dpreport_embrace/report_gen.py $(basename $subdir)
    
        # Create PDF with wkhtmltopdf
        for file in ${subdir}/actigraphy/processed/binned-hour/reports/*.html
            do
                wkhtmltopdf -d 650 --page-width 1000px ${file} ${file}.pdf
            done
    done
