clear mex
clc
clear
clearvars
close all

%run('C:/vlfeat/toolbox/vl_setup')

subjectaverages= cell(0);
subjectartifacts = 0;
subjectsingletriality=119;
%for subjectsingletriality=12*[10:-3:1]-1
for subject = 1:1
clear mex;clearvars  -except subject*;close all;clc;

% Clean all the directories where the images are located.
cleanimagedirectory();

%subject = 2;
% 3 letters
%convert_ov2mat('C:/Workspace/GuessMe/signals/p300-train-[2017.05.09-15.46.13].ov','C:/Workspace/GuessMe/signals/p300-train.mat')
% full 7 letters meaningless.
%convert_ov2mat('C:/Workspace/GuessMe/signals/p300-train-[2017.09.26-14.59.43].ov','C:/Workspace/GuessMe/signals/p300-train.mat')
load('./signals/p300-train.mat');

% Clean EEG image directory
if (exist(sprintf('%s','sidgnals\\*.ov'),'dir'))
    delete(sprintf('%s%s*.ov','signals\\',filesep));
end

% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

%     'Fz'    'Cz'    'Pz'    'Oz'    'P3'    'P4'    'PO7'    'PO8'



samples(find(sampleTime==stims(1,1)),:)

a=find(stims(:,2)==hex2dec('00008205')); % 32779
b=find(stims(:,2)==hex2dec('00008206')); % 32780

%%
fprintf('%04x\n',stims(:,2))


c=find(stims(:,2)==hex2dec('00008005')); % 32773 Trial Start
d=find(stims(:,2)==hex2dec('00008006')); % 32774 Trial Stop
a=find(stims(:,2)==hex2dec('00008205')); % 33285 Hit
b=find(stims(:,2)==hex2dec('00008206')); % 32286 Nohit
e=find(stims(:,2)==hex2dec('0000800C')); % Visual Stimulus Stop
f=find(stims(:,2)==hex2dec('0000800B')); % Visual Stimulus Start

stimuls = [];
for i=1:12
    stimuls = [stimuls; find(stims(:,2)==33025-1+i)];
end

ab = [a; b];

% a hits, b nohits, c and d contain where trial end and stop (five of each
% per letter).

%%
total=0;
for i=1:12
    size(find(stims(:,2)==33025-1+i))
    total=total+size(find(stims(:,2)==33025-1+i))
end


% Los stimulos pueden venir despues de muchas cosas.
counterhits=0;
counternohits=0;
validstimuls=[];
for i=1:size(stimuls,1)
    vl=stims(stimuls(i)-1,1:2)
    if (vl(2) == 33285)
        counterhits = counterhits + 1;
        validstimuls(end+1) = stimuls(i);
    elseif (vl(2) == 33286)
        counternohits = counternohits + 1;
        validstimuls(end+1) = stimuls(i);
    end
    assert ( vl(2)==33285 || vl(2)==33286 || vl(2)==32777 || vl(2) == 897 || vl(2)>=33025 || vl(2)<=33036);
end

% Los que valen son los que estan precedidos por una marca de target o no
% target
% Chequear si los targets estan bien asignados a los mismos estimulos
% dentro del mismo trial.
%%
for trial=1:35
    h=[];
    for i=1:20
        vl=stims(a((trial-1)*20+i)+1,1:2);
        [(trial-1)*35+i vl(2)];
        h=[h vl(2)];
    end
    h = unique(h);
    h
    assert( size(h,2) == 2);
end


%%

ab = sort(ab);

% Cut the stimulus from stims, getting only the time and duration of each.
targets = [ stims(ab,1:3)];

% Remap targets, assigning 1 for NoHit and 2 for Hit.
targets(targets(:,2)==33285,2) = 2;
targets(targets(:,2)==33286,2) = 1;
targets(targets(:,2)==32773,2) = 0;
targets(targets(:,2)==32774,2) = 0;
targets(targets(:,2)==32780,2) = 0;

sls = sort(validstimuls);

stimulations = [ stims(sls,1:3) ];


stimulations(:,2) = stimulations(:,2) - 33025 + 1;
stimulations( stimulations(:,2) < 0) = 0; 


stoptime=stims(c(36),1);

stopsample=find(sampleTime>stims(c(36),1));


sampleTime(stopsample(1):end,:) = [];
samples(stopsample(1):end,:) = [];


z = stims(c,1);

z(36) = [];

targets(4201:end,:) = [];
stimulations(4201:end,:) = [];

% Check target consistency
Word = [];
for trial=1:35
    h=[];
    for i=1:120
        if (targets((trial-1)*120+i,2)==2)
            h = [h stimulations((trial-1)*120+i,2)];
        end
    end
    h = unique(h);
    h
    assert( size(h,2) == 2);
    Word = [Word SpellMeLetter(h(1),h(2))];
end

Word

% Data Structure
data = cell(0);

