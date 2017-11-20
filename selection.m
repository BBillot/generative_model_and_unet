function imageOfApparition = selection(NbImage,NBou,probBoutonInFirstImage)

% This function generates the image of apparition and the duration of each
% bouton. The probability of appearing on the first image is set by the
% corresponding input. The prob of appearing on the other image is uniform.
% The duration of a bouton is randomly picked between the image of app and
% the total number of images.

a = rand(NBou,1);
complement = 1-probBoutonInFirstImage;
b = complement/NbImage:complement/NbImage:complement;
imageOfApparition = zeros(NBou,2); %first row is the image of apparition, second is the duration of a bouton

for i=2:NBou
    if a(i)>=complement %if a(i) above complement the ith bouton appears in the 1st image
        imageOfApparition(i,1) = 1;
    else %if not, then we check in which part of b a(i) has fallen
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
        imageOfApparition(i,2) = randi([2,max(2,imageOfApparition(i,2))]);
    end
end

end