%% Compute the roll-off factor

im = imread('./input/IMG_0110.JPG');

% Extract the luminance
imxyz = applycform(im, makecform('srgb2lab'));
imY = imxyz(:,:,1);

load('./MATFiles/correctionMask.mat')

imY = correctionMask.*double(imY);
imxyz(:,:,1) = uint8(imY);
imCorr = applycform(imxyz, makecform('lab2srgb'));
imshow(imCorr)
imwrite(imCorr, 'afterCorrection.jpg');

