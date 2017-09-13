% This script generates images imitating axons. It uses parameters contained
% in a JSON file 'parameters.json'. The N images as well as useful
% information are stored in a structure called data. Its fields are: the
% images (Patch), the corresponding axon segmentation (AxonSegmentation),
% the bouton segmentation (BoutonSegmentation), the points that form the
% axons and their branches (GTPoints), the first point of the axon
% (XYStart) and the last one ([XEnd,YEnd]), and the sizes of the gaps in
% each branch (GapSize).

% The resulting images ('images.mat'), the axon segmentations 
% ('axon_masks.mat') and the bouton segmentations ('bouton_masks.mat') are 
% saved in separate files. The last three are 3D matrices where the 
% different single elements are concatanated along the third dimension.

tic
clear;
close all;
%rng(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters to set %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = 100;                             % number of images per chunk of data
Nchunks = 1;                         % total number of chunks
json = 'parameters_hard_512.json';   % name of the json file to load

image_files = '/Users/benjaminbillot/Documents/Imperial/Project/test_images_crop_128';
axon_mask_files = '/Users/benjaminbillot/Documents/Imperial/Project/test_masks_crop_128';
filled_images_files = '/Users/benjaminbillot/Documents/Imperial/Project/test_filled_crop_128';
bouton_mask_files = '/Users/benjaminbillot/Documents/Imperial/Project/test_boutons_crop_128';


%%%%%%%%%%%%%%%%%%%%%%%%%%%% data generation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=loadjson(json);
for chunk=1:Nchunks
    
    %creates N images with associated parameters stored in 'data' structure
    for i=N:-1:1
        [Patch,PatchWithoutGap,AxonSegmentation,BoutonSegmentation,AxonsGTPoints,GapSize,...
            XStart,YStart,XEnd,YEnd] = getPatch(parameters);
        images(:,:,i) = Patch;
        images_gaps_filled(:,:,i) = PatchWithoutGap;
        axon_masks(:,:,i) = AxonSegmentation;
        bouton_masks(:,:,i) = BoutonSegmentation;
        if mod(i,100)==0
            disp(i);
        end 
    end
    
    %saves the structure, the images, the axon and bouton masks in separate files
    disp('saving data');
    path = strcat(strcat(image_files,'_'),strcat(num2str(chunk),'.mat'));
    save(path,'images','-v7.3')
    path = strcat(strcat(axon_mask_files,'_'),strcat(num2str(chunk),'.mat'));
    save(path,'axon_masks','-v7.3')
    path = strcat(strcat(filled_images_files,'_'),strcat(num2str(chunk),'.mat'));
    save(path,'images_gaps_filled','-v7.3')
    path = strcat(strcat(bouton_mask_files,'_'),strcat(num2str(chunk),'.mat'));
    save(path,'bouton_masks','-v7.3')
    
end
toc