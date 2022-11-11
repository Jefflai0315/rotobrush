function ColorModels = initColorModels(IMG, Mask, MaskOutline, LocalWindows, BoundaryWidth, WindowWidth)
% INITIALIZAECOLORMODELS Initialize color models.  ColorModels is a struct you should define yourself.
%
% Must define a field ColorModels.Confidences: a cell array of the color confidence map for each local window.
ColorModels = {};
numWindows = size(LocalWindows,1);
IMG = rgb2lab(IMG);
% get the colour of local windows using (localwindows,mask and img)
for i = 1:numWindows
    
    coor = LocalWindows(i,:);
    x= coor(1);
    y = coor(2);

    ymin = y-round(WindowWidth/2);
    xmin = x-round(WindowWidth/2);
    window = imcrop(IMG,[xmin ymin  WindowWidth-1 WindowWidth-1]);
    mask = imcrop(Mask,[xmin ymin  WindowWidth-1 WindowWidth-1]);
    maskOutline = imcrop(MaskOutline,[xmin ymin  WindowWidth-1 WindowWidth-1]);
    
    L_ = window(:,:,1);
    a_ = window(:,:,2);
    b_ = window(:,:,3);
    window_flat = [reshape(L_,[WindowWidth^2 1]) reshape(a_,[WindowWidth^2 1]) reshape(b_,[WindowWidth^2 1])];
    L_fg = L_(mask==255);
    a_fg = a_(mask==255);
    b_fg = b_(mask==255);
    X_fg = [L_fg a_fg b_fg];
    ColorModels{i}.Fg = (mask==255);
    ColorModels{i}.X_fg = X_fg;

    L_bg = L_(mask ==0);
    a_bg = a_(mask ==0);
    b_bg = b_(mask ==0);
    X_bg = [L_bg a_bg b_bg];
    ColorModels{i}.Bg = (mask==0);
    ColorModels{i}.X_bg = X_bg;
   
  
    options = statset('MaxIter',1500);
    GMM_fg = fitgmdist(X_fg,3,'RegularizationValue',0.001, 'Options', options);
    GMM_bg = fitgmdist(X_bg,3,'RegularizationValue',0.001, 'Options', options);

    f = pdf(GMM_fg,window_flat);
    b = pdf(GMM_bg,window_flat);
    % 
    f_ = reshape(f, [WindowWidth WindowWidth]);
    b_ = reshape(b, [WindowWidth WindowWidth]);
    
    fb = f_ ./ (f_ + b_);
    ColorModels{i}.ColorModel = fb;
    
    %sprintf(['generated ' num2str(i)])
    %imshow(mask)
    %b_w = cell2mat(bwboundaries(mask));
    %edge = zeros([WindowWidth WindowWidth]);
    %for j=1:size(b_w, 1)
    %    edge(b_w(j,1),b_w(j,2)) = 1;
    %end
    %imshow(edge)
    imshow(maskOutline)
    ColorModels{i}.BoundryEdge = maskOutline;
    
    %colorconfident 
    %D = bwdist(edge);
    D = bwdist(maskOutline);
    Wc = exp(-(D.^2)/((WindowWidth)/2)^2);
    Lt = double(mask/255);
    Pc = fb;
    Fc_top = sum(sum(abs(Lt-Pc) .* Wc));
    Fc_bot = sum(sum(Wc));
    Fc = 1 - (Fc_top/Fc_bot);
    ColorModels{i}.ColorConfidence = Fc;



end

% create for gmm , (1 for fg , 1 for bg)



end

