%% QUICK TEST - Motor LCA Functions
% This script performs a quick test of the LCA analysis functions
% to verify they work correctly with CSV_Impact_Machine.csv
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

clear all;
close all;
clc;

%% CONFIGURATION: Choose material source
% Set USE_DATABASE to true to load materials from motor_materials.mat
% Set USE_DATABASE to false to use manually defined quantities
USE_DATABASE = true;  % Change to true to use database

%% CONFIGURATION: Motor specifications for energy calculation
% Energy formula: E_vie = P_nom × f_load × t_life
% Where:
%   P_nom: Nominal power (kW)
%   f_load: Load factor (0.3 to 0.7)
%   t_life: Cumulative operating hours (h)
%
% Example: Small motor (1 kW), 20,000 h, f_load = 0.5
%   E = 1 × 0.5 × 20,000 = 10,000 kWh ≈ 10 MWh
P_nom = 1;          % Nominal power (kW)
t_life = 20000;     % Lifetime operating hours (h)
f_load = 0.5;       % Load factor (0.3 to 0.7)

% Calculate lifetime energy consumption
E_vie = P_nom * f_load * t_life;  % kWh

fprintf('===== TESTING MOTOR LCA FUNCTIONS =====\n');
if USE_DATABASE
    fprintf('Mode: Using material quantities from database\n');
else
    fprintf('Mode: Using manually defined quantities\n');
end
fprintf('\nEnergy configuration:\n');
fprintf('  P_nom = %.1f kW, t_life = %.0f h, f_load = %.2f\n', P_nom, t_life, f_load);
fprintf('  Lifetime energy: E_vie = %.0f kWh (%.1f MWh)\n\n', E_vie, E_vie/1000);

%% Test 1: Import CSV
fprintf('Test 1: Importing CSV file...\n');
try
    motorRAWmaterials = importMotorMaterialsCSV('CSV_Impact_Machine.csv');
    fprintf('  SUCCESS: Imported %d materials\n', length(motorRAWmaterials));

    % Display materials
    fprintf('  Materials found:\n');
    for i = 1:length(motorRAWmaterials)
        fprintf('    %d. %s\n', i, char(motorRAWmaterials(i).name));
    end
catch ME
    fprintf('  ERROR: %s\n', ME.message);
    return;
end

%% Test 2: Calculate LCA Impacts
fprintf('\nTest 2: Calculating LCA impacts...\n');
try
    motorRAWmaterials = calculateLCAImpacts(motorRAWmaterials);
    fprintf('  SUCCESS: Calculated impacts for all materials\n');

    % Display unique scores
    fprintf('  Unique scores (per unit):\n');
    for i = 1:length(motorRAWmaterials)
        fprintf('    %s: %.4e\n', char(motorRAWmaterials(i).name), ...
            motorRAWmaterials(i).UniqueScore);
    end
catch ME
    fprintf('  ERROR: %s\n', ME.message);
    return;
end

%% Test 3: Load or define material quantities
if USE_DATABASE
    fprintf('\nTest 3a: Loading material quantities from database...\n');
    try
        % Get the directory of this script
        scriptDir = fileparts(mfilename('fullpath'));
        dbPath = fullfile(scriptDir, '..', 'database', 'motor_materials.mat');
        load(dbPath, 'materials');

        % Define quantities from database
        materialQuantities = {
            'market for permanent magnet, for electric motor', materials.magnets.mass;
            'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', materials.stator_steel.mass + materials.rotor_steel.mass;
            'market for copper, cathode', materials.copper.mass;
            'market for electricity, low voltage', E_vie
        };

        fprintf('  SUCCESS: Loaded from database\n');
        fprintf('  Stator steel: %.2f kg\n', materials.stator_steel.mass);
        fprintf('  Rotor steel: %.2f kg\n', materials.rotor_steel.mass);
        fprintf('  Copper: %.2f kg\n', materials.copper.mass);
        fprintf('  Magnets: %.2f kg\n', materials.magnets.mass);
    catch ME
        fprintf('  ERROR: %s\n', ME.message);
        return;
    end
else
    fprintf('\nTest 3a: Using manually defined quantities...\n');
    % Define sample quantities as cell array {name, quantity}
    materialQuantities = {
        'market for permanent magnet, for electric motor', 0.8;
        'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 1.5;
        'market for copper, cathode', 0.2;
        'market for electricity, low voltage', E_vie
    };
    fprintf('  Manual quantities defined\n');
    fprintf('  Electricity: %.0f kWh\n', E_vie);
end

%% Test 3b: Calculate Motor LCA
fprintf('\nTest 3b: Calculating motor LCA...\n');
try
    motorImpacts = calculateMotorLCA(motorRAWmaterials, materialQuantities);
    fprintf('  SUCCESS: Motor LCA calculated\n');
    fprintf('  Total Unique Score: %.4e\n', motorImpacts.TotalUniqueScore);
catch ME
    fprintf('  ERROR: %s\n', ME.message);
    return;
end

%% Test 4: Verify Structure Fields
fprintf('\nTest 4: Verifying output structure...\n');
try
    % Check motorRAWmaterials fields
    assert(isfield(motorRAWmaterials(1), 'id'), 'Missing field: id');
    assert(isfield(motorRAWmaterials(1), 'index'), 'Missing field: index');
    assert(isfield(motorRAWmaterials(1), 'name'), 'Missing field: name');
    assert(isfield(motorRAWmaterials(1), 'NormalizedImpacts'), 'Missing field: NormalizedImpacts');
    assert(isfield(motorRAWmaterials(1), 'UniqueScore'), 'Missing field: UniqueScore');

    % Check motorImpacts fields
    assert(isfield(motorImpacts, 'TotalImpacts'), 'Missing field: TotalImpacts');
    assert(isfield(motorImpacts, 'TotalNormalizedImpacts'), 'Missing field: TotalNormalizedImpacts');
    assert(isfield(motorImpacts, 'TotalUniqueScore'), 'Missing field: TotalUniqueScore');
    assert(isfield(motorImpacts, 'MaterialContributions'), 'Missing field: MaterialContributions');

    fprintf('  SUCCESS: All required fields present\n');
catch ME
    fprintf('  ERROR: %s\n', ME.message);
    return;
end

%% Summary
fprintf('\n===== ALL TESTS PASSED =====\n');
fprintf('The LCA analysis functions are working correctly.\n');
fprintf('You can now use these functions for your motor analysis.\n');
