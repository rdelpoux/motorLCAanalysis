%% IMPROVED PLOTTING - Motor LCA Analysis
% This script creates better visualizations for the LCA results
% with improved readability
%
% Usage: Run after example_usage.m or after loading motor_lca_results.mat
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

%% Check if results exist
if ~exist('motorImpacts', 'var')
    error('Please run example_usage.m first or load motor_lca_results.mat');
end

fprintf('===== Creating Improved Visualizations =====\n');

%% Prepare data
nMaterials = length(motorImpacts.MaterialContributions);
scores = zeros(nMaterials, 1);
materialNames = cell(nMaterials, 1);

for i = 1:nMaterials
    scores(i) = motorImpacts.MaterialContributions(i).uniqueScore;
    materialNames{i} = motorImpacts.MaterialContributions(i).name;
end

impactCategories = fieldnames(motorImpacts.TotalNormalizedImpacts);
impactValues = zeros(length(impactCategories), 1);
for i = 1:length(impactCategories)
    impactValues(i) = motorImpacts.TotalNormalizedImpacts.(impactCategories{i});
end

%% Figure 1: Material contributions (horizontal bar for better readability)
figure('Name', 'Material Contributions', 'NumberTitle', 'off', 'Position', [100, 100, 800, 500]);

barh(scores);
ax = gca;
ax.YTick = 1:nMaterials;
ax.YTickLabel = materialNames;
xlabel('Unique Score Contribution');
title('Material Contributions to Motor Environmental Impact');
grid on;

fprintf('Figure 1: Material contributions created\n');

%% Figure 2: Impact categories (horizontal bar for better label visibility)
figure('Name', 'Impact Categories', 'NumberTitle', 'off', 'Position', [150, 150, 900, 700]);

barh(impactValues);
ax = gca;
ax.YTick = 1:length(impactCategories);
ax.YTickLabel = impactCategories;
xlabel('Normalized Impact');
title('Total Impacts by Environmental Category');
grid on;

fprintf('Figure 2: Impact categories created\n');

%% Figure 3: Percentage contributions pie chart
figure('Name', 'Material Contribution Percentages', 'NumberTitle', 'off', 'Position', [200, 200, 800, 600]);

percentages = 100 * scores / motorImpacts.TotalUniqueScore;
pie(percentages, materialNames);
title('Material Contribution Percentages to Total Impact');

fprintf('Figure 3: Pie chart created\n');

%% Figure 4: Top 5 impact categories
figure('Name', 'Top Impact Categories', 'NumberTitle', 'off', 'Position', [250, 250, 800, 500]);

[sortedValues, sortIdx] = sort(impactValues, 'descend');
topN = min(5, length(impactValues));

barh(sortedValues(1:topN));
ax = gca;
ax.YTick = 1:topN;
ax.YTickLabel = impactCategories(sortIdx(1:topN));
xlabel('Normalized Impact');
title(sprintf('Top %d Impact Categories', topN));
grid on;

fprintf('Figure 4: Top impact categories created\n');

%% Figure 5: Detailed breakdown per material and category
figure('Name', 'Detailed Impact Breakdown', 'NumberTitle', 'off', 'Position', [300, 300, 1000, 600]);

% Create matrix for stacked bar chart (categories x materials)
impactMatrix = zeros(length(impactCategories), nMaterials);

for i = 1:nMaterials
    for j = 1:length(impactCategories)
        catName = impactCategories{j};
        if isfield(motorImpacts.MaterialContributions(i).normalizedImpacts, catName)
            impactMatrix(j, i) = motorImpacts.MaterialContributions(i).normalizedImpacts.(catName);
        end
    end
end

% Plot top 5 categories as stacked bars
[~, topCatIdx] = sort(sum(impactMatrix, 2), 'descend');
topCats = min(5, length(impactCategories));

bar(impactMatrix(topCatIdx(1:topCats), :)', 'stacked');
ax = gca;
ax.XTick = 1:nMaterials;
ax.XTickLabel = materialNames;
ylabel('Normalized Impact');
title(sprintf('Top %d Impact Categories by Material (Stacked)', topCats));
legend(impactCategories(topCatIdx(1:topCats)), 'Location', 'best');
grid on;
xtickangle(45);

fprintf('Figure 5: Detailed breakdown created\n');

%% Summary
fprintf('\n===== Visualization Summary =====\n');
fprintf('Created 5 figures:\n');
fprintf('  1. Material contributions (horizontal bar)\n');
fprintf('  2. All impact categories (horizontal bar)\n');
fprintf('  3. Material contribution percentages (pie chart)\n');
fprintf('  4. Top 5 impact categories\n');
fprintf('  5. Detailed breakdown per material\n');
fprintf('\nAll figures are resizable and can be saved via File > Save As\n');
