function cfg = motorConfig(options)
%MOTORCONFIG Configuration partagée du modèle FEMM de la machine (SynRM / PMa-SynRM).
%   cfg = motorConfig() renvoie la structure de configuration du modèle
%   femmSynrelLaplace.fem : paramètres machine, coordonnées des barrières de
%   flux, propriétés des aimants et masses volumiques.
%
%   cfg = motorConfig(useMagnets=true) renseigne la variante (true :
%   barrières remplies d'aimants, PMa-SynRM ; false : SynRM). Le champ
%   cfg.motorType vaut alors 'PMaSynRM' ou 'SynRM'.
%
%   Les propriétés des aimants reprennent celles du projet machine_modeling
%   (sources/Lien vers machine_modeling, parametres_machine.m, topologie
%   MSAP) : Br = 1,1 T et mu_r = 1,1.
%
%   Exemple :
%     cfg = motorConfig(useMagnets=true);
%     opendocument(cfg.femFile);
%     configureBarriers(cfg);
%
%   See also configureBarriers, matlabFEMM, torqueRipple.

arguments
    options.useMagnets (1,1) logical = false
end

cfg = struct();

% --- Variante ------------------------------------------------------------------
cfg.useMagnets = options.useMagnets;
if cfg.useMagnets
    cfg.motorType = 'PMaSynRM';
else
    cfg.motorType = 'SynRM';
end

% --- Modèle FEMM ------------------------------------------------------------------
cfg.femFile  = 'femmSynrelLaplace.fem'; % casse exacte (Linux y est sensible)
cfg.p        = 2;        % paires de pôles
cfg.m        = 2;        % nombre de phases
cfg.phaseShift = [0 pi/2]; % [rad] déphasage des phases (machine diphasée)
cfg.circuits = {'phase1', 'phase2'}; % noms des circuits FEMM
cfg.L_active = 19.3e-3;  % [m] longueur active
cfg.nSym     = 4;        % le modèle représente 1/4 de la machine
cfg.rotorGroup = 1;      % groupe FEMM des régions du rotor
cfg.gapBoundary = 'BandeRoulement1'; % condition d'entrefer (rotation du rotor)
cfg.smartMesh = 0;

% --- Barrières de flux du rotor (coordonnées des étiquettes du .fem) -------------
% 4 couches de barrières par pôle. Les 3 couches intérieures sont coupées en
% deux par une nervure centrale sur l'axe du pôle (45°) ; la couche extérieure
% est une seule région. Chaque ligne = une région, repérée par son étiquette.
cfg.barrierLabels = [ ...
    0.012484449195535914  0.0096839314477170247   % couche 1, demi-barrière
    0.0096839314477170316 0.012484449195535909    % couche 1, demi-barrière
    0.019506951868024862  0.015131142887057848    % couche 2
    0.015131142887057858  0.019506951868024851    % couche 2
    0.024968898391071827  0.019367862895434049    % couche 3
    0.019367862895434063  0.024968898391071817    % couche 3
    0.030010695181576709  0.02327868136470438];   % couche 4 (région unique)

% --- Aimants (valeurs de machine_modeling/parametres_machine.m, MSAP) ------------
mu0 = 4*pi*1e-7;                                 % [H/m]
cfg.magnet.name    = 'NdFeB_LCA';                % matériau créé dans FEMM
cfg.magnet.Br      = 1.1;                        % [T] induction rémanente (B_aimant)
cfg.magnet.muR     = 1.1;                        % [-] perméabilité relative (mur_a)
cfg.magnet.Hc      = cfg.magnet.Br/(mu0*cfg.magnet.muR); % [A/m] champ coercitif
cfg.magnet.sigma   = 0.667;                      % [MS/m] conductivité (sans effet en magnétostatique)
cfg.magnet.density = 7500;                       % [kg/m^3] masse volumique NdFeB
cfg.magnet.dirDeg  = 225;                        % [°] aimantation sur l'axe q du pôle
                                                 % (axe de symétrie des barrières, 45°),
                                                 % orientée vers l'arbre. Avec 45° le
                                                 % couple des aimants s'oppose au couple
                                                 % de réluctance pour beta = 45°
                                                 % (convention de SetProblemType) ;
                                                 % 225° le rend additif.

% --- Masses volumiques (20 °C) ---------------------------------------------------
cfg.rho.steel  = 7850;  % [kg/m^3] tôles magnétiques (M270-35A typique)
cfg.rho.copper = 8960;  % [kg/m^3] cuivre
cfg.rho.magnet = cfg.magnet.density;

% --- Bobinage --------------------------------------------------------------------
cfg.winding.Jcu   = 5e6;  % [A/m^2] densité de courant (limite thermique)
cfg.winding.n_cs  = 30;   % [-] conducteurs par encoche
cfg.winding.kfill = 0.7;  % [-] coefficient de remplissage
end
