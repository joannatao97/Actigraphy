for j = 2:2
    try
        [s]=extractRawActData('/Users/joshsalvi/Documents/Lab/Lab/Baker/Actigraphy/',j);
    catch
        disp('error 1')
    end
    try
    s = s{j};
    end
    try
        save(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/' s.Patient '.mat'],'s');
    catch
        disp('error 2')
    end
    
    try
        daymin = min(s.EDAtimes{2}); daymax = max(s.EDAtimes{2});
        header = {'12:00am','','','','','','6:00am','','','','','','Noon','','','','','','6:00pm','','','','','11:00pm'};
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_acc_deltaRMSmean_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.ACCmean(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_acc_deltaRMSmax_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.ACCmax(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_acc_deltaRMSvar_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.ACCvar(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_temp_mean_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.TEMPmean(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_temp_max_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.TEMPmax(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_temp_var_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.TEMPvar(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_eda_mean_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.EDAmean(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_eda_max_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.EDAmax(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_embrace_eda_var_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.EDAvar(1,:,:)),header);
    catch
        disp('error 2')
    end
    
    try
        header = {'12:00am','','','','','','6:00am','','','','','','Noon','','','','','','6:00pm','','','','','11:00pm'};
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_REDCap_mean_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.RCmean(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_REDCap_max_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.RCmax(1,:,:)),header);
        csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data/CSV/DIA_' s.Patient '_REDCap_var_day' num2str(daymin) 'to' num2str(daymax) '.csv'],squeeze(s.RCvar(1,:,:)),header);
     catch
        disp('error 3')
    end
    
    clear s
end
