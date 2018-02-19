#!/bin/bash
##########################################################
 
dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/gits/dp_test"

#########################################################

study=$1
sub=$2
bwID=$3
out_home=$4
start_d=$5
end_d=$6

if [ ! $6 ]
then
	end_d=`date +%F`
fi

phx="/ncf/cnl03/PHOENIX"
moduledir="${dp_home}/MODULES"
out_sub="${out_home}/${sub}/mri"
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`
rawdir="${phx}/GENERAL/${study}/${sub}/mri/raw"
datestr=`date +%y%m%d_%H:%M`
start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`
days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1.9)}'`

####################################################################################################

cd ${out_sub}

if [ ! -e qc ]
then
	mkdir qc
else
	rm -f qc/*
fi

for i in `echo ${days_to_plot} | awk '{for (v=1; v<=$1; v++) print v}'`
do 
	sday=`date -d "${start_d} UTC ${i} days" +%y%m%d`
	
	if [ `grep -c ${sday} ${out_home}/.mrisessions_psf_complete` = 1 ]
	then
		sdayid=`grep ${sday} ${out_home}/.mrisessions_psf_complete`
	elif [ `grep -c ${sday} ${out_home}/.mrisessions_psf_complete` -gt 1 ]
	then
		for mri in `grep ${sday} ${out_home}/.mrisessions_psf_complete`
		do
			mri_sub=`ArcGet.py -a cbscentral -s ${sub} -readme | grep SUBJECT: | awk '{print $2}'`

			if [ "${mri_sub}" = "${sub}" ]
			then
				sdayid=${mri}
			fi
		done
	else
		sdayid="blah"
	fi

	if [ -e ${out_sub}/processed/fs531/${sdayid}/qc/INDIV_MAPS/${sdayid}_qc_table.txt ]
	then
		snr1=`grep SNR1 ${out_sub}/processed/fs531/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print 100-$4}'`
		snr2=`grep SNR2 ${out_sub}/processed/fs531/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print 100-$4}'`
		R=`grep Corr ${out_sub}/processed/fs531/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print $4}'`
		a=`grep Slope ${out_sub}/processed/fs531/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print $4}'`
		b=`grep Intercept ${out_sub}/processed/fs531/${sday}_*[0-9]/qc/INDIV_MAPS/*_qc_table.txt | awk '{print $4}'`
		date -d "${start_d} UTC ${i} days" +%F,${i},${snr1},${snr2},${R},${a},${b}
	else
		date -d "${start_d} UTC ${i} days" +%F,${i},NaN,NaN,NaN,NaN,NaN
	fi
done | pcut -cs , -cd , -c 3-max | awk -F , 'BEGIN{printf "%s,%s,%s,%s,%s\n", "SNR-1", "SNR-2", "Correlation", "Slope", "Intercept"}{OFS=","; print $1, $2, $3, $4, $5}' > ${out_sub}/qc/${sub}_qc_array.csv

cd ${out_sub}/qc

${dp_home}/commons/gplot.sh ${sub}_qc_array.csv 0 100 "BOLD QC" ${sun1}


grid_n=`echo ${days_to_plot} | awk '{print int($1/100)+1}'`

html_n=1

while [ ${html_n} -le ${grid_n} ]
do
	png=PNG/`ls -1 | grep ${html_n}00days.png$ | grep -v parse`

	echo '<div class="reportItem"><div class="reportItemDescription">' > ${sub}_qc.html${html_n}
	echo '<span class="reportItemDescriptionHeader">' >> ${sub}_qc.html${html_n}
	echo 'MRI QC Measures' >> ${sub}_qc.html${html_n}
	echo '</span></div>' >> ${sub}_qc.html${html_n}
	echo '<div class="reportItemImage"><img class="reportItemDataImage" src="'${png}'" alt="qc" /><img class="reportItemLegendImage" src="PNG/CBARS/qc_bar.png" alt="qc_bar_legend" /></div>' >> ${sub}_qc.html${html_n}
	echo '</div>' >> ${sub}_qc.html${html_n}
	
	html_n=`expr ${html_n} + 1`
done

cd ..

