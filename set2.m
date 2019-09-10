clc; clear all; close all;

%% Loading file
im = imread('recovery-15.5hr-fl (1).tif');
img = im(:,:,2);
H = fspecial('disk',60);
img_b = imfilter(img,H,'replicate');
img_c = img - img_b;
img_c = histeq(img_c);
img_c = wiener2(img_c, [5 5]);
img_c1 = imadjust(img_c, [0.5 1], []);


%% Binarizing

BW = imbinarize(img_c,'adaptive','ForegroundPolarity','dark','Sensitivity',0.59);
BW = bwareaopen(BW, 150);
BW = imclose(BW, strel('disk',4));

%% Marking
mark = imbinarize(img_c, 'adaptive');
mark = bwareaopen(mark, 60);
mark = imfill(mark, 'holes');
mark = imopen(mark, strel('disk',12));
mark = imerode(mark, strel('disk',8));

%% Peaks and valleys with watershed
img_b = imcomplement(img_c);
w = imimposemin(img_b, ~BW | mark);
L = watershed(w);
L1 = label2rgb(L);

%% Count
[L, num] = bwlabel(L);
s = regionprops(L, 'Centroid');

%% signal avg and std per cell
cell_body = img.*uint8(BW);
avg_signal = sum(cell_body(:))/max(num);
cell_pixel = cell_body(find(cell_body>0));
std_pixel = std(double(cell_pixel(:)));
mask_length = length(find(BW==1));
std_cell = std_pixel*(mask_length/num); % Converting std/pixel to std/cell

%% Calculating aspect ratio
calc = regionprops(L, 'Area', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength');
m = struct2cell(calc); m = cell2mat(m);

circ = 4*pi.*m(1,:)./m(4,:).^2;
ar = m(2,:)./m(3,:);

circ_avg = mean(circ); circ_std = std(circ);
ar_avg = mean(ar); ar_std = std(ar);
%% Display
overlay = imoverlay(img_c, bwperim(L));
figure(1);
imshow(overlay)
hold on
for k = 1:numel(s)
    c = s(k).Centroid;
    text(c(1)-20, c(2)+10, sprintf('%d', k), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'color', 'red');
end
hold off

title('Endothelial Cells with Outline');
str = sprintf(['Average signal per cell: %0.5g \n '...
    'Std signal per cell: %0.5g'], avg_signal, std_cell);
xlabel(str);

% Bargraph of average circularity and aspect ratio with standard deviation
figure(2);
data = [circ_avg ar_avg];
std = [circ_std ar_std];
x = [1 2];
bar(x, data)
hold on

er = errorbar(x,data,-std,std);    
er.Color = 'red';                            
er.LineStyle = 'none';  

hold off
xticks([1 2]);
xticklabels({'Average Circularity','Average Aspect Ratio'});
ylabel('Ratio'); title('Average Aspect Ratio and Circularity with Standard Deviation');

% Display table
m = {'Avg' , avg_signal, circ_avg, ar_avg ; ...
    'Std' , std_cell, circ_std, ar_std}; 
Ans1 = cell2table(m, 'VariableNames', {'Stats','Signal','Circularity','Aspect_Ratio'});
disp(['Total cell count: ' num2str(num)]);
disp(['Std per pixel: ' num2str(std_pixel)]);
disp(Ans1);