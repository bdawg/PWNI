% see here - http://www.mathworks.com/examples/daq/2581-log-analog-input-data-to-a-file-using-ni-devices





function main()
s = daq.createSession('ni');
ch1 = addAnalogInputChannel(s, 'Dev1', 0, 'Voltage');
ch2 = addAnalogInputChannel(s, 'Dev1', 1, 'Voltage');
ch3 = addAnalogInputChannel(s, 'Dev1', 2, 'Voltage');
ch4 = addAnalogInputChannel(s, 'Dev1', 3, 'Voltage');
s.Rate=99000;
s.DurationInSeconds = 2;

% Create a (binary) log file
fid1 = fopen('log.bin','w');

% Add a listener, put its handle in lh
lh = addlistener(s,'DataAvailable',@getData);

% Now acquire data continuously in background (non-blocking)
s.IsContinuous = true;
s.startBackground;


% Do something else
disp('Waiting 5 seconds')
pause(5)



end



function getData(src,event)
    disp('Called')
    %disp(event.Data)
end