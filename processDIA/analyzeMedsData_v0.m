clear; clc

parentdir = '/Users/joshsalvi/Documents/Lab/Lab/Baker/Data/DIA/';
binsize = 5;
timerangeMin = 30;
timerangeBins = timerangeMin * 60 / binsize; 
tvec = linspace(-timerangeMin, timerangeMin, timerangeBins*2 + 1);

subjdirs = dir(parentdir);

M0 = 1; M02 = 1;
for M = 1:length(subjdirs)
    if length(subjdirs(M).name) == 5

        clear indsLORPRNtimes indsLOR indsLORPRN indsPRN mednames 

        subject = subjdirs(M).name;
        disp(['(' num2str(M) ') Subject: '  subject])
        
        try
            filesMeds = dir([parentdir subject '/edw/processed/DIA_*binSize' num2str(binsize) '*s.csv']);
            filesActALL = dir([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/DIA_*ALL_mean_*binSize' num2str(binsize) '*s.csv']);
            filesActXPSD = dir([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/DIA_*x_PSD_*binSize' num2str(binsize) '*s.csv']);
            filesActYPSD = dir([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/DIA_*y_PSD_*binSize' num2str(binsize) '*s.csv']);
            filesActZPSD = dir([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/DIA_*z_PSD_*binSize' num2str(binsize) '*s.csv']);
            filesActSUMPSD = dir([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/DIA_*sum_PSD_*binSize' num2str(binsize) '*s.csv']);
        catch
        end

        try
            for m = 1:length(filesMeds)
                data = importdata([parentdir subject '/edw/processed/' filesMeds(m).name]);
                mednames = data.textdata;
                mednamesALL{M} = mednames;
                medtimes = data.data;
            end
        catch
        end

        clear data
        if exist('mednames') == 1
            disp('...Found medications list.')
            try
                for m = 1:length(filesActALL)
                    data = importdata([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/' filesActALL(m).name]);
                    actnamesALL = data.textdata;
                    actdataALL = data.data;
                end
                for m = 1:length(filesActXPSD)
                    data = importdata([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/' filesActXPSD(m).name]);
                    actdataXPSD = data;
                end
                for m = 1:length(filesActYPSD)
                    data = importdata([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/' filesActYPSD(m).name]);
                    actdataYPSD = data;
                end
                for m = 1:length(filesActZPSD)
                    data = importdata([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/' filesActZPSD(m).name]);
                    actdataZPSD = data;
                end
                for m = 1:length(filesActSUMPSD)
                    data = importdata([parentdir subject '/actigraphy/processed/binned/binSize' num2str(binsize) '/' filesActSUMPSD(m).name]);
                    actdataSUMPSD = data;
                end
            catch
            end
        end

        q0L = 1; q0P = 1; indsLOR = []; indsPRN = [];
        try
        for m = 1:length(mednames)
            if isempty(regexpi(mednames{m}, 'LOR')) == 0
                indsLOR(q0L) = m;
                q0L = q0L + 1;
            end
            if isempty(regexpi(mednames{m}, 'PRN')) == 0
                indsPRN(q0P) = m;
                q0P = q0P + 1;
            end
        end
        indsLORPRN = intersect(indsLOR, indsPRN);
        catch
        end

        try
        for m = 1:length(indsLORPRN)
            try
                indsLORPRNtimes{m} = find(medtimes(:,indsLORPRN(m)) == 1);
            end
            for n = 1:length(indsLORPRNtimes{m})
                try
                    try
                        LORPRN_meanX(:, M0) = actdataALL(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins, 1);
                        LORPRN_meanY(:, M0) = actdataALL(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins, 2);
                        LORPRN_meanZ(:, M0) = actdataALL(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins, 3);
                        LORPRN_meanSUM(:, M0) = actdataALL(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins, 4);
                    catch
                    end
                    try
                        LORPRN_XPSD{M0} = actdataXPSD(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins,:);
                        LORPRN_YPSD{M0} = actdataYPSD(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins,:);
                        LORPRN_ZPSD{M0} = actdataZPSD(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins,:);
                        LORPRN_SUMPSD{M0} = actdataSUMPSD(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins,:);
                        LORPRN_varX(:, M0) = sum(LORPRN_XPSD{M0},2);
                        LORPRN_varY(:, M0) = sum(LORPRN_YPSD{M0},2);
                        LORPRN_varZ(:, M0) = sum(LORPRN_ZPSD{M0},2);
                        LORPRN_varSUM(:, M0) = sum(LORPRN_SUMPSD{M0},2);
                    catch
                    end

                    disp(['...(' num2str(M0) ') Subject: ' subject '; index: ' num2str(indsLORPRNtimes{m}(n))])

                    M0 = M0 + 1;
                catch
                end
            end
        end

        for m = 1:length(indsLOR)
            try
                indsLORtimes{m} = find(medtimes(:,indsLOR(m)) == 1);
            end
            for n = 1:length(indsLORtimes{m})
                try
                    try
                        LOR_meanX(:, M02) = actdataALL(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins, 1);
                        LOR_meanY(:, M02) = actdataALL(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins, 2);
                        LOR_meanZ(:, M02) = actdataALL(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins, 3);
                        LOR_meanSUM(:, M02) = actdataALL(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins, 4);
                    catch
                    end
                    try
                        LOR_XPSD{M02} = actdataXPSD(indsLORPRNtimes{m}(n)-timerangeBins:indsLORPRNtimes{m}(n)+timerangeBins,:);
                        LOR_YPSD{M02} = actdataYPSD(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins,:);
                        LOR_ZPSD{M02} = actdataZPSD(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins,:);
                        LOR_SUMPSD{M02} = actdataSUMPSD(indsLORtimes{m}(n)-timerangeBins:indsLORtimes{m}(n)+timerangeBins,:);
                        LOR_varX(:, M02) = sum(LOR_XPSD{M02},2);
                        LOR_varY(:, M02) = sum(LOR_YPSD{M02},2);
                        LOR_varZ(:, M02) = sum(LOR_ZPSD{M02},2);
                        LOR_varSUM(:, M02) = sum(LOR_SUMPSD{M02},2);
                    catch
                    end
                    M02 = M02 + 1;
                catch
                end
            end
        end

        catch
        end
    end
end
