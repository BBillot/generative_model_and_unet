function [bouton,boutonSegm,rowInf,rowSup,colInf,colSup] = drawBoutons(boutonInfo,noise,height,width,image)

% This function draws a circle, its center, radius and brightness being
% specified in the inputs. As the brightness varies for the time series
% model, the function operates differently in this case (retrieval of the
% relevant brightness).

switch nargin 
    case 4
        center = boutonInfo{2};
        radius = boutonInfo{3};
        brightness = boutonInfo{6};
    case 5 
        centers = boutonInfo{2};
        center = centers(:,:,image);
        radius = boutonInfo{3};
        brightness = boutonInfo{6}(image-boutonInfo{4}+1);  
end

if (center(1)-radius>0 && center(1)+radius<=height && center(2)-radius>0 && center(2)+radius<=width) %middle
    rowInf=center(1)-radius; rowSup=center(1)+radius; colInf=center(2)-radius; colSup=center(2)+radius;
    refRow=radius+1; refCol=radius+1;
    
elseif (center(1)-radius<=0 && center(2)-radius<=0) %top left
    rowInf=1; rowSup=center(1)+radius; colInf=1; colSup=center(2)+radius;
    refRow=center(1); refCol=center(2);
    
elseif (center(1)+radius>height && center(2)-radius<=0) %bottom left
    rowInf=center(1)-radius; rowSup=height; colInf=1; colSup=center(2)+radius;
    refRow=radius+1; refCol=center(2);
    
elseif (center(1)-radius<=0 && center(2)+radius>width) %top right
    rowInf=1; rowSup=center(1)+radius; colInf=center(2)-radius; colSup=width;
    refRow=center(1); refCol=radius+1;
    
elseif (center(1)+radius>height && center(2)+radius>width) %bottom right
    rowInf=center(1)-radius; rowSup=height; colInf=center(2)-radius; colSup=width;
    refRow=radius+1; refCol=radius+1;
    
elseif (center(1)-radius<=0) %top
    rowInf=1; rowSup=center(1)+radius; colInf=center(2)-radius; colSup=center(2)+radius;
    refRow=center(1); refCol=radius+1;
    
elseif (center(1)+radius>height) % bottom
    rowInf=center(1)-radius; rowSup=height; colInf=center(2)-radius; colSup=center(2)+radius;
    refRow=radius+1; refCol=radius+1;
    
elseif (center(2)-radius<=0) %left
    rowInf=center(1)-radius; rowSup=center(1)+radius; colInf=1; colSup=center(2)+radius;
    refRow=radius+1; refCol=center(2);
    
elseif (center(2)+radius>width) %right
    rowInf=center(1)-radius; rowSup=center(1)+radius; colInf=center(2)-radius; colSup=width;
    refRow=radius+1; refCol=radius+1;
end

[X,Y] = meshgrid(1:colSup-colInf+1,1:rowSup-rowInf+1);
bouton = sqrt( (Y-refRow).^2 + (X-refCol).^2 ); %gets the distance to the center
v = sqrt(-radius^2 / (2*log(0.05/brightness))); %std deviation used for the gaussian profile
Indices = find(bouton>=radius); %points outside of the circle
for i = 1:length(Indices)
    thisRow = Y(Indices(i));
    thisCol = X(Indices(i));
    bouton(thisRow,thisCol) = Inf; %set the distance to Inf
end
boutonSegm = (bouton<Inf); % gets all the point of the bouton
bouton = bouton + noise*randn(size(bouton,1), size(bouton,2));
bouton = VaryingIntensityWithDistance(bouton,'circle','gauss',v,0,brightness); %gets the intensity of bouton

end