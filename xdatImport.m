function [sctHeader,pdData] = xdatImport(strFile, strSave,subject, numSubjects, numChannels)
f = waitbar(0, 'Converting...', 'Name', 'Converting XDAT file...');
metadata_file = strcat(extractBefore(strFile,'_data'), '.xdat.json');
x=allegoXDatFileReaderR2018a();
timeRange = x.getAllegoXDatTimeRange(extractBefore(strFile,'_data'));
try
    primarySignals = x.getAllegoXDatPriSigs(extractBefore(strFile,'_data'),timeRange,subject, numSubjects, numChannels);
catch e
    close(f);
    delete(f);
    rethrow(e);
    fprintf(e.message);
end
jsonData = jsondecode(fileread(metadata_file));

pdData = double(primarySignals.signals'); 

nChannels = size(primarySignals.signals,1);
fs = jsonData.status.samp_freq;
record_time = length(primarySignals.timeSamples) / fs;
t_amplifier = primarySignals.timeSamples;
sctHeader.sctAmplifierChannels  = nChannels;
sctHeader.sctBoardADCChannels   = jsonData.status.signals.aux; 
sctHeader.sctBoardDigInChannels = jsonData.status.signals.din;
sctHeader.nChannelNum           = nChannels;
sctHeader.dSamplingRate         = fs; 
sctHeader.dDuration             = record_time;  

save(strSave, 'pdData', 't_amplifier', 'sctHeader', '-v7.3');

waitbar(0.8, f, 'Loading data into EEGLAB modules...');
addpath(genpath('eeglab13_6_5b')); 
eeglab_test; 
load('eeglab_initialization.mat'); 
 
[strSavePath,strName] = fileparts(strSave);
strSaveNameEEG = [strName, '_EEG']; 
[pdEEGOUT, ~] = EEGLABImportData(strSaveNameEEG, pdData', sctHeader.dSamplingRate); 

clear pdEEGforEEGLAB; 
fprintf('\n');

waitbar(0.9, f, 'Saving EDF...');
strSaveEDFEEG = [strSavePath, '\', strSaveNameEEG, '.edf'];
EEGLABWriteEEG2edf(pdEEGOUT, strSaveEDFEEG); 

rmpath('eeglab13_6_5b'); 

waitbar(1, f, 'Done.'); pause(0.5); 
delete(f);

end

