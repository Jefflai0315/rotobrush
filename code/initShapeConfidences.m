function ShapeConfidences = initShapeConfidences(LocalWindows, ColorModels, WindowWidth, SigmaMin, A, fcutoff, R)
% INITSHAPECONFIDENCES Initialize shape confidences.  ShapeConfidences is a struct you should define yourself.
ShapeConfidences = {}

for i = 1: size(LocalWindows,1)
    fs = [];
    bw = ColorModels{i}.BoundryEdge;
    d = bwdist(bw);
    fc = ColorModels{i}.Confidence;
    xcounter = 1;
        
    % Used -1 in loop to exclude 41st, not 100% sure if correctly done
    for x=LocalWindows(i,1)-(WindowWidth/2):LocalWindows(i,1)+(WindowWidth/2-1)
        ycounter = 1;
        for y=LocalWindows(i,2)-(WindowWidth/2):LocalWindows(i,2)+(WindowWidth/2-1)
            if fcutoff < fc
                SigmaS = SigmaMin + A*(fc - fcutoff)^R;
            else
                SigmaS = SigmaMin;
            end
            
            fs(ycounter,xcounter) = 1 - exp(-(d(ycounter,xcounter))^2/SigmaS^2);
            
            ycounter = ycounter + 1;
        end
        xcounter = xcounter + 1;
    
    end
    ShapeConfidences{i} = fs;
end

end
