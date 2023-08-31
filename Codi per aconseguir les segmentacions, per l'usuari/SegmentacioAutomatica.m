% Autora: Camila Silva Delgado. Última revisió: Agost 2023.
% Escola politècnica superior. Universitat de Girona
% Aquest codi forma part del treball de fi de grau: Segmentació automàtica d'imatges radiològiques per la posterior fabricació de guies quirúrgiques per la planificació de cirurgies de la zona cap-coll.
% Descripció: Segmentació automàtica del TAC 
% Estructures segmentades: tiroides, teixit tou, os i vascular i múscul i greix

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
num_slices = double(length(dcm_files));
rows = double(info.Rows);
cols = double(info.Columns);
slice_thickness = double(info.SliceThickness);
pixel_spacing_row = double(info.PixelSpacing(1));
pixel_spacing_col = double(info.PixelSpacing(2));
% S'inicialitza una matriu 3D per emmagatzemar la imatge
Image = zeros(rows, cols, num_slices, 'int16'); % És important llegir la imatge com a int16 per capturar valors negatius
% Lectura de tots els arxius DICOM i ompliment la matriu 3D
for i = 1:num_slices
    filename = fullfile(dcm_dir, dcm_files(i).name);
    Image(:, :, i) = dicomread(filename);
end

size_CT = size(Image); % Mida del volum que desa del TAC

% Definició de thresholds amb els valors obtinguts fent proves amb el 3D slicer
os_vascular_min = 230;
teixit_tou_min = -18;
teixit_tou_max = 162;
tiroides_min = 75;
tiroides_max = 180;
muscul_greix_min =-140;
muscul_greix_max = -30;
background_max = -450;
background_min = -2048;

% Volums que contenen els pixels dels rangs determinats 
seg_os_vascular = (Image >= os_vascular_min);
seg_teixit_tou = (Image >= teixit_tou_min) & (Image <= teixit_tou_max);
seg_tiroides = (Image >= tiroides_min) & (Image <= tiroides_max);
seg_muscul_greix = (Image >= muscul_greix_min) & (Image <= muscul_greix_max);
seg_background = (Image >= background_min) & (Image <= background_max);


% Processat de la segmentació de la tiroides
% Definició element estructural per l'erosió i s'aplica erosió i ompliment
se = strel('square', 6);  
seg_tiroides_erode = imerode(seg_tiroides, se);
seg_tiroides_filled = bwmorph3(seg_tiroides_erode, 'fill');

% Segon ompliment llesca a llesca amb imfill
for j = 1:num_slices
    seg_tiroides_filled(:, :, j) = imfill(seg_tiroides_filled(:,:,j), 26,  'holes');
end

% S'etiqueten les regions
seg_tiroides_labelled = bwlabeln(seg_tiroides_filled); 
% Propietats de les regions trobades
properties_seg_tiroides = regionprops3(seg_tiroides_labelled); 

% Es troba la regió més gran per eliminar altres zones sobrants
regions = [properties_seg_tiroides.Volume];
[max_size, max_idx] = max(regions);
max_region = max_idx;

% Màscara binària amb només la regió més gran 
tiroides = false(size_CT); 

% Rang de llesques on hi és la tiroides
first_slice = 47; 
last_slice = 130;

for j = first_slice:last_slice
    % Es desa la regió més gran a les llesques 
    tiroides(:, :, j) = seg_tiroides_labelled(:, :, j) == max_region;
end

% Element estructural per dilatació i ompliment final
se2 = strel('diamond', 4);  

for j = first_slice:last_slice
    tiroides(:, :, j) = imdilate(tiroides(:,:,j), se2);
    tiroides(:, :, j) = imfill(tiroides(:,:,j), 26,  'holes');
end

% Visualització 3D de la tiroides segmentada
figure;
sliceViewer(tiroides);
title('Volum tiroides segmentació automàtica post-processada');


% Es crea un volum amb etiquetes per cada regió segmentada a partir de
% thresholds, perquè cada píxel pertanyi a una regió
% 0 --> Fons
% 1 --> Os/Vascular
% 2 --> Tiroides
% 3 --> Ttou sense la tiroides
% 4 --> Muscul i greix

% Volum inicialitzat a -1 per omplir amb les etiquetes 
volume_segmentations = -1 * ones(size_CT); 

% Assignació del fons i estructura òssia + vascular 
volume_segmentations(seg_os_vascular) = 1;  % Os + Vascular
volume_segmentations(seg_background) = 0;  % Fons

% S'assignen els pixels no assignats
% Quan les diferents regions se solapen, s'assigna segons ordre establert

