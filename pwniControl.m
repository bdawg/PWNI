function varargout = pwniControl(varargin)
% PWNICONTROL MATLAB code for pwniControl.fig
%      PWNICONTROL, by itself, creates a new PWNICONTROL or raises the existing
%      singleton*.
%
%      H = PWNICONTROL returns the handle to a new PWNICONTROL or the handle to
%      the existing singleton*.
%
%      PWNICONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PWNICONTROL.M with the given input arguments.
%
%      PWNICONTROL('Property','Value',...) creates a new PWNICONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pwniControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pwniControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pwniControl

% Last Modified by GUIDE v2.5 17-Mar-2016 21:14:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pwniControl_OpeningFcn, ...
                   'gui_OutputFcn',  @pwniControl_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before pwniControl is made visible.
function pwniControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pwniControl (see VARARGIN)


%%%%%%%%%%%%% CONSTANTS %%%%%%%%%%%
sampleRate = 64000;
%scrollSpeed = 10000;
guiUpdateRate = 4;
realtimeRate = 15;
%rtPlotLength = 100; %Data points (after averaging)
rtBufferSize = 256000; %Samples per channel in user RT buffer

dataPath = '\data\';

enableFlipmount = true;
doSharedMem = true;
sharedMemKey = 'nullerRTSHM';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
daqS = daq.createSession('ni');
ch0 = addAnalogInputChannel(daqS, 'Dev1', 0, 'Voltage');
ch1 = addAnalogInputChannel(daqS, 'Dev1', 1, 'Voltage');
ch2 = addAnalogInputChannel(daqS, 'Dev1', 2, 'Voltage');
ch3 = addAnalogInputChannel(daqS, 'Dev1', 3, 'Voltage');
daqS.Rate=sampleRate;

%setappdata(handles.pwniControl,'scrollSpeed',scrollSpeed)
setappdata(handles.pwniControl,'daqS',daqS)
setappdata(handles.pwniControl,'ch0',ch0)
setappdata(handles.pwniControl,'ch1',ch1)
setappdata(handles.pwniControl,'ch2',ch2)
setappdata(handles.pwniControl,'ch3',ch3)
setappdata(handles.pwniControl,'sampleRate',sampleRate)

rtPlotLength = str2num(get(handles.plotWidthBox,'String'));
allRtPlots = zeros(rtPlotLength,4);
setappdata(handles.pwniControl,'allRtPlots',allRtPlots)
rtBuffer = zeros(rtBufferSize,4);
setappdata(handles.pwniControl,'rtBuffer',rtBuffer)
setappdata(handles.pwniControl,'acqState',false)
setappdata(handles.pwniControl,'dataPath',dataPath)
setappdata(handles.pwniControl,'doSharedMem',doSharedMem)
setappdata(handles.pwniControl,'sharedMemKey',sharedMemKey)
setappdata(handles.pwniControl,'shmObj',0)
setappdata(handles.pwniControl,'oldtime',datenum(now));
setappdata(handles.pwniControl,'enableFlipmount',enableFlipmount);

logo = imread('littleRD.png');
imshow(logo,'Parent',handles.logoAxes);
set(handles.logoAxes,'XTickLabel','')
set(handles.logoAxes,'YTickLabel','')

if enableFlipmount
    flipObj = serial('COM12', ...
    'BaudRate',115200,'DataBits',8,'Parity','none','StopBits',1,'FlowControl','none');
    fopen(flipObj); %Open the device
    flipObj.Terminator=''; %Set terminator to ''
else
    flipObj=0;
end
setappdata(handles.pwniControl,'flipObj',flipObj)


handles.vidTimer = timer(...
    'ExecutionMode', 'fixedRate', ...
    'Period', 1/realtimeRate, ...
    'TimerFcn', {@updateRealtimePlots,hObject} );
setappdata(handles.pwniControl,'videoState',false)

% handles.valTimer = timer(...
%     'ExecutionMode', 'fixedRate', ...
%     'Period', 1/guiUpdateRate, ...
%     'TimerFcn', {@updateGuiFn,hObject} );

