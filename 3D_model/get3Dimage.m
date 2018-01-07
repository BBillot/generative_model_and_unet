function [AxonsPatch,AxonsGTPoints,InfoGTPoints,gapindices]...
    = get3Dimage(parameters)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% initialisation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%gets the value of each parameter in the parameters structure
[width,height, negative_image,maxIntensity,...
    sigma_noise_min,sigma_noise_max,lambdaMin,lambdaMax,...
    MinAxons,MaxAxons,MinBran,MaxBran,...
    conformity,MinThickness, MaxThickness,MinGapSize,MaxGapSize,...
    StepSize,NSplinePoints,crossingOK,straightBranching,SegmentationThreshold,...
    sigma_spread,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,AxonProfile,BranchProfile,sigma_noise_axon,...
    MinNbBouton,MaxNbBouton,MinBrightnessBouton,MaxBrightnessBouton,sigma_noise_bouton,minDistBetweenBoutons,...
    MinNbCircles,MaxNbCircles,MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius,sigma_noise_circle]...
    = getValues(parameters);

% when too many crossings between branches occur, we start a new drawing.
restart=0; 
while restart==0
    depth = 30;
    NAxons = randi([MinAxons MaxAxons]);             % number of axons
    NBran = randi([MinBran MaxBran],1,NAxons);       % numbers of branchse per axons
    thickness = randi([round(MinThickness*100),...
        round(MaxThickness*100)],1,sum(NBran))/100;  % thicknesses of the different branches
    TotalPoints = sum(NBran)*NSplinePoints;          % number of interpolating points
    AxonsGTPoints = zeros(3,TotalPoints);            % vector of the interpolating points
    variations = zeros(1,TotalPoints);               % vector of the intensity variations
    pointer = 0;                                     % points to the current branch
    pointerAxon = 1;                                 % points to the start of the current axon in the GTPoints
    AxonsDist = Inf*ones(height,width,depth);        % distance to the AxonsGTPoints without taking gaps into account
    AxonsVariations = Inf*ones(height,width,depth);  % describes intensity variations but without gaps
    InfoGTPoints = [];                               % contains info about interpolating points
    gapindices = [];
    
    
    for z=1:NAxons
        
        %%%%%%%%%%%%%%%%%%%%%% mother branch of an axon %%%%%%%%%%%%%%%%%%%
        
        if z>1
            pointerAxon = pointerAxon+NBran(z-1)*NSplinePoints;
        end
        
        ncross = 0;
        cross = 1;
        while cross
            [ControlPoints,v] = getStartCoords(height,width,depth,crossingOK,AxonsDist);
            AtTerminalState = 0;   %reinitialize value for testing
            while ~AtTerminalState
                v  = getValidDirection(v,conformity);   %gets new direction
                new_cpoint = ControlPoints(:,end)+StepSize*v;
                AtTerminalState = (new_cpoint(1)<=1 | new_cpoint(1)>=height | ...
                    new_cpoint(2)<=1 | new_cpoint(2)>=width | ...
                    new_cpoint(3)<=1 | new_cpoint(3)>=depth); %checks if inside
                ControlPoints = [ControlPoints,new_cpoint]; %stacks the new points inside a matrix
            end
            ControlPoints(1,end) = min(ControlPoints(1,end),height); %put xp at the border if it crossed it
            ControlPoints(1,end) = max(ControlPoints(1,end),1);      %put xp at the border if it crossed it
            ControlPoints(2,end) = min(ControlPoints(2,end),width);  %put yp at the border if it crossed it
            ControlPoints(2,end) = max(ControlPoints(2,end),1);      %put yp at the border if it crossed it
            ControlPoints(3,end) = min(ControlPoints(3,end),depth);  %put yp at the border if it crossed it
            ControlPoints(3,end) = max(ControlPoints(3,end),1);      %put yp at the border if it crossed it
            
            %creates a spline going through all the ControlPoints
            AxonPoly = MakeAxonPoly(ControlPoints);
            
            %matrix containing the points of the spline
            AxonsGTPoints(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = getAxonsGTPoints(AxonPoly,NSplinePoints);
            
            %fills the variation vector for this branch
            [variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints), gapidx] = makeVariation...
                (MinAxonIntensity+0.01+(MaxAxonIntensity-MinAxonIntensity-0.02)*rand(1),AxonProfile,NSplinePoints,MinAxonIntensity,...
                MaxAxonIntensity,MinPeriod,MaxPeriod,MinGapSize,MaxGapSize);
            
            %gets the distance to the GTPoints of the pixels belonging to the spline
            [BranchDist,BranchVariations] = ...
                PixDistanceToAxon(width,height,depth,AxonsGTPoints(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints),...
                thickness(pointer+1),variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints));
            
            %now we check if the spline crosses existing axons
            if ~crossingOK && isempty(find((BranchDist~=Inf & AxonsDist~=Inf),1))
                cross = 0;
            elseif crossingOK;
                cross = 0;
            else ncross = ncross+1;
            end
            if ncross>60, restart = 1; end
            if restart==1, break, end
        end
        if restart==1, break, end
        
        % updates the matrices with the new branch
        AxonsDist = min(AxonsDist,BranchDist);
        AxonsVariations = min(AxonsVariations,BranchVariations);
        
        % updates info and AxonsGTPointsWithGap
        InfoGTPoints = cat(2,InfoGTPoints,[z*ones(1,NSplinePoints);ones(1,NSplinePoints);(pointer+1)*ones(1,NSplinePoints)]);
        gapindices = cat(2,gapindices, gapidx);
        
        pointer = pointer+1;
        
        
        %%%%%%%%%%%%%%%%%%%% daughter branches of an axon %%%%%%%%%%%%%%%%%%%%%
        % this section is similar to the previous one
        
        for i=2:NBran(z)
            cross=1;
            while cross
                startOK = 1;
                while startOK
                    s = randi([pointerAxon+1,pointerAxon+NSplinePoints*(i-1)]);
                    if ~ismember(s,gapindices)
                        startOK = 0;
                    end
                end
                ControlPoints = AxonsGTPoints(:,s);
                v = AxonsGTPoints(:,s) - AxonsGTPoints(:,s-1);
                AtTerminalState = 0;                                     %reinitialize value for testing
                while ~AtTerminalState
                    if size(ControlPoints,2) == 1
                        v = getValidDirection(v,cosd(45)); % maximum angle between previous and new beanch is 45?
                    else
                        v  = getValidDirection(v,conformity);
                    end
                        %gets new direction
                        new_cpoint = ControlPoints(:,end) + StepSize*v;
                        AtTerminalState = (new_cpoint(1)<=1 | new_cpoint(1)>=height | ...
                                           new_cpoint(2)<=1 | new_cpoint(2)>=width | ...
                                           new_cpoint(3)<=1 | new_cpoint(3)>=depth); %checks if inside
                        ControlPoints = [ControlPoints,new_cpoint];
                end
                ControlPoints(1,end) = min(ControlPoints(1,end),height);
                ControlPoints(1,end) = max(ControlPoints(1,end),1);
                ControlPoints(2,end) = min(ControlPoints(2,end),width);
                ControlPoints(2,end) = max(ControlPoints(2,end),1);
                ControlPoints(3,end) = min(ControlPoints(3,end),depth);
                ControlPoints(3,end) = max(ControlPoints(3,end),1);
                
                AxonPoly = MakeAxonPoly(ControlPoints);
                AxonsGTPoints(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints) = getAxonsGTPoints(AxonPoly,NSplinePoints);
                
                [variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints), gapidx] = makeVariation...
                    (variations(s),BranchProfile,NSplinePoints,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,MinGapSize,MaxGapSize);
                
                [BranchDist,BranchVariations]...
                    = PixDistanceToAxon(width,height,depth,AxonsGTPoints(:,1+pointer*NSplinePoints:pointer*NSplinePoints+NSplinePoints),...
                    thickness(pointer+1),variations(1+pointer*NSplinePoints:NSplinePoints+pointer*NSplinePoints));
                
                % checks if the new branch crosses already existing branches
                if crossingOK
                    cross = 0;
                else
                    % as branches obviously cross their mother branch, we need a special function that checks the crossing only at
                    % a given distance from the branching point
                    cross=checkCrossings(AxonsDist,BranchDist,straightBranching*thickness(pointer+1),ControlPoints(:,1));
                    if cross==1, ncross = ncross+1; end
                end
                if ncross>60, restart = 1; end
                if restart==1, break, end
            end
            if restart==1, break, end
            
            % updates the matrices with the new branch
            AxonsDist = min(AxonsDist,BranchDist);
            AxonsVariations = min(AxonsVariations,BranchVariations);
            
            % updates info and AxonsGTPointsWithGap
            InfoGTPoints = cat(2,InfoGTPoints,[z*ones(1,NSplinePoints);i*ones(1,NSplinePoints);(pointer+1)*ones(1,NSplinePoints)]);
            gapindices = cat(2,gapindices, gapidx);
            
            pointer = pointer+1;
            
        end
        if restart==1, break, end
    end
    if restart==1, restart=0; continue,
    else restart = 1;
    end
