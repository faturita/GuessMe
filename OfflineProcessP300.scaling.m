% Signal Averaging x Selection g.Tec Dataset.

% run('/Users/rramele/work/vlfeat/toolbox/vl_setup')
% run('D:/workspace/vlfeat/toolbox/vl_setup')
% run('C:/vlfeat/toolbox/vl_setup')
% P300

%clear all;
%close all;

rng(396544);

globalnumberofepochspertrial=10;
globalaverages= cell(2,1);
globalartifacts = 0;
globalreps=10;
globalnumberofepochs=(2+10)*globalreps-1;

clear mex;clearvars  -except global*;close all;clc;

nbofclassespertrial=(2+10)*(10/globalreps);
breakonepochlimit=(2+10)*globalrepetitions-1;

% Clean all the directories where the images are located.
cleanimagedirectory();


% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

%     'Fz'    'Cz'    'Pz'    'Oz'    'P3'    'P4'    'PO7'    'PO8'

channels={ 'Fz '  ,  'Cz ',    'Pz ' ,   'Oz '  ,  'P3 '  ,  'P4 '   , 'PO7'   , 'PO8'};
channels={ 'Fz'  ,  'Cz',    'P3' ,   'Pz'  ,  'P4'  , 'PO7'   , 'PO8',  'Oz'};

% Parameters ==========================
subjectRange=[1 2 3 4 6 7 8 9 10 11 13 14 15 16 17 18 19 20 21 22 23];
subjectRange=[1 3 4 6 7 9 10 11 13 14 16 17 18 19 20 21 22 23];

%2,15, 8 high impeadance empty trials.

subjectRange=[1 11 14   16 17 20 22 23];

%subjectRange=22;

epochRange = 1:120*7*5;
channelRange=1:8;
labelRange = [];
siftscale = [3 3];  % Determines lamda length [ms] and signal amp [microV]
imagescale=4;    % Para agarrar dos decimales NN.NNNN
timescale=4;
qKS=32-3;
minimagesize=floor(sqrt(2)*15*siftscale(2)+1);
amplitude=3;
adaptative=false;
k=7;
artifactcheck=false;

siftdescriptordensity=1;
Fs=250;
windowsize=1;
expcode=2400;
show=0;
downsize=15;
applyzscore=true;
featuretype=1;
distancetype='cosine';
classifier=6;

% featuretype=2;
% timescale=1;
%applyzscore=false;
% classifier=5;
%amplitude=1;
artifactcheck=true;
% =====================================

% EEG(subject,trial,flash)
EEG = prepareEEG(Fs,windowsize,downsize,120,subjectRange,1:8);
KS=10:50;

% CONTROL
%EEG = randomizeEEG(EEG);

trainingRange = 1:nbofclassespertrial*15;

tic
Fs=floor(Fs/downsize);

sqKS = [37; 16; 13; 45; 47; 35; 31; 28;39; 33;   28;  ...
    33; 33; 35; ...
    33; 50; ...
    37; ...
    33; 33; 33; ...
    33; 29; ...
    39];

 sqKS = [37; -1;...
     16;    13;  -1;  45;    47; -1; 35; 31; 28;...
     -1; 39;    35;...
     -1; 50;...
     37;...
     43;    36;    33;...
     28;...
     29;...
     39];

% subjectRange=[1 11 14   16 17 20 22 23];
% sqKS = [37; 28; 35; 50; 37; 33; 29; 39]
 
 
 
%%
% Build routput pasting epochs toghether...
for subject=subjectRange
    for trial=1:35
        for i=1:12 hit{subject}{trial}{i} = 0; end
        for i=1:12 routput{subject}{trial}{i} = []; end
        for i=1:12 artifact{subject}{trial}{i} = 0; end
        for i=1:12 rcounter{subject}{trial}{i} = 0; end
        processedflashes=0;
        for flash=1:120
            if ((breakonepochlimit>0) && (processedflashes > breakonepochlimit))
                break;
            end
            % Skip artifacts
            if (artifactcheck && EEG(subject,trial,flash).isartifact)
                artifact{subject}{trial}{EEG(subject,trial,flash).stim}=artifact{subject}{trial}{EEG(subject,trial,flash).stim}+1;
                continue;
            end
            rcounter{subject}{trial}{EEG(subject,trial,flash).stim} = rcounter{subject}{trial}{EEG(subject,trial,flash).stim}+1;

            output = EEG(subject,trial,flash).EEG;
            routput{subject}{trial}{EEG(subject,trial,flash).stim} = [routput{subject}{trial}{EEG(subject,trial,flash).stim} ;output];
            
            if (hit{subject}{trial}{EEG(subject,trial,flash).stim}>0 && ...
                    hit{subject}{trial}{EEG(subject,trial,flash).stim} ~= EEG(subject,trial,flash).label)
                error('Inconsistent hit assignation.');
            end
            processedflashes = processedflashes+1;
            hit{subject}{trial}{EEG(subject,trial,flash).stim} = EEG(subject,trial,flash).label;
                     
        end
    end
