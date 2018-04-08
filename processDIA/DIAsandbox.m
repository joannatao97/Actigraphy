plot3(mean(LOR_meanX(1:timerangeBins,:),2),mean(LOR_meanY(1:timerangeBins,:),2),mean(LOR_meanZ(1:timerangeBins,:),2),'b');
hold on;
plot3(mean(LOR_meanX(timerangeBins+2:end,:),2),mean(LOR_meanY(timerangeBins+2:end,:),2),mean(LOR_meanZ(timerangeBins+2:end,:),2),'r');

%%
clear a b mm PSDall explainedVar
close all
inds12 = [1 4 5];
mm=1;
n = length(tvec);
cd = [uint8(255*linspace(0,1,n))'].';
cd0 = [cd.*1;cd.*0;fliplr(cd).*1;cd.*0];
% for j = [1 4 5 ]
for j = inds12
    try
        warning off
        x = [log(LORPRN_XPSD{j})'; log(LORPRN_YPSD{j})'; log(LORPRN_ZPSD{j})'];
        PSDall(:,:,mm) = x;
        [a(:,:,mm), ~, ~, ~, explainedVar] = pca(x);
%         [a(:,:,mm)] = pca2(x,4);
        clear x y z
        x = squeeze(a(:,1,mm)); y = squeeze(a(:,2,mm));
        dist_2D_all(mm) = sqrt((mean(x(3*timerangeBins/4+1:end)) - (mean(x(1:1*timerangeBins/4)))).^2 + (mean(y(3*timerangeBins/4+1:end)) - (mean(y(1:1*timerangeBins/4)))).^2);
        mm = mm+1;
    end
end
clear x y z
x=mean(squeeze(a(:,1,:)),2);
y=mean(squeeze(a(:,2,:)),2);
z=mean(squeeze(a(:,3,:)),2);

% dist_2D = sqrt((mean(x(timerangeBins+1:end)) - (mean(x(1:timerangeBins)))).^2 + (mean(y(timerangeBins+1:end)) - (mean(y(1:timerangeBins)))).^2);
% dist_2D = sqrt((mean(x(3*timerangeBins/4+1:end)) - (mean(x(1:1*timerangeBins/4)))).^2 + (mean(y(3*timerangeBins/4+1:end)) - (mean(y(1:1*timerangeBins/4)))).^2);
% dist_2D = sqrt((x(end)-x(1))^2 + (y(end)-y(1))^2);
dist_2D = mean(dist_2D_all);

% h = figure;
% set(gcf,'Color','k')
subplot_tight(2,2,1,[0.1 0.1]);
p = plot(x,y, 'LineWidth',2);
xlabel('PC1');ylabel('PC2');
try
    title(['Explained variance: ' num2str(round(sum(explainedVar(1:2)))) '%']);
end
pause(1)
set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
% set(gca,'Color','k','XColor','w','YColor','w')
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(2,2,2,[0.1 0.1]);
plot(x(1:timerangeBins), y(1:timerangeBins), 'b'); hold on;
xlabel('PC1');ylabel('PC2');
try
    title(['Explained variance: ' num2str(round(sum(explainedVar(1:2)))) '%']);
end
plot(x(timerangeBins+1:end), y(timerangeBins+1:end), 'r'); hold on;
% set(gca,'Color','k','XColor','w','YColor','w')
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(2,2,3,[0.1 0.1]);
p = plot3(x,y,z, 'LineWidth',2); 
xlabel('PC1');ylabel('PC2');zlabel('PC3');
try
    title(['Explained variance: ' num2str(round(sum(explainedVar(1:3)))) '%']);
end
pause(1)
set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
% set(gca,'Color','k','XColor','w','YColor','w','ZColor','w')
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(2,2,4,[0.1 0.1]);
plot3(x(1:timerangeBins), y(1:timerangeBins), z(1:timerangeBins), 'b'); hold on;
try
    title(['Explained variance: ' num2str(round(sum(explainedVar(1:3)))) '%']);
end
xlabel('PC1');ylabel('PC2');zlabel('PC3');
plot3(x(timerangeBins+1:end), y(timerangeBins+1:end), z(timerangeBins+1:end), 'r'); hold on;
% set(gca,'Color','k','XColor','w','YColor','w','ZColor','w')
set(gca, 'Color', [0.9 0.9 1]); grid on;

figure;
subplot_tight(4,1,1,[0.1 0.1]);
plot(tvec(1:timerangeBins),mean(LORPRN_varX(1:timerangeBins,inds12),2),'b'); hold on;
plot(tvec(timerangeBins+1:end),mean(LORPRN_varX(timerangeBins+1:end,inds12),2),'r'); hold on;
xlabel('time (min)');ylabel('var(X)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(4,1,2,[0.1 0.1]);
plot(tvec(1:timerangeBins),mean(LORPRN_varY(1:timerangeBins,inds12),2),'b'); hold on;
plot(tvec(timerangeBins+1:end),mean(LORPRN_varY(timerangeBins+1:end,inds12),2),'r'); hold on;
xlabel('time (min)');ylabel('var(Y)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(4,1,3,[0.1 0.1]);
plot(tvec(1:timerangeBins),mean(LORPRN_varZ(1:timerangeBins,inds12),2),'b'); hold on;
plot(tvec(timerangeBins+1:end),mean(LORPRN_varZ(timerangeBins+1:end,inds12),2),'r'); hold on;
xlabel('time (min)');ylabel('var(Z)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(4,1,4,[0.1 0.1]);
plot(tvec(1:timerangeBins),mean(LORPRN_varSUM(1:timerangeBins,inds12),2),'b'); hold on;
plot(tvec(timerangeBins+1:end),mean(LORPRN_varSUM(timerangeBins+1:end,inds12),2),'r'); hold on;
xlabel('time (min)');ylabel('var(SUM)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

figure;
subplot_tight(4,1,1,[0.1 0.1]);
p=plot(tvec,mean(LORPRN_varX(:,inds12),2),'b'); hold on;
pause(1);set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
xlabel('time (min)');ylabel('var(X)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(4,1,2,[0.1 0.1]);
p=plot(tvec,mean(LORPRN_varY(:,inds12),2),'b'); hold on;
pause(1);set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
xlabel('time (min)');ylabel('var(Y)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(4,1,3,[0.1 0.1]);
p=plot(tvec,mean(LORPRN_varZ(:,inds12),2),'b'); hold on;
pause(1);set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
xlabel('time (min)');ylabel('var(Z)');
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot_tight(4,1,4,[0.1 0.1]);
p=plot(tvec,mean(LORPRN_varSUM(:,inds12),2),'b'); hold on;
pause(1);set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
xlabel('time (min)');ylabel('var(SUM)');
set(gca, 'Color', [0.9 0.9 1]); grid on;
%%
% for j = 1:length(LORPRN_XPSD)
GAIN = 2;mm=1;
close all
for j = inds12
    
    x = (LORPRN_XPSD{j})';
    y = (LORPRN_YPSD{j})';
    z = (LORPRN_ZPSD{j})';

    x = (x-min(min(x)))/(max(max(x)) - min(min(x)));
    y = (y-min(min(y)))/(max(max(y)) - min(min(y)));
    z = (z-min(min(z)))/(max(max(z)) - min(min(z)));
%     x = abs(x.*255 - 255);
%     y = abs(y.*255 - 255);
%     z = abs(z.*255 - 255);
    x = x.*255;
    y = y.*255;
    z = z.*255;
    
    specall(:,:,1) = x;
    specall(:,:,2) = y;
    specall(:,:,3) = z;
    specall = specall.*GAIN;
    
%     figure(j)
    subplot_tight(length(inds12),1,mm,[0.07 0.07]);
    imagesc(tvec,linspace(1,16,size(LORPRN_XPSD{j},2)), specall);
    hold on;plot(zeros(1,16),linspace(1,16,16),'w')
    xlabel('min')
    ylabel('Hz')
%     title(['example ' num2str(j)])
    
    mm=mm+1;

    
    %{
    figure(j);
    subplot(3,1,1);
    imagesc(tvec,linspace(1,16,size(LORPRN_XPSD{j},2)),log(LORPRN_XPSD{j})');
    h=colorbar;
    title(['example ' num2str(j)])
%     set(h,'ylabel','X');
    
    subplot(3,1,2);
    imagesc(tvec,linspace(1,16,size(LORPRN_XPSD{j},2)),log(LORPRN_YPSD{j})');
    h=colorbar;
%     set(h,'ylabel','Y');
    
    subplot(3,1,3);
    imagesc(tvec,linspace(1,16,size(LORPRN_XPSD{j},2)),log(LORPRN_ZPSD{j})');
    h=colorbar;
%     set(h,'ylabel','Z');
    %}
end

%% bootstrap random euclidean distances

nboot = 1e4;
% mm=1;
% clear x_null a_null PSDall_null a1_null a1_null1 a1_null2 a2_null a2_null1 a2_null2 a3_null a3_null1 a3_null2
for m = 1:nboot
    try
        ind = round(unifrnd(0,1,1)*size(actdataXPSD,1));
        trange = ind-timerangeBins:ind+timerangeBins;
        warning off
        x_null = [actdataXPSD(trange,:)'; actdataYPSD(trange,:)'; actdataZPSD(trange,:)'];
        clear a_null
        [a_null(:,:,mm), ~, ~, ~, explainedVar] = pca(x_null);
%         PSDall_null(:,:,mm) = x_null;
        a1_null(:,mm) = a_null(:,1,mm);a1_null1(:,mm) = a1_null(1:1*timerangeBins/4,mm);a1_null2(:,mm) = a1_null(3*timerangeBins/4+1:end,mm);
        a2_null(:,mm) = a_null(:,2,mm);a2_null1(:,mm) = a2_null(1:1*timerangeBins/4,mm);a2_null2(:,mm) = a2_null(3*timerangeBins/4+1:end,mm);
        a3_null(:,mm) = a_null(:,3,mm);a3_null1(:,mm) = a3_null(1:1*timerangeBins/4,mm);a3_null2(:,mm) = a3_null(3*timerangeBins/4+1:end,mm);
        dist_null_2D(mm) = sqrt((mean(a1_null2(:,mm))-mean(a1_null1(:,mm))).^2 + (mean(a2_null2(:,mm))-mean(a2_null1(:,mm))).^2);
        dist_null_3D(mm) = sqrt((mean(a1_null2(:,mm))-mean(a1_null1(:,mm))).^2 + (mean(a2_null2(:,mm))-mean(a2_null1(:,mm))).^2 + (mean(a3_null2(:,mm))-mean(a3_null1(:,mm))).^2);
        mm=mm+1;
        if mod(mm,50) == 0
            disp(mm)
        end
    end
end
%% calculate the p-values
close all

xi = linspace(0,2*max(dist_null_2D),1e4);
[x1,x2] = ksdensity(dist_null_2D,xi,'function','pdf');
q = findnearest(x2,dist_2D);
pval = trapz(x2(q:end),x1(q:end));

x1=x1./sum(x1);

subplot(1,3,1);
p = plot(x,y, 'LineWidth',2);
axis([min(x) max(x) min(y) max(y)])
xlabel('PC1');ylabel('PC2');
title('Aligned data');
pause(1)
set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot(1,3,2);
p=plot(mean(a1_null,2),mean(a2_null,2));
axis([min(mean(a1_null,2)) max(mean(a1_null,2)) min(mean(a2_null,2)) max(mean(a2_null,2))]);
pause(1);
set(p.Edge, 'ColorBinding','interpolated', 'ColorData',cd0)
title('Null data')
xlabel('PC1');ylabel('PC2')
set(gca, 'Color', [0.9 0.9 1]); grid on;

subplot(1,3,3);
plot(x2,x1.*1e4);hold on;
plot(x2(q).*ones(1,5),linspace(0,x1(q).*1e4,5),'r--')
axis([min(x2) max(x2) 0 max(x1.*1e4)])
xlabel('dist'); ylabel('p(dist) *10^-^4')
% title(['nboot=' num2str(nboot) ' ; p=' num2str(round(pval,4))]);
title(['nboot=' num2str(sprintf('%.0e',nboot)) ' ; p=' num2str(round(pval,4))]);
set(gca, 'Color', [0.9 0.9 1]); grid on;


