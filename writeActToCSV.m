for j = 1:length(s)
    daymin = min(s{j}.EDAtimes{2}); daymax = max(s{j}.EDAtimes{2});
    try
        for q = 1:length(s{j}.EDAtimes{1})
            header = {'12:00am','','','','','','6:00am','','','','','','Noon','','','','','','6:00pm','','','','','11:00pm'};
             acc = squeeze(nanmean(s{j}.ACCmean(q,1:31,1:24,:),4)); acclog = log(acc);
             temp = s{j}.TEMPmean(q,1:31,1:24,:);temp(temp>35) = NaN; temp(temp<25) = NaN;
             temp = squeeze(nanmean(temp,4));
             eda = squeeze(nanmean(s{j}.EDAmean(q,1:31,1:24,:),4));

             eda(eda>20) = NaN;
            rc = squeeze(nanmean(s{j}.RCinterp_min(1,q,1:31,1:24,:),5));
             csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_acc_deltaRMSmean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(daymin) 'to' num2str(daymax) '.csv'],acc,header);
             csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_acc_LOGdeltaRMSmean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(daymin) 'to' num2str(daymax) '.csv'],acclog,header);
             csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_temp_mean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(daymin) 'to' num2str(daymax) '.csv'],temp,header);
             csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_eda_mean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(daymin) 'to' num2str(daymax) '.csv'],eda,header);
            csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_REDCap_mean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(daymin) 'to' num2str(daymax) '.csv'],rc,header);
        for k = daymin:daymax
            header = {'12:00am','','','','','','6:00am','','','','','','Noon','','','','','','6:00pm','','','','','11:00pm'};
            try
                
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_acc_deltaRMSmean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],squeeze(s{j}.ACCmean(q,k,:,:))',header);
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_acc_LOGdeltaRMSmean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],log(squeeze(s{j}.ACCmean(q,k,:,:))'),header);
                 temp = squeeze(s{j}.TEMPmean(q,k,:,:));
                 temp(temp>35) = NaN; temp(temp<25) = NaN;
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_temp_mean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],temp',header);
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_eda_mean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],squeeze(s{j}.EDAmean(q,k,:,:))',header);
            catch
                disp('error 1')
            end
            try
                csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_REDCap_mean' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],squeeze(s{j}.RCinterp_min(1,q,k,:,:))',header);
            end
            header2 = {'0:00','','','','','','','','','','0:10','','','','','','','','','','0:20','','','','','','','','','','0:30','','','','','','','','','','0:40','','','','','','','','','','0:50','','','','','','','','','0:59'};
            try
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_acc_deltaRMSmean_trans' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],squeeze(s{j}.ACCmean(q,k,:,:)),header2);
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_acc_LOGdeltaRMSmean_trans' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],log(squeeze(s{j}.ACCmean(q,k,:,:))),header2);
                 temp = squeeze(s{j}.TEMPmean(q,k,:,:));
                 temp(temp>35) = NaN; temp(temp<25) = NaN;
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_temp_mean_trans' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],temp,header2);
                 csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_embrace_eda_mean_trans' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],squeeze(s{j}.EDAmean(q,k,:,:)),header2);
            catch
                disp('error 3')
            end
            try
                csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-4/CSV/DIA_' s{j}.Patient '_REDCap_mean_trans' '_month' num2str(s{j}.EDAtimes{1}(q)) '_day' num2str(k) '.csv'],squeeze(s{j}.RCinterp_min(1,q,k,:,:)),header2);
            end
        end
        end
    end
end
    