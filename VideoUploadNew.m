% function VideoUpload

% Some very simple code to read in video frames into matlab. Let me know if
% you need any other functions that I may not have attached. 

% Find and select file to be uploaded
[fname, pname] = uigetfile('*.*','testUpload');
% Change path to file path
cd(pname)

% Read file name into video reader (Function appended to end
readerobj = VideoReader(fname, 'tag', 'myreader1');

% Get the number of frames. There are many more options here that you can
% get from the video object. If you simply type get(readerobj) in the
% command prompt (once you have created readerobj) you will get a list of
% different things that can be called. You probably already know this...
numFrames = get(readerobj, 'NumberOfFrames');

% Create a MATLAB movie struct from the video frames.
for k = 1 : round(numFrames/2)
    % Read in all video frames.
    vidFrame(:,:,:,k) = read(readerobj,k);
    % Here, I was collecting the average RGB value. I left it simply to
    % show... nothing... I'm just being lazy.
%     avg(k,:,:) = mean(mean(vidFrame)); % gives 1,1,3 RGB average for frame...
end


%% You will have to create a new function with the code attached here (in
% case you do not have VideoReader)

