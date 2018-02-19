#!/bin/bash
##########################################################
 
dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/gits/dp_test"

#########################################################

###############################################################
#
#   Usage:  dp_bw_wrap.sh $study $sub $out_home
#
#	study:    PHOENIX study name
#	sub:	  study ID
#	out_home:	Full path to output directory
#
################################################################
#
#	Dependencies:
#	
#	1. a ~/.${study}_auth file containing the study specific beiwe decrypt pass 
#
##################################################################

study=$1
sub=$2
out_home=$3

# parse explicit $end_d, or set to today
if [ -e ${out_home}/.${study}_end_dates ] && [ `grep -c ${sub} ${out_home}/.${study}_end_dates` -ge 1 ]
then
	end_d=`grep ${sub} ${out_home}/.${study}_end_dates | awk '{print $2}'`
else
	end_d=`date +%F`
fi

# parse ${study}.csv file for $bwID and $start_d
# set $sDOW and $sun1
start_d=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $3}'`
bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${sub}/phone/raw | head -1`
#bwID=`grep ${sub} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $5}' | awk -F ';' '{print $1}'`
sDOW=`date -d ${start_d} +%w`
sun1=`find_sunday $sDOW`

###############################################################
#
#   SCRIPT PATHS
#
################################################################

moduledir="${dp_home}/MODULES"
###############################################################
#
#   STUDY FOLDERS
#
################################################################



###############################################################
#
#   DO NOT CHANGE BELOW THIS LINE
#
################################################################

## STUDY PHOENIX CONFIG
phx="/ncf/cnl03/PHOENIX"
general=${phx}/GENERAL
protected=${phx}/PROTECTED
genhome=${general}/${study}
prohome=${protected}/${study}

## SUBJECT BEIWE_ROOT/OUTPUT CONFIG
out_sub=${out_home}/${sub}/phone/processed/${bwID}
bwroot_gen=${general}/${study}/${sub}/phone/raw/${bwID}
bwroot_pro=${protected}/${study}/${sub}/phone/raw/${bwID}
out_sub_raw=${out_home}/${sub}/phone/raw/${bwID}

if [ ! -e ${out_sub_raw} ]
then
	mkdir ${out_home}/${sub}/phone/raw ${out_home}/${sub}/phone/raw/${bwID}
fi
##############################################################

cd $out_sub

# First cycle through the protected data types build/submit datatype modules for processing on cluster
for datatype in gps voiceRecording
do
	if [ -e ${bwroot_pro}/${datatype} ]
	then
		out=${out_sub}/${datatype}
		out_raw=${out_sub_raw}/${datatype}
		cd $out
		rm -f *
		bw_script="${moduledir}/beiwe_${datatype}.sh"
		tmp_script=${sub}_beiwe_${datatype}.sh

		cat ${dp_home}/HTML_TEMPLATES/screencmd.hdr > $tmp_script
		echo "$bw_script $sub ${bwroot_pro}/${datatype} ${start_d} ${end_d} ${study}" >> $tmp_script

		if [ ${datatype} = "voiceRecording" ] 
		then
			if [ ! -e ${out_raw} ]
			then
				mkdir ${out_raw}
			fi

			echo "mv ${out}/*mp4 ${out}/*wav ${out_raw}/" >> $tmp_script
			
			if [ ${study} = "BLS" ]
			then
				echo "python /ncf/cnl/13/users/jbaker/PSF_SCRIPTS/voice_dbx_sync.py -p ${study} -s ${sub} -b ${bwID} -r ${out_raw} -y" >> $tmp_script
			fi
			echo "rm ${out_raw}/*mp4 ${out_raw}/*wav" >> $tmp_script
		fi
		chmod 777 $tmp_script
		
		echo "Preparing to submit ${datatype}"

		sbatch --mail-type=FAIL --mail-user=`whoami` --job-name=${sub}.${datatype} --uid=`whoami` --get-user-env -p ncf --time=180 --mem=2000 -o ${tmp_script}.so -e ${tmp_script}.se --wrap="source /users/`whoami`/.bash_profile && module load beiwe/5.0-ncf && cd $out && ./${tmp_script}"

		sleep 2
	fi
done


cd $out_sub


# Next build the ${sub}.${datatype}.sh scripts that get passed to the gplot wrapper (Not sure why it's separated into two loops)
for datatype in gps voiceRecording
do
	if [ -e ${bwroot_pro}/${datatype} ]
	then
		case $datatype in
			"gps")
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*gps_disthome_array.csv 0 10 \"GPS Mean Distance From Home\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*gps_disthome_array_mean.csv 0 10 \"Mean\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				#echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*gps_distmcl_array.csv 0 10 \"GPS Mean Distance From MCL\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				#echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*gps_distmcl_array_mean.csv 0 10 \"Mean\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				;;
			"voiceRecording")
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*voice_array.csv 0 0.04 \"Voice Recordings\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*voice_mean.csv 0 100 \"Total Duration\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				;;
		esac
	fi
done

