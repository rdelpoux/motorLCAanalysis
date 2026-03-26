function motorRAWmaterials = importMotorMaterialsCSV(csvFilePath)
% IMPORTMOTORMATERIALSCSV Import motor materials data from EcoInvent CSV file
%
% Syntax:
%   motorRAWmaterials = importMotorMaterialsCSV(csvFilePath)
%
% Input:
%   csvFilePath - Path to the CSV file containing material data from EcoInvent
%
% Output:
%   motorRAWmaterials - Structure array containing material properties and
%                       environmental impacts
%
% Structure fields:
%   - id: Unique identifier (0 to n)
%   - index: Material index
%   - amount: Quantity of material
%   - unit: Unit of measurement
%   - reference: Reference code
%   - product: Product name
%   - name: Material name
%   - location: Geographic location
%   - database: Source database
%   - EF impacts: All Environmental Footprint v3.1 indicators
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

    % Check if file exists - try multiple locations
    if ~isfile(csvFilePath)
        % Try in database folder (relative to this function)
        functionDir = fileparts(mfilename('fullpath'));
        databasePath = fullfile(functionDir, '..', 'database', csvFilePath);

        if isfile(databasePath)
            csvFilePath = databasePath;
        else
            error('CSV file not found: %s\nAlso tried: %s', csvFilePath, databasePath);
        end
    end

    % Import the CSV file
    opts = detectImportOptions(csvFilePath);
    opts.VariableNamingRule = 'preserve'; % Keep original column names
    data = readtable(csvFilePath, opts);

    % Get number of materials
    nMaterials = height(data);

    % Initialize structure array
    motorRAWmaterials = struct();

    % Define standard field names (base properties)
    % Note: CSV uses 'reference product' as column name
    baseFields = {'index', 'amount', 'unit', 'reference product', ...
                  'name', 'location', 'database'};

    % Process each material (row)
    for i = 1:nMaterials
        % Add ID
        motorRAWmaterials(i).id = i - 1; % 0 to n

        % Add base properties
        for j = 1:length(baseFields)
            fieldName = baseFields{j};
            if ismember(fieldName, data.Properties.VariableNames)
                value = data.(fieldName)(i);
                % Create valid MATLAB field name (remove spaces)
                validFieldName = strrep(fieldName, ' ', '');
                % Handle different data types
                if iscell(value)
                    motorRAWmaterials(i).(validFieldName) = value{1};
                else
                    motorRAWmaterials(i).(validFieldName) = value;
                end
            else
                % Create valid MATLAB field name (remove spaces)
                validFieldName = strrep(fieldName, ' ', '');
                motorRAWmaterials(i).(validFieldName) = [];
            end
        end

        % Add all Environmental Footprint (EF) impact categories
        % These are all remaining columns not in baseFields
        allColumns = data.Properties.VariableNames;
        efColumns = setdiff(allColumns, baseFields);

        % Also remove the first empty column if it exists
        efColumns = efColumns(~cellfun(@isempty, efColumns));

        for j = 1:length(efColumns)
            efName = efColumns{j};
            value = data.(efName)(i);

            % Extract short name from EF column name for easier access
            % Format: "EF v3.1 | category | description"
            shortName = extractShortImpactName(efName);

            % Skip if shortName is empty (e.g., inorganics/organics subdivisions)
            if isempty(shortName)
                continue;
            end

            % Handle different data types
            if iscell(value)
                motorRAWmaterials(i).(shortName) = value{1};
            else
                motorRAWmaterials(i).(shortName) = value;
            end

            % Also store original column name for reference
            if i == 1
                motorRAWmaterials(i).ImpactMapping.(shortName) = efName;
            end
        end
    end

    fprintf('Successfully imported %d materials from CSV file.\n', nMaterials);

end

function shortName = extractShortImpactName(longName)
% EXTRACTSHORTIMPACTNAME Extract short impact name from EF v3.1 full name
%
% Input: "EF v3.1 | acidification | accumulated exceedance (AE)"
% Output: "Acidification"

    % Check if it's an EF v3.1 column
    if contains(longName, 'EF v3.1')
        % Split by '|'
        parts = strsplit(longName, '|');
        if length(parts) >= 2
            % Get the category name (second part)
            category = strtrim(parts{2});

            % Handle special cases with subcategories
            if contains(category, ':')
                % Format: "climate change: fossil" or "human toxicity: carcinogenic"
                subparts = strsplit(category, ':');
                mainCategory = strtrim(subparts{1});
                subCategory = strtrim(subparts{2});

                % Skip "inorganics" and "organics" subdivisions
                if contains(subCategory, 'inorganics') || contains(subCategory, 'organics')
                    shortName = ''; % Empty string to skip these columns
                    return;
                end

                % Create combined name
                shortName = [capitalize(mainCategory) capitalize(subCategory)];
            else
                % Simple category
                shortName = capitalize(category);
            end

            % Clean up the name
            shortName = strrep(shortName, ' ', '');
            shortName = strrep(shortName, '/', '');
            shortName = strrep(shortName, '-', '');
        else
            shortName = matlab.lang.makeValidName(longName);
        end
    else
        % Not an EF column, use as is but make it valid
        shortName = matlab.lang.makeValidName(longName);
    end
end

function str = capitalize(str)
% CAPITALIZE Capitalize first letter of each word
    words = strsplit(str, ' ');
    for i = 1:length(words)
        if ~isempty(words{i})
            words{i}(1) = upper(words{i}(1));
        end
    end
    str = strjoin(words, '');
end
