
load('/Volumes/Macintosh HD/Users/joshsalvi/Documents/Lab/Lab/Baker/Actigraphy/2A6XM/actigraphy/processed/ExtractedData.mat')


displ = sqrt(s.acc_raw(:,2).^2 + s.acc_raw(:,3).^2 + s.acc_raw(:,4).^2);
% displ = displ - mean(displ);

times = s.acc_raw(:,1);
tz=0;
unix_epoch = datenum(1970,1,1,tz,0,0);
times = times./86400./1e3 + unix_epoch;

timestamps = [day(times)'; hour(times)'; minute(times)'; second(times)'];
timestamps = timestamps';

%%
day0 = 13;
hour0 = 12;
indS = intersect(find(timestamps(:,1)==day0),find(timestamps(:,2)==hour0));

%%
Fs = 31.9519;

winSize_inds = [0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 60, 120, 180];
perc_overlap_inds = [0, 0.1, 0.25, 0.5, 0.75, 0.9];
df_inds = [0.1, 0.2, 0.5, 1];

% winSize = 10;
% perc_overlap = 0;
% df = 0.5;
q0 = length(winSize_inds)*length(perc_overlap_inds)*length(df_inds);
q00 = 1;
for winSize = winSize_inds
    for perc_overlap0 = perc_overlap_inds
        for df = df_inds
            close all;
            disp([num2str(q00) ' out of ' num2str(q0)]);
            freqs = 0:df:15;
            
            perc_overlap = ceil(perc_overlap0 * Fs * winSize);
            
            warning off
            [STFT,F,T,S] = spectrogram(displ(indS)-mean(displ(indS)),Fs*winSize,perc_overlap,freqs,Fs);
            
%             T = T./Fs./(winSize/(60/winSize));
            
            h0 = figure('units','normalized','outerposition',[0 0 1 1]);
            imagesc(linspace(0,length(S)./winSize,length(S)),F,log(abs(S)));
            xlabel('time')
            ylabel('frequency (Hz)')
            title(['Spectrogram (W_b_i_n = ' num2str(winSize) ' s; overlap = ' num2str(perc_overlap0 *100) '%; df = ' num2str(df) ' Hz)'])
            h = colorbar;
            ylabel(h, 'log(PSD) (g^2·Hz^-^1)')
            
            filepath = '/Users/joshsalvi/Documents/Lab/Lab/Baker/embrace_psd_test/';
            print(h0,[filepath 'DIA_2A6XM_embrace_specttest_day' num2str(day0-12) '_hour' num2str(hour0-1) '_PSD_win' num2str(winSize) 'sec_overlap' num2str(perc_overlap0) '_df' num2str(df) '.png'],'-dpng')
            q00 = q00 + 1;
        end
    end
end