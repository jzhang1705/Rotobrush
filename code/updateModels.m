function [mask, LocalWindows, ColorModels, ShapeConfidences] = ...
    updateModels(...
        NewLocalWindows, ...   % W^{t+1}_k
        LocalWindows, ...      % W^t_k
        CurrentFrame, ...      % I_{t+1} images{curr}
        warpedMask, ...        
        warpedMaskOutline, ... %  
        WindowWidth, ...       % Between 30 to 80
        ColorModels, ...      % Color model M_c
        ShapeConfidences, ... % Shape model M_s
        ProbMaskThreshold, ...
        fcutoff, ...
        SigmaMin, ...
        R, ...
        A ...
    )
% UPDATEMODELS: update shape and color models, and apply the result to generate a new mask.
% Feel free to redefine this as several different functions if you prefer.
    

    IMG = rgb2lab(CurrentFrame); % recommended to use lab
    
    d = bwdist(warpedMaskOutline);       
    
    
    numLocalWindows = size(NewLocalWindows, 1);
    
    k = 3;
    TsF = 0.75;
    TsB = 0.25;
    sigma_c = WindowWidth/2;
    
    for i = 1:numLocalWindows
        %lowerX = round(LocalWindows(i,1) - sigma_c);
        %upperX = round(LocalWindows(i,1) + sigma_c);
        %lowerY = round(LocalWindows(i,2) - sigma_c);
        %upperY = round(LocalWindows(i,2) + sigma_c); 
        
        lowerX = round(newLocalWindows(i,1) - sigma_c);
        upperX = round(newLocalWindows(i,1) + sigma_c);
        lowerY = round(newLocalWindows(i,2) - sigma_c);
        upperY = round(newLocalWindows(i,2) + sigma_c); 
        
        
        % The shape model is composed of the foreground mask and the shape confidence map. 
        % These are both carried over from the previous frame.
        
        d_x = d(lowerY:upperY, lowerX:upperX);
        ShapeConfidences.Confidences{i} = 1 - exp(-d_x.^2 / SigmaMin^2);
        
        % Updating the color model Mc is essential for achieving good segmentation
        % Since the foreground and the background usually have
        % different motions, new background colors may appear in the local
        % region (window). To update the color model, we build a new foreground
        % G^{T+1}_F by sampling all pixels in the warped window
        % whose foreground confidence computed from the updated shape
        % model is greater than a high threshold T^s_F (0.75) (f_s(x) = 1 - exp(-d^2(x)/sigma_s^2)
        % A new background GMM G^{T+1}_B is constructed in a similar way using a
        % low threshold T^s_B (0.25).
        
        % https://www.mathworks.com/help/matlab/ref/find.html
        F_indices = find(ShapeConfidences.Confidences{i} > TsF); % Gets the indices
        B_indices = find(ShapeConfidences.Confidences{i} < TsB);
        
        % Get the actual pixel values (might not be correct at all)
        F_new = img(F_indices,:);
        B_new = img(B_indices,:);
        
        F_GMM_new = fitgmdist(F_new, k);
        B_GMM_new = fitgmdist(B_new, k);
        
        % Paragraph 3 of section 2.3 (research) 
        
        % Mcu = struct;
        % Mcu.GtF = ColorModels.F_GMM{i};
        % Mcu.GtB = ColorModels.B_GMM{i};
        
        % Mch = struct;
        % Mch.GtF = ColorModels.F_GMM{i};
        % Mch.Gt1F = F_GMM_new;
        % Mch.GtB = ColorModels.B_GMM{i};
        % Mch.Gt1B = F_GMM_new;
        
        % Paragraph 4-5 of section 2.3 (research) 
        pcu =  ColorModels.p_c{i};
        
        % Get pch 
        % First we need to combine the 2 GMMs
        F_GMM_combined = fitgmdist([F_new; ColorModels.F],6); % Could be either 6 or 2 idk
        B_GMM_combined = fitgmdist([B_new; ColorModels.B],6);
        
        p_c = ColorModels.p_c{i};
        pcu = zeros(WindowWidth, WindowWidth);
        numForegroundUnits = 0;
        
        
        % Count foregound pixels
        c = 1; % column index
        for j = lowerX:upperX
            r = 1; %row index
            for k = lowerY:upperY
                if (Mask(k,j) == 1 && MaskOutline(k,j) == 0)
                    numForegroundUnits = numForegroundUnits  + 1;
                end
                pcxF = pdf(F_GMM_combined, [IMG(k,j,1), IMG(k,j,2), IMG(k,j,3)]);
                pcxB = pdf(B_GMM_combined , [IMG(k,j,1), IMG(k,j,2), IMG(k,j,3)]);
                pcu(r,c) = pcxF/(pcxF + pcxB); %(r,c) is x
                r = r + 1;
            end
            c = c + 1;
        end
        
        % The number of pixels is incorrect because the way we collected it
        % in initColorModels.m doesn't use the boundary
        if(numForegroundUnits > size(ColorModels.F{i},1))
            % need to recompute fc since we chose the updated model
            w_cx = exp((-d_x.^2)/(sigma_c)^2);
            left = abs(warpedMaskOutline(lowerY:upperY,lowerX:upperX) - pch); 
            numerator = left.*w_cx;
            numerator = sum(numerator(:)); % Sum is the integral
            denominator = sum(w_cx(:));
            fc = 1 - numerator/denominator;
            ColorModels.Confidences{i} = fc;
            
            p_c = pcu;
        end
        
        
       % Updating the Color Model (Section 2.4 research, 6 project
       % description)
        if (ColorModels.Confidences{i} > fcutoff)
            sigma_s = SigmaMin + A*(ColorConfidences.Confidences{i} - fcutoff).^R;
        else
            sigma_s = SigmaMin;
        end
        
        ShapeConfidences.Confidences{i} = 1 - exp(-ColorConfidences.d{i}.^2 / sigma_s^2);
        
        % Calulate pkf
        pkf = ShapeConfidences.Confidences{i}.*warpedMask + (1 - ShapeConfidences.Confidences{i}).*p_c;
        ColorModels.p_c{i} = pkf;
    end
    
    e = 0.1;
    
    pf = [height, width] = size(image);
    for i = 
       
end

