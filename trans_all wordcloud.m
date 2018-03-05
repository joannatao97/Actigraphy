fileID = fopen('DIA_redcap_events_trans_all.csv');

data = textscan(fileID,'%s','Delimiter',' ');
fclose(fileID);
data = data{1};

i = 1;
lcount = 0;
rcount = 0;
c = 0;
while(i < length(data))
    if c == 0
        lcount = lcount + length(find(data{i} == '{'));
        rcount = rcount + length(find(data{i} == '}'));
    end
    
    if lcount ~= rcount
        lcount = lcount + length(find(data{i + 1} == '{'));
        rcount = rcount + length(find(data{i + 1} == '}'));
        data{i} = [data{i} ' ' data{i + 1}];
        data(i + 1) = [];
        c = c + 1;
        continue
    end
    c = 0;
    i = i + 1;
end

data = reshape(data, 4, length(data)/4)';
original = data;

%%

words = data(:, 4);
i = 1;
while(i < length(words))
    a = find(words{i} == ',');
    if (a(5) - a(1) == 4) && (a(10) - a(6) == 4)
        data(i, :) = [];
        words(i) = [];
        continue
    end
    i = i + 1;
end
%%

for i = 1:length(data)
    [s, f] = regexp(words{i}, '{[^}]+}');
    data{i, 4} = words{i}(s(1):f(1));
    data{i, 5} = words{i}(s(2):f(2));
end
%%
for i = 1:length(data)
    [s, f] = regexp(data{i, 4}, ',[^,]+[,]+[12345]');
    if length(s) >= 1
        data{i, 4} = data{i, 4}(s(1):f(1));
        [s, f] = regexp(data{i, 4}, '[^,]+[",]');
        data{i, 4} = data{i, 4}(s:f-1);
        if ~isempty(regexp(data{i, 4}, '".+"', "ONCE"))
            data{i, 4} = data{i, 4}(2:end - 1);
        end
    else
        data{i, 4} = [];
    end
    [s, f] = regexp(data{i, 5}, ',[^,]+[,]+[12345]');
    if length(s) >= 1
        data{i, 5} = data{i, 5}(s(1):f(1));
        [s, f] = regexp(data{i, 5}, '[^,]+[",]');
        data{i, 5} = data{i, 5}(s:f-1);
        if ~isempty(regexp(data{i, 5}, '".+"', "ONCE"))
            data{i, 5} = data{i, 5}(2:end - 1);
        end
    else
        data{i, 5} = [];
    end
end

%%
wordlist = [data(:, 4); data(:, 5)];

i = 1;
while(i <= length(wordlist))
    if isempty(wordlist{i})
        wordlist(i) = [];
        continue
    end
    i = i + 1;
end
figure(1)
wordcloud(categorical(wordlist));

w = [];
for i = 1:length(wordlist)
    w = [w; split(wordlist(i), ' ')];
end
figure(2)
wordcloud(categorical(w));