end

% Checkpoint
for subject=subjectRange
    for trial=1:35
        % Check if all the epochs contain 10 repetitions.
        for i=1:12
            assert( rcounter{subject}{trial}{i} >= 1, 'Some trials are empty due to artifacts (likely low high impeadance)' );
        end
    end
end

for subject=subjectRange
    h=[];
    Word=[];
    for trial=1:35
        hh = [];
        for i=1:12
            rput{i} = routput{subject}{trial}{i};
            channelRange = (1:size(rput{i},2));
            channelsize = size(channelRange,2);

            assert( artifactcheck || size(rput{i},1)/(Fs*windowsize) == rcounter{subject}{trial}{i}, 'Something wrong with PtP average. Sizes do not match.');

            rput{i}=reshape(rput{i},[(Fs*windowsize) size(rput{i},1)/(Fs*windowsize) channelsize]); 

            for channel=channelRange
                rmean{i}(:,channel) = mean(rput{i}(:,:,channel),2);
            end

            if (hit{subject}{trial}{i} == 2)
                h = [h i];
                hh = [hh i];
            end    
            routput{subject}{trial}{i} = rmean{i};
        end
        Word = [Word SpellMeLetter(hh(1),hh(2))];
    end
end

for subject=subjectRange
    for trial=1:35
        
        for i=1:12

            rmean{i} = routput{subject}{trial}{i};
            
            if (timescale ~= 1)
                for c=channelRange
                    rsignal{i}(:,c) = resample(rmean{i}(:,c),size(rmean{i},1)*timescale,size(rmean{i},1));
                    %rsignal{i}(:,c) = resample(rmean{i}(:,c),1:size(rmean{i},1),timescale);
                end
            else
                rsignal{i} = rmean{i};
            end

            if (applyzscore)
                rsignal{i} = zscore(rsignal{i})*amplitude;
            else
                rsignal{i} = rsignal{i}*amplitude;
            end
            
            routput{subject}{trial}{i} = rsignal{i};
        end
    end
end




if (featuretype == 1)
    for subject=subjectRange
        epoch=0;
        labelRange=[];
        epochRange=[];
        stimRange=[];
        for trial=1:35        
            for i=1:12
            epoch=epoch+1;    
            label = hit{subject}{trial}{i};
            labelRange(epoch) = label;
            stimRange(epoch) = i;
            DS = [];
            rsignal{i}=routput{subject}{trial}{i};
            for channel=channelRange
                %minimagesize=1;
                %[eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,1, false,minimagesize);
                [eegimg, DOTS, zerolevel, height] = eegimagecenteredimage(channel,rsignal{i},imagescale,1, false,minimagesize);
                %siftscale(1) = 11.7851;
                siftscale(2) = (height-1)/(sqrt(2)*15);
                saveeegimage(subject,epoch,label,channel,eegimg);
                zerolevel = size(eegimg,1)/2;

    %             if ((size(find(trainingRange==epoch),2)==0))
    %                qKS=ceil(0.20*(Fs)*timescale):floor(0.20*(Fs)*timescale+(Fs)*timescale/4-1);
    %             else
                    qKS=sqKS(subject);
                    %qKS=KS(globaliterations);
                    %qKS=125;
    %             end

                [frames, desc] = PlaceDescriptorsByImage(eegimg, DOTS,siftscale, siftdescriptordensity,qKS,zerolevel,false,distancetype);            
                F(channel,label,epoch).stim = i;
                F(channel,label,epoch).hit = hit{subject}{trial}{i};


                F(channel,label,epoch).descriptors = desc;
                F(channel,label,epoch).frames = frames; 
            end
            end
        end
        
        epochRange=1:epoch;
        trainingRange = 1:nbofclassespertrial*15;
        testRange=nbofclassespertrial*15+1:min(nbofclassespertrial*35,epoch);

        %trainingRange=1:nbofclasses*35;

        SBJ(subject).F = F;
        SBJ(subject).epochRange = epochRange;
        SBJ(subject).labelRange = labelRange;
        SBJ(subject).trainingRange = trainingRange;
        SBJ(subject).testRange = testRange;
        
        
    end
else
    for subject=subjectRange
        epoch=0;
        labelRange=[];
        epochRange=[];
        stimRange=[];
        for trial=1:35        
            for i=1:12
                epoch=epoch+1;    
                label = hit{subject}{trial}{i};
                labelRange(epoch) = label;
                stimRange(epoch) = i;
                DS = [];
                rsignal{i}=routput{subject}{trial}{i};

                feature = [];

                for channel=channelRange
                    feature = [feature ; rsignal{i}(:,channel)];
                end  

                for channel=channelRange
                    F(channel,label,epoch).hit = hit{subject}{trial}{i};
                    F(channel,label,epoch).descriptors = feature;
                    F(channel,label,epoch).frames = [];   
                    F(channel,label,epoch).stim = i;
                end    
            end
        end
        epochRange=1:epoch;
        trainingRange = 1:nbofclassespertrial*15;
        testRange=nbofclassespertrial*15+1:min(nbofclassespertrial*35,epoch);

        %trainingRange=1:nbofclasses*35;

        SBJ(subject).F = F;
        SBJ(subject).epochRange = epochRange;
        SBJ(subject).labelRange = labelRange;
        SBJ(subject).trainingRange = trainingRange;
        SBJ(subject).testRange = testRange;        
    end
