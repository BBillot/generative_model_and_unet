function [AxonAxisGT] = getAxonsGTPoints(AxonsPoly,npoints)

% This function exctracts points from the spline

tt = linspace(0,1,npoints);
AxonAxisGT = fnval(AxonsPoly,tt); %find the value of the spline for all values of tt

end