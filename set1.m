clc; clear all; close all;

%% Loading file
im = imread('Passage 3A-3B.png');
imb = im(:,:,3); % Loading only blue stain signal
imb_c = adapthisteq(imb);

%% Filtering
H = fspecial('disk',20);
blurred = imfilter(imb_c,H,'replicate'); 
imd = 6*(imb_c - blurred);
imd = wiener2(imd, [5 5]);

%% Binarizing
bw_b = imbinarize(imb_c);

%% Processing
bw2_b = imfill(bw_b, 'holes');
bw4_b = bwareaopen(bw2_b, 20);

%% Peaks and valleys
nhood = ones(9,9);
q = rangefilt(imd,nhood);

p = imd - q;
p = imerode(p, strel('disk',2));
p = bwareaopen(p, 60);
p = imfill(p, 'holes');

%% Watershed
imc_c = imcomplement(imb_c);
w = imimposemin(imc_c, ~bw4_b | p);
L = watershed(w);

%% Count
[L, num] = bwlabel(L);
s = regionprops(L, 'Centroid');

%% Segmenting cell body
img = im(:,:,2); % green signal
imgf = adapthisteq(img);
imgf = wiener2(imgf, [5 5]);

%% Masking
mask = imbinarize(imgf, 0.4);
mask = imfill(mask, 'holes');
mask = bwareaopen(mask, 1);

%% Calculating avg and std signal/cell 
cell_body = imgf.*uint8(mask);
avg_signal = sum(cell_body(:))/max(num);
cell_pixel = cell_body(find(cell_body>0));
std_pixel = std(double(cell_pixel(:)));
mask_length = length(find(mask==1));
std_cell = std_pixel*(mask_length/num); % Converting std/pixel to std/cell

%% Displaying
im_filtered(:,:,2) = imgf; % green with contrast and filter
im_filtered(:,:,3) = imb_c; % blue with contrast and filter
im_filtered(:,:,1) = im(:,:,1);
figure(2);
overlay1 = imoverlay(im, bwperim(mask) | bwperim(L));
imshow(overlay1)
hold on
for k = 1:numel(s)
    c = s(k).Centroid;
    text(c(1)-20, c(2)+10, sprintf('%d', k), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'color', 'red');
end

hold off
title('hMSCs with Nucleus and Cell Body Outline');
str = sprintf(['Average signal per cell: %0.5g \n '...
    'Std signal per cell: %0.5g'], avg_signal, std_cell);
xlabel(str);

% Display table
m = {'Avg' , avg_signal; ...
    'Std' , std_cell}; 
Ans1 = cell2table(m, 'VariableNames', {'Stats','Signal'});
disp(['Total cell count: ' num2str(num)]);
disp(['Std per pixel: ' num2str(std_pixel)]);
disp(Ans1);