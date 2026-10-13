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
