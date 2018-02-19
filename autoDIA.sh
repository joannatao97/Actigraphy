#!/bin/bash

parentdir=$1

# Run DIA Summary file to process REDCap annotations
/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi/DIA_summ.sh

for subdir in ${parentdir}/*
	do
		echo ${subdir}

		# Unzip the embrace data
		for file in ${subdir}/actigraphy/raw/*zip
			do
				echo "$file"
				unzip -j -o "$file" -d "${subdir}/actigraphy/raw/"
			done

		# Run matlab analysis to generate MAT file and CSVs
		/usr/local/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi'); extractRawActData('${subdir}');quit()"

		# Run gplot on all newly-generated CSVs, convert PNGs into a single PDF
		/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi/autogplot.sh "${subdir}/processed/binned-hour"

	done
