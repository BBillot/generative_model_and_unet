function AxonPoly = MakeAxonPoly(ControlPoints)

%creates a spline going trough all the ControlPoints

t = linspace(0,1,size(ControlPoints,2)); %vector going from 0 to 1 with n evenly spaced values (n=#column of ControlP)
AxonPoly = csapi(t, ControlPoints); %csapi=spline, creates the spline

end