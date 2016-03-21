% Results of pwniPlotData already in memory

dark=0;%-3.627308e-04;
channel=(ch1-dark) / mean(max(ch1-dark));%_sub;
nbins=100;

figure(4)
[histVals, histBins]=histcounts(channel,100);
binWidth = histBins(3) - histBins(2);
binCents = histBins(1:end-1)+binWidth/2;
plot(binCents, histVals)


[dummy, maxInd] = max(histVals);
histBins(maxInd)