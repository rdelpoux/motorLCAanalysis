%% LIFETIME ENERGY LOSSES AND LCA ANALYSIS
% This script calculates motor LCA considering lifetime energy losses
%
% Energy losses formula: E_losses = P_nom × f_load × t_life × (1 - η)
% Where:
%   P_nom: Nominal power (kW)
%   f_load: Load factor (0.3 to 0.7)
%   t_life: Cumulative operating hours (h)
%   η: Motor efficiency (typically 0.80 for 80%)
%
% Note: Only losses contribute to environmental impact during use phase
% Example: Small motor (1 kW), 20,000 h, f_load = 0.5, η = 0.80
%   E_losses = 1 × 0.5 × 20,000 × (1-0.80) = 2,000 kWh = 2 MWh
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
USE_DATABASE = true;  % Change to true to use database

fprintf('===== LIFETIME ENERGY LOSSES AND LCA ANALYSIS =====\n');
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
t_life = 10000;     % Lifetime operating hours (h)
f_load = 0.5;       % Load factor (0.3 to 0.7)
eta = 0.80;         % Motor efficiency (80%)

% Calculate lifetime energy losses (only losses contribute to LCA)
E_pertes = P_nom * f_load * t_life * (1 - eta);  % kWh

fprintf('Motor specifications:\n');
fprintf('  Nominal power: %.1f kW\n', P_nom);
fprintf('  Operating hours: %.0f h\n', t_life);
fprintf('  Load factor: %.2f\n', f_load);
fprintf('  Motor efficiency: %.1f%%\n', eta*100);
fprintf('  Lifetime energy losses: %.0f kWh (%.1f MWh)\n\n', E_pertes, E_pertes/1000);

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

