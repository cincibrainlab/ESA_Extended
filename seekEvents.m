%%FindEvents
function [pnPosEvents, pnNegEvents] = seekEvents(pdData, sctInfo, fs, sctSetting, bDoDisplay)
% function [posevents,negevents]=FindEvents(data,posspikes,negspikes,psn,nsn,psw,nsw,fs,Settings,DoDisplay)
% Use the peak information (locations and size) to find events, as defined
% in the 'Settings'. Positive events and Negative events are considered
% separately and both returned.  Optionally, can display found events in
% popup.
%
%Input:  'data'             Row vector containing data, sampled at rate 'fs'
%        'posspikes'        [position, height, width] of positive peaks
%        'negspikes'        [position, height, width] of negative peaks
%        'psn'              " " " of positive narrow peaks
%        'nsn'              " " " of negative narrow peaks
%        'psw'              " " " of positive wide peaks
%        'nsw'              " " " of negative wide peaks
%        'fs'               Number of samples per second
%        'Settings'
%        'DoDisplay'        1: Display events in popup window
%                           0: Don't show popup
%
%Output: 'posevents'        [start, end] of positive events, where
%                           'start' and 'end' are indices of 'data'
%        'negevents'        [start, end] of negative events, where
%                           'start' and 'end' are indices of 'data'
%
%Calls:     Usual_Suspects, Flagtape
%
%Called by: 'MenuAnalyze_Callback' in 'findallofthem.m'
%
    for subject=1:size(pdData,2)

        if length(fs) > 1
            samplingRate = fs(subject);
        else
            samplingRate = fs;
        end

        posspikes = sctInfo(subject).Spikes.pnPosSpikes;    
        negspikes = sctInfo(subject).Spikes.pnNegSpikes;
        psn = sctInfo(subject).Spikes.pnPosSpikesNarrow;
        nsn = sctInfo(subject).Spikes.pnNegSpikesNarrow;
        psw = sctInfo(subject).Spikes.pnPosSpikesWide;
        nsw = sctInfo(subject).Spikes.pnNegSpikesWide;

        %Use narrow Spike Information to find Events  
        pnPosEvents{subject} = Usual_Suspects(psn,samplingRate,sctSetting); %Positive Spike Events
        pnNegEvents{subject} = Usual_Suspects(nsn,samplingRate,sctSetting); %Negative Spike Events

        %Optional: Try to tape those events that are only separated by few
        %dense wide spikes which otherwise (besides width) follow the criteria
        if sctSetting.EventDetection.bConnectEventsCheck
            pnPosEvents{subject}=Flagtape(pnPosEvents{subject},posspikes,samplingRate,sctSetting);
            pnNegEvents{subject}=Flagtape(pnNegEvents{subject},negspikes,samplingRate,sctSetting);
        end
    %end  
    %Optional: Display the events in a pop-out figure
    if bDoDisplay
        FigureEvents=figure('Name','Find Events');
        plot(pdData)
        hold on
        plotPnPosEvents = pnPosEvents{subject};
        plotPnNegEvents = pnNegEvents{subject};
        for i=1:length(plotPnPosEvents)
            plot([plotPnPosEvents(i,1) plotPnPosEvents(i,2)], [0 0],'g');
        end
        for i=1:length(plotPnNegEvents)
            plot([plotPnNegEvents(i,1) plotPnNegEvents(i,2)], [0 0],'r');
        end
        hold off
    end
    end
end



