%% EXAMPLE USAGE - Motor LCA Analysis
% This script demonstrates how to use the motor LCA analysis functions
%
% Workflow:
% 1. Import material data from CSV
% 2. Calculate normalized impacts and unique scores
% 3. Define material quantities for a specific motor
% 4. Calculate total impacts for the motor
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

%% Clear workspace
clear all;
close all;
clc;

%% Step 1: Import material data from CSV
fprintf('===== STEP 1: Import Material Data =====\n');

% Path to your CSV file (adjust path as needed)
csvFilePath = 'CSV_Impact_Machine.csv';

% Import materials
motorRAWmaterials = importMotorMaterialsCSV(csvFilePath);

% Display imported materials
fprintf('\nImported materials:\n');
for i = 1:length(motorRAWmaterials)
    fprintf('  ID %d: %s\n', motorRAWmaterials(i).id, char(motorRAWmaterials(i).name));
end

%% Step 2: Calculate normalized impacts and unique scores
fprintf('\n===== STEP 2: Calculate LCA Impacts =====\n');

motorRAWmaterials = calculateLCAImpacts(motorRAWmaterials);

% Display unique scores for each material
fprintf('\nUnique scores per kg of material:\n');
for i = 1:length(motorRAWmaterials)
    fprintf('  %s: %.4e\n', char(motorRAWmaterials(i).name), ...
        motorRAWmaterials(i).UniqueScore);
end

%% Step 3: Define material quantities for a specific motor
fprintf('\n===== STEP 3: Define Motor Configuration =====\n');

% Define the quantities of each material in your motor as cell array
% Material names must match the 'name' field in your CSV file
% Format: {material_name, quantity}
materialQuantities = {
    'market for permanent magnet, for electric motor', 0.8;   % kg
    'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3;  % kg
    'market for copper, cathode', 5.2;   % kg
    'market for electricity, low voltage', 10000   % kWh (for motor production)
};

fprintf('\nMotor configuration:\n');
for i = 1:size(materialQuantities, 1)
    fprintf('  %s: %.2f\n', materialQuantities{i,1}, materialQuantities{i,2});
end

%% Step 4: Calculate total impacts for the motor
fprintf('\n===== STEP 4: Calculate Motor LCA =====\n');

motorImpacts = calculateMotorLCA(motorRAWmaterials, materialQuantities);

%% Step 5: Analyze and visualize results
fprintf('\n===== STEP 5: Results Analysis =====\n');

% Display detailed normalized impacts
fprintf('\nTotal Normalized Impacts:\n');
impactCategories = fieldnames(motorImpacts.TotalNormalizedImpacts);
for i = 1:length(impactCategories)
    fprintf('  %s: %.4e\n', impactCategories{i}, ...
        motorImpacts.TotalNormalizedImpacts.(impactCategories{i}));
end

%% Optional: Create visualization
fprintf('\n===== Creating Visualization =====\n');

% Bar chart of material contributions to unique score
nMaterials = length(motorImpacts.MaterialContributions);
scores = zeros(nMaterials, 1);
materialNames = cell(nMaterials, 1);

for i = 1:nMaterials
    scores(i) = motorImpacts.MaterialContributions(i).uniqueScore;
    materialNames{i} = motorImpacts.MaterialContributions(i).name;
end

figure('Name', 'Motor LCA Analysis', 'NumberTitle', 'off');

% Subplot 1: Material contribution to unique score
subplot(2, 1, 1);
bar(scores);
ax = gca;
ax.XTick = 1:length(materialNames);
ax.XTickLabel = materialNames;
ylabel('Unique Score Contribution');
title('Material Contributions to Motor Environmental Impact');
grid on;
xtickangle(45);

% Subplot 2: Impact categories breakdown
subplot(2, 1, 2);
impactValues = zeros(length(impactCategories), 1);
for i = 1:length(impactCategories)
    impactValues(i) = motorImpacts.TotalNormalizedImpacts.(impactCategories{i});
end

bar(impactValues);
ax = gca;
ax.XTick = 1:length(impactCategories);  % Force toutes les positions
ax.XTickLabel = impactCategories;        % Assigner tous les labels
ylabel('Normalized Impact');
title('Total Impacts by Environmental Category');
grid on;
xtickangle(45);

fprintf('\nVisualization complete!\n');

%% Save results to file (optional)
fprintf('\n===== Saving Results =====\n');

% Save workspace
save('motor_lca_results.mat', 'motorRAWmaterials', 'motorImpacts', 'materialQuantities');
fprintf('Results saved to motor_lca_results.mat\n');

% Export summary to text file
fid = fopen('motor_lca_summary.txt', 'w');
fprintf(fid, 'MOTOR LCA ANALYSIS SUMMARY\n');
fprintf(fid, '==========================\n\n');
fprintf(fid, 'Total Unique Score: %.4e\n\n', motorImpacts.TotalUniqueScore);
fprintf(fid, 'Material Quantities:\n');
for i = 1:length(motorImpacts.MaterialContributions)
    matData = motorImpacts.MaterialContributions(i);
    fprintf(fid, '  %s: %.2f %s (Score: %.4e)\n', matData.name, ...
        matData.quantity, char(matData.unit), matData.uniqueScore);
end
fclose(fid);
fprintf('Summary exported to motor_lca_summary.txt\n');

fprintf('\n===== ANALYSIS COMPLETE =====\n');
