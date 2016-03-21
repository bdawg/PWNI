
clear all

%filename='acqdata_04022016Vibrtests_DMMEMSPoweredOff_20160204T134515'
%filename='acqdata_medVibr_20160203T173842'
datapath='\data\';

%datapath='/Volumes/data/';
filename='acqdata_20160318T235539'
%filename='acqdata17032016_1638_dark_20160318T134252'

filestring=[datapath filename '.bin'];

fid = fopen(filestring,'r');
[data,count] = fread(fid,[5,inf],'double');
fclose(fid);

time = data(1,:);
ch0 = data(2,:);
ch1 = data(3,:);
ch2 = data(4,:);
ch3 = data(5,:);

figure(3)
clf()
subplot(2,2,1)
plot(time,ch0')
axis tight
title('Channel 0')
ylabel('Voltage')
xlabel('Time')
subplot(2,2,2)
plot(time,ch1')
axis tight
title('Channel 1')
ylabel('Voltage')
xlabel('Time')
subplot(2,2,3)
plot(time,ch2')
axis tight
title('Channel 2')
ylabel('Voltage')
xlabel('Time')
subplot(2,2,4)
plot(time,ch3')
axis tight
title('Channel 3')
ylabel('Voltage')
xlabel('Time')


ch0Av = mean(ch0);
ch1Av = mean(ch1);
ch2Av = mean(ch2);
ch3Av = mean(ch3);
ch0err = std(ch0)/sqrt(length(ch0));
ch1err = std(ch1)/sqrt(length(ch1));
ch2err = std(ch2)/sqrt(length(ch2));
ch3err = std(ch3)/sqrt(length(ch3));

disp(['Ch 0: ' num2str(ch0Av,'%e') ' +- ' num2str(ch0err,'%e')])
disp(['Ch 1: ' num2str(ch1Av,'%e') ' +- ' num2str(ch1err,'%e')])
disp(['Ch 2: ' num2str(ch2Av,'%e') ' +- ' num2str(ch2err,'%e')])
disp(['Ch 3: ' num2str(ch3Av,'%e') ' +- ' num2str(ch3err,'%e')])

ch0Max = max(ch0);
ch1Max = max(ch1);
ch2Max = max(ch2);
ch3Max = max(ch3);
ch0Min = min(ch0);
ch1Min = min(ch1);
ch2Min = min(ch2);
ch3Min = min(ch3);

disp(['Ch 0 min: ' num2str(ch0Min,'%e') ' , max:' num2str(ch0Max,'%e')])
disp(['Ch 1 min: ' num2str(ch1Min,'%e') ' , max:' num2str(ch1Max,'%e')])
disp(['Ch 2 min: ' num2str(ch2Min,'%e') ' , max:' num2str(ch2Max,'%e')])
disp(['Ch 3 min: ' num2str(ch3Min,'%e') ' , max:' num2str(ch3Max,'%e')])






