function [s] = extractRawActData(dir01, tz)
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
%       time zone as either EDT or EST, where tz equals UTC-4 or UTC-5 in
%       either case. By default, tz = -4.
%
% ----------------------
% Author: Joshua D. Salvi
% josh.salvi@gmail.com
% ----------------------
%
    
    if dir01(end) ~= '/'
        dir01 = [dir01 '/'];
    end
    
    clear RCvals acc temp eda data RCraw RCrawTS velRS RCstate RCdate RCu
    dir0Act = [dir01 'actigraphy/raw/'];

    files = dir(dir0Act);

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

    dir0RC = [dir01 'redcap/processed/'];
    files = dir(dir0RC);
    for p0 = 1:length(files)
        try
            if isempty(findstr(files(p0).name,'_events_trans.csv')) == 0
                data = importdata([dir0RC files(p0).name]);
                try
                    RCraw = data.data; RCrawTS = data.textdata(:,5);
                catch
                end
                try
                    RCraw = data; RCrawTS = data.textdata(:,5);
                catch
                end
            end
        catch

        end      
    end

    % Convert UNIX time in ms to MATLAB time
    if exist('tz') == 0
        tz = -4;
    end
    try
        unix_epoch = datenum(1970,1,1,tz,0,0);
        acc(:,1) = acc(:,1)./86400./1e3 + unix_epoch;
        temp(:,1) = temp(:,1)./86400./1e3 + unix_epoch;
        eda(:,1) = eda(:,1)./86400./1e3 + unix_epoch;
    catch
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
    catch
    end

    try
        RCdate = RCdate';
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];
        RCvals = NaN(length(RCu{1}), length(RCu{2}), 31, 24, 60, 60);
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];        
    catch
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
    end
    
    try
        RCvals(RCvals==0) = NaN;
        RCvals = RCvals(1:length(RCu{1}),1:length(RCu{2}),:,:,:,:);
        RCvals_min = nanmean(RCvals,6);
        s.RCinterp = RCvals;
        s.RCu = RCu;
        s.RCinterp_min = RCvals_min;
    catch
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
        velRS_pxx_0to5Hz = velRSmax;
        velRS_pxx_5to10Hz = velRSmax;
        velRS_pxx_10to15Hz = velRSmax;
        velRS_Pxx = cell([monthsmax, 31, 24, 60]);
        velRS_fxx = cell([monthsmax, 31, 24, 60]);
    catch
    end
    try
        for j = 1:length(accu{1})
            for k = 1:length(accu{2})
                for l = 1:length(accu{3})
                    for m = 1:length(accu{4}) 
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
    catch
    end

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
    end

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
    end

    try
        s.Patient = patients;
        s.ACCmean = velRSmean; s.ACCmax = velRSmax; s.ACCvar = velRSvar;
        s.TEMPmean = tempmean; s.TEMPmax = tempmax; s.TEMPvar = tempvar;
        s.EDAmean = edamean; s.EDAmax = edamax; s.EDAvar = edavar;
        s.ACCtimes = accu; s.TEMPtimes = tempu; s.EDAtimes = edau; 
    catch
    end
    try
        s.velRS_Pxx = velRS_pxx; s.velRS_fxx = velRS_fxx;
        s.velRS_Pxx_0to5Hz = velRS_pxx_0to5Hz;
        s.velRS_Pxx_5to10Hz = velRS_pxx_5to10Hz;
        s.velRS_Pxx_10to15Hz = velRS_pxx_10to15Hz;
    catch
    end  
    
    % Save the MAT file
    try
        save([dir01 'ExtractedData.mat'],'s','-v7.3');
    catch
    end
    
    
    % Create CSV files
    header = {'annot','acc PSD 0-5 Hz','acc PSD 5-10 Hz','acc PSD 10-15 Hz','acc dRMS','eda','temp'};
    try
        daymin = min(s.EDAtimes{2}); daymax = max(s.EDAtimes{2});
        for q = 1:length(s.EDAtimes{1})
            for k = daymin:daymax
                % Extract values
                acc = squeeze(s.ACCvar(q,k,:,:)); logacc = log(acc);
                temp = squeeze(s.TEMPmean(q,k,:,:)); temp(temp>40) = NaN; temp(temp<25) = NaN;
                eda = squeeze(s.EDAmean(q,k,:,:)); eda(eda>30) = NaN; eda = log(eda);
                rc = squeeze(s.RCinterp_min(1,q,k,:,:));

                % acc PSD
                acc_PSD_0to5Hz = log(squeeze(s.velRS_Pxx_0to5Hz(q,k,:,:)));
                acc_PSD_5to10Hz = log(squeeze(s.velRS_Pxx_5to10Hz(q,k,:,:)));
                acc_PSD_10to15Hz = log(squeeze(s.velRS_Pxx_10to15Hz(q,k,:,:)));

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

                if s.EDAtimes{1}(q)-s.EDAtimes{1}(1)+1 < 10
                    month0 = ['0' num2str(s.EDAtimes{1}(q)-s.EDAtimes{1}(1)+1)];
                else
                    month0 = num2str(s.EDAtimes{1}(q)-s.EDAtimes{1}(1)+1);
                end
                
                for l = 1:24
                    try
                        warning off
                        mkdir([dir01 'CSV/'])
                    catch
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
                            csvwrite_with_headers([dir01 'CSV/' s.Patient '/' 'DIA_' s.Patient '_annot_embrace' '_month' month0 '_day' day0 '_hour' num2str(l-1) '.csv'],mat',header);
                        else
                            csvwrite_with_headers([dir01 'CSV/' s.Patient '/' 'DIA_' s.Patient '_annot_embrace' '_month' month0 '_day' day0 '_hour0' num2str(l-1) '.csv'],mat',header);

                        end
                    end
                end
                
            end
        end
    catch
    end   
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

if nargout==1 | nargout==0   
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
