% curr = prev+1;
% calculateGlobalAffine(images{prev}, images{curr}, mask, LocalWindows);

% We want the features of I'_{t+1}
function [WarpedFrame, WarpedMask, WarpedMaskOutline, WarpedLocalWindows] = calculateGlobalAffine(IMG1,IMG2,Mask,Windows)
% CALCULATEGLOBALAFFINE: finds affine transform between two frames, and applies it to frame1, the mask, and local windows.
    
    % https://www.mathworks.com/help/vision/ref/estimategeometrictransform.html
    % The link above proves to be rather useful in regards to the formating
    % of what needs to be done


    % Our motion estimation operates in a hierarchical fashion. From
    % two successive frames I_t and I_{t+1}, we first estimate a global affine
    % transform from matching SIFT feature points, [Lowe 2004], between the two frames 
    % (only SIFT features inside the foreground
    % object in I_t are used for matching), and use this transform to align
    % I_t to I_{t+1}, resulting in a new image I'_{t+1}
  
    prev = rgb2gray(IMG1); % mxn 2D matrix
    curr = rgb2gray(IMG2);
    
    % We are using SIFT instead of SURF, this is a difference
    % between what is mentioned in the link above vs what we are doing
   
    % points = detectSIFTFeatures(I) detects SIFT features in the 2-D grayscale input image I and returns 
    % a SIFTPoints object. The detectSIFTFeatures function implements the Scale-Invariant Feature Transform (SIFT) 
    % algorithm to find local features in an image.
    
    prevPts = detectSIFTFeatures(prev); % SIFTPoints object (contains properties)
    currPts = detectSIFTFeatures(curr); % https://www.mathworks.com/help/vision/ref/siftpoints.html
    
    [featuresPrev,validPtsPrev] = extractFeatures(prev,prevPts); % features is an mxn binary matrix
    [featuresCurr,validPtsCurr] = extractFeatures(curr,currPts); % validPoints is an mx2 matrix of [x,y] coordinates
    
    % https://www.mathworks.com/help/vision/ref/matchfeatures.html
    index_pairs = matchFeatures(featuresPrev,featuresCurr); % index_pairs is a Px2 matrix
    
    % The logic of this is evident once you look at the Output Arguments 
    % section in the link for matchfeatures
    % Please check if this will cause an error
    
    % matchedPtsPrev = validPtsPrev(index_pairs(:,1)); % mx2 matrix of [x,y] coordinates
    % matchedPtsCurr = validPtsCurr(index_pairs(:,2));
    matchedPtsPrev = validPtsPrev(index_pairs(:,1), :); % mx2 matrix of [x,y] coordinates
    matchedPtsCurr = validPtsCurr(index_pairs(:,2), :);
    
    % Only SIFT features inside the foreground object in I_t are used for matching
    % Thus we must isolate the foreground of I_t (IMG1)
    
    % Note: It might be a good a good idea to use metrics and find corner
    % points to avoid errors but this might not be necessary
    
    F_img1 = []; % foreground of IMG1 
    matched_F = []; % matched points of the foregound for IMG1   
    
    % https://www.mathworks.com/help/vision/ref/kazepoints.length.html
    for i = 1:length(matchedPtsPrev)
        point1 = matchedPtsPrev(i,:);
        point2 = matchedPtsCurr(i,:);
   
        % Remember x and y are column and row respectively (switched)
        if(Mask(round(point1(:,2)), round(point1(:,1))) == 1)
            F_img1 = [F_img1; point1];
            matched_F = [matched_F; point2];
        end
    end
    
    % Get the transform
    tform = estimateGeometricTransform(matched_F,F_img1,'affine');
    
    % Declare the parameters (returns)
    % Based from initLocalWindows.m way of implementing similar features
    % I'_{t+1} is the "Warped" 
    WarpedMask = imwarp(Mask, tform);
    WarpedMask = imresize(WarpedMask, [size(IMG2, 1), size(IMG2, 2)]); 
    WarpedMaskOutline = bwperim(WarpedMask,4);
    WarpedFrame = imresize(imwarp(IMG1, tform), [size(IMG2, 1), size(IMG2, 2)]);    
    WarpedLocalWindows = transformPointsForward(tform, Windows(:,1), Windows(:, 2));
end

