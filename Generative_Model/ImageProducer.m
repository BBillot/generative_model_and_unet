% This script generates images imitating axons in chunks (N being the
% number of images in a chunk). It uses parameters contained
% in a JSON file. The images, corresponding segmentation maps (for both
% boutons and axons) as well as useful information are stored in a
% structure called data. Its fields are: the points that form the axons and
% their branches with or without gap, info about those points (to which
% axon and branch they belong) and gap sizes.

% The resulting images ('images.mat'), the axon segmentations
% ('axon_masks.mat') and the bouton segmentations ('bouton_masks.mat') are
% saved in separate files.

% Depending on size and the amount of data that one wishes to generate,
% Matlab might not be able to save the created matrices. That's why we can
% divide the images in several chunks that will be saved separately.

tic
clear;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters to set %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = 200;                 % number of images per chunk of data
Nchunks = 1;             % total number of chunks
json = '256x256.json';   % name of the json file to load

image_files = 'path_to_file/file_name';
axon_mask_files = 'path_to_file/file_name';
filled_images_files = 'path_to_file/file_name';
bouton_mask_files = 'path_to_file/file_name';


%%%%%%%%%%%%%%%%%%%%%%%%%%%% data generation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=loadjson(json);
for chunk=1:Nchunks

    %creates N images with associated parameters stored in 'data' structure
    for i=N:-1:1

        %create individual image
        [Patch,AxonSegmentation,BoutonSegmentation,GTPoints,InfoGTPoints,gapindices]...
            = getPatch(parameters);
        %save image and related information
        images(:,:,i) = Patch;
        axon_masks(:,:,i) = AxonSegmentation;
        bouton_masks(:,:,i) = BoutonSegmentation;
        data(i).GTPoints = GTPoints;
        data(i).InfoGTPoints = InfoGTPoints;
        data(i).gapindices = gapindices;

        if mod(i,50)==0
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