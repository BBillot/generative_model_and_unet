function [dist, ordInf, ordSup, absInf, absSup] = ...
    drawCircles(AxonsPatch, radius, SelectionPixel, brightness, height, width, sigma_noise_circle)

NbImages = size(AxonsPatch,3);
cross = 1;

% draw the location of a cell, look if it crosses an axon
% find if the circle is located near a border and defines parameters used
% to draw the circle.
while cross
    center=zeros(1,2);
    center(1)=randi(width); center(2)=randi(height);
    
    if (center(1)-radius>0 && center(2)-radius>0 && center(1)+radius<=width && center(2)+radius<=height) %middle
        if AxonsPatch(center(2)-radius:center(2)+radius,center(1)-radius:center(1)+radius,:)==zeros(2*radius+1,2*radius+1,NbImages)
            cross=0;
            absInf=center(1)-radius; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=center(2)+radius;
            refAbs=radius+1; refOrd=radius+1;
        end
    elseif (center(1)-radius<=0 && center(2)-radius<=0) %top left
        if AxonsPatch(1:center(2)+radius,1:center(1)+radius,:)==zeros(center(2)+radius,center(1)+radius,NbImages)
            cross=0;
            absInf=1; absSup=center(1)+radius; ordInf=1; ordSup=center(2)+radius;
            refAbs=center(1); refOrd=center(2);
        end
    elseif (center(2)+radius>width && center(1)-radius<=0) %bottom left
        if AxonsPatch(center(2)-radius:height,1:center(1)+radius,:)==zeros(radius+height-center(2)+1,center(1)+radius,NbImages)
            cross=0;
            absInf=1; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=height;
            refAbs=center(1); refOrd=radius+1;
        end
    elseif (center(2)-radius<=0 && center(1)+radius>height) %top right
        if AxonsPatch(1:center(2)+radius,center(1)-radius:width,:)==zeros(center(2)+radius,radius+width-center(1)+1,NbImages)
            cross=0;
            absInf=center(1)-radius; absSup=width; ordInf=1; ordSup=center(2)+radius;
            refAbs=radius+1; refOrd=center(2);
        end
    elseif (center(1)+radius>width && center(2)+radius>height) %bottom right
        if AxonsPatch(center(2)-radius:height,center(1)-radius:width,:)==...
                zeros(radius+height-center(2)+1,radius+width-center(1)+1,NbImages)
            cross=0;
            absInf=center(1)-radius; absSup=width; ordInf=center(2)-radius; ordSup=height;
            refAbs=radius+1; refOrd=radius+1;
        end
    elseif (center(2)-radius<=0) %top
        if AxonsPatch(1:center(2)+radius,center(1)-radius:center(1)+radius,:)==zeros(center(2)+radius,2*radius+1,NbImages)
            cross=0;
            absInf=center(1)-radius; absSup=center(1)+radius; ordInf=1; ordSup=center(2)+radius;
            refAbs=radius+1; refOrd=center(2);
        end
        
    elseif (center(2)+radius>width) % bottom
        if AxonsPatch(center(2)-radius:height,center(1)-radius:center(1)+radius,:)==zeros(radius+height-center(2)+1,2*radius+1,NbImages)
            cross=0;
            absInf=center(1)-radius; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=height;
            refAbs=radius+1; refOrd=radius+1;
        end
    elseif (center(1)-radius<=0) %left
        if AxonsPatch(center(2)-radius:center(2)+radius,1:center(1)+radius,:)==zeros(2*radius+1,center(1)+radius,NbImages)
            cross=0;
            absInf=1; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=center(2)+radius;
            refAbs=center(1); refOrd=radius+1;
        end
    elseif (center(1)+radius>height) %right
        if AxonsPatch(center(2)-radius:center(2)+radius,center(1)-radius:width,:)==zeros(2*radius+1,radius+width-center(1)+1,NbImages)
            cross=0;
            absInf=center(1)-radius; absSup=width; ordInf=center(2)-radius; ordSup=center(2)+radius;
            refAbs=radius+1; refOrd=radius+1;
        end
    end
    
end

[X,Y] = meshgrid(1:absSup-absInf+1,1:ordSup-ordInf+1);

% gets the pixel distances to the center of the cell and define points out
% the circle
dist = sqrt((X(:,:)-refAbs).^2+(Y(:,:)-refOrd).^2);
dist(dist>radius) = Inf;

% add noise to the matrix by resetting randomly picked pixel to radius dist
SelectionMatrix = randi(SelectionPixel,ordSup-ordInf+1,absSup-absInf+1);
dist(SelectionMatrix==SelectionPixel & dist<Inf) = radius;

%adds white noise to the circle
dist = dist+sigma_noise_circle*randn(ordSup-ordInf+1,absSup-absInf+1);

% sigma coefficient for VaryingIntensityWithDistance
v = sqrt(-radius^2/(2*log(0.05/brightness)));
%gets intensity out of distance
dist = VaryingIntensityWithDistance(dist,'circle','gauss',v,0,brightness); 

end