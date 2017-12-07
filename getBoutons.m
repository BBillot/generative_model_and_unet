function [AxonsPatch,BoutonSegmentation] = getBoutons(AxonsPatch,AxonsGTPoints, variations, MinNbBouton,MaxNbBouton,...
    MinBouBrightness, MaxBouBrightness, BouSigma, height, width, thickness, sigma_spread, sigma_noise_axon,InfoGTPoints,...
    NbImages,probBoutonInFirstImage,rowshift, colshift, finalHeight, finalWidth)

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
            % add it to the patch and update bouton segmentation map
            AxonsPatch(rowInf:rowSup,colInf:colSup) = max(AxonsPatch(rowInf:rowSup,colInf:colSup),boutonDist);
            BoutonSegmentation(rowInf:rowSup,colInf:colSup) = max(BoutonSegmentation(rowInf:rowSup,colInf:colSup),boutonSegm);
            if boutonsInfo{bou,1} == 1
                [terminalBranch,top_left,bottom_right] = getTerminalBranch(boutonsInfo(bou,:),sigma_spread,sigma_noise_axon,height,width);
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
                if(image==boutonsInfo{bou,4} || (boutonsInfo{bou,4}<image && boutonsInfo{bou,4}+boutonsInfo{bou,5}>image))
                    %draw a bouton
                    [boutonDist,boutonSegm,rowInf,rowSup,colInf,colSup] = drawBoutons(boutonsInfo(bou,:),BouSigma,height,width,image);
                    % add it to the patch and update bouton segmentation map
                    AxonsPatch(rowInf:rowSup,colInf:colSup,image) = max(AxonsPatch(rowInf:rowSup,colInf:colSup,image),boutonDist);
                    BoutonSegmentation(rowInf:rowSup,colInf:colSup,image) = max(BoutonSegmentation(rowInf:rowSup,colInf:colSup,image),boutonSegm);
                    if boutonsInfo{bou,1}==1
                        [terminalBranch,top_left,bottom_right] = getTerminalBranch(boutonsInfo(bou,:),sigma_spread,sigma_noise_axon,height,width,image);
                        AxonsPatch(top_left(1):bottom_right(1),top_left(2):bottom_right(2),image) = ...
                            max(AxonsPatch(top_left(1):bottom_right(1),top_left(2):bottom_right(2),image),terminalBranch);
                    end
                end
            end
        end
        
end

end