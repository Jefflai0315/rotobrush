function ColorModels = initShapeConfidences(LocalWindows, ColorModels, WindowWidth, SigmaMin, A, fcutoff, R)
% INITSHAPECONFIDENCES Initialize shape confidences.  ShapeConfidences is a struct you should define yourself.


for i = 1: size(LocalWindows,1)
    bw = ColorModels{i}.BoundryEdge;
    D = bwdist(bw);
    fc = ColorModels{i}.ColorConfidence;
    if fcutoff < fc
        SigmaS = SigmaMin + A*(fc - fcutoff)^R;
    else
        SigmaS = SigmaMin;
    end
    Wc = exp(-(D.^2)/(SigmaS)^2);
    Fs = 1 - Wc;
    ColorModels{i}.ShapeModel = Fs;
end

end
