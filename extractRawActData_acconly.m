function [s] = extractRawActData_acconly(dir01, binSize, patient)
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
%       (4) binSize corresponds to the bin size in seconds used
% ----------------------
% Author: Joshua D. Salvi
% josh.salvi@gmail.com
% ----------------------
%

    % Append '/' to directory if not already present
    if dir01(end) ~= '/'
        dir01 = [dir01 '/'];
    end
    
    % Open log file
    diaryfile = [dir01 'MATLAB_logs.txt'];
    diary(diaryfile)

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
            end
        catch
        end
    end
    try
        s.acc_raw = acc;
    end

    % Convert UNIX time in ms to MATLAB time
    try
        unix_epoch = datenum(1970,1,1,0,0,0);
        acc(:,1) = acc(:,1)./86400./1e3 + unix_epoch;
    catch
        disp('Unable to convert time (Line 78)')
    end


    % Loop through each minute of acceleration data
    disp('ACC extraction...')
    
    % Calculate bins
    disp('Calculating time bins...')
    try
        timestampsdv = datevec(acc(:,1));
        elapsedtime = arrayfun(@(n) etime(timestampsdv(n,:),timestampsdv(1,:)), 1:size(timestampsdv,1));
        % elapsedtime = etime(timestampsdv,timestampsdv(1,:));
        [~, idx] = histc(elapsedtime,0:binSize:elapsedtime(end));
        idx(idx==0) = [];
        Fs = 1/elapsedtime(2);
        if isnan(Fs) ~= 0
            Fs = 30;        % Set default sample rate
        elseif Fs == 0
            Fs = 30;        % Set default sample rate
        end
    catch
        disp('Unable to calculate bins for ACC')
    end

    % Calculate mean and variance for each variable
    disp('ACC mean and variance...')
    try
        acc2(:,1) = acc(1:length(idx),1); acc2(:,2) = acc(1:length(idx),2); acc2(:,3) = acc(1:length(idx),3); acc2(:,4) = acc(1:length(idx),4);
        acc = acc2;
        displ = sqrt(acc(:,2).^2 + acc(:,3).^2 + acc(:,4).^2); displ = displ-nanmean(displ);
        s.acc_x_mean = accumarray(idx(:),acc(:,2),[],@mean);
        s.acc_y_mean = accumarray(idx(:),acc(:,3),[],@mean);
        s.acc_z_mean = accumarray(idx(:),acc(:,4),[],@mean);
        s.acc_sum_mean = accumarray(idx(:),displ(1:length(idx)),[],@mean);
    catch
        disp('Unable to calculate mean and variance for ACC')
    end

    disp('ACC spectrograms...')
    try
        freqs = 0:0.05:round(Fs/2);s.sample_rate = Fs;
        [~, s.acc_x_freqs, s.acc_x_times, s.acc_x_psd] = spectrogram(acc(:,2)-nanmean(acc(:,2)), round(Fs)*binSize, 0, freqs, round(Fs));
        s.acc_x_var = sum(abs(s.acc_x_psd));
        [~, s.acc_y_freqs, s.acc_y_times, s.acc_y_psd] = spectrogram(acc(:,3)-nanmean(acc(:,3)), round(Fs)*binSize, 0, freqs, round(Fs));
        s.acc_y_var = sum(abs(s.acc_y_psd));
        [~, s.acc_z_freqs, s.acc_z_times, s.acc_z_psd] = spectrogram(acc(:,4)-nanmean(acc(:,4)), round(Fs)*binSize, 0, freqs, round(Fs));
        s.acc_z_var = sum(abs(s.acc_z_psd));
        [~, s.acc_sum_freqs, s.acc_sum_times, s.acc_sum_psd] = spectrogram(displ, round(Fs)*binSize, 0, freqs, round(Fs));
        s.acc_sum_var = sum(abs(s.acc_sum_psd));
        s.acc_x_psd = abs(s.acc_x_psd); s.acc_y_psd = abs(s.acc_y_psd); s.acc_x_psd = abs(s.acc_z_psd);
    catch
        disp('Unable to calculate spectrograms for ACC')
    end
   
    % Save data to a structure with Patient ID and all relevant measures
    try
        s.Patient = patient;
    catch
        disp('Error in providing patient data')
    end

    disp('Importing medications...')
    try
        studydir = '/eris/sbdp/PHOENIX/PROTECTED/DIA/';     % Study directory
        dir0 = [studydir patient '/edw/raw/'];              % EDW data location
        files = dir(dir0);                                  % Extract filenames
    catch
        disp('No EDW files.')
    end

    % Get the actigraphy start time so that everything syncs up
    try
        unix_epoch = datenum(1970,1,1,0,0,0);
        start_time = s.acc_raw(1,1)./86400/1e3 + unix_epoch;
    end
    try
        for p = 1:length(files)
            if isempty(strfind(files(p).name,'.csv')) == 0
                disp(files(p).name);
                raw_meds_data = importdata([dir0 files(p).name]);
                for j = 2:length(raw_meds_data)
                    % meds_data = strsplit(raw_meds_data{j},',');
                    meds_data = regexp(raw_meds_data{j}, ',', 'split');
                    s.medications(j-1).timeET = datenum(meds_data{2}, 'yyyy-mm-dd HH:MM:SS');
                    s.medications(j-1).timeUTC = TimezoneConvert(datenum(s.medications(j-1).timeET),'America/New_York','UTC');
                    s.medications(j-1).elapsedTimeSeconds = etime(datevec(s.medications(j-1).timeUTC),datevec(start_time));
                    % medname0 = strsplit(meds_data{3},' ');
                    medname0 = regexp(meds_data{3}, ' ', 'split');
                    s.medications(j-1).name = '';
                    for k = 1:length(medname0)-3
                        s.medications(j-1).name = [s.medications(j-1).name ' ' medname0{k}];
                    end
                    s.medications(j-1).dose = [meds_data{4} ' ' meds_data{5}];
                    s.medications(j-1).route = meds_data{6};
                    if isempty(strfind(meds_data{7},'PRN')) == 0
                        s.medications(j-1).frequency = 'PRN';
                    else
                        s.medications(j-1).frequency = 'SCH';
                    end
                    s.medications(j-1).all = [s.medications(j-1).name(2:end) ' ' s.medications(j-1).dose ' ' s.medications(j-1).route ' ' s.medications(j-1).frequency];
                    mednames{j-1} = s.medications(j-1).all;
                end
            end
        end
    catch
        disp('Unable to import EDW data.')
    end

    % Generate binarized data matrix, aligned to actigraphy
    try
        headerMeds = unique(mednames); clear mednames
        s.medsArray = zeros(length(headerMeds),length(s.acc_x_mean));
        for j = 1:length(s.medications)
            if s.medications(j).elapsedTimeSeconds <= s.acc_x_times(end)
                m = findnearest(s.acc_x_times, s.medications(j).elapsedTimeSeconds);
                n = find(cell2mat(cellfun(@(x) isempty(strfind(x,s.medications(j).all))==0,headerMeds,'UniformOutput',0))==1);
                s.medsArray(n,m) = 1;
            end
        end

        disp('Writing EDW data to CSV...')
        dirMedsOut = [studydir patient '/edw/processed/'];
        csvwrite_with_headers([dirMedsOut '/DIA_' s.Patient '_edw' '_medications_binary_binSize' num2str(binSize) 's.csv'], s.medsArray', headerMeds);
    catch
        disp('Unable to generate EDW matrix')
    end

    % Save the structure to a MAT file
    disp('Saving MAT files...')
    try
        save([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/ExtractedData_acconly.mat'],'s','-v7.3');
    catch
        disp('Unable to save data (Line 400)')
    end
      
    % Create CSV files
    % Headers
    disp('Saving CSV files...')
    header1 = {'ACC X', 'ACC Y', 'ACC Z', 'ACC SUM'};
    header2 = {};
    try
        for j = 1:length(s.acc_sum_freqs)
            if mod(s.acc_sum_freqs(j),1) == 0
                header2{j} = num2str(s.acc_sum_freqs(j));
            else
                header2{j} = ' ';
            end
        end
    catch
        disp('Unable to generate headers')
    end

    % Write to CSV files
    try
        minPSD = nanmin([nanmin(nanmin(s.acc_x_psd)) nanmin(nanmin(s.acc_y_psd)) nanmin(nanmin(s.acc_z_psd)) nanmin(nanmin(s.acc_sum_psd))]);
        maxPSD = nanmax([nanmax(nanmax(s.acc_x_psd)) nanmax(nanmax(s.acc_y_psd)) nanmax(nanmax(s.acc_z_psd)) nanmax(nanmax(s.acc_sum_psd))]);
        s.acc_x_psd_scaled = (s.acc_x_psd - minPSD)./(maxPSD - minPSD);
        s.acc_y_psd_scaled = (s.acc_y_psd - minPSD)./(maxPSD - minPSD);
        s.acc_z_psd_scaled = (s.acc_z_psd - minPSD)./(maxPSD - minPSD);
        s.acc_sum_psd_scaled = (s.acc_sum_psd - minPSD)./(maxPSD - minPSD);

        minacc = nanmin([nanmin(s.acc_x_mean) nanmin(s.acc_y_mean) nanmin(s.acc_z_mean) nanmin(s.acc_sum_mean)]);
        maxacc = nanmax([nanmax(s.acc_x_mean) nanmax(s.acc_y_mean) nanmax(s.acc_z_mean) nanmax(s.acc_sum_mean)]);
        s.acc_x_mean_scaled = (s.acc_x_mean - minacc)./(maxacc - minacc);
        s.acc_y_mean_scaled = (s.acc_y_mean - minacc)./(maxacc - minacc);
        s.acc_z_mean_scaled = (s.acc_z_mean - minacc)./(maxacc - minacc);
        s.acc_sum_mean_scaled = (s.acc_sum_mean - minacc)./(maxacc - minacc);
    end
    try
        mat1 = [s.acc_x_mean'; s.acc_y_mean'; s.acc_z_mean'; s.acc_sum_mean']';
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_x_mean_binSize' num2str(binSize) 's.csv'], s.acc_x_mean, {'ACC X'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_y_mean_binSize' num2str(binSize) 's.csv'], s.acc_y_mean, {'ACC Y'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_z_mean_binSize' num2str(binSize) 's.csv'], s.acc_z_mean, {'ACC Z'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_sum_mean_binSize' num2str(binSize) 's.csv'], s.acc_sum_mean, {'ACC SUM'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_ALL_mean_binSize' num2str(binSize) 's.csv'], mat1, header1);

        % CSV files for spectral data
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_x_PSD_binSize' num2str(binSize) 's.csv'], s.acc_x_psd', header2);
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_y_PSD_binSize' num2str(binSize) 's.csv'], s.acc_y_psd', header2);
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_z_PSD_binSize' num2str(binSize) 's.csv'], s.acc_z_psd', header2);
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_sum_PSD_binSize' num2str(binSize) 's.csv'], s.acc_sum_psd', header2); 

        mat1_scaled = [s.acc_x_mean_scaled'; s.acc_y_mean_scaled'; s.acc_z_mean_scaled'; s.acc_sum_mean_scaled']';
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_x_mean_binSize' num2str(binSize) 's_scaled.csv'], s.acc_x_mean_scaled, {'ACC X'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_y_mean_binSize' num2str(binSize) 's_scaled.csv'], s.acc_y_mean_scaled, {'ACC Y'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_z_mean_binSize' num2str(binSize) 's_scaled.csv'], s.acc_z_mean_scaled, {'ACC Z'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_sum_mean_binSize' num2str(binSize) 's_scaled.csv'], s.acc_sum_mean_scaled, {'ACC SUM'});
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_ALL_mean_binSize' num2str(binSize) 's_scaled.csv'], mat1_scaled, header1);

        % CSV files for spectral data
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_x_PSD_binSize' num2str(binSize) 's_scaled.csv'], s.acc_x_psd_scaled', header2);
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_y_PSD_binSize' num2str(binSize) 's_scaled.csv'], s.acc_y_psd_scaled', header2);
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_z_PSD_binSize' num2str(binSize) 's_scaled.csv'], s.acc_z_psd_scaled', header2);
        csvwrite_with_headers([dir01 'actigraphy/processed/binned/binSize' num2str(binSize) '/DIA_' s.Patient '_embrace' '_acc_sum_PSD_binSize' num2str(binSize) 's_scaled.csv'], s.acc_sum_psd_scaled', header2);
    catch
        disp('Unable to save CSV files')
    end

    % Turn off logging
    diary off

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


function [c, matches] = strsplit(str, aDelim, varargin)

    % Initialize default values.
    collapseDelimiters = true;
    delimiterType = 'Simple';
    if nargin < 2
        delimiterType = 'RegularExpression';
        aDelim = {'\s'};
    elseif ischar(aDelim)
        aDelim = {aDelim};
    elseif isstring(aDelim)
        aDelim(ismissing(aDelim)) = [];
        aDelim = cellstr(aDelim);
    elseif ~iscellstr(aDelim)
        error(message('MATLAB:strsplit:InvalidDelimiterType'));
    end
    if nargin > 2
        funcName = mfilename;
        p = inputParser;
        p.FunctionName = funcName;
        p.addParameter('CollapseDelimiters', collapseDelimiters);
        p.addParameter('DelimiterType', delimiterType);
        p.parse(varargin{:});
        collapseDelimiters = verifyScalarLogical(p.Results.CollapseDelimiters, ...
            funcName, 'CollapseDelimiters');
        delimiterType = validatestring(p.Results.DelimiterType, ...
            {'RegularExpression', 'Simple'}, funcName, 'DelimiterType');
    end

    % Handle DelimiterType.
    if strcmp(delimiterType, 'Simple')
        % Handle escape sequences and translate.
        aDelim = strescape(aDelim);
        aDelim = regexptranslate('escape', aDelim);
    else
        % Check delimiter for regexp warnings.
        regexp('', aDelim, 'warnings');
    end

    % Handle multiple delimiters.
    aDelim = strjoin(aDelim, '|');

    % Handle CollapseDelimiters.
    if collapseDelimiters
        aDelim = ['(?:', aDelim, ')+'];
    end

    % Split.
    [c, matches] = regexp(str, aDelim, 'split', 'match');

end

function tf = verifyScalarLogical(tf, funcName, parameterName)

    if isscalar(tf) && (islogical(tf) || (isnumeric(tf) && any(tf == [0, 1])))
        tf = logical(tf);
    else
        validateattributes(tf, {'logical'}, {'scalar'}, funcName, parameterName);
    end

end
