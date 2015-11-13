% See here - http://au.mathworks.com/help/daq/examples/acquire-data-using-ni-devices.html#zmw57dd0e566



s = daq.createSession('ni');
ch1 = addAnalogInputChannel(s, 'Dev1', 0, 'Voltage')
ch2 = addAnalogInputChannel(s, 'Dev1', 1, 'Voltage')
s.Rate=200000
s.DurationInSeconds = 1;


% Get some properties, and set some
sub = ch1.Device.Subsystems
get(sub(1)) % Lists its properties
ch1.Range=[-10,+10] %Set a property


data = s.inputSingleScan % Do one measurement (so returns 2 vals for 2 channels)

% This is starts session in 'Foreground', which means it's blocking.
[data,time,triggerTime] = s.startForeground;

plot(time,data(:,2));
xlabel('Time (secs)');
ylabel('Voltage')

delete(s)


