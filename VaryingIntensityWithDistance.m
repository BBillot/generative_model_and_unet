function I = VaryingIntensityWithDistance(d,StructureType,IntProfileType,sigma_spread,AxonsVariations,brightness)

% Function to take an n-dimensional array of distances to centreline (d)
% and to return an array, I, of the same size and dimensions of d in which
% the values in the array are a function of d.
% Current options include a Butterworth, a Gaussian and a flat profile.
% We differenciate two cases: intensity along an axon that varies according
% AxonVariations, and intensity for circles.


switch StructureType
    
    case {'axons'}
        switch lower(IntProfileType)
            case {'butter','butterworth'}
                I = 1./(1+(d/2).^4); % 4th order Butterworth, radius of vessel of around 2
            case {'flat'}
                I = abs(d)<2;
            case {'gaussian','gauss'}
                I = exp(-d.^2/(2*sigma_spread^2))/sqrt(2*pi*sigma_spread^2).*AxonsVariations;
        end
        
    case {'circle'}
        switch lower(IntProfileType)
            case {'butter','butterworth'}
                I = 1./(1+(d/2).^4); % 4th order Butterworth, radius of vessel of around 2
            case {'flat'}
                I = abs(d)<2;
            case {'gaussian','gauss'}
                I = exp(-d.^2/(2*sigma_spread^2))*brightness;
        end
        
        
end


end