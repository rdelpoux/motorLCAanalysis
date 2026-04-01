%% LIFETIME ENERGY CONSUMPTION AND LCA ANALYSIS
% This script calculates motor LCA considering lifetime energy consumption
%
% Energy formula: E_vie = P_nom × f_load × t_life
% Where:
%   P_nom: Nominal power (kW)
%   f_load: Load factor (0.3 to 0.7)
%   t_life: Cumulative operating hours (h)
%
% Example: Small motor (1 kW), 20,000 h, f_load = 0.5
%   E = 1 × 0.5 × 20,000 = 10,000 kWh ≈ 10 MWh
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

%% Clear workspace
clear all;
close all;
clc;

%% CONFIGURATION: Choose material source
% Set USE_DATABASE to true to load materials from motor_materials.mat
% Set USE_DATABASE to false to use manually defined quantities
USE_DATABASE = false;  % Change to true to use database

fprintf('===== LIFETIME ENERGY CONSUMPTION AND LCA ANALYSIS =====\n');
if USE_DATABASE
    fprintf('===== DATABASE MODE =====\n\n');
else
    fprintf('===== MANUAL MODE =====\n\n');
end

%% Step 1: Import and prepare materials data
fprintf('Step 1: Importing materials data...\n');
motorRAWmaterials = importMotorMaterialsCSV('CSV_Impact_Machine.csv');
motorRAWmaterials = calculateLCAImpacts(motorRAWmaterials);
fprintf('Done!\n\n');

%% Step 2: Define motor specifications
fprintf('Step 2: Defining motor specifications...\n');

% Motor parameters
P_nom = 2;          % Nominal power (kW)
t_life = 20000;      % Lifetime operating hours (h)
f_load = 0.5;     % Load factor (0.3 to 0.7)

% Calculate lifetime energy consumption
E_vie = P_nom * f_load * t_life;  % kWh

fprintf('Motor specifications:\n');
fprintf('  Nominal power: %.1f kW\n', P_nom);
fprintf('  Operating hours: %.0f h\n', t_life);
fprintf('  Load factor: %.2f\n', f_load);
fprintf('  Lifetime energy: %.0f kWh (%.1f MWh)\n\n', E_vie, E_vie/1000);

%% Step 3: Define motor materials (manufacturing phase)
fprintf('Step 3: Defining motor materials...\n');

if USE_DATABASE
    % Load material quantities from database
    fprintf('Loading materials from database...\n');
    scriptDir = fileparts(mfilename('fullpath'));
    dbPath = fullfile(scriptDir, '..', 'database', 'motor_materials.mat');
    load(dbPath, 'materials');

    % Manufacturing materials from database
    baseMaterials = {
        'market for permanent magnet, for electric motor', materials.magnets.mass;
        'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', materials.stator_steel.mass + materials.rotor_steel.mass;
        'market for copper, cathode', materials.copper.mass
    };

    fprintf('Manufacturing materials from database:\n');
    fprintf('  Stator steel: %.2f kg\n', materials.stator_steel.mass);
    fprintf('  Rotor steel: %.2f kg\n', materials.rotor_steel.mass);
    fprintf('  Copper: %.2f kg\n', materials.copper.mass);
    fprintf('  Magnets: %.2f kg\n', materials.magnets.mass);
    fprintf('  Total active mass: %.2f kg\n', materials.total.mass_active);
else
    % Manufacturing materials (manually defined)
    baseMaterials = {
        'market for permanent magnet, for electric motor', 0.8;
        'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3;
        'market for copper, cathode', 5.2
    };

    fprintf('Manufacturing materials (manual):\n');
    for i = 1:size(baseMaterials, 1)
        fprintf('  %s: %.2f kg\n', baseMaterials{i,1}, baseMaterials{i,2});
    end
end
fprintf('\n');

%% Step 4: Calculate total LCA (manufacturing + lifetime energy)
fprintf('Step 4: Calculating total LCA...\n');

% Combine manufacturing and lifetime energy
totalMaterials = [
    baseMaterials;
    {'market for electricity, low voltage', E_vie}
];

% Calculate total impact
motorImpacts = calculateMotorLCA(motorRAWmaterials, totalMaterials);

%% Step 5: Analyze manufacturing vs. use phase
fprintf('\n===== LIFE CYCLE PHASE ANALYSIS =====\n');

% Calculate manufacturing phase only
manufacturingImpacts = calculateMotorLCA(motorRAWmaterials, baseMaterials);

% Manufacturing impact
manufacturing_score = manufacturingImpacts.TotalUniqueScore;
total_score = motorImpacts.TotalUniqueScore;
use_phase_score = total_score - manufacturing_score;

fprintf('Impact breakdown:\n');
fprintf('  Manufacturing phase: %.4e (%.1f%%)\n', manufacturing_score, ...
    100*manufacturing_score/total_score);
fprintf('  Use phase (energy):  %.4e (%.1f%%)\n', use_phase_score, ...
    100*use_phase_score/total_score);
fprintf('  Total:               %.4e (100.0%%)\n\n', total_score);

%% Step 6: Parametric analysis - Vary lifetime hours
fprintf('Step 6: Parametric analysis - Lifetime variation...\n\n');

% Vary lifetime from 0 to t_life hours
t_life_range = linspace(0, t_life, 15);
n_points = length(t_life_range);

