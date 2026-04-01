%% Init FEMM
clear all;clc;


% Load path
showFemm = false;

if ~exist('tmp', 'dir')
    mkdir('tmp')
end


%run ./../generalParam.m

%% Motor Paramters
motorName = 'femmSynRelLaplace.fem';
motor.parameters.p = 2;
motor.parameters.m = 2;
smartMeshVar = 0;


%%
tmpFileName = ['.\tmp\femm_temp_svg'];
addpath('C:\femm42\mfiles');

openfemm(~showFemm);
main_resize(800,800)

% Open Motor file generate by Pyleecan
opendocument(motorName);
smartmesh(smartMeshVar);
svgFileName = [tmpFileName '.fem'];
% Save temporary femm file
mi_saveas(svgFileName);
n_nodes = mi_createmesh; % create mesh
fprintf(['\nNombre de noeuds FEMM = ' num2str(n_nodes) '\n']);
% Def FEMM properties
L_active = 19.3e-3; % [m]
mi_probdef(0, 'meters', 'planar', 1.e-8, L_active, 30,0);

 % We have to save before analyzing it.
            mi_saveas(svgFileName);
            % analyze
            mi_analyse();
            % solution
            mi_loadsolution();

%% ========================================================================
%  MATERIAL VOLUME EXTRACTION (1/4 machine model)
%  ========================================================================

% Initialize materials structure
materials = struct();

% Material densities (at 20°C)
rho_steel  = 7850;  % [kg/m^3] Electrical steel (Silicon steel M270-35A typical)
rho_copper = 8960;  % [kg/m^3] Copper (pure copper)
rho_magnet = 7500;  % [kg/m^3] NdFeB magnets (typical N35-N52 grade)

% ------------------------------------------------------------------------
% 1. MAGNETIC STEEL - STATOR
% ------------------------------------------------------------------------
% Select stator block in FEMM model (center coordinates)
mo_clearblock();
mo_selectblock(0.0379, 0.0380);

% Integrate volume of selected block (code 10 = volume in m^3)
materials.stator_steel.volume_quarter = mo_blockintegral(10);  % [m^3] Volume 1/4 machine
materials.stator_steel.volume_total = 4 * materials.stator_steel.volume_quarter;  % [m^3] Total volume
materials.stator_steel.density = rho_steel;  % [kg/m^3] Material density
materials.stator_steel.mass = materials.stator_steel.volume_total * rho_steel;  % [kg] Total mass
materials.stator_steel.description = 'Laminated magnetic steel sheets - stator';

% ------------------------------------------------------------------------
% 2. MAGNETIC STEEL - ROTOR
% ------------------------------------------------------------------------
% Select rotor block in FEMM model (center coordinates)
mo_clearblock();
mo_selectblock(0.0175, 0.001);

% Integrate volume of selected block
materials.rotor_steel.volume_quarter = mo_blockintegral(10);  % [m^3] Volume 1/4 machine
materials.rotor_steel.volume_total = 4 * materials.rotor_steel.volume_quarter;  % [m^3] Total volume
materials.rotor_steel.density = rho_steel;  % [kg/m^3] Material density
materials.rotor_steel.mass = materials.rotor_steel.volume_total * rho_steel;  % [kg] Total mass
materials.rotor_steel.description = 'Laminated magnetic steel sheets - rotor';

% ------------------------------------------------------------------------
% 3. COPPER - STATOR WINDINGS
% ------------------------------------------------------------------------
% Winding parameters
Jcu   = 5e6;    % [A/m^2] Current density in conductors (thermal limit)
n_cs  = 30;     % [-]     Number of conductors per slot
kfill = 0.7;    % [-]     Slot fill factor (copper filling ratio)

% Select stator slots (multiple blocks selection)
mo_clearblock();
mo_selectblock(0.045, 0.01);   % First slot
mo_selectblock(0.045, 0.014);  % Second slot (multi-selection example)

% Calculate copper volume
Enc_Volume = mo_blockintegral(10);  % [m^3] Total volume of selected slots
S_enc = Enc_Volume / L_active;      % [m^2] Slot cross-section area
V_cond_per_slot = Enc_Volume * kfill;  % [m^3] Copper volume per slot (accounting for fill factor)

