clear mex
clc
clear
clearvars
close all

%run('C:/vlfeat/toolbox/vl_setup')
rng(396544);

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

if (exist('p300.mat','file'))
    delete('p300.mat');
end

% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

%     'Fz'    'Cz'    'Pz'    'Oz'    'P3'    'P4'    'PO7'    'PO8'
channelRange=1:8;


samples(find(sampleTime==stims(1,1)),:)

a=find(stims(:,2)==hex2dec('00008205')); % 32779
b=find(stims(:,2)==hex2dec('00008206')); % 32780

%%
fprintf('%04x\n',stims(:,2))

% First, get the stimulus to different events
c=find(stims(:,2)==hex2dec('00008005')); % 32773 Trial Start
d=find(stims(:,2)==hex2dec('00008006')); % 32774 Trial Stop
a=find(stims(:,2)==hex2dec('00008205')); % 33285 Hit
b=find(stims(:,2)==hex2dec('00008206')); % 32286 Nohit
e=find(stims(:,2)==hex2dec('0000800C')); % Visual Stimulus Stop
f=find(stims(:,2)==hex2dec('0000800B')); % Visual Stimulus Start

% Find all the stimulus assosiated with row/col flashing.
stimuls = [];
for i=1:12
    stimuls = [stimuls; find(stims(:,2)==33025-1+i)];
end


%%
% Chequear si la cantidad de estimulos encontradas coincide.
total=0;
for i=1:12
    size(find(stims(:,2)==33025-1+i))
    total=total+size(find(stims(:,2)==33025-1+i))
end


% Los stimulos pueden venir despues de muchas cosas.
% Filtrar solo aquellos estimulos que estan asociados a targets.
counterhits=0;
counternohits=0;
validstimuls=[];
for i=1:size(stimuls,1)
    vl=stims(stimuls(i)-1,1:2)
    if (vl(2) == 33285) % Hit
        counterhits = counterhits + 1;
        validstimuls(end+1) = stimuls(i);
    elseif (vl(2) == 33286) % Nohit
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
    % Verificar que para cada trial, solo haya dos tipos de estimulos
    % asociados a hit (el correspondiente a las filas y el de las columnas)
    assert( size(h,2) == 2);
end


%%
ab = [a; b];

% a hits, b nohits, c and d contain where trial end and stop (five of each
% per letter).

ab = sort(ab);

% Cut the stimulus from stims, getting only the time and duration of each.
targets = [ stims(ab,1:3)];

% Remap targets, assigning 1 for NoHit and 2 for Hit.
targets(targets(:,2)==33285,2) = 2;
targets(targets(:,2)==33286,2) = 1;
targets(targets(:,2)==32773,2) = 0;
targets(targets(:,2)==32774,2) = 0;
targets(targets(:,2)==32780,2) = 0;



% Sort validstimuls based on time.
sls = sort(validstimuls);

% Pick the stimuls sorted.
stimulations = [ stims(sls,1:3) ];

% Map stimulus to 1-12 values.
stimulations(:,2) = stimulations(:,2) - 33025 + 1;
stimulations( stimulations(:,2) < 0) = 0; 

% trials
z = stims(c,1);

% Stop time is where the first invalid trial starts.
if (size(c,1)>35)
    
    stoptime=stims(c(36),1);

    stopsample=find(sampleTime>stims(c(36),1));


    sampleTime(stopsample(1):end,:) = [];
    samples(stopsample(1):end,:) = [];

    z(36) = [];

    targets(4201:end,:) = [];
    stimulations(4201:end,:) = [];
end
    
    
% Check target consistency
Word = [];
for trial=1:35
    h=[];
    for i=1:120
        if (targets((trial-1)*120+i,2)==2)
            h = [h stimulations((trial-1)*120+i,2)];
        end
    end
    % There must be only TWO targets per trial (row and col).
    h = unique(h);
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
    % Obtengo el ID del sample que esta justo despues del estimulo
    maximalsampleidx=find(sampleTime>=targets(i,1));
    maximalsampleidx=maximalsampleidx(1);
    
    % Obtengo la localizacion donde esta el marcador de fin del estimulo
    % (e)
    loc = find(stims(e,1)>targets(i,1));
    loc = loc(1); % Location on e.
    duration = stims(e(loc),1)-targets(i,1);
    
    % Marco donde inicia el flash y la duracion en sample points.
    data.flash(end+1,1) = maximalsampleidx 
    data.flash(end,2) = ceil(Fs*duration);
    
    %fakeEEG=fakeeegoutput(4,targets(i,2),channelRange,25,100,4);
    
    % Marco todos los estimulos y targets donde el flash estuvo presente.
    for j=1:ceil(Fs*duration)
        data.y(maximalsampleidx+j-1) = targets(i,2); 
        data.y_stim(maximalsampleidx+j-1) = stimulations(i,2);
        
        %fakeEEG(j,:);
    end
    
    if (targets(i,2)==2)
        %data.X(maximalsampleidx+ceil(Fs*duration)-1:maximalsampleidx+ceil(Fs*duration)-1+ceil(Fs*0.33),:) = zeros(ceil(Fs*0.33)+1,size(data.X,2));
        %data.X(maximalsampleidx-1:maximalsampleidx-1+ceil(Fs*1),:) = zeros(ceil(Fs*1)+1,size(data.X,2));
 
        %data.X(maximalsampleidx-1+ceil(Fs/2*1),:) = 1000*ones(1,size(data.X,2));
        
    end    
    
    
end


% Marco los inicios de los trials.
for i=1:size(z)
    n=find(sampleTime>z(i));
    data.trial(i)=n(1);
end

data.trial = data.trial';


%%
% Antes de cada uno de los inicios de los flash, los estimulos tienen que
% estar marcados con zero.
for i=1:4200
    ss=data.y_stim(data.flash(i)-5:data.flash(i)+40)'
    
    assert ( ss(5) == 0, 'Not zero');
end
%%

%data.X = data.X * 10;
save('p300.mat');

% LISTOOOOOO
 
end
%%

run('ProcessP300.m');
run('GeneralClassifyP300.m');
