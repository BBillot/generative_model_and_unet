function dE = distE(X,Y,Point)
dE = sqrt((X(:)-Point(1)).^2+(Y(:)-Point(2)).^2);
end