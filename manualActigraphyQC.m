function manualActigraphyQC()
%
% Actigraphy QC Analysis
% ----------------------
% ABOUT: This software performs a user-guided assessment of wrist
% actigraphy data. 
%
% USE: manualactigraphyQC()
%       (1) The program will first ask for a directory in str format. Choose
%       the parent directory in which all patients are listed.
%       e.g. '~/Baker/Actigraphy/' or '~/Baker/Actigraphy'
%       (2) You will then be directed to select a patient from a list. Data
%       are then imported automatically from that patient's actigraphy
%       folder.
%       (3) Select a type of transition (still, slow, moderate, or
%       vigorous). A list of associated transitions from the REDCap data
%       will then be displayed. Choose an appropriate transition.
%       (4) Choose a time window (sec).
%       (5) Actigraphy data are then plotted in a 2x2 window. You can
%       choose to save this figure.
%       (6) You can choose to repeat the analysis for other transition
%       events and to save associated figures.
%       (7) Finally choose to save the actigraphy data in MAT format if you
%       so desire. Note that this step will not affect future runs of the
%       program at this time.
%
% ----------------------
% Author: Joshua D. Salvi
% josh.salvi@gmail.com
% ----------------------
%

    dir0 = input('Which directory? ');
    
    if dir0(end) ~= '/'
            dir0 = [dir0 '/'];
        end
    q=1;
    files0 = dir(dir0);
    for j = 1:length(files0)
        if length(files0(j).name) == 5
            patients{q} = files0(j).name;
            disp(['(' num2str(q) ') ' patients{q}])
            q = q + 1;
        end
    end

    patientChoice = input('Choose a patient: ');

    dir0 = [dir0 patients{patientChoice} '/'];

    dir0Act = [dir0 'actigraphy/raw/'];
    dir0RC = [dir0 'redcap/processed/'];
    
    pp = 1;
    pp0 = 0;
    while pp == 1
        
        files = dir(dir0Act);
        
        if pp0 == 0
            % Import Data
            disp('Importing...')
            for p0 = 1:length(files)
                try
                    if isempty(findstr(files(p0).name,'acc.csv')) == 0
                        disp(files(p0).name)
                        data = importdata([dir0Act files(p0).name]); acc = data.data;
                    elseif isempty(findstr(files(p0).name,'temp.csv')) == 0
                        disp(files(p0).name)
                        data = importdata([dir0Act files(p0).name]); temp = data.data;
                    elseif isempty(findstr(files(p0).name,'eda.csv')) == 0
                        disp(files(p0).name)
                        data = importdata([dir0Act files(p0).name]); eda = data.data;
                    end
                end
            end
            pp0 = 1; clear p0
            disp('Importing complete.')
        end
        
        fprintf('%s\n%s\n%s\n%s\n','(1) still','(2) slow','(3) moderate','(4) vigorous');
        transtype = input('Transition type: ');
        if transtype == 1
            transout0 = strsplit(evalc('system([''cat '' dir0RC ''DIA_'' patients{patientChoice} ''_redcap_events_trans.csv | grep still'']);'),'\n');
        elseif transtype == 2
            transout0 = strsplit(evalc('system([''cat '' dir0RC ''DIA_'' patients{patientChoice} ''_redcap_events_trans.csv | grep slow'']);'),'\n');
        elseif transtype == 3
            transout0 = strsplit(evalc('system([''cat '' dir0RC ''DIA_'' patients{patientChoice} ''_redcap_events_trans.csv | grep moderate'']);'),'\n');
        elseif transtype == 4
            transout0 = strsplit(evalc('system([''cat '' dir0RC ''DIA_'' patients{patientChoice} ''_redcap_events_trans.csv | grep vigorous'']);'),'\n');
        end

        q = 1;
        for j = 1:length(transout0)
            if isempty(findstr(transout0{j},patients{patientChoice})) == 0
                transout{q} = transout0{j};
                disp(['(' num2str(q) ') ' transout{q}])
                q = q + 1;
            end
        end
        inputStrChoice = input('Transition to analyze: ');
        inputStr = transout{inputStrChoice};
        trange = input('Time window (sec): ');
        
        qrc = find(inputStr == ':'); qrc = qrc(end);
        inputStr2 = strsplit(inputStr,' '); inputStr2 = strsplit(inputStr2{4},':');
        lab1 = inputStr2{1}(1); lab2 = inputStr2{2}(1);
        
        formatIn = 'yyyy-mm-dd HH:MM:SS';
        datenum_ms = 86400e3*(datenum(inputStr(7:25),formatIn)-719529);

        qa = findnearest(acc(:,1),datenum_ms);
        qt = findnearest(temp(:,1),datenum_ms);
        qe = findnearest(eda(:,1),datenum_ms);

        Fsa = round(1/((acc(2,1)-acc(1,1))*1e-3));
        Fst = round(1/((temp(2,1)-temp(1,1))*1e-3));
        Fse = round(1/((eda(2,1)-eda(1,1))*1e-3));

        rga = trange * Fsa;
        rgt = trange * Fst;
        rge = trange * Fse;

        displ = sqrt(gradient(acc(:,2)).^2 + gradient(acc(:,3)).^2 + gradient(acc(:,4)).^2);
        vel = gradient(displ);
        velRS = sqrt(vel.^2);
        accel = gradient(vel);
        accelRS = sqrt(accel.^2);

        close all;h0 = figure;

        subplot(2,2,1);
        rectangle('Position',[0 1.05*min(vel(qa-rga:qa+rga)) acc(qa+rga,1)/1e3-acc(qa,1)/1e3 1.05*max(vel(qa-rga:qa+rga))-1.05*min(vel(qa-rga:qa+rga))],'FaceColor',[.7 .7 .7],'EdgeColor',[0 0 0])
        hold on; plot(acc(qa-rga:qa+rga,1)/1e3 - acc(qa,1)/1e3, vel(qa-rga:qa+rga));
        plot(zeros(1,100),linspace(1.05*min(vel(qa-rga:qa+rga)), 1.05*max(vel(qa-rga:qa+rga)), 100), 'k--');
        axis tight; box on;
        text(trange/2,max(vel(qa-rga:qa+rga)),0,lab2);
        text(-trange/2,max(vel(qa-rga:qa+rga)),0,lab1);
        xlabel('t_r_e_l (sec)'); ylabel('vel')
        title(inputStr);

        subplot(2,2,2);
        rectangle('Position',[0 1.05*min(velRS(qa-rga:qa+rga)) acc(qa+rga,1)/1e3-acc(qa,1)/1e3 1.05*max(velRS(qa-rga:qa+rga))-1.05*min(velRS(qa-rga:qa+rga))],'FaceColor',[.7 .7 .7],'EdgeColor',[0 0 0])
        hold on; plot(acc(qa-rga:qa+rga,1)/1e3 - acc(qa,1)/1e3, velRS(qa-rga:qa+rga));
        plot(zeros(1,100),linspace(1.05*min(velRS(qa-rga:qa+rga)), 1.05*max(velRS(qa-rga:qa+rga)), 100), 'k--');
        axis tight; box on;
        text(trange/2,max(velRS(qa-rga:qa+rga)),0,lab2);
        text(-trange/2,max(velRS(qa-rga:qa+rga)),0,lab1);
        xlabel('t_r_e_l (sec)'); ylabel('vel_R_S')

        subplot(2,2,3);
        rectangle('Position',[0 min(temp(qt-rgt:qt+rgt,2)) temp(qt+rgt,1)/1e3-temp(qt,1)/1e3 1.05*max(temp(qt-rgt:qt+rgt,2))-1.05*min(temp(qt-rgt:qt+rgt,2))],'FaceColor',[.7 .7 .7],'EdgeColor',[0 0 0])
        hold on; plot(temp(qt-rgt:qt+rgt,1)/1e3 - temp(qt,1)/1e3, temp(qt-rgt:qt+rgt,2));
        plot(zeros(1,100),linspace(min(temp(qt-rgt:qt+rgt,2)), max(temp(qt-rgt:qt+rgt,2)), 100), 'k--');
        axis tight; box on;
        text(trange/2,max(temp(qt-rgt:qt+rgt,2)),0,lab2);
        text(-trange/2,max(temp(qt-rgt:qt+rgt,2)),0,lab1);
        xlabel('t_r_e_l (sec)'); ylabel('temp')

        subplot(2,2,4);
        rectangle('Position',[0 min(eda(qe-rge:qe+rge,2)) eda(qe+rge,1)/1e3-eda(qe,1)/1e3 1.05*max(eda(qe-rge:qe+rge,2))-1.05*min(eda(qe-rge:qe+rge,2))],'FaceColor',[.7 .7 .7],'EdgeColor',[0 0 0])
        hold on; plot(eda(qe-rge:qe+rge,1)/1e3 - eda(qe,1)/1e3, eda(qe-rge:qe+rge,2));
        plot(zeros(1,100),linspace(min(eda(qe-rge:qe+rge,2)), max(eda(qe-rge:qe+rge,2)), 100), 'k--');
        axis tight; box on;
        text(trange/2,max(eda(qe-rge:qe+rge,2)),0,lab2);
        text(-trange/2,max(eda(qe-rge:qe+rge,2)),0,lab1);
        xlabel('t_r_e_l (sec)'); ylabel('eda')
        
        savefigYN = input('Save figure? (1=yes): ');
        if savefigYN == 1
            try
                warning off; mkdir(dir0,'figures');
            end
            savefig(h0, [dir0 '/figures/' inputStr '-' num2str(trange) 'sec' '.fig']);
            saveas(h0, [dir0 '/figures/' inputStr '-' num2str(trange) 'sec' '.eps']);
            saveas(h0, [dir0 '/figures/' inputStr '-' num2str(trange) 'sec' '.png']);
        end
        
        pp = input('Repeat for another time window? (1=yes): ');
        
    end
    savedataYN = input('Save data? (1=yes): ');
    if savedataYN == 1
        save([dir0 'output.mat'],'acc','temp','eda');
    end
end

function [r,c,V] = findnearest(srchvalue,srcharray,bias)

    if nargin<2
        error('Need two inputs: Search value and search array')
    elseif nargin<3
        bias = 0;
    end

    % find the differences
    srcharray = srcharray-srchvalue;

    if bias == -1   % only choose values <= to the search value
        srcharray(srcharray>0) =inf;
    elseif bias == 1  % only choose values >= to the search value
        srcharray(srcharray<0) =inf;
    end

    % give the correct output
    if nargout==1 | nargout==0
        if all(isinf(srcharray(:)))
            r = [];
        else
            r = find(abs(srcharray)==min(abs(srcharray(:))));
        end 
    elseif nargout>1
        if all(isinf(srcharray(:)))
            r = [];c=[];
        else
            [r,c] = find(abs(srcharray)==min(abs(srcharray(:))));
        end
        if nargout==3
            V = srcharray(r,c)+srchvalue;
        end
    end
end
