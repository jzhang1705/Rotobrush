% Each classifier inside the window Wtk consists of a local color
% model Mc, a color model confidence value fc, and a local shape
% model Ms.

function ColorModels = initColorModels(img, mask, MaskOutline, LocalWindows, BoundaryWidth, WindowWidth)
% INITIALIZAECOLORMODELS Initialize color models.  ColorModels is a struct you should define yourself.
%
% Must define a field ColorModels.Confidences: a cell array of the color confidence map for each local window.
      
    % number of local windows
    numLocalWindows = size(LocalWindows, 1);
    
    % Declare ColorModel struct
    ColorModels = struct;
    ColorModels.Confidences = cell(numLocalWindows, 1);
    ColorModels.F = cell(numLocalWindows, 1); % foreground points
    ColorModels.B = cell(numLocalWindows, 1); % background  points
    ColorModels.F_GMM = cell(numLocalWindows, 1); % foreground GMMs
    ColorModels.B_GMM = cell(numLocalWindows, 1); % background GMMs
    ColorModels.d = cell(numLocalWindows, 1); % distances
    ColorModels.p_c = cell(numLocalWindows, 1); % foreground probabilities
    
    % Gets all the spacial distances
    d = bwdist(MaskOutline);
    
    % We build GMMs for the local foreground (F) and background (B) regions, in the Lab color space.
    img = rgb2lab(img);

    % σc is fixed as half of the window size in our system. 
    sigma = WindowWidth/2;

    % GMM model is a window-level local classifier.
    for i = 1:numLocalWindows
        % Get the corners of the window

        display(LocalWindows(i,:));

        Xlower = round(LocalWindows(i,1) - WindowWidth / 2);
        Xupper = round(LocalWindows(i,1) + WindowWidth / 2);
        Ylower = round(LocalWindows(i,2) - WindowWidth / 2);
        Yupper = round(LocalWindows(i,2) + WindowWidth / 2);
        
        % To avoid possible sampling errors, 
        % we only use pixels whose spatial distance to the segmented
        % boundary is larger than a threshold (5 pixels in our system) as the
        % training data for the GMMs.
        XlowerB = Xlower + BoundaryWidth;
        XupperB = Xupper - BoundaryWidth;
        YlowerB = Ylower + BoundaryWidth;
        YupperB = Yupper - BoundaryWidth;
        

        % grab the local mask for our window
        local_mask = mask(YlowerB:YupperB, XlowerB:XupperB);

        % WINDOW
        window = img(Ylower:Yupper, Xlower:Xupper, :);

        l = window(:,:,1);
        a = window(:,:,2);
        b = window(:,:,3);

        window_vector = [];
        window_vector(:,1:3) = [l(:),a(:),b(:)];

        % TRAINING WINDOW
        window_train = img(YlowerB:YupperB, XlowerB:XupperB, :);

        l = window_train(:,:,1);
        a = window_train(:,:,2);
        b = window_train(:,:,3);

        window_train_vector = [];
        window_train_vector(:,1:3) = [l(:),a(:),b(:)];


        % apply the mask
        F = window_train_vector.*repmat(double(local_mask(:)),[1,1]);
        B = window_train_vector.*repmat(double(~local_mask(:)),[1,1]);
    

        % remove the 0 values, aka the ones not included in mask
        F(~any(F, 2), :) = [];
        B(~any(B, 2), :) = [];   
        

        % Create gmm models 
        F_GMM = fitgmdist(F, 1);
        B_GMM = fitgmdist(B, 1);
        
        
        % initialize probability map
        p_c = zeros(WindowWidth);

        % prob map for Fore and Back
        f_prob = pdf(F_GMM, window_vector);
        b_prob = pdf(B_GMM, window_vector);

        % calculate prob map
        p_c = f_prob ./ (f_prob + b_prob);

        
        % The local color model confidence fc is used to describe how separable the 
        % local foreground is against the local background using just the color model.
        % Note: The equation for fc is mentioned in the the resouces of this project:
       
        % The weighting function ωc(x) is computed as ωc(x) = exp(−d^2(x)/σc^2), 
        % where d(x) is the spatial distance between x and
        % the foreground boundary, computed using a distance transform. σc
        % is fixed as half of the window size in our system.
        
        % Gets all the spacial distanes for points in a window
        d_x = d(Ylower:Yupper, Xlower:Xupper); 
        
        % Compute the weighting function ωc(x)
        w_cx = exp((-d_x.^2)/(sigma)^2);
        
        % Calculate the local color model confidence fc
        % |L^t(x) - p_c(x)|
        p_c = reshape(p_c, [size(window, 1) size(window, 2)]);

        left = abs(MaskOutline(Ylower:Yupper,Xlower:Xupper) - p_c); 
        numerator = left.*w_cx;
        numerator = sum(numerator(:)); % Sum is the integral
        denominator = sum(w_cx(:));
        fc = 1 - numerator/denominator;
        
        % Add elements to the ColorModel struct
        ColorModels.Confidences{i} = fc;
        ColorModels.F{i} = F;
        ColorModels.B{i} = B;
        ColorModels.F_GMM{i} = F_GMM;
        ColorModels.B_GMM{i} = B_GMM;
        ColorModels.d{i} = d_x;
        ColorModels.p_c{i} = p_c;
    end
end

