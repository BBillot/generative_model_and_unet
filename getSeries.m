function [finalAxonsSeries,finalAxonSegmentation,finalBoutonSegmentation,...
    rotatedAxonsGTPointsWithoutGap,rotatedAxonsGTPointsWithGap,...
    InfoGTPointsWithoutGap,InfoGTPointsWithGap,GapSize]...
    = getSeries(parameters)

% Main function for creating one image. The image is progressively filled
% with splines starting from an edge and moving towards another one.

% All the parameters are in the parameters structure. Their values can be
% modified in the parameters_structure_creation script, where they are also
% explained in details.

% Axon control points are generated by a random walk whose directions
% are controlled by a rejection sampling process to lie within a triangular
% region centred on the axis defined by the last step. Making "conformity"
% closer to 1 creates a set of control points that are more likely to lie
% in a straight line.

% Axon "Ground Truth" (AxonsGTPoints), in the form of a medial
% axis sampled at a much higher density than the control points (x10)
% through using spline (AxonPoly) interpolation. If an axon has several
% branches, new control points are generated starting from a point of the
% spline randomly picked.

% Several axons with several branches can be generated, and we can choose
% if they can cross each other by setting the crossingOK parameter value.

% Once all the splines are created, we determine the distance between each
% pixel in the image and its closest spline point. If the distance is below
% a certain threshold, then the pixel is colored according to this distance
% following a gaussian profile. We get the actual image (AxonsPatch) and
% its axon segmentation (AxonSegmentation).

% Then we modify the image by adding synapting boutons. We get the new
% image (AxonsPatch) and the bouton segmentation (BoutonSegmentation).

% Finally different sources of noise are added. First we add little circles
% representing cells that are often present whithin TPM images of neurons.
% We also add colored and white noise to the image.

% LIMITATIONS
% 1) Small probability for axons to cross near branching points
% 2) Step Size between control points is not a function of resolution
% 3) Number of spline points is fixed regardless of the length of a branch
% 4) If "straightBranching" is too high, a lot of crossings will happen
% near branching areas, but if it's too low, then only right angle
% branchings will occur
% 5) If crossings aren't allowed, the time needed to generate an image is
% not linear with image complexity. (1 axon without branch will take 1s
% whereas 4 axons with each 4 branches will take around 45s sometimes more)
% 6) Only one type of synaptic boutons have been modelled


%%%%%%%%%%%%%%%%%%%%%%%%%%%% initialisation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%gets the value of each parameter in the parameters structure
[finalWidth,finalHeight, negative_image,maxIntensity,...
    NbImages,rowshift,colshift,maxRotAngle,probBoutonInFirstImage,...
    sigma_noise_min,sigma_noise_max,lambdaMin,lambdaMax,...
    MinAxons,MaxAxons,MinBran,MaxBran,...
    conformity,MinThickness, MaxThickness,MinGapSize,MaxGapSize,...
    StepSize,NSplinePoints,crossingOK,straightBranching,SegmentationThreshold,...
    sigma_spread,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,AxonProfile,BranchProfile,sigma_noise_axon,...
    MinNbBouton,MaxNbBouton,MinBouRadius,MaxBouRadius,MinBrightnessBouton,MaxBrightnessBouton,sigma_noise_bouton,minDistBetweenBoutons,...
    MinNbCircles,MaxNbCircles,CircleBrightness,MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius,sigma_noise_circle]...
    = getValues(parameters);