# Next cycle through the general data types
for datatype in accel callLog textsLog surveyAnswers
do
	if [ -e ${bwroot_gen}/${datatype} ]
	then
		#bw_script="beiwe_${datatype}.sh"
		if [ ${datatype} = "surveyAnswers" ]
		then
			surveys=`ls -1 ${bwroot_gen}/${datatype} | paste -s -d \  -`
			
			ns=1
			
			for survey in $surveys
			do
				if [ ! -e ${out_sub}/${datatype}/${survey} ]
				then
					mkdir ${out_sub}/${datatype}/${survey}
				fi
				
				beiweroot="${bwroot_gen}/${datatype}/${survey}"

				out=${out_sub}/${datatype}/${survey}
				
				cd $out
				rm -f *
				
				${moduledir}/beiwe_surveyAnswers.sh ${sub} ${bwroot_gen}/${datatype}/${survey} ${start_d} $end_d
                echo 'surveyAnswers conversion done'

				${dp_home}/commons/gplot.sh ${out}/${sub}*surveyAnswers_array.csv 0 4 "Survey Answers" ${sun1}
                echo 'surveyAnswers plotting done'
				
				rename surveyAnswers surveyAnswers${ns} *png
                echo 'surveyAsnwers renaming done'

				n=`cat ${sub}*surveyAnswers_array.csv | grep -c ^[0-9]`
				nan=`cat ${sub}*surveyAnswers_array.csv | grep -c ^NaN`
				days=`expr $n + $nan`
				pct=`echo "$n $nan" | awk '{printf "%d\%\n",(($1/($1+$2))*100)}'`
				#png=PNG/`ls -1 | grep .png$ | grep -v mean`
				last_date="`ls -l ${beiweroot} | tail -1 | awk '{print $9}'`"
				secs_last=`date -d "${last_date}" +%s`
				secs_now=`date +%s`
				last_hours=`echo "${secs_now} ${secs_last}" | awk '{print int(($1-$2)/(3600*24))}'`

				echo "${n},${pct},${last_hours}" > ${sub}.surveyAnswers${ns}.info		
				

				grid_n=`echo ${days} | awk '{print int($1/100)+1}'`

				html_n=1

				while [ ${html_n} -le ${grid_n} ]
				do
					png=PNG/`ls -1 | grep ${html_n}00days.png$`
				
	
					echo '<div class="reportItem"><div class="reportItemDescription">' > ${sub}.surveyAnswers${ns}.html${html_n}
                    echo '<span class="reportItemDescriptionHeader">' >> ${sub}.surveyAnswers${ns}.html${html_n}
					echo 'Survey (phone) #'${ns} >> ${sub}.surveyAnswers${ns}.html${html_n}
                    echo '</span><span class="reportItemDescriptionDetail">'${n}'/'${days}' days collected ('${pct}')</span></div>' >> ${sub}.surveyAnswers${ns}.html${html_n}
					#echo '<div class="reportItemImage"><img class="reportItemDataImage" src="'${pngmean}'" alt="surveym" /></div>' >> ${sub}.surveyAnswers${ns}.html${html_n}
					echo '<div class="reportItemImage"><img class="reportItemDataImage" src="'${png}'" alt="survey"/><img class="reportItemLegendImage" src="PNG/CBARS/surveyAnswers'${ns}'_bar.png" alt="survey_bar_legend" /></div>' >> ${sub}.surveyAnswers${ns}.html${html_n}
					echo '</div>' >> ${sub}.surveyAnswers${ns}.html${html_n}

					html_n=`expr $html_n + 1`
				done
				
				ns=`expr $ns + 1`
			done
		else
			out=${out_sub}/${datatype}
			cd $out
			rm -f * 
			bw_script=${moduledir}/beiwe_${datatype}.sh
			tmp_script=${sub}_beiwe_${datatype}.sh

			cat ${dp_home}/HTML_TEMPLATES/screencmd.hdr > $tmp_script
			echo "$bw_script $sub ${bwroot_gen}/${datatype} ${start_d} ${end_d}" >> $tmp_script
			chmod 777 $tmp_script

			echo "Preparing to submit ${datatype}"

			if [ ${datatype} = "accel" ]
			then
				sbatch --mail-type=FAIL --mail-user=`whoami` --uid=`whoami` --get-user-env --job-name=${sub}.${datatype} -p ncf --time=180 --mem=2000 -o ${tmp_script}.so -e ${tmp_script}.se --wrap=". /ncf/tools/current/code/bin/env_setup.sh && source /users/`whoami`/.bash_profile && module load beiwe/5.0-ncf && cd $out && ./${tmp_script}"
			else
				sbatch --mail-type=FAIL --mail-user=`whoami` --uid=`whoami` --get-user-env --job-name=${sub}.${datatype} -p ncf --time=60 --mem=1000 -o ${tmp_script}.so -e ${tmp_script}.se --wrap="source /users/`whoami`/.bash_profile && module load beiwe/5.0-ncf && cd $out && ./${tmp_script}"
			fi

			sleep 2
		fi
	else
		echo "${sub} has no ${datatype} data"
	fi
done

cd ${out_sub}


for datatype in accel textsLog callLog
do
	if [ -e ${bwroot_gen}/${datatype} ]
	then		
		case $datatype in
			"accel")
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*accel_drms_array.csv 0 0.6 \"Accelerometer\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*accel_drms_array_mean.csv 0 0.6 \"Mean\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				;;
			"textsLog")
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*textsLog_array.csv 0 500 \"Text Log\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*textsLog_array_mean.csv 0 500 \"Mean\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				;;
			"callLog")
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*callLog_array.csv 0 300 \"Phone Call Duration\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				echo "${dp_home}/commons/gplot.sh ${out_sub}/${datatype}/${sub}*callLog_array_mean.csv 0 300 \"Mean\" ${sun1}" >> ${datatype}/${sub}.${datatype}.sh
				;;
			
		esac
	fi
done

cd $out_sub


exit 0
