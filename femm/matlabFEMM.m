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
% See also motorConfig, configureBarriers, torqueRipple, femmSetup.

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
useMagnets = true;   % true : barrières de flux remplies d'aimants (PMa-SynRM)
                     % false : barrières en air (SynRM de référence)

% Paramètres partagés (modèle, barrières de flux, aimants, masses volumiques)
cfg = motorConfig(useMagnets = useMagnets);
motorType = cfg.motorType;
motorName = cfg.femFile;
L_active  = cfg.L_active;            % [m] longueur active
nSym      = cfg.nSym;                % le modèle représente 1/4 de la machine
barrierLabels = cfg.barrierLabels;   % régions de barrières de flux (étiquettes)
magnet    = cfg.magnet;              % propriétés des aimants (machine_modeling)
smartMeshVar = cfg.smartMesh;

% --- Masses volumiques (20 °C) ------------------------------------------------
rho_steel  = cfg.rho.steel;   % [kg/m^3] tôles magnétiques
rho_copper = cfg.rho.copper;  % [kg/m^3] cuivre
rho_magnet = cfg.rho.magnet;  % [kg/m^3] NdFeB

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
configureBarriers(cfg);

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
Jcu   = cfg.winding.Jcu;    % [A/m^2] densité de courant (limite thermique)
n_cs  = cfg.winding.n_cs;   % [-]     conducteurs par encoche
kfill = cfg.winding.kfill;  % [-]     coefficient de remplissage

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
