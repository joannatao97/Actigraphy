#!/bin/bash
##########################################################
 
dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/gits/dp_test" 

#########################################################

study=$1
sub=$2
out_home=$3

if [ -e ${out_home}/.${study}_end_dates ] && [ `grep -c ${sub} ${out_home}/.${study}_end_dates` -ge 1 ]
then
	end_d=`grep ${sub} ${out_home}/.${study}_end_dates | awk '{print $2}'`
else
	end_d=`date +%F`
fi


start_d=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $3}'`
#bwID=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $5}'`
bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${sub}/phone/raw | head -1`
echo ${bwID}
cd ${out_home}
#if [ `ls -1 ${out_home}/${sub}/mri/processed | wc -l | awk '{print $1}'` -gt 1 ]
#then
#	${dp_home}/MODULES/mri_func.sh ${study} ${sub} ${bwID} ${out_home} ${start_d} ${end_d}
#fi

${dp_home}/MODULES/mri_qc.sh ${study} ${sub} ${bwID} ${out_home} ${start_d} ${end_d}

if [ -e ${out_home}/.${study}_scales.csv ]
then
	${dp_home}/MODULES/clin_scales.sh ${study} ${sub} ${bwID} ${out_home} ${start_d} ${end_d}
fi

exit 0