% Store in structure
materials.copper.volume_per_slot = V_cond_per_slot;  % [m^3] Copper volume for analyzed slots
materials.copper.fill_factor = kfill;                % [-]   Fill factor
materials.copper.slot_area = S_enc;                  % [m^2] Slot area
materials.copper.density = rho_copper;               % [kg/m^3] Material density
materials.copper.mass_per_slot = V_cond_per_slot * rho_copper;  % [kg] Mass for analyzed slots
materials.copper.mass = 4*4*materials.copper.mass_per_slot;  % [kg] Total mass (4 slots per pole, 4 poles)  
materials.copper.description = 'Copper windings - stator';

% Calculate rated current based on current density
Istator = Jcu * S_enc * kfill / n_cs;  % [A] Rated current per conductor
materials.copper.rated_current = Istator;  % [A] Store rated current

% ------------------------------------------------------------------------
% 4. PERMANENT MAGNETS (if applicable)
% ------------------------------------------------------------------------
% NOTE: This motor is a Synchronous Reluctance Motor (SynRM)
% SynRM motors do NOT use permanent magnets - they rely on magnetic
% reluctance variations in the rotor structure to produce torque.
%
% For PMSM (Permanent Magnet Synchronous Motors), uncomment and adapt:
%
% % Select magnet blocks in FEMM model
% mo_clearblock();
% mo_selectblock(0.020, 0.005);  % Example coordinates for magnet block
%
% % Integrate magnet volume
% materials.magnets.volume_quarter = mo_blockintegral(10);  % [m^3] Volume 1/4 machine
% materials.magnets.volume_total = 4 * materials.magnets.volume_quarter;  % [m^3] Total volume
% materials.magnets.density = rho_magnet;  % [kg/m^3] Material density
% materials.magnets.mass = materials.magnets.volume_total * rho_magnet;  % [kg] Total mass
% materials.magnets.description = 'NdFeB permanent magnets';
% materials.magnets.grade = 'N35';  % Example: magnet grade

% For this SynRM motor, explicitly set magnets to zero
materials.magnets.volume_total = 0;     % [m^3] No magnets in SynRM
materials.magnets.volume_quarter = 0;   % [m^3] No magnets in SynRM
materials.magnets.density = rho_magnet; % [kg/m^3] Material density (reference only)
materials.magnets.mass = 0;             % [kg] No magnet mass in SynRM
materials.magnets.description = 'No permanent magnets - Synchronous Reluctance Motor';

% ------------------------------------------------------------------------
% 5. TOTAL ACTIVE MASS CALCULATION
% ------------------------------------------------------------------------
% Calculate total active mass (sum of all materials)
materials.total.mass_active = materials.stator_steel.mass + ...
                              materials.rotor_steel.mass + ...
                              materials.copper.mass_per_slot + ...
                              materials.magnets.mass;  % [kg] Total active mass

materials.total.volume_active = materials.stator_steel.volume_total + ...
                                materials.rotor_steel.volume_total + ...
                                materials.copper.volume_per_slot + ...
                                materials.magnets.volume_total;  % [m^3] Total active volume

%% ========================================================================
%  SAVE MATERIALS STRUCTURE
%  ========================================================================

% Display summary in console
fprintf('\n========================================\n');
fprintf('EXTRACTED MATERIALS SUMMARY\n');
fprintf('Motor Type: Synchronous Reluctance Motor (SynRM)\n');
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
fprintf('\nPERMANENT MAGNETS:\n');
fprintf('  Total volume: %.6e m^3 (SynRM - no magnets)\n', materials.magnets.volume_total);
fprintf('  Density:      %.0f kg/m^3 (reference)\n', materials.magnets.density);
fprintf('  Total mass:   %.6f kg\n', materials.magnets.mass);
fprintf('  Description:  %s\n', materials.magnets.description);
fprintf('========================================\n');
fprintf('TOTAL ACTIVE MASS:   %.6f kg\n', materials.total.mass_active);
fprintf('TOTAL ACTIVE VOLUME: %.6e m^3\n', materials.total.volume_active);
fprintf('========================================\n\n');

% Save structure to .mat file
save('tmp/motor_materials.mat', 'materials');
fprintf('Materials structure saved in: tmp/motor_materials.mat\n\n');