% Use a timer to handle background data acquistion
% acqTimerRate = 2;
% handles.acqTimer = timer(...
%     'ExecutionMode', 'fixedRate', ...
%     'Period', 1/acqTimerRate, ...
%     'TimerFcn', {@acqTimerFunction,hObject} );
% start(handles.acqTimer)

% Choose default command line output for pwniControl
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%start(handles.valTimer);

% UIWAIT makes pwniControl wait for user response (see UIRESUME)
% uiwait(handles.pwniControl);


% --- Outputs from this function are returned to the command line.
function varargout = pwniControl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in exitBtn.
function exitBtn_Callback(hObject, eventdata, handles)
% hObject    handle to exitBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Exiting...')

%stop(handles.valTimer)
stop(handles.vidTimer)
%stop(handles.acqTimer)

daqS=getappdata(handles.pwniControl,'daqS');
delete(daqS)

shmObj = getappdata(handles.pwniControl,'shmObj');
if getappdata(handles.pwniControl,'shmObj') ~= 0
    delete(shmObj)
end

enableFlipmount=getappdata(handles.pwniControl,'enableFlipmount');
if enableFlipmount
    flipObj=getappdata(handles.pwniControl,'flipObj');
    fclose(flipObj);
    delete(flipObj);
end

delete(handles.pwniControl);
%delete(handles.valTimer)
delete(handles.vidTimer)

% --- Executes on button press in realtimeBtn.
function realtimeBtn_Callback(hObject, eventdata, handles)
% hObject    handle to realtimeBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
daqS = getappdata(handles.pwniControl,'daqS');
rtlh = getappdata(handles.pwniControl,'rtlh');
if getappdata(handles.pwniControl,'videoState') %Stop realtime display
    stop(handles.vidTimer);
    daqS.stop
    delete(rtlh)
    setappdata(handles.pwniControl,'videoState',false)
    set(handles.realtimeBtn,'ForegroundColor',[0 0 0])
    set(handles.statusText,'String','Realtime Display Stopped')
    
else %Start realtime display
    start(handles.vidTimer);
    setappdata(handles.pwniControl,'videoState',true)
    set(handles.realtimeBtn,'ForegroundColor',[0 0.7 0])
    set(handles.statusText,'String','Realtime Display Running')
    
    rtlh = addlistener(daqS,'DataAvailable',@(src,event)RTgetData(src, event, handles));
    setappdata(handles.pwniControl,'rtlh',rtlh)
    daqS.IsContinuous = true;
    daqS.startBackground;
end

function RTgetData(src,event,handles)

rtBuffer=getappdata(handles.pwniControl,'rtBuffer');
bSize = size(rtBuffer,1);
newdata=event.Data;
dSize = size(newdata,1);

%Replace oldest entries in buffer with new data:
rtBuffer(1:dSize,:) = newdata;
%Shift buffer so that newest data is at the end:
rtBuffer = circshift(rtBuffer,-dSize,1);

% axis(handles.plotAxes1,'auto');
% plot(rtBuffer(:,1),'Parent',handles.plotAxes2)
% set(handles.plotAxes2,'XTickLabel','')
% drawnow

if getappdata(handles.pwniControl,'doSharedMem')
    shmObj = getappdata(handles.pwniControl,'shmObj');
    % Not sure if this is necessary (to detach) but I'm worried about
    % memory leak
    if getappdata(handles.pwniControl,'shmObj') ~= 0
        delete(shmObj)
    end
    shmkey = getappdata(handles.pwniControl,'sharedMemKey');
    shmObj = shmobject(shmkey, newdata);
    setappdata(handles.pwniControl,'shmObj',shmObj)
end

% disp(etime(now,getappdata(handles.pwniControl,'oldtime')))
% setappdata(handles.pwniControl,'oldtime',now);

setappdata(handles.pwniControl,'rtBuffer',rtBuffer)
    

function updateRealtimePlots(hObject,eventdata,hfigure)
handles = guidata(hfigure);

