function [dist,rowInf,rowSup,colInf,colSup] = ...
    drawCells(AxonsPatch, radius, SelectionPixel, brightness, height, width, sigma_noise_circle)


NbImages = size(AxonsPatch,3);
cradius = ceil(radius/2);
h = radius+cradius;

%get all the locations of the noise sources
NSources = 5;
rowNoiseSources=[h+1, h+1+randi([-ceil(radius/2)+1,ceil(radius/2)-1],1,NSources-1)];
colNoiseSources=[h+1, h+1+randi([-ceil(radius/2)+1,ceil(radius/2)-1],1,NSources-1)];

% sigma to make gaussian profile reach 5% of its peak at the radius
v = sqrt(-radius^2/(2*log(0.05/brightness)));

% gets the pixel distances to the center of the cell and define points out
% the circle
dist=Inf*ones(2*h+1);
[X,Y] = meshgrid(1:2*h+1,1:2*h+1);
for i=1:NSources
    dist = min(dist,sqrt((X(:,:)-rowNoiseSources(i)).^2+(Y(:,:)-colNoiseSources(i)).^2));
end
dist(dist>radius) = Inf;

%convolve the obtained matrix with gaussian mask, to deform the image
MaskSize = ceil(radius*0.85);
g2 = fspecial('gaussian',MaskSize,v);
dist = conv2(dist,g2,'same');

% add noise to the matrix by resetting randomly picked pixel to radius dist
SelectionMatrix = randi(SelectionPixel,2*h+1,2*h+1);
dist(SelectionMatrix==SelectionPixel & dist<Inf) = radius;

%adds white noise to the circle
dist = dist+sigma_noise_circle*randn(2*h+1);

%gets intensity out of distance
dist = VaryingIntensityWithDistance(dist,'circle','gauss',v,0,brightness);

%remove zero rows and columns
dist(~any(dist,2),:) = []; dist(:,~any(dist,1)) = [];

sz = size(dist);
cross = 1;

while cross
    
    %top right corner of the circle
    topr = [randi([-ceil(cradius),height]), randi([-ceil(cradius),width])];
    
    %boundaries of the inserted cell
    rowInf = max(topr(1),1); rowSup = min(topr(1)+sz(1)-1,height);
    colInf = max(topr(2),1); colSup = min(topr(2)+sz(2)-1,width);
    
    %binary masks to check overlapping between axons and the cell
    amask = AxonsPatch(rowInf:rowSup,colInf:colSup,:);
    amask = amask>0;
    cmask = dist>0;
    
    %crop the cell parts that are outside of the image
    [X,Y] = meshgrid(topr(1):topr(1)+sz(1)-1,topr(2):topr(2)+sz(2)-1);
    cmask(:,~any(Y>0,2)) = []; cmask(~any(X'>0,2),:) = [];
    cmask(:,~any(Y<=height,2)) = []; cmask(~any(X'<=width,2),:) = [];
    cmask = repmat(cmask,[1,1,NbImages]);
    
    %check any overlapping bewteen axons and cell
    if max(max(max(amask+cmask)))<2
        dist(:,~any(Y>0,2)) = []; dist(~any(X'>0,2),:) = [];
        dist(:,~any(Y<=height,2)) = []; dist(~any(X'<=width,2),:) = [];
        cross =0;
    end
    
end