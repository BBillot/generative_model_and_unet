function [finalAxonsSeries,finalAxonsPatchWithoutGap,finalAxonSegmentation,finalBoutonSegmentation] = postprocess(...
    AxonsSeries,AxonsPatchWithoutGap,AxonSegmentation,BoutonSegmentation,...
    rowshift,colshift,finalHeight,finalWidth,NbImages,negative_image,maxIntensity)

% This function first crops differently all the images stored in the 3D 
% matrices. The same shift is applied to the corresponding information
% matrices (segmentations,...). This allows to obtained shifted versions of
% the time series images.

% This function also transforms the images to obtain pixelvalues between 0
% and 255. This also where the negative images are obtained if the user has
% specified it in the parameters.

finalAxonsSeries = zeros(finalHeight,finalWidth,NbImages);
finalAxonsPatchWithoutGap = zeros(finalHeight,finalWidth,NbImages);
finalAxonSegmentation = zeros(finalHeight,finalWidth,NbImages);
finalBoutonSegmentation = zeros(finalHeight,finalWidth,NbImages);

%shifting differently each image (and their corresponding segmentation maps) of the serie
for im=1:NbImages
    rowstart = randi([1,rowshift]);
    colstart = randi([1,colshift]);
    finalAxonsSeries(:,:,im) =  AxonsSeries(rowstart:rowstart+finalHeight-1,colstart:colstart+finalWidth-1,im);
    finalAxonsSeries(:,:,im) = floor(finalAxonsSeries(:,:,im)*maxIntensity/max(max(finalAxonsSeries(:,:,im))));
    finalAxonsPatchWithoutGap(:,:,im) = AxonsPatchWithoutGap(rowstart:rowstart+finalHeight-1,colstart:colstart+finalWidth-1);
    finalAxonsPatchWithoutGap(finalAxonsPatchWithoutGap<0) = 0;
    finalAxonsPatchWithoutGap(:,:,im) = floor(finalAxonsPatchWithoutGap(:,:,im)*maxIntensity/max(max(finalAxonsPatchWithoutGap(:,:,im))));
    finalAxonSegmentation(:,:,im) = AxonSegmentation(rowstart:rowstart+finalHeight-1,colstart:colstart+finalWidth-1);
    finalBoutonSegmentation(:,:,im) = BoutonSegmentation(rowstart:rowstart+finalHeight-1,colstart:colstart+finalWidth-1,im);
end
finalAxonSegmentation = maxIntensity*finalAxonSegmentation;
finalBoutonSegmentation = maxIntensity*finalBoutonSegmentation;

% take the negative of image if specified
if negative_image
    finalAxonsSeries = maxIntensity*ones(width,height)-finalAxonsSeries;
    finalAxonsPatchWithoutGap = maxIntensity*ones(width,height)-finalAxonsPatchWithoutGap;
end

end