function tracking_accuracy = getTrackingAccuracy(gtpoints,tr_points,window)

% This function calculates the average distance between a set of points
% resulting from a tracking procedure and a set of ground truth points. For
% each decoded point we calculate the distance to the ground truth in a
% given area (window). We only keep the two closest ground truth points and
% use them to calculate the distance.

% The distance is calculated by first getting the sine of the angle between
% the decoded point and the two nearest GT Points (by using the cross
% product definition) and then by applying a simple trigonometric relation.

tracking_accuracy = 0;

for i=1:size(tr_points,2)
   tr_point = tr_points(:,i); % ith tracking point
   % get the indeices of the GT points around this point
   indices = gtpoints(1,:)>tr_point(1)-window & gtpoints(1,:)<tr_point(1)+window & ...
       gtpoints(2,:)>tr_point(2)-window & gtpoints(2,:)<tr_point(2)+window;
   close_gtpoints = gtpoints(:,indices); % get the actual GT points
   dist = sqrt((close_gtpoints(1,:)-tr_point(1)).^2+(close_gtpoints(2,:)-tr_point(2)).^2); %dist between selected points and tracking point 
   [~ , ind] = sort(dist); 
   ind = ind(1:2); %get the two closest points
   d1 = [(tr_point-close_gtpoints(:,ind(1)));0]; %vector bewteen tracking point and closest gt point
   d2 = [(close_gtpoints(:,ind(2))-close_gtpoints(:,ind(1)));0]; %vector between two closest gt points
   d = norm(cross(d1,d2))/norm(d2); %distance between tracking point and axon
   tracking_accuracy = tracking_accuracy + d; %add all the distances (all positive)
end

tracking_accuracy = tracking_accuracy/size(tr_points,2); %average the total distance by the number of steps

end