function [BranchDistWithoutGap,BranchDistWithGap,BranchVariationsWithGap,BranchVariationsWithoutGap,GapSize] = PixDistanceToAxon...
    (width,height,AxonGTPointsWithoutGap,thickness,MinGapSize,MaxGapSize,variations)

NVesselCentrelinePoints = size(AxonGTPointsWithoutGap,2);
middlePoint = randi(size(AxonGTPointsWithoutGap,2)); % picks the gap middle point
GapSize = randi([MinGapSize,MaxGapSize]);
Case = 0;
indicesGapPoints = [];
BranchDistWithoutGap = Inf*ones(width,height);  % Create a vessel dist with "inf"
BranchVariationsWithoutGap = Inf(width,height);
[X,Y] = meshgrid(1:width,1:height);


if GapSize>0
    Case = 1;
    if middlePoint>GapSize && middlePoint<NVesselCentrelinePoints-GapSize
        %gap in the middle
        indicesGapPoints = middlePoint-GapSize:middlePoint+GapSize;
    elseif middlePoint<=GapSize
        %the axon starts by a gap
        indicesGapPoints = 1:middlePoint+GapSize;
    elseif middlePoint>=NVesselCentrelinePoints-GapSize
        %the axon ends by a gap
        indicesGapPoints = middlePoint-GapSize:width;
    end
end

newAxonGTPoints = AxonGTPointsWithoutGap;
newVariations = variations;
newAxonGTPoints(:,indicesGapPoints)=[];
newVariations(indicesGapPoints)=[];

for n = 1:size(newAxonGTPoints,2)
    Dist = distE(X,Y,newAxonGTPoints(:,n)); %gets distance between a GT point and all the pixels
    Indices = find(Dist<thickness); %gets the indices of the closest points
    if ~isempty(Indices)
        for i = 1:length(Indices)
            thisRow = Y(Indices(i));
            thisCol = X(Indices(i));
            a = min(BranchDistWithoutGap(thisRow,thisCol),Dist(Indices(i)));
            if a==Dist(Indices(i)) %checks if the distance if inferior to smallest distance calculated yet
                BranchDistWithoutGap(thisRow,thisCol) = a; %in the corresponding pixel value is set to that distance
                BranchVariationsWithoutGap(thisRow,thisCol) = newVariations(n); %correpsonding multiplicative coef also inserted
            end
        end
    end
end
BranchDistWithGap = BranchDistWithoutGap; %as there is no gap the two matrices are the same
BranchVariationsWithGap = BranchVariationsWithoutGap;

if Case
    %gap part
    for n=size(indicesGapPoints,2)
        Dist = distE(X,Y,AxonGTPointsWithoutGap(:,n));
        Indices = find(Dist<thickness); %gets the indices of the closest points
        if ~isempty(Indices)
            for i = 1:length(Indices)
                thisRow = Y(Indices(i));
                thisCol = X(Indices(i));
                a = min(BranchDistWithoutGap(thisRow,thisCol),Dist(Indices(i)));
                if a==Dist(Indices(i))
                    BranchDistWithoutGap(thisRow,thisCol) = a; %distance
                    BranchVariationsWithoutGap(thisRow,thisCol) = variations(n);
                end
            end
        end
    end
end

end

% newGTP = AxonsGTPoints(1:2,:); %coordinates of GTPoints
% theta=5; %rotation angle
% R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)]; %rotation matrix
% nGTP = [newGTP(1,:)-132;newGTP(2,:)-132]; %coordinates in the new system
% rot=R*nGTP; %rotated coordinates in the new system
% rot = [rot(1,:)+132;rot(2,:)+132]; %rotated coordinates