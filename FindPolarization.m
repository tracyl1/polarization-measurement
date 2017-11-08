%{ 
This code is used to calculate the polarization of laser light by analyzing
the motion of a rotating calcite crystal in an optical trap.

Overview of steps:
- Imports quadrant photodiode (QPD) data (.lvm)
- Computes the derivative of this data
- Locates local extrema of the derivative (correspond to maximum angular
velocity)
- Imports two video data files (.mat); linear and elliptical/circular
- Displays frames corresponding to extrema
- Takes user input and calculates polarization based on the angle of the
crystal in these frames
- Uses the extrema to determine average frequency and period

Written by Lucas Tracy, July 2017

Sections on conversion, smoothing, and calculating the derivative based on 
ProcessData_v4.m by:
Dr. Natalie Cartwright (SUNY New Paltz, Mathematics)
Dr. Catherine Herne (SUNY New Paltz, Physics and Astronomy)
January 2017
%}

% Import QPD data file (.lvm)
[fname, pname] = uigetfile('*.lvm','Choose .lvm QPD Data File');
cd(pname);
data = importdata(fname);

% Due to currently unresolved issues with the LabVIEW program which
% acquires our data there is a discrepancy between the time measured in
% the video and in the QPD data.  The factor by which the sensor data needs
% to be "stretched" is input and applied here.
convert = 1.03;
tt = convert*transpose(data(:,1)); 

% The QPD outputs 3 pieces of data for each sample point.  These correspond
% to x-difference, y-difference, and sum signals. They are stored in
% columns 2, 3, and 4 of our .lvm respectively.
II = transpose(data(:,4));

% This section filters the QPD data to reduce the impact of noise on the
% rest of the code.  It is currently commented out for two reasons:
% 1. Our current data is not noisy enough to warrant it
% 2. The noise which is present just so happens to reside in a very
% similar frequency range to our data (basically the filter destroys our data) 
% 
% In order to determine the 'PassbandFrequency' and 'StopbandFrequency'
% parameters a fast fourier transform (QPD_FFT.m) should be performed on
% the QPD data
%{
lpf = designfilt('lowpassfir', 'PassbandFrequency', 1.5, 'StopbandFrequency', 2, 'PassbandRipple', 1, 'StopbandAttenuation', 60, 'SampleRate', 60);
II = filter(lpf, II);
%}

% This section smooths the data using some custom functions (fastmooth.m
% and sa.m). Smoothing the data is most likely unnecessary if it is
% filtered.
newdata = fastsmooth((II),5,2,1); 
newII = newdata;

% Compute derivative using central difference
n = length(newII);
dII = zeros(size(newII));
dIIdtt(1) = newII(2)-newII(1)/(tt(2)-tt(1));
dIIdtt(n) = newII(n)-newII(n-1)/(tt(n) - tt(n-1));

for j = 2:n-1;
  dIIdtt(j)= (newII(j+1)-newII(j-1)) ./ (tt(j+1)-tt(j-1));
end

% Subset and normalize data
st = size(tt);
s = int64(st(2)/1);

ttnorm = tt(2:s);
IInorm = (II(2:s)-min(II(2:s)))/(max(II(2:s))-min(II(2:s)));
newIInorm = (newII(2:s)-min(newII(2:s)))/(max(newII(2:s))-min(newII(2:s)));
dIIdttnorm = dIIdtt(2:s)/max(dIIdtt(2:s));

% Here the local extrema are identified.  The 'MinPeakDistance' and
% 'MinPeakHeight' values are declared as variables because they are called
% again at the end of the code. The last two lines of this section contain
% some manipulations of the findpeaks function which allows us to identify
% minima as well as maxima.
minDist = .3;
minHeight = .01;
[Maxima, MaxIdx] = findpeaks(dIIdttnorm,ttnorm,'MinPeakDistance',minDist,'MinPeakHeight',minHeight);
[Minima, MinIdx] = findpeaks(-dIIdttnorm,ttnorm,'MinPeakDistance',minDist,'MinPeakHeight',minHeight);
Minima = -Minima;

