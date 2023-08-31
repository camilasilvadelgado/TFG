% Autora: Camila Silva Delgado. Última revisió: Agost 2023.
% Aquest codi forma part del treball de fi de grau: Segmentació automàtica d'imatges radiològiques per la posterior fabricació de guies quirúrgiques per la planificació de cirurgies de la zona cap-coll.
% Escola politècnica superior. Universitat de Girona
% Descripció: Anàlisi del TAC a segmentar i del seu respectiu GT 

% Clear de l'espai de treball i es tanquen totes les figures obertes
clear all;
close all;

% Especificar directori amb arxius DICOM: 
dcm_dir = '/Users/camilasilva/Desktop/TFG local/1- Casos/Goll compressiu/IMATGES/DICOM/DICOM/PAT00000/STU00000/SER00004_dcm/';
dcm_files = dir(fullfile(dcm_dir, '*.dcm'));
% Es comprova si hi ha arxius DICOM al directori especificat.
if isempty(dcm_files)
    error('No hi ha arxius dcm al directori');
end
% Llegeix el primer arxiu DICOM, s'obtenen dimensions i altres dades
info = dicominfo(fullfile(dcm_dir, dcm_files(1).name));
num_slices = length(dcm_files);
rows = info.Rows;
cols = info.Columns;
% S'inicialitza una matriu 3D per emmagatzemar la imatge
Image = zeros(rows, cols, num_slices, 'int16'); % És important llegir la imatge com a int16 per capturar valors negatius
% Lectura de tots els arxius DICOM i ompliment la matriu 3D
for i = 1:num_slices
    filename = fullfile(dcm_dir, dcm_files(i).name);
    Image(:, :, i) = dicomread(filename);
end

figure;
sliceViewer(Image);

size_CT = size(Image); % Mida del volum que desa del TAC

% Lectura del Ground Truth (GT) en format NRRD
GT = nrrdread('Segmentation.seg.nrrd');
labels = unique(GT(:));
num_labels = length(labels);

max_intensity = max(max(max(Image )));
min_intensity = min(min(min(Image)));

% Histograma de les intensitats
figure;
histogram(Image(:), 'BinWidth', 10, 'BinLimits', [min_intensity, 32000]);
xlabel('Intensitat');
ylabel('Freqüència');
title('Histograma Intensitats');

% Mitjanes, valors màxims i valors mínims d'intensitat per secció
mean_intensity_slice = mean(Image, [1, 2]);
max_intensity_slice = max(Image, [], [1, 2]);
min_intensity_slice = min(Image, [], [1, 2]);

% Contrast per secció
contrast = max_intensity_slice - min_intensity_slice;

% Desviació estàndard per secció
std_deviation_slice = std(single(Image), 0, [1, 2]);

% Anàlisi GT
for i = 0:num_labels-1
    % propietats d'intensitat de cada regió
    props = regionprops3(GT == i, Image, 'VoxelValues');  
    fprintf('Regió %d:\n', i);
    voxel_values = props.VoxelValues{1};
    fprintf('Nombre de voxels = %d\n', numel(voxel_values));
    fprintf('Mínima intensitat = %d\n', min(voxel_values));
    fprintf('Màxima intensitat = %d\n', max(voxel_values));
    fprintf('Mitjana intensitat = %.2f\n\n', mean(voxel_values));
    fprintf('Mediana intensitat = %.2f\n\n', median(voxel_values));
end

% Taula amb les mètriques
metrics_table = table();
metrics_table.Regio = (0:num_labels-1)';
for i = 0:num_labels-1
    props = regionprops3(GT == i, Image, 'VoxelValues');
    voxel_values = props.VoxelValues{1};
    metrics_table.NumVoxels(i + 1) = numel(voxel_values);
    metrics_table.MinIntensity(i + 1) = min(voxel_values);
    metrics_table.MaxIntensity(i + 1) = max(voxel_values);
    metrics_table.MeanIntensity(i + 1) = mean(voxel_values);
    metrics_table.MedianIntensity(i + 1) = median(voxel_values);
end

% Gràfics per visualitzar les mètriques
figure;

% Gràfic de nombre de voxels per regió
subplot(2, 3, 1);
bar(metrics_table.Regio, metrics_table.NumVoxels);
xlabel('Regió');
ylabel('Nombre de Voxels');
title('Nombre de Voxels per Regió');

% Gràfic de mínima intensitat per regió
subplot(2, 3, 2);
bar(metrics_table.Regio, metrics_table.MinIntensity);
xlabel('Regió');
ylabel('Mínima Intensitat');
title('Mínima Intensitat per Regió');

% Gràfic de màxima intensitat per regió
subplot(2, 3, 3);
bar(metrics_table.Regio, metrics_table.MaxIntensity);
xlabel('Regió');
ylabel('Màxima Intensitat');
title('Màxima Intensitat per Regió');

% Gràfic de mitjana intensitat per regió
subplot(2, 3, 4);
bar(metrics_table.Regio, metrics_table.MeanIntensity);
xlabel('Regió');
ylabel('Mitjana Intensitat');
title('Mitjana Intensitat per Regió');

% Gràfic de mediana intensitat per regió
subplot(2, 3, 5);
bar(metrics_table.Regio, metrics_table.MedianIntensity);
xlabel('Regió');
ylabel('Mediana Intensitat');
title('Mediana Intensitat per Regió');

% Per mostrar les màscares binàries amb les segmentacions del GT 

maks = cell(1, num_labels);

for i = 1:num_labels
    mask_name = sprintf('mask%d', i); 
    mask=zeros(size(GT));
    mask(GT == i) = 1;
    mask = imrotate3(mask, 270, [0, 0, 1]); % Rotació per fer coincidir orientació 
    mask = mask(1:size_CT(1), 1:size_CT(2), 1:size_CT(3)); 
    eval([mask_name ' = mask;']); 
    mask_name = sprintf('mask%d', i);
    maks{i} = eval(mask_name);
end

for i = 1:num_labels
    figure;
    sliceViewer(maks{i});
    title(sprintf('Mask %d', i));
end
