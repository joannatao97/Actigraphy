function [actigraphyData QC] = autoActigraphyQC()
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
%       (2) Select a time window.
%       (3) Select a type of transition (still, slow, moderate, or
%       vigorous). A list of associated transitions from the REDCap data
%       will then be displayed. Choose an appropriate transition.
%
% ----------------------
% Author: Joshua D. Salvi
% josh.salvi@gmail.com
% ----------------------
%

    dir01 = input('Which directory? ');
    
    if dir01(end) ~= '/'
            dir01 = [dir01 '/'];
        end
    q=1;
    files0 = dir(dir01);
    for j = 1:length(files0)
        if length(files0(j).name) == 5
            patients{q} = files0(j).name;
%             disp(['(' num2str(q) ') ' patients{q}])
            q = q + 1;
        end
    end
    trans0 = [{'still'}, {'slow'}, {'moderate'}, {'vigorous'}];
    fprintf('%s\n%s\n%s\n%s\n','(1) still','(2) slow','(3) moderate','(4) vigorous');
    transtype1 = trans0{input('Activity 1: ')};
    transtype2 = trans0{input('Activity 2: ')};
    transtype = [transtype1 ':' transtype2]; disp(['Selected transition ' transtype]);
    
    trange = input('Time window (sec): ');
    
    for patientChoice = 1:length(patients)
        
        QC(patientChoice) = 1;
        
        dir0 = [dir01 patients{patientChoice} '/'];

        dir0Act = [dir0 'actigraphy/raw/'];
        dir0RC = [dir0 'redcap/processed/'];

        pp = 1;
        pp0 = 0;
        
        files = dir(dir0Act);
        actigraphyData{patientChoice}.patient = patients{patientChoice};
        
        if pp0 == 0
            % Import Data
            disp(['Patient ' patients{patientChoice}]);
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
        
        try
        transout0 = strsplit(evalc('system([''cat '' dir0RC ''DIA_'' patients{patientChoice} ''_redcap_events_trans.csv | grep '' transtype]);'),'\n');
                
        q = 1;
        for j = 1:length(transout0)
            if isempty(findstr(transout0{j},patients{patientChoice})) == 0
                transout{q} = transout0{j};
%                 disp(['(' num2str(q) ') ' transout{q}])
                q = q + 1;
            end
        end
        
        actigraphyData{patientChoice}.transitions = transout;
        
        catch
            disp('No transitions found.');
            actigraphyData{patientChoice}.transitions = 'None';
            QC(patientChoice) = 0;
        end
        
        try
            
        for inputStrChoice = 1:length(transout)
            try
            inputStr = transout{inputStrChoice}
        
            qrc = find(inputStr == ':'); qrc = qrc(end);
        
            formatIn = 'yyyy-mm-dd HH:MM:SS';
            datenum_ms = 86400e3 * (datenum(inputStr(7:25),formatIn) - 719529);
            catch
                disp('error 1');
                QC(patientChoice) = 0;
            end
            try
            qa = findnearest(acc(:,1),datenum_ms);
            qt = findnearest(temp(:,1),datenum_ms);
            qe = findnearest(eda(:,1),datenum_ms);

            Fsa = round(1/((acc(2,1)-acc(1,1))*1e-3));
            Fst = round(1/((temp(2,1)-temp(1,1))*1e-3));
            Fse = round(1/((eda(2,1)-eda(1,1))*1e-3));
            catch
                disp('error 2');
                QC(patientChoice) = 0;
            end
            try
            rga = trange * Fsa;
            rgt = trange * Fst;
            rge = trange * Fse;

            displ = sqrt(gradient(acc(:,2)).^2 + gradient(acc(:,3)).^2 + gradient(acc(:,4)).^2);
            vel = gradient(displ);
            velRS = sqrt(vel.^2);
            accel = gradient(vel);
            accelRS = sqrt(accel.^2);
            catch
                disp('error 3')
                QC(patientChoice) = 0;
            end
            
%             try

            actigraphyDataACC(inputStrChoice,:,1) = acc(qa-rga:qa+rga,1)/1e3 - acc(qa,1)/1e3;
            actigraphyDataACC(inputStrChoice,:,2) = vel(qa-rga:qa+rga);
            
            actigraphyDataACCRS(inputStrChoice,:,1) = acc(qa-rga:qa+rga,1)/1e3 - acc(qa,1)/1e3;
            actigraphyDataACCRS(inputStrChoice,:,2) = velRS(qa-rga:qa+rga);
            
            actigraphyDataTEMP(inputStrChoice,:,1) = temp(qt-rgt:qt+rgt,1)/1e3 - temp(qt,1)/1e3;
            actigraphyDataTEMP(inputStrChoice,:,2) = temp(qt-rgt:qt+rgt,2);
            
            actigraphyDataEDA(inputStrChoice,:,1) = eda(qe-rge:qe+rge,1)/1e3 - eda(qe,1)/1e3;
            actigraphyDataEDA(inputStrChoice,:,2) = eda(qe-rge:qe+rge,2);
%             catch
%                 disp('error 4');
%                 clear inputStr
%             end
            clear inputStr
        end
        
        catch
            disp('Error: Looping through transitions');
            actigraphyDataACC = []; actigraphyDataACCRS = []; 
            actigraphyDataTEMP = []; actigraphyDataEDA = [];
            QC(patientChoice) = 0;
        end
        try
        actigraphyData{patientChoice}.ACC = actigraphyDataACC;
        actigraphyData{patientChoice}.ACCRS = actigraphyDataACCRS;
        actigraphyData{patientChoice}.TEMP = actigraphyDataTEMP;
        actigraphyData{patientChoice}.EDA = actigraphyDataEDA;
        catch
            disp('error 5')
            QC(patientChoice) = 0;
        end
        
        clear actigraphyDataACC actigraphyDataACCRS actigraphyDataTEMP actigraphyDataEDA transout inputStr
        
    end
    
    savedataYN = input('Save data? (1=yes): ');
    if savedataYN == 1
        save([dir01 date 'output-' transtype '-auto.mat'], 'actigraphyData', 'trange' ,'QC');
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
