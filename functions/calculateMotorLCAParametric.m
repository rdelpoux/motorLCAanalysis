function results = calculateMotorLCAParametric(motorRAWmaterials, baseMaterials, variedMaterial, variedRange)
% CALCULATEMOTORLCAPARAMETRIC Calculate LCA for a range of material quantities
%
% This function performs a parametric sweep, calculating motor LCA impacts
% while varying one material quantity over a specified range.
%
% Syntax:
%   results = calculateMotorLCAParametric(motorRAWmaterials, baseMaterials, variedMaterial, variedRange)
%
% Inputs:
%   motorRAWmaterials - Structure array with material properties and impacts
%                       (from calculateLCAImpacts)
%   baseMaterials     - Cell array of {name, quantity} pairs for fixed materials
%                       Example: {
%                           'market for copper, cathode', 5.2;
%                           'market for steel, ...', 12.3
%                       }
%   variedMaterial    - Name of material to vary (string)
%                       Example: 'market for electricity, low voltage'
%   variedRange       - Array of values to sweep
%                       Example: 1:10:100 (from 1 to 100 by steps of 10)
%                       Or: linspace(1, 100, 20) (20 points from 1 to 100)
%
% Output:
%   results - Structure containing:
%             .variedMaterial: Name of varied material
%             .variedRange: Array of values used
%             .TotalUniqueScore: Array of total unique scores
%             .TotalNormalizedImpacts: Structure with arrays for each category
%             .MaterialContributions: Cell array of contribution details
%             .FullResults: Cell array of complete motorImpacts for each point
%
% Example:
%   % Fix copper and steel, vary electricity from 1 to 100 kWh
%   baseMaterials = {
%       'market for copper, cathode', 5.2;
%       'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3
%   };
%   results = calculateMotorLCAParametric(motorRAWmaterials, baseMaterials, ...
%       'market for electricity, low voltage', 1:10:100);
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

    % Input validation
    if ~iscell(baseMaterials)
        error('baseMaterials must be a cell array of {name, quantity} pairs');
    end

    if ~ischar(variedMaterial) && ~isstring(variedMaterial)
        error('variedMaterial must be a string');
    end

    if ~isnumeric(variedRange) || isempty(variedRange)
        error('variedRange must be a numeric array');
    end

    % Initialize results structure
    results = struct();
    results.variedMaterial = char(variedMaterial);
    results.variedRange = variedRange(:)';  % Ensure row vector
    nPoints = length(variedRange);

    % Initialize arrays
    results.TotalUniqueScore = zeros(1, nPoints);
    results.TotalNormalizedImpacts = struct();
    results.MaterialContributions = cell(1, nPoints);
    results.FullResults = cell(1, nPoints);

    % Get impact categories from first material
    if isfield(motorRAWmaterials(1), 'NormalizedImpacts')
        impactCategories = fieldnames(motorRAWmaterials(1).NormalizedImpacts);
    else
        error('Materials must be processed with calculateLCAImpacts first.');
    end

    % Initialize impact category arrays
    for i = 1:length(impactCategories)
        results.TotalNormalizedImpacts.(impactCategories{i}) = zeros(1, nPoints);
    end

    fprintf('Running parametric sweep: %s from %.2f to %.2f (%d points)\n', ...
        results.variedMaterial, min(variedRange), max(variedRange), nPoints);

    % Perform sweep
    for i = 1:nPoints
        % Create material quantities for this iteration
        % Combine base materials with current value of varied material
        currentQuantities = [baseMaterials; {variedMaterial, variedRange(i)}];

        % Calculate LCA for this configuration (suppress output)
        originalOutput = evalc('motorImpacts = calculateMotorLCA(motorRAWmaterials, currentQuantities);');

        % Store results
        results.TotalUniqueScore(i) = motorImpacts.TotalUniqueScore;

        for j = 1:length(impactCategories)
            catName = impactCategories{j};
            results.TotalNormalizedImpacts.(catName)(i) = ...
                motorImpacts.TotalNormalizedImpacts.(catName);
        end

        results.MaterialContributions{i} = motorImpacts.MaterialContributions;
        results.FullResults{i} = motorImpacts;

        % Progress indicator
        if mod(i, max(1, floor(nPoints/10))) == 0
            fprintf('  Progress: %d/%d (%.0f%%)\n', i, nPoints, 100*i/nPoints);
        end
    end

    fprintf('Parametric sweep complete!\n');

    % Display summary
    fprintf('\nResults summary:\n');
    fprintf('  Varied material: %s\n', results.variedMaterial);
    fprintf('  Range: %.2f to %.2f\n', min(variedRange), max(variedRange));
    fprintf('  Unique Score range: %.4e to %.4e\n', ...
        min(results.TotalUniqueScore), max(results.TotalUniqueScore));
    fprintf('  Variation: %.2f%%\n', ...
        100 * (max(results.TotalUniqueScore) - min(results.TotalUniqueScore)) / ...
        mean(results.TotalUniqueScore));

end