% Combine manufacturing and lifetime energy losses
totalMaterials = [
    baseMaterials;
    {'market for electricity, low voltage', E_pertes}  % E_pertes represents losses only
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
results_life.E_pertes = P_nom * f_load * t_life_range * (1 - eta);  % Energy losses
results_life.TotalScore = zeros(1, n_points);
results_life.ManufacturingScore = manufacturing_score * ones(1, n_points);
results_life.UsePhaseScore = zeros(1, n_points);

for i = 1:n_points
    E_current = results_life.E_pertes(i);
    currentMaterials = [baseMaterials; {'market for electricity, low voltage', E_current}];
    impacts = calculateMotorLCA(motorRAWmaterials, currentMaterials);
    results_life.TotalScore(i) = impacts.TotalUniqueScore;
    results_life.UsePhaseScore(i) = impacts.TotalUniqueScore - manufacturing_score;
end

fprintf('Lifetime analysis complete!\n\n');

%% Step 6b: Parametric analysis - Vary efficiency
fprintf('Step 6b: Parametric analysis - Efficiency variation...\n\n');

% Define efficiency values to test
eta_values = [0.80, 0.85, 0.90, 0.95];
n_eta = length(eta_values);

% Store results for each efficiency
results_eta = struct();
results_eta.eta_values = eta_values;
results_eta.t_life = t_life_range;
results_eta.UsePhasePercentage = zeros(n_eta, n_points);

for j = 1:n_eta
    eta_current = eta_values(j);
    fprintf('  Calculating for η = %.0f%%...\n', eta_current*100);

    for i = 1:n_points
        % Calculate energy losses for current efficiency
        E_current = P_nom * f_load * t_life_range(i) * (1 - eta_current);

        % Calculate total impact
        currentMaterials = [baseMaterials; {'market for electricity, low voltage', E_current}];
        impacts = calculateMotorLCA(motorRAWmaterials, currentMaterials);

        % Calculate use phase percentage
        use_score = impacts.TotalUniqueScore - manufacturing_score;
        results_eta.UsePhasePercentage(j, i) = 100 * use_score / impacts.TotalUniqueScore;
    end
end

fprintf('Efficiency analysis complete!\n\n');

%% Step 7: Visualizations
fprintf('Step 7: Creating visualizations...\n');

% Figure 1: Phase comparison (pie chart)
figure('Theme', 'light', 'Name', 'Life Cycle Phases', 'NumberTitle', 'off', 'Position', [100, 100, 800, 400]);

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

% Figure 1b: Impact categories by life cycle phase
figure('Theme', 'light', 'Name', 'Impact Categories by Phase', 'NumberTitle', 'off', 'Position', [120, 120, 1400, 600]);

% Get normalized impacts for manufacturing and total
impactCategories = fieldnames(manufacturingImpacts.TotalNormalizedImpacts);
nCategories = length(impactCategories);
manufImpacts = zeros(nCategories, 1);
totalImpacts = zeros(nCategories, 1);

for i = 1:nCategories
    manufImpacts(i) = manufacturingImpacts.TotalNormalizedImpacts.(impactCategories{i});
    totalImpacts(i) = motorImpacts.TotalNormalizedImpacts.(impactCategories{i});
end

% Calculate use phase impacts
useImpacts = totalImpacts - manufImpacts;

% Sort by total value
[~, sortIdx] = sort(totalImpacts, 'descend');
manufImpacts_sorted = manufImpacts(sortIdx);
useImpacts_sorted = useImpacts(sortIdx);
impactCategories_sorted = impactCategories(sortIdx);

% Create stacked bar chart
barData = [manufImpacts_sorted, useImpacts_sorted];
bar(barData, 'stacked');
ax = gca;
ax.XTick = 1:length(impactCategories_sorted);
ax.XTickLabel = impactCategories_sorted;
ylabel('Normalized Impact');
title('Normalized Impacts by Environmental Category and Life Cycle Phase');
legend('Manufacturing', 'Use Phase', 'Location', 'best');
grid on;
xtickangle(45);
set(gca, 'FontSize', 10);

% Figure 2: Lifetime analysis
figure('Theme', 'light', 'Name', 'Lifetime Analysis', 'NumberTitle', 'off', 'Position', [150, 150, 1200, 500]);

subplot(1, 3, 1);
plot(results_life.t_life/1000, results_life.E_pertes/1000, 'b-o', 'LineWidth', 2);
grid on;
xlabel('Operating Hours (×1000 h)');
ylabel('Lifetime Energy Losses (MWh)');
title(sprintf('Energy Losses\n(P=%.1f kW, f=%.2f, η=%.0f%%)', P_nom, f_load, eta*100));

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

% Figure 3: Use Phase Percentage for Different Efficiencies
figure('Theme', 'light', 'Name', 'Use Phase vs Efficiency', 'NumberTitle', 'off', 'Position', [170, 170, 900, 600]);

% Define colors and line styles for different efficiencies
colors = [0.8 0.2 0.2;    % Red for 80%
          0.2 0.6 0.8;    % Blue for 85%
          0.2 0.8 0.2;    % Green for 90%
          0.8 0.6 0.2];   % Orange for 95%

hold on;
for j = 1:n_eta
    plot(results_eta.t_life/1000, results_eta.UsePhasePercentage(j,:), ...
        '-o', 'LineWidth', 2.5, 'MarkerSize', 8, 'Color', colors(j,:), ...
        'DisplayName', sprintf('η = %.0f%%', eta_values(j)*100));
end
hold off;

grid on;
xlabel('Heures de fonctionnement (×1000 h)', 'FontSize', 14);
ylabel('Contribution de la phase d''usage (%)', 'FontSize', 14);
title('Pourcentage de l''impact dû à la phase d''usage selon le rendement', 'FontSize', 14);
legend('Location', 'southeast', 'FontSize', 12);
set(gca, 'FontSize', 12);
ylim([0 100]);

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

% Save Figure 1b: Impact Categories by Phase
figure(2);
print(fullfile(figuresDir, 'impact_categories_by_phase'), '-dpng', '-r300');
print(fullfile(figuresDir, 'impact_categories_by_phase'), '-depsc');

% Save Figure 2: Lifetime Analysis
figure(3);
print(fullfile(figuresDir, 'lifetime_analysis'), '-dpng', '-r300');
print(fullfile(figuresDir, 'lifetime_analysis'), '-depsc');

% Save Figure 3: Use Phase vs Efficiency
figure(4);
print(fullfile(figuresDir, 'use_phase_multi_efficiency'), '-dpng', '-r300');
print(fullfile(figuresDir, 'use_phase_multi_efficiency'), '-depsc');

fprintf('Figures saved in %s (PNG and EPS formats)\n\n', figuresDir);

%% Step 8: Key findings
fprintf('===== KEY FINDINGS =====\n');

% At which lifetime does use phase become dominant?
idx_50 = find(100*results_life.UsePhaseScore./results_life.TotalScore >= 50, 1);
if ~isempty(idx_50)
    fprintf('Use phase becomes dominant (>50%%) after %.0f hours (%.1f MWh)\n', ...
        results_life.t_life(idx_50), results_life.E_pertes(idx_50)/1000);
end

% Impact per MWh
impact_per_MWh = use_phase_score / (E_pertes/1000);
fprintf('Impact per MWh of operation: %.4e\n', impact_per_MWh);

% Lifetime impact analysis
fprintf('\nLifetime impact progression:\n');
fprintf('  At 0 h: Manufacturing only = %.4e\n', manufacturing_score);
fprintf('  At %.0f h: Total impact = %.4e (Use phase: %.1f%%)\n', ...
    t_life, total_score, 100*use_phase_score/total_score);

%% Step 9: Save results
fprintf('\n===== SAVING RESULTS =====\n');
save('lifetime_analysis_results.mat', 'motorRAWmaterials', 'baseMaterials', ...
    'P_nom', 't_life', 'f_load', 'E_pertes', 'motorImpacts', ...
    'manufacturingImpacts', 'results_life', 'results_eta');
fprintf('Results saved to lifetime_analysis_results.mat\n');

fprintf('\n===== ANALYSIS COMPLETE =====\n');
