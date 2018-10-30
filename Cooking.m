clear mex
clc
clear
clearvars
close all

addpath('./ov2mat/');

%run('C:/vlfeat/toolbox/vl_setup')
rng(396544);

for subject = [ 21 ]
%for subject = [1 2 3 4 6 7 8 9 10 11 14 15 16 17 18 19 20 21 22 23];
%for subject=16;   
clear mex;clearvars  -except subject*;close all;clc;

%Parameters
Fs=250;
Trials=35;

%subject = 2;
convert_ov2mat(sprintf('./signals/Subject%d/p300-train.ov',subject),sprintf('./signals/p300-train-%d.mat',subject));
load(sprintf('./signals/p300-train-%d.mat',subject));

% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

channels={ 'Fz'  ,  'Cz',    'P3' ,   'Pz'  ,  'P4'  , 'PO7'   , 'PO8',  'Oz'};
channelRange=1:8;


samples(find(sampleTime==stims(1,1)),:)

%%
fprintf('%04x\n',stims(:,2))

% First, get the stimulus to different events
c=find(stims(:,2)==hex2dec('00008005')); % 32773 Trial Start
d=find(stims(:,2)==hex2dec('00008006')); % 32774 Trial Stop
a=find(stims(:,2)==hex2dec('00008205')); % 33285 Hit
b=find(stims(:,2)==hex2dec('00008206')); % 32286 Nohit
e=find(stims(:,2)==hex2dec('0000800C')); % Visual Stimulus Stop 32780
f=find(stims(:,2)==hex2dec('0000800B')); % Visual Stimulus Start 32779

H = zeros(35,2);

for trial=1:Trials
    h=[];
    for i=1:20  % Hay 20 hits en cada trial, 20*35 = 700 que es el tamaño de a
        vl=stims(a((trial-1)*20+i)+1,1:2);
        %[(trial-1)*Trials+i vl(2)]
        h=[h vl(2)];
    end
    h = unique(h);
    [trial h]
    % Verificar que para cada trial, solo haya dos tipos de estimulos
    % asociados a hit (el correspondiente a las filas y el de las columnas)
    assert( size(h,2) == 2);
    H(trial, :) = h;    
end


end