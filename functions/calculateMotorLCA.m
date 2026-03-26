function motorImpacts = calculateMotorLCA(motorRAWmaterials, materialQuantities)
% CALCULATEMOTORLCA Calculate total LCA impacts for a specific motor
%
% Syntax:
%   motorImpacts = calculateMotorLCA(motorRAWmaterials, materialQuantities)
%
% Inputs:
%   motorRAWmaterials - Structure array with material properties and impacts
%                       (from calculateLCAImpacts)
%   materialQuantities - Cell array of {name, quantity} pairs OR structure
%                        Example (cell array):
%                          materialQuantities = {
%                              'market for copper, cathode', 5.2;
%                              'market for steel, ...', 12.3
%                          };
%                        Example (structure with IDs):
%                          materialQuantities.mat1 = struct('name', 'Copper', 'quantity', 5.2);
%
% Output:
%   motorImpacts - Structure containing total impacts for the motor
%                  .TotalImpacts: Raw impacts by category
%                  .TotalNormalizedImpacts: Normalized impacts by category
%                  .TotalUniqueScore: Single score for the motor
%                  .MaterialContributions: Array with individual contributions
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

    % Initialize output structure
    motorImpacts = struct();
    motorImpacts.TotalImpacts = struct();
    motorImpacts.TotalNormalizedImpacts = struct();
    motorImpacts.TotalUniqueScore = 0;
    motorImpacts.MaterialContributions = [];

    % Get all impact category names from the first material
    if isfield(motorRAWmaterials(1), 'NormalizedImpacts')
        impactCategories = fieldnames(motorRAWmaterials(1).NormalizedImpacts);
    else
        error('Materials must be processed with calculateLCAImpacts first.');
    end

    % Initialize total impacts
    for i = 1:length(impactCategories)
        motorImpacts.TotalImpacts.(impactCategories{i}) = 0;
        motorImpacts.TotalNormalizedImpacts.(impactCategories{i}) = 0;
    end

    % Convert material quantities to cell array if needed
    if ~iscell(materialQuantities)
        error('materialQuantities must be a cell array of {name, quantity} pairs');
    end

    % Process each material in the motor
    nMaterials = size(materialQuantities, 1);

    for i = 1:nMaterials
        materialName = materialQuantities{i, 1};
        quantity = materialQuantities{i, 2};

        % Find the corresponding material in motorRAWmaterials
        materialFound = false;
        for j = 1:length(motorRAWmaterials)
            % Try to match by name field
            if isfield(motorRAWmaterials(j), 'name') && ...
                strcmpi(strtrim(char(motorRAWmaterials(j).name)), strtrim(materialName))

                materialFound = true;
                material = motorRAWmaterials(j);

                % Initialize this material's contribution
                materialContribution = struct();
                materialContribution.name = materialName;
                materialContribution.quantity = quantity;
                materialContribution.unit = material.unit;
                materialContribution.impacts = struct();
                materialContribution.normalizedImpacts = struct();

                % Calculate impacts for this material quantity
                for k = 1:length(impactCategories)
                    categoryName = impactCategories{k};

                    % Get raw impact value
                    if isfield(material, categoryName)
                        rawImpactPerUnit = material.(categoryName);
                    else
                        rawImpactPerUnit = 0;
                    end

                    % Get normalized impact value
                    if isfield(material.NormalizedImpacts, categoryName)
                        normImpactPerUnit = material.NormalizedImpacts.(categoryName);
                    else
                        normImpactPerUnit = 0;
                    end

                    % Calculate total impact for this material
                    if isnumeric(rawImpactPerUnit) && isnumeric(normImpactPerUnit)
                        totalRawImpact = rawImpactPerUnit * quantity;
                        totalNormImpact = normImpactPerUnit * quantity;

                        % Add to material contribution
                        materialContribution.impacts.(categoryName) = totalRawImpact;
                        materialContribution.normalizedImpacts.(categoryName) = totalNormImpact;

                        % Add to motor total
                        motorImpacts.TotalImpacts.(categoryName) = ...
                            motorImpacts.TotalImpacts.(categoryName) + totalRawImpact;
                        motorImpacts.TotalNormalizedImpacts.(categoryName) = ...
                            motorImpacts.TotalNormalizedImpacts.(categoryName) + totalNormImpact;
                    end
                end

                % Calculate unique score for this material
                materialContribution.uniqueScore = material.UniqueScore * quantity;
                motorImpacts.TotalUniqueScore = motorImpacts.TotalUniqueScore + ...
                    materialContribution.uniqueScore;

                % Store material contribution in array
                motorImpacts.MaterialContributions = [motorImpacts.MaterialContributions; materialContribution];

                break;
            end
        end

        if ~materialFound
            warning('Material "%s" not found in database. Skipping.', materialName);
        end
    end

    % Display summary
    fprintf('\n===== MOTOR LCA RESULTS =====\n');
    fprintf('Total Unique Score: %.4e\n', motorImpacts.TotalUniqueScore);
    fprintf('\nImpact Contributions by Material:\n');

    for i = 1:length(motorImpacts.MaterialContributions)
        matData = motorImpacts.MaterialContributions(i);
        fprintf('  %s: %.2f %s (Score: %.4e)\n', matData.name, ...
            matData.quantity, char(matData.unit), matData.uniqueScore);
    end

    fprintf('\nDetailed impacts saved in motorImpacts structure.\n');

end
