artifactcount = 0;            
            
for subject=subjectRange
    clear data.y_stim
    clear data.y
    clear data.X
    clear dataX;
    clear data.trial
    load('p300.mat');

    %dataX = notchsignal(data.X, channelRange,Fs);
    datatrial = data.trial;

    dataX = data.X;
    %dataX = decimateaveraging(dataX,channelRange,downsize);
 %dataX = bandpasseeg(dataX, channelRange,Fs);
 %dataX = decimatesignal(dataX,channelRange,downsize); 
    %dataX = downsample(dataX,downsize);
    
    %l=randperm(size(data.y,1));
    %data.y = data.y(l);
       
    for trial=1:size(datatrial,2)
        for flash=1:flashespertrial
            
            % Mark this 12 repetition segment as artifact or not.
            %if (mod((flash-1),12)==0)
            %    iteration = extract(dataX, (ceil(data.trial(trial)/downsize)+64/downsize*(flash-1)),64/downsize*12);
            %    artifact=isartifact(iteration,70);  
            artifact = false;
            %end         
            
            %EEG(subject,trial,flash).EEG = zeros((Fs/downsize)*windowsize,size(channelRange,2));

            
            start = data.flash((trial-1)*120+flash,1);
            duration = data.flash((trial-1)*120+flash,2);
            
            output = baselineremover(dataX,ceil(start/downsize),(Fs/downsize)*windowsize,channelRange,downsize);

            EEG(subject,trial,flash).label = data.y(start);
            EEG(subject,trial,flash).stim = data.y_stim(start); 
            
            [trial, flash, EEG(subject,trial,flash).stim, EEG(subject,trial,flash).label]
            
            EEG(subject,trial,flash).isartifact = false;
            if (artifact)
                artifactcount = artifactcount + 1;
                EEG(subject,trial,flash).isartifact = true;
            end
            
            % This is a very important step, do not forget it.
            % Rest the media from the epoch.
            [n,m]=size(output);
            output=output - ones(n,1)*mean(output,1); 
            
            %output = zscore(output)*2;

            EEG(subject,trial,flash).EEG = output;

        end
    end
end