% %scrollSpeed = getappdata(handles.pwniControl,'scrollSpeed');
% daqS = getappdata(handles.pwniControl,'daqS');
% ch0 = getappdata(handles.pwniControl,'ch0');
% ch1 = getappdata(handles.pwniControl,'ch1');
% ch2 = getappdata(handles.pwniControl,'ch2');
% ch3 = getappdata(handles.pwniControl,'ch3');
oldAllRtPlots = getappdata(handles.pwniControl,'allRtPlots');

% Reset plot length if changed
rtPlotLengthSet = str2num(get(handles.plotWidthBox,'String'));
if rtPlotLengthSet ~= size(oldAllRtPlots,1)
    oldAllRtPlots = zeros(rtPlotLengthSet,4);
end


% daqS.DurationInSeconds = avTime;
% 
% % This is blocking - maybe a problem for longer averages.
% tic
% %[data,time,triggerTime] = daqS.startForeground;
% data = daqS.inputSingleScan;
% toc

avTime = round(str2double(get(handles.avTimeBox,'String')));
rtBuffer=getappdata(handles.pwniControl,'rtBuffer');

%Get the desired amount from the buffer and average it
newData = rtBuffer(end-avTime+1:end,:);
newData = mean(newData,1);

allRtPlots = oldAllRtPlots(2:end,:);
allRtPlots(end+1,:) = newData;

yMin=str2double(get(handles.plotMinBox,'String'));
yMax=str2double(get(handles.plotMaxBox,'String'));

%axis(handles.plotAxes1,'auto');
plot(allRtPlots(:,1),'Parent',handles.plotAxes1)
axis(handles.plotAxes1,[-inf inf yMin yMax]);
set(handles.plotAxes1,'XTickLabel','')
%axis(handles.plotAxes2,'auto');
plot(allRtPlots(:,2),'Parent',handles.plotAxes2)
axis(handles.plotAxes2,[-inf inf yMin yMax]);
set(handles.plotAxes2,'XTickLabel','')
%axis(handles.plotAxes3,'auto');
plot(allRtPlots(:,3),'Parent',handles.plotAxes3)
axis(handles.plotAxes3,[-inf inf yMin yMax]);
set(handles.plotAxes3,'XTickLabel','')
%axis(handles.plotAxes4,'auto');
plot(allRtPlots(:,4),'Parent',handles.plotAxes4)
axis(handles.plotAxes4,[-inf inf yMin yMax]);
set(handles.plotAxes4,'XTickLabel','')

sigs = std(allRtPlots,0,1);
curFlux = allRtPlots(end,:);
txt1 = ['SD: ' num2str(sigs(1),3) ', Current: ' num2str(curFlux(1),3)];
txt2 = ['SD: ' num2str(sigs(2),3) ', Current: ' num2str(curFlux(2),3)];
txt3 = ['SD: ' num2str(sigs(3),3) ', Current: ' num2str(curFlux(3),3)];
txt4 = ['SD: ' num2str(sigs(4),3) ', Current: ' num2str(curFlux(4),3)];
set(handles.sigmaText1,'String',txt1)
set(handles.sigmaText2,'String',txt2)
set(handles.sigmaText3,'String',txt3)
set(handles.sigmaText4,'String',txt4)
% set(handles.sigmaText1,'String',['SD: ' num2str(sigs(1),3)])
% set(handles.sigmaText2,'String',['SD: ' num2str(sigs(2),3)])
% set(handles.sigmaText3,'String',['SD: ' num2str(sigs(3),3)])
% set(handles.sigmaText4,'String',['SD: ' num2str(sigs(4),3)])
drawnow limitrate

% Instead, now do this to the raw rtbuffer (in the listener callback)
% if getappdata(handles.pwniControl,'doSharedMem')
%     shmObj = getappdata(handles.pwniControl,'shmObj');
%     % Not sure if this is necessary (to detach) but I'm worried about
%     % memory leak
%     if getappdata(handles.pwniControl,'shmObj') ~= 0
%         delete(shmObj)
%     end
%     shmkey = getappdata(handles.pwniControl,'sharedMemKey');
%     shmObj = shmobject(shmkey, curFlux);
%     setappdata(handles.pwniControl,'shmObj',shmObj)
% end

