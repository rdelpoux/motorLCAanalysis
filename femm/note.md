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

Fait (13 octobre 2026, suite) :
- Code partagé : `motorConfig.m` (paramètres machine, barrières, aimants, masses volumiques)
  et `configureBarriers.m` (air ou aimants dans les barrières), utilisés par `matlabFEMM.m`
  et `torqueRipple.m`. `park_transform.m` copié depuis Collab_Laplace/hbk_synrel.
- `torqueRipple.m` : point de fonctionnement "one_OP" (SetProblemType), Is = 10 A, beta = 45°,
  quart de tour mécanique (un pas polaire) en 90 positions, pour les deux variantes.
  Conventions du script d'origine (Collab_Laplace/hbk_synrel/02_FEMM/matlabFEMM.m) :
  i_k = Is cos(p theta + beta - phaseShift_k), rotation par BandeRoulement1,
  couple = mo_gapintegral (déjà machine complète), flux/tensions x nSym.
  Sorties dans results/ : torqueRipple_Is10A_beta45deg.mat (+ .png / .eps).
  Premier run (aimantation à 45°) archivé dans results/essai_dir45/ : couple moyen SynRM = +0,39 Nm
  (ondulation c-c 50 %), PMa-SynRM = -0,75 Nm -> le couple des aimants s'oppose au couple de
  réluctance. Correction : cfg.magnet.dirDeg = 225 dans motorConfig.m (couple additif pour beta = 45°).
À FAIRE EN PRIORITÉ : relancer torqueRipple.m (environ 12 min, 2 x 90 résolutions) pour obtenir
  results/torqueRipple_Is10A_beta45deg.mat/.png/.eps avec l'aimantation corrigée, puis vérifier
  que le couple PMa-SynRM est positif et supérieur au SynRM.

Fait (13 octobre 2026, soir) :
- torqueRipple.m : sweep = pi/4 (le couple se répète 2 fois par pas polaire), nSteps = 15.
- Aimantation 225° validée : couple moyen PMa-SynRM = +1,19 Nm (ondulation c-c 129 %) contre
  +0,39 Nm SynRM (47 %), Is = 10 A, beta = 45°, profondeur 19,3 mm.
- Écart avec l'étude couple d'origine expliqué : le script Collab_Laplace n'appelait pas mi_probdef,
  FEMM utilisait la profondeur du .fem = 100 mm. Au banc (dataHBK normI8beta47) : 1,06 Nm mesuré à
  8 A / 47°, FEMM 1,29 Nm avec 100 mm. Test : SynRM 7 A / 45° -> 0,19 Nm à 19,3 mm, 0,98 Nm à 100 mm.
  DÉCISION À PRENDRE : L_active = 0,1 m dans motorConfig.m ? Impact direct sur les masses de l'ACV V1
  (x 5,18 sur tôles, cuivre et aimants).
- beta = 45° n'est pas le MTPA de la machine à aimants : prévoir un balayage en beta (et Is) pour
  comparer les deux machines à leur MTPA respectif / à puissance équivalente.

Fait (13 octobre 2026, L_active confirmé = 100 mm par Romain) :
- motorConfig.m : cfg.L_active = 0.1. Masses (machine complète) : tôles stator 3,60 kg, rotor 2,17 kg,
  aimants 1,41 kg (PMa-SynRM). Fichiers tmp/motor_materials_SynRM.mat et _PMaSynRM.mat.
  database/motor_materials.mat (V1, 19,3 mm) NON remplacé : à faire pour l'ACV V2 (masses x 5,18).
- torqueRipple.m à 100 mm, Is = 10 A, beta = 45° : SynRM 2,03 Nm (ondulation c-c 47 %),
  PMa-SynRM 6,19 Nm (129 %). Prochaine étape : balayage en beta pour le MTPA de chaque machine.
