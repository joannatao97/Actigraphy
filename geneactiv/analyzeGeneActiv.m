function [s, rawdata, metadata] = analyzeGeneActiv(datafile, metadatafile)
    
    % Import data
    s = {};
    rawdata = importdata(datafile);
    metadata = importdata(metadatafile);

    % Extract raw data information
    datatimes = rawdata.textdata;
    acc_x = rawdata.data(:,1); acc_y = rawdata.data(:,2); acc_z = rawdata.data(:,3);
    lux = rawdata.data(:,4); button = rawdata.data(:,5); amb_temp = rawdata.data(:,6);
        
    % Extract the scan rate
    scan_rate = str2double(metadata.textdata{7,2}(11:end));
    
    % Split into N-minute chunks
    Nsec = 10;
    chunk_size = scan_rate * Nsec;
    datatimes_split = reshape(datatimes(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(datatimes)/chunk_size), chunk_size)';
    acc_x_split = reshape(acc_x(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(acc_x)/chunk_size), chunk_size)';
    acc_y_split = reshape(acc_y(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(acc_y)/chunk_size), chunk_size)';
    acc_z_split = reshape(acc_z(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(acc_z)/chunk_size), chunk_size)';
    lux_split = reshape(lux(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(lux)/chunk_size), chunk_size)';
    button_split = reshape(button(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(button)/chunk_size), chunk_size)';
    amb_temp_split = reshape(amb_temp(1:floor(length(datatimes)/chunk_size)*chunk_size),floor(length(amb_temp)/chunk_size), chunk_size)';
    
    % Process each chunk of data
    for j = 1:size(datatimes_split,2)
        disp(['iteration ' num2str(j) ' out of ' num2str(size(datatimes_split,2))])
        acc_x_split_mean(j) = mean(acc_x_split(:,j));
        acc_y_split_mean(j) = mean(acc_y_split(:,j));
        acc_z_split_mean(j) = mean(acc_z_split(:,j));
        lux_split_mean(j) = mean(lux_split(:,j));
        amb_temp_split_mean(j) = mean(amb_temp_split(:,j));
        
        [acc_x_split_psd(:,j), fxx] = pwelch(acc_x_split(:,j),[],[],[],scan_rate);
        [acc_y_split_psd(:,j), fxx] = pwelch(acc_y_split(:,j),[],[],[],scan_rate);
        [acc_z_split_psd(:,j), fxx] = pwelch(acc_z_split(:,j),[],[],[],scan_rate);
        [lux_split_psd(:,j), fxx] = pwelch(lux_split(:,j),[],[],[],scan_rate);
        [amb_temp_split_psd(:,j), fxx] = pwelch(amb_temp_split(:,j),[],[],[],scan_rate);
    end
    s.accx = acc_y_split_psd;
    s.accxsplit = acc_y_split;
    s.fxx = fxx;
end