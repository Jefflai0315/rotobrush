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
        A ...
    )
% UPDATEMODELS: update shape and color models, and apply the result to generate a new mask.
% Feel free to redefine this as several different functions if you prefer.


%update boundry 
t = WindowWidth/2;
windows = NewLocalWindows;
Mask = warpedMask;

K = rgb2lab(CurrentFrame);
Pf = [];
%Bw={};
%Fg = {};
%Kwindows = {}
%for i=1:size(windows,1)
    %pos = windows(i,:);
    %X = round(pos(1))-1;
    %Y = round(pos(2))-1;
    %Fg{i} = warpedMask(Y-t:Y+t, X-t:X+t);
    %Bw{i} = warpedMaskOutline(Y-t:Y+t, X-t:X+t);
    %Kwindows{i} = K(Y-t:Y+t, X-t:X+t,:);
%end


%getshape 
%Fs = {};
%for i = 1: size(LocalWindows,1)
    %bw = Bw{i};
    %D = bwdist(bw);
   % Wc = exp(-(D.^2)/(SigmaMin)^2);
  %  fs = 1 - Wc;
 %   Fs{i} = fs;
%end


%update colour 

fg_thresh = 0.75;
bg_thresh = 0.2;
for j = 1 : size(LocalWindows,1)
    
    %L_ = Kwindows{j}(:,:,1);
    %a_ = Kwindows{j}(:,:,2);
    %b_ = Kwindows{j}(:,:,3);

    coor = windows(j,:);
    x= coor(1);
    y = coor(2);

    ymin = y-round(WindowWidth/2);
    xmin = x-round(WindowWidth/2);
    window = imcrop(K,[xmin ymin  WindowWidth-1 WindowWidth-1]);
    mask = imcrop(warpedMask,[xmin ymin  WindowWidth-1 WindowWidth-1]);
    maskOutline = imcrop(warpedMaskOutline,[xmin ymin  WindowWidth-1 WindowWidth-1]);


    D = bwdist(mask);
    Wc = exp(-(D.^2)/(SigmaMin)^2);
    fs = 1 - Wc;
    ColorModels{j}.ShapeModel = fs;
    
    L_ = window(:,:,1);
    a_ = window(:,:,2);
    b_ = window(:,:,3);

    Kwindows_flat = [reshape(L_,[WindowWidth^2 1]) reshape(a_,[WindowWidth^2 1]) reshape(b_,[WindowWidth^2 1])];
    L_fg = L_(mask ==255 & fs > fg_thresh);
    a_fg = a_(mask ==255 & fs> fg_thresh);
    b_fg = b_(mask ==255 & fs> fg_thresh);
    X_fg = [L_fg a_fg b_fg];
    X_fg2 = [X_fg; ColorModels{j}.X_fg];
    
    L_bg = L_(mask == 0  & fs> bg_thresh);
    a_bg = a_(mask == 0 & fs> bg_thresh);
    b_bg = b_(mask == 0 & fs> bg_thresh);
    X_bg = [L_bg a_bg b_bg];
    X_bg2 = [X_bg; ColorModels{j}.X_bg];


%%
if(size(X_fg2, 1) > size(X_fg2, 2) && size(X_bg2, 1) > size(X_bg2, 2))
iter = 100;
converged = false;
while(converged == false)
iter = iter + 100;
options = statset('MaxIter',iter);
GMM_fg = fitgmdist(X_fg2,3,'RegularizationValue',0.1, 'Options', options);
GMM_bg = fitgmdist(X_bg2,3,'RegularizationValue',0.1, 'Options', options);
converged = GMM_bg.Converged && GMM_fg.Converged;
end


f = pdf(GMM_fg,Kwindows_flat);
b = pdf(GMM_bg,Kwindows_flat);
% 
f_ = reshape(f, [WindowWidth WindowWidth]);
b_ = reshape(b, [WindowWidth WindowWidth]);

fb = f_ ./ (f_ + b_);

if (numel(find(fb > .75)) < numel(find(ColorModels{j}.ColorModel > .75))) 
    ColorModels{j}.ColorModel = fb;

    D = bwdist(maskOutline);
    Wc = exp(-(D.^2)/((WindowWidth)/2)^2);
    Lt = double(mask/255);
   
    Fc_top = sum(sum(abs(Lt-fb) .* Wc));
    Fc_bot = sum(sum(Wc));
    ColorModels{j}.ColorConfidence = 1 - (Fc_top/Fc_bot);
    sprintf(['window ' num2str(j) ' updated'])
    ColorModels{j}.X_fg = X_fg;
    ColorModels{j}.X_bg = X_bg;
%else % no change
    %window{i}.X_fg = prevWindows{i}.X_fg;
     %window{i}.X_bg = prevWindows{i}.X_bg;
end
    sprintf([num2str(j) ' generated'])
%
%else
    % window{i}.X_bg = prevWindows{i}.X_fg;
     % window{i}.X_bg = prevWindows{i}.X_bg;
%end
end
%outWindows = windows;

%combine 
    fb= ColorModels{j}.ColorModel;
    Lt = double(mask/255);
    pf = (fs .* Lt) + ((1-fs).*fb); 
    Pf = [Pf ;pf];


end

%merge 
LocalWindows = NewLocalWindows;

end