restart=0;
while restart==0
    thetas = randi([-maxRotAngle,maxRotAngle],1,NbImages-1);
    thetamax = max(abs(thetas));
    padding_thickness = round( max( finalWidth*(sqrt(2)-cosd(45-thetamax).^-1),...
        finalHeight*(sqrt(2)-cosd(45-thetamax).^-1) ) );
    height = finalHeight+rowshift-1+padding_thickness*2;
    width = finalWidth+colshift-1+padding_thickness*2;
    NAxons = randi([MinAxons MaxAxons]);                 % number of axons
    NBran = randi([MinBran MaxBran],1,NAxons);           % numbers of branchse per axons
    thickness = randi([round(MinThickness*100),...
        round(MaxThickness*100)],1,sum(NBran))/100;      % thicknesses of the different branches
    GapSize = zeros(1,sum(NBran));                       % size of the gap in each branch
    TotalPoints = sum(NBran)*NSplinePoints;              % number of interpolating points
    AxonsGTPointsWithoutGap = zeros(2,TotalPoints);      % vector of the interpolating points
    AxonsGTPointsWithGap = [];                           % vector of the interpolating points with gap
    variationsWithoutGap = zeros(1,TotalPoints);         % vector of the intensity variations
    variationsWithGap = [];                              % vector on the intensity variations once gaps have been inserted
    pointer = 0;                                         % points to the current branch
    pointerAxon = 1;                                     % points to the start of the current axon in the GTPoints
    AxonsDistWithoutGap = Inf*ones(height,width);        % distance to the AxonsGTPoints without taking gaps into account
    AxonsDistWithGap = Inf*ones(height,width);           % distance to the AxonsGTPoints
    AxonsVariationsWithGap = Inf*ones(height,width);     % describes intensity variations along axons taking gaps into account
    AxonsVariationsWithoutGap = Inf*ones(height,width);  % describes intensity variations but without gaps
    InfoGTPointsWithoutGap = [];                         % contains info about interpolating points
    InfoGTPointsWithGap = [];
    
    
    
    
    for z=1:NAxons
        
        %%%%%%%%%%%%%%%%%%%%%% mother branch of an axon %%%%%%%%%%%%%%%%%%%
        
        if z>1
            pointerAxon = pointerAxon+NBran(z-1)*NSplinePoints;
        end
        
        ncross = 0;
        cross = 1;
        while cross
            if crossingOK % if axons can cross we just get the starting point
                [start,v] = getstartcoords(height,width);%randomly select the starting point
                cross=0;
            else % if they can't then we need to check if the randomly picked starting point is not already
                %on an existing branch
                startOK = 0;
                while startOK==0
                    [start,v] = getstartcoords(height,width);%randomly select the starting point
                    if AxonsDistWithoutGap(start(1),start(2))==Inf %checks if it belongs to an existing branch
                        startOK = 1;
                    end
                end
            end
            ControlPoints = start;
            AtTerminalState = 0;   %reinitialize value for testing
            while ~AtTerminalState
                v  = getValidDirection(v,conformity);   %gets new direction
                new_cpoint = ControlPoints(:,end)+StepSize*v;
                AtTerminalState = (new_cpoint(1)<=1 | new_cpoint(1)>=height | new_cpoint(2)<=1 | new_cpoint(2)>=width); %checks if inside
                ControlPoints = [ControlPoints,new_cpoint]; %stacks the new points inside a matrix
            end
            ControlPoints(1,end) = min(ControlPoints(1,end),height); %put xp at the border if it crossed it
            ControlPoints(1,end) = max(ControlPoints(1,end),1);      %put xp at the border if it crossed it
            ControlPoints(2,end) = min(ControlPoints(2,end),width);  %put yp at the border if it crossed it
            ControlPoints(2,end) = max(ControlPoints(2,end),1);      %put yp at the border if it crossed it
            
            %creates a spline going through all the ControlPoints
            AxonPoly = MakeAxonPoly(ControlPoints);
            
            %matrix containing the points of the spline
            AxonsGTPointsWithoutGap(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = getAxonsGTPoints(AxonPoly,NSplinePoints); %coordinates of the GT Points
            
            %fills the variation vector for this branch
            variationsWithoutGap(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints) = makeVariation...
                (MinAxonIntensity+0.01+(MaxAxonIntensity-MinAxonIntensity-0.02)*rand(1),AxonProfile,NSplinePoints,MinAxonIntensity,...
                MaxAxonIntensity,MinPeriod,MaxPeriod);
            
            %gets the distance to the GTPoints of the pixels belonging to the spline
            [BranchDistWithoutGap,BranchDistWithGap,BranchVariationsWithoutGap,BranchVariationsWithGap,GapSize(1+pointer),newAxonGTPoints,newVariations] = ...
                PixDistanceToAxon(width,height,AxonsGTPointsWithoutGap(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints),...
                thickness(pointer+1),MinGapSize,MaxGapSize,variationsWithoutGap(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints));
            
            %now we check if the spline crosses existing axons
            if ~crossingOK && isempty(find((BranchDistWithoutGap~=Inf & AxonsDistWithoutGap~=Inf),1))
                cross = 0;
            else ncross = ncross+1;
            end
            if ncross>60, disp('restarting drawing'); restart = 1; end
            if restart==1, break, end
        end
        if restart==1, break, end
        
        % updates the matrices with the new branch
        AxonsDistWithGap = min(AxonsDistWithGap,BranchDistWithGap);
        AxonsDistWithoutGap = min(AxonsDistWithoutGap,BranchDistWithoutGap);
        AxonsVariationsWithGap = min(AxonsVariationsWithGap,BranchVariationsWithGap);
        AxonsVariationsWithoutGap = min(AxonsVariationsWithoutGap,BranchVariationsWithoutGap);
        
        % updates info and AxonsGTPointsWithGap
        AxonsGTPointsWithGap = cat(2,AxonsGTPointsWithGap,newAxonGTPoints);
        variationsWithGap = cat(2,variationsWithGap,newVariations);
        InfoGTPointsWithoutGap = cat(2,InfoGTPointsWithoutGap,[z*ones(1,NSplinePoints);ones(1,NSplinePoints);(pointer+1)*ones(1,NSplinePoints)]);
        InfoGTPointsWithGap = cat(2,InfoGTPointsWithGap,[z*ones(1,size(newAxonGTPoints,2));ones(1,size(newAxonGTPoints,2));(pointer+1)*ones(1,size(newAxonGTPoints,2))]);
        
        pointer = pointer+1;
        
        
        %%%%%%%%%%%%%%%%%%%% daughter branches of an axon %%%%%%%%%%%%%%%%%%%%%
        % this section is similar to the previous one
        
        for i=2:NBran(z)
            cross=1;
            while cross
                indicesCurrentAxon = InfoGTPointsWithGap(1,:)==z;
                CurrentAxonGTPoints = AxonsGTPointsWithGap(:,indicesCurrentAxon);
                CurrentAxonVariations = variationsWithGap(indicesCurrentAxon);
                s = randi([2,size(CurrentAxonGTPoints,2)]);
                ControlPoints = CurrentAxonGTPoints(:,s);
                v = CurrentAxonGTPoints(:,s) - CurrentAxonGTPoints(:,s-1);
                AtTerminalState = 0;                                     %reinitialize value for testing
                while ~AtTerminalState
                    if size(ControlPoints,2) == 1
                        v = getValidDirection(v,cosd(45)); % maximum angle between previous and new beanch is 45?
                    else
                        v  = getValidDirection(v,conformity);
                    end
                        %gets new direction
                        new_cpoint = ControlPoints(:,end) + StepSize*v;
                        AtTerminalState = (new_cpoint(1,end)<=1 | new_cpoint(1,end)>=height | new_cpoint(2,end)<=1 | new_cpoint(2,end)>=width);
                        ControlPoints = [ControlPoints,new_cpoint];
                end
                ControlPoints(1,end) = min(ControlPoints(1,end),height);
                ControlPoints(1,end) = max(ControlPoints(1,end),1);
                ControlPoints(2,end) = min(ControlPoints(2,end),width);
                ControlPoints(2,end) = max(ControlPoints(2,end),1);
                
                AxonPoly = MakeAxonPoly(ControlPoints);
                AxonsGTPointsWithoutGap(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = getAxonsGTPoints(AxonPoly,NSplinePoints);
                
                variationsWithoutGap(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints) = makeVariation...
                    (CurrentAxonVariations(s),BranchProfile,NSplinePoints,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod);
                
                [BranchDistWithoutGap,BranchDistWithGap,BranchVariationsWithoutGap,BranchVariationsWithGap,GapSize(1+pointer),newAxonGTPoints, newVariations]...
                    = PixDistanceToAxon(width,height,AxonsGTPointsWithoutGap(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints),...
                    thickness(pointer+1),MinGapSize,MaxGapSize,variationsWithoutGap(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints));
                
                % checks if the new branch crosses already existing branches
                if crossingOK
                    cross = 0;
                else
                    % as branches obviously cross their mother branch, we need a special function that checks the crossing only at
                    % a given distance from the branching point
                    cross=checkCrossings(AxonsDistWithoutGap,BranchDistWithoutGap,straightBranching*thickness(pointer+1),ControlPoints(:,1));
                    if cross==1, ncross = ncross+1; end
                end
                if ncross>60, disp('restarting drawing'); restart = 1; end
                if restart==1, break, end
            end
            if restart==1, break, end
            
            % updates the matrices with the new branch
            AxonsDistWithGap = min(AxonsDistWithGap,BranchDistWithGap);
            AxonsDistWithoutGap = min(AxonsDistWithoutGap,BranchDistWithoutGap);
            AxonsVariationsWithGap = min(AxonsVariationsWithGap,BranchVariationsWithGap);
            AxonsVariationsWithoutGap = min(AxonsVariationsWithoutGap,BranchVariationsWithoutGap);
            
            % updates info and AxonsGTPointsWithGap
            AxonsGTPointsWithGap = cat(2,AxonsGTPointsWithGap,newAxonGTPoints);
            variationsWithGap = cat(2,variationsWithGap,newVariations);
            InfoGTPointsWithoutGap = cat(2,InfoGTPointsWithoutGap,[z*ones(1,NSplinePoints);i*ones(1,NSplinePoints);(pointer+1)*ones(1,NSplinePoints)]);
            InfoGTPointsWithGap = cat(2,InfoGTPointsWithGap,[z*ones(1,size(newAxonGTPoints,2));i*ones(1,size(newAxonGTPoints,2));(pointer+1)*ones(1,size(newAxonGTPoints,2))]);
            
            pointer = pointer+1;
            
        end
        if restart==1, break, end
    end
    if restart==1, restart=0; continue,
    else restart = 1;
    end
end
disp(ncross);


%%%%%%%%%%%%%%%% obtain rotated versions of the main image %%%%%%%%%%%%%%%%

[rotatedCopies, rotatedSegmentations, rotatedAxonsGTPointsWithoutGap, rotatedAxonsGTPointsWithGap, height, width] = getRotatedIntensityMatrices...
    (AxonsDistWithoutGap, AxonsDistWithGap, AxonsGTPointsWithoutGap, AxonsGTPointsWithGap, AxonsVariationsWithGap,variationsWithoutGap,...
    variationsWithGap, height, width, NbImages, padding_thickness, thetas, SegmentationThreshold, sigma_noise_axon, sigma_spread);

%%%%%%%%%%%%%%%%%% adding circles representing boutons %%%%%%%%%%%%%%%%%%%%

%modifies the AxonPatch matrix to add boutons, and creates the bouton
%segmentation
[AxonsSeries,BoutonSegmentation] = getBoutons(rotatedCopies, rotatedAxonsGTPointsWithGap, variationsWithGap, MinNbBouton, MaxNbBouton,...
    MinBrightnessBouton, MaxBrightnessBouton, sigma_noise_bouton, height, width, thickness, sigma_spread, sigma_noise_axon,...
    InfoGTPointsWithGap, minDistBetweenBoutons,NbImages, probBoutonInFirstImage, rowshift, colshift, finalHeight, finalWidth);

%%%%%%%%%%%%%%%%%%% adding circles representing cells %%%%%%%%%%%%%%%%%%%%%

% modifies Axonspatch to add circles
[AxonsSeries, ~] = getCircles...
    (AxonsSeries,height,width,sigma_noise_circle,MinNbCircles,MaxNbCircles,CircleBrightness,...
    MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius);

%%%%%%%%%%%%%%%%%%%%%%%% adding different noises %%%%%%%%%%%%%%%%%%%%%%%%%%

% Add coloured and white noise to the image
sigma_noise = randi([round(sigma_noise_min*100000),round(sigma_noise_max*100000)])/100000;
lambda = randi([lambdaMin,lambdaMax]);
AxonsSeries = noise(AxonsSeries, sigma_noise, lambda, width, height);

%%%%%%%%%%%%%%%%%%%%%%%%% postprocessing images %%%%%%%%%%%%%%%%%%%%%%%%%%%

[finalAxonsSeries,finalAxonSegmentation,finalBoutonSegmentation] = postprocess...
    (AxonsSeries,rotatedSegmentations,BoutonSegmentation,...
    rowshift,colshift,finalHeight,finalWidth,NbImages,negative_image,maxIntensity);

end


function [width,height,negative_image,maxIntensity,...
    NbImages,rowshift,colshift,maxRotAngle,probBoutonInFirstImage,...
    sigma_noise_min,sigma_noise_max,lambdaMin,lambdaMax,...
    MinAxons,MaxAxons,MinBran,MaxBran,...
    conformity,MinThickness, MaxThickness,MinGapSize,MaxGapSize,...
    StepSize,NSplinePoints,crossingOK,straightBranching,SegmentationThreshold,...
    sigma_spread,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,AxonProfile,BranchProfile,sigma_noise_axon,...
    MinNbBouton,MaxNbBouton,MinBouRadius,MaxBouRadius,MinBrightnessBouton,MaxBrightnessBouton,sigma_noise_bouton,minDistBetweenBoutons,...
    MinNbCircles,MaxNbCircles,CircleBrightness,MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius,sigma_noise_circle]...
    = getValues(parameters)

% This function takes out the parameters from the structure

width = parameters(1).width;
height = parameters(1).height;
negative_image = parameters(1).negative_image;
maxIntensity = parameters(1).maxIntensity;

NbImages = parameters(1).NbImages;
rowshift = parameters(1).rowshift;
colshift = parameters(1).colshift;

maxRotAngle = parameters(1).maxRotAngle;
probBoutonInFirstImage = parameters(1).probBoutonInFirstImage;

sigma_noise_min = parameters(1).sigma_noise_min;
sigma_noise_max = parameters(1).sigma_noise_max;
lambdaMin = parameters(1).lambdaMin;
lambdaMax = parameters(1).lambdaMax;

MinAxons = parameters(1).MinAxons;
MaxAxons = parameters(1).MaxAxons;
MinBran = parameters(1).MinBran;
MaxBran = parameters(1).MaxBran;

conformity = parameters(1).conformity;
MinThickness = parameters(1).MinThickness;
MaxThickness = parameters(1).MaxThickness;
MinGapSize = parameters(1).MinGapSize;
MaxGapSize = parameters(1).MaxGapSize;

StepSize = parameters(1).StepSize;
NSplinePoints = parameters(1).NSplinePoints;
crossingOK = parameters(1).crossingOK;
straightBranching = parameters(1).straightBranching;
SegmentationThreshold = parameters(1).SegmentationThreshold;

sigma_spread = parameters(1).sigma_spread;
MinAxonIntensity = parameters(1).MinAxonIntensity/100;
MaxAxonIntensity = parameters(1).MaxAxonIntensity/100;
MinPeriod = parameters(1).MinPeriod;
MaxPeriod = parameters(1).MaxPeriod;
AxonProfile = parameters(1).AxonProfile;
BranchProfile = parameters(1).BranchProfile;
sigma_noise_axon = parameters(1).sigma_noise_axon;

MinNbBouton = parameters(1).MinNbBouton;
MaxNbBouton = parameters(1).MaxNbBouton;
MinBouRadius = parameters(1).MinBouRadius;
MaxBouRadius = parameters(1).MaxBouRadius;
MinBrightnessBouton  = parameters(1).MinBrightnessBouton;
MaxBrightnessBouton  = parameters(1).MaxBrightnessBouton;
sigma_noise_bouton = parameters(1).sigma_noise_bouton;
minDistBetweenBoutons = parameters(1).minDistBetweenBoutons;

MinNbCircles = parameters(1).MinNbCircles;
MaxNbCircles = parameters(1).MaxNbCircles;
MinRadius = parameters(1).MinRadius;
MaxRadius = parameters(1).MaxRadius;
CircleBrightness = parameters(1).CircleBrightness;
MinBrightnessCircles = parameters(1).MinBrightnessCircles;
MaxBrightnessCircles = parameters(1).MaxBrightnessCircles;
sigma_noise_circle = parameters(1).sigma_noise_circle;

end