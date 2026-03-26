function results = calculateMotorLCAMultiParametric(motorRAWmaterials, baseMaterials, variedMaterials, variedRanges)
% CALCULATEMOTORLCAMULTIPARAMETRIC Calculate LCA for multiple varying materials
%
% This function performs a multi-parametric sweep, calculating motor LCA impacts
% while varying multiple material quantities over specified ranges.
%
% Syntax:
%   results = calculateMotorLCAMultiParametric(motorRAWmaterials, baseMaterials, variedMaterials, variedRanges)
%
% Inputs:
%   motorRAWmaterials - Structure array with material properties and impacts
%   baseMaterials     - Cell array of {name, quantity} pairs for fixed materials
%   variedMaterials   - Cell array of material names to vary
%                       Example: {'market for copper, cathode';
%                                 'market for electricity, low voltage'}
%   variedRanges      - Cell array of ranges for each varied material
%                       Example: {4:0.5:6; 50:10:150}
%
% Output:
%   results - Structure containing sweep results with gridded data
%
% Example:
%   % Vary copper (4-6 kg) and electricity (50-150 kWh)
%   variedMaterials = {'market for copper, cathode';
%                      'market for electricity, low voltage'};
%   variedRanges = {4:0.5:6; 50:10:150};
%   results = calculateMotorLCAMultiParametric(motorRAWmaterials, baseMaterials, ...
%       variedMaterials, variedRanges);
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

    % Input validation
    if ~iscell(variedMaterials) || ~iscell(variedRanges)
        error('variedMaterials and variedRanges must be cell arrays');
    end

    if length(variedMaterials) ~= length(variedRanges)
        error('variedMaterials and variedRanges must have the same length');
    end

    nVars = length(variedMaterials);

    % Initialize results
    results = struct();
    results.variedMaterials = variedMaterials;
    results.variedRanges = variedRanges;

    if nVars == 1
        % Single parameter - use simpler function
        warning('Only one material varied. Consider using calculateMotorLCAParametric instead.');
        results = calculateMotorLCAParametric(motorRAWmaterials, baseMaterials, ...
            variedMaterials{1}, variedRanges{1});
        return;
    end

    if nVars == 2
        % Two parameters - create 2D grid
        fprintf('Running 2D parametric sweep...\n');
        fprintf('  Material 1: %s\n', variedMaterials{1});
        fprintf('  Material 2: %s\n', variedMaterials{2});

        range1 = variedRanges{1}(:);
        range2 = variedRanges{2}(:);
        n1 = length(range1);
        n2 = length(range2);

        fprintf('  Grid size: %d x %d = %d points\n\n', n1, n2, n1*n2);

        % Create meshgrid
        [R1, R2] = meshgrid(range1, range2);
        results.R1 = R1;
        results.R2 = R2;

        % Initialize result arrays
        results.TotalUniqueScore = zeros(size(R1));

        % Get impact categories
        if isfield(motorRAWmaterials(1), 'NormalizedImpacts')
            impactCategories = fieldnames(motorRAWmaterials(1).NormalizedImpacts);
        else
            error('Materials must be processed with calculateLCAImpacts first.');
        end

        results.TotalNormalizedImpacts = struct();
        for i = 1:length(impactCategories)
            results.TotalNormalizedImpacts.(impactCategories{i}) = zeros(size(R1));
        end

        % Perform sweep
        totalPoints = n1 * n2;
        pointCount = 0;

        for i = 1:n2
            for j = 1:n1
                pointCount = pointCount + 1;

                % Create material quantities for this point
                currentQuantities = [
                    baseMaterials;
                    {variedMaterials{1}, R1(i,j)};
                    {variedMaterials{2}, R2(i,j)}
                ];

                % Calculate LCA (suppress output)
                evalc('motorImpacts = calculateMotorLCA(motorRAWmaterials, currentQuantities);');

                % Store results
                results.TotalUniqueScore(i,j) = motorImpacts.TotalUniqueScore;

                for k = 1:length(impactCategories)
                    catName = impactCategories{k};
                    results.TotalNormalizedImpacts.(catName)(i,j) = ...
                        motorImpacts.TotalNormalizedImpacts.(catName);
                end

                % Progress
                if mod(pointCount, max(1, floor(totalPoints/20))) == 0
                    fprintf('  Progress: %d/%d (%.0f%%)\n', pointCount, totalPoints, ...
                        100*pointCount/totalPoints);
                end
            end
        end

        fprintf('2D sweep complete!\n');
        fprintf('  Unique Score range: %.4e to %.4e\n', ...
            min(results.TotalUniqueScore(:)), max(results.TotalUniqueScore(:)));

    else
        % N-dimensional sweep (N > 2)
        error('Multi-parametric sweep for more than 2 variables not yet implemented. Contact developer.');
    end

end
