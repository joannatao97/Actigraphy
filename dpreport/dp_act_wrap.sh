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

dp_modules="${dp_home}/MODULES"
start_d=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $3}'`
bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${sub}/phone/raw | head -1`
phx="/ncf/cnl03/PHOENIX/GENERAL"
act_root="${phx}/${study}/${sub}/actigraphy/raw"
out_sub="${out_home}/${sub}"
sDOW=`date -d ${start_d} +%w`
act_home=${out_sub}/actigraphy
sun1=`find_sunday ${sDOW}`
datestr=`date +%y%m%d_%H%M`

start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`

days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1)}'`
days_to_plot0=`echo ${days_to_plot} | awk '{printf "%03d\n", $1}'`

#echo ${days_to_plot} test

cd ${act_home}
	
for i in `ls -1 ${act_root} | grep -v -f ${out_home}/.act_exclude.list `
do
	if [ ! -e raw/${i} ]
	then
		cp ${act_root}/${i} raw/${i}
		sed -i s/
//g raw/${i}
	fi
done

for i in `cat ${out_home}/.act_exclude.list`
do
	if [ -e raw/${i} ]
	then
		rm -f raw/${i}
	fi
done

if [ ! -e ${act_home}/config ]
then
	touch ${act_home}/config
fi

# If no new actigraphy data, just append NaNs to existing; otherwise process.	
if [ `ls -1 raw | sdiff - config | grep -c '<'` -lt 1 ]
then
	if [ -e old ]
	then
		rm -rf old
		mv processed old
	else
		mv processed old
	fi

	rm -f old/*png
	rm -f old/*html
	rm -f old/*info*
	
	mkdir processed

	if [ -e old/ACT_array ]
	then
		cp old/ACT_array old/LIGHT_array old/*samples.csv processed/
	else
		touch processed/{LIGHT,ACT}_array
	fi

	while [ `wc -l processed/ACT_array | awk '{print $1}'` -lt ${days_to_plot} ]
	do
		echo "NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN" >> processed/ACT_array
	done


	while [ `wc -l processed/LIGHT_array | awk '{print $1}'` -lt ${days_to_plot} ]
	do
		echo "NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN" >> processed/LIGHT_array
	done

	cd processed
	
	sed -i 's/NaN,NaN,0,NaN,NaN/NaN,NaN,NaN,NaN,NaN/g' LIGHT_array
	sed -i 's/NaN,NaN,0,NaN,NaN/NaN,NaN,NaN,NaN,NaN/g' ACT_array


	cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv ACT_array > ${sub}_ACT_array.csv
	cat ${dp_home}/HTML_TEMPLATES/hourheaders.csv LIGHT_array > ${sub}_LIGHT_array.csv

	${dp_home}/commons/gplot.sh ${sub}_ACT_array.csv 0 250 "Actigraphy" ${sun1}
	${dp_home}/commons/gplot.sh ${sub}_LIGHT_array.csv 0 1000 "Light" ${sun1}

	n=`cat ${sub}_ACT_array.csv | grep -v -c ^NaN,.*NaN$ | awk '{print $1-1}'`
	nan=`cat ${sub}_ACT_array.csv | grep -c ^NaN,.*NaN$`
	hours=`expr $n + $nan`
	pct=`echo "$n $nan" | awk '{printf "%d%s\n",(($1/($1+$2))*100), "\%"}'`
	#pngact=PNG/`ls -1 | grep .png$ | grep ACT`
	#pnglight=PNG/`ls -1 | grep .png$ | grep LIGHT`
	secs_last=0

	for file in `ls -1 ../raw | egrep -i -v 'Combined|Export'`
	do
		if [ `wc -l  ../raw/${file} | awk '{print $1}'` -gt 100 ]
		then
			dcol=`sed s/^M//g ../raw/${file} | sed 's/"//g' | grep Date | tail -1 | awk -F , '{ for (i=1;i<=NF;i++) if ($i=="Date") print i}'`
			file_last=`sed s/^M//g ../raw/${file} | grep -v ^$ | sed 's/,$//g' | grep -v '^,\(,\)\{3,\}$' | tail -1 | awk -F , '{print $"'${dcol}'"}' | sed 's/"//g'`
			
			if [ `echo ${file_last} | awk '{print length($1)}'` -ge 6 ]
			then
				n_secs=`date -d "${file_last}" +%s`
			else
				echo ${file} ${file_last}
			fi

			if [ ${n_secs} -gt ${secs_last} ]
			then 
				secs_last="${n_secs}"
				echo ${file}
				echo ${secs_last}
			fi
		fi
	done
	
	
	secs_now=`date +%s`

	last=`echo ${secs_now} ${secs_last} | awk '{print int(($1-$2)/(3600*24))}'`

	echo "${n},${pct},${last}" > ${sub}.actigraphy.info
	
	
	grid_n=`echo ${hours} | awk '{print int($1/100)+1}'`
	html_n=1
	echo grid_n ${grid_n}
	echo html_n ${html_n}
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
		echo html_n ${html_n}
	done


	rm -f *tmp

	cd ${act_home}

	exit 0
else
	rm ${sub}.actigraphy.sh
	ls -1 raw > config
	cat ${dp_home}/HTML_TEMPLATES/screencmd.hdr > ${sub}.actigraphy.sh
	echo "${dp_modules}/actigraphy.sh ${sub} ${days_to_plot0} config ${datestr} ${sun1} ${start_d_sec}" >> ${sub}.actigraphy.sh
	echo "cd ${act_home}/processed" >> ${sub}.actigraphy.sh
	echo "${dp_home}/commons/gplot.sh ${sub}_ACT_array.csv 0 250 \"Actigraphy\" ${sun1}" >> ${sub}.actigraphy.sh
	echo "cd ${act_home}/processed" >> ${sub}.actigraphy.sh
	echo "${dp_home}/commons/gplot.sh ${sub}_LIGHT_array.csv 0 1000 \"Light\" ${sun1}" >> ${sub}.actigraphy.sh
	chmod 777 ${sub}.actigraphy.sh
	
	sbatch --mail-type=FAIL --mail-user=`whoami` --job-name=${sub}.ACT -p ncf --time=240 --mem=2000 -o ${sub}.actigraphy.so -e ${sub}.actigraphy.se --wrap="source /users/`whoami`/.bash_profile && cd ${act_home} && ./${sub}.actigraphy.sh"
	
	cd ${act_home}
fi

exit 0
