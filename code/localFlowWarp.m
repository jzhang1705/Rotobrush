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
end

