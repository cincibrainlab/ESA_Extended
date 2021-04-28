function sctThresholds = calculateThresholds(pdData, dSampRate, sctSet, DoDisplay)
%Given data, shifted to recenter around 0, determine cutoffs of positive data points, negative datapoints, and all datapoints. 
%Used to set automatic thresholds in spike-determination. Optionally display the results in popout     
%Input:         'data'       contains data points of 1 file, as a row vector, recentered around 0
%               'Settings'   contains all settings parameters
%               'DoDisplay'  0=don't show, 1=show
%    
%Output:        'chline'     cutoff high of settings.ch% of all data
%               'clline'     cutoff low of settings.cl% of all data
%               'pchline'    cutoff high of settings.pch% of all data
%               'nclline'    cutoff low of settings.ncl% of all data
%
%Calls:         DetermineCutoffs
%
%Called by:     'CutoffsAutomic_Callback' in 'findallofthem.m'
%
%determine ALL spikes, including the teeny ones
%pchline=[];cnlline=[];pN=[];nN=[];
for i=1:size(pdData,2)
    temp_pdData = pdData(:,i);
    if length(dSampRate) > 1
        samplingRate = dSampRate(i);
    else
        samplingRate = dSampRate;
    end
    spp = peakseek(temp_pdData, sctSet.AutoThresholds.nPosPeaksMinDist, sctSet.AutoThresholds.dPosPeaksAmp);   %positive peak loc & data
    spn = peakseek(-temp_pdData, sctSet.AutoThresholds.nNegPeaksMinDist, sctSet.AutoThresholds.dNegPeaksAmp);  %negative peak loc & data

    % if size(pdData,2)>1
    %     spp=reshape(spp,size(pdData,2),[]);
    %     spn = reshape(spn,size(pdData,2),[]);
    % end
%determine standard deviations of data, and peaks
    sd_multiplier=sctSet.AutoThresholds.nNumSDfromMean;
    sd_data=std(temp_pdData); sddataline=sd_multiplier*sd_data;
    sd_pos=std(temp_pdData(spp)); sdposline=sd_multiplier*sd_pos;
    sd_neg=std(temp_pdData(spn)); sdnegline=-1*sd_multiplier*sd_neg;


    %histogram count, and cumulative histogram. Also find indices for low and high cutoffs
    [N,~, ~,~,clline,chline]=calculateCutoffs(temp_pdData,sctSet.AutoThresholds.dPctCutoffALLPeaks);  

    %Find the low and high cutoff of the positive spikes
    pchline=0;cnlline=0;pN=0;nN=0; %Make sure program doesn't crash if spp,spn are empty
    if ~isempty(spp)
        ppeakdata=temp_pdData(spp);
        [pN,~, ~,~,pclline, pchline]=calculateCutoffs(ppeakdata,sctSet.AutoThresholds.dPctCutoffPosPeaks);
    end

    %Find the low and high cutoff of the negative spikes
    if ~isempty(spn)
        npeakdata=temp_pdData(spn);
        [nN,~, ~,~,nclline,nchline]=calculateCutoffs(npeakdata,sctSet.AutoThresholds.dPctCutoffNegPeaks);
    end

    sctThresholds.CutoffAllPeaks(i,:) = [clline, chline]; 
    sctThresholds.CutoffPosPeaks(i,:) = [pclline, pchline];
    sctThresholds.CutoffNegPeaks(i,:) = [nclline, nchline];
    sctThresholds.StdDvAll(i,:)       = sddataline; 
    sctThresholds.StdDvPos(i,:)      = sdposline; 
    sctThresholds.StdDvNeg(i,:)       = sdnegline; 

    % downsample the data for display
    pdDownSampData = downsampleData(temp_pdData, samplingRate);

