function [WarpedFrame, WarpedMask, WarpedMaskOutline, WarpedLocalWindows] = calculateGlobalAffine(IMG1,IMG2,Mask,Windows)
% CALCULATEGLOBALAFFINE: finds affine transform between two frames, and applies it to frame1, the mask, and local windows.
img1 = IMG1;
img2 = IMG2;


%% Detect Transformation
temp_img = rgb2gray(img1);
temp_img2 = rgb2gray(img2);
pts1 = detectSURFFeatures(temp_img,"MetricThreshold",200);
pts2 = detectSURFFeatures(temp_img2,"MetricThreshold",200);
[ft1,vpoints1] = extractFeatures(temp_img, pts1);
[ft2,vpoints2] = extractFeatures(temp_img2,pts2);

%% Show detected points
%imshow(img1);
% hold on
% %plot(pts1.Location(:,1),pts1.Location(:,2),'.', 'Color', 'r');
% hold off
% 
 idxpair = matchFeatures(ft1,ft2);
 matchedPoints1 = vpoints1(idxpair(:, 1));
 matchedPoints2 = vpoints2(idxpair(:, 2));
%% Estimage Geometric Transform
[tform,inlierIdx2, inlierIdx1] = estimateGeometricTransform(matchedPoints1, ...
    matchedPoints2, 'affine');
%tform = estimateGeometricTransform(inlierIdx1, ...
%    inlierIdx2, 'affine');

rout = imref2d(size(IMG2));
WarpedFrame = imwarp(IMG1,tform,'OutputView', rout);
WarpedMask = imwarp(Mask, tform,'OutputView', rout);
WarpedMaskOutline = bwperim(WarpedMask,4);

WarpedLocalWindows = round(transformPointsForward(tform,Windows));

%showMatchedFeatures(IMG1,IMG2,inlierIdx1,inlierIdx2)



end


