function boutonsInfo = getInfoBoutons(AxonsGTPoints,NBou,MinBouBrightness,MaxBouBrightness,thickness,NbImages)

%boutonsInfo = zeros(NBou,6);
boutonsInfo = cell(NBou,5);
Points = randi(length(AxonsGTPoints),[1,NBou]);
probBoutonInFirstImage = 0.4;

% boutonsInfo(:,1:2) = round([AxonsGTPoints(1,Points);AxonsGTPoints(2,Points)])';
% boutonsInfo(:,3) = (floor(thickness(AxonsGTPoints(5,Points)))+1)';
% boutonsInfo(:,4:5) = selection(NbImages,NBou,probBoutonInFirstImage);
% boutonsInfo(:,6) = randi([MinBouBrightness,MaxBouBrightness],NBou,1)/100;

%center of boutons
boutonsInfo(:,1) = mat2cell(round([AxonsGTPoints(1,Points);AxonsGTPoints(2,Points)])',ones(1,NBou));
%radius
boutonsInfo(:,2) = num2cell((floor(thickness(AxonsGTPoints(5,Points)))+1)'); 
%image of apparition and duration of a bouton
boutonsInfo(:,3:4) = num2cell(selection(NbImages,NBou,probBoutonInFirstImage));
%brightness of each bouton
moy = randi([MinBouBrightness+1,MaxBouBrightness-1],NBou,1)/100;
for bou=1:NBou
    up = randi([0,1]);
    if up
        ma = moy(bou);
        while ma==moy(bou)
            ma = moy(bou) + (MaxBouBrightness/100-moy(bou))*rand;
        end
        brightness = moy(bou):(ma-moy(bou))/(boutonsInfo{bou,4}-1):ma;
    else
        mi = moy(bou);
        while mi==moy(bou)
            mi = MinBouBrightness/100 + (moy(bou)-MinBouBrightness/100)*rand;
        end
        brightness = moy(bou):-(moy(bou)-mi)/(boutonsInfo{bou,4}-1):mi;
    end
    
    boutonsInfo{bou,5} = brightness;
end

%     BouBrightness = randi([MinBouBrightness,MaxBouBrightness])/100;
%     %radius = randi([MinBouRadius,MaxBouRadius]);
%     Point = randi(length(AxonsGTPoints));
%     center = round([AxonsGTPoints(1,Point),AxonsGTPoints(2,Point)]);
%     radius = floor(thickness(AxonsGTPoints(5,Point)))+1;
%     %dev = randi([-floor(thickness(AxonsGTPoints(3,Point))),floor(thickness(AxonsGTPoints(3,Point)))]);
%     dev = 0;
%     center = min(max(center+dev,1),width);

end