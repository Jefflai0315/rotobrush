function [NewLocalWindows] = localFlowWarp(WarpedPrevFrame, CurrentFrame, LocalWindows, Mask, Width)
% LOCALFLOWWARP Calculate local window movement based on optical flow between frames.

% TODO
NewLocalWindows = LocalWindows;
opticFlow = opticalFlowFarneback('NeighborhoodSize',7);
estimateFlow(opticFlow, rgb2gray(WarpedPrevFrame));
flow = estimateFlow(opticFlow, rgb2gray(CurrentFrame));
imshow(CurrentFrame)
hold on
plot(flow,'DecimationFactor',[5 5],'ScaleFactor',10);
hold off
%pause(0.5)
%% test transform forward

imshow(CurrentFrame)
hold on
for i=1:size(LocalWindows,1)    %plot the windows
    pos = LocalWindows(i,:);
    w = rectangle('Position', [pos(1) - Width/2, pos(2) - Width/2 Width Width],'EdgeColor', 'y');
    plot(pos(1), pos(2),'.','Color', 'r');
end
hold off

for i=1:size(LocalWindows,1)
    window = LocalWindows(i,:);
    X = round(window(1)-(Width/2));
    Y = round(window(2)-(Width/2));
    XX = X + Width-1;
    YY = Y + Width-1;
    if(XX >= size(CurrentFrame,2))
        XX = size(CurrentFrame,2)-1;
        X = XX -(Width)+1;   
    end
     if(X <1)
        X = 1;
        XX = Width;
    end
    if(YY >= size(CurrentFrame,1))
        YY = size(CurrentFrame,1)-1;
        Y = YY - Width+1;
    end
    if(Y < 1)
        Y = 1;
        YY = Width;
    end

    Vx = flow.Vx;
    Vy = flow.Vy; 
    Vx(Mask == 0 ) = NaN;
    Vx = Vx(Y:YY,X:XX);
    Vy(Mask == 0  ) = NaN;
    Vy = Vy(Y:YY,X:XX);
    avgVx = (mean(mean(Vx,2,'omitnan'),1,'omitnan'));
    avgVy = (mean(mean(Vy,2,'omitnan'),1,'omitnan'));

    if isnan(avgVy)
        avgVy = 0;
    end
    if isnan(avgVx)
        avgVx= 0;
    end

    NewLocalWindows(i, 1) = round(LocalWindows(i, 1) + avgVx);
    NewLocalWindows(i, 2) = round(LocalWindows(i, 2) + avgVy);
  
end


imshow(CurrentFrame)
hold on
for i=1:size(LocalWindows,1)    %plot the windows
    pos = NewLocalWindows(i,:);
    w = rectangle('Position', [pos(1) - Width/2, pos(2) - Width/2 Width Width],'EdgeColor', 'y');
    plot(pos(1), pos(2),'.','Color', 'r');
end
hold off

end

