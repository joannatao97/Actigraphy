function [s] = analyzeGeneActiv(datafile, metadatafile, switch0)
    
    % Import data
    s = {};
    s.rawdata = importdata(datafile);
    s.metadata = importdata(metadatafile);

    % Extract raw data information
    s.datatimes = s.rawdata.textdata;
    s.acc_x = s.rawdata.data(:,1); s.acc_y = s.rawdata.data(:,2); s.acc_z = s.rawdata.data(:,3);
    s.lux = s.rawdata.data(:,4); s.button = s.rawdata.data(:,5); s.ambtemp = s.rawdata.data(:,6);
    try
        s.acc_sum = s.rawdata.data(:,7);
        s.acc_x_SD = s.rawdata.data(:,8);
        s.acc_y_SD = s.rawdata.data(:,9);
        s.acc_z_SD = s.rawdata.data(:,10);
    catch
    end
    try
        s.lux_peak = s.rawdata.data(:,11);
    catch
    end
        
    % Extract the scan rate
    s.scan_rate = str2double(s.metadata.textdata{7,2}(11:end));
    
    % Switch between options for analysis
    if switch0 == 1
        % Split into N-minute chunks
        s.Nsec = 10;
        chunk_size = s.scan_rate * s.Nsec;
        s.datatimes_split = reshape(s.datatimes(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.datatimes)/chunk_size), chunk_size)';
        s.acc_x_split = reshape(s.acc_x(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_x)/chunk_size), chunk_size)';
        s.acc_y_split = reshape(s.acc_y(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_y)/chunk_size), chunk_size)';
        s.acc_z_split = reshape(s.acc_z(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_z)/chunk_size), chunk_size)';
        s.lux_split = reshape(s.lux(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.lux)/chunk_size), chunk_size)';
        s.button_split = reshape(s.button(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.button)/chunk_size), chunk_size)';
        s.ambtemp_split = reshape(s.ambtemp(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.ambtemp)/chunk_size), chunk_size)';

        try
            s.acc_sum_split = reshape(s.acc_sum(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_sum)/chunk_size), chunk_size)';
            s.acc_x_SD_split = reshape(s.acc_x_SD(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_x_SD)/chunk_size), chunk_size)';
            s.acc_y_SD_split = reshape(s.acc_y_SD(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_y_SD)/chunk_size), chunk_size)';
            s.acc_z_SD_split = reshape(s.acc_z_SD(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_z_SD)/chunk_size), chunk_size)';
            s.lux_peak_split = reshape(s.lux_peak(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.lux_peak)/chunk_size), chunk_size)';
        catch
        end

        % Process each chunk of data
        for j = 1:size(s.datatimes_split,2)
            disp(['iteration ' num2str(j) ' out of ' num2str(size(s.datatimes_split,2))])
            s.acc_x_split_mean(j) = mean(s.acc_x_split(:,j));
            s.acc_y_split_mean(j) = mean(s.acc_y_split(:,j));
            s.acc_z_split_mean(j) = mean(s.acc_z_split(:,j));
            s.lux_split_mean(j) = mean(s.lux_split(:,j));
            s.ambtemp_split_mean(j) = mean(s.ambtemp_split(:,j));

            try
                s.acc_x_SD_split_mean(j) = mean(s.acc_x_SD_split(:,j));
                s.acc_y_SD_split_mean(j) = mean(s.acc_y_SD_split(:,j));
                s.acc_z_SD_split_mean(j) = mean(s.acc_z_SD_split(:,j));
                s.acc_sum_split_mean(j) = mean(s.acc_sum_split(:,j));
                s.lux_peak_split_mean(j) = mean(s.lux_peak_split(:,j));
            catch
            end

            [s.acc_x_split_psd(:,j), s.fxx] = pwelch(s.acc_x_split(:,j) - mean(s.acc_x_split(:,j)),[],[],[],s.scan_rate);
            [s.acc_y_split_psd(:,j), s.fxx] = pwelch(s.acc_y_split(:,j) - mean(s.acc_y_split(:,j)),[],[],[],s.scan_rate);
            [s.acc_z_split_psd(:,j), s.fxx] = pwelch(s.acc_z_split(:,j) - mean(s.acc_z_split(:,j)),[],[],[],s.scan_rate);
            [s.lux_split_psd(:,j), s.fxx] = pwelch(s.lux_split(:,j) - mean(s.lux_split(:,j)),[],[],[],s.scan_rate);
            [s.ambtemp_split_psd(:,j), s.fxx] = pwelch(s.ambtemp_split(:,j) - mean(s.ambtemp_split(:,j)),[],[],[],s.scan_rate);

            try
                [s.acc_x_SD_split_psd(:,j), s.fxx] = pwelch(s.acc_x_SD_split(:,j) - mean(s.acc_x_SD_split(:,j)),[],[],[],s.scan_rate);
                [s.acc_y_SD_split_psd(:,j), s.fxx] = pwelch(s.acc_y_SD_split(:,j) - mean(s.acc_y_SD_split(:,j)),[],[],[],s.scan_rate);
                [s.acc_z_SD_split_psd(:,j), s.fxx] = pwelch(s.acc_z_SD_split(:,j) - mean(s.acc_z_SD_split(:,j)),[],[],[],s.scan_rate);
                [s.lux_peak_split_psd(:,j), s.fxx] = pwelch(s.lux_peak_split(:,j) - mean(s.lux_peak_split(:,j)),[],[],[],s.scan_rate);
                [s.acc_sum_split_psd(:,j), s.fxx] = pwelch(s.acc_sum_split(:,j) - mean(s.acc_sum_split(:,j)),[],[],[],s.scan_rate);
            catch
            end
        end
    elseif switch0 == 2
        % Choose bin size in seconds and percent overlap
        s.Nsec = 1;
        s.noverlap = 0;
        s.freqvec = 0:0.1:s.scan_rate/2;
        
        % Calculate bin size 
        chunk_size = s.scan_rate * s.Nsec;
        
        % Calculate spectrograms
        [s.acc_x_spec, s.freqs, s.times] = spectrogram(s.acc_x - mean(s.acc_x), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
        [s.acc_y_spec, s.freqs, s.times] = spectrogram(s.acc_y - mean(s.acc_y), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
        [s.acc_z_spec, s.freqs, s.times] = spectrogram(s.acc_z - mean(s.acc_z), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
        [s.lux_spec, s.freqs, s.times] = spectrogram(s.lux - mean(s.lux), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
        [s.ambtemp_spec, s.freqs, s.times] = spectrogram(s.ambtemp - mean(s.ambtemp), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
        
        try
            [s.acc_x_SD_spec, s.freqs, s.times] = spectrogram(s.acc_x_SD - mean(s.acc_x_SD), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
            [s.acc_y_SD_spec, s.freqs, s.times] = spectrogram(s.acc_y_SD - mean(s.acc_y_SD), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
            [s.acc_z_SD_spec, s.freqs, s.times] = spectrogram(s.acc_z_SD - mean(s.acc_z_SD), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
            [s.lux_peak_spec, s.freqs, s.times] = spectrogram(s.lux_peak - mean(s.lux_peak), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
            [s.acc_sum_spec, s.freqs, s.times] = spectrogram(s.acc_sum - mean(s.acc_sum), chunk_size, s.noverlap, s.freqvec, s.scan_rate);
        catch
        end
    end
end

