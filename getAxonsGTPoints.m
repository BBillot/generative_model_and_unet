function [AxonAxisGT] = getAxonsGTPoints(AxonsPoly,npoints)

% This function exctracts points from the spline

tt = linspace(0,1,npoints);
AxonAxisGT = fnval(AxonsPoly,tt); %find the value of the spline for all values of tt
AxonPolyDer = fnder(AxonsPoly,1); % differentiates VesselPoly
AxonDirGT = fnval(AxonPolyDer,tt); %find the values of the derivative at the spline points

end