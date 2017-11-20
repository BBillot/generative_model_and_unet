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
        intensities = randi([MinAxonIntensity+1,MaxAxonIntensity-1],[1,2]); %draw two numbers from intensity range
        MaxIntensity = max(intensities)/100;
        MinIntensity = min(intensities)/100;
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