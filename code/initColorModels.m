function ColorModels = initColorModels(IMG, Mask, MaskOutline, LocalWindows, BoundaryWidth, WindowWidth)
% INITIALIZAECOLORMODELS Initialize color models.  ColorModels is a struct you should define yourself.
%
% Must define a field ColorModels.Confidences: a cell array of the color confidence map for each local window.
ColorModels = {};
numWindows = size(LocalWindows,1);
IMG = rgb2lab(IMG);
% emphasize the importance of dist of pixels from boundary 
d = bwdist(MaskOutline)/1.5;
% get the colour of local windows using (localwindows,mask and img)
for k = 1:numWindows
    pc = [];
    coor = LocalWindows(k,:);
    x= coor(1);
    y = coor(2);

    xRange = (x-(WindowWidth/2)):(x+(WindowWidth/2 - 1));   
    yRange = (y-(WindowWidth/2)):(y+(WindowWidth/2 - 1)); 
    
    F = [];
    B = [];
    

    for x = xRange
        for y = yRange
            if d(y,x) < BoundaryWidth
                continue
            end
           
            if Mask(y,x) == 255 || Mask(y,x) == 1
               F(end+1,:) = IMG(y,x,:);
            else
               B(end+1,:) = IMG(y,x,:);
            end
        end
    end
    


    ColorModels{k}.fgData1 = F;
    ColorModels{k}.bgData1 = B;
    Fgmm = fitgmdist(F, 3, 'RegularizationValue', .01, 'Options', statset('MaxIter',1500,'TolFun',1e-5));
    Bgmm = fitgmdist(B, 3, 'RegularizationValue', .01, 'Options', statset('MaxIter',1500,'TolFun',1e-5));
    
    sigma_s = WindowWidth/2;



    num_sum = 0;
    den_sum = 0;
    % Compute color confidence for each pixel in the window
    xcounter = 1;
    for x=LocalWindows(k,1)-(WindowWidth/2):LocalWindows(k,1)+(WindowWidth/2 - 1)
        ycounter = 1;
        for y=LocalWindows(k,2)-(WindowWidth/2):LocalWindows(k,2)+(WindowWidth/2 - 1)
            pf = pdf(Fgmm,[IMG(y,x,1), IMG(y,x,2), IMG(y,x,3)]);
            bf = pdf(Bgmm,[IMG(y,x,1), IMG(y,x,2), IMG(y,x,3)]);
            pc = pf/(pf+bf);
            pcs(ycounter,xcounter) = pc;
            num_sum = num_sum + double(abs(Mask(y,x)-pc)) * exp((-d(y,x)^2)/sigma_s^2);
            den_sum = den_sum + exp((-d(y,x)^2)/sigma_s^2);
            ycounter = ycounter + 1;
        end
        xcounter = xcounter + 1;
    end
    fc = 1 - (num_sum/den_sum);
    ColorModels{k}.Confidence = fc;
    ColorModels{k}.foreGMM =Fgmm;
    ColorModels{k}.backGMM = Bgmm;
    ColorModels{k}.pc = pcs;
    ColorModels{k}.BoundryEdge = MaskOutline(yRange,xRange);

end


end




