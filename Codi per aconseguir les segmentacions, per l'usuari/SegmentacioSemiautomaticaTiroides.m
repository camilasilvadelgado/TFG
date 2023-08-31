% Autora: Camila Silva Delgado. Última revisió: Agost 2023.
% Escola politècnica superior. Universitat de Girona
% Aquest codi forma part del treball de fi de grau: Segmentació automàtica d'imatges radiològiques per la posterior fabricació de guies quirúrgiques per la planificació de cirurgies de la zona cap-coll.
% Descripció: Segmentació semiautomàtica de la tiroides al TAC

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

%SEGMENTACIÓ SEMIAUTOMÀTICA DE LA TIROIDES:

% Visualize TAC in 3D
figure
sliceViewer(Image);
title(['TAC on segmentar la tiroides.' newline 'Escollir: número de llesca on es vegi bé la tiroides,' newline 'número de la primera i última llesca on es veu']);


% Triar aquests 3 paràmetres interactivament
fprintf(['Visualitza el TAC i ajusta la visualització movent la barra de les llesques i el cursor per millorar el contrast. ' newline 'Escull els paràmetres següents (nombres de l''1 al 253):\n']);
first_slice = input('Nombre aproximat de la llesca on primer es veu la tiroides: ');
last_slice = input('Nombre aproximat de la última llesca on es veu la tiroides: ');
seed_num = input('Nombre d''una llesca on es vegi bé la tiroides i on es dibuixarà la segmentació: ');


% Els triats per nosaltres
% primera_llesca_tiroides = 50;
% ultima_llesca_tiroides = 120;
% seed_num=76; 

% Imatge sobre la qual es traça la silueta de la tiroides 
% S'ajustem level i window per visualitzar millor la tiroides

level = 44;  % level value (triats amb 3D Slicer)
window = 243; % window value (triats amb 3D Slicer)
min_value = level - window/2;
max_value = level + window/2;

% Es mostra la llesca sobre la qual es vol dibuixar
slice_to_draw = Image(:,:,seed_num); 
figure
imshow(slice_to_draw, [min_value, max_value]);
title('Dibuixa la silueta de la tiroides, en acabar, prémer la tecla enter')


% Es dibuixa sobre la imatge la silueta de la tiroides
drawing_tiroides = drawfreehand();
wait(drawing_tiroides);

% Es crea la màscara binària a partir del dibuix 
mask = createMask(drawing_tiroides);
seed_slice = mask;
close gcf;

% SEGMENTACIÓ FENT SERVIR ACTIVE CONTOURS: 

% Volum on es desa la segmentació 
tiroides_seg = zeros(size(Image), 'logical');
tiroides_seg(:,:,seed_num) = seed_slice; % s'omple amb la llesca dibuixada


% Contrast a la imatge per millorar la segmetnació
for i = 1:size_CT(1,3)
    Image(:, :, i) = histeq(Image(:, :, i));
end

num_iterations = 20; %Paràmetre per l'active contours

% Bucles per segmentar amb activecontours cada llesca: un de la llavor fins
% la llesca superior i l'altre de la llavor a la inferior

for i = seed_num+1:last_slice
    current_slice = Image(:,:,i);
    segmented_slice = activecontour(current_slice, seed_slice, num_iterations, 'edge', 'ContractionBias', 0.17);
    % S' emmagatzemen els resultats a la llesca corresponent
    tiroides_seg(:,:,i) = segmented_slice; 
    % S'utilitza el resultat de la segmentació anterior com a màscara per la següent
    seed_slice = segmented_slice; 
end

%Tornem a inicialitzar la màscara per agafar la del dibuix
seed_slice = mask;

for j = seed_num-1:-1:first_slice
    current_slice = Image(:,:,j);
    segmented_slice = activecontour(current_slice, seed_slice, num_iterations, 'edge', 'ContractionBias', 0.17);
    tiroides_seg(:,:,j) = segmented_slice; 
    seed_slice = segmented_slice;
end

% Flip de la segmentació per guardar-la i avaluar bé amb el GT
tiroides_seg = fliplr(tiroides_seg); 

%Guardem segmentació tiroides en un volum en stl
%Fent servir l'arxiu (https://es.mathworks.com/matlabcentral/fileexchange/27733-converting-a-3d-logical-array-into-an-stl-surface-mesh)

%Primer definim la mida per conservar les mides del TAC original
gridX = linspace(0, pixel_spacing_row * (cols - 1), cols);
gridY = linspace(0, pixel_spacing_col * (rows - 1), rows);
gridZ = linspace(0, slice_thickness * (num_slices - 1), num_slices);
 
STLname = 'tiroides_semiautomatica.stl'; 
CONVERT_voxels_to_stl(STLname, tiroides_seg, gridX, gridY, gridZ);
fprintf('La segmentació en format stl ha estat desada al directori des d''on ha estat executat aquest codi ');