data.X = samples;
data.y = zeros(size(samples,1),1);
data.y_stim = zeros(size(samples,1),1);
data.trial=zeros(5,1);


Fs=250;

data.flash = [];

for i=1:size(targets,1)
    maximalsampleidx=find(sampleTime>=targets(i,1));
    maximalsampleidx=maximalsampleidx(1);
    loc = find(stims(e,1)>targets(i,1));
    loc = loc(1);
    duration = stims(e(loc),1)-targets(i,1);
    data.flash(end+1,1) = maximalsampleidx 
    data.flash(end,2) = ceil(Fs*duration);
    for j=1:ceil(Fs*duration)
        data.y(maximalsampleidx+j-1) = targets(i,2); 
        data.y_stim(maximalsampleidx+j-1) = stimulations(i,2);
    end
end



for i=1:size(z)
    n=find(sampleTime>z(i));
    data.trial(i)=n(1);
end

data.trial = data.trial';


%%
% Do some check
for i=1:4200
    ss=data.y_stim(data.flash(i)-5:data.flash(i)+40)'
    
    assert ( ss(5) == 0, 'Not zero');
end
%%

%data.X = data.X * 10;
save('p300.mat');


windowsize=1;
downsize=25;
imagescale=4;
timescale=4;
amplitude=3;
sqKS=[20];
siftscale=[4 4];
siftdescriptordensity=1;
minimagesize=floor(sqrt(2)*15*siftscale(2)+1);
nbofclassespertrial=12;
k=7;
adaptative=false;
subjectRange=1:1;

EEG = prepareEEG(Fs,windowsize,downsize,120,1:1,1:8);
Fs=Fs/downsize;

for subject=1:1
    for trial=1:35
        for i=1:12 rcounter{subject}{trial}{i} = 0; end
        for flash=1:120
            rcounter{subject}{trial}{EEG(subject,trial,flash).stim} = rcounter{subject}{trial}{EEG(subject,trial,flash).stim}+1;
        end
    end
end

%%
clear hit
for subject=1:1
    for trial=1:35
        for i=1:12 hit{subject}{trial}{i} = 0; end
        for i=1:12 routput{subject}{trial}{i} = []; end
        for flash=1:120
            output = EEG(subject,trial,flash).EEG;
            routput{subject}{trial}{EEG(subject,trial,flash).stim} = [routput{subject}{trial}{EEG(subject,trial,flash).stim} ;output];
            hit{subject}{trial}{EEG(subject,trial,flash).stim} = EEG(subject,trial,flash).label;
        end
    end
end

%%
h=[];
Word=[];
for subject=1:1
    for trial=1:35
        hh = [];
        for i=1:12
            rput{i} = routput{subject}{trial}{i};
            channelRange = (1:size(rput{i},2));
            channelsize = size(channelRange,2);

            %assert( size(rput{i},1)/(Fs*windowsize) == rcounter{i}, 'Something wrong with PtP average. Sizes do not match.');

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

for subject=1:1
    for trial=1:35
        
        for i=1:12

            rmean{i} = routput{subject}{trial}{i};
            
            for c=channelRange
                %rsignal{i}(:,c) = resample(rmean{i}(:,c),size(rmean{i},1)*timescale,size(rmean{i},1));
                rsignal{i}(:,c) = resample(rmean{i}(:,c),1:size(rmean{i},1),timescale);
            end

            rsignal{i} = zscore(rsignal{i})*amplitude;
            
            routput{subject}{trial}{i} = rsignal{i};
        end
    end
end


%%

epoch=0;
labelRange=[];
epochRange=[];
stimRange=[];
for subject=1:1
    for trial=1:35        
        for i=1:12
        epoch=epoch+1;    
        label = hit{subject}{trial}{i};
        labelRange(epoch) = label;
        stimRange(epoch) = i;
        DS = [];
        rsignal{i}=routput{subject}{trial}{i};
        for channel=channelRange
            [eegimg, DOTS, zerolevel] = eegimage(channel,rsignal{i},imagescale,1, false,minimagesize);

            saveeegimage(subject,epoch,label,channel,eegimg);
            zerolevel = size(eegimg,1)/2;

%             if ((size(find(trainingRange==epoch),2)==0))
%                qKS=ceil(0.20*(Fs)*timescale):floor(0.20*(Fs)*timescale+(Fs)*timescale/4-1);
%             else
                qKS=sqKS(subject);
%             end

            [frames, desc] = PlaceDescriptorsByImage(eegimg, DOTS,siftscale, siftdescriptordensity,qKS,zerolevel,false,'euclidean');            
            F(channel,label,epoch).stim = i;
            F(channel,label,epoch).hit = hit{subject}{trial}{i};
            

            F(channel,label,epoch).descriptors = desc;
            F(channel,label,epoch).frames = frames; 
        end
        end
    end
end
 
end
