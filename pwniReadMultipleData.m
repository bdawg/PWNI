

filePrefix = 'acqdata_';
filePath = '/data/';
fileExtn = '.bin';

skipRead = true;

gain = 1e9; % V/W. Set to 1 to keep units as Volts.
subtBias = true;
nSampScl = 32; % Reduce n by this factor to account for oversampling
               % (Very rough approach - do stats properly).

yr = [-1e-14, 3.5e-14];           
               
               
%%% Data set 1:
startTimeString1 = '20151127T224319';
%endTimeString1 = '20151127T225624';
endTimeString1 = '20151127T231812';

% Data after this are considered a separate set
delimTimeString = '20151127T225624';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

formatIn = 'yyyymmddTHHMMSS';
startTimeNum = datenum(startTimeString1,formatIn);
endTimeNum = datenum(endTimeString1,formatIn);
delimTimeNum = datenum(delimTimeString,formatIn);

listing = dir([filePath '*' fileExtn]);
allFileNames = { listing.name };
nAllFiles = length(allFileNames);
pLength = length(filePrefix);
fCount = 1;

if ~skipRead
    for k = 1:nAllFiles
        curName = allFileNames{k};
        curTimeStr = curName(pLength+1:pLength+1+15);
        curTimeNum = datenum(curTimeStr,formatIn);

        if (curTimeNum >= startTimeNum) && (curTimeNum <= endTimeNum)
            
            if curTimeNum <= delimTimeNum
                dataSet(fCount) = 1;
            else
                dataSet(fCount) = 2;
            end
            
            % Read this file and save its statistics
            filestring=[filePath curName];
            disp(['Reading ' filestring])

            fid = fopen(filestring,'r');
            [data,count] = fread(fid,[5,inf],'double');
            fclose(fid);

            time = data(1,:);
            ch0 = data(2,:);
            ch1 = data(3,:);
            ch2 = data(4,:);
            ch3 = data(5,:);

            ch0Av(fCount) = mean(ch0)/gain;
            ch1Av(fCount) = mean(ch1)/gain;
            ch2Av(fCount) = mean(ch2)/gain;
            ch3Av(fCount) = mean(ch3)/gain;
            ch0err(fCount) = std(ch0)/sqrt(length(ch0)/nSampScl)/gain;
            ch1err(fCount) = std(ch1)/sqrt(length(ch1)/nSampScl)/gain;
            ch2err(fCount) = std(ch2)/sqrt(length(ch2)/nSampScl)/gain;
            ch3err(fCount) = std(ch3)/sqrt(length(ch3)/nSampScl)/gain;
            timeNums(fCount) = curTimeNum;

            clear ch0;
            clear ch1;
            clear ch2;
            clear ch3;
            clear time;
            clear data;

            fCount = fCount + 1;
        end
    end
    
    s1ix = find(dataSet == 1);
    s2ix = find(dataSet == 2);
    % Assumes set 2 is dark
    bias0 = mean(ch0Av(s2ix));
    bias1 = mean(ch1Av(s2ix));
    bias2 = mean(ch2Av(s2ix));
    bias3 = mean(ch3Av(s2ix));
    %bias = mean([bias0 bias1 bias2 bias3])
    if subtBias
        ch0Av = ch0Av - bias0;
        ch1Av = ch1Av - bias1;
        ch2Av = ch2Av - bias2;
        ch3Av = ch3Av - bias3;
    end
end


s1ix = find(dataSet == 1);
s2ix = find(dataSet == 2);

figure(2)
clf()
subplot(2,2,1)
hold on
%errorbar(timeNums,ch0Av,ch0err)
errorbar(ch0Av(s1ix),ch0err(s1ix))
errorbar(ch0Av(s2ix),ch0err(s2ix),'r')
title('Channel 0')
xlabel('File index (arb)')
ylabel('Watts')
axis([-inf inf yr(1) yr(2)]);
hold off

subplot(2,2,3)
hold on
%errorbar(timeNums,ch1Av,ch1err)
errorbar(ch1Av(s1ix),ch1err(s1ix))
errorbar(ch1Av(s2ix),ch1err(s2ix),'r')
title('Channel 1')
xlabel('File index (arb)')
ylabel('Watts')
axis([-inf inf yr(1) yr(2)]);
hold off

subplot(2,2,4)
hold on
%errorbar(timeNums,ch2Av,ch2err)
errorbar(ch2Av(s1ix),ch2err(s1ix))
errorbar(ch2Av(s2ix),ch2err(s2ix),'r')
title('Channel 2')
xlabel('File index (arb)')
ylabel('Watts')
axis([-inf inf yr(1) yr(2)]);
hold off

subplot(2,2,2)
hold on
%errorbar(timeNums,ch3Av,ch3err)
errorbar(ch3Av(s1ix),ch3err(s1ix))
errorbar(ch3Av(s2ix),ch3err(s2ix),'r')
title('Channel 3')
xlabel('File index (arb)')
ylabel('Watts')
axis([-inf inf yr(1) yr(2)]);
hold off







    