end



end



function [width,height,negative_image,maxIntensity,...
    sigma_noise_min,sigma_noise_max,lambdaMin,lambdaMax,...
    MinAxons,MaxAxons,MinBran,MaxBran,...
    conformity,MinThickness, MaxThickness,MinGapSize,MaxGapSize,...
    StepSize,NSplinePoints,crossingOK,straightBranching,SegmentationThreshold,...
    sigma_spread,MinAxonIntensity,MaxAxonIntensity,MinPeriod,MaxPeriod,AxonProfile,BranchProfile,sigma_noise_axon,...
    MinNbBouton,MaxNbBouton,MinBrightnessBouton,MaxBrightnessBouton,sigma_noise_bouton,minDistBetweenBoutons,...
    MinNbCircles,MaxNbCircles,MinBrightnessCircles,MaxBrightnessCircles,MinRadius,MaxRadius,sigma_noise_circle]...
    = getValues(parameters)

% This function takes out the parameters from the structure

width = parameters(1).width;
height = parameters(1).height;
negative_image = parameters(1).negative_image;
maxIntensity = parameters(1).maxIntensity;

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
MinBrightnessBouton  = parameters(1).MinBrightnessBouton;
MaxBrightnessBouton  = parameters(1).MaxBrightnessBouton;
sigma_noise_bouton = parameters(1).sigma_noise_bouton;
minDistBetweenBoutons = parameters(1).minDistBetweenBoutons;

MinNbCircles = parameters(1).MinNbCircles;
MaxNbCircles = parameters(1).MaxNbCircles;
MinRadius = parameters(1).MinRadius;
MaxRadius = parameters(1).MaxRadius;
MinBrightnessCircles = parameters(1).MinBrightnessCircles;
MaxBrightnessCircles = parameters(1).MaxBrightnessCircles;
sigma_noise_circle = parameters(1).sigma_noise_circle;

end