end


for subject=subjectRange  
    
    F=SBJ(subject).F;
    epochRange=SBJ(subject).epochRange;
    labelRange=SBJ(subject).labelRange;
    trainingRange=SBJ(subject).trainingRange;
    testRange=SBJ(subject).testRange;
        
    switch classifier
        case 5
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = LDAClassifier(F,labelRange,trainingRange,testRange,channel);
                globalaccij1(subject,channel)=ACC;
                globalsigmaaccij1 = globalaccij1;
                globalaccij2(subject,channel)=AUC;
            end  
        case 4
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = SVMClassifier(F,labelRange,trainingRange,testRange,channel);
                globalaccij1(subject,channel)=ACC;
                globalsigmaaccij1 = globalaccij1;
                globalaccij2(subject,channel)=AUC;
            end            
        case 1
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = NNetClassifier(F,labelRange,trainingRange,testRange,channel);
                globalaccij1(subject,channel)=ACC;
                globalsigmaaccij1 = globalaccij1;
                globalaccij2(subject,channel)=AUC;
            end
        case 2
            [AccuracyPerChannel, SigmaPerChannel] = CrossValidated(F,epochRange,labelRange,channelRange, @IterativeNBNNClassifier,1);
            globalaccij1(subject,:)=AccuracyPerChannel
            globalsigmaaccij1(subject,:)=SigmaPerChannel;
            globalaccijpernumberofsamples(globalnumberofepochs,subject,:) = globalaccij1(subject,:);
        case 3
            for channel=channelRange
                [DE(channel), ACC, ERR, AUC, SC(channel)] = IterativeNBNNClassifier(F,channel,trainingRange,labelRange,testRange,false,false);

                globalaccij1(subject,channel)=1-ERR/size(testRange,2);
                globalaccij2(subject,channel)=AUC;
                globalsigmaaccij1 = globalaccij1;
            end
        case 6
            for channel=channelRange
                DE(channel) = NBNNFeatureExtractor(F,channel,trainingRange,labelRange,[1 2],false); 
   
                %[ACC, ERR, AUC, SC(channel)] = NBMultiClass(F,DE(channel),channel,testRange,labelRange,false);
                [ACC, ERR, AUC, SC(channel)] = NBNNClassifier4(F,DE(channel),channel,testRange,labelRange,false,distancetype,k);                                                        
                
                globalaccij1(subject,channel)=1-ERR/size(testRange,2);
                globalaccij2(subject,channel)=AUC;
                globalsigmaaccij1 = globalaccij1;
            end

    end
    SBJ(subject).DE = DE;
    SBJ(subject).SC = SC;
end

%%
for subject=subjectRange
    % '2'    'B'    'A'    'C'    'I'    '5'    'R'    'O'    'S'    'E'    'Z'  'U'    'P'    'P'    'A'   
    % 'G' 'A' 'T' 'T' 'O'    'M' 'E' 'N''T' 'E'   'V''I''O''L''A'  'R''E''B''U''S'
    Speller = SpellMe(F,channelRange,16*nbofclassespertrial/12:35*nbofclassespertrial/12+(nbofclassespertrial/12-1),labelRange,trainingRange,testRange,SBJ(subject).SC);

    S = 'MANSOCINCOJUEGOQUESO';
    S = repmat(S,nbofclassespertrial/12);
    S = reshape( S, [1 size(S,1)*size(S,2)]);
    S=S(1:size(S,2)/(nbofclassespertrial/12));
    
    SpAcc = [];
    for channel=channelRange
        counter=0;
        for i=1:size(S,2)
            if Speller{channel}{i}==S(i)
                counter=counter+1;
            end
        end
        spellingacc = counter/size(S,2);
        SpAcc(end+1) = spellingacc;
        globalspeller(subject,channel) = spellingacc;
        globalspellers(subject,channel,globalrepetitions) = spellingacc;
    
    end
    [a,b] = max(SpAcc);
end

experiment=sprintf(' K = %d ',k);
fid = fopen('experiment.log','a');
fprintf(fid,'Experiment: %s \n', experiment);
fprintf(fid,'st %f sv %f scale %f timescale %f qKS %d\n',siftscale(1),siftscale(2),imagescale,timescale,qKS);
totals = DisplayTotals(subjectRange,globalaccij1,globalspeller,globalaccij2,globalspeller,channels)
totals(:,6)
fclose(fid)