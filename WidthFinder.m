function [spikelist,spikes_wide,spikes_narrow] = WidthFinder(evnt, sign, data, fs, Settings)
%  Given a vector of spikes (location and raw data), calculate the width of the spikes, measured at a certain user specified height.
%  Positive and negative spikes are considered separately and specified with the variable 'sign'
%
%Input:         'evnt'      Row vector of peak locations, stored as indices of 'data'
%               'sign'      indicates whether positive or negative spikes are considered
%                           0  = positive peaks
%                           1  = negative peaks
%               'data'      Row vector containing data, sampled at rate 'fs'
%               'fs'        Number of samples per second
%               'Settings'  Relevant settings components:
%                           'Settings.ht_perc'  : height of a spike at
%                           which to determine its width (fraction)
%                           'Settings.req_width': width cutoff between
%                           narrow and wide spikes (s)
%
%Output:        'spikelist'     List of ALL peaks (both narrow and wide)
%                               spikelist(i,:)=[location, height, width]
%                               where location references the index in 'data'
%               'spikes_wide'   List of only the 'wide' peak info
%               'spikes_narrow' List of only the 'narrow' peak info
%
%Calls:         Flip
%
%Called by:     SpikeFinder
    % adding waitbar functionality by E. Pedapati 2/9/2020
    waitbarEnable = true;

    %Load in relevant Settings
    ht_perc=Settings.SpikeDetection.dHeightPct;       %Width of a spike is determined at specified height of spikes (fraction)
    req_width=Settings.SpikeDetection.dMaxWidthOfSpikes;   %Spike is considered wide if width exceeds this threshold (in s)

    %Initialize structures
    spikelist=[];
    spikes_wide=[];
    spikes_narrow=[];
    
    %Loop through all peaks found. Find the width of each peak. Sometimes
    %the data will change direction before height threshold is reached in
    %which case interpolation might be used to calculate the peak height.
    
    % adding waitbar functionality by E. Pedapati 2/9/2020
    if waitbarEnable == true
        if sign == 0
            loopLabel = 'Positive (1/2) Events: ';
        else
            loopLabel = 'Negative (2/2) Events: ';
        end
%         f = waitbar(0, '1','Name','Identifying peaks...',...
%             'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
%         setappdata(f,'canceling',0);
        f=waitbar(0,loopLabel,'Name','Identifying Peaks');
    end
    
    parfor i = 1:length(evnt)
        
        % adding waitbar functionality by E. Pedapati 2/9/2020
%         if waitbarEnable == true            
%             if getappdata(f,'canceling')
%                 break
%             end
%             waitbar(i/length(evnt),f,sprintf('%s %d of %d',loopLabel, i,length(evnt)));
%         end
        % end revision
        
        pk = evnt(i);                                        %location of peak
        pk_ht = data(pk);                                    %height of peak
        pk_ht_perc = data(pk) * ht_perc;                     %height of pk thresh
        left = pk;  %will be used to find width
        right = pk; %will be used to find witth

        %First attempt to just walk down the graph to the height threshold
        %This will only work if the graph does not go up again before
        %reaching it within the specified width
        leftsuccess=1;
        while leftsuccess &&...
              Flip((pk_ht_perc<data(left)),sign)                
          if left==1
              leftsuccess=0;
          elseif pk-left<0.5*req_width*fs  %making sure it terminates
             left=left-1;
          else
              leftsuccess=0;
          end
        end
        if leftsuccess
            %We found left edge of spike
        else
            if left==1
                %Peak is too far to the beginning of file, we cannot locate
                %left of spike. Double the right portion for best estimate
            else
                %Too much meandering. Use extrapolation to find width
                left = floor(pk - abs((pk - left) * ...
                (pk_ht - pk_ht_perc) / (pk_ht - data(left))));   %based on ratio
                leftsuccess=1;
            end
        end
        
        rightsuccess=1;
        while rightsuccess &&...
              Flip((pk_ht_perc<data(right)),sign)

          if right==length(data)
              rightsuccess=0;
          elseif right-pk<0.5*req_width*fs
              right=right+1;
          else
              rightsuccess=0;
          end
        end
        
        if rightsuccess
           %Right is the correct location 
        else
            if right==length(data)
                %Peak is too far to the end of file, we cannot locate right
                %of spike. Double left portion for best estimate
            else
                %Too much meandering. Use extrapolation to find width
                right = ceil(pk + abs((right - pk) * ...
                (pk_ht - pk_ht_perc) / (pk_ht - data(right))));   %based on ratio
                rightsuccess=1;
            end
        end
        
        %Deal with edge cases: 
        if ~leftsuccess && rightsuccess
            left=pk-(right-pk);
        elseif leftsuccess && ~rightsuccess
            right=pk+(pk-left);
        end
        
        %left and right are both successful, so calculate width
        spk_width = (right - left) / fs;
        
        
        spikelist=[spikelist ; [pk pk_ht  spk_width]];
        if (spk_width>Settings.SpikeDetection.dMaxWidthOfSpikes)
            spikes_wide=[spikes_wide ; [pk pk_ht spk_width]];
        else
            spikes_narrow=[spikes_narrow ; [pk pk_ht spk_width]];
        end
    end
    %
    waitbar(1,f);
    if waitbarEnable == true        
        delete(f); % adding waitbar functionality by E. Pedapati 2/9/2020
    end
end


function new_value = Flip(value, sign)
%Outputs boolean value based on 'sign'
%
%Input:     'value'     Boolean value (0 or 1)
%           'sign'      0 = return same value
%                       1 = return opposite value
%
%Output:    'new_value' boolean (0 or 1)
%
%Called by: WidthFinder
%
    new_value = value;    
    if sign == 1
       new_value = ~value;
    end
end
