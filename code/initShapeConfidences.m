% ShapeConfidences = ...
%   initShapeConfidences(LocalWindows,ColorModels,...
%   WindowWidth, SigmaMin, A, fcutoff, R);

function ShapeConfidences = initShapeConfidences(LocalWindows, ColorModels, WindowWidth, SigmaMin, A, fcutoff, R)
% INITSHAPECONFIDENCES Initialize shape confidences.  ShapeConfidences is a struct you should define yourself.
    
    % Section 2.4 of the research paper. 
    % Might not be complete since WindowWidth is not used
    numLocalWindows = size(LocalWindows, 1);
    ShapeConfidences = struct;
    ShapeConfidences.Confidences = cell(numLocalWindows);
    
    for i = 1:numLocalWindows
        if (ColorModels.Confidences{i} > fcutoff)
            sigma_s = SigmaMin + A*(ColorModel.Confidences{i} - fcutoff).^R;
        else
            sigma_s = SigmaMin;
        end
        ShapeConfidences.Confidences{i} = 1 - exp(-ColorModels.d{i}.^2 / sigma_s^2);
    end
    
end
