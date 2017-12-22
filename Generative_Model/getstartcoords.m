function [Start,u0] = getstartcoords(height,width)

% Randomly generates a starting on one of the four edges

whichside = randi(4,1); % One random number from 1 to 4

switch whichside
    case 1 %upper side
        Start = [1 ; randi([round(width/4),round(3*width/4)],1)];
        u0 = [1;0];
    case 2 %left side
        Start = [randi([round(height/4),round(3*height/4)],1) ; 1];
        u0 = [0;1];
    case 3 %bottom side
        Start = [height ; randi([round(width/4),round(3*width/4)],1)];
        u0 = [-1;0];
    case 4 %right side
        Start = [randi([round(height/4),round(3*height/4)],1) ; width];
        u0 = [0;-1];
end
end