setappdata(handles.pwniControl,'allRtPlots',allRtPlots)




function avTimeBox_Callback(hObject, eventdata, handles)
% hObject    handle to avTimeBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of avTimeBox as text
%        str2double(get(hObject,'String')) returns contents of avTimeBox as a double


% --- Executes during object creation, after setting all properties.
function avTimeBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to avTimeBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plotWidthBox_Callback(hObject, eventdata, handles)
% hObject    handle to plttext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plttext as text
%        str2double(get(hObject,'String')) returns contents of plttext as a double
rtPlotLength = str2num(get(handles.plotWidthBox,'String'));
allRtPlots = zeros(rtPlotLength,4);
setappdata(handles.pwniControl,'allRtPlots',allRtPlots)

% --- Executes during object creation, after setting all properties.
function plotWidthBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plttext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in rangePanel.
function rangePanel_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in rangePanel 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ch0 = getappdata(handles.pwniControl,'ch0');
ch1 = getappdata(handles.pwniControl,'ch1');
ch2 = getappdata(handles.pwniControl,'ch2');
ch3 = getappdata(handles.pwniControl,'ch3');
daqS = getappdata(handles.pwniControl,'daqS');
daqS.stop
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'rangeBtn1'
        ch0.Range=[-0.2,+0.2];
        ch1.Range=[-0.2,+0.2];
        ch2.Range=[-0.2,+0.2];
        ch3.Range=[-0.2,+0.2];
    case 'rangeBtn2'
        ch0.Range=[-1.0,+1.0];
        ch1.Range=[-1.0,+1.0];
        ch2.Range=[-1.0,+1.0];
        ch3.Range=[-1.0,+1.0];
    case 'rangeBtn3'
        ch0.Range=[-5.0,+5.0];
        ch1.Range=[-5.0,+5.0];
        ch2.Range=[-5.0,+5.0];
        ch3.Range=[-5.0,+5.0];
    case 'rangeBtn4'
        ch0.Range=[-10.0,+10.0];
        ch1.Range=[-10.0,+10.0];
        ch2.Range=[-10.0,+10.0];
        ch3.Range=[-10.0,+10.0];
end
daqS.startBackground;
            
 
        


% --- Executes on button press in startAcqBtn.
function startAcqBtn_Callback(hObject, eventdata, handles)
% hObject    handle to startAcqBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

daqS = getappdata(handles.pwniControl,'daqS');
dataPath = getappdata(handles.pwniControl,'dataPath');

% If already in acqusition mode, stop it.
if getappdata(handles.pwniControl,'acqState')
    setappdata(handles.pwniControl,'acqState',false)
    set(handles.startAcqBtn,'ForegroundColor',[0 0 0])
    set(handles.statusText,'String','Acquisition Stopped')
    daqS.stop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     acqlh=getappdata(handles.pwniControl,'acqlh');
%     delete(acqlh)

