function Patch = noise (Patch,sigmawn,lambda,height,width)

% this function takes a clean patch as input. It models all the noise
% occuring the acquisition procedure (optic blurring, photon emmissions,
% electronic noise). Its output is a grayscale image with values between 0
% and 255.

sigma1 = 0.1;
sigma2 = 6;

size1 = 2;
size2 = 50;

Patch = floor(Patch*255/max(max(max(Patch))));
Poisson = poissrnd(lambda,height,width);
Gauss = sigmawn * randn(height,width);
Oblur1 = fspecial('gaussian', size1, sigma1);
Oblur2 = 25*fspecial('gaussian', size2, sigma2);

for im=1:size(Patch,3)
    Patch(:,:,im) = imfilter(Patch(:,:,im),Oblur1,'replicate') + imfilter(Poisson,Oblur2,'replicate') + Gauss;
end
Patch(Patch<0) = 0;
Patch = floor(Patch*255/max(max(max(Patch))));

end