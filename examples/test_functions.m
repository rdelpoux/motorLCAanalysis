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

fprintf('===== TESTING MOTOR LCA FUNCTIONS =====\n\n');

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

%% Test 3: Calculate Motor LCA
fprintf('\nTest 3: Calculating motor LCA with sample quantities...\n');
try
    % Define sample quantities as cell array {name, quantity}
    materialQuantities = {
        'market for permanent magnet, for electric motor', 0.8;
        'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3;
        'market for copper, cathode', 5.2;
        'market for electricity, low voltage', 100
    };

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
