function [s] = extractRawRCData(dir01, patientstoanalyse, dir2, loadfile)
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

    try
        load(loadfile)
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
        
        dir0 = [dir01 patients{patientChoice} '/'];
        dir0RC = [dir0 'redcap/processed/'];
        files = dir(dir0RC);
        for p0 = 1:length(files)
            try
                if isempty(findstr(files(p0).name,'_events_trans.csv')) == 0
                    disp(['Importing ' files(p0).name])
                    data = importdata([dir0RC files(p0).name]);
                    
                    RCraw = data.data; RCrawTS = data.textdata(:,5);
                end
            catch
                
            end
            
            
        end
        
        p0=1;
        for j = 2:length(data)
            try
                RCrawTS{p0} = data{j}(7:25);
                RCdate(p0,:,:,:,:,:,:) = [year(RCrawTS{p0}), month(RCrawTS{p0}), day(RCrawTS{p0}), hour(RCrawTS{p0}), minute(RCrawTS{p0}), second(RCrawTS{p0})];
                RCstate{p0} = data{j}(27:end);
                p0 = p0+1;
            end
        end
        RCdate = RCdate';
        RCu = [{unique(RCdate(1,:))}, {unique(RCdate(2,:))}, {unique(RCdate(3,:))}, {unique(RCdate(4,:))}, {unique(RCdate(5,:))}, {unique(RCdate(6,:))}];
        RCvals = NaN(length(RCu{1}), length(RCu{2}), 31, 24, 60);
        
        for q = 1:length(RCstate)
            if isempty(findstr(RCstate{q},':still')) == 0
                try
                    if isempty(findstr(RCstate{q+1},'still:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q);
                    min1 = RCdate(5,q);
                    s1 = RCdate(6,q);
                    
                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1);
                    min2 = RCdate(5,q+1);
                    s2 = RCdate(6,q+1);
                    
                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 1;
                    end
                end
            elseif isempty(findstr(RCstate{q},':slow')) == 0
                try
                    if isempty(findstr(RCstate{q+1},'slow:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q);
                    min1 = RCdate(5,q);
                    s1 = RCdate(6,q);
                    
                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1);
                    min2 = RCdate(5,q+1);
                    s2 = RCdate(6,q+1);
                    
                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 2;
                    end
                end
            elseif isempty(findstr(RCstate{q},':moderate')) == 0
                try
                    if isempty(findstr(RCstate{q+1},'moderate:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q);
                    min1 = RCdate(5,q);
                    s1 = RCdate(6,q);
                    
                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1);
                    min2 = RCdate(5,q+1);
                    s2 = RCdate(6,q+1);
                    
                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 3;
                    end
                end
            elseif isempty(findstr(RCstate{q},':vigorous')) == 0
                try
                    if isempty(findstr(RCstate{q+1},'vigorous:')) == 0
                    y1 = find(RCu{1}==RCdate(1,q));
                    m1 = find(RCu{2}==RCdate(2,q));
                    d1 = RCdate(3,q);
                    h1 = RCdate(4,q);
                    min1 = RCdate(5,q);
                    s1 = RCdate(6,q);
                    
                    y2 = find(RCu{1}==RCdate(1,q+1));
                    m2 = find(RCu{2}==RCdate(2,q+1));
                    d2 = RCdate(3,q+1);
                    h2 = RCdate(4,q+1);
                    min2 = RCdate(5,q+1);
                    s2 = RCdate(6,q+1);
                    
                    RCvals(y1:y2,m1:m2,d1:d2,h1:h2,min1:min2,s1:s2) = 4;
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
    end
    
    if isempty('dir2') == 0
        save([dir2 'extractedRCdata.mat'],'s');
    end
end
