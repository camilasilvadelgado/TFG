# Segmentació automàtica d'imatges radiològiques per la posterior fabricació de guies quirúrgiques per la planificació de cirurgies de la zona cap-coll

**Autora:** Camila Silva Delgado

Treball Final de Grau del grau en Enginyeria Biomèdica de la Universitat de Girona.


## PROPÒSTI DEL PROJECTE I DESCRIPCIÓ DEL REPOSITORI
A aquest TFG es desenvolupa una metodologia de segmentació automàtica de l'anatomia del coll, se'n creen models 3D i s'obtenen prototips de guies quirúrgiques impresos amb fabricació additiva. Es desenvolupa una proposta de protocol estàndard per a l'obtenció de guies quirúrgiques. La principal motivació del treball és millorar la planificació i qualitat de les cirurgies mitjançant una eina que ofereixi una representació espacial i personalitzada de l'anatomia de la zona als metges, també amb l'objectiu de millorar l'experiència dels pacients.

A aquest repositori es presenta el codi per a l'obtenció de la segmentació d'un TAC. S'obtenen les següents segmentacions en format STL: tiroides (dos mètodes), estructura òssia i vascular, múscul i greix i resta del teixit tou.

El repostiori té la següent estructura. Dues carpetes:
•	**Codi per aconseguir les segmentacions, per l'usuari.** Inclou el codi necessari per obtenir les segmentacions (dos codis amb les dues metodologies de segmentació i els arxius necessaris a tenir al directori per passar les segmentacions a STL).
•	**Codi anàlisi i avaluació.** Hi ha el codi desenvolupat per l’anàlisi de la imatge i el GT, la prova de segmentació amb k-means i el codi fet servir per a l’avaluació i el càlcul del coeficient DICE. 


## REQUERIMENTS 

Els requeriments per obtenir les segmentacions són els següents:
•	MATLAB amb Image processing Toolbox, Medical Imaging Toolbox

- Funcions '*Converting a 3D logical array into an STL surface mesh*' [(Pàgina web on trobar-les)]([https://es.mathworks.com/matlabcentral/fileexchange/68794-make-stl-of-3d-array-optimal-for-3d-printing?s_tid=prof_contriblnk](https://es.mathworks.com/matlabcentral/fileexchange/27733-converting-a-3d-logical-array-into-an-stl-surface-mesh)).


</p>
