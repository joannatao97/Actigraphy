function [s] = extractRawActData3(dir01, patientstoanalyse, dir2, loadfile, RConly)
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
% josh.salvi@gmail.comx
% ----------------------
%
    if exist('RConly') == 0
        RConly = 0;
    end
    try
        disp('Loading previous data...')
        load(loadfile)
        disp('Loaded.')
    end
    
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
        clear RCvals acc temp eda data RCraw RCrawTS velRS RCstate RCdate RCu
        dir0 = [dir01 patients{patientChoice} '/'];
        dir0Act = [dir0 'actigraphy/raw/'];
        
        pp = 1;
        pp0 = 0;
        
        files = dir(dir0Act);
        
        disp(['Patient ' patients{patientChoice}]);
        disp('Importing...')
        
        if RConly == 0
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
        end
        
        dir0 = [dir01 patients{patientChoice} '/'];
        dir0RC = [dir0 'redcap/processed/'];
        files = dir(dir0RC);
        for p0 = 1:length(files)
            try
                if isempty(findstr(files(p0).name,'_events_trans.csv')) == 0
                    disp(['Importing ' files(p0).name])
                    data = importdata([dir0RC files(p0).name]);
                    
                    try
                        RCraw = data.data; RCrawTS = data.textdata(:,5);
                    end
                    try
                        RCraw = data; RCrawTS = data.textdata(:,5);
                    end
                end
            catch
                
            end      
        end
        
        % Convert UNIX time in ms to MATLAB time
        if RConly == 0
        try
        unix_epoch = datenum(1970,1,1,-4,0,0);
        acc(:,1) = acc(:,1)./86400./1e3 + unix_epoch;
        temp(:,1) = temp(:,1)./86400./1e3 + unix_epoch;
        eda(:,1) = eda(:,1)./86400./1e3 + unix_epoch;
        
