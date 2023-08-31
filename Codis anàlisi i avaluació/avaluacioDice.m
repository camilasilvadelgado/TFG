% Autora: Camila Silva Delgado. Última revisió: Agost 2023.
% Escola politècnica superior. Universitat de Girona
% Aquest codi forma part del treball de fi de grau: Segmentació automàtica d'imatges radiològiques per la posterior fabricació de guies quirúrgiques per la planificació de cirurgies de la zona cap-coll.
% Descripció: Avaluació de les segmentacions calculant el DICE

% Suposant prèviament l'obtenció de la segmentació a partir d'un TAC o la lectura d'aquesta

%Lectura del GT per avaluació i adaptació per assimilar-lo a la segmentació

GT = nrrdread('Segmentation.seg.nrrd');

labels = unique(GT(:));
num_labels = numel(labels);

for i = 1:num_labels
    mask_name = sprintf('mask%d', i); 
    mask = zeros(size(GT));
    mask(GT == i) = 1;
    mask = imrotate3(mask, 270, [0, 0, 1]); % Rotació per fer coincidir orientació 
    mask = mask(1:size_CT(1), 1:size_CT(2), 1:size_CT(3)); 
    eval([mask_name ' = mask;']); 
end

% Determinació de màscares del gt i unió de màscares os + vascular per fer avaluació 
% Aquest pas depen de com estigui etiquetat el GT, el codi d'anàlisi permet
% visualitzar-lo per màscares i determinar les estructures de cada màscara per poder fer aquest pas. 

mask_os_vascular_gt = mask1+mask2+mask3+mask4+mask5;
mask_tiroides_gt= mask6;


% Càlcul del dice per avaluar tiroides (automàtica o semiautomàtica) i os + vascular

intersection = mask_tiroides_gt & seg_tiroides_final;
sum_mask_tiroides = sum(mask_tiroides_gt(:));
sum_tiroides_segmented = sum(seg_tiroides_final(:));
dice_tiroides = 2 * sum(intersection(:)) / (sum_mask_tiroides + sum_tiroides_segmented);
fprintf('Coeficient DICE de la segmentació automàtica de la tiroides: %.4f\n', dice_tiroides);

intersection2 = mask_os_vascular_gt & seg_os_vasc_final;
sum_mask_os_vas = sum(mask_os_vascular_gt(:));
sum_seg_os_vas = sum(seg_os_vasc_final(:));
dice_os_vascular = 2 * sum(intersection2(:)) / (sum_mask_os_vas + sum_seg_os_vas);
fprintf('Coeficient DICE de la segmentació automàtica de la segmentació os i vascular: %.4f\n', dice_os_vascular);
