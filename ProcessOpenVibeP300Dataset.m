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

ab = sort(ab);

% Cut the stimulus from stims, getting only the time and duration of each.
targets = [ stims(ab,1:3)];

% Remap targets, assigning 1 for NoHit and 2 for Hit.
targets(targets(:,2)==33285,2) = 2;
targets(targets(:,2)==33286,2) = 1;
targets(targets(:,2)==32773,2) = 0;
targets(targets(:,2)==32774,2) = 0;
targets(targets(:,2)==32780,2) = 0;

sls = sort(stimuls);

stimulations = [ stims(sls,1:3) ];


stimulations(:,2) = stimulations(:,2) - 33025 + 1;
stimulations( stimulations(:,2) < 0) = 0; 


stoptime=stims(c(36),1);

stopsample=find(sampleTime>stims(c(36),1));


sampleTime(stopsample:end,:) = [];
samples(stopsample:end,:) = [];


% Data Structure
data = cell(0);

data.X = samples;
data.y = zeros(size(samples,1),1);
data.y_stim = zeros(size(samples,1),1);
data.trial=zeros(5,1);
z = stims(c,1);

% erase the last one.
z(end) = [];

targets(4201:end,:) = [];
stimulations(4201:end,:) = [];

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


% First, lets map the stimulus and the target information.
% for i=1:size(z,1)
%     maxs=find(sampleTime>z(i));
%     for stimuls=0:119
%         data.y(maxs+64*stimuls:(maxs+64*stimuls)+32-1)=targets((i-1)*120+stimuls+1,2);
%     end
% end
% 
% 
% 
% % I need to assign a label for each target.
% if (false)
%     events=1;
%     whichtarget = 0;
%     for i=1:size(samples,1)
%         if (events>size(targets,1))
%             whichtarget = 0;
%         elseif (sampleTime(i)>targets(events,1))    
%             whichtarget = targets(events,2);
%             events=events+1;
%         end
%         data.y(i) = whichtarget;
% 
%     end
% 
%     [1:size(data.y,1)'; data.y']'
% end

for i=1:size(z)
    n=find(sampleTime>z(i));
    data.trial(i)=n(1);
end

data.trial = data.trial';

%data.X = data.X * 10;
save('p300.mat');


windowsize=1;
downsize=10;

EEG = prepareEEG(Fs,windowsize,downsize,120,1:1,1:8);

for i=1:12 routput{i} = 0; end


for subject=1:1
    for trial=1:35
        for flash=1:120
            routput{EEG(subject,trial,flash).stim} = routput{EEG(subject,trial,flash).stim}+1;
        end
    end
end


%%
% Epoching
globalnumberofsamples=1200000;
globalnumberofepochs=12000000;
routput = [];
boutput = [];
rcounter = 0;
bcounter = 0;
processedflashes = 0;
        
Fs=Fs/downsize;
for subject=1:1
   epoch=0;
   for trial=1:35
        %routput = [];
        %boutput = [];
        %rcounter = 0;
        %bcounter = 0;
        %processedflashes = 0;
        for flash=1:120
            
            % Process one epoch if the number of flashes has been reached.
            if (processedflashes>globalnumberofsamples)
                break;
                %SignalAveragingProcessingSegment;
                %processedflashes=0;
            end
            
            % Skip artifacts
            if (EEG(subject,trial,flash).isartifact)
                continue;
            end

            
%             if (mod(flash-1,12)==0)
%                 assert( globalnumberofepochs>2 ||  processedflashes==0 || bcounter==1);
%                 bcounter=0;
%                 rcounter=0; 
%                 bpickercounter = 0;
%                 bwhichone = [0 1];%bwhichone=sort(randperm(10,2)-1);
%             end

            label = EEG(subject,trial,flash).label;
            output = EEG(subject,trial,flash).EEG;
            
            processedflashes = processedflashes+1;
            
            if ((label==2) && (rcounter<globalnumberofepochs))
                routput = [routput; output];
                rcounter=rcounter+1;
            end
            if ((label==1) && (bcounter<globalnumberofepochs))
                boutput = [boutput; output];
                bcounter=bcounter+1;
            end

        end
   end 
end
end
channelRange=1:8;
channels={ 'Fz'  ,  'Cz',    'Pz' ,   'Oz'  ,  'P3'  ,  'P4'   , 'PO7'   , 'PO8'};

%%
    if (size(routput,1) >= 2)
        %assert( bcounter == rcounter, 'Averages are calculated from different sizes');
    
        %assert( size(boutput,1) == size(routput,1), 'Averages are calculated from different sizes.')
    
        assert( (size(routput,1) >= 2 ), 'There arent enough epoch windows to average.');
   
        routput=reshape(routput,[Fs size(routput,1)/Fs 8]);
        boutput=reshape(boutput,[Fs size(boutput,1)/Fs 8]);

        for channel=channelRange
            rmean(:,channel) = mean(routput(:,:,channel),2);
            bmean(:,channel) = mean(boutput(:,:,channel),2);
        end

        subjectaverages{subject}.rmean = rmean;
        subjectaverages{subject}.bmean = bmean;  
 
    end

%%
for channel=1:8
    rmean = subjectaverages{subject}.rmean;
    bmean = subjectaverages{subject}.bmean;
    
    %[n,m]=size(rmean);
    %rmean=rmean - ones(n,1)*mean(rmean,1);
            
    %[n,m]=size(bmean);
    %bmean=bmean - ones(n,1)*mean(bmean,1);
    
    fig = figure(3);

    subplot(4,2,channel);
    
    hold on;
    Xi = 0:0.1:size(rmean,1);
    Yrmean = pchip(1:size(rmean,1),rmean(:,channel),Xi);
    Ybmean = pchip(1:size(rmean,1),bmean(:,channel),Xi);
    plot(Xi,Yrmean,'r','LineWidth',2);
    plot(Xi,Ybmean,'b--','LineWidth',2);
    %plot(rmean(:,2),'r');
    %plot(bmean(:,2),'b');
    axis([0 Fs -6 6]);
    set(gca,'XTick', [Fs/4 Fs/2 Fs*3/4 Fs]);
    set(gca,'XTickLabel',{'0.25','.5','0.75','1s'});
    set(gca,'YTick', [-5 0 5]);
    set(gca,'YTickLabel',{'-5 uV','0','5 uV'});
    set(gcf, 'renderer', 'opengl')
    %hx=xlabel('Repetitions');
    %hy=ylabel('Accuracy');
    set(0, 'DefaultAxesFontSize',18);
    text(0.5,4.5,sprintf('Channel %s',channels{channel}),'FontWeight','bold');
    %set(hx,'fontSize',20);
    %set(hy,'fontSize',20);
end
legend('Target','NonTarget');
hold off
