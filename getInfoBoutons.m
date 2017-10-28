function boutonsInfo = getInfoBoutons(AxonsGTPoints,NBou,MinBouBrightness,MaxBouBrightness,thickness)

NbImage = randi([4,5]);
boutonsInfo = zeros(NBou,6);
Points = randi(length(AxonsGTPoints),[1,NBou]);
probBoutonInFirstImage = 0.6;

% center of boutons
boutonsInfo(:,1:2) = round([AxonsGTPoints(1,Points);AxonsGTPoints(2,Points)])';
% radius
boutonsInfo(:,3) = (floor(thickness(AxonsGTPoints(5,Points)))+1)'; 
% image of apparition and duration of a bouton
boutonsInfo(:,4:5) = selection(NbImage,NBou,probBoutonInFirstImage);
% brightness of each bouton
boutonsInfo(:,6) = randi([MinBouBrightness,MaxBouBrightness],NBou,1)/100;

%     BouBrightness = randi([MinBouBrightness,MaxBouBrightness])/100;
%     %radius = randi([MinBouRadius,MaxBouRadius]);
%     Point = randi(length(AxonsGTPoints));
%     center = round([AxonsGTPoints(1,Point),AxonsGTPoints(2,Point)]);
%     radius = floor(thickness(AxonsGTPoints(5,Point)))+1;
%     %dev = randi([-floor(thickness(AxonsGTPoints(3,Point))),floor(thickness(AxonsGTPoints(3,Point)))]);
%     dev = 0;
%     center = min(max(center+dev,1),width);

end