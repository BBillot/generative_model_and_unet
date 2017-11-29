function boutonsInfo = getInfoBoutons2(height, width, AxonsGTPoints,variations,NBou,MinBouBrightness,MaxBouBrightness,thickness, InfoGTPoints,...
    NbImages, probBoutonInFirstImage, rowshift, colshift, finalHeight, finalWidth)

% This function generates the parameters necessary to draw circles
% representing synaptic boutons: center, radius, and brightness. It
% operates differently for the time series model, because boutons appear at
% different times. So in this case we also specify the image of apparition
% and the duration of a bouton, as well as the brightness of the bouton in
% each image.
% The results are returned in a cell format: 1st column=center,2nd=radius,
% 3rd=image of apparition, 4th=duration, 5th=brightnesses.

boutonsInfo = cell(NBou,8);

switch nargin
    case 9
        %type of boutons
        boutonsInfo(:,1) = mat2cell(randi([0,1],[NBou,1]),ones(1,NBou));
        Points = zeros(1,NBou);
        for bou=1:NBou
            if boutonsInfo{bou,1} == 1
                bouton_ok = 1;
                while bouton_ok
                    idx = randi([2,size(AxonsGTPoints,2)-1]);
                    Points(bou) = idx;
                    point = round(AxonsGTPoints(:,idx));
                    thi = floor(thickness(InfoGTPoints(3,idx)))+1;
                    rho = thi*(2.1+1*rand(1));
                    thetamin = asin(2*thi/rho);
                    theta = thetamin+(pi-2*thetamin)*rand(1);
                    next_point = getNextPoint(AxonsGTPoints,idx,InfoGTPoints);
                    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
                    new_center = round(point+rho/sqrt(sum((next_point-point).^2))*R*(next_point-point));
                    if (new_center(1)>0 && new_center(1)<=height && new_center(2)>0 && new_center(2)<=width)
                        boutonsInfo{bou,2} = new_center;
                        boutonsInfo{bou,7} = [point, next_point];
                        boutonsInfo{bou,8} = [variations(idx),thi];
                        bouton_ok = 0;
                    end
                end
            else
                idx = randi(size(AxonsGTPoints,2));
                Points(bou) = idx;
                boutonsInfo{bou,2} = round(AxonsGTPoints(:,idx));                
            end
        end
        %radius
        boutonsInfo(:,3) = num2cell((floor(thickness(InfoGTPoints(3,Points)))+1)');
        moy = randi([MinBouBrightness+1,MaxBouBrightness-1],NBou,1)/100;
        boutonsInfo(:,6) = num2cell(moy);
    case 15
        Points = zeros(1,NBou);
        for i=1:NBou
            Point = [-1;-1];
            while(Point(1)<rowshift | Point(1)>rowshift+finalWidth | Point(2)<colshift | Point(2)>colshift+finalHeight)
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

function next_point = getNextPoint(Points,idx_point,InfoGTPoints)

upordown=randi(1);

if upordown
    if InfoGTPoints(3,idx_point)==InfoGTPoints(3,idx_point+1)
        next_point = Points(:,idx_point+1);
    else 
        next_point = Points(:,idx_point-1);
    end
elseif ~upordown
    if InfoGTPoints(3,idx_point)==InfoGTPoints(3,idx_point+1)
        next_point = Points(:,idx_point-1);
    else 
        next_point = Points(:,idx_point+1);
    end
end
    
end