% Es desen les coordenades dels píxels sense assignar
[row, col, slice] = ind2sub(size(volume_segmentations), find(volume_segmentations == -1));

%Assignació d'etiquetes segons regions de les segmentacions
for i = 1:numel(row)
    label = volume_segmentations(row(i), col(i), slice(i));
    if label == -1 % si no està assignat
        if tiroides(row(i), col(i), slice(i))
            % Si és tiroides
            volume_segmentations(row(i), col(i), slice(i)) = 2;
        elseif seg_muscul_greix(row(i), col(i), slice(i))
            % Si és ttou
            volume_segmentations(row(i), col(i), slice(i)) = 4;
        elseif seg_teixit_tou(row(i), col(i), slice(i))
            % Si és muscul i greix
            volume_segmentations(row(i), col(i), slice(i)) = 3;
        end
    end
end

% Als pixels de valor no assignats s'hi assigna valor segons píxels veïns

% Es desen les coordenades dels píxels sense assignar
[row, col, slice] = ind2sub(size(volume_segmentations), find(volume_segmentations == -1));

for i = 1:numel(row)
    label = volume_segmentations(row(i), col(i), slice(i));
    if label == -1
        % Llistat de píxels veins
        veins = volume_segmentations(max(row(i)-1, 1):min(row(i)+1, size_CT(1)), max(col(i)-1, 1):min(col(i)+1, size_CT(2)), max(slice(i)-1, 1):min(slice(i)+1, size_CT(3)));
        labels_voltant = unique(veins(:));
        labels_voltant(labels_voltant == -1 | labels_voltant == 0) = []; % S'elimina el -1 i 0 per no assignar-los
        
        if ~isempty(labels_voltant)
            % Etiqueta mes comú del pixels veins 
            label_counts = histcounts(veins(:), [labels_voltant; max(labels_voltant)+1]);
            [~, max_count_idx] = max(label_counts); %no ens cal el valor sino l'índex
            volume_segmentations(row(i), col(i), slice(i)) = labels_voltant(max_count_idx);
        else
            % Si no hi ha etiquetes vàlides, s'assigna l'etiqueta 4 (ttou)
            volume_segmentations(row(i), col(i), slice(i)) = 4;
        end
    end
end

figure;
sliceViewer(volume_segmentations);
title('Segmentació automàtica');


% Inversió de la segmentació (està invertida)
volume_segmentations = fliplr(volume_segmentations); 

% Volums finals
seg_os_vasc_final = double(volume_segmentations== 1);
seg_tiroides_final = double(volume_segmentations== 2);
seg_ttou_final = double(volume_segmentations== 3);
seg_muscul_greix_final = double(volume_segmentations== 4);

% Es desa també només una secció de la segmentació òssia i vascular
% Crear una matriu amb totes les llesques a zero
seg_os_vasc_final_tallat = zeros(size(seg_os_vasc_final));
% Assignar les llesques en l'interval 36:137 amb els valors originals
seg_os_vasc_final_tallat(:,:,36:137) = seg_os_vasc_final(:,:,36:137);


% Definició sistema per conservar mides del TAC original quan desem a stl
gridX = linspace(0, pixel_spacing_row * (cols - 1), cols);
gridY = linspace(0, pixel_spacing_col * (rows - 1), rows);
gridZ = linspace(0, slice_thickness * (num_slices - 1), num_slices);

% Volums a arxius .stl
% Fent servir l'arxiu (https://es.mathworks.com/matlabcentral/fileexchange/27733-converting-a-3d-logical-array-into-an-stl-surface-mesh)
STLname_tiroides = 'tiroides_automatica.stl';
STLname_os_vasc = 'os_vascular_automatica.stl';
STLname_os_tallat = 'os_vascular_automatica_tallat.stl';
STLname_ttou = 'ttou_automatica.stl';
STLname_muscul_greix = 'muscul_greix_automatic.stl';

CONVERT_voxels_to_stl(STLname_tiroides, seg_tiroides_final, gridX, gridY, gridZ);
CONVERT_voxels_to_stl(STLname_os_vasc, seg_os_vasc_final, gridX, gridY, gridZ);
CONVERT_voxels_to_stl(STLname_os_tallat, seg_os_vasc_final_tallat, gridX, gridY, gridZ);
CONVERT_voxels_to_stl(STLname_ttou, seg_ttou_final, gridX, gridY, gridZ);
CONVERT_voxels_to_stl(STLname_muscul_greix, seg_muscul_greix_final, gridX, gridY, gridZ);

fprintf('Les segmentacions en format stl han estat desades al directori on ha estat executat aquest codi ');

