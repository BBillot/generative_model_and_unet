function imageOfApparition = selection(NbImage,NBou,probBoutonInFirstImage)

a = rand(NBou,1);
firstImage = 1-probBoutonInFirstImage;
b = firstImage/NbImage:firstImage/NbImage:firstImage;
imageOfApparition = zeros(NBou,2);

for i=1:NBou
    if a(i)>=firstImage
        imageOfApparition(i,1) = 1;
    else
        for j=1:length(b)-1
            if a(i)<b(j)
                imageOfApparition(i,1) = j+1;
                break
            end
        end
    end
end
imageOfApparition(imageOfApparition(:,1)==0) = NbImage;
imageOfApparition(:,2) = NbImage-imageOfApparition(:,1)+1;
for i=1:NBou
    if imageOfApparition(i,2)-1>2
        imageOfApparition(i,2) = randi([2,max(2,imageOfApparition(i,2)-1)]);
    end
end

end