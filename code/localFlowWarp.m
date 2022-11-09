function [NewLocalWindows] = localFlowWarp(WarpedPrevFrame, CurrentFrame, LocalWindows, Mask, Width)
% LOCALFLOWWARP Calculate local window movement based on optical flow between frames.

% TODO
NewLocalWindows = LocalWindows;
opticFlow = opticalFlowFarneback();
flow = estimateFlow(opticFlow, rgb2gray(WarpedPrevFrame));
flow = estimateFlow(opticFlow, rgb2gray(CurrentFrame));


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
    XX = X + Width;
    YY = Y + Width;
    if(XX >= size(CurrentFrame,2))
        XX = size(CurrentFrame,2);
        X = XX -(Width);
       
    end
    
    if(YY >= size(CurrentFrame,1))
    YY = size(CurrentFrame,1);
    Y = YY - Width;
    end
   
    Vx = flow.Vx;
    Vy = flow.Vy; 
    Vx(Mask == 0) = NaN;
    Vx = Vx(Y:YY,X:XX);
    Vy(Mask == 0) = NaN;
    Vy = Vy(Y:YY,X:XX);
    
   
    %avg_Vx = ceil(sum(sum(Vx)));
    %avg_Vy = ceil(sum(sum(Vy)));
    avg_Vx = (mean(mean(Vx,2,'omitnan'),1,'omitnan'));
    avg_Vy = (mean(mean(Vy,2,'omitnan'),1,'omitnan'));
    if(isnan(avg_Vx))
        avg_Vx = 0;
    end
    if(isnan(avg_Vy))
        avg_Vy = 0;
    end
    sprintf(['avg' num2str(i) 'is: ' num2str(avg_Vy)])
    
    window = [(window(1) + avg_Vx), ...
        (window(2) + avg_Vy)]; 
    NewLocalWindows(i,:) = window;
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

