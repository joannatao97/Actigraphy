for j = 1:length(s)
    daymin = min(s{j}.EDAtimes{2}); daymax = max(s{j}.EDAtimes{2});
    try
        for q = 1:length(s{j}.EDAtimes{1})
            for k = daymin:daymax
                % Header
                header = {'annot','acc PSD 0-5 Hz','acc PSD 5-10 Hz','acc PSD 10-15 Hz','acc dRMS','eda','temp'};
                
                % Extract values
                acc = squeeze(s{j}.ACCvar(q,k,:,:)); logacc = log(acc);
                temp = squeeze(s{j}.TEMPmean(q,k,:,:)); temp(temp>40) = NaN; temp(temp<25) = NaN;
                eda = squeeze(s{j}.EDAmean(q,k,:,:)); eda(eda>30) = NaN; eda = log(eda);
                rc = squeeze(s{j}.RCinterp_min(1,q,k,:,:));
                
                % acc PSD
                acc_PSD_0to5Hz = log(squeeze(s{j}.velRS_Pxx_0to5Hz(q,k,:,:)));
                acc_PSD_5to10Hz = log(squeeze(s{j}.velRS_Pxx_5to10Hz(q,k,:,:)));
                acc_PSD_10to15Hz = log(squeeze(s{j}.velRS_Pxx_10to15Hz(q,k,:,:)));
                
                % Rescale: 0-1
                logacc = (logacc - min(min(logacc)))./abs(max(max(logacc) - min(min(logacc))));
                temp = (temp - min(min(temp)))./abs(max(max(temp) - min(min(temp))));
                eda = (eda - min(min(eda)))./abs(max(max(eda) - min(min(eda))));
                rc = (rc - min(min(rc)))./abs(max(max(rc) - min(min(rc))));
                accPSDmin = min([min(min(acc_PSD_0to5Hz)) min(min(acc_PSD_5to10Hz)) min(min(acc_PSD_10to15Hz))]);
                accPSDmax = max([max(max(acc_PSD_0to5Hz)) max(max(acc_PSD_5to10Hz)) max(max(acc_PSD_10to15Hz))]);
                acc_PSD_0to5Hz = (acc_PSD_0to5Hz - accPSDmin)./abs(accPSDmax - accPSDmin);
                acc_PSD_5to10Hz = (acc_PSD_5to10Hz - accPSDmin)./abs(accPSDmax - accPSDmin);
                acc_PSD_10to15Hz = (acc_PSD_10to15Hz - accPSDmin)./abs(accPSDmax - accPSDmin);
                
                if s{j}.EDAtimes{1}(q)-s{j}.EDAtimes{1}(1)+1 < 10
                    month0 = ['0' num2str(s{j}.EDAtimes{1}(q)-s{j}.EDAtimes{1}(1)+1)];
                else
                    month0 = num2str(s{j}.EDAtimes{1}(q)-s{j}.EDAtimes{1}(1)+1);
                end
                
                for l = 1:24
                    try
                        warning off
                        mkdir(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-All Modes/CSV/' s{j}.Patient '/'])
                    end
                    % Combine into one array
                    mat = [rc(l,:); acc_PSD_0to5Hz(l,:); acc_PSD_5to10Hz(l,:); acc_PSD_10to15Hz(l,:); logacc(l,:); eda(l,:); temp(l,:)];
                    
                    if isnan(nanmean(nanmean(mat))) == 0
                        
                        if k-daymin+1<10
                            day0 = ['0' num2str(k-daymin+1)];
                        else
                            day0 = num2str(k-daymin+1);
                        end
                        
                        if l-1 >= 10
                            % Write to CSV
                            csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-All Modes/CSV/' s{j}.Patient '/' 'DIA_' s{j}.Patient '_annot_embrace' '_month' month0 '_day' day0 '_hour' num2str(l-1) '.csv'],mat',header);
                        else
                            csvwrite_with_headers(['/Users/joshsalvi/Documents/Lab/Lab/Baker/Extracted Actigraphy Data-All Modes/CSV/' s{j}.Patient '/' 'DIA_' s{j}.Patient '_annot_embrace' '_month' month0 '_day' day0 '_hour0' num2str(l-1) '.csv'],mat',header);

                        end
                    end
                end
                
            end
        end
    end
end
            