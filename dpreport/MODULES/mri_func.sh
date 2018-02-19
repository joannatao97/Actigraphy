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
#script_dir="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS"
moduledir="${dp_home}/MODULES"
out_sub="${out_home}/${sub}/mri"
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`
rawdir="${phx}/GENERAL/${study}/${sub}/mri/raw"
datestr=`date +%y%m%d_%H:%M`
start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`
days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1.9)}'`


#######################################################################################

cd ${out_sub}

for i in func
do
	if [ ! -e ${out_sub}/${i} ]
	then
		mkdir ${out_sub}/${i}
	else
		rm ${out_sub}/${i}/*
	fi
done

tac ${dp_home}/NORMS/17NET/netnames | paste -s -d , - > ${out_sub}/func/${sub}_func.csv

cp ${out_sub}/func/${sub}_func.csv ${out_sub}/func/${sub}_funcSparse.csv

for i in `echo ${days_to_plot} | awk '{for (v=1; v<$1; v++) print v}'`
do
	sday=`date -d "${start_d} UTC ${i} days" +%y%m%d`
	
	if [ `ls -1 ${rawdir} | grep -c ${sday}_` -ge 1 ]
	then
		sdayid=`ls -1 ${rawdir} | grep ${sday} | head -1`
	else
		sdayid=blah
	fi

	if [ -e ${out_sub}/processed/fs531/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt ]
	then
		cat ${out_sub}/processed/fs531/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt | pcut -cd , -c 3 -t >> ${out_sub}/func/${sub}_func.csv
		cat ${out_sub}/processed/fs531/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt | pcut -cd , -c 3 -t >> ${out_sub}/func/${sub}_funcSparse.csv
	
	elif [ ! -e ${out_sub}/processed/fs531/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt ] && [ -e ${out_sub}/processed/fs450/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt ]
	then
		cat ${out_sub}/processed/fs450/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt | pcut -cd , -c 3 -t >> ${out_sub}/func/${sub}_func.csv
		cat ${out_sub}/processed/fs450/${sdayid}/qc/INDIV_MAPS/${sdayid}_17net_table.txt | pcut -cd , -c 3 -t >> ${out_sub}/func/${sub}_funcSparse.csv
	else
		echo "NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN" >> ${out_sub}/func/${sub}_func.csv
	fi
done

cd ${out_sub}/func

${dp_home}/commons/gplot.sh ${sub}_func.csv 0 100 "17-Network FC Percentiles" ${sun1}
${dp_home}/commons/gplot.sh ${sub}_funcSparse.csv 0 100 "17-Network FC Percentiles" ${sun1}

png=PNG/`ls -1 | grep .png$ | grep -v parse`

echo '<div class="reportItem"><div class="reportItemDescription">' > ${sub}.func.html
echo '<span class="reportItemDescriptionHeader">' >> ${sub}.func.html
echo 'Within-Network functional connectivity' >> ${sub}.func.html
echo '</span></div>' >> ${sub}.func.html
echo '<div class="reportItemImage"><img class="reportItemDataImage" src="'${png}'" alt="funcmri" /><img class="reportItemLegendImage" src="PNG/CBARS/func_bar.png" alt="func_bar_legend" /></div>' >> ${sub}.func.html
echo '</div>' >> ${sub}.func.html

cd ..
	
