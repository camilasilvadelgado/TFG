% Autora: Camila Silva Delgado. Última revisió: Agost 2023.
% Escola politècnica superior. Universitat de Girona
% Aquest codi forma part del treball de fi de grau: Segmentació automàtica d'imatges radiològiques per la posterior fabricació de guies quirúrgiques per la planificació de cirurgies de la zona cap-coll.
% Descripció: Primera aproximació a la segmentació del TAC - kmeans

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

size_CT = size(Image); % Mida del volum que desa del TAC

%Visualitzem el TAC
figure;
sliceViewer(Image);
title('TAC original');

%S'aplica al TAC una millora del contrast adaptativa i un filtre
for i=1:size_CT(3)
    Im_postprocessed(:,:,i) = adapthisteq(Image(:,:,i));
    Im_postprocessed(:,:,i) = medfilt2(Image(:,:,i)); 
end 

%Segmentació utilitzant la funció imsegkmeans3 
k_values = [3, 4, 7, 12]; %valors de k que es proven
num_k = length(k_values);
figure;
for i=1:num_k
    k = k_values(i);
    labels_seg = imsegkmeans3(Im_postprocessed, k); %Segmentació 
    subplot(1, num_k, i);
    imshow(label2rgb(labels_seg(:,:,95))); %S'atribueix color a les etiquetes
    title(['Llesca 95 - k = ', num2str(k)]); %Es mostren les diverses proves
end
