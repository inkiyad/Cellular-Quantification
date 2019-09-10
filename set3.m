clc; clear all; close all;

%% Loading files
im(:,:,:,1) = imread('CytometerFullGrid.tif');
im(:,:,:,2) = imread('CytometerLargeGrid.tif');
im(:,:,:,3) = imread('CytometerSemiGrid.tif');

T = {'Viability_Full',... 
     'Viability_Large',...
     'Viability_Semi'};
%% Automating process for 3 images
tlevel1 = [0.3, 0.3, 0.34]; % Threshold adjustments for total cells
tlevel2 = [0.25, 0.24, 0.27]; % Threshold adjustments for dead cells
for i=1:3
    %% RGB2GRAY
    imgr(:,:,i) = rgb2gray(im(:,:,:,i));
    %% Isolating grid
    mask1 = ~imbinarize(imgr(:,:,i),tlevel1(i));
    mask1 = bwareaopen(mask1, 60);
    mask1 = imclose(mask1, strel('disk', 2));
    mask1 = imdilate(mask1, strel('square', 6));
    
    mask1 = imfill(mask1, 'holes');
    
    %% Total count
    [L{1}, total] = bwlabel(mask1);
    count(i,1) = total;
    %% Viability count
    mask2 = ~imbinarize(imgr(:,:,i),tlevel2(i));
    mask2 = imerode(mask2, strel('disk', 2));
    mask2 = bwareaopen(mask2, 20);
    mask2 = imdilate(mask2, strel('disk', 8));
    
    [L{2}, dead] = bwlabel(mask2);
    count(i,2) = dead;
    viability(i) = (1 - dead/total)*100;
    
    %% Display
    overlay(:,:,:,1) = imoverlay(im(:,:,:,i), bwperim(mask1));
    overlay(:,:,:,2) = imoverlay(im(:,:,:,i), bwperim(mask2));
    tlabel{1} = 'Total Count'; tlabel{2} = 'Dead Count'; 
    figure(i);
    for ii = 1:2;
        s{ii} = regionprops(L{ii}, 'Centroid');
        subplot(1,2,ii)
        imshow(overlay(:,:,:,ii))
        hold on
        for k = 1:numel(s{ii})
            c = s{ii}(k).Centroid;
            text(c(1)-20, c(2)+10, sprintf('%d', k), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'color', 'red');
        end
        hold off; title(tlabel{ii});
    end        


end
Ans1 = array2table(viability, 'VariableNames', T);
Ans2 = array2table(count, 'VariableNames', {'Total_Count', 'Dead_count'});
disp(Ans1); disp(Ans2);