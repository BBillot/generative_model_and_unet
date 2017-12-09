function [width,height,negative_image,maxIntensity,...
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