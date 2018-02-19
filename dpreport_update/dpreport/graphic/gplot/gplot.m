function gplot(array,header,low,high,label)
format long g
a=load(array);


% First scale all values from 0 to 1 based on linear mapping between low and high
b=(a-low)/(high-low);

% Next clip high and low values
b(b>1)=1;
b(b<0)=0;

% Next project from 1 to 55 (to work with 56-bin colormap)
c=(54*b)+1;


% Finally swap NaN values for 0
c(isnan(c))=0;

% Then plot imagesc
imagesc(c,[0 55]);
axis equal tight;

% The following segment plots white lines onto the imagesc grid for visual clarity
yrange=[ylim];
xrange=[xlim];
xall=[xrange(1):1:xrange(2)];
yall=[yrange(1):1:yrange(2)];

hold on

for i=1:size(xall,2)
x1=repmat(xall(i),1,size(yall,2));
plot(x1,yall,'w','LineWidth',0.1);
end

for i=1:size(yall,2)
y1=repmat(yall(i),1,size(xall,2));
plot(xall,y1,'w','LineWidth',0.1);
end

%axis equal tight
set(gca,'YAxisLocation','right');

%  This section handles the Y-labels
n=size(a,1);
formatspec='%s';
fid=fopen(header,'rt');
headers=textscan(fid,formatspec,n,'delimiter',',');
fclose(fid);

set(gca,'ytick',[1:n]);
set(gca,'yticklabel',headers{:},'fontsize',10);
set(gca,'tickdir','out');
set(gca,'ticklength',[0.0025 0.005]);
set(gca,'Units','pixels')

%ylabel(label,'FontSize',14);

%ylabelpos0=get(get(gca,'ylabel'),'Position');
%set(get(gca,'ylabel'),'Position',[-0.6 ylabelpos0(2) 1]);


set(gcf,'Position',[0 0 4500 900]);
set(gcf,'Clipping','off','PaperUnits','points');

% This section handles the X-labels
xrange=[xlim];
Xn=xrange(2)-0.5;
yrange=[ylim];
Yn=yrange(2)-0.5;

set(gca,'XTick',[10:10:Xn]);
xlabs=[10:10:Xn];
set(gca,'XTickLabel',xlabs(:));
%set(gca,'XTickLabel',[1:Xn]);

% For a 24-hour data set, Yn=24.  To achieve h=300 for Yn=24, so h=1000/24*Yn
% This translates to ~1300 pixel height for 24-row plot.

h=250*Yn/24
w=250*Xn/24;
set(gca,'Position',[40 40 w h]);

ylabel(label,'FontSize',14);

ylabelpos0=get(get(gca,'ylabel'),'Position');
set(get(gca,'ylabel'),'Position',[-0.6 ylabelpos0(2) 1],'Interpreter', 'none');
% This is the colormap that works w this 56-bin scaling, reserving 0 for missing

%load('/eris/sbdp/GSP_Subject_Data/SCRIPTS/modified_jet.mat');
load('/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/dpreport_update/dpreport/graphic/gplot/modified_jet.mat');
set(gcf,'Colormap',A);

exportfig(gcf,[array,'.eps'],'Color','rgb')
