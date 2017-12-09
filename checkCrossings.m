function [cross]=checkCrossings(AxonsDistWithoutGap,BranchDistWithoutGap,threshold,newStart)

% Checks that the new branch doesn't cross existing axons.
% We are forced to consider the case where a branch starts from another
% branch. Obviously the new branch crosses its mother branch. So we
% tolerate crossings in the vicinity of the branching point. Otherwise (if
% crossing occurs far from the branching point), it probably
% means the new branch crosses another branch.

cross = 1;
[row,col]=find(AxonsDistWithoutGap~=Inf & BranchDistWithoutGap~=Inf); %finds the pixels belonging to both branches

if isempty(row)
    cross=0;
else
    lIndices = length(row); %numbers of pixels common to both branches
    l = 1; %initialization
    while cross
        thisRow = row(l); thisCol = col(l);
        distToStartControlPoint = sqrt((newStart(1)-thisCol)^2+(newStart(2)-thisRow)^2); % distance to branching point
        if distToStartControlPoint>threshold
            break %two different branch cross,
        elseif l==lIndices
            cross=0; %if all the points are close enough then we consider that there is no crossing
        else
            l = l+1;
        end
    end
    
end

end