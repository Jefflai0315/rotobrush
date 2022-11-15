% MyRotobrush.m  - UMD CMSC426, Fall 2018
% You should set these parameters yourself:
WindowWidth = 80;  
ProbMaskThreshold = 0.55; 
NumWindows= 40; 
BoundaryWidth = 3;

%% Load images by changing fpath and mask_number
fpath = '../input';
mask_number = '2';

files = dir(fullfile(fpath, '*.jpg'));
imageNames = zeros(length(files),1);
images = cell(length(files),1);

for i=1:length(files)
    imageNames(i) = str2double(strtok(files(i).name,'.jpg'));
end

imageNames = sort(imageNames);
imageNames = num2str(imageNames);
imageNames = strcat(imageNames, '.jpg');

for i=1:length(files)
    images{i} = im2double(imread(fullfile(fpath, strip(imageNames(i,:)))));
end

% NOTE: to save time during development, you should save/load your mask rather than use ROIPoly every time.
if exist(strcat(fpath, '/../Mask',mask_number,'.png'))
    mask = imread(strcat(fpath, '/../Mask',mask_number,'.png'));
    mask = mask(:,:,1);
else
    mask = roipoly(images{1});
    size(mask)
    filename=['../','Mask', mask_number '.png'];
    imwrite(mask,filename);
    imshow(mask)
end


imshow(imoverlay(images{1}, boundarymask(mask,8),'red'));
set(gca,'position',[0 0 1 1],'units','normalized')
F = getframe(gcf);
[I,~] = frame2im(F);
imwrite(I, fullfile(strcat('../output/' ,strip(imageNames(1,:)))));


%% output frame1 to video 
outputVideo = VideoWriter(fullfile(strcat('../','result', mask_number,'.mp4')),'MPEG-4');
open(outputVideo);
writeVideo(outputVideo,I);



%% Sample local windows and initialize shape+color models:
[mask_outline, LocalWindows] = initLocalWindows(images{1},mask,NumWindows,WindowWidth,true);

ColorModels = ...
    initColorModels(images{1},mask,mask_outline,LocalWindows,BoundaryWidth,WindowWidth);

% You should set these parameters yourself:
fcutoff = 0.4;
SigmaMin = 2;
SigmaMax = WindowWidth;
R = 2;
A = (SigmaMax-SigmaMin)/((1-fcutoff)^R);

ShapeConfidences = ...
    initShapeConfidences(LocalWindows,ColorModels,...
    WindowWidth, SigmaMin, A, fcutoff, R);

% Show initial local windows and output of the color model:
imshow(images{1})
hold on
showLocalWindows(LocalWindows,WindowWidth,'r.');
hold off
set(gca,'position',[0 0 1 1],'units','normalized')
F = getframe(gcf);
[I,~] = frame2im(F);

%ColorConfidences = {};
%for i= 1:size(ColorModels ,2)
%    ColorConfidences{1,i}= ColorModels{i}.Confidence;
%end
%showColorConfidences(images{1},mask_outline,ColorConfidences,LocalWindows,WindowWidth);

%% MAIN LOOP %%
% Process each frame in the video.
for prev=1:(length(files)-1)
    curr = prev+1;
    fprintf('Current frame: %i\n', curr)
    
    %%% Global affine transform between previous and current frames:
    [warpedFrame, warpedMask, warpedMaskOutline, warpedLocalWindows] = calculateGlobalAffine(images{prev}, images{curr}, mask, LocalWindows);
    

    %%% Calculate and apply local warping based on optical flow:
    NewLocalWindows = ...
        localFlowWarp(warpedFrame, images{curr}, warpedLocalWindows,warpedMask,WindowWidth);
    
    % Show windows before and after optical flow-based warp:
    imshow(images{curr});
    hold on
    showLocalWindows(warpedLocalWindows,WindowWidth,'r.');
    showLocalWindows(NewLocalWindows,WindowWidth,'b.');
    hold off
    
    %%% UPDATE SHAPE AND COLOR MODELS:
    % This is where most things happen.
    % Feel free to redefine this as several different functions if you prefer.
    [ ...
        mask, ...
        LocalWindows, ...
        ColorModels, ...
        ShapeConfidences, ...
    ] = ...
    updateModels(...
        NewLocalWindows, ...
        LocalWindows, ...
        images{curr}, ...
        warpedMask, ...
        warpedMaskOutline, ...
        WindowWidth, ...
        ColorModels, ...
        ShapeConfidences, ...
        ProbMaskThreshold, ...
        fcutoff, ...
        SigmaMin, ...
        R, ...
        A,...
        BoundaryWidth ...
    );

    
    %% Write video frame:
    imshow(imoverlay(images{curr}, boundarymask(mask,8), 'red'));
    pause(1)
    set(gca,'position',[0 0 1 1],'units','normalized')
    F = getframe(gcf);
    [I,~] = frame2im(F);
    imwrite(I, fullfile(strcat('../output/' ,strip(imageNames(curr,:)))));
    writeVideo(outputVideo,I);
    
    
    imshow(images{curr})
    hold on
    showLocalWindows(LocalWindows,WindowWidth,'r.');
    
    hold off
    set(gca,'position',[0 0 1 1],'units','normalized')
    F = getframe(gcf);
    [I,~] = frame2im(F);
end

close(outputVideo);
disp('DONE')
