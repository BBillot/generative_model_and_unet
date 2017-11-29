function [terminalBranch,top_left,bottom_right] = getTerminalBranch(boutonInfo,sigma_spread,sigma_noise_axon)

% frame defined by GTPoint and center of bouton
top_left = [floor(min(boutonInfo{7}(1,1),boutonInfo{2}(1))),floor(min(boutonInfo{7}(2,1),boutonInfo{2}(2)))];
bottom_right = [ceil(max(boutonInfo{7}(1,1),boutonInfo{2}(1))),ceil(max(boutonInfo{7}(2,1),boutonInfo{2}(2)))];
height = bottom_right(1)-top_left(1)+1;
width = bottom_right(2)-top_left(2)+1;

%shift it to get top_left corner= [1,1]
new_gtpoint = [boutonInfo{7}(1,1)-top_left(1)+1;boutonInfo{7}(2,1)-top_left(2)+1];
new_center = [boutonInfo{2}(1)-top_left(1)+1;boutonInfo{2}(2)-top_left(2)+1];

%define intermediate points
interPoint = [1+(height-1)*rand(1);1+(width-1)*rand(1)];
middle_gt = (interPoint+new_gtpoint)/2;
middle_center = (interPoint+new_center)/2;
ControlPoints = [new_gtpoint,middle_gt,interPoint,middle_center,new_center];

%fit a spline through those points and get GTPoints 
terminalSpline = MakeAxonPoly(ControlPoints);
terminalGTPoints = getAxonsGTPoints(terminalSpline,20);

%get distance matrix
variation = boutonInfo{8}(1)*ones(1,size(terminalGTPoints,2));
thick = boutonInfo{8}(2)/2;
[terminalDist,~,~,terminalVariations,~,~,~] = PixDistanceToAxon(height,width,terminalGTPoints,thick,0,0,variation);
terminalVariations = terminalVariations + sigma_noise_axon*randn(height,width);

%convert it to intensity matrix
terminalVariations(terminalVariations==Inf) = 0;
terminalBranch = VaryingIntensityWithDistance(terminalDist,'axons','gauss',sigma_spread*0.75,terminalVariations);

end