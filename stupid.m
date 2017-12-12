X=makeStructuredNoise(128,128, 5, 4, 2, 4, 0.1, 2, 5);
figure; imagesc(X); colormap(gray);

for m=4:10
    MaskSize = ceil(radius*m/10);
    g2 = fspecial('gaussian',MaskSize,v);
    dist2 = conv2(dist,g2,'same');
    figure; imagesc(dist2); colormap(gray);
end