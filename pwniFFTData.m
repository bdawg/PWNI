% Results of pwniPlotData already in memory

channel=ch1;
channel2=ch2;
figure(2)


%channel=ytest.^2;


%window=hann(length(channel));
window=hamming(length(channel));

ch_win=window.*channel';
ps=abs(fft(ch_win)).^2;
freq=linspace(0,(1./(time(2)-time(1))),length(channel));
ps=ps./max(ps);

ch_win=window.*channel2';
ps2=abs(fft(ch_win)).^2;
freq=linspace(0,(1./(time(2)-time(1))),length(channel));
ps2=ps2./max(ps2);

% ps = ps+ps2;
% ps = ps./max(ps);

%hold on
plot(freq,ps)
title(filename)

axis([0 150 0 1e-4])
%axis([0 5e2 0 3e-6])
%axis([0 150 0 20e-4])