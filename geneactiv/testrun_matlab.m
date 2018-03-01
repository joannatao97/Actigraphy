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
s.datatimes0 = reshape(s.datatimes0,6,length(s.datatimes0)/6)';
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
        