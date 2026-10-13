%% Extraction des matériaux actifs d'une machine (SynRM ou PMa-SynRM) sous FEMM
% Ce script ouvre le modèle FEMM d'un quart de machine à réluctance variable
% (femmSynrelLaplace.fem), le résout, puis intègre les volumes des régions
% (tôles stator/rotor, cuivre, aimants) pour alimenter l'ACV.
%
% Paramètre principal : useMagnets. S'il vaut true, les barrières de flux du
% rotor sont remplies d'aimants NdFeB (même géométrie, machine assistée par
% aimants, PMa-SynRM) et la quantité d'aimants est calculée. Sinon la machine
% reste une SynRM pure (barrières en air, masse d'aimants nulle).
%
% Les propriétés des aimants reprennent celles du projet machine_modeling
% (sources/Lien vers machine_modeling, parametres_machine.m, topologie MSAP) :
% Br = 1,1 T et mu_r = 1,1.
%
% See also SetProblemType, femmSetup.

clearvars; clc;

% Se placer dans le dossier du script : FEMM résout les chemins relatifs
% (tmp/, fichier .fem) depuis le dossier courant de MATLAB au moment de openfemm
cd(fileparts(mfilename('fullpath')));

% Pont FEMM portable : ActiveX sous Windows, wine femm.exe -filelink sous Linux
% (déployé par la skill femmLinux, voir femmLinux/wine/README.md)
addpath(fullfile(pwd, 'femmLinux'));
femmSetup();

showFemm = false;

if ~exist('tmp', 'dir')
    mkdir('tmp')
end

%% Configuration de la machine
% --- Choix de la variante ----------------------------------------------------
useMagnets = true;    % true : barrières de flux remplies d'aimants (PMa-SynRM)
                     % false : barrières en air (SynRM de référence)

% --- Modèle FEMM --------------------------------------------------------------
motorName = 'femmSynrelLaplace.fem'; % casse exacte du fichier (Linux y est sensible)
motor.parameters.p = 2;              % paires de pôles
motor.parameters.m = 2;              % nombre de phases
L_active = 19.3e-3;                  % [m] longueur active
nSym = 4;                            % le modèle représente 1/4 de la machine
smartMeshVar = 0;

% --- Barrières de flux du rotor (coordonnées des étiquettes du .fem) ---------
% 4 couches de barrières par pôle. Les 3 couches intérieures sont coupées en
% deux par une nervure centrale sur l'axe du pôle (45°) ; la couche extérieure
% est une seule région. Chaque ligne = une région, repérée par son étiquette.
barrierLabels = [ ...
    0.012484449195535914  0.0096839314477170247   % couche 1, demi-barrière
    0.0096839314477170316 0.012484449195535909    % couche 1, demi-barrière
    0.019506951868024862  0.015131142887057848    % couche 2
    0.015131142887057858  0.019506951868024851    % couche 2
    0.024968898391071827  0.019367862895434049    % couche 3
    0.019367862895434063  0.024968898391071817    % couche 3
    0.030010695181576709  0.02327868136470438];   % couche 4 (région unique)
rotorGroup = 1;                      % groupe FEMM des régions du rotor

% --- Aimants (valeurs de machine_modeling/parametres_machine.m, MSAP) --------
mu0 = 4*pi*1e-7;                     % [H/m]
magnet.name     = 'NdFeB_LCA';       % nom du matériau créé dans FEMM
magnet.Br       = 1.1;               % [T] induction rémanente (B_aimant)
magnet.muR      = 1.1;               % [-] perméabilité relative (mur_a)
magnet.Hc       = magnet.Br/(mu0*magnet.muR); % [A/m] champ coercitif
magnet.sigma    = 0.667;             % [MS/m] conductivité (sans effet en magnétostatique)
magnet.density  = 7500;              % [kg/m^3] masse volumique NdFeB
magnet.dirDeg   = 45;                % [°] direction d'aimantation : axe q du pôle
                                     % (axe de symétrie des barrières, 45° dans
                                     % le quart de machine). Le signe (45 ou
                                     % 225) doit rester cohérent avec la
                                     % convention de courant de SetProblemType.

% --- Masses volumiques (20 °C) ------------------------------------------------
rho_steel  = 7850;  % [kg/m^3] tôles magnétiques (M270-35A typique)
rho_copper = 8960;  % [kg/m^3] cuivre
rho_magnet = magnet.density;

if useMagnets
    motorType = 'PMaSynRM';
else
    motorType = 'SynRM';
end

%% Ouverture du modèle et configuration des barrières
tmpFileName = fullfile('tmp', ['femm_' motorType]); % séparateurs portables

openfemm(~showFemm);
main_resize(800,800)

% Ouverture du modèle (issu de Pyleecan)
opendocument(motorName);
smartmesh(smartMeshVar);
svgFileName = [tmpFileName '.fem'];
mi_saveas(svgFileName);

% Remplissage des barrières de flux : aimants ou air
if useMagnets
    % Matériau aimant : mu_x, mu_y, H_c, J, Cduct, Lam_d, Phi_hmax, lam_fill,
    % LamType, Phi_hx, Phi_hy
    mi_addmaterial(magnet.name, magnet.muR, magnet.muR, magnet.Hc, ...
        0, magnet.sigma, 0, 0, 1, 0, 0, 0);
    barrierMaterial = magnet.name;
    barrierMagDir   = magnet.dirDeg;
else
    barrierMaterial = 'Air';
    barrierMagDir   = 0;
end

for k = 1:size(barrierLabels, 1)
    mi_clearselected();
    mi_selectlabel(barrierLabels(k,1), barrierLabels(k,2));
    % blockname, automesh, meshsize, incircuit, magdir, group, turns
    mi_setblockprop(barrierMaterial, 1, 0, '<None>', barrierMagDir, rotorGroup, 0);
end
mi_clearselected();

n_nodes = mi_createmesh; % maillage
fprintf('\nVariante : %s\n', motorType);
fprintf('Nombre de noeuds FEMM = %d\n', n_nodes);
mi_probdef(0, 'meters', 'planar', 1.e-8, L_active, 30, 0);

% Sauvegarde obligatoire avant résolution
mi_saveas(svgFileName);
mi_analyse();
mi_loadsolution();

%% ========================================================================
%  EXTRACTION DES VOLUMES DE MATÉRIAUX (modèle 1/4 de machine)
%  ========================================================================

materials = struct();
materials.motorType = motorType;
materials.useMagnets = useMagnets;

% ------------------------------------------------------------------------
% 1. TÔLES MAGNÉTIQUES - STATOR
% ------------------------------------------------------------------------
mo_clearblock();
mo_selectblock(0.0379, 0.0380);

% Intégrale de volume du bloc sélectionné (code 10 = volume en m^3)
materials.stator_steel.volume_quarter = mo_blockintegral(10);  % [m^3] 1/4 machine
materials.stator_steel.volume_total = nSym * materials.stator_steel.volume_quarter;  % [m^3]
materials.stator_steel.density = rho_steel;  % [kg/m^3]
materials.stator_steel.mass = materials.stator_steel.volume_total * rho_steel;  % [kg]
materials.stator_steel.description = 'Laminated magnetic steel sheets - stator';

% ------------------------------------------------------------------------
% 2. TÔLES MAGNÉTIQUES - ROTOR
% ------------------------------------------------------------------------
mo_clearblock();
mo_selectblock(0.0175, 0.001);

materials.rotor_steel.volume_quarter = mo_blockintegral(10);  % [m^3] 1/4 machine
materials.rotor_steel.volume_total = nSym * materials.rotor_steel.volume_quarter;  % [m^3]
materials.rotor_steel.density = rho_steel;  % [kg/m^3]
materials.rotor_steel.mass = materials.rotor_steel.volume_total * rho_steel;  % [kg]
materials.rotor_steel.description = 'Laminated magnetic steel sheets - rotor';

% ------------------------------------------------------------------------
% 3. CUIVRE - BOBINAGE STATOR
% ------------------------------------------------------------------------
Jcu   = 5e6;    % [A/m^2] densité de courant (limite thermique)
n_cs  = 30;     % [-]     conducteurs par encoche
kfill = 0.7;    % [-]     coefficient de remplissage

% Sélection des encoches (sélection multiple)
mo_clearblock();
mo_selectblock(0.045, 0.01);   % première encoche
mo_selectblock(0.045, 0.014);  % seconde encoche

Enc_Volume = mo_blockintegral(10);  % [m^3] volume des encoches sélectionnées
S_enc = Enc_Volume / L_active;      % [m^2] section d'encoche
V_cond_per_slot = Enc_Volume * kfill;  % [m^3] volume de cuivre (avec remplissage)

materials.copper.volume_per_slot = V_cond_per_slot;  % [m^3]
materials.copper.fill_factor = kfill;                % [-]
materials.copper.slot_area = S_enc;                  % [m^2]
materials.copper.density = rho_copper;               % [kg/m^3]
materials.copper.mass_per_slot = V_cond_per_slot * rho_copper;  % [kg]
materials.copper.mass = 4*4*materials.copper.mass_per_slot;  % [kg] (4 encoches par pôle, 4 pôles)
materials.copper.description = 'Copper windings - stator';

% Courant nominal déduit de la densité de courant
Istator = Jcu * S_enc * kfill / n_cs;  % [A] par conducteur
materials.copper.rated_current = Istator;  % [A]

% ------------------------------------------------------------------------
% 4. AIMANTS PERMANENTS (barrières de flux du rotor)
% ------------------------------------------------------------------------
% Volume de chaque région de barrière, aimant ou air selon useMagnets
nBarriers = size(barrierLabels, 1);
barrierVolumes = zeros(nBarriers, 1);
for k = 1:nBarriers
    mo_clearblock();
    mo_selectblock(barrierLabels(k,1), barrierLabels(k,2));
    barrierVolumes(k) = mo_blockintegral(10);  % [m^3] 1/4 machine
end
mo_clearblock();

materials.barriers.volume_each_quarter = barrierVolumes;     % [m^3] par région, 1/4 machine
materials.barriers.volume_quarter = sum(barrierVolumes);     % [m^3] 1/4 machine
materials.barriers.volume_total = nSym * sum(barrierVolumes); % [m^3] machine complète
materials.barriers.n_regions = nBarriers;

materials.magnets.density = rho_magnet;      % [kg/m^3]
materials.magnets.material = magnet.name;
materials.magnets.Br = magnet.Br;            % [T]
materials.magnets.mu_r = magnet.muR;         % [-]
materials.magnets.Hc = magnet.Hc;            % [A/m]
materials.magnets.direction_deg = magnet.dirDeg; % [°]
if useMagnets
    materials.magnets.volume_quarter = materials.barriers.volume_quarter; % [m^3]
    materials.magnets.volume_total = materials.barriers.volume_total;     % [m^3]
    materials.magnets.mass = materials.magnets.volume_total * rho_magnet; % [kg]
    materials.magnets.description = 'NdFeB permanent magnets in rotor flux barriers (PMa-SynRM)';
else
    materials.magnets.volume_quarter = 0;  % [m^3]
    materials.magnets.volume_total = 0;    % [m^3]
    materials.magnets.mass = 0;            % [kg]
    materials.magnets.description = 'No permanent magnets - Synchronous Reluctance Motor';
end

% ------------------------------------------------------------------------
% 5. MASSE ACTIVE TOTALE
% ------------------------------------------------------------------------
materials.total.mass_active = materials.stator_steel.mass + ...
                              materials.rotor_steel.mass + ...
                              materials.copper.mass_per_slot + ...
                              materials.magnets.mass;  % [kg]

materials.total.volume_active = materials.stator_steel.volume_total + ...
                                materials.rotor_steel.volume_total + ...
                                materials.copper.volume_per_slot + ...
                                materials.magnets.volume_total;  % [m^3]

%% ========================================================================
%  SAUVEGARDE DE LA STRUCTURE
%  ========================================================================

fprintf('\n========================================\n');
fprintf('EXTRACTED MATERIALS SUMMARY\n');
fprintf('Motor Type: %s\n', motorType);
fprintf('========================================\n');
fprintf('STATOR STEEL:\n');
fprintf('  Total volume: %.6e m^3\n', materials.stator_steel.volume_total);
fprintf('  Volume 1/4:   %.6e m^3\n', materials.stator_steel.volume_quarter);
fprintf('  Density:      %.0f kg/m^3\n', materials.stator_steel.density);
fprintf('  Total mass:   %.6f kg\n', materials.stator_steel.mass);
fprintf('\nROTOR STEEL:\n');
fprintf('  Total volume: %.6e m^3\n', materials.rotor_steel.volume_total);
fprintf('  Volume 1/4:   %.6e m^3\n', materials.rotor_steel.volume_quarter);
fprintf('  Density:      %.0f kg/m^3\n', materials.rotor_steel.density);
fprintf('  Total mass:   %.6f kg\n', materials.rotor_steel.mass);
fprintf('\nCOPPER:\n');
fprintf('  Volume per slot:  %.6e m^3\n', materials.copper.volume_per_slot);
fprintf('  Density:          %.0f kg/m^3\n', materials.copper.density);
fprintf('  Mass per slot:    %.6f kg\n', materials.copper.mass_per_slot);
fprintf('  Fill factor:      %.2f\n', materials.copper.fill_factor);
fprintf('  Rated current:    %.2f A\n', materials.copper.rated_current);
fprintf('\nFLUX BARRIERS (%d regions, 1/4 machine):\n', nBarriers);
fprintf('  Region volumes:  %s m^3\n', mat2str(barrierVolumes', 4));
fprintf('  Total volume:    %.6e m^3 (full machine)\n', materials.barriers.volume_total);
fprintf('\nPERMANENT MAGNETS:\n');
fprintf('  Material:     %s (Br = %.2f T, mu_r = %.2f, Hc = %.0f A/m)\n', ...
    magnet.name, magnet.Br, magnet.muR, magnet.Hc);
fprintf('  Total volume: %.6e m^3\n', materials.magnets.volume_total);
fprintf('  Density:      %.0f kg/m^3\n', materials.magnets.density);
fprintf('  Total mass:   %.6f kg\n', materials.magnets.mass);
fprintf('  Description:  %s\n', materials.magnets.description);
fprintf('========================================\n');
fprintf('TOTAL ACTIVE MASS:   %.6f kg\n', materials.total.mass_active);
fprintf('TOTAL ACTIVE VOLUME: %.6e m^3\n', materials.total.volume_active);
fprintf('========================================\n\n');

% Sauvegarde : un fichier par variante + le nom générique lu par le pipeline ACV
outFile = fullfile('tmp', ['motor_materials_' motorType '.mat']);
save(outFile, 'materials');
save(fullfile('tmp', 'motor_materials.mat'), 'materials');
fprintf('Materials structure saved in: %s (and tmp/motor_materials.mat)\n\n', outFile);
