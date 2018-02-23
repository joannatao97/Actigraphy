function [s] = analyzeGeneActiv(datafile, metadatafile)
    
    % Import data
    s = {};
    s.rawdata = importdata(datafile);
    s.metadata = importdata(metadatafile);

    % Extract raw data information
    s.datatimes = s.rawdata.textdata;
    s.acc_x = s.rawdata.data(:,1); s.acc_y = s.rawdata.data(:,2); s.acc_z = s.rawdata.data(:,3);
    s.lux = s.rawdata.data(:,4); s.button = s.rawdata.data(:,5); amb_temp = s.rawdata.data(:,6);
        
    % Extract the scan rate
    s.scan_rate = str2double(s.metadata.textdata{7,2}(11:end));
    
    % Split into N-minute chunks
    s.Nsec = 10;
    chunk_size = s.scan_rate * s.Nsec;
    s.datatimes_split = reshape(s.datatimes(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.datatimes)/chunk_size), chunk_size)';
    s.acc_x_split = reshape(s.acc_x(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_x)/chunk_size), chunk_size)';
    s.acc_y_split = reshape(s.acc_y(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_y)/chunk_size), chunk_size)';
    s.acc_z_split = reshape(s.acc_z(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.acc_z)/chunk_size), chunk_size)';
    s.lux_split = reshape(s.lux(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.lux)/chunk_size), chunk_size)';
    s.button_split = reshape(s.button(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(s.button)/chunk_size), chunk_size)';
    s.amb_temp_split = reshape(amb_temp(1:floor(length(s.datatimes)/chunk_size)*chunk_size),floor(length(amb_temp)/chunk_size), chunk_size)';
    
    % Process each chunk of data
    for j = 1:size(s.datatimes_split,2)
        disp(['iteration ' num2str(j) ' out of ' num2str(size(s.datatimes_split,2))])
        s.acc_x_split_mean(j) = mean(s.acc_x_split(:,j));
        s.acc_y_split_mean(j) = mean(s.acc_y_split(:,j));
        s.acc_z_split_mean(j) = mean(s.acc_z_split(:,j));
        s.lux_split_mean(j) = mean(s.lux_split(:,j));
        s.amb_temp_split_mean(j) = mean(s.amb_temp_split(:,j));
        
        [s.acc_x_split_psd(:,j), s.fxx] = pwelch(s.acc_x_split(:,j),[],[],[],s.scan_rate);
        [s.acc_y_split_psd(:,j), s.fxx] = pwelch(s.acc_y_split(:,j),[],[],[],s.scan_rate);
        [s.acc_z_split_psd(:,j), s.fxx] = pwelch(s.acc_z_split(:,j),[],[],[],s.scan_rate);
        [s.lux_split_psd(:,j), s.fxx] = pwelch(s.lux_split(:,j),[],[],[],s.scan_rate);
        [s.amb_temp_split_psd(:,j), s.fxx] = pwelch(s.amb_temp_split(:,j),[],[],[],s.scan_rate);
    end
end