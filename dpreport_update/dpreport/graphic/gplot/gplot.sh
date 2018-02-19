#!/bin/bash

file=$1
min=$2
max=$3
label=$4
pcutDir=/cluster/nrg/tools/0.10.0b/code/bin/


echo ${file}


sed -i 's/, $//g' ${file}

head -1 ${file} > ${file}.hdr
n=`wc -l ${file} | awk '{print $1-1}'`
tail -$n $file | $pcutDir/pcut -cs , -cd , -t -c 1-max > ${file}.array

# Replace the missing values with NaN before input into matlab

awk -F , '{ OFS=","; for (i=0; i<=NF; i++) if (length($i)<1) $i="NaN"; print $0}' ${file}.array > ${file}.NaNarray

#cat ${file}.NaNarray

/cluster/nrg/tools/0.10.0b/apps/arch/linux_x86_64/matlab/7.4/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/dpreport_update/dpreport/graphic/gplot'); gplot('${file}.NaNarray','${file}.hdr',$min,$max,'${label}');quit()" >/dev/null 2>/dev/null
#/ncf/nrg/sw/apps/matlab/7.4/bin/matlab -nosplash -nodisplay -nodesktop -nojvm -r "addpath('/ncf/cnl/13/users/jbaker/PSF_SCRIPTS'); gplot('${file}.NaNarray','${file}.hdr',$min,$max,'${label}');quit()" >/dev/null 2>/dev/null


stem=`echo $file | sed -e '/\.csv/s///'`
convert -density 300 ${file}.NaNarray.eps -background white -flatten ${stem}_scale${min}to${max}.png
#rm ${file}.array ${file}.hdr ${file}.NaNarray ${file}.NaNarray.eps
