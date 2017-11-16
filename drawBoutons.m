function [bouton,boutonSegm,ordInf,ordSup,absInf,absSup] = drawBoutons(boutonInfo,noise,height,width,image)

% This function draws a circle, its center, radius and brightness being
% specified in the inputs. As the brightness varies for the time series
% model, the function operates differently in this case (retrieval of the
% relevant brightness).

switch nargin 
    case 4
        center = boutonInfo{1};
        radius = boutonInfo{2};
        brightness = boutonInfo{5};
    case 5 
        centers = boutonInfo{1};
        center = centers(:,:,image);
        radius = boutonInfo{2};
        brightness = boutonInfo{5}(image-boutonInfo{3}+1);  
end

if (center(1)-radius>0 && center(2)-radius>0 && center(1)+radius<=width && center(2)+radius<=height) %middle
    absInf=center(1)-radius; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=center(2)+radius;
    refAbs=radius+1; refOrd=radius+1;
    
elseif (center(1)-radius<=0 && center(2)-radius<=0) %top left
    absInf=1; absSup=center(1)+radius; ordInf=1; ordSup=center(2)+radius;
    refAbs=center(1); refOrd=center(2);
    
elseif (center(2)+radius>width && center(1)-radius<=0) %bottom left
    absInf=1; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=height;
    refAbs=center(1); refOrd=radius+1;
    
elseif (center(2)-radius<=0 && center(1)+radius>height) %top right
    absInf=center(1)-radius; absSup=width; ordInf=1; ordSup=center(2)+radius;
    refAbs=radius+1; refOrd=center(2);
    
elseif (center(1)+radius>width && center(2)+radius>height) %bottom right
    absInf=center(1)-radius; absSup=width; ordInf=center(2)-radius; ordSup=height;
    refAbs=radius+1; refOrd=radius+1;
    
elseif (center(2)-radius<=0) %top
    absInf=center(1)-radius; absSup=center(1)+radius; ordInf=1; ordSup=center(2)+radius;
    refAbs=radius+1; refOrd=center(2);
    
elseif (center(2)+radius>width) % bottom
    absInf=center(1)-radius; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=height;
    refAbs=radius+1; refOrd=radius+1;
    
elseif (center(1)-radius<=0) %left
    absInf=1; absSup=center(1)+radius; ordInf=center(2)-radius; ordSup=center(2)+radius;
    refAbs=center(1); refOrd=radius+1;
    
elseif (center(1)+radius>width) %right
    absInf=center(1)-radius; absSup=width; ordInf=center(2)-radius; ordSup=center(2)+radius;
    refAbs=radius+1; refOrd=radius+1;
end

[X,Y] = meshgrid(1:absSup-absInf+1,1:ordSup-ordInf+1);
bouton = sqrt( (X(:,:)-refAbs).^2 + (Y(:,:)-refOrd).^2 ); %gets the distance to the center
v = sqrt(-radius^2 / (2*log(0.05/brightness))); %std deviation used for the gaussian profile
Indices = find(bouton>=radius); %gets the indice of the points belonging to the bouton
for i = 1:length(Indices)
    thisRow = Y(Indices(i));
    thisCol = X(Indices(i));
    bouton(thisRow,thisCol) = Inf; %gets the distance for each point plus noise
end
boutonSegm = (bouton<Inf); % gets all the point of the bouton
bouton = bouton + noise*randn(ordSup-ordInf+1, absSup-absInf+1);
bouton = VaryingIntensityWithDistance(bouton,'circle','gauss',v,0,brightness); %gets the intensity of bouton

end