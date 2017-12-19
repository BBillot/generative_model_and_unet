function [terminalBranch,top_left,bottom_right] = getTerminalBranch(boutonInfo,sigma_spread,sigma_noise_axon,height,width,image)

% This function draws the "link" between an axon branch and a terminal
% bouton (ie those not located on the axons). It works the same way as the
% axons were created. We generate control points, then a spline is fitted
% through those points. GT Points are then sampled from this spline. We
% calculate a distance matrix which is then converted into an intensity
% matrix (terminalBranch).

switch nargin
    
    case 5
        
    % frame defined by GTPoint and center of bouton
    top_left = boutonInfo{9}(:,1);
    bottom_right = boutonInfo{9}(:,2);
    height = boutonInfo{11}(1);
    width = boutonInfo{11}(2);

    %shift it to get top_left corner= [1,1]
    new_gtpoint = [boutonInfo{7}(1,1)-top_left(1)+1;boutonInfo{7}(2,1)-top_left(2)+1];
    new_center = [boutonInfo{2}(1)-top_left(1)+1;boutonInfo{2}(2)-top_left(2)+1];
    
    %point between gt point and bouton center
    interPoint = boutonInfo{10};
    
    case 6
    
    % frame defined by GTPoint and center of bouton
    top_left = boutonInfo{9}(:,1,image);
    bottom_right = boutonInfo{9}(:,2,image);
    height = bottom_right(1)-top_left(1)+1;
    width = bottom_right(2)-top_left(2)+1;

    %shift it to get top_left corner= [1,1]
    new_gtpoint = [boutonInfo{7}(1,1,image)-top_left(1)+1;boutonInfo{7}(2,1,image)-top_left(2)+1];
    new_center = [boutonInfo{2}(1,1,image)-top_left(1)+1;boutonInfo{2}(2,1,image)-top_left(2)+1];
    
    %point between gt point and bouton center
    interPoint = boutonInfo{10}(:,:,image);
   
end

%define intermediate points
middle_gt = (interPoint+new_gtpoint)/2;
middle_center = (interPoint+new_center)/2;
ControlPoints = [new_gtpoint,middle_gt,interPoint,middle_center,new_center];

%fit a spline through those points and get GTPoints 
terminalSpline = MakeAxonPoly(ControlPoints);
terminalGTPoints = getAxonsGTPoints(terminalSpline,20);

%get distance matrix
variation = boutonInfo{8}(1)*ones(1,size(terminalGTPoints,2));
thick = boutonInfo{8}(2)/2;
[terminalDist,terminalVariations] = PixDistanceToAxon2(height,width,terminalGTPoints,thick,variation);
terminalVariations = terminalVariations + sigma_noise_axon*randn(height,width);

%convert it to intensity matrix
terminalVariations(terminalVariations==Inf) = 0;
terminalBranch = VaryingIntensityWithDistance(terminalDist,'axons','gauss',sigma_spread*0.75,terminalVariations);

end