
% converts OV saved data+stim file pair to a .mat file

function convert_ov2mat(inputOvFilename, outputMatFilename)

    dire = 'openvibe';
    dire2 = 'openvibe-2.1.0';
    
    openvibeConvertFile = sprintf('C:\\%s\\openvibe-convert.cmd',dire2);
	openvibeConvert = sprintf('"C:\\%s\\openvibe-convert.cmd"',dire2);
    
    
    
    if (~exist(openvibeConvertFile,'file'))
        openvibeConvert = '"D:\openvibe\openvibe-convert.cmd"';
    end
	
	csvFn = regexprep(inputOvFilename, '\.ov$', '\.csv');	
	stimFn = regexprep(inputOvFilename, '\.ov$', '\.csv\.stims\.csv');	

	fprintf(1, 'File %s ... \n', inputOvFilename);
	fprintf(1, '  Converting to CSV pair...\n');
	fprintf(1, '    Signal : %s\n', csvFn);
	fprintf(1, '    Markers: %s\n', stimFn);
	
	cmd = sprintf('%s %s %s', openvibeConvert, inputOvFilename, csvFn);
    disp(cmd);
	system(cmd);
	
	fprintf(1, '  Loading pair...\n');
	
	data=readtable(csvFn,'delimiter',';');
	stims=readtable(stimFn,'delimiter',';');
	
	channelNames = data.Properties.VariableNames;

	data = table2array(data);
	stims = table2array(stims);
	sampleTime = data(:,1);
	samplingFreq = data(1,end);
	samples = data(:,2:end-1);
	channelNames = channelNames(2:end-1);
	
	fprintf(1, '  Saving to %s...\n', outputMatFilename);
	
	save(outputMatFilename, 'stims','sampleTime', 'samples', 'samplingFreq', 'channelNames');
		
	fprintf(1, '  Deleting temp files...\n');
	
	delete(csvFn);
	delete(stimFn);
	
end



