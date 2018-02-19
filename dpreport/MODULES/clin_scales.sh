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
out_sub="${out_home}/${sub}/redcap/processed/scales"
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`
rawdir="${phx}/GENERAL/${study}/${sub}/mri/raw"
datestr=`date +%y%m%d_%H:%M`
start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`
days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1.9)}'`


#######################################################################################

if [ ! -e ${out_sub} ]
then
	mkdir ${out_home}/${sub}/redcap ${out_home}/${sub}/redcap/{raw,processed} ${out_home}/${sub}/redcap/processed/scales
fi

cd ${out_sub}

rm -f ${out_sub}/*

head -1 ${out_home}/.${study}_scales.csv | /ncf/tools/current/code/bin/pcut -cs , -cd , -c 3,4,5,6,9 > ${sub}_redcap_scales_array.csv
cp ${sub}_redcap_scales_array.csv ${sub}_redcap_scales_array_sparse.csv

for i in `echo ${days_to_plot} | awk '{for (v=1; v<=$1; v++) print v}'`
do
	sday=`date -d "${start_d} UTC ${i} days" +%F`
	#sday=`date -d "${start_d} UTC ${i} days" +%y%m%d`

	#if [ `ls -1 ${out_sub}/processed | grep -c ${sday}_` -ge 2 ]
	#then
	#	sdayid=`ls -1 ${out_sub}/processed | grep ${sday} | head -1`
	#else
	#	sdayid=blah
	#fi

	#echo ${sdayid}

	sdayid=${sday}

	if [ `grep ${sub} ${out_home}/.${study}_scales.csv | grep -c ${sdayid} | awk '{print $1}'` = 1 ]
	then
		grep ${sub} ${out_home}/.${study}_scales.csv | grep ${sdayid} | /ncf/tools/current/code/bin/pcut -cs , -cd , -c 3,4,5,6,9 >> ${out_sub}/${sub}_redcap_scales_array.csv
		grep ${sub} ${out_home}/.${study}_scales.csv | grep ${sdayid} | /ncf/tools/current/code/bin/pcut -cs , -cd , -c 3,4,5,6,9 >> ${out_sub}/${sub}_redcap_scales_array_sparse.csv
	else
		echo "NaN,NaN,NaN,Nan,NaN" >> ${out_sub}/${sub}_redcap_scales_array.csv
	fi
done

cd ${out_sub}

#### NEW
mv ${sub}_redcap_scales_array.csv array.tmp

mymrs=`awk -F , '{print $1}' ${out_home}/.${study}_scale_means.csv`
mmadrs=`awk -F , '{print $2}' ${out_home}/.${study}_scale_means.csv`
mpanssp=`awk -F , '{print $3}' ${out_home}/.${study}_scale_means.csv`
mpanssn=`awk -F , '{print $4}' ${out_home}/.${study}_scale_means.csv`
mpanssg=`awk -F , '{print $5}' ${out_home}/.${study}_scale_means.csv`
mpansst=`awk -F , '{print $6}' ${out_home}/.${study}_scale_means.csv`
mmcas=`awk -F , '{print $7}' ${out_home}/.${study}_scale_means.csv`


symrs=`awk -F , '{print $1}' ${out_home}/.${study}_scale_stds.csv`
smadrs=`awk -F , '{print $2}' ${out_home}/.${study}_scale_stds.csv`
spanssp=`awk -F , '{print $3}' ${out_home}/.${study}_scale_stds.csv`
spanssn=`awk -F , '{print $4}' ${out_home}/.${study}_scale_stds.csv`
spanssg=`awk -F , '{print $5}' ${out_home}/.${study}_scale_stds.csv`
spansst=`awk -F , '{print $6}' ${out_home}/.${study}_scale_stds.csv`
smcas=`awk -F , '{print $7}' ${out_home}/.${study}_scale_stds.csv`

grep -v panss array.tmp | awk -F , 'BEGIN{print "ymrs,madrs,panss+,panss-,mcas"}{OFS=","; if ($1!="NaN") print ($1-"'${mymrs}'")/"'$symrs'", ($2-"'$mmadrs'")/"'$smadrs'", ($3-"'$mpanssp'")/"'$spanssp'", ($4-"'$mpanssn'")/"'$spanssn'", -1*(($5-"'$mmcas'")/"'$smcas'"); else print $1, $2, $3, $4, $5}' > ${sub}_redcap_scales_array.csv


mv ${sub}_redcap_scales_array_sparse.csv sparse.tmp


grep -v ymrs sparse.tmp | awk -F , 'BEGIN{print "ymrs,madrs,panss+,panss-,mcas"}{OFS=","; if ($1!="NaN") print ($1-"'${mymrs}'")/"'$symrs'", ($2-"'$mmadrs'")/"'$smadrs'", ($3-"'$mpanssp'")/"'$spanssp'", ($4-"'$mpanssn'")/"'$spanssn'", -1*(($5-"'$mmcas'")/"'$smcas'"); else print $1, $2, $3, $4, $5}' > ${sub}_redcap_scales_array_sparse.csv

####
${dp_home}/commons/gplot.sh ${sub}_redcap_scales_array.csv -2 2 "Clinical Scales" ${sun1}
${dp_home}/commons/gplot.sh ${sub}_redcap_scales_array_sparse.csv -2 2 "Clinical Scales" ${sun1}

grid_n=`echo ${days_to_plot} | awk '{print int($1/100)+1}'`

html_n=1

while [ ${html_n} -le ${grid_n} ]
do
	png=PNG/`ls -1 | grep ${html_n}00days.png$ | grep -v parse`

	echo '<div class="reportItem"><div class="reportItemDescription">' > ${sub}_redcap_scales.html${html_n}
	echo '<span class="reportItemDescriptionHeader">' >> ${sub}_redcap_scales.html${html_n}
	echo 'Clinical Scales' >> ${sub}_redcap_scales.html${html_n}
	echo '</span></div>' >> ${sub}_redcap_scales.html${html_n}
	echo '<div class="reportItemImage"><img "reportItemDataImage" src="'${png}'" alt="clin_scales" /><img class="reportItemLegendImage" src="PNG/CBARS/clin_bar.png" alt="clin_bar_legend" /></div>' >> ${sub}_redcap_scales.html${html_n}
	echo '</div>' >> ${sub}_redcap_scales.html${html_n}

	html_n=`expr ${html_n} + 1`
done

cd ${out_home}

exit 0


