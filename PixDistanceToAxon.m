function [BranchDistWithoutGap,BranchDistWithGap,BranchVariationsWithGap,BranchVariationsWithoutGap,GapSize,...
    newAxonGTPoints,newVariations]= PixDistanceToAxon(width,height,AxonGTPointsWithoutGap,thickness,MinGapSize,MaxGapSize,variations)

% If this function is used to draw several branches, where the gaps have
% already been defined, set both Min/MaxGapSize to 0.

NVesselCentrelinePoints = size(AxonGTPointsWithoutGap,2); % Number of GTPoints
BranchDistWithoutGap = Inf*ones(width,height);            % Create a distance matrix initialised with "inf"
BranchVariationsWithoutGap = Inf(width,height);           % Create a variation matrix initialised with "Inf"
[X,Y] = meshgrid(1:width,1:height);                       % Meshgrid matrices
middlePoint = randi(size(AxonGTPointsWithoutGap,2));      % Randomly pick a gap middle point
GapSize = randi([MinGapSize,MaxGapSize]);                 % Randomly select a size for this gap
indicesGapPoints = [];                                    % Contains the indices of the gap GTPoints ton be removed
Case = 0;                                                 % No gap

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
        indicesGapPoints = middlePoint-GapSize:NVesselCentrelinePoints;
    end
end

newAxonGTPoints = AxonGTPointsWithoutGap;
newVariations = variations;
newAxonGTPoints(:,indicesGapPoints)=[];
newVariations(indicesGapPoints)=[];
for n = 1:size(newAxonGTPoints,2)
    if newAxonGTPoints(1,n)>1 && newAxonGTPoints(1,n)<=width && newAxonGTPoints(2,n)>1 && newAxonGTPoints(2,n)<=height
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