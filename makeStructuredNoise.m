function [ X ] = makeStructuredNoise(M,N, MaxClusters, MaxSourcesPerCluster, minsss, maxsss, wns, cns, snk)
% Function to generate Gaussian blobs using mixtures of Gaussians arranged
% in clusters.  Done in such a way that depth-based blurring can be
% performed in future versions.
% Random images contain random numbers of clusters (up to a max), and each
% cluster can have a random number of blurry point sources. 
% making minsss large will make the number of 
%
% Inputs:
%      M,N (integer): row and column numbers for the image size
%      NSourcesPerCluster (integer > 1): max number of blobs (sources) per cluster
%      MaxClusters (integer > 1): max number of clusters 
%      minsss (float>0):  sets min of size distributon of coherent noise sources
%      maxsss (float>minsss): sets max size distribution of coherent noise sources
%      wns (float>=0): additive white noise sigma
%      cns (float>=0): additive coloured noise sigma
%      snk (0,1,2): structured noise kernel option [NOT USED YET]
%
% v 0.1  AAB 28th Nov 2017
% Some examples:
%  X=makeStructuredNoise(128,128, 5, 4, 2, 4, 0.1, 2, 5);
%  X=makeStructuredNoise(128,128, 5, 4, 2, 4, 0.01, 2, 5);
%  X=makeStructuredNoise(128,128, 5, 4, 2, 4, 0.1, 0, 1);

if nargin<9
    disp('Error:');
    disp(['    ',mfilename,': must supply all inputs']);
    disp('    Usage: X=makeStructuredNoise(M,N, MaxClusters, MaxSourcesPerCluster, minsss, maxsss, wns, cns, snk)');
    narginchk(9,9);
end

if maxsss<=minsss 
    error('Must have maxsss>minsss in arguments') 
end;

% number of clusters
NC = randi(MaxClusters,1);

% the number of sources for each cluster
SpC = randi(MaxSourcesPerCluster,[1,NC]);

if cns==0 %if no coloured noise
    X = makecleanimage(M,N,NC,SpC,minsss,maxsss);
    X = X/max(X(:)); %image between 0 and 1
    if wns>0 %if white noise
        X = X+wns*randn(M,N); %add white noise
        X = X.*(X>0); %keep only positive values
    end
else %if coloured noise
    X = makecleanimage(M,N,NC,SpC,minsss,maxsss);
    X = X/max(X(:)); %pixelvalues bewteen 0 and 1
    nf = makecolourednoisefield(M,N,cns,min(snk,1));
    X = X+nf;
    
    if wns>0 %if white noise
        X = X+wns*randn(M,N); % add white noise
        X = X.*(X>0); %keep positive values
    end
end
end

function nf=makecolourednoisefield(M,N,cns,snk)
nf = cns*randn(M,N);
nf = conv2(nf,fspecial('gaussian',15,3),'same');
end
function X=makecleanimage(M,N,NC,SpC,minsss,maxsss)
CP = zeros(M,N,NC); %diff empty matrix for each noise cluster
[xc,yc] = drawsamplelocations(ones(M,N),NC); %get noise clusters' middle

for c = 1:NC
    CP(:,:,c)=makeclusterplane(M,N,xc(c),yc(c),SpC(c),minsss,maxsss);
end

X = sum(CP,3); %gather all clusters in one image

end

function CP=makeclusterplane(M,N,xc,yc,NSources,minsss,maxsss)
SP = zeros(M,N,NSources); % will hold individual blurred point sources

% We need to place samples in the vicinity of xc,yc.... but where exactly?
% Solution, draw samples uniformly in a circle centrerd on xc,yc...
% can alter if needed...
sampleregion = zeros(M,N); 
sampleregion(max(floor(xc),1),max(floor(yc),1))=1; %put a 1 at center of cluster
se = strel('disk',ceil(3*maxsss+1)); %get circle around it
sampleregion=imdilate(sampleregion,se); %put 1s in this circle
[xs,ys] = drawsamplelocations(sampleregion,NSources); %pick individual noise sources in this circle

for ps = 1:NSources
    sigma=(maxsss-minsss)*rand(1)+minsss; %noise
    SP(:,:,ps) = makeblurredpointsource(M,N,xs(ps),ys(ps),sigma);
end

CP=sum(SP,3);
end

function psp = makeblurredpointsource(M,N,x,y,sigma)
% Make a point source in the form of a complete clean plane which can
% then be summed as in a mixture of Gaussians, possibly of different
% sigmas. 
P = zeros(M,N);
P(round(y),round(x)) = 0.5*(1+rand(1)); % nudging them into visibility with 0.5....

% Now for the Gaussian blur
MaskSize = ceil(4*sigma+1); %size of the gausian filter

g2 = fspecial('gaussian',MaskSize,sigma); %gaussian filter

psp = conv2(P,g2,'same'); %create circle with gaussian intensity decrease
end

function [xlocs,ylocs]=drawsamplelocations(IM,NSamples)
% Given an importance mask in the form of a single channel image (IM)
% this draws samples according to the distribution suggested by IM.
% Values in IM with higher intensity will be more likely to contain 
% samples, those with lower intensity are less likely to have samples
% Locations which have a value of 0 are quite unlikely to have samples
% within them.
% Input is the scalar image, IM and the Number of samples (NSamples)
% outputs are x,y, vectors containing locations where samples are drawn

[M,N]=size(IM);
xlocs=zeros(1,NSamples);ylocs=zeros(1,NSamples);
% Turn the mask into a 1D PDF over location
pIM = IM(:)/sum(IM(:));

% Turn into CDF over 1D location (x)
cdfIM = cumsum(pIM);

% Draw uniform samples in [0,1]...
u = rand(1,NSamples);

% Look these up on the CDF curve y axis and find locations on the x
% axis; this - surprisingly, calculates the logical test
% u <= CDF(IM), creating a matrix in which the rows of each column 
% represents the entire (unravelled) image, and each column is the
% result of the test for a different random number, u (there are NSamples
% columns)
A=bsxfun(@le,u,cdfIM);

% The next code fragment finds the first location (row number) within each 
% column at which u<=CDF(IM); this represents a sample location in pixel
% space.
for n = 1:NSamples
    iloc=find(A(:,n),1,'first');
    [ylocs(n),xlocs(n)]=ind2sub([M,N],iloc);
end

end