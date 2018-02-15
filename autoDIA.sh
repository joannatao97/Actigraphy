#!/bin/bash

parentdir=$1

# Run DIA Summary file to process REDCap annotations
/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi/DIA_summ.sh

for subdir in ${parentdir}/*
	do
		echo ${subdir}
		
		for file in ${subdir}/actigraphy/raw/*zip
			do
				echo "$file"
				unzip -j -o "$file" -d "${subdir}/actigraphy/raw/"
			done

		/usr/local/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi'); extractRawActData('${subdir}');quit()"

		/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi/autogplot.sh "${subdir}"

	done