% Set the framerate of the video, and use this to convert the timestamps of
% the maxima and minima from seconds to frames.
framerate = 30;
MaxFrames = round(MaxIdx*framerate);
MinFrames = round(MinIdx*framerate);

% Load in the video (.mat) file of the crystal in linearly polarized light.
% Set linearframe to correspond to a point in the video where the
% crystal is trapped, and stationary.
[Vidfname, Vidpname] = uigetfile('*.mat','Choose linear polarization .mat file');
cd(Vidpname);
load(Vidfname);
linearframe = 30;

% The next few chunks of code take inputs from the user. The idea is to
% first identify the center of rotation, and then to choose an
% "Identifiable Feature". Such a feature being one you can locate, and
% click on again in a later prompt.
imagesc(vidFrame(:,:,:,linearframe))
title('Locate Center of Rotation')
[xcl,ycl]=ginput;
close

imagesc(vidFrame(:,:,:,linearframe))
title('Locate Identifiable Feature')
[x0,y0]=ginput;
close

% Load in the video (.mat) file of the crystal in circularly/elliptically
% polarized light.
[Vidfname, Vidpname] = uigetfile('*.mat','Choose circular/elliptical polarization .mat file');
cd(Vidpname);
load(Vidfname);

% This section solicits user input once again. Often, if not always, there
% are sections of the QPD data which do not contain useful information
% (there is no crystal rotating).  These sections can result in extrema we
% do not care about.  There are plans to implement an algorithm to sift
% these useless extrema out, but currently the index of the extrema to be
% analyzed must be determined manually.
imagesc(vidFrame(:,:,:,MaxFrames(24)))
title('Relocate Identifiable Feature')
[x1,y1]=ginput;
close

% Use a little trigonometry to calculate the angle of rotation of the
% crystal.  Print these values to the console.  These values are our
% polarization measurements in radians, and degrees respectively.
phirad = abs(atan((y0-ycl)/(x0-xcl))-atan((y1-ycl)/(x1-xcl)))
phideg = phirad*(180/pi)

% This section displays each and every individual frame of the rotation
% video corresponding to an extrema.  It's currently commented
% out as it's a bit unnecessary and unwieldy.  It can easy be un-commented
% if you wish to visually check the consistency of the crystal position in 
% each frame.
%{
for i=2:length(MaxFrames)+1
    figure(i)
    imagesc(vidFrame(:,:,:,MaxFrames(i-1)))
end
j=1;
for k=length(MaxFrames)+2:length(MaxFrames)+length(MinFrames)+1
    figure(k)
    imagesc(vidFrame(:,:,:,MinFrames(j)))
    j=j+1;
end
%}

% This section calculates the average frequency of the crystal's rotation.
% It also represents my first attempt at an algorithm to account for
% useless sections of the data.  It still needs a lot of work. The loop
% goes through each peak determining if the time difference between the
% peak at index 'n' and the following one is significantly greater than the
% average distance between the peaks which have been condsidered so far.
% The loop ends if there is a large gap between peaks.  The last peak
% before the gap is set as the end of the range over which the average
% frequency will be calculated.
%{
n=2;
while i==0
    avg = (MaxIdx(n)-MaxIdx(1))/(n-1);
    if MaxIdx(n)-MaxIdx(n-1)<=(avg+.5)
        lastCycle = n;
        n=n+1;
    else
        i=1;
    end
end
numCycles = lastCycle-1;
deltat = MaxIdx(lastCycle) - min(MaxIdx);
freq = numCycles/deltat
period = 1/freq
%}

% Finally this section plots the data with indicators for the maxima. Due
% to the way the minima were identified it's not as trivial to mark them on
% the plot.  I'm sure there's a way to do this, but I never got around to
% looking into it since the primary purpose of this code is to ouput a
% polarization measurement.
figure(1)
findpeaks(dIIdttnorm, ttnorm, 'MinPeakDistance',minDist,'MinPeakHeight',minHeight)
xlabel('time (s)')
ylabel('derivative of intensity (a.u.)')
grid on
g=gca;
set(g,'fontsize',20)