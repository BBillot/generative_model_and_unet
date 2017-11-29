function [AxonsPatch,BoutonSegmentation] = getBoutons(AxonsPatch,AxonsGTPoints, variations, MinNbBouton,MaxNbBouton,...
    MinBouBrightness, MaxBouBrightness, BouSigma, height, width, thickness, sigma_spread, sigma_noise_axon,InfoGTPoints, NbImages,probBoutonInFirstImage, ...
    rowshift, colshift, finalHeight, finalWidth)

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
    
    case 14
        boutonsInfo = getInfoBoutons2(height,width,AxonsGTPoints,variations,NBou,MinBouBrightness,MaxBouBrightness,thickness,InfoGTPoints);
        BoutonSegmentation = zeros(height,width);
        for bou=1:NBou
            %draw a bouton
            [boutonDist,boutonSegm,rowInf,rowSup,colInf,colSup] = drawBoutons(boutonsInfo(bou,:),BouSigma,height,width);
            % add it to the patch
            AxonsPatch(rowInf:rowSup,colInf:colSup) = max(AxonsPatch(rowInf:rowSup,colInf:colSup),boutonDist); %puts back the bouton in the image
            BoutonSegmentation(rowInf:rowSup,colInf:colSup) = max(BoutonSegmentation(rowInf:rowSup,colInf:colSup),boutonSegm); %updates the BoutonSegmentation mask
            if boutonsInfo{bou,1} == 1
                [terminalBranch,top_left,bottom_right] = getTerminalBranch(boutonsInfo(bou,:),sigma_spread,sigma_noise_axon);
                AxonsPatch(top_left(1):bottom_right(1),top_left(2):bottom_right(2)) = ...
                    max(AxonsPatch(top_left(1):bottom_right(1),top_left(2):bottom_right(2)),terminalBranch);
            end
        end
        BoutonSegmentation = logical(BoutonSegmentation);
        
    case 20
        boutonsInfo = getInfoBoutons2(height,width,AxonsGTPoints,variations,NBou,MinBouBrightness,MaxBouBrightness,thickness,InfoGTPoints,...
            NbImages,probBoutonInFirstImage,rowshift, colshift, finalHeight, finalWidth);
        BoutonSegmentation = zeros(height,width,NbImages);
        for image=1:NbImages
            for bou=1:NBou
                if(image==boutonsInfo{bou,3} || (boutonsInfo{bou,3}<image && boutonsInfo{bou,3}+boutonsInfo{bou,4}>image))
                    %draw a bouton
                    [boutonDist,boutonSegm,rowInf,rowSup,colInf,colSup] = drawBoutons(boutonsInfo(bou,:),BouSigma,height,width,image);
                    % add it to the patch
                    AxonsPatch(rowInf:rowSup,colInf:colSup,image) = max(AxonsPatch(rowInf:rowSup,colInf:colSup,image),boutonDist); %puts back the bouton in the image
                    %BoutonSegmentation(ordInf:ordSup,absInf:absSup,image) = bou*max(BoutonSegmentation(ordInf:ordSup,absInf:absSup,image),boutonSegm); %updates the BoutonSegmentation mask
                    BoutonSegmentation(rowInf:rowSup,colInf:colSup,image) = max(BoutonSegmentation(rowInf:rowSup,colInf:colSup,image),boutonSegm); %updates the BoutonSegmentation mask
                end
            end
        end
        
end

end