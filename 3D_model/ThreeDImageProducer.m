% 3D model!!!!!!!!!!!!!!!!!!

tic
clear; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%% parameters to set %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = 1;                 % number of images per chunk of data
Nchunks = 1;             % total number of chunks
json = '256x256.json';   % name of the json file to load


%%%%%%%%%%%%%%%%%%%%%%%%%%%% data generation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parameters=loadjson(json);
for chunk=1:Nchunks

    %creates N images with associated parameters stored in 'data' structure
    for i=N:-1:1
        
        %create individual image
        [Patch,GTPoints,InfoGTPoints,gapindices]...
            = get3Dimage(parameters);
        %save image and related information
        images(:,:,i) = Patch;
        data(i).GTPoints = GTPoints;
        data(i).InfoGTPoints = InfoGTPoints;
        data(i).gapindices = gapindices;

        if mod(i,50)==0
            disp(i);
        end
        
    end
    
end

toc