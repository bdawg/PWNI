% see here - http://www.mathworks.com/examples/daq/2581-log-analog-input-data-to-a-file-using-ni-devices

s = daq.createSession('ni');
ch1 = addAnalogInputChannel(s, 'Dev1', 0, 'Voltage')
ch2 = addAnalogInputChannel(s, 'Dev1', 1, 'Voltage')
s.Rate=100000


% Create a (binary) log file
fid1 = fopen('log.bin','w');

% Add a listener, put its handle in lh
lh = addlistener(s,'DataAvailable',@(src, event)logData(src, event, fid1));

% Now acquire data continuously in background (non-blocking)
s.IsContinuous = true;
s.startBackground;


% Do something else
disp('Waiting 10 seconds')
pause(10)


% Stop acquistion, close log file
s.stop
delete(lh)
fclose(fid1);


%%%%%%%%
% Read the logged data
fid2 = fopen('log.bin','r');
[data,count] = fread(fid2,[3,inf],'double');
fclose(fid2);

time = data(1,:);
ch1 = data(2,:);
ch2 = data(3,:);
