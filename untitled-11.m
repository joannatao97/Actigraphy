
for m = 1:30
try
    subplot_tight(6,5,m,[0.05 0.05]);
scatter(reshape(s{m}.RCinterp_min,1,size(s{m}.ACCmean,1)*size(s{m}.ACCmean,2)*size(s{m}.ACCmean,3)*size(s{m}.ACCmean,4)),reshape(s{m}.ACCmean,1,size(s{m}.ACCmean,1)*size(s{m}.ACCmean,2)*size(s{m}.ACCmean,3)*size(s{m}.ACCmean,4)))
title(s{m}.Patient)
end
end

%%
close all
m=7;
scatter(reshape(s{m}.RCmean,1,size(s{m}.ACCmean,1)*size(s{m}.ACCmean,2)*size(s{m}.ACCmean,3)*size(s{m}.ACCmean,4)),reshape(s{m}.ACCmean,1,size(s{m}.ACCmean,1)*size(s{m}.ACCmean,2)*size(s{m}.ACCmean,3)*size(s{m}.ACCmean,4)))


%%
clear accmean accstd tempmean tempstd edamean edastd accsem tempsem edasem
close all
m=7;
% rc = s{m}.RCmean; rc = permute(rc,[4 3 2 1]);
rc = squeeze(s{m}.RCinterp_min(1,:,:,:,:)); rc = permute(rc,ndims(rc):-1:1);
acc = s{m}.ACCmean; acc = permute(acc,[4 3 2 1]);
temp = s{m}.TEMPmean; temp = permute(temp,[4 3 2 1]);
eda = s{m}.EDAmean; eda = permute(eda,[4 3 2 1]);

size2 = size(rc,1)*size(rc,2)*size(rc,3)*size(rc,4)*size(rc,5);

rc = reshape(rc,1,size2);
acc = reshape(acc,1,size2);
temp = reshape(temp,1,size2);
eda = reshape(eda,1,size2);

q = find(isnan(rc)==0);
rcu = unique(rc(q));
for j = 1:length(rcu)
    accmean(j) = nanmean(acc(rc==rcu(j))); accstd(j) = nanstd(acc(rc==rcu(j)));accsem(j) = accstd(j)/sqrt(length(rc==rcu(j)));
    tempmean(j) = nanmean(temp(rc==rcu(j))); tempstd(j) = nanstd(temp(rc==rcu(j)));tempsem(j) = tempstd(j)/sqrt(length(rc==rcu(j)));
    edamean(j) = nanmean(eda(rc==rcu(j))); edastd(j) = nanstd(eda(rc==rcu(j)));edasem(j) = edastd(j)/sqrt(length(rc==rcu(j)));
end


subplot(1,3,1);plot(rcu(isnan(accmean)==0),accmean(isnan(accmean)==0),'r');xlabel('Activity annotation');ylabel('dRMS');
title(s{m}.Patient);
subplot(1,3,3);plot(rcu(isnan(tempmean)==0),tempmean(isnan(tempmean)==0),'b');xlabel('Activity annotation');ylabel('temp');
title(s{m}.Patient);
subplot(1,3,2);plot(rcu(isnan(edamean)==0),edamean(isnan(edamean)==0),'g');xlabel('Activity annotation');ylabel('eda');
title(s{m}.Patient);

figure;
subplot(1,3,1);errorbar(rcu,accmean,accsem);xlabel('Activity annotation');ylabel('dRMS');
title(s{m}.Patient);
subplot(1,3,2);errorbar(rcu,tempmean,tempsem);xlabel('Activity annotation');ylabel('temp');
title(s{m}.Patient);
subplot(1,3,3);errorbar(rcu,edamean,edasem);xlabel('Activity annotation');ylabel('eda');
title(s{m}.Patient);

%%
% close all;
figure;

m=7;
% rc = s{m}.RCmean; rc = permute(rc,[4 3 2 1]);
rc = squeeze(s{m}.RCinterp_min(1,:,:,:,:)); rc = permute(rc,ndims(rc):-1:1);
acc = s{m}.ACCmean; acc = permute(acc,[4 3 2 1]);
temp = s{m}.TEMPmean; temp = permute(temp,[4 3 2 1]);
eda = s{m}.EDAmean; eda = permute(eda,[4 3 2 1]);

size2 = size(rc,1)*size(rc,2)*size(rc,3)*size(rc,4)*size(rc,5);
rc = reshape(rc,1,size2);
acc = reshape(acc,1,size2);
temp = reshape(temp,1,size2);
eda = reshape(eda,1,size2);

rc(isnan(rc)==1)=0;

subplot(4,1,1);
plot(1:length(rc(isnan(acc)==0)),rc(isnan(acc)==0),'k');ylabel('annot')
title(s{m}.Patient)
subplot(4,1,2);
plot(1:length(acc(isnan(acc)==0)),acc(isnan(acc)==0),'r');ylabel('acc')
subplot(4,1,3);
plot(1:length(eda(isnan(acc)==0)),eda(isnan(acc)==0),'g');ylabel('eda')
subplot(4,1,4);
plot(1:length(temp(isnan(acc)==0)),temp(isnan(acc)==0),'b');ylabel('temp')

%%
figure;
[a,b]=sort(acc(isnan(acc)==0));
rc0 = rc(isnan(acc)==0);
acc0 = acc(isnan(acc)==0);
temp0 = temp(isnan(acc)==0);
eda0 = eda(isnan(acc)==0);
subplot(4,1,1);
stem(1:length(rc(isnan(acc)==0)),rc0(b));ylabel('annot')
subplot(4,1,2);
plot(1:length(acc(isnan(acc)==0)),acc0(b),'r');ylabel('acc')
subplot(4,1,3);
plot(1:length(eda(isnan(acc)==0)),eda0(b),'g');ylabel('eda')
subplot(4,1,4);
plot(1:length(temp(isnan(acc)==0)),temp0(b),'b');ylabel('temp')