%         unix_epoch = datenum(1970,1,1,0,0,0);
%         disp('Converting times...')
%         disp('...acc...')
%         for j = 1:size(acc,1)
%             acc(j,1) = acc(j,1)./86400./1e3 + unix_epoch;
%             acc(j,1) = TimezoneConvert(acc(j,1),'UTC','America/New_York');
%         end
%         disp('...temp...')
%         for j = 1:size(temp,1)
%             temp(j,1) = temp(j,1)./86400./1e3 + unix_epoch;
%             acc(j,1) = TimezoneConvert(temp(j,1),'UTC','America/New_York');
%         end
%         disp('...eda...');
%         for j = 1:size(eda,1)
%             eda(j,1) = eda(j,1)./86400./1e3 + unix_epoch;
%             eda(j,1) = TimezoneConvert(eda(j,1),'UTC','America/New_York');
%         end
%         disp('Complete.')
        end
        end
        
        p0=1;
        try
        for j = 2:length(data)
            try
                RCrawTS{p0} = data{j}(7:25);
                RCdate(p0,:,:,:,:,:,:) = [year(RCrawTS{p0}), month(RCrawTS{p0}), day(RCrawTS{p0}), hour(RCrawTS{p0}), minute(RCrawTS{p0}), second(RCrawTS{p0})];
                RCstate{p0} = data{j}(27:end);
                p0 = p0+1;
            end
        end
        end
        try
        RCdate = RCdate';
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];
        RCvals = NaN(length(RCu{1}), length(RCu{2}), 31, 24, 60, 60);
        end
        try
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];        
        end
        
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
                end
            end
        end
        end
        try
            RCvals(RCvals==0) = NaN;
            RCvals = RCvals(1:length(RCu{1}),1:length(RCu{2}),:,:,:,:);
            RCvals_min = nanmean(RCvals,6);
            s{patientChoice}.RCinterp = RCvals;
            s{patientChoice}.RCu = RCu;
            s{patientChoice}.RCinterp_min = RCvals_min;
        end
        
        if RConly == 0
        % Time stamps from actigraphy data
        try
        accdate = [month(acc(:,1))'; day(acc(:,1))'; hour(acc(:,1))'; minute(acc(:,1))'];
        tempdate = [month(temp(:,1))'; day(temp(:,1))'; hour(temp(:,1))'; minute(temp(:,1))'];
        edadate = [month(eda(:,1))'; day(eda(:,1))'; hour(eda(:,1))'; minute(eda(:,1))'];
        
        % Find the unique values
        accu = [{unique(accdate(1,:))}; {unique(accdate(2,:))}; {unique(accdate(3,:))}; {unique(accdate(4,:))}];
        tempu = [{unique(tempdate(1,:))}; {unique(tempdate(2,:))}; {unique(tempdate(3,:))}; {unique(tempdate(4,:))}];
        edau = [{unique(edadate(1,:))}; {unique(edadate(2,:))}; {unique(edadate(3,:))}; {unique(edadate(4,:))}];        
        end
        disp('ACC extraction...')
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
        velRSmax = NaN([monthsmax, 31, 24, 60]);
        velRSvar = velRSmax; velRSmean = velRSmax;
        velRS_pxx_0to5Hz = velRSmax;
        velRS_pxx_5to10Hz = velRSmax;
        velRS_pxx_10to15Hz = velRSmax;
        velRS_Pxx = cell([monthsmax, 31, 24, 60]);
        velRS_fxx = cell([monthsmax, 31, 24, 60]);
        ind = 0; nn = 0;
        indall = length(accu{1})*length(accu{2})*length(accu{3})*length(accu{4});
        bar = '                    ';
        end
        try
        for j = 1:length(accu{1})
            for k = 1:length(accu{2})
                for l = 1:length(accu{3})
                    for m = 1:length(accu{4}) 
                        if floor(ind/indall*100) > 0 && mod(ind/indall*100,5) == 0
                            try
                                bar(1:ind/indall*100/5) = '='; nn = nn+1;
                                disp(['Progress: [' bar '] ' num2str(ind/indall*100) '% complete']);
                            end
                        elseif floor(ind/indall*100) == 0 && nn == 0
                            try
                                nn = 1;
                                disp(['Progress: [' bar '] ' num2str(ind/indall*100) '% complete']);
                            end
                        end
                        
                        try
                        a = intersect(find(accdate(1,:)==accu{1}(j)),find(accdate(2,:)==accu{2}(k)));
                        b = intersect(find(accdate(3,:)==accu{3}(l)),find(accdate(4,:)==accu{4}(m)));
                        c = intersect(a,b);
                        displ = sqrt(gradient(acc(c,2)).^2 + gradient(acc(c,3)).^2 + gradient(acc(c,4)).^2);
                        vel = gradient(displ);
                        velRS = sqrt(vel.^2);
                        
                        velRSmax(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = nanmax(velRS);
                        velRSmean(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = nanmean(velRS);
                        velRSvar(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = nanvar(velRS);
                        
                        Fs = 30; % Hz
                        [pxx, fxx] = pwelch(velRS,[],[],[],Fs);
                        n0 = findnearest(fxx, 5);n0=n0(1);
                        n1 = findnearest(fxx, 10);n1=n1(1);
                        velRS_pxx_0to5Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(1:n0-1),pxx(1:n0-1)));
                        velRS_pxx_5to10Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n0:n1-1),pxx(n0:n1-1)));
                        velRS_pxx_10to15Hz(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = abs(trapz(fxx(n1:end),pxx(n1:end)));
                        velRS_fxx{j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1} = fxx;
                        velRS_pxx{j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1} = pxx;
                        catch
                            velRSmax(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = NaN;
                            velRSmean(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = NaN;
                            velRSvar(j,accu{2}(k),accu{3}(l)+1,accu{4}(m)+1) = NaN;
                        end
                        ind = ind+1;
                    end
                end
            end
        end
        end
        
        try
        disp('TEMP extraction...')
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
        end
        
        try
        disp('EDA extraction...')
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
        end
        
        try
        s{patientChoice}.Patient = patients{patientChoice};
        s{patientChoice}.ACCmean = velRSmean; s{patientChoice}.ACCmax = velRSmax; s{patientChoice}.ACCvar = velRSvar;
        s{patientChoice}.TEMPmean = tempmean; s{patientChoice}.TEMPmax = tempmax; s{patientChoice}.TEMPvar = tempvar;
        s{patientChoice}.EDAmean = edamean; s{patientChoice}.EDAmax = edamax; s{patientChoice}.EDAvar = edavar;
        s{patientChoice}.ACCtimes = accu; s{patientChoice}.TEMPtimes = tempu; s{patientChoice}.EDAtimes = edau; 
        end
%         [s{patientChoice}.ACCdista s{patientChoice}.ACCdistb] = hist(velRS, freedmandiaconis(velRS));
%         [s{patientChoice}.RCdista s{patientChoice}.RCdistb] = hist(RCraw, freedmandiaconis(RCraw));
%         [s{patientChoice}.TEMPdista s{patientChoice}.TEMPdistb] = hist(temp(:,2), freedmandiaconis(temp(:,2)));
%         [s{patientChoice}.EDAdista s{patientChoice}.EDAdistb] = hist(eda(:,2), freedmandiaconis(eda(:,2)));
        try
        s{patientChoice}.velRS_Pxx = velRS_pxx; s{patientChoice}.velRS_fxx = velRS_fxx;
        s{patientChoice}.velRS_Pxx_0to5Hz = velRS_pxx_0to5Hz;
        s{patientChoice}.velRS_Pxx_5to10Hz = velRS_pxx_5to10Hz;
        s{patientChoice}.velRS_Pxx_10to15Hz = velRS_pxx_10to15Hz;
        end
        end
        
        clear velRSmean velRSmax velRSvar tempmean tempmax tempvar edamean edamax edavar RCmean RCmax RCvar
        if isempty('dir2') == 0
            save([dir2 'extractedActdata-all.mat'],'s','-v7.3');
        end
        
    end
    
end

function [ targetDST ] = TimezoneConvert( dn, fromTimezone, toTimezone )
%   Converts a datenum from a given timezone (e.g. 'UTC') to a daylight saving local time of another timezone (e.G. 'Europe/Paris').
%   Use TimeZone.getAvailableIDs for a complete list of supported timezones.
%   If a timezone parameter is wrong, it will be replaced by GMT.

    import java.lang.String
    import java.util.* java.awt.*
    import java.util.Enumeration

    t1 = GregorianCalendar(TimeZone.getTimeZone(fromTimezone));
    t1.set(year(dn), month(dn)-1, day(dn), hour(dn), minute(dn), second(dn))

    t2 = GregorianCalendar(TimeZone.getTimeZone(toTimezone));
    t2.setTimeInMillis(t1.getTimeInMillis());
    targetDST = rawjavacalendar2datenum(t2);
end

function [ matlabdatenum ] = rawjavacalendar2datenum( cal )
%   Converts a java.util.Calendar date local time into a Matlab datenum.
%   Keeps the original local time, does not try to convert to UTC.
    javaSerialDate = cal.getTimeInMillis() + cal.get(cal.ZONE_OFFSET) + cal.get(cal.DST_OFFSET);
    matlabdatenum = datenum([1970 1 1 0 0 javaSerialDate / 1000]);
end

