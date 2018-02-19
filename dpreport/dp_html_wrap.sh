#!/bin/bash
##########################################################

dp_home="/ncf/cnl/13/users/jbaker/PSF_SCRIPTS/gits/dp_test"

#########################################################
#   DP HTML WRAPPER:
#
#	1. Creates HTML folder for participant
#	2. Copies all HTML files created during processing (find under "phone", "actigraphy" and "mri")
#	3. Uses regular naming congvention to figure out which headers to use
#	4. Adds available HTML to appropriate sections: INFO, STUDY VISIT (clin, mri), ACTIVE (surveys, voice), PASSIVE (beiwe, actigraphy)

#  "info" should become its own datatype
#  find should look across all available folders

if [ $# -lt 1 ]
then
	echo "Usage:  ...."
fi


study=$1
subID=$2
study_dir=$3  #study_dir is the main study folder

if [ -e ${study_dir}/.${study}_end_dates ] && [ `grep -c ${subID} ${study_dir}/.${study}_end_dates` -ge 1 ]
then
	end_d=`grep ${subID} ${study_dir}/.${study}_end_dates | awk '{print $2}'`
else
	end_d=`date +%F`
fi



gentime=`date +%c | sed 's/ /_/g'`
phx="/ncf/cnl03/PHOENIX/GENERAL"
dp_modules="${dp_home}/MODULES"

html_dir="${dp_home}/HTML_TEMPLATES"

start_d=`grep ${subID} /ncf/cnl03/PHOENIX/GENERAL/${study}/${study}.csv | awk -F , '{print $3}'`
bwID=`ls -1 -S /ncf/cnl03/PHOENIX/GENERAL/${study}/${subID}/phone/raw | head -1`
outdir="${study_dir}/${subID}/dp_report"
#outfile=${outdir}/${subID}_DPreport.html

start_d_sec=`date -d ${start_d} +%s`
end_d_sec=`date -d ${end_d} +%s`

days_to_plot=`echo $end_d_sec $start_d_sec | awk '{print int(($1-$2)/(60*60*24)+1)}'`
echo ${days_to_plot}
grids_n=`echo ${days_to_plot} | awk '{print int($1/100)+1}'`

#  1. Create directories
if [ ! -e $outdir ]
then
	mkdir $outdir 
else 
	rm -f ${outdir}/*{html,pdf}
fi

if [ ! -e ${outdir}/HTML ]
then
	mkdir ${outdir}/{HTML,PDF,PNG}
else
	rm -f ${outdir}/HTML/* ${outdir}/PNG/*
fi

# 2. Go to output dir and sweep for files
cd $outdir


cp ${html_dir}/dpreport_logo.png ./PNG
cp ${html_dir}/dpr.css ./
cp -r ${html_dir}/fonts ./

html_n=1

while [ ${html_n} -le ${grids_n} ]
do
	outfile=${outdir}/${subID}_DPreport${html_n}.html
	for datatype in phone actigraphy redcap mri
	do
		if [ -e ${study_dir}/${subID}/${datatype} ]
		then
			find ${study_dir}/${subID}/${datatype} -name "*.html${html_n}" -exec cp '{}' ./HTML/ \;
			find ${study_dir}/${subID}/${datatype} -name "*${html_n}00days.png" -exec cp '{}' ./PNG \;
		fi
	done

    # This section is time-consuming and can be replaced with css. 
	#cd ./PNG/
	#${dp_home}/dp_png_buffer.sh  # Adds the legend and any additional buffer to each PNG


	cd ${outdir}/HTML

	${dp_modules}/dp_info.sh ${study} ${subID} ${study_dir}  

	#  Now we will create the DPreport HTML file and begin appending sections
	#
	#  Sections to Append for REPORT:   DPreport
	#  1.  dp_info
	#  2.  ...

	# First open the HTML file and drop in CSS
	cat ${html_dir}/body_template_top.html >> $outfile

	# Next drop in info section
	cat ${subID}_info.html >> $outfile

    # Open reportBody
    echo '<div class="reportBody">' >> $outfile

	#Checking for Study Visit measures
	if [ `ls -1 | egrep -c 'scales|func|qc'` -ge 1 ]
	then
		${dp_modules}/dp_headline.sh "Study Visit Measures" >> $outfile 

		for datatype in redcap_scales qc
		do
			if [ -e ${subID}_${datatype}.html${html_n} ]
			then
				cat ${subID}_${datatype}.html${html_n} | grep -v 'src="PNG/"' >> $outfile
			fi
		done
	fi

	# Checking for Active datatypes
	if [ -e ${subID}.voiceRecording.html${html_n} ] || [ -e ${subID}.surveyAnswers1.html${html_n} ]
	then
		${dp_modules}/dp_headline.sh "Active Measures" >> $outfile 

		for datatype in surveyAnswers1 surveyAnswers2 voiceRecording 
		do
			if [ -e ${subID}.${datatype}.html${html_n} ]
			then
				cat ${subID}.${datatype}.html${html_n} | grep -v 'src="PNG/"' >> $outfile
			fi
		done
	fi

	# Checking for Passive datatypes
	if [ `ls -1 | egrep -c 'call|gps|accel|actigraphy'` -ge 1 ]
	then
		${dp_modules}/dp_headline.sh "Passive Measures" >> $outfile 

		for datatype in gps accel actigraphy callLog textsLog
		do
			if [ -e ${subID}.${datatype}.html${html_n} ]
			then
				cat ${subID}.${datatype}.html${html_n} | grep -v 'src="PNG/"' >> $outfile
			fi
		done
	fi

	# Finally close the reportBody and body section of the HTML
	echo '</div></body></html>' >> $outfile

	sed -i 's/_gentime_/'${gentime}'/g' ${outfile}

	#   This will convert the HTML report into a PDF
	#${dp_home}/makepdf $outfile ${outdir}/PNG

	#rm ${outdir}/HTML/* ${outdir}/PNG/*
	
	cp ${html_dir}/dpreport_logo.png ${outdir}/PNG

	cd ${outdir}

	html_n=`expr ${html_n} + 1`
done

/usr/bin/pdftk `ls -1 | grep pdf$ | paste -s -d \  -` cat output ${study}_${subID}_mri_clin_beiwe_activ.pdf

#rm ${outdir}/*DPreport[0-9].pdf ${outdir}/*html

exit 0
