function [NewAxonsPatch, NbCircles] = getCircles(AxonsPatch,height,width,sigma_noise_circle,MinNbCircles,MaxNbCircles,...
    CircleBrightness,MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius)

% This function takes an image as input and returns the same image with
% circles having been added. We randomly pick the center of the circle and
% its radius. Then we check that the corresponding location in the original
% image is empty. In that case we insert the circles after having added
% some noise to it.

% The intensity of a pixel is calculated by taking its distance to the
% center of the circle according to a gaussian profile.

% There are two sources of noise in this function. This first one consists
% to reset some pixel of the distance matrix to the radius value. This is
% done to mimick what is observed in real Two Photon Microscopy images
% (black dots). The second source of noise is simply a white noise.

% We have to consider the cases where the circle could be on one edge of
% the image (9 cases).

NewAxonsPatch = AxonsPatch;
NbCircles = randi([MinNbCircles,MaxNbCircles]);

for nbCircle=1:NbCircles
    
    radius = randi([MinRadius,MaxRadius]); %picks a radius
    SelectionPixel = randi([1,1+CircleBrightness]);
    brightness = randi([MinBrightnessCircles,MaxBrightnessCircles])/100; %picks the brightness of the circle
    [dist,ordInf,ordSup,absInf,absSup] = drawCircles(AxonsPatch,radius,SelectionPixel,brightness,height,width,sigma_noise_circle);
    NewAxonsPatch(ordInf:ordSup,absInf:absSup,:) = max...
        (NewAxonsPatch(ordInf:ordSup,absInf:absSup,:),repmat(dist,[1,1,size(AxonsPatch,3)])); %puts back the circle in the Patch

end


end