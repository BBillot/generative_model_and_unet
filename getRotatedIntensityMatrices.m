function [rotatedCopies,rotatedSegmentations,rotatedAxonsGTPoints,height,width] = getRotatedIntensityMatrices...
    (AxonsDist,AxonsGTPoints,AxonsVariations, variations, height,width,NbImages,padding_thickness,...
    thetas,SegmentationThreshold,sigma_noise_axon,sigma_spread)

% This function returns two 3d matrices. The 1st one contains images, all
% obtained by rotating the GT Points of the previously created image (with 
% gaps along branches). The 2nd matrix contains the corresponding 
% segmentations that are also created by rotating the GT Points, this time 
% without gaps.

% preallocating rotated images and segmentations
rotatedCopies = zeros(height,width,NbImages);
rotatedSegmentations = zeros(height,width,NbImages);
rotatedAxonsGTPoints = zeros(2,size(AxonsGTPoints,2),NbImages);

%fills matrices with info from the previously generated image
AxonsVariations(AxonsVariations==Inf) = 0; % gets compatible version with VaryingIntensityWithDistance
AxonsVariations = AxonsVariations+sigma_noise_axon*randn(height,width); % adds noise to the variations
rotatedCopies(:,:,1) = VaryingIntensityWithDistance(AxonsDist,'axons','gauss',sigma_spread,AxonsVariations); % transforms distance into intensity
rotatedSegmentations(:,:,1) = (AxonsDist <SegmentationThreshold); % gets the axon segmentation
rotatedAxonsGTPoints(:,:,1) = AxonsGTPoints;


for i=2:NbImages
    
    % define rotation angle, rotation matrix, and points to rotate
    tempGTP = AxonsGTPoints; %coordinates of GTPoints without gap to rotate
    theta = thetas(i-1); %current rotation angle
    R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)]; %rotation matrix
    
    % perform rotation of GT Points without gaps
    tempGTP = [tempGTP(1,:)-height/2;tempGTP(2,:)-width/2]; %coordinates in rotation center system
    tempGTP=R*tempGTP; %rotated coordinates in the new system
    rotatedAxonsGTPoints(:,:,i) = [tempGTP(1,:)+height/2;tempGTP(2,:)+width/2];
    
    % get corresponding segmentation image without gaps
    [tempAxonsDist,tempAxonsVar] = PixDistanceToAxon(height,width,rotatedAxonsGTPoints(:,:,i),3,variations); %get distance matrix
    rotatedSegmentations(:,:,i) = (tempAxonsDist <SegmentationThreshold);
    
    % get corresponding clean image
    tempAxonsVar(tempAxonsVar==Inf) = 0;
    tempAxonsVar=tempAxonsVar+sigma_noise_axon*randn(height,width); % add noise to the axons
    rotatedCopies(:,:,i) = VaryingIntensityWithDistance(tempAxonsDist,'axons','gauss',sigma_spread,tempAxonsVar); %get intensity matrix
    
end

%get rid of the now unecessary padding introduced for the rotations
rotatedCopies = rotatedCopies(1+padding_thickness:height-padding_thickness,1+padding_thickness:width-padding_thickness,:);
rotatedSegmentations = rotatedSegmentations(1+padding_thickness:height-padding_thickness,1+padding_thickness:width-padding_thickness,:);
%update the width and heigth
height = height-2*padding_thickness;
width = width-2*padding_thickness;
%updates the rotatedAxonsGTPoints
rotatedAxonsGTPoints = rotatedAxonsGTPoints-padding_thickness;

end