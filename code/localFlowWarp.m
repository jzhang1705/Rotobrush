% localFlowWarp(warpedFrame, images{curr}, warpedLocalWindows,warpedMask,WindowWidth);

function [NewLocalWindows] = localFlowWarp(WarpedPrevFrame, CurrentFrame, LocalWindows, Mask, Width)
% LOCALFLOWWARP Calculate local window movement based on optical flow between frames.

% TODO

    % In the second step, optical flow is estimated between I'_{t+1} and I_{t+1},
    % in order to capture the local deformations of the object. 
    % In our case, we are only interested in flow vectors for pixels inside the object in
    % I'_{t+1}. It is well known that optical flow is unreliable, especially near
    % boundaries where occlusions occur, thus in our system we use a local flow
    % averaging approach which generates significantly more robust results.
    
    %% Calculate local window non-rigid (object) movement based on optical flow
    % between 2 frames: frame1’ (moved by global affine) & frame2 (current frame)
    % https://www.mathworks.com/help/vision/ref/opticalflowhs.html
    % https://www.mathworks.com/help/vision/ref/opticalflowhs.estimateflow.html
    
    % Based on the links above, we see that the opticalFlowHS
    % object is dynamic and changes after each use of estimateflow. 
    opticFlow = opticalFlowHS;
    
    frameGray1 = im2gray(WarpedPrevFrame); % Need to convert to grayscale images
    frameGray2 = im2gray(CurrentFrame); 
    
    % https://www.mathworks.com/help/vision/ref/opticalflowobject.html
    % estimateFlow returns an optical flow object
    flow = estimateFlow(opticFlow,frameGray1); % remember opticFlow is dynamic
    flow = estimateFlow(opticFlow,frameGray2);
    
    %% Find the average of the flow vectors inside the object’s bounds and local
    % windows bound, use (the average of) that to re-center windows.
    
    % There are x components and y components for velocity which are the
    % flow vectors
    
    sigma_c = Width/2;
    NewLocalWindows = LocalWindows;
    numLocalWindows = size(NewLocalWindows, 1);
    for i = 1:numLocalWindows
        
        % Get the corners of the window
        lowerX = round(LocalWindows(i,1) - sigma_c);
        upperX = round(LocalWindows(i,1) + sigma_c);
        lowerY = round(LocalWindows(i,2) - sigma_c);
        upperY = round(LocalWindows(i,2) + sigma_c); 
        
        changeX = 0;
        changeY = 0;
        
        for j = lowerX:upperX
           for k = lowerY:upperY
               if (Mask(k,j) == 1)
                   changeX = changeX + flow.Vx(k,j);
                   changeY = changeY + flow.Vy(k,j);
               end
           end
        end
        
        % Change/Area
        averageChangeX = changeX / (Width^2);
        averageChangeY = changeY / (Width^2);
        
        newX = round(LocalWindows(i,1) + averageChangeX);
        newY = round(LocalWindows(i,2) + averageChangeY);
        
        NewLocalWindows(i, 1) = newX;
        NewLocalWindows(i, 2) = newY;

    end
end

