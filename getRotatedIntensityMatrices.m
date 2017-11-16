function [rotatedCopies,rotatedSegmentations,rotatedAxonsGTPoints,width,height] = getRotatedIntensityMatrices...
    (AxonsDistWithoutGap,AxonsDistWithGap,AxonsGTPoints,AxonsGTPointsWithGap,AxonsVariations, variationsWithoutGap, ...
    variationsWithGap, width,height,NbImages,padding_thickness,thetas,SegmentationThreshold,sigma_noise_axon,sigma_spread)

% This function returns two 3d matrices. The 1st one contains images, all
% obtained by rotating the GT Points of the previously created image (with 
% gaps along branches). The 2nd matrix contains the corresponding 
% segmentations that are also created by rotating the GT Points, this time 
% without gaps.

% preallocating rotated images and segmentations
rotatedCopies = zeros(width,height,NbImages);
rotatedSegmentations = zeros(width,height,NbImages);
rotatedAxonsGTPoints = zeros(2,size(AxonsGTPointsWithGap,2),NbImages);

%fills matrices with info from the previously generated image
AxonsVariations(AxonsVariations==Inf) = 0; % gets compatible version with VaryingIntensityWithDistance
AxonsVariations = AxonsVariations+sigma_noise_axon*randn(width,height); % adds noise to the variations
rotatedCopies(:,:,1) = VaryingIntensityWithDistance(AxonsDistWithGap,'axons','gauss',sigma_spread,AxonsVariations); % transforms distance into intensity
rotatedSegmentations(:,:,1) = (AxonsDistWithoutGap <SegmentationThreshold); % gets the axon segmentation
rotatedAxonsGTPoints(:,:,1) = AxonsGTPointsWithGap;

for i=2:NbImages
    
    % define rotation angle, rotation matrix, and points to rotate
    tempGTPWithoutGap = AxonsGTPoints; %coordinates of GTPoints without gap to rotate
    tempGTPWithGap = AxonsGTPointsWithGap; %coordinates of GTPoints to rotate
    theta = thetas(i-1); %current rotation angle
    R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)]; %rotation matrix
    
    % perform rotation of GT Points without gaps
    tempGTPWithoutGap = [tempGTPWithoutGap(1,:)-width/2;tempGTPWithoutGap(2,:)-height/2]; %coordinates in rotation center system
    tempGTPWithoutGap=R*tempGTPWithoutGap; %rotated coordinates in the new system
    tempGTPWithoutGap = [tempGTPWithoutGap(1,:)+width/2;tempGTPWithoutGap(2,:)+height/2];
    
    % perform rotation of GT Points with gaps
    tempGTPWithGap = [tempGTPWithGap(1,:)-width/2;tempGTPWithGap(2,:)-height/2]; %coordinates in rotation center system
    tempGTPWithGap=R*tempGTPWithGap; %rotated coordinates in the new system
    rotatedAxonsGTPoints(:,:,i) = [tempGTPWithGap(1,:)+width/2;tempGTPWithGap(2,:)+height/2]; %rotated coordinates in the original system
    
    % get corresponding clean image with gaps
    [tempRotatedPatch,~,~,rotatedPatchVar,~,~,~] = PixDistanceToAxon(width,height,rotatedAxonsGTPoints(:,:,i),3,0,0,variationsWithGap); %get distance matrix
    rotatedPatchVar(rotatedPatchVar==Inf) = 0;
    rotatedPatchVar=rotatedPatchVar+sigma_noise_axon*randn(width,height); % add noise to the axons
    rotatedCopies(:,:,i) = VaryingIntensityWithDistance(tempRotatedPatch,'axons','gauss',sigma_spread,rotatedPatchVar); %get intensity matrix
    
    % get corresponding segmentation image without gaps
    [tempAxonsDistWithoutGap,~,~,~,~,~,~] = PixDistanceToAxon(width,height,tempGTPWithoutGap,3,0,0,variationsWithoutGap); %get distance matrix
    rotatedSegmentations(:,:,i) = (tempAxonsDistWithoutGap <SegmentationThreshold);
    
end

%get rid of the now unecessary padding introduced for the rotations
rotatedCopies = rotatedCopies(1+padding_thickness:width-padding_thickness,1+padding_thickness:height-padding_thickness,:);
rotatedSegmentations = rotatedSegmentations(1+padding_thickness:width-padding_thickness,1+padding_thickness:height-padding_thickness,:);
%update the width and heigth
width = width-2*padding_thickness;
height = height-2*padding_thickness;
%updates the rotatedAxonsGTPoints
rotatedAxonsGTPoints = rotatedAxonsGTPoints-padding_thickness;

end