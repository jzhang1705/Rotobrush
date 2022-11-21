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
  
    % convert to gray
    I1 = rgb2gray(IMG1); 
    I2 = rgb2gray(IMG2);
    
    % find the features
    points1 = detectHarrisFeatures(I1); 
    points2 = detectHarrisFeatures(I2);
    
    % extract the neighborhood features
    [features1,valid_points1] = extractFeatures(I1,points1);
    [features2,valid_points2] = extractFeatures(I2,points2); 

    
    % match the features
    indexPairs = matchFeatures(features1,features2); 
    
    % Retrieve the locations of the corresponding points for each image.
    matchedPoints1 = valid_points1(indexPairs(:,1),:);
    matchedPoints2 = valid_points2(indexPairs(:,2),:);
    
    figure; 
    showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2);
    
    % Note: It might be a good a good idea to use metrics and find corner
    % points to avoid errors but this might not be necessary

    
    % https://www.mathworks.com/help/vision/ref/kazepoints.length.html
%     for i = 1:length(matched_points1)
%         matched_point1 = matched_points1.Location(i,:);
%         matched_point2 = matched_points2.Location(i,:);
%    
%         % Remember x and y are column and row respectively (switched)
%         if(Mask(round(matched_point1(:,2)), round(matched_point1(:,1))) == 1)
%             f_points1 = [f_points1; matched_point1];
%             f_points2 = [f_points2; matched_point2];
%             metric1 = [metric1; matched_points1.Metric(i)];
%             metric2 = [metric2; matched_points2.Metric(i)];
%         end
%     end
%     
%     updated_matched_points1 = cornerPoints(f_points1, 'Metric', metric1);
%     updated_matched_points2 = cornerPoints(f_points2, 'Metric', metric2);
    
    transform = estimateGeometricTransform(matchedPoints1, matchedPoints2, 'affine');
    
    %figure; showMatchedFeatures(img1,img2,updated_matched_points1,updated_matched_points2);
    
    WarpedMask = imwarp(Mask, transform);
    WarpedMask = imresize(WarpedMask, [size(IMG2, 1), size(IMG2, 2)]); 

    WarpedMaskOutline = bwperim(WarpedMask,4);
    WarpedFrame = imresize(imwarp(IMG1, transform), [size(IMG2, 1), size(IMG2, 2)]);    
    
    [x, y] = transformPointsForward(transform, Windows(:,1), Windows(:, 2));
    WarpedLocalWindows = [x, y];

end

