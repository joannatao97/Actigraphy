function [s] = extractRawActData(dir01, tz, patient)
%
% Actigraphy QC Analysis
% ----------------------
% ABOUT: This software performs a user-guided assessment of wrist
% actigraphy data. 
%
% USE: extractRawActData(dir, tz)
%       (1) The program takes as an input the parent directory, `dir`, for
%       a particular patient and within which the dir/actigraphy and
%       dir/redcap folders can be found.
%       (2) The program will create a MAT file with a structure containing
%       all of the patient's data.
%       (3) The program will create a subfolder with CSVs (one per hour)
%       with the actigraphy and redcap data included for use in gplot.
%       (4) An optional second argument, `tz`, can be used to specify the
%       time zone, where tz equals UTC-tz (e.g. EDT is tz-4, EST is tz-5).
%       By default, tz = 0 (UTC).

% ----------------------
% Author: Joshua D. Salvi
% josh.salvi@gmail.com
% ----------------------
%
    
    % Append '/' to directory if not already present
    if dir01(end) ~= '/'
        dir01 = [dir01 '/'];
    end
    
    % Initialization
    clear RCvals acc temp eda data RCraw RCrawTS velRS RCstate RCdate RCu
    dir0Act = [dir01 'actigraphy/raw/'];
    files = dir(dir0Act);

    % Import Embrace actigraphy data
    acc = []; eda = []; temp = [];
    for p0 = 1:length(files)
        try
            if isempty(strfind(files(p0).name,'acc.csv')) == 0
                disp(files(p0).name)
                data = importdata([dir0Act files(p0).name]); acc = data.data;
            elseif isempty(strfind(files(p0).name,'temp.csv')) == 0
                disp(files(p0).name)
                data = importdata([dir0Act files(p0).name]); temp = data.data;
            elseif isempty(strfind(files(p0).name,'eda.csv')) == 0
                disp(files(p0).name)
                data = importdata([dir0Act files(p0).name]); eda = data.data;
            end
        catch
        end
    end

    try
        s.acc_raw = acc;
        s.temp_raw = temp;
        s.eda_raw = eda;
    end

    % Import processed survey data (from DIA_summ.sh)
    dir0RC = [dir01 'surveys/processed/'];
    files = dir(dir0RC); clear data
    for p0 = 3:length(files)
        try
            if isempty(strfind(files(p0).name,'_events_trans.csv')) == 0
                disp([dir0RC files(p0).name])
                data = importdata([dir0RC files(p0).name]);
                % try
                %     RCraw = data; 
                %     RCrawTS = data;
                % catch
                % end
            end
        catch
            % disp('No survey data')
        end      
    end

    % Convert UNIX time in ms to MATLAB time
    if exist('tz') == 0
        tz = 0;
    end
    try
        unix_epoch = datenum(1970,1,1,tz,0,0);
        acc(:,1) = acc(:,1)./86400./1e3 + unix_epoch;
        temp(:,1) = temp(:,1)./86400./1e3 + unix_epoch;
        eda(:,1) = eda(:,1)./86400./1e3 + unix_epoch;
    catch
        disp('Unable to convert time (Line 78)')
    end

    % Extract timestamps from survey data
    p0=1;
    RCdate = [];
    try
        for j = 2:length(data)
            try
                RCrawTS{p0} = data{j}(7:25);
                RCdate(p0,:,:,:,:,:,:) = [str2num(RCrawTS{p0}(1:4)); str2num(RCrawTS{p0}(6:7)); str2num(RCrawTS{p0}(9:10));  str2num(RCrawTS{p0}(12:13));  str2num(RCrawTS{p0}(15:16));  str2num(RCrawTS{p0}(18:19))];
                RCstate{p0} = data{j}(27:end);
                p0 = p0+1;
            end
        end
    end
    
    % Initialize activity annotation matrices to NaN arrays
    try
        RCdate = RCdate';
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];
        RCvals = NaN(length(RCu{1}), length(RCu{2}), 31, 24, 60, 60);
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];        
    catch
        disp('Unable to extract RC data (Line 104)')
        RCvals = NaN(1, 1, 31, 24, 60, 60);
    end

    % Generate vector for each type of activity level (1=still; 2=slow; 3=moderate; 4=vigorous)
    % This will interpolate between transitions.
    % Unknowns currently remain NaN values
    try
    for q = 1:length(RCstate)
        if isempty(findstr(RCstate{q},':still')) == 0
            try
                if isempty(findstr(RCstate{q+1},'still:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q) + 1;
                    min1 = RCdate(5,q) + 1;
                    s1 = RCdate(6,q) + 1;

                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1) + 1;
                    min2 = RCdate(5,q+1) + 1;
                    s2 = RCdate(6,q+1) + 1;

                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 1;
                end
            catch
            end
        elseif isempty(findstr(RCstate{q},':slow')) == 0
            try
                if isempty(findstr(RCstate{q+1},'slow:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q) + 1;
                    min1 = RCdate(5,q) + 1;
                    s1 = RCdate(6,q) + 1;

                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1) + 1;
                    min2 = RCdate(5,q+1) + 1;
                    s2 = RCdate(6,q+1) + 1;

                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 2;
                end
            catch
            end
        elseif isempty(findstr(RCstate{q},':moderate')) == 0
            try
                if isempty(findstr(RCstate{q+1},'moderate:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q) + 1;
                    min1 = RCdate(5,q) + 1;
                    s1 = RCdate(6,q) + 1;

                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1) + 1;
                    min2 = RCdate(5,q+1) + 1;
                    s2 = RCdate(6,q+1) + 1;

                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 3;
                end
            catch
            end
        elseif isempty(findstr(RCstate{q},':vigorous')) == 0
            try
                if isempty(findstr(RCstate{q+1},'vigorous:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q) + 1;
                    min1 = RCdate(5,q) + 1;
                    s1 = RCdate(6,q) + 1;

                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1) + 1;
                    min2 = RCdate(5,q+1) + 1;
                    s2 = RCdate(6,q+1) + 1;

                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 4;
                end
            catch
            end
        end
    end
    catch
        disp('Unable to process RC data (Line 115)')
    end
    
    % Find the mean over each minute (averaging over seconds)
    try
        RCvals(RCvals==0) = NaN;
        RCvals = RCvals(1:length(RCu{1}),1:length(RCu{2}),:,:,:,:);
        RCvals_min = nanmean(RCvals,6);
        s.RCinterp = RCvals;
        s.RCu = RCu;
        s.RCinterp_min = RCvals_min;
    catch
        disp('Unable to output RC data (Line 209)')
        RCvals_min = nanmean(RCvals,6);
        s.RCinterp = RCvals;
        s.RCinterp_min = RCvals_min;
    end

    % Time stamps from actigraphy data
    try
        accdate = [month(acc(:,1))'; day(acc(:,1))'; hour(acc(:,1))'; minute(acc(:,1))'];
        tempdate = [month(temp(:,1))'; day(temp(:,1))'; hour(temp(:,1))'; minute(temp(:,1))'];
        edadate = [month(eda(:,1))'; day(eda(:,1))'; hour(eda(:,1))'; minute(eda(:,1))'];

        % Find the unique values
        accu = [{unique(accdate(1,:))}; {unique(accdate(2,:))}; {unique(accdate(3,:))}; {unique(accdate(4,:))}];
        tempu = [{unique(tempdate(1,:))}; {unique(tempdate(2,:))}; {unique(tempdate(3,:))}; {unique(tempdate(4,:))}];
        edau = [{unique(edadate(1,:))}; {unique(edadate(2,:))}; {unique(edadate(3,:))}; {unique(edadate(4,:))}];       
    catch
    end

    try
        monthsmax = max([length(accu{1}) length(tempu{1}) length(edau{1}) length(RCu{1})]);
    catch
        try
            monthsmax = max([length(accu{1}) length(tempu{1}) length(edau{1})]);
        end
    end
    try
        daysmax = max([length(accu{2}) length(tempu{2}) length(edau{2}) length(RCu{2})]);
    catch
        try
            daysmax = max([length(accu{2}) length(tempu{2}) length(edau{2})]);
        end
    end
    try
        % Initialize variables
        velRSmax = NaN([monthsmax, 31, 24, 60]);
        velRSvar = velRSmax; velRSmean = velRSmax;
        velRS_pxx_0to1Hz = velRSmax; velRS_pxx_1to2Hz = velRSmax; velRS_pxx_2to3Hz = velRSmax; velRS_pxx_3to4Hz = velRSmax; velRS_pxx_4to5Hz = velRSmax;
        velRS_pxx_5to6Hz = velRSmax; velRS_pxx_6to7Hz = velRSmax; velRS_pxx_7to8Hz = velRSmax; velRS_pxx_8to9Hz = velRSmax; velRS_pxx_9to10Hz = velRSmax;
        velRS_pxx_10to11Hz = velRSmax; velRS_pxx_11to12Hz = velRSmax; velRS_pxx_12to13Hz = velRSmax; velRS_pxx_13to14Hz = velRSmax; velRS_pxx_14to15Hz = velRSmax;
        velRS_Pxx = cell([monthsmax, 31, 24, 60]);
        velRS_fxx = cell([monthsmax, 31, 24, 60]);
    catch
        disp('Unable to initialize variables (Line 247)')
    end

    % Loop through each minute of acceleration data
    disp('ACC extraction...')
    try
        for j = 1:length(accu{1})
            for k = 1:length(accu{2})
                for l = 1:length(accu{3})
                    for m = 1:length(accu{4}) 
                        try
                            a = intersect(find(accdate(1,:)==accu{1}(j)),find(accdate(2,:)==accu{2}(k)));
                            b = intersect(find(accdate(3,:)==accu{3}(l)),find(accdate(4,:)==accu{4}(m)));
                            c = intersect(a,b);

                            % Simplify the (x,y,z) time series into a single vector
                            displ = sqrt(gradient(acc(c,2)).^2 + gradient(acc(c,3)).^2 + gradient(acc(c,4)).^2);
                            displ = displ - mean(displ);

                            vel = gradient(displ);     % Find the derivative of the acc vector
                            velRS = sqrt(vel.^2);       % Find the dRMS of the acc vector

                            % Find the max, mean, and variance of the velRS vector
                            velRSmax(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = nanmax(velRS);
                            velRSmean(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = nanmean(velRS);
                            velRSvar(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = nanvar(velRS);

                            % Use Welch's algorithm to find the PSD of the displacement vector
                            Fs = 30; % Hz
                            [pxx, fxx] = pwelch(displ,[],[],[],Fs);

                            % Use findnearest() to find the index of each frequency for 1-Hz intervals
                            n0 = findnearest(fxx, 1);n0=n0(1); n1 = findnearest(fxx, 2);n1=n1(1); n2 = findnearest(fxx, 3);n2=n2(1); n3 = findnearest(fxx, 4);n3=n3(1); n4 = findnearest(fxx, 5);n4=n4(1);
                            n5 = findnearest(fxx, 6);n5=n5(1); n6 = findnearest(fxx, 7);n6=n6(1); n7 = findnearest(fxx, 8);n7=n7(1); n8 = findnearest(fxx, 9);n8=n8(1); n9 = findnearest(fxx, 10);n9=n9(1);
                            n10 = findnearest(fxx, 11);n10=n10(1); n11 = findnearest(fxx, 12);n11=n11(1); n12 = findnearest(fxx, 13);n12=n12(1); n13 = findnearest(fxx, 14);n13=n13(1);

                            % Calculate the total power in 1-Hz bins
                            velRS_pxx_0to1Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(1:n0-1),pxx(1:n0-1))); velRS_pxx_1to2Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n0:n1-1),pxx(n0:n1-1)));
                            velRS_pxx_2to3Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n1:n2-1),pxx(n1:n2-1))); velRS_pxx_3to4Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n2:n3-1),pxx(n2:n3-1)));
                            velRS_pxx_4to5Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n3:n4-1),pxx(n3:n4-1))); velRS_pxx_5to6Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n4:n5-1),pxx(n4:n5-1)));
                            velRS_pxx_6to7Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n5:n6-1),pxx(n5:n6-1))); velRS_pxx_7to8Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n6:n7-1),pxx(n6:n7-1)));
                            velRS_pxx_8to9Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n7:n8-1),pxx(n7:n8-1))); velRS_pxx_9to10Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n8:n9-1),pxx(n8:n9-1)));
                            velRS_pxx_10to11Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n9:n10-1),pxx(n9:n10-1))); velRS_pxx_11to12Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n10:n11-1),pxx(n10:n11-1)));
                            velRS_pxx_12to13Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n11:n12-1),pxx(n11:n12-1))); velRS_pxx_13to14Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n12:n13-1),pxx(n12:n13-1)));
                            velRS_pxx_14to15Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n13:end),pxx(n13:end)));

                            % Save the raw PSD for each time window
                            velRS_fxx{j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1} = fxx;
                            velRS_pxx{j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1} = pxx;
                        catch
                            velRSmax(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = NaN;
                            velRSmean(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = NaN;
                            velRSvar(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = NaN;
                        end
                    end
                end
            end
        end
    catch
        disp('Unable to process ACC data (Line 261)')
    end

    % Loop through each time point in the temperature vector
    disp('TEMP extraction...')
    try
        tempmax = NaN([monthsmax, 31, 24, 60]);
        tempvar = tempmax; tempmean = tempmax;
        for j = 1:length(tempu{1})
            for k = 1:length(tempu{2})
                for l = 1:length(tempu{3})
                    for m = 1:length(tempu{4})
                        try
                        a = intersect(find(tempdate(1,:)==tempu{1}(j)),find(tempdate(2,:)==tempu{2}(k)));
                        b = intersect(find(tempdate(3,:)==tempu{3}(l)),find(tempdate(4,:)==tempu{4}(m)));
                        c = intersect(a,b);

                        % Find the max, mean, and variance of the temperature within each bin
                        tempmax(j,tempu{2}(k),tempu{3}(l)+1,tempu{4}(m)+1) = nanmax(temp(c,2));
                        tempmean(j,tempu{2}(k),tempu{3}(l)+1,tempu{4}(m)+1) = nanmean(temp(c,2));
                        tempvar(j,tempu{2}(k),tempu{3}(l)+1,tempu{4}(m)+1) = nanvar(temp(c,2));
                        catch
                            tempmax(j,tempu{2}(k),tempu{3}(l)+1,tempu{4}(m)+1) = NaN;
                            tempmean(j,tempu{2}(k),tempu{3}(l)+1,tempu{4}(m)+1) = NaN;
                            tempvar(j,tempu{2}(k),tempu{3}(l)+1,tempu{4}(m)+1) = NaN;
                        end
                    end
                end
            end
        end
    catch
        disp('Unable to process TEMP data (Line 319)')
    end

    % Loop through each time point in the eda (skin conductivity) vector
    disp('EDA Extraction...')
    try
        edamax = NaN([monthsmax, 31, 24, 60]);
        edavar = edamax; edamean = edamax;
        for j = 1:length(edau{1})
            for k = 1:length(edau{2})
                for l = 1:length(edau{3})
                    for m = 1:length(edau{4})
                        try
                        a = intersect(find(edadate(1,:)==edau{1}(j)),find(edadate(2,:)==edau{2}(k)));
                        b = intersect(find(edadate(3,:)==edau{3}(l)),find(edadate(4,:)==edau{4}(m)));
                        c = intersect(a,b);

                        % Find the max, mean, and variance of the skin conductivity within each bin
                        edamax(j,edau{2}(k),edau{3}(l)+1,edau{4}(m)+1) = nanmax(eda(c,2));
                        edamean(j,edau{2}(k),edau{3}(l)+1,edau{4}(m)+1) = nanmean(eda(c,2));
                        edavar(j,edau{2}(k),edau{3}(l)+1,edau{4}(m)+1) = nanvar(eda(c,2));             
                        catch
                            edamax(j,edau{2}(k),edau{3}(l)+1,edau{4}(m)+1) = NaN;
                            edamean(j,edau{2}(k),edau{3}(l)+1,edau{4}(m)+1) = NaN;
                            edavar(j,edau{2}(k),edau{3}(l)+1,edau{4}(m)+1) = NaN;
                        end
                    end
                end
            end
        end
    catch
        disp('Unable to process EDA data (Line 351)')
    end

    % Save data to a structure with Patient ID and all relevant measures
    try
        s.Patient = patient;
        s.ACCmean = velRSmean; s.ACCmax = velRSmax; s.ACCvar = velRSvar;
        s.TEMPmean = tempmean; s.TEMPmax = tempmax; s.TEMPvar = tempvar;
        s.EDAmean = edamean; s.EDAmax = edamax; s.EDAvar = edavar;
        s.ACCtimes = accu; s.TEMPtimes = tempu; s.EDAtimes = edau; 
    catch
        disp('Cannot save actigraphy data (Line 381)')
    end
    try
        s.velRS_Pxx = velRS_Pxx; s.velRS_fxx = velRS_fxx; 
        s.velRS_Pxx_0to1Hz = velRS_pxx_0to1Hz; s.velRS_Pxx_1to2Hz = velRS_pxx_1to2Hz; s.velRS_Pxx_2to3Hz = velRS_pxx_2to3Hz; s.velRS_Pxx_3to4Hz = velRS_pxx_3to4Hz; s.velRS_Pxx_4to5Hz = velRS_pxx_4to5Hz;
        s.velRS_Pxx_5to6Hz = velRS_pxx_5to6Hz; s.velRS_Pxx_6to7Hz = velRS_pxx_6to7Hz; s.velRS_Pxx_7to8Hz = velRS_pxx_7to8Hz; s.velRS_Pxx_8to9Hz = velRS_pxx_8to9Hz; s.velRS_Pxx_9to10Hz = velRS_pxx_9to10Hz;
        s.velRS_Pxx_10to11Hz = velRS_pxx_10to11Hz; s.velRS_Pxx_11to12Hz = velRS_pxx_11to12Hz; s.velRS_Pxx_12to13Hz = velRS_pxx_12to13Hz; s.velRS_Pxx_13to14Hz = velRS_pxx_13to14Hz; s.velRS_Pxx_14to15Hz = velRS_pxx_14to15Hz;
    catch
        disp('Cannot save actigraphy data (Line 390)')
    end  

    % Save the structure to a MAT file
    disp('Saving MAT files...')
    try
        save([dir01 'actigraphy/processed/ExtractedData.mat'],'s','-v7.3');
    catch
        disp('Unable to save data (Line 400)')
    end
    
    
    % Create CSV files, with one CSV per hour
    % Header
    disp('Saving CSV files...')
    header = {'ACTIVITY','TEMP','EDA','ACCEL.','ACCEL. PSD 0-1 Hz','ACCEL. PSD 1-2 Hz','ACCEL. PSD 2-3 Hz','ACCEL. PSD 3-4 Hz','ACCEL. PSD 4-5 Hz','ACCEL. PSD 5-6 Hz','ACCEL. PSD 6-7 Hz','ACCEL. PSD 7-8 Hz','ACCEL. PSD 8-9 Hz','ACCEL. PSD 9-10 Hz','ACCEL. PSD 10-11 Hz','ACCEL. PSD 11-12 Hz','ACCEL. PSD 12-13 Hz','ACCEL. PSD 13-14 Hz','ACCEL. PSD 14-15 Hz'};
    try
        daymin = min(s.EDAtimes{2}); daymax = max(s.EDAtimes{2});
        for q = 1:length(s.EDAtimes{1})
            for k = daymin:daymax
                % Extract values
                acc = squeeze(s.ACCvar(q,k,:,:)); logacc = log(acc);
                temp = squeeze(s.TEMPmean(q,k,:,:)); temp(temp>40) = NaN; temp(temp<25) = NaN;
                eda = squeeze(s.EDAmean(q,k,:,:)); eda(eda>30) = NaN; eda = log(eda);
                rc = squeeze(s.RCinterp_min(1,q,k,:,:));

                % Extract the values for the PSD data
                acc_PSD_0to1Hz = log(squeeze(s.velRS_Pxx_0to1Hz(q,k,:,:))); acc_PSD_1to2Hz = log(squeeze(s.velRS_Pxx_1to2Hz(q,k,:,:))); acc_PSD_2to3Hz = log(squeeze(s.velRS_Pxx_2to3Hz(q,k,:,:))); acc_PSD_3to4Hz = log(squeeze(s.velRS_Pxx_3to4Hz(q,k,:,:))); acc_PSD_4to5Hz = log(squeeze(s.velRS_Pxx_4to5Hz(q,k,:,:)));
                acc_PSD_5to6Hz = log(squeeze(s.velRS_Pxx_5to6Hz(q,k,:,:))); acc_PSD_6to7Hz = log(squeeze(s.velRS_Pxx_6to7Hz(q,k,:,:))); acc_PSD_7to8Hz = log(squeeze(s.velRS_Pxx_7to8Hz(q,k,:,:))); acc_PSD_8to9Hz = log(squeeze(s.velRS_Pxx_8to9Hz(q,k,:,:))); acc_PSD_9to10Hz = log(squeeze(s.velRS_Pxx_9to10Hz(q,k,:,:)));
                acc_PSD_10to11Hz = log(squeeze(s.velRS_Pxx_10to11Hz(q,k,:,:))); acc_PSD_11to12Hz = log(squeeze(s.velRS_Pxx_11to12Hz(q,k,:,:))); acc_PSD_12to13Hz = log(squeeze(s.velRS_Pxx_12to13Hz(q,k,:,:))); acc_PSD_13to14Hz = log(squeeze(s.velRS_Pxx_13to14Hz(q,k,:,:))); acc_PSD_14to15Hz = log(squeeze(s.velRS_Pxx_14to15Hz(q,k,:,:)));


                % Rescale all data on a scale from 0 to 1 for ease of plotting
                logacc = (logacc - min(min(logacc)))./abs(max(max(logacc) - min(min(logacc))));
                temp = (temp - min(min(temp)))./abs(max(max(temp) - min(min(temp))));
                eda = (eda - min(min(eda)))./abs(max(max(eda) - min(min(eda))));
                rc = (rc - min(min(rc)))./abs(max(max(rc) - min(min(rc))));
                accPSDmin = min([min(min(acc_PSD_0to1Hz)) min(min(acc_PSD_1to2Hz)) min(min(acc_PSD_2to3Hz)) min(min(acc_PSD_3to4Hz)) min(min(acc_PSD_4to5Hz)) min(min(acc_PSD_5to6Hz)) min(min(acc_PSD_6to7Hz)) min(min(acc_PSD_7to8Hz)) min(min(acc_PSD_8to9Hz)) min(min(acc_PSD_9to10Hz)) min(min(acc_PSD_10to11Hz)) min(min(acc_PSD_11to12Hz)) min(min(acc_PSD_12to13Hz)) min(min(acc_PSD_13to14Hz)) min(min(acc_PSD_14to15Hz))]);
                accPSDmax = max([max(max(acc_PSD_0to1Hz)) max(max(acc_PSD_1to2Hz)) max(max(acc_PSD_2to3Hz)) max(max(acc_PSD_3to4Hz)) max(max(acc_PSD_4to5Hz)) max(max(acc_PSD_5to6Hz)) max(max(acc_PSD_6to7Hz)) max(max(acc_PSD_7to8Hz)) max(max(acc_PSD_8to9Hz)) max(max(acc_PSD_9to10Hz)) max(max(acc_PSD_10to11Hz)) max(max(acc_PSD_11to12Hz)) max(max(acc_PSD_12to13Hz)) max(max(acc_PSD_13to14Hz)) max(max(acc_PSD_14to15Hz))]);
                acc_PSD_0to1Hz = (acc_PSD_0to1Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_1to2Hz = (acc_PSD_1to2Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_2to3Hz = (acc_PSD_2to3Hz - accPSDmin)./abs(accPSDmax - accPSDmin);
                acc_PSD_3to4Hz = (acc_PSD_3to4Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_4to5Hz = (acc_PSD_4to5Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_5to6Hz = (acc_PSD_5to6Hz - accPSDmin)./abs(accPSDmax - accPSDmin); 
                acc_PSD_6to7Hz = (acc_PSD_6to7Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_7to8Hz = (acc_PSD_7to8Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_8to9Hz = (acc_PSD_8to9Hz - accPSDmin)./abs(accPSDmax - accPSDmin);
                acc_PSD_9to10Hz = (acc_PSD_9to10Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_10to11Hz = (acc_PSD_10to11Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_11to12Hz = (acc_PSD_11to12Hz - accPSDmin)./abs(accPSDmax - accPSDmin);
                acc_PSD_12to13Hz = (acc_PSD_12to13Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_13to14Hz = (acc_PSD_13to14Hz - accPSDmin)./abs(accPSDmax - accPSDmin); acc_PSD_14to15Hz = (acc_PSD_14to15Hz - accPSDmin)./abs(accPSDmax - accPSDmin);

                if s.EDAtimes{1}(q)-s.EDAtimes{1}(1)+1 < 10
                    month0 = ['0' num2str(s.EDAtimes{1}(q)-s.EDAtimes{1}(1)+1)];
                else
                    month0 = num2str(s.EDAtimes{1}(q)-s.EDAtimes{1}(1)+1);
                end
                
                for l = 1:24

                    % Make directory where CSVs will be saved
                    try
                        warning off
                        mkdir([dir01 'actigraphy/processed/binned-hour/'])
                    catch
                    end
                    
                    % Combine into one array
                    mat = [rc(l,:); temp(l,:); eda(l,:); logacc(l,:); acc_PSD_0to1Hz(l,:); acc_PSD_1to2Hz(l,:); acc_PSD_2to3Hz(l,:);  acc_PSD_3to4Hz(l,:);  acc_PSD_4to5Hz(l,:);  acc_PSD_5to6Hz(l,:);  acc_PSD_6to7Hz(l,:);  acc_PSD_7to8Hz(l,:);  acc_PSD_8to9Hz(l,:);  acc_PSD_9to10Hz(l,:);  acc_PSD_10to11Hz(l,:);  acc_PSD_11to12Hz(l,:);  acc_PSD_12to13Hz(l,:);  acc_PSD_13to14Hz(l,:);  acc_PSD_14to15Hz(l,:);  ];
                    
                    if isnan(nanmean(nanmean(mat))) == 0 
                        if k-daymin+1<10
                            day0 = ['0' num2str(k-daymin+1)];
                        else
                            day0 = num2str(k-daymin+1);
                        end
                        
                        if l-1 >= 10
                            % Write to CSV
                            disp([dir01 'actigraphy/processed/binned-hour/' 'DIA_' s.Patient '_annot_embrace' '_all_accPSDdf1Hz' '_month' month0 '_day' day0 '_hour' num2str(l-1) '.csv'])
                            csvwrite_with_headers([dir01 'actigraphy/processed/binned-hour/' 'DIA_' s.Patient '_annot_embrace' '_all_accPSDdf1Hz' '_month' month0 '_day' day0 '_hour' num2str(l-1) '.csv'],mat',header);
                        else
                            disp([dir01 'actigraphy/processed/binned-hour/' 'DIA_' s.Patient '_annot_embrace' '_all_accPSDdf1Hz' '_month' month0 '_day' day0 '_hour0' num2str(l-1) '.csv'])     
                            csvwrite_with_headers([dir01 'actigraphy/processed/binned-hour/' 'DIA_' s.Patient '_annot_embrace' '_all_accPSDdf1Hz' '_month' month0 '_day' day0 '_hour0' num2str(l-1) '.csv'],mat',header);
                        end
                    end
                end
                
            end
        end
    catch
        disp('Unable to output to CSV (Line 410)')
    end
    disp('Complete.')   
end    

function [r,c,V] = findnearest(srchvalue,srcharray,bias)
    if nargin<2
        error('Need two inputs: Search value and search array')
    elseif nargin<3
        bias = 0;
    end
    srcharray = srcharray-srchvalue;
    if bias == -1      
        srcharray(srcharray>0) =inf;        
    elseif bias == 1    
        srcharray(srcharray<0) =inf;        
    end

    if nargout==1 || nargout==0   
        if all(isinf(srcharray(:)))
            r = [];
        else
            r = find(abs(srcharray)==min(abs(srcharray(:))));
        end        
    elseif nargout>1
        if all(isinf(srcharray(:)))
            r = [];c=[];
        else
            [r,c] = find(abs(srcharray)==min(abs(srcharray(:))));
        end   
        if nargout==3
            V = srcharray(r,c)+srchvalue;
        end
    end
end

function csvwrite_with_headers(filename,m,headers,r,c)
    if ~ischar(filename)
        error('FILENAME must be a string');
    end
    if nargin < 4
        r = 0;
    end
    if nargin < 5
        c = 0;
    end
    if ~iscellstr(headers)
        error('Header must be cell array of strings')
    end

    if length(headers) ~= size(m,2)
        error('number of header entries must match the number of columns in the data')
    end
    header_string = headers{1};
    for i = 2:length(headers)
        header_string = [header_string,',',headers{i}];
    end
    if r>0
        for i=1:r
            header_string = [',',header_string];
        end
    end
    fid = fopen(filename,'w');
    fprintf(fid,'%s\r\n',header_string);
    fclose(fid);
    dlmwrite(filename, m,'-append','delimiter',',','roffset', r,'coffset',c);
end

function y = year(d,f) 
    if nargin < 1 
      error(message('finance:year:missingInputs')) 
    end 
    if nargin < 2
      f = '';
    end
    tFlag = false;   %Keep track if input was character array 
    if ischar(d) 
      d = datenum(d,f); 
      tFlag = true;
    end 
    % Generate date vectors
    if nargin < 2 || tFlag
      c = datevec(d(:));
    else
      c = datevec(d(:),f);
    end
    y = c(:,1);             % Extract years  
    if ~ischar(d) 
      y = reshape(y,size(d)); 
    end 
end

function [n, m] = month(d,f)
    if nargin < 1
        error(message('finance:month:missingInput'))
    end
    if nargin < 2
      f = '';
    end
    tFlag = false;   %Keep track if input was character array 
    if ischar(d)
        d = datenum(d,f);
        tFlag = true;
    end
    % Generate date vectors
    if nargin < 2  || tFlag
      c = datevec(d(:));
    else
      c = datevec(d(:),f);
    end
    % Monthly strings
    mths = ['NaN';'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul'; ...
        'Aug';'Sep';'Oct';'Nov';'Dec'];

    % Extract numeric months
    n = c(:, 2);

    % Keep track of nan values.
    nanLoc = isnan(n);

    % Extract monthly strings. (c(:, 2) == 0) handles the case when d = 0.
    mthIdx = c(:, 2) + (c(:, 2) == 0);
    mthIdx(nanLoc) = 0;
    m = mths(mthIdx + 1, :);

    % Preserve the dims of the inputs for n. m is a char array so it should be
    % column oriented.
    if ~ischar(d)
        n = reshape(n, size(d));
    end
end

function dom = day(d,f) 
    if nargin < 1 
      error(message('finance:day:missingInputs')) 
    end 
    if nargin < 2
      f = '';
    end
    tFlag = false;   %Keep track if input was character array 
    if ischar(d)
        d = datenum(d,f);
        tFlag = true;
    end
    % Generate date vectors
    if nargin < 2  || tFlag
      c = datevec(d(:));
    else
      c = datevec(d(:),f);
    end
    dom = c(:,3);            % Extract day of month 
    if ~ischar(d) 
      dom = reshape(dom,size(d)); 
    end
end

function h = hour(d,f) 
    if nargin < 1 
      error(message('finance:hour:missingInputs')) 
    end 
    if nargin < 2
      f = '';
    end
    tFlag = false;   %Keep track if input was character array 
    if ischar(d)
        d = datenum(d,f);
        tFlag = true;
    end
    % Generate date vectors
    if nargin < 2  || tFlag
      c = datevec(d(:));
    else
      c = datevec(d(:),f);
    end
    h = c(:,4);     % Extract hour 
    if ~ischar(d) 
      h = reshape(h,size(d)); 
    end
end

function m = minute(d,f)
    if nargin < 1
       error(message('finance:minute:missingInputs'))
    end
    if nargin < 2
      f = '';
    end
    if ischar(d) 
       d = datenum(d,f);
       sizeD = size(d); 
    elseif iscell(d)
       sizeD = size(d);   
       d = datenum(d(:),f);
    elseif isnumeric(d)
       sizeD = size(d); 
    else
       error(message('finance:minute:invalidInputClass'))
    end
    % Generate date vectors from dates
    c = datevecmx(d(:), 1);
    % Extract minute
    m = c(:, 5);
    % Reshape into the correct dims
    m = reshape(m, sizeD);
end

function s = second(d,f)
    if nargin < 1
       error(message('finance:second:missingInputs'))
    end
    if nargin < 2
      f = '';
    end
    if ischar(d)
       d = datenum(d,f);
       sizeD = size(d);
    elseif iscell(d)
       sizeD = size(d);
       d = datenum(d(:),f);
    elseif isnumeric(d)
       sizeD = size(d);
    else
       error(message('finance:second:invalidInputClass'))
    end
end

