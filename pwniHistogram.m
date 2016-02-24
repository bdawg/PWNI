% Results of pwniPlotData already in memory

channel=ch1 / max(ch2);%_sub;
nbins=100;

figure(3)
[histVals, histBins]=histcounts(channel,100);
binWidth = histBins(3) - histBins(2);
binCents = histBins(1:end-1)+binWidth/2;
plot(binCents, histVals)


[dummy, maxInd] = max(histVals);
histBins(maxInd)