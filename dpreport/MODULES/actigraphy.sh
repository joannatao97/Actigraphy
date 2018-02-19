#!/bin/bash
##########################################################
 
dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/gits/dp_test"

#########################################################
sub=$1
days_to_plot=$2
cfg=$3
datestr=$4
sun1=$5
start_d_sec=$6


rm processed/*
for i in `cat $cfg`
do
	sed 's/
//g' raw/${i} | sed 's/"//g' | sed 's/ AM/AM/g' | sed 's/ PM/PM/g' > processed/`echo ${i} | sed 's/_\([1-9]\)_/_0\1_/g' | sed 's/_\([1-9]\)_/_0\1_/g'`
done

cd processed	

echo 'in processed'

for i in `ls -1`
do
	x=`grep -n Activity ${i} | awk -F \: '{print $1}' | tail -1`
	y=`wc -l ${i} | awk '{print $1}'`

	lines=`echo "$x $y" | awk '{print $2-$1}'`
	
	echo ${lines}
	
	grep Activity ${i} | tail -1 | awk -F , 'NR==1{OFS=","; for (n=1; n<=NF; n++) if ($n=="Date" || $n=="Time" || $n=="Activity" || $n=="Marker" || $n=="White Light") print $n,n}' > cols.tmp

	for col in Date Time Activity Marker Light
	do
		export ${col}="`grep ${col} cols.tmp | awk -F , '{print $2}'`"
	done

	tail -${lines} ${i} | grep -v ^$ | pcut -cs , -cd , -c ${Date},${Time},${Activity},${Marker},${Light} | grep -v ime | awk -F , '{OFS=","; "date -d \""$1"\" +%s" | getline dt; print int(((dt-"'${start_d_sec}'")/(60*60*24))+1.5)}' > ${i}.day.tmp


	for d in `tail -${lines} ${i} | grep -v ^$ | pcut -cs , -cd , -c ${Time} | grep -v ime`
	do
		date -d ${d} +%k >> ${i}.hrs.tmp
	done

	tail -${lines} ${i} | grep -v ^$ | pcut -cs , -cd , -c ${Activity},${Light} | grep -v ight | paste -d , ${i}.day.tmp ${i}.hrs.tmp - > ${i}_array.csv

done

for i in `ls -1 | grep csv_array.csv`;
do
	cat ${i} >> ${sub}_${datestr}_samples.csv
done

sed -i 's/ //g' ${sub}_${datestr}_samples.csv

for d in `echo ${days_to_plot} | awk '{for (i=1; i<=$1; i++) print i}'`
do 
	for h in {0..23}
	do
		if [ `grep -c ^$d,$h, ${sub}_${datestr}_samples.csv | awk '{print $1}'` -ge 1 ]
		then
			cat ${sub}_${datestr}_samples.csv | grep -v NaN | awk -F , '{OFS=","; if  ($1=="'${d}'" && $2=="'${h}'") print $3}' | awk '{sum+=$1}END{print sum/NR}'
		else
			echo "NaN"
		fi
	done | paste -s -d , - >> ACT_array
done


for d in `echo ${days_to_plot} | awk '{for (i=1; i<=$1; i++) print i}'`
do 
	for h in {0..23}
	do
		if [ `grep -c ^$d,$h, ${sub}_${datestr}_samples.csv | awk '{print $1}'` -ge 1 ]
		then
			cat ${sub}_${datestr}_samples.csv | grep -v NaN | awk -F , '{OFS=","; if  ($1=="'${d}'" && $2=="'${h}'") print $4}' | awk '{sum+=$1}END{print sum/NR}'
		else
			echo "NaN"
		fi
	done | paste -s -d , - >> LIGHT_array
done


days_to_plot=`echo ${days_to_plot} | awk '{printf "%03d\n", $1}'`

cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv ACT_array > ${sub}_ACT_array.csv
cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv LIGHT_array > ${sub}_LIGHT_array.csv


if [ -e ${sub}.actigraphy.sh ]
then
	chmod 775 ${sub}.actigraphy.sh
	./${sub}.actigraphy.sh
else
	${dp_home}/commons/gplot.sh ${sub}_ACT_array.csv 0 250 "Actigraphy" ${sun1}
	${dp_home}/commons/gplot.sh ${sub}_LIGHT_array.csv 0 1000 "Light" ${sun1}
fi

n=`cat ${sub}_ACT_array.csv | grep -v -c ^NaN,.*NaN$ | awk '{print $1-1}'`
nan=`cat ${sub}_ACT_array.csv | grep -c ^NaN,.*NaN$`
hours=`expr $n + $nan`
pct=`echo "$n $nan" | awk '{printf "%d%s\n",(($1/($1+$2))*100), "\%"}'`
#pngact=PNG/`ls -1 | grep .png$ | grep ACT`
#pnglight=PNG/`ls -1 | grep .png$ | grep LIGHT`

secs_last=0

for file in `ls -1 ../raw`
do
	if [ `wc -l  ../raw/${file} | awk '{print $1}'` -gt 100 ]
	then
		dcol=`sed s/^M//g ../raw/${file} | sed 's/"//g' | grep Date | tail -1 | awk -F , '{ for (i=1;i<=NF;i++) if ($i=="Date") print i}'`
		file_last=`sed s/^M//g ../raw/${file} | grep -v ^$ | grep -v '^,\(,\)\{3,\}$' | tail -1 | awk -F , '{print $dcol}' dcol=$dcol | sed 's/"//g'`
		
		if [ `echo ${file_last} | awk '{print length($1)}'` -ge 6 ]
		then
			n_secs=`date -d "${file_last}" +%s`
		fi

		if [ ${n_secs} -gt ${secs_last} ]
		then 
			secs_last="${n_secs}"
		fi
	fi
done

secs_now=`date +%s`

last=`echo ${secs_now} ${secs_last} | awk '{print int(($1-$2)/(3600*24))}'`

echo "${n},${pct},${last}" > ${sub}.actigraphy.info

grid_n=`echo ${hours} | awk '{print int($1/100)+1}'`
html_n=1

while [ ${html_n} -le ${grid_n} ]
do
	pngact=PNG/`ls -1 | grep ${html_n}00days.png$ | grep ACT`
	pnglight=PNG/`ls -1 | grep ${html_n}00days.png$ | grep LIGHT`

	echo '<div class="reportItem"><div class="reportItemDescription">' > ${sub}.actigraphy.html${html_n}
	echo '<span class="reportItemDescriptionHeader">' >> ${sub}.actigraphy.html${html_n}
	echo 'Activity (wrist)' >> ${sub}.actigraphy.html${html_n}
	echo '</span><span class="reportItemDescriptionDetail">'${n}'/'${hours}' hours collected ('${pct}')</span></div>' >> ${sub}.actigraphy.html${html_n}
	echo '<div class="reportItemImage"><img class="reportItemDataImage" src="'${pngact}'" alt="act" /><img class="reportItemLegendImage" src="PNG/CBARS/ACT_bar.png" alt="ACT_legend" /></div>' >> ${sub}.actigraphy.html${html_n}
	echo '</div>' >> ${sub}.actigraphy.html${html_n}

	echo '<div class="reportItem"><div class="reportItemDescription">' >> ${sub}.actigraphy.html${html_n}
	echo '<span class="reportItemDescriptionHeader">' >> ${sub}.actigraphy.html${html_n}
	echo 'Light Exposure (wrist)' >> ${sub}.actigraphy.html${html_n}
	echo '</span><span class="reportItemDescriptionDetail">'${n}'/'${hours}' hours collected ('${pct}')</span></div>' >> ${sub}.actigraphy.html${html_n}
	echo '<div class="reportItemImage"><img class="reportItemDataImage" src="'${pnglight}'" alt="light" /><img class="reportItemLegendImage" src="PNG/CBARS/LIGHT_bar.png" alt="LIGHT_legend" /></div>' >> ${sub}.actigraphy.html${html_n}
	echo '</div>' >> ${sub}.actigraphy.html${html_n}

	html_n=`expr ${html_n} + 1`
done
rm *tmp

cd ..

exit 0
#cat 1 > ${sub}.actigraphy.pipe
