function boutonsInfo = getInfoBoutons(AxonsGTPoints,NBou,MinBouBrightness,MaxBouBrightness,thickness,NbImages,...
    probBoutonInFirstImage, rowshift, colshift, finalHeight, finalWidth, InfoGTPoints)

% This function generates the parameters necessary to draw circles
% representing synaptic boutons: center, radius, and brightness. It
% operates differently for the time series model, because boutons appear at
% different times. So in this case we also specify the image of apparition
% and the duration of a bouton, as well as the brightness of the bouton in
% each image.
% The results are returned in a cell format: 1st column=center,2nd=radius,
% 3rd=image of apparition, 4th=duration, 5th=brightnesses.

boutonsInfo = cell(NBou,5);


switch nargin
    case 5
        Points = randi(length(AxonsGTPoints),[1,NBou]);
        %center of boutons
        boutonsInfo(:,1) = mat2cell(round([AxonsGTPoints(1,Points);AxonsGTPoints(2,Points)])',ones(1,NBou));
        %radius
        boutonsInfo(:,2) = num2cell((floor(thickness(AxonsGTPoints(5,Points)))+1)');
        moy = randi([MinBouBrightness+1,MaxBouBrightness-1],NBou,1)/100;
        boutonsInfo(:,5) = num2cell(moy);
    case 12
        Points = zeros(1,NBou);
        for i=1:NBou
            Point = [-1;-1];
            while(Point(1)<rowshift || Point(1)>rowshift+finalWidth || Point(2)<colshift || Point(2)>colshift+finalHeight)
                Point_idx = randi(length(AxonsGTPoints));
                Point = [AxonsGTPoints(1,Point_idx,1);AxonsGTPoints(2,Point_idx,1)];
            end
            Points(i) = Point_idx;
        end
        
        %center of boutons
        boutonsInfo(:,1) = mat2cell(permute(round([AxonsGTPoints(1,Points,:);AxonsGTPoints(2,Points,:)]),[2,1,3]),ones(1,NBou));
        %radius
        boutonsInfo(:,2) = num2cell((floor(thickness(InfoGTPoints(3,Points)))+1)');
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
end

end