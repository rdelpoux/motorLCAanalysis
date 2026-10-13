Etape à faire :
Changer les matériaux dans les barrière de flux uniquement pouvoir faicilement mettre ou enlever les aimants à partir du fichier : 
motorLCAanalysis/femm/matlabFEMM.m
les matériaux pour les aimants néodymes doivent se trouver dans 

sources/Lien vers machine_modeling

Et calculer la quantité d'aimants dans le moteur si le parmètre est activé. 
---
Fait (13 octobre 2026) :
- `matlabFEMM.m` : paramètre `useMagnets` (true = barrières remplies de NdFeB, false = SynRM).
  Les 7 régions de barrières (coordonnées des étiquettes du .fem) reçoivent le matériau
  `NdFeB_LCA` (Br = 1,1 T, mu_r = 1,1, repris de machine_modeling/parametres_machine.m, MSAP),
  aimantation à 45° (axe q du pôle dans le quart de machine).
- Masse d'aimants calculée par intégrale de volume FEMM : 0,272 kg (36,3 cm3) pour la machine complète.
- Sorties : tmp/motor_materials_SynRM.mat, tmp/motor_materials_PMaSynRM.mat (+ tmp/motor_materials.mat).
À faire : vérifier le signe de l'aimantation (45° / 225°) par rapport à la convention de courant
(SetProblemType), puis comparaisons couple / ondulation / pertes à puissance équivalente.
