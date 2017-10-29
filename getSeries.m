function [finalAxonsSeries,finalAxonsPatchWithoutGap,finalAxonSegmentation,finalBoutonSegmentation,AxonsGTPoints,GapSize,XStart,YStart,XEnd,YEnd]...
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
    NbImages,rowshift,colshift,probBoutonInFirstImage,...
    sigma_noise_min,sigma_noise_max,lambdaMin,lambdaMax,...
    MinAxons,MaxAxons,MinBran,MaxBran,...
    conformity,MinThickness, MaxThickness,MinGapSize,MaxGapSize,...
    StepSize,NSplinePoints,crossingOK,straightBranching,SegmentationThreshold,...
    sigma_spread,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,AxonProfile,BranchProfile,sigma_noise_axon,...
    MinNbBouton,MaxNbBouton,MinBouRadius,MaxBouRadius,MinBrightnessBouton,MaxBrightnessBouton,sigma_noise_bouton,...
    MinNbCircles,MaxNbCircles,CircleBrightness,MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius,sigma_noise_circle]...
    = getValues(parameters);

width = finalWidth+rowshift-1;
height = finalHeight+colshift-1;

restart=0;
while restart==0
    NAxons = randi([MinAxons MaxAxons]);                 % number of axons
    NBran = randi([MinBran MaxBran],1,NAxons);           % numbers of branchse per axons
    thickness = randi([round(MinThickness*100),...
        round(MaxThickness*100)],1,sum(NBran))/100;      % thicknesses of the different branches
    GapSize = zeros(1,sum(NBran));                       % size of the gap in each branch
    TotalPoints = sum(NBran)*NSplinePoints;              % number of interpolating points
    AxonsGTPoints = zeros(5,TotalPoints);                % vector of the interpolating points
    variations = zeros(1,TotalPoints);                   % vector of the intensity variations
    pointer = 0;                                         % points to the current branch
    pointerAxon = 1;                                     % points to the start of the current axon in the GTPoints
    AxonsDistWithoutGap = Inf*ones(height,width);        % distance to the AxonsGTPoints without taking gaps into account
    AxonsDistWithGap = Inf*ones(height,width);           % distance to the AxonsGTPoints
    AxonsVariations = Inf*ones(height,width);            % describes intensity variations along axons taking gaps into account
    AxonsVariationsWithoutGap = Inf*ones(height,width);  % describes intensity variations but without gaps
    
    
    for z=1:NAxons
        
        %%%%%%%%%%%%%%%%%%%%%% mother branch of an axon %%%%%%%%%%%%%%%%%%%
        
        if z>1
            pointerAxon = pointerAxon+NBran(z-1)*NSplinePoints;
        end
        
        ncross = 0;
        cross = 1;
        while cross
            if crossingOK % if axons can cross we just get the starting point
                [Xstart,Ystart,v] = getstartcoords(width,height);%randomly select the starting point
                cross=0;
            else % if they can't then we need to check if the randomly picked starting point is not already
                %on an existing branch
                startOK = 0;
                while startOK==0
                    [Xstart,Ystart,v] = getstartcoords(width,height);%randomly select the starting point
                    if AxonsDistWithoutGap(Xstart,Ystart)==Inf %checks if it belongs to an existing branch
                        startOK = 1;
                    end
                end
            end
            if z==1
                XStart = Xstart; YStart = Ystart;
            end
            xp = Xstart; yp = Ystart; ControlPoints = [xp;yp];
            AtTerminalState = 0;   %reinitialize value for testing
            while ~AtTerminalState
                v  = getValidDirection(v,conformity);   %gets new direction
                xp = xp + StepSize*v(1);                %updates xp
                yp = yp + StepSize*v(2);                %updates yp
                AtTerminalState = (xp <= 1 | xp >= width | yp <= 1 | yp >= height); %checks if inside
                xp = min(xp,width); xp = max(xp,1);  %put xp at the border if it crossed it
                yp = min(yp,height); yp = max(yp,1);  %put yp at the border if it crossed it
                ControlPoints = [ControlPoints,[xp;yp]]; %stacks the new points inside a matrix
            end
            if z==1
                XEnd = ControlPoints(1,end); YEnd = ControlPoints(2,end); %gets the last point of the first axon
            end
            %creates a spline going through all the ControlPoints VesselPoly
            AxonPoly = MakeAxonPoly(ControlPoints);
            
            %matrix containing the points of the spline
            AxonsGTPoints(1:2,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = getAxonsGTPoints(AxonPoly,NSplinePoints); %coordinates of the GT Points
            AxonsGTPoints(3,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) =z ;
            AxonsGTPoints(4,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = 1;
            AxonsGTPoints(5,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = pointer+1;
            
            %fills the variation vector for this branch
            variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints) = makeVariation...
                (randi([MinAxonIntensity,MaxAxonIntensity])/100,AxonProfile,NSplinePoints,MinAxonIntensity,...
                MaxAxonIntensity,MinPeriod,MaxPeriod);
            
            %gets the distance to the GTPoints of the pixels belonging to the
            %spline
            [BranchDistWithoutGap,BranchDistWithGap,BranchVariations,BranchVariationsWithoutGap,GapSize(1+pointer)] = PixDistanceToAxon...
                (width,height,AxonsGTPoints(1:2,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints),...
                thickness(pointer+1),MinGapSize,MaxGapSize,...
                variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints));
            
            %now we check if the spline crosses existing axons
            if ~crossingOK && isempty(find((BranchDistWithoutGap~=Inf & AxonsDistWithoutGap~=Inf),1))
                cross = 0;
            else ncross = ncross+1;
            end
            if ncross>50, restart = 1; end
            if restart==1, break, end
        end
        if restart==1, break, end
        
        %updates the AxonsDisthWithGap and the checking matrices (AxonsDistWithoutGap) with the new branch
        AxonsDistWithGap = min(AxonsDistWithGap,BranchDistWithGap);
        AxonsDistWithoutGap = min(AxonsDistWithoutGap,BranchDistWithoutGap);
        AxonsVariations = min(AxonsVariations,BranchVariations);
        AxonsVariationsWithoutGap = min(AxonsVariationsWithoutGap,BranchVariationsWithoutGap);
        
        pointer = pointer+1;
        
        
        %%%%%%%%%%%%%%%%%%%% daughter branches of an axon %%%%%%%%%%%%%%%%%%%%%
        % this section is similar to the previous one
        
        for i=2:NBran(z)
            cross=1;
            while cross
                s = randi([pointerAxon,pointerAxon+NSplinePoints*(i-1)]); %picks a starting point in the current axon
                newStart = AxonsGTPoints(1:2,s);                        %gets its coordinates
                xp = newStart(1); yp = newStart(2); ControlPoints = [xp;yp];
                AtTerminalState = 0;                                     %reinitialize value for testing
                while ~AtTerminalState
                    v  = getValidDirection(v,conformity);                %gets new direction
                    xp = xp + StepSize*v(1); yp = yp + StepSize*v(2);    %updates xp and yp
                    AtTerminalState = (xp <= 1 | xp >= width | yp <= 1 | yp >= height);
                    xp = min(xp,width);xp = max(xp,1);
                    yp = min(yp,height);yp = max(yp,1);
                    ControlPoints = [ControlPoints,[xp;yp]];
                end
                AxonPoly = MakeAxonPoly(ControlPoints);
                AxonsGTPoints(1:2,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = getAxonsGTPoints(AxonPoly,NSplinePoints);
                AxonsGTPoints(3,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = z; % number of the axon it belongs to
                AxonsGTPoints(4,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = i; % number of the axon's branch it belongs to
                AxonsGTPoints(5,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = pointer+1; % number of the branch it belongs to (in agreggate) 
                
                variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints) = makeVariation...
                    (variations(s),BranchProfile,NSplinePoints,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod);
                
                [BranchDistWithoutGap,BranchDistWithGap,BranchVariations,BranchVariationsWithoutGap,GapSize(1+pointer)] = PixDistanceToAxon(width,height,...
                    AxonsGTPoints(1:2,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints),thickness(pointer+1),...
                    MinGapSize,MaxGapSize,variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints));
                
                % checks if the new branch crosses already existing branches
                if crossingOK
                    cross = 0;
                    
                else
                    % as branches obviously cross their mother branch, we need a special function that checks the crossing only at
                    % a given distance from the branching point
                    cross=checkCrossings(AxonsDistWithoutGap,BranchDistWithoutGap,straightBranching*thickness(pointer+1),newStart);
                    if cross==1, ncross = ncross+1; end
                end
                if ncross>50, restart = 1; end
                if restart==1, break, end
            end
            if restart==1, break, end
            
            % updates the matrices with the new branch
            AxonsDistWithGap = min(AxonsDistWithGap,BranchDistWithGap);
            AxonsDistWithoutGap = min(AxonsDistWithoutGap,BranchDistWithoutGap);
            AxonsVariations = min(AxonsVariations,BranchVariations);
            AxonsVariationsWithoutGap = min(AxonsVariationsWithoutGap,BranchVariationsWithoutGap);
            
            pointer = pointer+1;
            
        end
        if restart==1, break, end
    end
    if restart==1, restart=0; continue,
    else restart = 1;
    end
end

%%%%%%%%%%%%%%% Obtaining the image from distance matrix %%%%%%%%%%%%%%%%%%

% gets a compatible version of AxonsVariations with VaryingIntensityWithDistance
AxonsVariations(AxonsVariations==Inf) = 0;
AxonsVariationsWithoutGap(AxonsVariationsWithoutGap==Inf) = 0;
% adds noise to the variations
AxonsVariations = AxonsVariations+sigma_noise_axon*randn(width,height);
% transforms distance into intensity, taking the variations into account
AxonsPatch = VaryingIntensityWithDistance(AxonsDistWithGap,'axons','gauss',sigma_spread,AxonsVariations);
% same but with the matrix without gaps
AxonsPatchWithoutGap = VaryingIntensityWithDistance(AxonsDistWithoutGap,'axons','gauss',sigma_spread,AxonsVariationsWithoutGap);
% gets the axon segmentation
AxonSegmentation = (AxonsDistWithoutGap <SegmentationThreshold);

%%%%%%%%%%%%%%%%%% adding circles representing boutons %%%%%%%%%%%%%%%%%%%%

%modifies the AxonPatch matrix to add boutons, and creates the bouton
%segmentation
[AxonsSeries,BoutonSegmentation] = getBoutons(AxonsPatch,AxonsGTPoints, MinNbBouton, MaxNbBouton,...
    MinBrightnessBouton, MaxBrightnessBouton, sigma_noise_bouton, height, width, thickness, NbImages,probBoutonInFirstImage);
    % ,MinBouRadius,MaxBouRadius)

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

[finalAxonsSeries,finalAxonsPatchWithoutGap,finalAxonSegmentation,finalBoutonSegmentation] = postprocess...
    (AxonsSeries,AxonsPatchWithoutGap,AxonSegmentation,BoutonSegmentation,...
    rowshift,colshift,finalHeight,finalWidth,NbImages,negative_image,maxIntensity);

end

function [cross]=checkCrossings(AxonsDistWithoutGap,BranchDistWithoutGap,threshold,newStart)

% Checks that the new branch doesn't cross existing axons.
% We are forced to consider the case where a branch starts from another
% branch. Obviously the new branch crosses its mother branch. So we
% tolerate crossings in the vicinity of the branching point. Otherwise (if
% crossing occurs far from the branching point), it probably
% means the new branch crosses another branch.

cross = 1;
[row,col]=find(AxonsDistWithoutGap~=Inf & BranchDistWithoutGap~=Inf); %finds the pixels belonging to both branches

if isempty(row)
    cross=0;
else
    lIndices = length(row); %numbers of pixels common to both branches
    l = 1; %initialization
    while cross
        thisRow = row(l); thisCol = col(l);
        distToStartControlPoint = sqrt((newStart(1)-thisCol)^2+(newStart(2)-thisRow)^2); % distance to branching point
        if distToStartControlPoint>threshold
            break %two different branch cross,
        elseif l==lIndices
            cross=0; %if all the points are close enough then we consider that there is no crossing
        else
            l = l+1;
        end
    end
    
end

end

function [AxonAxisGT] = getAxonsGTPoints(AxonsPoly,npoints)

% This function exctracts points from the spline

tt = linspace(0,1,npoints);
AxonAxisGT = fnval(AxonsPoly,tt); %find the value of the spline for all values of tt
AxonPolyDer = fnder(AxonsPoly,1); % differentiates VesselPoly
AxonDirGT = fnval(AxonPolyDer,tt); %find the values of the derivative at the spline points

end

function [StartX,StartY,u0] = getstartcoords(width,height)

% Randomly generates a starting on one of the four edges

whichside = randi(4,1); % One random number from 1 to 4

switch whichside
    case 1
        StartX = 1;
        StartY = randi([round(height/4),round(3*height/4)],1);
        u0 = [1,0];
    case 2
        StartX = randi([round(width/4),round(3*width/4)],1);
        StartY = 1;
        u0 = [0,1];
    case 3
        StartX = width;
        StartY = randi([round(height/4),round(3*height/4)],1);
        u0 = [-1,0];
    case 4
        StartX = randi([round(width/4),round(3*width/4)],1);
        StartY = height;
        u0 = [0,-1];
end
end

function u = getValidDirection(v, conformity)

%Gets a direction that more or less moves forward from the previous
%direction. Some deviation allowed as a straight tube vessel isn't
%interesting

%Increase if you want a straighter vessel.
%Decerease to make it curve more
v = v/norm(v); %normalize v
NoValidDirection = 1;
while NoValidDirection
    u = makerandunitdirvec(1);
    dp = v*u';
    if dp>conformity
        NoValidDirection = 0;
    end
end
end

function [width,height,negative_image,maxIntensity,...
    NbImages,rowshift,colshift,probBoutonInFirstImage,...
    sigma_noise_min,sigma_noise_max,lambdaMin,lambdaMax,...
    MinAxons,MaxAxons,MinBran,MaxBran,...
    conformity,MinThickness, MaxThickness,MinGapSize,MaxGapSize,...
    StepSize,NSplinePoints,crossingOK,straightBranching,SegmentationThreshold,...
    sigma_spread,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,AxonProfile,BranchProfile,sigma_noise_axon,...
    MinNbBouton,MaxNbBouton,MinBouRadius,MaxBouRadius,MinBrightnessBouton,MaxBrightnessBouton,sigma_noise_bouton,...
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
MinAxonIntensity = parameters(1).MinAxonIntensity;
MaxAxonIntensity = parameters(1).MaxAxonIntensity;
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

MinNbCircles = parameters(1).MinNbCircles;
MaxNbCircles = parameters(1).MaxNbCircles;
MinRadius = parameters(1).MinRadius;
MaxRadius = parameters(1).MaxRadius;
CircleBrightness = parameters(1).CircleBrightness;
MinBrightnessCircles = parameters(1).MinBrightnessCircles;
MaxBrightnessCircles = parameters(1).MaxBrightnessCircles;
sigma_noise_circle = parameters(1).sigma_noise_circle;

end

function AxonPoly = MakeAxonPoly(ControlPoints)

%creates a spline going trough all the ControlPoints

t = linspace(0,1,size(ControlPoints,2));%vector going from 0 to 1 with n evenly spaced values (n=#column of ControlP)
AxonPoly = csapi(t, ControlPoints); %csapi=spline, creates the spline

end

function u1 = makerandunitdirvec(N)
v = randn(N,2);
u1 = bsxfun(@rdivide,v,sqrt(sum(v.^2,2))); %normalize the vector v
end

function variation = makeVariation(startVariation,profileType,NSplinePoints,MinAxonIntensity,...
    MaxAxonIntensity,MinPeriod,MaxPeriod)

% This function generates vectors with values evolving according to a
% given profile. The length of this vector is the same as the number of
% spline points in a branch. Indeed each spline points will be associated
% with a multiplicative coefficient for its intensity.

switch profileType
    
    case {'constant'}
        variation = startVariation*ones(1,NSplinePoints);
        
    case {'linear'} %linear variation of intensity along the branch.
        upordown = randi(1); %intensity should increase or decrease from its starting point: 1=up 0=down
        if upordown
            MaxIntensity = randi([min(round(startVariation*10),MaxAxonIntensity*10-1),MaxAxonIntensity*10-1])/10;
            if startVariation~=MaxIntensity
                variation = startVariation:(MaxIntensity-startVariation)/(NSplinePoints-1):MaxIntensity;
            else
                variation = startVariation*ones(1,NSplinePoints);
            end
        else
            MinIntensity = randi([MinAxonIntensity*10+1,max(round(startVariation*10),MinAxonIntensity*10+1)])/10;
            if startVariation~=MinIntensity
                variation = startVariation:-(startVariation-MinIntensity)/(NSplinePoints-1):MinIntensity;
            else
                variation = startVariation*ones(1,NSplinePoints);
            end
        end
        
    case {'cosine'} %cosine variation of intensity along a branch
        NPeriods = randi([MinPeriod*100,MaxPeriod*100])/100;
        if startVariation<1, startVariation = startVariation*100; end
        MaxIntensity = randi([min(round(startVariation)-1,MaxAxonIntensity-1),MaxAxonIntensity-1])/100;
        MinIntensity = randi([MinAxonIntensity+1,max(round(startVariation)+1,MinAxonIntensity+1)])/100;
        a = 0.5*(MaxIntensity+MinIntensity); b = 0.5*(MaxIntensity-MinIntensity);
        %real part is due to no infinite calculation accuracy that leads to complex number for acos(1)
        phi = real(acos((round(startVariation)/100-a)/b));
        upordown = randi(1); %intensity should increase or decrease from its starting point: 1=up 0=down
        if upordown
            variation = a+b*cos((0:2*pi*NPeriods/(NSplinePoints-1):2*pi*NPeriods)-phi);
        else
            variation = a+b*cos((0:2*pi*NPeriods/(NSplinePoints-1):2*pi*NPeriods)+phi);
        end
        
end

end