%Display histograms on screen
    if DoDisplay
        FigureThresholds=figure('units','normalized','outerposition',[0 0 1 1],'Name','Determine Thresholds');
        %plot data
        subplot(3,3,[1 2 3]);
        plot(pdDownSampData);
        hold on
        plotcl=plot([0 length(pdDownSampData)-1],[clline clline],'m');                %baseline (% of ALL data)
        plotch=plot([0 length(pdDownSampData)-1],[chline chline],'m');                %baseline (% of ALL data)
        plotpch=plot([0 length(pdDownSampData)-1],[pchline pchline],'--r');           %noise cutoff (%of +data)
        plotncl=plot([0 length(pdDownSampData)-1],[nclline nclline],'--r');           %noise cutoff (%of +data)
        plotsddata=plot([0 length(pdDownSampData)-1],[-sddataline -sddataline],'b');  
        plotsdneg=plot([0 length(pdDownSampData)-1],[sdnegline sdnegline],'y');       %spikes (#SD of -data)
        plotsdpos=plot([0 length(pdDownSampData)-1],[sdposline sdposline],'y');       %spikes (#SD of +data
        plotsddata2=plot([0 length(pdDownSampData)-1],[sddataline sddataline],'b');
        hold off

        %plot histograms
        subplot(3,3,4);
        histogram(temp_pdData);
        title('All datapoints');
        axis([2*clline 2*chline 0 0.5*max(N)]);
        hold on
        plot([clline clline],[0 0.5*max(N)],'m');
        plot([chline chline],[0 0.5*max(N)],'m');
        plot([-sddataline -sddataline],[0 0.5*max(N)],'b');
        plot([sddataline sddataline],[0 0.5*max(N)],'b');
        plot([sdnegline sdnegline],[0 max(nN)],'y');
        plot([sdposline sdposline],[0 max(pN)],'y');
        hold off

        subplot(3,3,5);
        histogram(temp_pdData(spp));
        title('Positive data');
        axis([0 2*pchline 0 inf]);
        hold on
        plot([pchline pchline],[0 max(pN)],'--r');
        plot([sdposline sdposline],[0 max(pN)],'y');
        hold off

        subplot(3,3,6);
        histogram(temp_pdData(spn));
        title('Negative data');
        axis([2*nclline 0 0 inf]);
        hold on
        plot([nclline nclline],[0 max(nN)],'--r');
        plot([sdnegline sdnegline],[0 max(nN)],'y');
        hold off

        %Add legend
        subplr=subplot(3,3,[7,8,9]);
        axis off
        legendbaseline=[num2str(100*(sctSet.AutoThresholds.dPctCutoffALLPeaks(1,2) - sctSet.AutoThresholds.dPctCutoffALLPeaks(1,1))) '% of data (detect baseline)'];
        noisebaseline=[num2str(100*sctSet.AutoThresholds.dPctCutoffPosPeaks(1,2)) '% of + or - data (used for noise)'];
        noisebaseline2=[num2str(100*(1-sctSet.AutoThresholds.dPctCutoffNegPeaks(1,1))) '%'];
        legend(subplr,[plotcl,plotsddata,plotsdneg,plotsdpos,plotpch],{legendbaseline,[num2str(sd_multiplier) 'SD data'],[num2str(sd_multiplier) 'SD -Data (detect -spikes)'],[num2str(sd_multiplier) 'SD +Data (detect +spikes)'],noisebaseline})

    end
end
end


function [N,Edges,cutoff_low,cutoff_high,clline,chline] = calculateCutoffs(data,cutoff)
%Given a dataset, and a lower and upper threshold for data, return the histcount,
%the indices for the cutoff values specified and the values reached here.
%
%Input:         'data'          Row vector of numerical data
%               'cl'            Proportion of data - low threshold 
%               'ch'            Proportion of data - high threshold
%
%Output:        'N'             Number of data points in each bin
%               'Edges'         Edges of each bin
%               'cutoff_low'    Number of data points below 'cl'%
%               'cutoff_high'   Number of data points above 'ch'%
%               'clline'        Value of data at 'cl'%
%               'chline'        Value of data at 'ch'%
%
%Calls:         
%
%Called by:     DetermineThresholds
%       
[N,Edges]=histcounts(data);
cumN=zeros(1,length(N));
progress_Thresholds = waitbar(0, 'Calculating Thresholds...','Name','Threshold Calculation','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(progress_Thresholds,'canceling',0);
cutoff_low = zeros(length(N),1);
cutoff_high = zeros(length(N),1);
clline = zeros(length(N),1);
chline = zeros(length(N),1);
tic;
for i=1:length(N)
%     if getappdata(progress_Thresholds,'canceling')
%                 break
%     end
% 
%     waitbar(i/length(N),progress_Thresholds,sprintf('Thresholds %d of %d', i, length(N)));
    cumN(i)=sum(N(1:i))/length(data);
    if cutoff_low(i)==0 && cumN(i)>cutoff(1)
        cutoff_low(i)=i;
        clline(i)=Edges(cutoff_low(i));
    end
    if cutoff_high(i)==0 && cumN(i)>cutoff(2)
        cutoff_high(i)=i;
        chline(i)=Edges(cutoff_high(i));
    end

end
toc
waitbar(1,progress_Thresholds,sprintf('Thresholds %d of %d', length(chline), length(N)));
cutoff_low = min(cutoff_low(cutoff_low~=0));
cutoff_high = min(cutoff_high(cutoff_high~=0));
clline = min(clline(clline~=0));
chline = min(chline(chline~=0));
pause(.5)
delete(progress_Thresholds);
end

function [pdDownSampData, varargout] = downsampleData(pdData, dSampRate)
    nDownSampFactor = round(dSampRate / 50);  
    if isequal(nDownSampFactor, 0)
        nDownSampFactor = 1;
        pdDownSampData = pdData;
        if nargout > 1
            varargout{1} = nDownSampFactor;
        end
    else
        pdDownSampData = downsample(pdData,nDownSampFactor);
        if nargout > 1
            varargout{1} = nDownSampFactor;
        end
    end

end


