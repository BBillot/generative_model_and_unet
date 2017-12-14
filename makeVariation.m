function variation = makeVariation(startVariation,profileType,NSplinePoints,MinAxonIntensity,...
    MaxAxonIntensity,MinPeriod,MaxPeriod)

% This function generates vectors with values evolving according to a
% given profile. The length of this vector is the same as the number of
% spline points in a branch. Indeed each spline points will be associated
% with a multiplicative coefficient for its intensity.

if startVariation>1
    disp('variation>1');
end

switch profileType
    
    case {'constant'}
        variation = startVariation*ones(1,NSplinePoints);
        
    case {'linear'} %linear variation of intensity along the branch.
        upordown = randi(1); %intensity should increase or decrease from its starting point: 1=up 0=down
        if upordown
            MaxIntensity = startVariation + (MaxAxonIntensity - min(startVariation,MaxAxonIntensity-0.01)) * rand(1);
            if startVariation~=MaxIntensity
                variation = startVariation:(MaxIntensity-startVariation)/(NSplinePoints-1):MaxIntensity;
            else
                variation = startVariation*ones(1,NSplinePoints);
            end
            disp(startVariation); disp(MaxIntensity);
        else
            MinIntensity = startVariation - (max(startVariation,MinAxonIntensity+0.01) - MinAxonIntensity) * rand(1);
            if startVariation~=MinIntensity
                variation = startVariation:-(startVariation-MinIntensity)/(NSplinePoints-1):MinIntensity;
            else
                variation = startVariation*ones(1,NSplinePoints);
            end
            disp(startVariation); disp(MinIntensity);
        end
        
        
    case {'cosine'} %cosine variation of intensity along a branch
        NPeriods = MinPeriod + (MaxPeriod-MinPeriod) * rand(1);
        MaxIntensity = startVariation + (MaxAxonIntensity - min(startVariation,MaxAxonIntensity-0.01)) * rand(1);
        MinIntensity = startVariation - (max(startVariation,MinAxonIntensity+0.01) - MinAxonIntensity) * rand(1);
        while MinIntensity >= MaxIntensity
            intensities = MinAxonIntensity+0.01+(MaxAxonIntensity-MinAxonIntensity-0.02)*rand(1,2); %draw two numbers from intensity range
            MaxIntensity = max(intensities);
            MinIntensity = min(intensities);
        end
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