clear

metafile = '/Users/joshsalvi/Documents/GENEActiv/Data/JDS/processed/JDS_038816_2018-02-26_09-41-50.csv_metadata.csv';
rawfile = '/Users/joshsalvi/Documents/GENEActiv/Data/JDS/processed/JDS_038816_2018-02-26_09-41-50.csv_rawdata.csv';

binsize = 5;    % seconds

[s]=analyzeGeneActiv(rawfile,metafile,binsize,2);
%% Import annotations

disp('Importing annotations...')
annot = importdata('/Users/joshsalvi/Documents/GENEActiv/Data/JDS/processed/GA_JDS_annotations_20180220.csv'); 
for j = 1:length(annot)
    annot{j} = strsplit(annot{j},',');
end
clear j


disp('Generating time bins...')
tic
s.datatimes0 = cellfun(@(x) [str2double(x(1:4)), str2double(x(6:7)), str2double(x(9:10)), str2double(x(12:13)), str2double(x(15:16)), str2double(x(18:19))],s.datatimes,'UniformOutput',false);
s.datatimes0 = cell2mat(s.datatimes0);
% s.datatimes0 = reshape(s.datatimes0,6,length(s.datatimes0)/6)';
s.timeelapsed = etime(s.datatimes0,s.datatimes0(1,:));
s.timebins = ceil((s.timeelapsed+1)./5);
toc

disp('Labeling annotations...')
tic
s.activities = NaN(1,length(s.datatimes));
s.activities_binned = NaN(1,length(s.times));
s.activity_matrix = zeros(11,length(s.times));
for j = 2:length(annot)
    try
        a = intersect(find(s.datatimes0(:,1)==year(annot{j}{2})),find(s.datatimes0(:,2)==month(annot{j}{2})-2));
        b = intersect(find(s.datatimes0(:,3)==day(annot{j}{2})),find(s.datatimes0(:,4)==hour(annot{j}{2})));
        c = find(s.datatimes0(:,5)==minute(annot{j}{2}));
        d = intersect(a,b);
        indStart = intersect(c,d);indStart = indStart(1);
        
        a = intersect(find(s.datatimes0(:,1)==year(annot{j}{3})),find(s.datatimes0(:,2)==month(annot{j}{3})-2));
        b = intersect(find(s.datatimes0(:,3)==day(annot{j}{3})),find(s.datatimes0(:,4)==hour(annot{j}{3})));
        c = find(s.datatimes0(:,5)==minute(annot{j}{3}));
        d = intersect(a,b);
        indStop = intersect(c,d);indStop = indStop(end);
        
        indBinned = unique(s.timebins(indStart:indStop));
        
        s.activities(indStart:indStop) = str2double(annot{j}{1});
        s.activities_binned(indBinned) = str2double(annot{j}{1});
        s.activity_matrix(str2double(annot{j}{1}),indBinned) = 1;
    catch
    end
end
toc

disp('Generating headers...')
tic
clear header
header = {'still','computer','writing','walking','running','showering','brushingteeth','combinghair','lightsleep','deepsleep','eating'};
for j = length(header)+1:length(header)+length(s.freqs)
    header{j} = ' ';
end
toc

%%
accx = log(abs(s.acc_x_spec));
accy = log(abs(s.acc_y_spec));
accz = log(abs(s.acc_z_spec));

% minallx = min(min(accx)); minally = min(min(accy)); minallz = min(min(accz));
% maxallx = max(max(accx)); maxally = max(max(accy)); maxallz = max(max(accz));
minallx = min([min(min(accx)) min(min(accy)) min(min(accz))]);minally=minallx;minallz=minallx;
maxallx = max([max(max(accx)) max(max(accy)) max(max(accz))]);maxally=maxallx;maxallz=maxallx;
rangex = maxallx-minallx; rangey = maxally-minally; rangez = maxallz-minallz;

acc_x_spec_scaled = (accx-minallx)./rangex; 
acc_x_spec_scaled = acc_x_spec_scaled.*255;

acc_y_spec_scaled = (accy-minally)./rangey; 
acc_y_spec_scaled = acc_y_spec_scaled.*255;

acc_z_spec_scaled = (accz-minallz)./rangez; 
acc_z_spec_scaled = acc_z_spec_scaled.*255;

% acc_x_spec_scaled = uint8(accx);
% acc_y_spec_scaled = uint8(accy);
% acc_z_spec_scaled = uint8(accz);

acc_all_spec_scaled(:,:,1) = 1.*acc_x_spec_scaled;
acc_all_spec_scaled(:,:,2) = 1.*acc_y_spec_scaled;
acc_all_spec_scaled(:,:,3) = 1.*acc_z_spec_scaled;


GAIN = 0.15;

acc_all_spec_scaled = GAIN.*acc_all_spec_scaled;

%%
close all;
q=1;

for ind0 = 1:11
    inds = find(s.activities_binned==ind0);
    breaks = find(diff(inds)>1); L = length(breaks) + 1;
    breaks = [1 breaks length(inds)];
    for k = 1:L
        try
            close all
            h0=figure('units','normalized','outerposition',[0 0 2.2 1.6]);
            inds0 = inds(breaks(k):breaks(k+1));
            
            subplot(3,1,1);
            imagesc(s.times(1:length(inds0)), s.freqs, accx(:,inds0));
            ylabel('Frequency (Hz)'); xlabel('Time (s)');
            h = colorbar;
            ylabel(h, 'X');
            caxis([-6 6]);
            title([header{ind0} ' ' num2str(k)]);
            
            subplot(3,1,2);
            imagesc(s.times(1:length(inds0)), s.freqs, accy(:,inds0));
            ylabel('Frequency (Hz)'); xlabel('Time (s)');
            h = colorbar;
            ylabel(h, 'Y');
            caxis([-6 6]);
            
            subplot(3,1,3);
            imagesc(s.times(1:length(inds0)), s.freqs, accz(:,inds0));
            ylabel('Frequency (Hz)'); xlabel('Time (s)');
            h = colorbar;
            ylabel(h, 'Z');
            caxis([-6 6]);
            
            outpath = '/Users/joshsalvi/Downloads/actclasses';
            print(h0, [outpath 'GA_JDS_activity' num2str(ind0) '_epoch' num2str(k) '.png'], '-dpng')
            
%             h0=image(s.times(1:length(inds0))./60,s.freqs,acc_all_spec_scaled(:,inds0,1:3), 'CDataMapping', 'direct');
%             ylabel('frequency (Hz)');xlabel('time (minutes)')
%             title(['Activity: ' header{ind0} '; Gain: ' num2str(GAIN)])
%             savepath0 = '/Users/joshsalvi/Downloads/actclasses/rescaled/';
%             print([savepath0 'GA_JDS_' header{ind0} '_gain' num2str(GAIN) '_' num2str(k) '.pdf'],'-dpdf','-bestfit')
        end
    end
end