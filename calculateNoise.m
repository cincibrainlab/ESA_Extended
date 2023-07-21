%%FindNoise in original file
function pnNoise = calculateNoise(pdData, sctInfo, fs, sctSettings, nDownSampFactor, bDoDisplay)
% function noise = FindNoise(data,posspikes,negspikes,fs,Settings,DoDisplay)

%Look through the data, using the parameters set in 'Settings', and return all noise indices.
%1. Use a sliding window to determine various metrics of the signal
%2. Compare metrics of interest to thresholds, and flag as noise if they exceed set levels
%
%Input: 'data'                Row vector containing data
%       'posspikes'           [location, height, width] info for all positive spikes, where location is index of data
%       'negspikes'           [location, height, width] info for all negative spikes, where location is index of data
%       'fs'                  Number of samples per second
%       'Settings'            Contains parameter settings. Relevant are:
%       'DoDisplay'           1 = show popup of noise identification
%                             0 = don't show popup
%
%       'noise'               Matrix with [start,end] of all noise events as indices of 'data'
%
%Calls:         none
%
%Called by:     'MenuAnalyze_Callback' in 'findallofthem.m'
%

%Intitialize data structure used to analyze various metrics
    metrics=struct;
    pnNoise=[];
    for subject=1:size(pdData,2)
        temp_pdData = pdData(:,subject);
        gluednoise=[];
        temp_pnNoise =[];

         posspikes = sctInfo(subject).Spikes.pnPosSpikes;
         negspikes = sctInfo(subject).Spikes.pnNegSpikes;

        if length(fs)>1
            samplingRate = fs(subject);
        else
            samplingRate = fs;
        end
        %================================================
        %Step 1: Calculate metrics on all sliding windows
        %================================================
        totallength=length(temp_pdData);
        ThrUpper=sctSettings.dBaselineUp(subject); %???
        ThrLower=sctSettings.dBaselineLow(subject); %???
        WindowFactor=1;  %(Not necessary if you are using parameters in 'Settings' - Will scale sliding window extra)

        %Initialize sliding window at the start of the data file
        start=1;finish=sctSettings.NoiseDetection.dSlidingWindowSize*samplingRate*WindowFactor;
        i=1;
        
        %Initialize counters for efficiently calculating spike metrics in each window
        filteri=1;filterj=1;filterdone=false;
        filteri2=1;filterj2=1;filter2done=false;


        %Loop through all windows, calculating and storing metrics on each window
        %Note that not all metrics are used for noise calculation. Rather, we
        %can consider this a place to examine the metrics and tune them with the
        %observed noise patterns in the data in step 2.
        while finish<totallength 
            %Extract data in current sliding window
            currentdata=temp_pdData(start:finish);
            currentlength=length(currentdata);

            %-------------------
            %Calculate statistics on the current frame
            %-------------------

            metrics(subject,i).average=mean(currentdata);       %mean of data
            metrics(subject,i).minimum=min(currentdata);        %minimum of data
            metrics(subject,i).maximum=max(currentdata);        %maximum of data
            metrics(subject,i).st=std(currentdata);             %standard deviation of data
            metrics(subject,i).absmean=mean(abs(currentdata));  %mean of the absolute value of data

            %Calculate the 'up-down' length of the trace (sum of vertical distances of consecutive datapoints)
            metrics(subject,i).tracelength=sum(abs(currentdata(2:currentlength)-currentdata(1:currentlength-1)));

            %Normalized number of times the window data 'crosses' 0
            metrics(subject,i).zerox=sum(currentdata(2:currentlength).*currentdata(1:currentlength-1)<0)/currentlength;

            %Normalized number of times the window data 'crosses' the window average
            metrics(subject,i).meanx=sum((currentdata(2:currentlength)-metrics(subject,i).average).*(currentdata(1:currentlength-1)-metrics(subject,i).average)<0)/currentlength;

            %Normalized number of direction changes (number of peaks) {this metric seems effective at finding noise edges}
            rshift=currentdata(2:currentlength-1)-currentdata(1:currentlength-2); %+ for increase, - for decrease
            lshift=currentdata(2:currentlength-1)-currentdata(3:currentlength); %- for increase, + for decrease
            metrics(subject,i).nrchanges=sum(rshift.*lshift>0)/currentlength; %count #positive products, which gives us number of peaks

            %Mean and Standard Deviation of positive data exceeding the set data thresholds
            ah=mean(currentdata(currentdata>ThrUpper));
            if ~isnan(ah)
                metrics(subject,i).average_high=ah;
                metrics(subject,i).st_high=std(currentdata(currentdata>ThrUpper));
            else
                metrics(subject,i).average_high=0;
                metrics(subject,i).st_high=0;
            end

            %Mean and Standard Deviation of negative data exceeding the data thresholds
            al=mean(currentdata(currentdata<ThrLower));
            if ~isnan(al)
                metrics(subject,i).average_low=al;
                metrics(subject,i).st_low=std(currentdata(currentdata<ThrLower));
            else
                metrics(subject,i).average_low=0;
                metrics(subject,i).st_low=0;
            end

            %The portion of the spikes that are high (measured as exceeding twice the thresholds
            pks=peakseek(currentdata, 50 ,ThrUpper);
            metrics(subject,i).highpeakperc=(sum(currentdata(pks)>2*ThrUpper)+sum(currentdata(pks)<2*ThrLower))/currentlength;


            %mean and standard deviation of spike width and height for negative spikes
            length_negspikes=size(negspikes,1);
            swn=0;swnst=0;shn=0;shnst=0;
            %Find first negative spike in window
            while filteri<=length_negspikes && negspikes(filteri,1)<start 
                filteri=filteri+1;
            end
            if filteri>length_negspikes
                filterdone=true;
            else
                %Find last negative spike in window
                filterj=filteri; 
                while filterj<=length_negspikes && negspikes(filterj,1)<finish
                    filterj=filterj+1;
                end

                %Calculate metrics (mean, std) or negative spike width and height
                negfilter=negspikes(filteri:filterj-1,3);
                if sum(negfilter)==0
                    swn=0;swnst=0;shn=0;shnst=0;
                else
                    swn=mean(negfilter);
                    swnst=std(negfilter);
                    shn=mean(negspikes(filteri:filterj-1,2));
                    shnst=std(negspikes(filteri:filterj-1,2));
                end

            end
            metrics(subject,i).spikewidth_neg_st=swnst;     %standard deviation of neg spike width in window
            metrics(subject,i).spikewidth_neg=swn;          %mean of neg spike width in window
            metrics(subject,i).spikeheight_neg_st=shnst;    %standard deviation of neg spike height in window
            metrics(subject,i).spikeheight_neg=shn;         %mean of neg spike height in window

            %Spike rate of positive spikes
            %Find the segment of interest in posspikes
            length_posspikes=size(posspikes,1);
            swp=0;swpst=0;shp=0;shpst=0;
            %Find first positive spike in window
            while filteri2<=length_posspikes && posspikes(filteri2,1)<start
                filteri2=filteri2+1;
            end
            if filteri2>length_posspikes
                filter2done=true;
            else
                %Find last positive spike in window
                filterj2=filteri2; 
                while filterj2<=length_posspikes && posspikes(filterj2,1)<finish
                    filterj2=filterj2+1;
                end

                %mean and standard deviation of spike width and height for negative spikes
                posfilter=posspikes(filteri2:filterj2-1,3);
                if sum(posfilter)==0
                    swp=0;swpst=0;shp=0;shpst=0;
                else
                    swp=mean(posfilter);
                    swpst=std(posfilter);
                    shp=mean(posspikes(filteri2:filterj2-1,2));
                    shpst=std(posspikes(filteri2:filterj2-1,2));
                end

            end
            metrics(subject,i).spikewidth_pos_st=swpst;     %standard deviation of pos spike width in window
            metrics(subject,i).spikewidth_pos=swp;          %mean of pos spike width in window
            metrics(subject,i).spikeheight_pos_st=shpst;    %standard deviation of neg spike width in window
            metrics(subject,i).spikeheight_pos=shp;         %mean of neg spike width in window

            %Calculate spike rates in window
            metrics(subject,i).spikerate_neg=length(negfilter)/sctSettings.NoiseDetection.dSlidingWindowSize;
            metrics(subject,i).spikerate_pos=length(posfilter)/sctSettings.NoiseDetection.dSlidingWindowSize;
            metrics(subject,i).spikerate_total=metrics(subject,i).spikerate_pos+metrics(subject,i).spikerate_neg;


            %-------------------
            %Slide window to next location
            start=start+sctSettings.NoiseDetection.dSlidingWindowStep*samplingRate*WindowFactor;
            finish=finish+sctSettings.NoiseDetection.dSlidingWindowStep*samplingRate*WindowFactor;
            i=i+1;
        end


        nrmn=mean([metrics(subject,:).nrchanges]);
        for i=1:length([metrics(subject,:).nrchanges])
            metrics(subject,i).nrchanges=metrics(subject,i).nrchanges-nrmn;
        end

        xrange=sctSettings.NoiseDetection.dSlidingWindowSize*samplingRate*WindowFactor/2:sctSettings.NoiseDetection.dSlidingWindowStep*samplingRate*WindowFactor:sctSettings.NoiseDetection.dSlidingWindowSize*samplingRate*WindowFactor/2+(length([metrics(subject,:).average])-1)*sctSettings.NoiseDetection.dSlidingWindowStep*samplingRate*WindowFactor;


        %================================================
        %Step 2: Compare relevant metrics to thresholds to identify noise
        %================================================
        % If a combination of the metrics triggers a noise-alert, this window is
        % labeled as "noisy" in the vector 'noisecriteria'
        % We then use the metric 'nrchanges' to find the edges of that noise event
        % Finally, the vector 'noisecriteria' is used to create a matrix of noise
        % events [start, end], both as indices of data.

        %Specify Noise Criteria Components
        %1. Number of direction changes 
        noise1=[metrics(subject,:).nrchanges]<1.5*ThrLower; %blue

        %2. Is average data too large or too little
        noise2=([metrics(subject,:).average]>0.5*ThrUpper)+([metrics(subject,:).average]<0.5*ThrLower); %red

        %3.Is average of positive peaks too high, or average of negative peaks too low
        noise3=max(([metrics(subject,:).average_high]>sctSettings.dNoiseUp(subject,2)),([metrics(subject,:).average_low]<sctSettings.dNoiseLow(subject,1))); %magenta

        %4. Does data fluctuate too much
        noise4=[metrics(subject,:).st]>1*sctSettings.dNoiseUp(subject,2); %green

        %5. Are the positive data or negative peak heights fluctuating too much?
        noise5=max(([metrics(subject,:).spikeheight_pos_st]>ThrUpper),([metrics(subject,:).spikeheight_neg_st]>-1*ThrLower)); %cyan

        %Combine Noise Criteria of Interest - This is where you ultimately
        %determine whether or not to flag a window as noise!
        totalnoise=noise2+noise3+0*noise4+0*noise5;
        noisecriteria=[totalnoise>1]; %yellow

        %Fill noise array if there was noise detected
        if sum(noisecriteria)>0

            %Find boundaries of noise event, using nrchanges
            %For each window, 'noisecriteria' will flag it as noisy (1) or not (0)
            i=1;
            while i<length(noisecriteria)
                if and(noisecriteria(i)==1,metrics(subject,i).nrchanges<0)
                    ileft=i;iright=i;
                    while (metrics(subject,ileft).nrchanges<0) && (metrics(subject,ileft).maximum-metrics(subject,ileft).minimum>ThrUpper-ThrLower) && (ileft>1)
                        noisecriteria(ileft)=1;
                        ileft=ileft-1;
                    end
                    while (metrics(subject,iright).nrchanges<0) && (metrics(subject,iright).maximum-metrics(subject,iright).minimum>ThrUpper-ThrLower) && (iright<length(noisecriteria))
                        noisecriteria(iright)=1;
                        iright=iright+1;
                    end
                    i=max(i+1,iright);
                else
                    i=i+1;
                end
            end

            %Use 'noisecriteria' to determine a matrix of [start, end] for each
            %noise event, as indices of 'data'

            %Check wether we start in noise or out of noise
            if (noisecriteria(1)==0) 
                InNoise=false; 
            else
                InNoise=true;
                noisestart=1;
            end

            %Continue search
            for i=1:length(noisecriteria)     
                 if InNoise         %in noise event
                     if noisecriteria(i)
                         %keep looking for the end of the current noise event
                     else
                         %add finished event and start looking for start of next
                         temp_pnNoise=[temp_pnNoise ; [xrange(noisestart) xrange(i)]];
                         InNoise=false;
                     end
                 else               %not in noise event
                     if noisecriteria(i)
                         %found start of next event -> start looking for the end
                         noisestart=i;
                         InNoise=true;
                     else
                         %keep looking for the start of the next noise event
                     end
                 end

            end

            %Check wether we end in noise or out of noise
            if InNoise
                %file is over while we were in noise. Add it to the noise list
                temp_pnNoise=[temp_pnNoise ; [xrange(noisestart) xrange(i)]];
            end

            %Glue together noise events that are close together
            %Note: Noise must be separated by more than 'glue_noise' to be counted as separate
            i=1;
            if ~isempty(temp_pnNoise)
                while i<length(temp_pnNoise(:,1))
                    glued = temp_pnNoise(i,:);
                    while and(i<length(temp_pnNoise),temp_pnNoise(i,1)-glued(2)<sctSettings.NoiseDetection.dJoinNoise*samplingRate)
                        glued = [glued(1) temp_pnNoise(i,2)];
                        i=i+1;
                    end
                    gluednoise = [gluednoise; glued];
                end
            end
            temp_pnNoise=gluednoise;
        end
        pnNoise{subject} = temp_pnNoise;
        %================================================
        %Step 3: Optionally display window metrics and noise identification in popup window
        %================================================
        if isempty(nDownSampFactor)
            bDoDisplay = 0; 
        end

        if (bDoDisplay)
            % down sample all data
            pdDSData = temp_pdData(1 : nDownSampFactor : end); 
            xrange = ceil(xrange / nDownSampFactor);
            pnDSNoise = ceil(temp_pnNoise / nDownSampFactor);


            FigureNoise=figure('units','normalized','outerposition',[0 0 1 1],'Name','Find Noise');
            subplot(2,1,1)
            plot(1:length(pdDSData),pdDSData);                                                      %plot data
            hold on
            plot(xrange,[metrics(subject,:).average],'r');
            plot(xrange,[metrics(subject,:).minimum],'Color',[0.5,0.5,0.5]);
            plot(xrange,[metrics(subject,:).maximum],'Color',[0.5,0.5,0.5]);
            %plot(xrange,[metrics.spikewidth_pos],'k');
            %plot(xrange,[metrics.spikewidth_pos_st],'--k');
            %plot(xrange,[metrics.spikeheight_pos],'b');
            %plot(xrange,[metrics.spikeheight_pos_st],'--b');
            %plot(xrange,-1*[metrics.spikeheight_neg_st],'--r');
            %plot(xrange,-1*[metrics.spikewidth_neg_st],'r');

            cl = sctSettings.AutoThresholds.dPctCutoffALLPeaks(1);
            ch = sctSettings.AutoThresholds.dPctCutoffALLPeaks(2);
            pch = sctSettings.AutoThresholds.dPctCutoffPosPeaks(2);
            ncl = sctSettings.AutoThresholds.dPctCutoffNegPeaks(1);

            plot([xrange(1) xrange(end)],[ThrUpper ThrUpper],'m');
            plot([xrange(1) xrange(end)],[ThrLower ThrLower],'m');
            plot([xrange(1) xrange(end)],[sctSettings.dNoiseUp(1,2) sctSettings.dNoiseUp(1,2)],'--r');
            plot([xrange(1) xrange(end)],[sctSettings.dNoiseLow(1,1) sctSettings.dNoiseLow(1,1)],'--r');
            plot([xrange(1) xrange(end)],[sctSettings.dSpikeUp(1) sctSettings.dSpikeUp(1)],'y');
            plot([xrange(1) xrange(end)],[sctSettings.dSpikeLow(1) sctSettings.dSpikeLow(1)],'y');
            minperc=num2str(round(cl*100,0));
            maxperc=num2str(round(ch*100,0));
            posperc=num2str(round(pch*100,0));
            negperc=num2str(round(ncl*100,0));
            legend('data','average','minimum','maximum',[maxperc '% data threshold (baseline)'],[minperc '% data threshold (baseline)'],[negperc '% neg spikes (noise cutoff)'],[posperc '% pos spikes (noise cutoff)'],'SD spike cutoff','SD spike cutoff');
            hold off

            %Second Plot is used to show only those metrics used in noise
            %detection, as well as the picked up noise for those metrics
            subplot(2,1,2)
            pldata=plot(1:length(pdDSData),pdDSData);
        %     axis([0,inf,-1,2]);
            hold on

            plot(xrange,[metrics(subject,:).nrchanges],'b');           %source of noise 1
            plot(xrange,[metrics(subject,:).average],'r');             %source of noise 2
            plot(xrange,[metrics(subject,:).average_high],'m');        %source of noise 3
            plot(xrange,[metrics(subject,:).average_low],'m');         %source of noise 3
            plot(xrange,[metrics(subject,:).st],'g');                  %source of noise 4
            plot(xrange,[metrics(subject,:).spikeheight_pos_st],'c');  %source of noise 5
            plot(xrange,[metrics(subject,:).spikeheight_neg_st],'c');  %source of noise 5

            noise1 = double(noise1);
            noise2 = double(noise2);
            noise3 = double(noise3);
            noise4 = double(noise4);
            noise5 = double(noise5);
            noisecriteria = double(noisecriteria); 

            noise1(noise1 == 0) = NaN; 
            noise2(noise2 == 0) = NaN; 
            noise3(noise3 == 0) = NaN; 
            noise4(noise4 == 0) = NaN; 
            noise5(noise5 == 0) = NaN; 
            noisecriteria(noisecriteria == 0) = NaN; 

            dMax = max(pdDSData); 
        %     dMin = min(pdDSData); 

            pln1=plot(xrange,1.5*dMax*noise1,'.b');                   %noise 1 triggered
            pln2=plot(xrange,1.55*dMax*noise2,'.r');                  %noise 2 triggered
            pln3=plot(xrange,1.6*dMax*noise3,'.m');                   %noise 3 triggered
            pln4=plot(xrange,1.65*dMax*noise4,'.g');                  %noise 4 triggered
            pln5=plot(xrange,1.7*dMax*noise5,'.c');                   %noise 5 triggered
            plnn=plot(xrange,1.75*dMax*noisecriteria,'.y','Linewidth',1); %NOISE triggered

            if ~isempty(pnDSNoise)
               for i=1:length(pnDSNoise(:,1))
                   plot([pnDSNoise(i,1) pnDSNoise(i,2)],[1.8*dMax 1.8*dMax],'y','LineWidth',2);
               end
               %lastnoise=plot([noise(i,1) noise(i,2)],[1.8 1.8],'y','LineWidth',2);
            end

            plot([xrange(1) xrange(end)],0.5*[ThrUpper ThrUpper],'--r');
            plot([xrange(1) xrange(end)],0.5*[ThrLower ThrLower],'--r');
        %     minperc=num2str(round(cl*100,0));
        %     maxperc=num2str(round(ch*100,0));
        %     posperc=num2str(round(pch*100,0));
        %     negperc=num2str(round(ncl*100,0));

            legend([pldata,pln1,pln2,pln3,pln4,pln5,plnn],{'Data','Noise 1 triggered','Noise 2 triggered', 'Noise 3 triggered', 'Noise 4 triggered','Noise 5 triggered','Identified Noise'});

            %UNUSED METRIC PLOTS
            %plot(xrange,[metrics.average_high],'r');
            %plot(xrange,[metrics.average_low],'c');
            %plot(xrange,[metrics.highpeakperc],'b');
            %plot(xrange,[metrics.average],'m');
            %plot(xrange,[metrics.minimum],'k');
            %plot(xrange,[metrics.maximum],'y');
            %plot([xrange(1) xrange(end)],[ThrUpper ThrUpper],'--b');
            %plot([xrange(1) xrange(end)],[ThrLower ThrLower],'--b');
            %plot([xrange(1) xrange(end)],[Settings.NoiseUpper Settings.NoiseUpper],'--m');
            %plot([xrange(1) xrange(end)],[Settings.NoiseLower Settings.NoiseLower],'--m');
            %plot(xrange,0.1*[metrics.tracelength],'c');
            %plot(xrange,[metrics.spikewidth_pos],'c');
            %plot(xrange,[metrics.spikewidth_neg],'m');
            %plot(xrange,[metrics.spikewidth_total],'--k');
            %plot(xrange,[metrics.increaserate],'--y');
            %plot(xrange,[metrics.spikerate_pos],'--k');
            %plot(xrange,[metrics.spikerate_neg],'--y');
            %plot(xrange,[metrics.spikewidth_total],'--k');
            %plot(xrange,[metrics.increaserate],'--y');
            %plot(xrange,[metrics.absmean],'--y');
            %plot(xrange,[metrics.zerox],'r');
            %plot(xrange,[metrics.meanx],'--r');
            %plot(xrange,[metrics.st_high],'--k');
            %plot(xrange,[metrics.spikewidth_pos],'k');
            %plot(xrange,[metrics.highpeakperc],'b');

            hold off
        end
    end
end