else % Start acqusition
    % If realtime is running, stop it and delete its listener
    if getappdata(handles.pwniControl,'videoState')
        rtlh = getappdata(handles.pwniControl,'rtlh');
        stop(handles.vidTimer);
        daqS.stop
        delete(rtlh)
        setappdata(handles.pwniControl,'videoState',false)
        set(handles.realtimeBtn,'ForegroundColor',[0 0 0])
        set(handles.statusText,'String','Realtime Display Stopped')
        pause(0.5)
    end
    
    set(handles.startAcqBtn,'ForegroundColor',[1 0 0])
    set(handles.statusText,'String','Acquisition Begun')
    setappdata(handles.pwniControl,'acqState',true)
    
    darkFreq = str2double(get(handles.darkFreqBox,'String'));
    shutterWaitTime = 5;
    fileCount = 1;
    
    % Start up the first file
    curFileSize = 0;
    filePref = get(handles.filenameBox,'String');
    filename = [dataPath filePref '_' datestr(clock,30) '.bin'];
    fid = fopen(filename,'w');
    acqlh = addlistener(daqS,'DataAvailable',@(src, event)logData(src, event, fid));
    setappdata(handles.pwniControl,'acqlh',acqlh)
    daqS.IsContinuous = true;
    daqS.startBackground;
    
    while getappdata(handles.pwniControl,'acqState')
        % The main acqusition loop  
        pause(0.5)
        
        set(handles.curFilenameText,'String',filename)
        fileInfo = dir(filename);
        curFileSize = fileInfo.bytes/1024/1024;
        set(handles.curSizeText,'String',num2str(curFileSize))
        
        % Change to a new file if necessary
        maxSize = str2num(get(handles.maxSizeBox,'String'));
        if curFileSize > maxSize
            daqS.stop
            delete(acqlh)
            fclose(fid);
            filePref = get(handles.filenameBox,'String');
            
            if darkFreq > 0
                if fileCount == darkFreq
                    fileCount = -1; %This means it will open the shutter next time
                    filePref = [filePref '_DARK'];                     
                    flipInBtn_Callback(hObject, eventdata, handles)
                    pause(shutterWaitTime)
                end
                if fileCount == 0
                    flipOutBtn_Callback(hObject, eventdata, handles)
                    pause(shutterWaitTime)
                end 
                fileCount = fileCount+1
            end
            
            filename = [dataPath filePref '_' datestr(clock,30) '.bin'];
            fid = fopen(filename,'w');
            acqlh = addlistener(daqS,'DataAvailable',@(src, event)logData(src, event, fid));
            setappdata(handles.pwniControl,'acqlh',acqlh)
            daqS.IsContinuous = true;
            daqS.startBackground;
        end
    end
    
    daqS.stop
    delete(acqlh)
    fclose(fid);
    disp('Acquistion ending')
end

% Enable acquisition state




function filenameBox_Callback(hObject, eventdata, handles)
% hObject    handle to filenameBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filenameBox as text
%        str2double(get(hObject,'String')) returns contents of filenameBox as a double


% --- Executes during object creation, after setting all properties.
function filenameBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filenameBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxSizeBox_Callback(hObject, eventdata, handles)
% hObject    handle to maxSizeBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxSizeBox as text
%        str2double(get(hObject,'String')) returns contents of maxSizeBox as a double


% --- Executes during object creation, after setting all properties.
function maxSizeBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxSizeBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plotMinBox_Callback(hObject, eventdata, handles)
% hObject    handle to plotMinBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plotMinBox as text
%        str2double(get(hObject,'String')) returns contents of plotMinBox as a double


% --- Executes during object creation, after setting all properties.
function plotMinBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotMinBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function plotMaxBox_Callback(hObject, eventdata, handles)
% hObject    handle to plotMaxBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plotMaxBox as text
%        str2double(get(hObject,'String')) returns contents of plotMaxBox as a double


% --- Executes during object creation, after setting all properties.
function plotMaxBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotMaxBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in releaseDaqBtn.
function releaseDaqBtn_Callback(hObject, eventdata, handles)
% hObject    handle to releaseDaqBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
daqS=getappdata(handles.pwniControl,'daqS');
rtlh = getappdata(handles.pwniControl,'rtlh');
sampleRate=getappdata(handles.pwniControl,'sampleRate');

% Pause the realtime display if necessary
if getappdata(handles.pwniControl,'videoState')
    stop(handles.vidTimer);
    daqS.stop
    delete(rtlh)
end

release(daqS)
msgbox('DAQ Released. Press OK to take it back.','DAQ Released')
uiwait
daqS = daq.createSession('ni');
ch0 = addAnalogInputChannel(daqS, 'Dev1', 0, 'Voltage');
ch1 = addAnalogInputChannel(daqS, 'Dev1', 1, 'Voltage');
ch2 = addAnalogInputChannel(daqS, 'Dev1', 2, 'Voltage');
ch3 = addAnalogInputChannel(daqS, 'Dev1', 3, 'Voltage');
daqS.Rate=sampleRate;
setappdata(handles.pwniControl,'daqS',daqS)
setappdata(handles.pwniControl,'ch0',ch0)
setappdata(handles.pwniControl,'ch1',ch1)
setappdata(handles.pwniControl,'ch2',ch2)
setappdata(handles.pwniControl,'ch3',ch3)