function events = Usual_Suspects(peaks,fs, Settings)
%Given a list of peak information, use the user specifications to determine
%which peaks make an 'event'
%
%Input: 'peaks'     matrix where peaks(:,1) contains locations
%       'fs'        Number of samples per second
%       'Settings'  Contains parameter settings
%
%Output: 'events'   [start, end] of events, as indices of 'data'
%
%Calls:         none
%
%Called by:     FindEvents
%

    %Load in relevant information from 'Settings'
    %This information specifies what defines an event
    mns=Settings.EventDetection.nMinNumSpikesAsEvent-1;              %Minimum number of spikes / sliding window to be considered an event
    min_szr_windw=Settings.EventDetection.dMinRollingTimeWin*fs;  %Seizure sliding window measured in samples
    min_szr_lngth=Settings.EventDetection.dMinSeizureLength*fs;  %Minimum seizure interval measured in samples. Any event less that this length is removed.
    
    %Initialize
    events = [];                        
    InEvent=0;
    eventstart=1;
    
    %Loop through all peaks, and determine when they combine into events
    i=1;
    while i<=length(peaks)-mns
            
        if InEvent         %In Seizure Event
            if (peaks(i+mns)-peaks(i)<min_szr_windw)
                %Keep looking for the end of the current event
                i=i+1;
            else
                %Add finished event and start looking for start of next
                %First check if the event is not too short.
                candidate=[peaks(eventstart) peaks(i+mns-1)];
                if candidate(2)-candidate(1)>min_szr_lngth
                    events=[events ; candidate];
                end
                InEvent=false;
                i=i+mns;
            end
        else               %Not in Seizure Event
            if (peaks(i+mns)-peaks(i)<min_szr_windw)
                %Found start of next event -> start looking for the end
                eventstart=i;
                InEvent=true;
            else
                %Keep looking for the start of the next seizure event
                i=i+1;
            end
        end             
    end
        
    %Once we have considered all peaks, check wether we end in seizure event of out of it
    if InEvent
        %File is over while we were in event. Add it to the event list
        %events=[events ; [peaks(eventstart) peaks(end,1)]];
        if peaks(end,1) - peaks(eventstart) > min_szr_lngth
            events=[events ; [peaks(eventstart) peaks(end,1)]];
        end
    end
end
    


function taped_events = Flagtape(events,allspikes,fs,Settings)
%If two events are separated by enough wide spikes to consider them as
%one single event if they had been narrow spikes, connect them. 
%Only runs if user picks it as an option in the Settings. 
%
%Input:         'events'        [start, end] of events, as indices of 'data'
%                               either positive or negative events
%               'allspikes'     locations of ALL spikes 
%                               (positive or negative, matching the events)
%               'fs'            Number of samples per second
%               'Settings'      Contains parameter settings. 
%
%Output:        'taped_events'  [start, end] of events, as indices of 'data'
%
%Calls:         none
%
%Called by:     FindEvents
%

    %Intialize data structure
    taped_events=[];
    InTape=0;
    
    %Consider trivial cases
    if isempty(events)
       return 
    elseif length(events(:,1))==1
       taped_events=events;
       return
    end
    
    %Loop through all events
    for i=1:length(events(:,1))-1
        
        %Check if consecutive events are close enough to be considered
        gap_start=events(i,2);
        gap_end=events(i+1,1);
        if (gap_end-gap_start<=Settings.EventDetection.dMinSeizureLength*fs) 
           
            %Check if there are the necessary number of wide spikes to make
            %up for the lack of narrow ones
            nr_all=sum((allspikes(:,1)>gap_start).*(allspikes(:,1)<gap_end));
            if (nr_all>=Settings.EventDetection.nMinNumSpikesAsEvent-2)
                if ~InTape
                    %Start the tape, and keep looking for the end
                    InTape=1;
                    eventstart=events(i,1);
                end
            else
                if InTape
                    %Finish up the tape and add the event
                    InTape=0;
                    taped_events=[taped_events;[eventstart,events(i,2)]];
                else
                    %Add event as it is
                    taped_events=[taped_events;[events(i,1),events(i,2)]];       
                end
            end
        else
            if InTape
                %Finish up the tape and add the event
                InTape=0;
                taped_events=[taped_events;[eventstart,events(i,2)]];
            else
                %Add event as it is
                taped_events=[taped_events;[events(i,1),events(i,2)]];
            end
        end
    end
    
    %Only the last event remaining. 
    if InTape
        taped_events=[taped_events;[eventstart,events(i+1,2)]];
    else
        taped_events=[taped_events;[events(i+1,1),events(i+1,2)]];
    end
end
    

