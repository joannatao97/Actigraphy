metafile = '/Users/joshsalvi/Documents/GENEActiv/Data/JDS/processed/JDS_038816_2018-02-26_09-41-50.csv_metadata.csv';
rawfile = '/Users/joshsalvi/Documents/GENEActiv/Data/JDS/processed/JDS_038816_2018-02-26_09-41-50.csv_rawdata.csv';

[s]=analyzeGeneActiv(rawfile,metafile,1,2);


%% Import annotations

annot = importdata('/Users/joshsalvi/Documents/GENEActiv/Data/JDS/processed/GA_JDS_annotations_20180220.csv'); 
for j = 1:length(annot)
    annot{j} = strsplit(annot{j},',');
end
clear j

%% Label activities
s.activities = NaN(length(s.datatimes));
for j = 2:length(annot)
    try
        a = intersect(find(year(s.datatimes)==year(annot{j}{2})),find(month(s.datatimes)==month(annot{j}{2})));
        b = intersect(find(day(s.datatimes)==day(annot{j}{2})),find(hour(s.datatimes)==hour(annot{j}{2})));
        c = find(minute(s.datatimes)==minute(annot{j}{2}));
        d = intersect(a,b);
        indStart = intersect(c,d);
        
        a = intersect(find(year(s.datatimes)==year(annot{j}{3})),find(month(s.datatimes)==month(annot{j}{3})));
        b = intersect(find(day(s.datatimes)==day(annot{j}{3})),find(hour(s.datatimes)==hour(annot{j}{3})));
        c = find(minute(s.datatimes)==minute(annot{j}{3}));
        d = intersect(a,b);
        indStop = intersect(c,d);
        
        s.activities(indStart:indStop) = s.datatimes{j}{1};
    end
end
        
        