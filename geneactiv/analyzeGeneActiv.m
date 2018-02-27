function [s] = analyzeGeneActiv(datafile, metadatafile, binsize, switch0)
%
% function [s] = analyzeGeneActiv(datafile, metadatafile, binsize, switch0)
%
% INPUTS:
%   datafile:       path to raw data file
%   metadatafile:   path to metadata file
%   binsize:        bin size in seconds
%   switch0:        if 1, will split up raw time series,do pwelch, and analyze
%                   if 2, will perform STFT and analyze
% 
% 
% Author:   Joshua Salvi
% Year:     2018
    
    % Import data
    s = {};
    disp('Importing...')
    s.rawdata = importdata(datafile);
    s.metadata = importdata(metadatafile);
    disp('Completed import.')

    % Extract raw data information
    disp('Extracting data...')
    s.datatimes = cellfun(@(x) x(1:end-4),s.rawdata.textdata,'UniformOutput',false);
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
        % Split into chunks
        disp('Splitting data...')
        s.Nsec = binsize; % number of seconds as input
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
        disp('Processing chunks...')
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
        s.Nsec = binsize;
        s.noverlap = 0;
        s.freqvec = 0:0.1:s.scan_rate/2;
        
        % Calculate bin size 
        chunk_size = s.scan_rate * s.Nsec;
        
        % Calculate spectrograms
        disp('Calculating spectrograms...')
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
        
        % Combine into higher-dimensional dataset
        disp('Combining spectrograms...')
        s.M_acc = [abs(s.acc_x_spec); abs(s.acc_y_spec); abs(s.acc_z_spec)]';
        try
            s.M_acc_all = [s.M_acc'; abs(s.acc_x_SD_spec); abs(s.acc_y_SD_spec); abs(s.acc_z_SD_spec); abs(s.acc_sum_spec)]';
        catch
        end
        
        % Perform PCA
        disp('PCA...')
        
        % Built-in PCA
        [s.M_acc_pca_coeff, s.M_acc_pca_score, ~, s.M_acc_pca_tsquared, s.M_acc_pca_explainedvariance] = pca(s.M_acc');
        
        % Custome PCA
%         [s.M_acc_pca_coeff, s.M_acc_pca_mapping] = pca(s.M_acc);
        try
            [s.M_acc_all_pca_coeff, s.M_acc_all_pca_mapping] = pca(s.M_acc_all);
        catch
        end
%         try
%             s.M_acc_pca_coeff = s.M_acc_pca_coeff(:,1:3);
%             s.M_acc_all_pca_coeff = s.M_acc_all_pca_coeff(:,1:3);
%         end

        % Perform t-SNE
        disp('tSNE...')
        [s.M_acc_tsne_coeff, s.M_acc_tsne_loss] = tsne(s.M_acc,'Standardize',1,'NumDimensions',3);
        try
            [s.M_acc_all_tsne_coeff, s.M_acc_all_tsne_loss] = tsne(s.M_acc_all,'Standardize',1,'NumDimensions',3);
        catch
        end
    end
    disp('Complete.');
end

%{
function [mappedX, mapping] = pca(X, no_dims)

    if ~exist('no_dims', 'var')
        no_dims = 2;
    end
	
	% Make sure data is zero mean
    mapping.mean = mean(X, 1);
	X = bsxfun(@minus, X, mapping.mean);

	% Compute covariance matrix
    if size(X, 2) < size(X, 1)
        C = cov(X);
    else
        C = (1 / size(X, 1)) * (X * X');        % if N>D, we better use this matrix for the eigendecomposition
    end
	
	% Perform eigendecomposition of C
	C(isnan(C)) = 0;
	C(isinf(C)) = 0;
    [M, lambda] = eig(C);
    
    % Sort eigenvectors in descending order
    [lambda, ind] = sort(diag(lambda), 'descend');
    if no_dims < 1
        no_dims = find(cumsum(lambda ./ sum(lambda)) >= no_dims, 1, 'first');
        disp(['Embedding into ' num2str(no_dims) ' dimensions.']);
    end
    if no_dims > size(M, 2)
        no_dims = size(M, 2);
        warning(['Target dimensionality reduced to ' num2str(no_dims) '.']);
    end
	M = M(:,ind(1:no_dims));
    lambda = lambda(1:no_dims);
	
	% Apply mapping on the data
    if ~(size(X, 2) < size(X, 1))
        M = bsxfun(@times, X' * M, (1 ./ sqrt(size(X, 1) .* lambda))');     % normalize in order to get eigenvectors of covariance matrix
    end
    mappedX = X * M;
    
    % Store information for out-of-sample extension
    mapping.M = M;
	mapping.lambda = lambda;
end

%}