results_life = struct();
results_life.t_life = t_life_range;
results_life.E_vie = P_nom * f_load * t_life_range;
results_life.TotalScore = zeros(1, n_points);
results_life.ManufacturingScore = manufacturing_score * ones(1, n_points);
results_life.UsePhaseScore = zeros(1, n_points);

for i = 1:n_points
    E_current = results_life.E_vie(i);
    currentMaterials = [baseMaterials; {'market for electricity, low voltage', E_current}];
    impacts = calculateMotorLCA(motorRAWmaterials, currentMaterials);
    results_life.TotalScore(i) = impacts.TotalUniqueScore;
    results_life.UsePhaseScore(i) = impacts.TotalUniqueScore - manufacturing_score;
end

fprintf('Lifetime analysis complete!\n\n');

%% Step 7: Visualizations
fprintf('Step 7: Creating visualizations...\n');

% Figure 1: Phase comparison (pie chart)
figure('Name', 'Life Cycle Phases', 'NumberTitle', 'off', 'Position', [100, 100, 800, 400]);

subplot(1, 2, 1);
% Calculate percentages
manuf_percent = 100 * manufacturing_score / total_score;
use_percent = 100 * use_phase_score / total_score;
% Use percentages for pie chart
pie([manuf_percent, use_percent], ...
    {sprintf('Manufacturing (%.1f%%)', manuf_percent), ...
     sprintf('Use Phase (%.1f%%)', use_percent)});
title(sprintf('Impact Distribution\n(P=%.1f kW, t=%.0f h, f=%.2f)', P_nom, t_life, f_load));

subplot(1, 2, 2);
bar([manufacturing_score, use_phase_score, total_score]);
set(gca, 'XTickLabel', {'Manufacturing', 'Use Phase', 'Total'});
ylabel('Unique Score');
title('Impact by Life Cycle Phase');
grid on;

% Figure 2: Lifetime analysis
figure('Name', 'Lifetime Analysis', 'NumberTitle', 'off', 'Position', [150, 150, 1200, 500]);

subplot(1, 3, 1);
plot(results_life.t_life/1000, results_life.E_vie/1000, 'b-o', 'LineWidth', 2);
grid on;
xlabel('Operating Hours (×1000 h)');
ylabel('Lifetime Energy (MWh)');
title(sprintf('Energy Consumption\n(P=%.1f kW, f=%.2f)', P_nom, f_load));

subplot(1, 3, 2);
plot(results_life.t_life/1000, results_life.TotalScore, 'r-o', 'LineWidth', 2);
hold on;
plot(results_life.t_life/1000, results_life.ManufacturingScore, '--', 'Color', [0 0.5 0], 'LineWidth', 1.5);  % Dark green
plot(results_life.t_life/1000, results_life.UsePhaseScore, 'b--', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Operating Hours (×1000 h)');
ylabel('Unique Score');
legend('Total', 'Manufacturing', 'Use Phase', 'Location', 'best');
title('Impact vs Lifetime');

subplot(1, 3, 3);
use_percentage = 100 * results_life.UsePhaseScore ./ results_life.TotalScore;
plot(results_life.t_life/1000, use_percentage, 'm-o', 'LineWidth', 2);
grid on;
xlabel('Operating Hours (×1000 h)');
ylabel('Use Phase Contribution (%)');
title('Use Phase Impact Percentage');

fprintf('Visualizations created!\n');

% Save figures
fprintf('Saving figures...\n');
% Get script directory and create figures directory
scriptDir = fileparts(mfilename('fullpath'));
figuresDir = fullfile(scriptDir, 'figures');
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

% Save Figure 1: Life Cycle Phases
figure(1);
print(fullfile(figuresDir, 'life_cycle_phases'), '-dpng', '-r300');
print(fullfile(figuresDir, 'life_cycle_phases'), '-depsc');

% Save Figure 2: Lifetime Analysis
figure(2);
print(fullfile(figuresDir, 'lifetime_analysis'), '-dpng', '-r300');
print(fullfile(figuresDir, 'lifetime_analysis'), '-depsc');

fprintf('Figures saved in %s (PNG and EPS formats)\n\n', figuresDir);

%% Step 8: Key findings
fprintf('===== KEY FINDINGS =====\n');

% At which lifetime does use phase become dominant?
idx_50 = find(100*results_life.UsePhaseScore./results_life.TotalScore >= 50, 1);
if ~isempty(idx_50)
    fprintf('Use phase becomes dominant (>50%%) after %.0f hours (%.1f MWh)\n', ...
        results_life.t_life(idx_50), results_life.E_vie(idx_50)/1000);
end

% Impact per MWh
impact_per_MWh = use_phase_score / (E_vie/1000);
fprintf('Impact per MWh of operation: %.4e\n', impact_per_MWh);

% Lifetime impact analysis
fprintf('\nLifetime impact progression:\n');
fprintf('  At 0 h: Manufacturing only = %.4e\n', manufacturing_score);
fprintf('  At %.0f h: Total impact = %.4e (Use phase: %.1f%%)\n', ...
    t_life, total_score, 100*use_phase_score/total_score);

%% Step 9: Save results
fprintf('\n===== SAVING RESULTS =====\n');
save('lifetime_analysis_results.mat', 'motorRAWmaterials', 'baseMaterials', ...
    'P_nom', 't_life', 'f_load', 'E_vie', 'motorImpacts', ...
    'manufacturingImpacts', 'results_life');
fprintf('Results saved to lifetime_analysis_results.mat\n');

fprintf('\n===== ANALYSIS COMPLETE =====\n');
