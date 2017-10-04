%creation of the JSON file ('parameters.json') containing the parameters of
%the model. Modify the values of the parameters and then run the code


%%%%%%%%%%%%%%%%%%%%%% generation of the parameters %%%%%%%%%%%%%%%%%%%%%%%

% General parameters of the image
width = 64;                % Set Width of the image (integer)
height = 64;               % Set Height (integer)
negative_image = 0;        % 0=white axons on black background, 1=black axons on white background

% Set the different sources of noise
sigma_noise_min = 10;      % Set min gaussian white noise level (integer)
sigma_noise_max = 10;      % Set max gaussian white noise level (integer)
lambdaMin = 7;             % Set max Poisson noise level (integer)
lambdaMax = 7;             % Set min Poisson noise level (integer)

% Numbers of Axons and branches
MinAxons = 2;              % Set minimum number of axons in the image (integer)
MaxAxons = 2;              % Set maximum number of axons in the image (integer)
MinBran = 2;               % Set minimum number of branches for an axon (integer)
MaxBran = 2;               % Set maximum number of branches for an axon (integer)

% Shape of the axons
conformity = 0.99;         % Set how straight the axon is (real number between 0 and 0.9999)
MinThickness = 3;          % Set Min thickness of vessels (real number)
MaxThickness = 6;          % Set Max thickness of vessels (real number)
MinGapSize = 3;            % Set gap size (positive integer)
MaxGapSize = 7;            % if you don't want any gap set both to 0 (positive integer)

% Construction of axons
StepSize = 4;              % distance between each controlPoints. (real number)
NSplinePoints = 400;       % Number of points for the interpolation of the spline (integer)
crossingOK = 0;            % O=crossings allowed, 1=no crossing
straightBranching = 13;    % Distance from which overlapping is checked between mother branch and its daughter (real number)
SegmentationThreshold = 4.7; % Threshold for obtaining the true segmentation (set to Inf to get it all) (real number)

% Intensity of the axons
sigma_spread = 1;          % std deviation of the gaussian profile for axons (real number)
MinAxonIntensity = 60;     % Minimum level of intensity for an axon (integer between 0 and 100)
MaxAxonIntensity = 90;     % Maximum level of intensity for an axon (integer between 0 and 100)
MinPeriod = 0.1;           % Min spatial period for intensity variation along axons for a cosine profile (real number)
MaxPeriod = 2;             % Max spatial period for intensity variation along axons for a cosine profile (real number)
AxonProfile = 'cosine';    % Type of intensity variations along a mother branch (constant, linear or cosine)
BranchProfile = 'cosine';  % Type of intensity variations along a daughter branch (constant, linear or cosine)
sigma_noise_axon = 0.055;  % Set the white noise level for an axon (real number)

% Shape of the synaptic Boutons
MinNbBouton = 5;           % Set the minimum number of boutons (integer)
MaxNbBouton = 7;           % Set the maximum number of boutons (integer)
MinBouRadius = 3;          % Set the minimum radius of  the boutons (integer)
MaxBouRadius = 3;          % Set the maximum radius of  the boutons (integer)
MinBrightnessBouton = 30;  % Set the brightness of the boutons (integer between 0 and 100)
MaxBrightnessBouton = 40;  % Set the brightness of the boutons (integer between 0 and 100)
sigma_noise_bouton = 1;    % Set the noise level for the boutons  (real number)

% Shape of the circles
MinNbCircles = 6;          % Set the min number of circles in the image (integer)
MaxNbCircles = 9;          % Set the max number of circles in the image (integer)
MinRadius = 3;             % Minimum radius for a cell (integer)
MaxRadius = 20;            % Maximum radius for a cell (integer) 
CircleBrightness = 1;      % Set if we want bright cells (0/1)
MinBrightnessCircles = 20; % Minimum level of cell intensity (fine tuning) (integer between 0 and 100)
MaxBrightnessCircles = 30; % Maximum level of cell intensity (fine tuning) (integer between 0 and 100)
sigma_noise_circle = 1.3;  % Set white noise whithin a circle (real number)


%%%%%%%%%%%%%%%%%%%%%%%% creation of the structure %%%%%%%%%%%%%%%%%%%%%%%%

AxonParameters(1).width = width;
AxonParameters(1).height = height;
AxonParameters(1).negative_image = negative_image;

AxonParameters(1).sigma_noise_min = sigma_noise_min;
AxonParameters(1).sigma_noise_max = sigma_noise_max;
AxonParameters(1).lambdaMin = lambdaMin;
AxonParameters(1).lambdaMax = lambdaMax;

AxonParameters(1).MinAxons = MinAxons;
AxonParameters(1).MaxAxons = MaxAxons;
AxonParameters(1).MinBran = MinBran;
AxonParameters(1).MaxBran = MaxBran;

AxonParameters(1).conformity = conformity;
AxonParameters(1).MinThickness = MinThickness;
AxonParameters(1).MaxThickness = MaxThickness;
AxonParameters(1).MinGapSize = MinGapSize;
AxonParameters(1).MaxGapSize = MaxGapSize;

AxonParameters(1).StepSize = StepSize;
AxonParameters(1).NSplinePoints = NSplinePoints;
AxonParameters(1).crossingOK = crossingOK;
AxonParameters(1).straightBranching = straightBranching;
AxonParameters(1).SegmentationThreshold = SegmentationThreshold;

AxonParameters(1).sigma_spread = sigma_spread;
AxonParameters(1).MinAxonIntensity = MinAxonIntensity;
AxonParameters(1).MaxAxonIntensity = MaxAxonIntensity;
AxonParameters(1).MinPeriod = MinPeriod;
AxonParameters(1).MaxPeriod = MaxPeriod;
AxonParameters(1).AxonProfile = AxonProfile;
AxonParameters(1).BranchProfile = BranchProfile;
AxonParameters(1).sigma_noise_axon = sigma_noise_axon;

AxonParameters(1).MinNbBouton = MinNbBouton;
AxonParameters(1).MaxNbBouton = MaxNbBouton;
AxonParameters(1).MinBouRadius = MinBouRadius;
AxonParameters(1).MaxBouRadius = MaxBouRadius;
AxonParameters(1).MinBrightnessBouton = MinBrightnessBouton;
AxonParameters(1).MaxBrightnessBouton = MaxBrightnessBouton;
AxonParameters(1).sigma_noise_bouton = sigma_noise_bouton;

AxonParameters(1).MinNbCircles = MinNbCircles;
AxonParameters(1).MaxNbCircles = MaxNbCircles;
AxonParameters(1).MinRadius = MinRadius;
AxonParameters(1).MaxRadius = MaxRadius;
AxonParameters(1).CircleBrightness = CircleBrightness;
AxonParameters(1).MinBrightnessCircles = MinBrightnessCircles;
AxonParameters(1).MaxBrightnessCircles = MaxBrightnessCircles;
AxonParameters(1).sigma_noise_circle = sigma_noise_circle;


%%%%%%%%%%%%%%%%%%% saving the structure in a JSON file %%%%%%%%%%%%%%%%%%%

clearvars -except AxonParameters
savejson('',AxonParameters,'parameters_64x64_images.json');