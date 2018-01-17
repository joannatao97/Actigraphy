function [s] = extractRawActData(dir01, patientstoanalyse)
%
% Actigraphy QC Analysis
% ----------------------
% ABOUT: This software performs a user-guided assessment of wrist
% actigraphy data. 
%
% USE: manualactigraphyQC()
%       (1) The program will first ask for a directory in str format. Choose
%       the parent directory in which all patients are listed.
%       e.g. '~/Baker/Actigraphy/' or '~/Baker/Actigraphy'
%       (2) Select a time window.
%       (3) Select a type of transition (still, slow, moderate, or
%       vigorous). A list of associated transitions from the REDCap data
%       will then be displayed. Choose an appropriate transition.
%
% ----------------------
% Author: Joshua D. Salvi
% josh.salvi@gmail.com
% ----------------------
%
    
    if dir01(end) ~= '/'
            dir01 = [dir01 '/'];
        end
    q=1;
    files0 = dir(dir01);
    for j = 1:length(files0)
        if length(files0(j).name) == 5
            patients{q} = files0(j).name;
            q = q + 1;
        end
    end
    
%     for patientChoice = 1:1 %length(patients)
    for patientChoice = patientstoanalyse
        
        dir0 = [dir01 patients{patientChoice} '/'];

        dir0Act = [dir0 'actigraphy/raw/'];
        dir0RC = [dir0 'redcap/raw/'];

        pp = 1;
        pp0 = 0;
        
        files = dir(dir0Act);
        
        disp(['Patient ' patients{patientChoice}]);
        disp('Importing...')
        
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
                disp('Error: Raw files not found.');
            end
        end
        
        files = dir(dir0RC);
        for p0 = 1:length(files)
            try
                if isempty(findstr(files(p0).name,'change_state_motion')) == 0
                    disp(files(p0).name)
                    data = importdata([dir0RC files(p0).name]); RCraw = data.data; RCrawTS = data.textdata(:,5);
                end
            catch
                disp('Error: REDCap files not found.');
            end
        end
        
        % Convert UNIX time in ms to MATLAB time
        unix_epoch = datenum(1970,1,1,-4,0,0);
        acc(:,1) = acc(:,1)./86400./1e3 + unix_epoch;
        temp(:,1) = temp(:,1)./86400./1e3 + unix_epoch;
        eda(:,1) = eda(:,1)./86400./1e3 + unix_epoch;
        
        % Extract month, day, hour, and minute from the RC data
        for p0 = 1:length(RCrawTS)
            try
                warning off
                RCdate(p0,:,:,:,:) = [month(RCrawTS{p0}), day(RCrawTS{p0}), hour(RCrawTS{p0}), minute(RCrawTS{p0})];
            end
        end
        
        % Time stamps from actigraphy data
        accdate = [month(acc(:,1))'; day(acc(:,1))'; hour(acc(:,1))'; minute(acc(:,1))'];
        tempdate = [month(temp(:,1))'; day(temp(:,1))'; hour(temp(:,1))'; minute(temp(:,1))'];
        edadate = [month(eda(:,1))'; day(eda(:,1))'; hour(eda(:,1))'; minute(eda(:,1))'];
        
        % Find the unique values
        accu = [{unique(accdate(1,:))}; {unique(accdate(2,:))}; {unique(accdate(3,:))}; {unique(accdate(4,:))}];
        tempu = [{unique(tempdate(1,:))}; {unique(tempdate(2,:))}; {unique(tempdate(3,:))}; {unique(tempdate(4,:))}];
        edau = [{unique(edadate(1,:))}; {unique(edadate(2,:))}; {unique(edadate(3,:))}; {unique(edadate(4,:))}];
        RCdate = RCdate'; RCu = [{unique(RCdate(1,:))}; {unique(RCdate(2,:))}; {unique(RCdate(3,:))}; {unique(RCdate(4,:))}];
        
        
        disp('ACC extraction...')
        monthsmax = max([length(accu{1}) length(tempu{1}) length(edau{1}) length(RCu{1})]);
        daysmax = max([length(accu{2}) length(tempu{2}) length(edau{2}) length(RCu{2})]);
        velRSmax = NaN([monthsmax, 31, 24]);
        velRSvar = velRSmax; velRSmean = velRSmax;
        for j = 1:length(accu{1})
            for k = 1:length(accu{2})
                for l = 1:length(accu{3})
                        try
                        a = intersect(find(accdate(1,:)==accu{1}(j)),find(accdate(2,:)==accu{2}(k)));
                        b = find(accdate(3,:)==accu{3}(l));
                        c = intersect(a,b);
                        displ = sqrt(gradient(acc(c,2)).^2 + gradient(acc(c,3)).^2 + gradient(acc(c,4)).^2);
                        vel = gradient(displ);
                        velRS = sqrt(vel.^2);
                        
                        velRSmax(j,accu{2}(k),accu{3}(l)+1) = nanmax(velRS);
                        velRSmean(j,accu{2}(k),accu{3}(l)+1) = nanmean(velRS);
                        velRSvar(j,accu{2}(k),accu{3}(l)+1) = nanvar(velRS);
                        
                        catch
                            velRSmax(j,accu{2}(k),accu{3}(l)+1) = NaN;
                            velRSmean(j,accu{2}(k),accu{3}(l)+1) = NaN;
                            velRSvar(j,accu{2}(k),accu{3}(l)+1) = NaN;
                        end
                end
            end
        end
        
        
        disp('TEMP extraction...')
        tempmax = NaN([monthsmax, 31, 24]);
        tempvar = tempmax; tempmean = tempmax;
        for j = 1:length(tempu{1})
            for k = 1:length(tempu{2})
                for l = 1:length(tempu{3})
                        try
                        a = intersect(find(tempdate(1,:)==tempu{1}(j)),find(tempdate(2,:)==tempu{2}(k)));
                        b = find(tempdate(3,:)==tempu{3}(l));
                        c = intersect(a,b);
                        
                        tempmax(j,tempu{2}(k),tempu{3}(l)+1) = nanmax(temp(c,2));
                        tempmean(j,tempu{2}(k),tempu{3}(l)+1) = nanmean(temp(c,2));
                        tempvar(j,tempu{2}(k),tempu{3}(l)+1) = nanvar(temp(c,2));
                        
                        catch
                            tempmax(j,tempu{2}(k),tempu{3}(l)+1) = NaN;
                            tempmean(j,tempu{2}(k),tempu{3}(l)+1) = NaN;
                            tempvar(j,tempu{2}(k),tempu{3}(l)+1) = NaN;
                        end
                end
            end
        end
        
        disp('EDA extraction...')
        edamax = NaN([monthsmax, 31, 24]);
        edavar = edamax; edamean = edamax;
        for j = 1:length(edau{1})
            for k = 1:length(edau{2})
                for l = 1:length(edau{3})
                        try
                        a = intersect(find(edadate(1,:)==edau{1}(j)),find(edadate(2,:)==edau{2}(k)));
                        b = find(edadate(3,:)==edau{3}(l));
                        c = intersect(a,b);
                        
                        edamax(j,edau{2}(k),edau{3}(l)+1) = nanmax(eda(c,2));
                        edamean(j,edau{2}(k),edau{3}(l)+1) = nanmean(eda(c,2));
                        edavar(j,edau{2}(k),edau{3}(l)+1) = nanvar(eda(c,2));
                        
                        catch
                            edamax(j,edau{2}(k),edau{3}(l)+1) = NaN;
                            edamean(j,edau{2}(k),edau{3}(l)+1) = NaN;
                            edavar(j,edau{2}(k),edau{3}(l)+1) = NaN;
                        end
                end
            end
        end
        %}
        
        disp('RC extraction...')
        RCmax = NaN([monthsmax, 31, 24]);
        RCvar = RCmax; RCmean = RCmax;
        for j = 1:length(RCu{1})
            for k = 1:length(RCu{2})
                for l = 1:length(RCu{3})
                        try
                        a = intersect(find(RCdate(1,:)==RCu{1}(j)),find(RCdate(2,:)==RCu{2}(k)));
                        b = find(RCdate(3,:)==RCu{3}(l));
                        c = intersect(a,b);
                        
                        RCmax(j,RCu{2}(k),RCu{3}(l)+1) = nanmax(RCraw(c));
                        RCmean(j,RCu{2}(k),RCu{3}(l)+1) = nanmean(RCraw(c));
                        RCvar(j,RCu{2}(k),RCu{3}(l)+1) = nanvar(RCraw(c));
                        
                        catch
                            RCmax(j,RCu{2}(k),RCu{3}(l)+1) = NaN;
                            RCmean(j,RCu{2}(k),RCu{3}(l)+1) = NaN;
                            RCvar(j,RCu{2}(k),RCu{3}(l)+1) = NaN;
                        end
                end
            end
        end
        
        s{patientChoice}.Patient = patients{patientChoice};
        s{patientChoice}.ACCmean = velRSmean; s{patientChoice}.ACCmax = velRSmax; s{patientChoice}.ACCvar = velRSvar;
        s{patientChoice}.TEMPmean = tempmean; s{patientChoice}.TEMPmax = tempmax; s{patientChoice}.TEMPvar = tempvar;
        s{patientChoice}.EDAmean = edamean; s{patientChoice}.EDAmax = edamax; s{patientChoice}.EDAvar = edavar;
        s{patientChoice}.RCmean = RCmean; s{patientChoice}.RCmax = RCmax; s{patientChoice}.RCvar = RCvar;
        s{patientChoice}.ACCtimes = accu; s{patientChoice}.TEMPtimes = tempu; s{patientChoice}.EDAtimes = edau; 
        s{patientChoice}.RCtimes = RCu;
        
        [s{patientChoice}.ACCdista s{patientChoice}.ACCdistb] = hist(velRS, freedmandiaconis(velRS));
        [s{patientChoice}.RCdista s{patientChoice}.RCdistb] = hist(RCraw, freedmandiaconis(RCraw));
        [s{patientChoice}.TEMPdista s{patientChoice}.TEMPdistb] = hist(temp(:,2), freedmandiaconis(temp(:,2)));
        [s{patientChoice}.EDAdista s{patientChoice}.EDAdistb] = hist(eda(:,2), freedmandiaconis(eda(:,2)));
    
        clear velRSmean velRSmax velRSvar tempmean tempmax tempvar edamean edamax edavar RCmean RCmax RCvar
        
        
    end
    
end
