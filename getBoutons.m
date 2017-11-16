function [AxonsPatch,BoutonSegmentation] = getBoutons(AxonsPatch,AxonsGTPoints,MinNbBouton,MaxNbBouton,...
    MinBouBrightness, MaxBouBrightness, BouSigma, height, width, thickness, NbImages,probBoutonInFirstImage, ...
    rowshift, colshift, finalHeight, finalWidth, InfoGTPoints)

%, MinBouRadius,MaxBouRadius)

% This function takes an image with axons as input and returns the same
% image with synaptic boutons having been added (AxonsPatch). The boutons
% are represented as circles. Their center is in the vicinity of a randomly
% picked spline point. The intensity of each pixel belonging to the bouton
% depends on its distance to the center (function
% VaryingIntensityWithDistance) with a gaussian profile. The average
% brightness is controlled by the parameter BouBrightness, and the expected
% variance (v) is calculated here.
% The function also returns the segmentation of the synaptic boutons
% (BoutonSegmentation).

NBou = randi([MinNbBouton,MaxNbBouton]);

switch nargin
    
    case 10
        boutonsInfo = getInfoBoutons(AxonsGTPoints,NBou,MinBouBrightness,MaxBouBrightness,thickness);
        BoutonSegmentation = zeros(height,width);
        for bou=1:NBou
            %draw a bouton
            [boutonDist,boutonSegm,ordInf,ordSup,absInf,absSup] = drawBoutons(boutonsInfo(bou,:),BouSigma,height,width);
            % add it to the patch
            AxonsPatch(ordInf:ordSup,absInf:absSup) = max(AxonsPatch(ordInf:ordSup,absInf:absSup),boutonDist); %puts back the bouton in the image
            %BoutonSegmentation(ordInf:ordSup,absInf:absSup) = bou*max(BoutonSegmentation(ordInf:ordSup,absInf:absSup),boutonSegm); %updates the BoutonSegmentation mask
            BoutonSegmentation(ordInf:ordSup,absInf:absSup) = max(BoutonSegmentation(ordInf:ordSup,absInf:absSup),boutonSegm); %updates the BoutonSegmentation mask
        end
        BoutonSegmentation = logical(BoutonSegmentation);
        
    case 17
        boutonsInfo = getInfoBoutons(AxonsGTPoints,NBou,MinBouBrightness,MaxBouBrightness,thickness,NbImages,probBoutonInFirstImage,...
            rowshift, colshift, finalHeight, finalWidth, InfoGTPoints);
        BoutonSegmentation = zeros(height,width,NbImages);
        for image=1:NbImages
            for bou=1:NBou
                if(image==boutonsInfo{bou,3} || (boutonsInfo{bou,3}<image && boutonsInfo{bou,3}+boutonsInfo{bou,4}>image))
                    %draw a bouton
                    [boutonDist,boutonSegm,ordInf,ordSup,absInf,absSup] = drawBoutons(boutonsInfo(bou,:),BouSigma,height,width,image);
                    % add it to the patch
                    AxonsPatch(ordInf:ordSup,absInf:absSup,image) = max(AxonsPatch(ordInf:ordSup,absInf:absSup,image),boutonDist); %puts back the bouton in the image
                    %BoutonSegmentation(ordInf:ordSup,absInf:absSup,image) = bou*max(BoutonSegmentation(ordInf:ordSup,absInf:absSup,image),boutonSegm); %updates the BoutonSegmentation mask
                    BoutonSegmentation(ordInf:ordSup,absInf:absSup,image) = max(BoutonSegmentation(ordInf:ordSup,absInf:absSup,image),boutonSegm); %updates the BoutonSegmentation mask
                end
            end
        end
        
end


end