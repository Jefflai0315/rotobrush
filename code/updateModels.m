function [Mask, LocalWindows, ColorModels, ShapeConfidences] = ...
    updateModels(...
        NewLocalWindows, ...
        LocalWindows, ...
        CurrentFrame, ...
        warpedMask, ...
        warpedMaskOutline, ...
        WindowWidth, ...
        ColorModels, ...
        ShapeConfidences, ...
        ProbMaskThreshold, ...
        fcutoff, ...
        SigmaMin, ...
        R, ...
        A, ...
        BoundaryWidth ...
    )
% UPDATEMODELS: update shape and color models, and apply the result to generate a new mask.
% Feel free to redefine this as several different functions if you prefer.


%variables
windows = NewLocalWindows;
K = rgb2lab(CurrentFrame);
%Pf = {};
pFx = [];


% calculate shapecnfidence from the new localwindows using previous bw and pc
tmpShapeConf = initShapeConfidences(NewLocalWindows,ColorModels,WindowWidth,SigmaMin,A,fcutoff,R);

tmpNum = zeros(size(warpedMask));
tmpDenom = zeros(size(warpedMask));
%pF = zeros(size(warpedMask));


for j = 1 : size(LocalWindows,1)
    

    coor = windows(j,:);
    win_x= coor(1);
    win_y = coor(2);

    X = round(win_x-(WindowWidth/2));
    Y = round(win_y-(WindowWidth/2));
    XX = X + WindowWidth-1;
    YY = Y + WindowWidth-1;
    if(XX >= size(CurrentFrame,2))
        XX = size(CurrentFrame,2)-1;
        X = XX -(WindowWidth)+1;
       
    end

     if(X <1)
        X = 1;
        XX = WindowWidth;
     end

    if(YY >= size(CurrentFrame,1))
        YY = size(CurrentFrame,1)-1;
        Y = YY -(WindowWidth)+1;
       
    end

     if(Y <1)
        Y = 1;
        YY = WindowWidth;
     end
   
    xRange = X:XX;   
    yRange = Y:YY;
    IMG = K(yRange,xRange,:);
    locMask = double(warpedMask(yRange,xRange));
    fgData = [];
    bgData = [];
    % emphasize the importance of dist of pixels from boundary 
    dist = bwdist(warpedMaskOutline(yRange,xRange))/1.3;

    for x = 1:length(xRange)
        for y = 1:length(yRange)
            if dist(y,x) < BoundaryWidth
                continue
            end
            
            if locMask(y,x) == 1 && tmpShapeConf{j}(y,x) >= 0.75
                fgData(end+1,:) = IMG(y,x,:);
            elseif locMask(y,x) == 0 && tmpShapeConf{j}(y,x) <= 0.25
                bgData(end+1,:) = IMG(y,x,:);
            end
        end
    end



%%
%if(size(X_fg2, 1) > size(X_fg2, 2) && size(X_bg2, 1) > size(X_bg2, 2))
if (size(fgData,1)>3)
    fgData = [fgData ; fgData ;ColorModels{j}.fgData1 ];
    foregroundGMM = fitgmdist(fgData, 3, 'RegularizationValue', 0.1, 'Options', statset('MaxIter',1500,'TolFun',1e-5));  
else
    foregroundGMM = ColorModels{j}.foreGMM;
end

if size(bgData,1) > 3
    bgData = [bgData ;ColorModels{j}.bgData1 ];
    backgroundGMM = fitgmdist(bgData, 3, 'RegularizationValue', 0.1, 'Options', statset('MaxIter',1500,'TolFun',1e-5));   
else
    backgroundGMM = ColorModels{j}.backGMM;
end

datafit = reshape(IMG,WindowWidth^2,3);

% Calculating probability mask with old models
pxFold = pdf(ColorModels{j}.foreGMM,datafit);
pxBold = pdf(ColorModels{j}.backGMM,datafit);
valOld = pxFold./(pxFold+pxBold);
pCXold = reshape(valOld,WindowWidth,WindowWidth);

% Calculating probability mask with new models
pxFnew = pdf(foregroundGMM,datafit);
pxBnew = pdf(backgroundGMM,datafit);
valNew = pxFnew./(pxFnew+pxBnew);   
pCXnew = reshape(valNew,WindowWidth,WindowWidth);

[new,~] = find(pCXnew>ProbMaskThreshold);
[old,~] = find(pCXold>ProbMaskThreshold);


if (length(new)<length(old))
    weight = exp(-(dist.^2)/(WindowWidth*0.5)^2);
    denom = sum(sum(weight));
    numer = sum(sum(abs(locMask - pCXnew).*weight));
    ColorModels{j}.ColorConfidence = 1 - numer/denom;
    ColorModels{j}.foreGMM = foregroundGMM;
    ColorModels{j}.backGMM = backgroundGMM;
    ColorModels{j}.pcs(:,:) = pCXnew;
else
    ColorModels{j}.pcs(:,:) = pCXold;
end


%% Updating Shape Model
        
% Calculating the new shape confidence based on simga_s 
if fcutoff < ColorModels{j}.Confidence
    SigmaS = SigmaMin + A*(ColorModels{j}.Confidence - fcutoff)^R;
else
    SigmaS = SigmaMin;
end

ShapeConfidences{j}(:,:) = 1 - exp(-(dist.^2)/((SigmaS)^2));

%% Merging color and shape confidences
for x = 1:length(xRange)
    for y =1:length(yRange)
        pFx(j,y,x) = ShapeConfidences{j}(y,x) * locMask(y,x) + (1-ShapeConfidences{j}(y,x)) * ColorModels{j}.pcs(y,x);
    end
end
        
%% Merging windows
        % Calculating the final foreground probability for all pixels in the image
for y = 1:length(yRange)
    for x = 1:length(xRange)
        dstFromCenter = 1/(sqrt((yRange(y)-win_y)^2 + (xRange(x)-win_x)^2)+0.1);
        tmpNum(yRange(y),xRange(x)) = tmpNum(yRange(y),xRange(x)) + double(pFx(j,y,x))*dstFromCenter;
        tmpDenom(yRange(y),xRange(x)) = tmpDenom(yRange(y),xRange(x))+ dstFromCenter;
    end
end
        
end 

%% Get final foreground probability mask

    % Setting up pF
    pF = (tmpNum)./(tmpDenom);
    pF(isnan(pF))=0;
    
    % Getting mask from pF if above threshold
    Mask = (pF>ProbMaskThreshold);
    %set(gcf,'visible','off')

    % Getting mask outline from the new mask generated above
    %mask_outline = bwperim(Mask,4);
   % imshow(mask_outline);
    LocalWindows = NewLocalWindows;
    Mask =bwareaopen(Mask, 60);
    se = strel('line',2,0);
    Mask = imdilate(Mask,se);
    se = strel('line',2,90);
    Mask = imdilate(Mask,se);
    
end