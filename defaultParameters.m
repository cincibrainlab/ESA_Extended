function sctSet = defaultParameters()

% automatic thresholds 
%SETTINGS FOR PREANALYSIS (HISTOGRAM ANALYSIS OF PEAKS)
%Peekseek Settings for Preanalysis of ALL spikes. The cutoffs of 95% of data are
%pretty helpful in detecting all spikes. This is why the thresholds are set so small. 
sctSet.AutoThresholds.nPosPeaksMinDist     = 50;            % all_dist_pos: min distance between pos spikes
sctSet.AutoThresholds.dPosPeaksAmp         = 0.001;         % all_thrsh_pos: amplitude threshold for pos spikes
sctSet.AutoThresholds.nNegPeaksMinDist     = 50;            % all_dist_neg: min distance between neg spikes
sctSet.AutoThresholds.dNegPeaksAmp         = 0.001;         % all_thrsh_neg: amplitude threshold for neg spikes
sctSet.AutoThresholds.dPctCutoffALLPeaks  = [0.05, 0.95];   % [cl, ch]: cutoff for all spikes            
sctSet.AutoThresholds.dPctCutoffPosPeaks  = [0.05, 0.95];   % [pcl, pch]: cutoff for positive spikes (in preanalysis)
sctSet.AutoThresholds.dPctCutoffNegPeaks  = [0.05, 0.95];   % [ncl, nch]: cutoff for negative spikes (in preanalysis)            
sctSet.AutoThresholds.nNumSDfromMean       = 2;             % number_of_sd: number of standard deviations away from mean to consider spike

% spike detection 
%SETTINGS FOR FINDING SPIKES (peekseak in main loop)
%Peaks are only considered to be 'spikes' if they exceed a multiplier of the threshold, are at least dist apart (in samples), 
%and the width is measured at the height prescribed, as a percentage of peak height. 
%Let's say 95% of ALL negative spikes lie below -0.6, then given a
%multiplier of 0.5 (50%) we only consider those spikes that exceed -0.3 (50% of -0.6)
sctSet.SpikeDetection.dMaxWidthOfSpikes    = 0.05;          % req_width: req width threshold for each spike (in seconds)
sctSet.SpikeDetection.dHeightPct           = 0.5;           % ht_perc: determines percent of height for each spike needed to det. width
sctSet.SpikeDetection.nPosSpikeMinDist     = 50;            % dist_pos: positive distance between spikes
sctSet.SpikeDetection.nNegSpikeMinDist     = 50;            % dist_neg: negative distance between spikes

% event detection 
%SETTINGS FOR FINDING EVENTS
%An event is defined as a series of 'spikes' that:
%  * are dense enough  (maintains 'min_nr_spikes' / 'min_szre_windw')
%  * lasts long enough ('min_szre_lngth')   
%If two events are closer than 'eventglue' (s), make them the same event
%If two events are only separated by few wide spikes that don't indicate noise, optionally merge them
sctSet.EventDetection.nMinNumSpikesAsEvent = 3;             % min_nr_spikes: minimum number of spikes to count as event
sctSet.EventDetection.dMinRollingTimeWin   = 1.0;           % min_szre_windw: min length req for rolling time window 
sctSet.EventDetection.dMinSeizureLength    = 10.0;           % min_szre_lngth: min length req for seiz evnt 
sctSet.EventDetection.MergePosNegEvents.Value   = 1;        % (selection of radio button group) deal_with_merge: 
                                                                % 1=union, 2=intersect, 3=positive only, 4=negative only
sctSet.EventDetection.bConnectEventsCheck  = 1;             % connect_events: attempt to connect events if separated by few dense wide spikes
                                                                %The wide spikes would have to adhere to spike conditions
                                                                %0 = don't merge
                                                                %1 = merge
sctSet.EventDetection.dGlueEvents          = 1.0;           % eventglue: glue events together if they are less than #s apart

switch sctSet.EventDetection.MergePosNegEvents.Value
    case 1;     sctSet.EventDetection.MergePosNegEvents.Selection = 'Union events';   
    case 2;     sctSet.EventDetection.MergePosNegEvents.Selection = 'Intersect events'; 
    case 3;     sctSet.EventDetection.MergePosNegEvents.Selection = 'Only take (+) events'; 
    case 4;     sctSet.EventDetection.MergePosNegEvents.Selection = 'Only take (-) events'; 
end

% noise detection 
%SETTINGS FOR IDENTIFYING NOISE
%NOTE: More noise settings are automatically added after threshold analysis
sctSet.NoiseDetection.dIgnoreNoise         = 0.5 * sctSet.EventDetection.dMinRollingTimeWin;    % noisecutoff: delete noise shorter than this (s)
sctSet.NoiseDetection.dJoinNoise           = 1.0;           % glue_noise: glue noise events together if they are less than #s apart
sctSet.NoiseDetection.DealWithNoise.Value  = 1;             % (selection of radio button group) deal_with_noise: 
                                                                % 1=ignore all noise, 2=truncate events at noise, 3=ignore noisy events altogether
sctSet.NoiseDetection.dSlidingWindowSize   = 1.0;           % movingwin(1): Sliding window [size,overlap] in s
sctSet.NoiseDetection.dSlidingWindowStep   = 0.5;           % movingwin(2): Resolution of noise detection determined by 'size'

switch sctSet.NoiseDetection.DealWithNoise.Value
    case 1;     sctSet.NoiseDetection.DealWithNoise.Selection = 'Allow noise';   
    case 2;     sctSet.NoiseDetection.DealWithNoise.Selection = 'Split events at noise locations'; 
    case 3;     sctSet.NoiseDetection.DealWithNoise.Selection = 'Ignore events containing noise'; 
end

sctSet.dBaselineUp      = []; 
sctSet.dBaselineLow     = [];
sctSet.dSpikeUp         = []; 
sctSet.dSpikeLow        = []; 
sctSet.strCutoffMethod  = 'Not specified'; 
sctSet.dNoiseUp         = [];               % NoiseUpper
sctSet.dNoiseLow        = [];               % NoiseLower

end