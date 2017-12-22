function [variation, gapindices] = makeVariation(startVariation,profileType,NSplinePoints,MinAxonIntensity,...
    MaxAxonIntensity,MinPeriod,MaxPeriod,MinGapSize,MaxGapSize)

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

%add gap to the axons
if MaxGapSize >0
    gapsize = randi([MinGapSize,MaxGapSize]);
    [variation, gapindices] = makeGap(variation,gapsize);
end

end

function [variation, gapindices] = makeGap(variation,gapsize)

% This function selects a point of the variation vector and set its value
% to zero. On each side of this point the variations go back linearly to
% the value they had originally.

% select an index that will be set to zero
idx= randi(length(variation));

if idx >= gapsize && idx <= length(variation)-gapsize
    
    gapindices = max(idx-gapsize,1)+1:min(idx+gapsize,length(variation))-1;
    
    % mofify the part just before the selected index
    variation(max(idx-gapsize,1):idx) = ...
        variation(max(idx-gapsize,1)) : -variation(max(idx-gapsize,1))/min(gapsize,idx-1) : 0;
    
    % mofify the part just after the selected index
    variation(idx:min(idx+gapsize,length(variation))) = ...
        0 : variation(min(idx+gapsize,length(variation)))/min(gapsize,length(variation)-idx) : variation(min(idx+gapsize,length(variation)));
    
elseif idx == 1
    
    gapindices = 1:gapsize;
    
    variation(1:gapsize+1) = 0 : variation(gapsize)/gapsize : variation(gapsize);
    
elseif idx == length(variation)
    
    gapindices = length(variation)-gapsize+1:length(variation);
    
    variation(end-gapsize:end) = variation(end-gapsize) : -variation(end-gapsize)/gapsize : 0;
    
elseif idx < gapsize
    
    gapindices = 1:min(idx+gapsize,length(variation))-1;
    
    variation(1:idx) = ...
        variation(1) -(gapsize-idx+1)*variation(1)/gapsize: -(variation(1) -(gapsize-idx+1)*variation(1)/gapsize)/(idx-1) : 0;
    
    variation(idx:min(idx+gapsize,length(variation))) = ...
        0 : variation(min(idx+gapsize,length(variation)))/min(gapsize,length(variation)-idx) : variation(min(idx+gapsize,length(variation)));
    
elseif idx > length(variation) - gapsize
    
    gapindices = max(idx-gapsize,1)+1:length(variation);
    
    variation(max(idx-gapsize,1):idx) = ...
        variation(max(idx-gapsize,1)) : -variation(max(idx-gapsize,1))/min(gapsize,idx-1) : 0;
    
    variation(idx:length(variation)) = ...
        0 : (variation(end)-(gapsize+idx-length(variation))*variation(end)/gapsize)/(length(variation)-idx) : variation(end) - (gapsize+idx-length(variation))*variation(end)/gapsize;
end

end