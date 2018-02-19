#!/bin/bash
##########################################################
 
dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/gits/dp_test" 

#########################################################
file=$1
min=$2
max=$3
label=$4
sun1=$5
sed -i 's/, $//g' ${file}

head -1 ${file} > ${file}.hdr
n=`wc -l ${file} | awk '{print $1-1}'`
grid_n=`echo ${n} | awk '{print int($1/100)+1}'`

stem=`echo $file | sed -e '/\.csv/s///'`
array_n=1

while [ ${array_n} -le ${grid_n} ]
do
	ext="`expr ${array_n} \* 100 - 99 | awk '{printf "%03d", $1}'`to`expr ${array_n} \* 100`days"
	tail -$n $file | awk -F , 'NR>=((array_n*100)-99) && NR<=(array_n*100) {OFS=","; print $0}' array_n=${array_n} | /ncf/tools/current/code/bin/pcut -cs , -cd , -t -c 1-max > ${file}_${ext}.array

	# Replace the missing values with NaN before input into matlab

	awk -F , '{ OFS=","; for (i=0; i<=NF; i++) if (length($i)<1) $i="NaN"; print $0}' ${file}_${ext}.array > ${file}_${ext}.NaNarray

	xtick=`echo ${array_n} | awk '{print ((($1-1)*100)+10)}'`

	if [ `wc -l ${file}_${ext}.NaNarray | awk '{print $1}'` -gt 1 ]
	then
		/ncf/nrg/sw/apps/matlab/7.4/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('${dp_home}/commons'); gplotwc('${file}_${ext}.NaNarray','${file}.hdr',$min,$max,'${label}',$sun1,$xtick);quit()" 

		convert -density 300 ${file}_${ext}.NaNarray.eps -background white -flatten ${stem}_${ext}.png
	fi

	array_n=`expr ${array_n} + 1`
done

cat ${stem}*NaNarray > ${file}.NaNarray
rm ${stem}*days*.NaNarray ${file}.hdr *.eps *days.array
