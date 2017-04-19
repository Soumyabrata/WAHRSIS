%% Compute the roll-off factor

im = imread('./input/IMG_0110.JPG');
load ./MATFiles/ocam_model_wahrsis1_bw_iter.mat

[centers,radii] = imfindcircles(im,[1450 1500], 'Sensitivity',0.99);
xCtr = centers(1,2); yCtr = centers(1,1); radius = radii(1);
xCtr = ocam_model_bw.xc; yCtr = ocam_model_bw.yc;
imshow(im);
viscircles(centers,radii); 



[maskY, maskX] = meshgrid(1:size(im,2), 1:size(im,1));
radMask = sqrt((maskX-xCtr).^2 + (maskY-yCtr).^2);
mask = radMask;
mask(radMask <= radius) = 1;
mask(radMask > radius) = 0;
mask = logical(mask);
 

%%

% Extract the luminance
imxyz = applycform(im, makecform('srgb2lab'));
imY = imxyz(:,:,1);

luminances = imY(mask);
luminances = luminances(1:100:end);
radii = radMask(mask);
radii = radii(1:100:end);

locX = maskX(mask);
locX = locX(1:100:end);
locY = maskY(mask);
locY = locY(1:100:end);

% to world coordinates
M = cam2world([locX' ; locY'], ocam_model_bw);
disth = sqrt(M(1,:).^2 + M(2,:).^2);
thetas = atan2d(disth, -M(3,:));

[radii, indxSort] = sort(radii);
luminances = luminances(indxSort);
thetas = thetas(indxSort);


%%

load ./MATFiles/model_params.mat 
scatter(radii, luminances, 'x');
xlim([0 radius])
ylim([0 255]);
grid on
xlabel('Distance from image center [pixels]');
ylabel('Luminance [0-255]');

%%

figure
[thetas, indxSort] = sort(thetas);
s_luminances = luminances(indxSort);
radii = radii(indxSort);

s_luminances = double(s_luminances);
s_luminances = s_luminances./max(s_luminances);
s_luminances = 1.0./s_luminances;

newradii = 1:radius;
newLum = interp1(radii, s_luminances, newradii);
newLum(isnan(newLum)) = 1;

lengthMA = 20;
correctionCoeff = imfilter(newLum', ones(lengthMA, 1)/lengthMA, 'replicate', 'same');

scatter(radii, s_luminances, 'x');
hold on
grid on
plot(newradii, correctionCoeff, 'r', 'LineWidth', 2.0);
xlabel('Distance from image center [pixels]');
ylabel('Correction coefficient');
xlim([0 radius])
ylim([0.5 2.5]);


%%

% ==========================================================

% For the thesis.
% Consider only less than 1300.
luminances = double(luminances);

consIndex = find(radii<1300) ;

consRadii = radii(consIndex);
consLumi = luminances(consIndex);

consThetas = thetas(consIndex);
figure('Position', [400, 250, 390, 300]);
scatter(consRadii, consLumi,'.'); hold on;


% Plot the equation
p1 = -1.365/(10^5);
p2 = -0.004006;
p3 = 235.8;

x_points = linspace(0,1300,1300);
y_points = p1.*(x_points.*x_points) + p2.*x_points + p3 ;
plot (x_points,y_points, 'r','LineWidth',2); hold on;

xlabel('Distance from image center [pixels] (r)','FontSize',12);
ylabel('Luminance [0-255] (L_w)','FontSize',12);
ylim([0 255]);
xlim([0 1350])
grid on ;
set(gca,'fontsize',12);

%%



figure('Position', [400, 250, 390, 300]);

cons2Index = find(radii<1300) ;

cons2_radii = radii(cons2Index);
cons2_s_luminances = s_luminances(cons2Index);


cons3Index = find(newradii<1300) ;
cons3_newradii = newradii(cons3Index);
cons3_correctionCoeff = correctionCoeff(cons3Index);
%cons2_newradii = newradii(cons2Index);
%cons2_correctionCoeff = correctionCoeff(cons2Index);

scatter(cons2_radii, cons2_s_luminances, 'x');
hold on
grid on
plot(cons3_newradii, cons3_correctionCoeff, 'r', 'LineWidth', 2.0);
xlabel('Distance from image center [pixels] (r)','FontSize',12);
ylabel('Correction coefficient','FontSize',12);
xlim([0 1350])
ylim([0.5 2]);

set(gca,'fontsize',12);



%%
figure
[ymask, xmask] = meshgrid(1:size(im,2), 1:size(im,1));
correctionMask = sqrt((xmask - xCtr).^2 + (ymask - yCtr).^2);

for i=1:size(correctionMask, 1)
    for j=1:size(correctionMask, 2)
        if correctionMask(i,j) > length(correctionCoeff)
            correctionMask(i,j) = 0;
        elseif correctionMask(i,j) < 1
            correctionMask(i,j) = 1;
        else
            correctionMask(i,j) = correctionCoeff(round(correctionMask(i,j)));
        end
    end
end

save('correctionMask.mat', 'correctionMask')

imY = correctionMask.*double(imY);
imxyz(:,:,1) = uint8(imY);
imCorr = applycform(imxyz, makecform('lab2srgb'));
imshow(imCorr)
imwrite(imCorr, 'afterCorrection.jpg');

