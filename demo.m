%% Read the image
img = imread('inputs/demo.jpg');
% img = rgb2gray(img);

%% MatPencil(img, ks, width, dirNum, gammaS, gammaI, theta, pencil_stroke, sm_kr, group_num, avg_ks)
I = MatPencil(img, 8, 1, 8, 1.0, 1.0, 0.2, 'pencils/pencil0.jpg', 3, 2, 10);

%% Save the image
imwrite(I, 'outputs/demo.jpg');