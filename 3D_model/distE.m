function dE = distE(X,Y,Z,Point)
dE = sqrt((X(:)-Point(1)).^2+(Y(:)-Point(2)).^2+(Z(:)-Point(3)).^2);
end