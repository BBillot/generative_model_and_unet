clear
close all;

a = vertcat(1:20,1:20); %integer diagonal
b = vertcat(1.5:20.5,1.5:20.5); %shifted diagonal from 0.5
c = vertcat(1:0.5:20,(1:0.5:20)+cos(0:12*pi/38:12*pi)); %points oscilating around the GT Points

%plot the two distributions of points
figure;
imagesc(zeros(21)); colormap(gray); hold on;
for i=1:size(a,2)
    plot(a(1,i),a(2,i),'r*'); hold on; %gt points in red
end
for i=1:size(c,2)
    plot(c(1,i),c(2,i),'b+'); hold on; %tracking points in blue
end
hold off;

%compute tracking accuracy
tracking_accuracy = getTrackingAccuracy(a,c,3);