function [dist, ordInf, ordSup, absInf, absSup] = ...
    drawCells(AxonsPatch, radius, SelectionPixel, brightness, height, width, sigma_noise_circle)

NbImages = size(AxonsPatch,3);
cross = 1;
NSources = 4;

rad = radius+ceil(radius/2);

% draw the location of a cell, look if it crosses an axon
% find if the circle is located near a border and defines parameters used
% to draw the circle.
while cross
    center=zeros(1,2);
    center(1)=randi(width); center(2)=randi(height);
    
    if (center(1)-rad>0 && center(2)-rad>0 && center(1)+rad<=width && center(2)+rad<=height) %middle
        if AxonsPatch(center(2)-rad:center(2)+rad,center(1)-rad:center(1)+rad,:)==zeros(2*rad+1,2*rad+1,NbImages)
            cross=0;
            absInf=center(1)-rad; absSup=center(1)+rad; ordInf=center(2)-rad; ordSup=center(2)+rad;
            refAbs=rad+1; refOrd=rad+1;
        end
    elseif (center(1)-rad<=0 && center(2)-rad<=0) %top left
        if AxonsPatch(1:center(2)+rad,1:center(1)+rad,:)==zeros(center(2)+rad,center(1)+rad,NbImages)
            cross=0;
            absInf=1; absSup=center(1)+rad; ordInf=1; ordSup=center(2)+rad;
            refAbs=center(1); refOrd=center(2);
        end
    elseif (center(2)+rad>width && center(1)-rad<=0) %bottom left
        if AxonsPatch(center(2)-rad:height,1:center(1)+rad,:)==zeros(rad+height-center(2)+1,center(1)+rad,NbImages)
            cross=0;
            absInf=1; absSup=center(1)+rad; ordInf=center(2)-rad; ordSup=height;
            refAbs=center(1); refOrd=rad+1;
        end
    elseif (center(2)-rad<=0 && center(1)+rad>height) %top right
        if AxonsPatch(1:center(2)+rad,center(1)-rad:width,:)==zeros(center(2)+rad,rad+width-center(1)+1,NbImages)
            cross=0;
            absInf=center(1)-rad; absSup=width; ordInf=1; ordSup=center(2)+rad;
            refAbs=rad+1; refOrd=center(2);
        end
    elseif (center(1)+rad>width && center(2)+rad>height) %bottom right
        if AxonsPatch(center(2)-rad:height,center(1)-rad:width,:)==...
                zeros(rad+height-center(2)+1,rad+width-center(1)+1,NbImages)
            cross=0;
            absInf=center(1)-rad; absSup=width; ordInf=center(2)-rad; ordSup=height;
            refAbs=rad+1; refOrd=rad+1;
        end
    elseif (center(2)-rad<=0) %top
        if AxonsPatch(1:center(2)+rad,center(1)-rad:center(1)+rad,:)==zeros(center(2)+rad,2*rad+1,NbImages)
            cross=0;
            absInf=center(1)-rad; absSup=center(1)+rad; ordInf=1; ordSup=center(2)+rad;
            refAbs=rad+1; refOrd=center(2);
        end
        
    elseif (center(2)+rad>width) % bottom
        if AxonsPatch(center(2)-rad:height,center(1)-rad:center(1)+rad,:)==zeros(rad+height-center(2)+1,2*rad+1,NbImages)
            cross=0;
            absInf=center(1)-rad; absSup=center(1)+rad; ordInf=center(2)-rad; ordSup=height;
            refAbs=rad+1; refOrd=rad+1;
        end
    elseif (center(1)-rad<=0) %left
        if AxonsPatch(center(2)-rad:center(2)+rad,1:center(1)+rad,:)==zeros(2*rad+1,center(1)+rad,NbImages)
            cross=0;
            absInf=1; absSup=center(1)+rad; ordInf=center(2)-rad; ordSup=center(2)+rad;
            refAbs=center(1); refOrd=rad+1;
        end
    elseif (center(1)+rad>height) %right
        if AxonsPatch(center(2)-rad:center(2)+rad,center(1)-rad:width,:)==zeros(2*rad+1,rad+width-center(1)+1,NbImages)
            cross=0;
            absInf=center(1)-rad; absSup=width; ordInf=center(2)-rad; ordSup=center(2)+rad;
            refAbs=rad+1; refOrd=rad+1;
        end
    end
    
end

[X,Y] = meshgrid(1:absSup-absInf+1,1:ordSup-ordInf+1);

%get all the noise sources
refAbs=[refAbs, refAbs+randi([-ceil(radius/2)+1,ceil(radius/2)-1],1,NSources-1)]; 
refOrd=[refOrd, refOrd+randi([-ceil(radius/2)+1,ceil(radius/2)-1],1,NSources-1)];

% sigma to make gaussian profile reach 5% of its peak at the radius
v = sqrt(-radius^2/(2*log(0.05/brightness)));

% gets the pixel distances to the center of the cell and define points out
% the circle
dist=Inf*ones(ordSup-ordInf+1,absSup-absInf+1);
for i=1:NSources
    dist = min(dist,sqrt((X(:,:)-refAbs(i)).^2+(Y(:,:)-refOrd(i)).^2));
end
dist(dist>radius) = Inf;

%convolve the obtained matrix with gaussian mask, to deform the image
MaskSize = ceil(radius*0.9);
g2 = fspecial('gaussian',MaskSize,v);
dist = conv2(dist,g2,'same');

% add noise to the matrix by resetting randomly picked pixel to radius dist
SelectionMatrix = randi(SelectionPixel,ordSup-ordInf+1,absSup-absInf+1);
dist(SelectionMatrix==SelectionPixel & dist<Inf) = radius;

%adds white noise to the circle
dist = dist+sigma_noise_circle*randn(ordSup-ordInf+1,absSup-absInf+1);

%gets intensity out of distance
dist = VaryingIntensityWithDistance(dist,'circle','gauss',v,0,brightness); 

end