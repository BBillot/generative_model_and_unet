function [BranchDist,BranchVariations]= PixDistanceToAxon(height,width,AxonGTPoints,thickness,variations)

% If this function is used to draw several branches, where the gaps have
% already been defined, set both Min/MaxGapSize to 0.

BranchDist = Inf*ones(height,width);            % Create a distance matrix initialised with "inf"
BranchVariations = Inf(height,width);           % Create a variation matrix initialised with "Inf"

%loop over the gt points out of the gap
for n = 1:size(AxonGTPoints,2)
    if AxonGTPoints(1,n)>0 && AxonGTPoints(1,n)<=height && AxonGTPoints(2,n)>0 && AxonGTPoints(2,n)<=width
        [Y,X] = meshgrid(max(1,floor(AxonGTPoints(2,n)-thickness)):min(width,ceil(AxonGTPoints(2,n)+thickness)),...
                         max(1,floor(AxonGTPoints(1,n)-thickness)):min(height,ceil(AxonGTPoints(1,n)+thickness)));
        Dist = distE(X,Y,AxonGTPoints(:,n)); %gets distance between a GT point and all the pixels

        for i = 1:length(Dist)
            thisRow = X(i);
            thisCol = Y(i);
            a = min(BranchDist(thisRow,thisCol),Dist(i));
            if a==Dist(i) %checks if the distance if inferior to smallest distance calculated yet
                BranchDist(thisRow,thisCol) = a; %in the corresponding pixel value is set to that distance
                BranchVariations(thisRow,thisCol) = variations(n); %correpsonding multiplicative coef also inserted
            end
        end
    end

end

end