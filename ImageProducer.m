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
% saved in separate files.

% Depending on size and the amount of data that one wishes to generate,
% Matalb might not be able to save the created matrices. That's why we can
% divide the images in several chunks. The number of the chunk will
% automatically be appended to the name of the saved files.

tic
clear;
%close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters to set %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = 1;                   % number of images per chunk of data
Nchunks = 1;             % total number of chunks
json = '256x256.json';   % name of the json file to load

% image_files = 'path_to_file/file_name';
% axon_mask_files = 'path_to_file/file_name';
% filled_images_files = 'path_to_file/file_name';
% bouton_mask_files = 'path_to_file/file_name';


%%%%%%%%%%%%%%%%%%%%%%%%%%%% data generation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parameters=loadjson(json);
for chunk=1:Nchunks
    
    %creates N images with associated parameters stored in 'data' structure
    for i=N:-1:1
        rng(35);
        [Patch,PatchWithoutGap,AxonSegmentation,BoutonSegmentation,...
            GTPointsWithoutGap,GTPointsWithGap,...
            InfoGTPointsWithoutGap,InfoGTPointsWithGap,GapSize] = getPatch(parameters);
         images(:,:,i) = Patch;
         axon_masks(:,:,i) = AxonSegmentation;
         bouton_masks(:,:,i) = BoutonSegmentation;
%          data(i).GTPointsWithoutGap = GTPointsWithoutGap;
%          data(i).GTPointsWithGap = GTPointsWithGap;
%          data(i).InfoGTPointsWithoutGap = InfoGTPointsWithoutGap;
%          data(i).InfoGTPointsWithGap = InfoGTPointsWithGap;
%          data(i).GapSizes = GapSize;
        if mod(i,50)==0
            disp(i);
        end 
    end
    
    %saves the structure, the images, the axon and bouton masks in separate files
%     disp('saving data');
%     path = strcat(strcat(image_files,'_'),strcat(num2str(chunk),'.mat'));
%     save(path,'images','-v7.3')
%     path = strcat(strcat(axon_mask_files,'_'),strcat(num2str(chunk),'.mat'));
%     save(path,'axon_masks','-v7.3')
%     path = strcat(strcat(filled_images_files,'_'),strcat(num2str(chunk),'.mat'));
%     save(path,'images_gaps_filled','-v7.3')
%     path = strcat(strcat(bouton_mask_files,'_'),strcat(num2str(chunk),'.mat'));
%     save(path,'bouton_masks','-v7.3')
    
end

im = images(:,:,1);
ma=axon_masks(:,:,1);

figure; imagesc(im); colormap(gray); axis off;

toc

%TODO :
% -make them fuzzier
% -minimum distance between boutons
% -make that the bouton can't be on another axon
% -include Anil's circles
% -integrate the changes in the time series model