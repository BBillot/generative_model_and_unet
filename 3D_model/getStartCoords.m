function [Start,u] = getStartCoords(height,width,depth,crossingOK,AxonsDist)

% Randomly generates a starting point on one of the faces of the cube. This
% function also checks if necessary if the created point overlaps with a
% previously created axon.

if crossingOK % if axons can cross we just get the starting point
    [Start,u] = getSingleStartCoords(height,width,depth);%randomly select the starting point
else % if they can't then we need to check if the starting point is not on an existing branch
    startOK = 0;
    while startOK==0
        [Start,u] = getSingleStartCoords(height,width,depth);%randomly select the starting point
        if AxonsDist(Start(1),Start(2))==Inf %checks if it belongs to an existing branch
            startOK = 1;
        end
    end
end

end

function [Start,u0] = getSingleStartCoords(height,width,depth)

% Randomly generates a starting on one of the faces of the cube. However
% this can't start on one the the z-axis faces, to prevent obtaining axons
% that look like dots in the z-axis maximum projections.

whichside = randi(4,1); % One random number from 1 to 4

switch whichside
    case 1 %upper side
        Start = [1; randi([round(width/4),round(3*width/4)],1); randi([round(depth/4),round(3*depth/4)],1)];
        u0 = [1;0;0];
    case 2 %left side
        Start = [randi([round(height/4),round(3*height/4)],1); 1; randi([round(depth/4),round(3*depth/4)],1)];
        u0 = [0;1;0];
    case 3 %bottom
        Start = [height ; randi([round(width/4),round(3*width/4)],1); randi([round(depth/4),round(3*depth/4)],1)];
        u0 = [-1;0;0];
    case 4 %rigth side
        Start = [randi([round(height/4),round(3*height/4)],1); width; randi([round(depth/4),round(3*depth/4)],1)];
        u0 = [0;-1;0];
end

end