function boutonsInfo = getInfoBoutons(height, width, AxonsGTPoints,variations,NBou,MinBouBrightness,MaxBouBrightness,thickness, InfoGTPoints,minDistBetweenBoutons,...
    NbImages, probBoutonInFirstImage, rowshift, colshift, finalHeight, finalWidth)

% This function generates the parameters necessary to draw circles
% representing synaptic boutons: center, radius, and brightness. It
% operates differently for the time series model, because boutons appear at
% different times. So in this case we also specify the image of apparition
% and the duration of a bouton, as well as the brightness of the bouton in
% each image.
% The results are returned in a cell format: 1st column=center,2nd=radius,
% 3rd=image of apparition, 4th=duration, 5th=brightnesses.

boutonsInfo = cell(NBou,11);
centers = [];

switch nargin
    
    case 10
        %type of boutons
        boutonsInfo(:,1) = mat2cell(randi([0,1],[NBou,1]),ones(1,NBou));
        Points = zeros(1,NBou);
        
        %get center, and affiliated information in the case of a TB
        for bou=1:NBou
            if boutonsInfo{bou,1} == 1
                bouton_ok = 1;
                while bouton_ok %ie until the center is in the image range
                    
                    idx = randi([2,size(AxonsGTPoints,2)-1]); %pick the id of a GT Point
                    Points(bou) = idx; %store this id
                    point = AxonsGTPoints(:,idx); %store the point
                    thi = floor(thickness(InfoGTPoints(3,idx)))+1; %thickness of the corresponding axon
                    rho = thi*(2.1+1*rand(1)); %distance bewteen the gt point and the center of the tb bouton
                    thetamin = asin(2*thi/rho); %min rotation angle possible (for the center not overlapping the axon)
                    theta = thetamin+(pi-2*thetamin)*rand(1); %pick rotation angle
                    next_point = getNextPoint(AxonsGTPoints,idx,InfoGTPoints); %pick one of the two neighbour gt point
                    R = [cos(theta), -sin(theta); sin(theta), cos(theta)]; %rotation matrix
                    new_center = round(point+rho/sqrt(sum((next_point-point).^2))*R*(next_point-point)); %center of the tb bouton
                    
                    %check if bouton is far enough from the existing ones
                    if (bou==1 || min(distE(centers(1,:),centers(2,:),new_center)) > minDistBetweenBoutons)
                        
                        if (new_center(1)>0 && new_center(1)<=height && new_center(2)>0 && new_center(2)<=width)
                            boutonsInfo{bou,2} = new_center; %store new center
                            centers = [centers,new_center]; %update collection of bouton centers
                            boutonsInfo{bou,7} = [point, next_point]; %store the two points used to calculate the center
                            boutonsInfo{bou,8} = [variations(idx),thi]; %store axon's intensity and thickness
                            
                            % extract new frame defined by GTPoint and center of bouton
                            top_left = [max(1,floor(min(point(1),new_center(1))));max(1,floor(min(point(2),new_center(2))))];
                            bottom_right = [min(height,ceil(max(point(1),new_center(1))));min(width,ceil(max(point(2),new_center(2))))];
                            new_height = bottom_right(1)-top_left(1)+1;
                            new_width = bottom_right(2)-top_left(2)+1;
                            
                            %pick a point between the gt point and the center of the bouton
                            interPoint = [1+(new_height-1)*rand(1);1+(new_width-1)*rand(1)];
                            boutonsInfo{bou,9} = [top_left,bottom_right];
                            boutonsInfo{bou,10} = interPoint;
                            boutonsInfo{bou,11} = [new_height; new_width];

                            bouton_ok = 0;
                            
                        end
                    end
                end
            else % if not a tb bouton
                centerOK = 1;
                while centerOK %redraw the center if it's too close to the other centers
                    idx = randi(size(AxonsGTPoints,2));
                    new_center = round(AxonsGTPoints(:,idx));
                    if (bou == 1 || min(distE(centers(1,:),centers(2,:),new_center)) > minDistBetweenBoutons)
                        centerOK = 0;
                    end
                end
                Points(bou) = idx;
                boutonsInfo{bou,2} = new_center;
                centers = [centers, new_center]; %update collection of bouton centers
            end
        end
        %radius
        boutonsInfo(:,3) = num2cell((floor(thickness(InfoGTPoints(3,Points)))+1)');
        % bouton brightness
        moy = randi([MinBouBrightness+1,MaxBouBrightness-1],NBou,1)/100;
        boutonsInfo(:,6) = num2cell(moy);
        
    case 16
        %type of boutons
        boutonsInfo(:,1) = mat2cell(randi([0,1],[NBou,1]),ones(1,NBou));
        Points = zeros(1,NBou);
        %get center, and affiliated information in the caes of a TB
        for bou=1:NBou
            if boutonsInfo{bou,1} == 1 %ie if this is a TB bouton
                bouton_ok = 1;
                while bouton_ok
                    
                    idx = randi([2,size(AxonsGTPoints,2)-1]);
                    Points(bou) = idx; %select index of a GT Point
                    point = AxonsGTPoints(:,idx,:); %gets the GT point
                    thi = floor(thickness(InfoGTPoints(3,idx)))+1; %gets radius of the bouton = thickness of axon
                    rho = thi*(2.1+1*rand(1)); %distance to the TB bouton
                    thetamin = asin(2*thi/rho);
                    theta = thetamin+(pi-2*thetamin)*rand(1); %draw angle of rotation
                    next_point = getNextPoint(AxonsGTPoints,idx,InfoGTPoints);
                    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
                    new_center = round(point(:,:,1)+rho/sqrt(sum((next_point(:,:,1)-point(:,:,1)).^2))*R*(next_point(:,:,1)-point(:,:,1)));
                    for i=2:NbImages
                            new_center = [new_center,round(point(:,:,i)+rho/sqrt(sum((next_point(:,:,i)-point(:,:,i)).^2))*R*(next_point(:,:,i)-point(:,:,i)))];
                    end
                    if (all(new_center(1,:)>rowshift) && all(new_center(1,:)<=rowshift+finalWidth) && ...
                        all(new_center(2,:)>colshift) && all(new_center(2,:)<=colshift+finalHeight) && ...
                        (bou==1 || min(distE(centers(1,:),centers(2,:),new_center)) > minDistBetweenBoutons))
                        
                        new_center = reshape(new_center,[2,1,NbImages]);
                        boutonsInfo{bou,2} = new_center;
                        centers = [centers,new_center(:,:,1)];
                        boutonsInfo{bou,7} = [point, next_point];
                        boutonsInfo{bou,8} = [variations(idx),thi];
                        
                        % frame defined by GTPoint and center of bouton
                        top_left = max(1,floor(min([point, new_center],[],2)));
                        bottom_right = floor(max([point, new_center],[],2));
                        bottom_right(1,:,:) = min(bottom_right(1,:,:),height); bottom_right(2,:,:) = min(bottom_right(2,:,:),width);
                        new_height = bottom_right(1,:,:)-top_left(1,:,:)+1;
                        new_width = bottom_right(2,:,:)-top_left(2,:,:)+1;
                        
                        %pick a point between the gt point and the center of the bouton
                        interPoint = [1+(new_height-1)*rand(1);1+(new_width-1)*rand(1)];
                        boutonsInfo{bou,9} = [top_left,bottom_right];
                        boutonsInfo{bou,10} = interPoint;
                        boutonsInfo{bou,11} = [new_height; new_width];
                        
                        bouton_ok = 0;
                    end
                    
                end
            else
                bouton_ok = 1;
                while bouton_ok
                    idx = randi(size(AxonsGTPoints,2));
                    Points(bou) = idx;
                    points = round(AxonsGTPoints(:,idx,:));
                    if (all(points(1,:,:)>rowshift) && all(points(1,:,:)<=rowshift+finalWidth) && ...
                        all(points(2,:,:)>colshift) && all(points(2,:,:)<=colshift+finalHeight) && ...
                        (bou==1 || min(distE(centers(1,:),centers(2,:),points(:,:,1))) > minDistBetweenBoutons))
                            boutonsInfo{bou,2} = points;
                            centers = [centers,points(:,:,1)];
                            bouton_ok = 0;
                    end
                end
            end
        end
        %radius
        boutonsInfo(:,3) = num2cell((floor(thickness(InfoGTPoints(3,Points)))+1)');
        %image of apparition and duration of a bouton
        boutonsInfo(:,4:5) = num2cell(selection(NbImages,NBou,probBoutonInFirstImage));
        %brightness of each bouton
        moy = randi([MinBouBrightness+1,MaxBouBrightness-1],NBou,1)/100;
        for bou=1:NBou
            up = randi([0,1]);
            if up
                ma = moy(bou);
                while ma==moy(bou)
                    ma = moy(bou) + (MaxBouBrightness/100-moy(bou))*rand;
                end
                brightness = moy(bou):(ma-moy(bou))/(boutonsInfo{bou,5}-1):ma;
            else
                mi = moy(bou);
                while mi==moy(bou)
                    mi = MinBouBrightness/100 + (moy(bou)-MinBouBrightness/100)*rand;
                end
                brightness = moy(bou):-(moy(bou)-mi)/(boutonsInfo{bou,5}-1):mi;
            end
            boutonsInfo{bou,6} = brightness;
        end
        
        
end

end

function next_point = getNextPoint(Points,idx_point,InfoGTPoints)

upordown=randi(1);

if upordown
    if InfoGTPoints(3,idx_point)==InfoGTPoints(3,idx_point+1)
        next_point = Points(:,idx_point+1,:);
    else
        next_point = Points(:,idx_point-1,:);
    end
elseif ~upordown
    if InfoGTPoints(3,idx_point)==InfoGTPoints(3,idx_point+1)
        next_point = Points(:,idx_point-1,:);
    else
        next_point = Points(:,idx_point+1,:);
    end
end

end