if getappdata(handles.pwniControl,'videoState')
    start(handles.vidTimer);
    rtlh = addlistener(daqS,'DataAvailable',@(src,event)RTgetData(src, event, handles));
    setappdata(handles.pwniControl,'rtlh',rtlh)
    daqS.IsContinuous = true;
    daqS.startBackground;
end



function bg0Box_Callback(hObject, eventdata, handles)
% hObject    handle to bg0Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bg0Box as text
%        str2double(get(hObject,'String')) returns contents of bg0Box as a double


% --- Executes during object creation, after setting all properties.
function bg0Box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bg0Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bg1Box_Callback(hObject, eventdata, handles)
% hObject    handle to bg1Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bg1Box as text
%        str2double(get(hObject,'String')) returns contents of bg1Box as a double


% --- Executes during object creation, after setting all properties.
function bg1Box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bg1Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bg2Box_Callback(hObject, eventdata, handles)
% hObject    handle to bg2Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bg2Box as text
%        str2double(get(hObject,'String')) returns contents of bg2Box as a double


% --- Executes during object creation, after setting all properties.
function bg2Box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bg2Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bg3Box_Callback(hObject, eventdata, handles)
% hObject    handle to bg3Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bg3Box as text
%        str2double(get(hObject,'String')) returns contents of bg3Box as a double


% --- Executes during object creation, after setting all properties.
function bg3Box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bg3Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in enableBgSubtCheckbox.
function enableBgSubtCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to enableBgSubtCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enableBgSubtCheckbox


% --- Executes on button press in measureBgCheckbox.
function measureBgCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to measureBgCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of measureBgCheckbox


% --- Executes on button press in flipInBtn.
function flipInBtn_Callback(hObject, eventdata, handles)
% hObject    handle to flipInBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
flipObj=getappdata(handles.pwniControl,'flipObj');
disp('Moving to position In')
posn = '02';
nbytes=6;
hexString={'6A' '04' '00' posn '50' '01'};
for ii = 1:nbytes
    hex=hexString{ii};
    dec=hex2dec(hex);
    fwrite(flipObj,dec,'uint8')
end

pause(3)

%Get status bits
%Send request:
nbytes=6;
hexString={'29' '04' '00' '00' '50' '01'};
for ii = 1:nbytes
    hex=hexString{ii};
    dec=hex2dec(hex);
    fwrite(flipObj,dec,'uint8')
end

%Retrieve the get
nbytes=12;
response=fread(flipObj,nbytes);
statusBits=response(9:12)

% --- Executes on button press in flipOutBtn.
function flipOutBtn_Callback(hObject, eventdata, handles)
% hObject    handle to flipOutBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
flipObj=getappdata(handles.pwniControl,'flipObj');
disp('Moving to position Out')
posn = '01';
nbytes=6;
hexString={'6A' '04' '00' posn '50' '01'};
for ii = 1:nbytes
    hex=hexString{ii};
    dec=hex2dec(hex);
    fwrite(flipObj,dec,'uint8')
end

pause(3)

%Get status bits
%Send request:
nbytes=6;
hexString={'29' '04' '00' '00' '50' '01'};
for ii = 1:nbytes
    hex=hexString{ii};
    dec=hex2dec(hex);
    fwrite(flipObj,dec,'uint8')
end

%Retrieve the get
nbytes=12;
response=fread(flipObj,nbytes);
statusBits=response(9:12)



function darkFreqBox_Callback(hObject, eventdata, handles)
% hObject    handle to darkFreqBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of darkFreqBox as text
%        str2double(get(hObject,'String')) returns contents of darkFreqBox as a double


% --- Executes during object creation, after setting all properties.
function darkFreqBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to darkFreqBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
