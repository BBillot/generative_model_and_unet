function [BranchDist,BranchVariations]= PixDistanceToAxon2(height,width,AxonGTPoints,thickness,variations)

% If this function is used to draw several branches, where the gaps have
% already been defined, set both Min/MaxGapSize to 0.

[X,Y] = meshgrid(1:height,1:width);             % Meshgrid matrices

mx = max(height+1,width+1);
variations(AxonGTPoints(1,:)<1 |AxonGTPoints(2,:)<1 | AxonGTPoints(1,:)>height |AxonGTPoints(2,:)>width) = [];
AxonGTPoints(:,any(AxonGTPoints<1)) = mx;
AxonGTPoints(:,AxonGTPoints(1,:) > height | AxonGTPoints(2,:)> width) = [];
tic
BranchDist=sqrt(( repmat(Y(:),[1,size(AxonGTPoints,2)]) - repmat(AxonGTPoints(1,:), [size(X(:),1),1]) ).^2 + ...
    (repmat(X(:),[1,size(AxonGTPoints,2)]) - repmat(AxonGTPoints(2,:), [size(X(:),1),1]) ).^2);
toc
[BranchDist,BranchVariations] = min(BranchDist,[],2);
BranchDist(BranchDist>thickness) = Inf;

BranchDist = reshape(BranchDist,[height,width]);
BranchVariations = reshape(BranchVariations, [height,width]);
toc
for i=1:height
    for j=1:width
        if BranchDist(i,j)<Inf
            BranchVariations(i,j) = variations(BranchVariations(i,j));
        else
            BranchVariations(i,j) = Inf;
        end
    end
end

end