# Motor LCA Analysis - MATLAB

![Work in Progress](https://img.shields.io/badge/status-work%20in%20progress-orange)

> **⚠️ DISCLAIMER / AVERTISSEMENT**
>
> This toolbox is a **work in progress** and an experimental implementation. **No results are guaranteed**. This is a trial implementation without any claim regarding the validity of the results or the analyses that can be derived from them. Use this tool for educational and research exploration purposes only.
>
> Cet outil est un **travail en cours** et une implémentation expérimentale. **Aucun résultat n'est garanti**. Il s'agit d'un essai sans aucune prétention quant à la validité des résultats ni aux analyses qui peuvent en être tirées. Utilisez cet outil uniquement à des fins éducatives et de recherche exploratoire.

This package provides MATLAB functions for performing Life Cycle Assessment (LCA) analysis of electric motors using Environmental Footprint (EF) v3.1 methodology.

**Authors:**
- Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
- Romain DELPOUX <romain.delpoux@insa-lyon.fr>

**Affiliation:** Maîtres de Conférences, Laboratoire Ampere

**Date:** March 2026

## Directory Structure

```
motorLCAanalysis/
├── README.md                # This file
├── setup.m                  # Setup script (run first!)
├── functions/               # Core LCA functions
│   ├── importMotorMaterialsCSV.m
│   ├── calculateLCAImpacts.m
│   ├── calculateMotorLCA.m
│   ├── calculateMotorLCAParametric.m
│   └── calculateMotorLCAMultiParametric.m
├── database/                # EcoInvent data files
│   └── CSV_Impact_Machine.csv
└── examples/                # Example scripts and tests
    ├── example_usage.m
    ├── example_parametric_analysis.m
    ├── example_2D_parametric.m
    ├── example_lifetime_analysis.m
    ├── example_lifetime_2D.m
    ├── test_functions.m
    ├── test_parametric.m
    ├── test_lifetime.m
    ├── plot_improved.m
    └── how_to_use_results.m
```

## Files Description

### Main Functions

1. **importMotorMaterialsCSV.m**
   - Imports material data from EcoInvent CSV files
   - Creates structured data with material properties and environmental impacts
   - Returns: `motorRAWmaterials` structure

2. **calculateLCAImpacts.m**
   - Calculates normalized impacts using EF v3.1 Normalization Factors
   - Applies weighting factors to compute unique score (single score)
   - Adds normalized impacts and unique score to each material
   - Returns: Updated `motorRAWmaterials` structure

3. **calculateMotorLCA.m**
   - Calculates total environmental impacts for a specific motor configuration
   - Takes material quantities as input
   - Computes total impacts and material contributions
   - Returns: `motorImpacts` structure with detailed results

4. **calculateMotorLCAParametric.m**
   - Performs parametric sweep by varying one material quantity
   - Useful for sensitivity analysis and optimization
   - Returns: Arrays of results across the parameter range

5. **calculateMotorLCAMultiParametric.m**
   - Performs 2D parametric sweep varying two materials simultaneously
   - Creates gridded results for contour and surface plots
   - Returns: 2D arrays of results for visualization

### Example Files (in `examples/` folder)

- **example_usage.m**: Complete example workflow demonstrating all functions
- **example_parametric_analysis.m**: Parametric analysis example (1D sweep)
- **example_2D_parametric.m**: Multi-parametric analysis example (2D sweep)
- **example_lifetime_analysis.m**: Lifetime energy consumption analysis (1D: load factor and operating hours)
- **example_lifetime_2D.m**: 2D lifetime analysis (load factor × operating hours grid)
- **test_functions.m**: Quick test of all main functions
- **test_parametric.m**: Quick test of parametric analysis
- **test_lifetime.m**: Quick test of lifetime energy calculation
- **plot_improved.m**: Advanced visualization script
- **how_to_use_results.m**: Guide for accessing and analyzing results

### Database Files (in `database/` folder)

- **CSV_Impact_Machine.csv**: Sample CSV file from EcoInvent with motor materials and their environmental impacts

## Getting Started

### Installation

1. Navigate to the `matlab/` directory in MATLAB
2. Run the setup script to add necessary paths:
   ```matlab
   >> setup
   ```

This will add `functions/`, `database/`, and `examples/` to your MATLAB path.

### Quick Start

### 1. Prepare Your Data

Ensure your CSV file from EcoInvent contains these columns:
- Basic properties: `index`, `amount`, `unit`, `reference product`, `name`, `location`, `database`
- EF v3.1 impact categories with full names like:
  - `EF v3.1 | acidification | accumulated exceedance (AE)`
  - `EF v3.1 | climate change | global warming potential (GWP100)`
  - `EF v3.1 | ecotoxicity: freshwater | comparative toxic unit for ecosystems (CTUe)`
  - And other EF v3.1 categories...

The import function automatically extracts short names from these long column headers.

### 2. Run Analysis

```matlab
% Import materials
motorRAWmaterials = importMotorMaterialsCSV('CSV_Impact_Machine.csv');

% Calculate impacts
motorRAWmaterials = calculateLCAImpacts(motorRAWmaterials);

% Define motor configuration as cell array {name, quantity}
% Material names must match the 'name' field in your CSV
materialQuantities = {
    'market for copper, cathode', 5.2;
    'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3;
    'market for permanent magnet, for electric motor', 0.8
};

% Calculate motor LCA
motorImpacts = calculateMotorLCA(motorRAWmaterials, materialQuantities);
```

### 3. View Results

The `motorImpacts` structure contains:
- `TotalImpacts`: Raw environmental impacts by category
- `TotalNormalizedImpacts`: Normalized impacts by category
- `TotalUniqueScore`: Single environmental score for the motor
- `MaterialContributions`: Array with detailed breakdown by material (each element contains name, quantity, unit, impacts, normalizedImpacts, uniqueScore)

## Parametric Analysis

### Single Parameter Sweep (1D)

To study how impact varies with one material quantity:

```matlab
% Define fixed materials
baseMaterials = {
    'market for copper, cathode', 5.2;
    'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3
};

% Vary electricity from 1 to 100 kWh
results = calculateMotorLCAParametric(motorRAWmaterials, baseMaterials, ...
    'market for electricity, low voltage', 1:5:100);

% Plot results
figure;
plot(results.variedRange, results.TotalUniqueScore, '-o');
xlabel('Electricity (kWh)');
ylabel('Total Unique Score');
```

### Multi-Parameter Sweep (2D)

To study interaction between two materials:

```matlab
% Define materials to vary
variedMaterials = {
    'market for copper, cathode';
    'market for electricity, low voltage'
};

variedRanges = {
    4:0.5:6;        % Copper: 4-6 kg
    50:10:150       % Electricity: 50-150 kWh
};

% Run 2D sweep
results = calculateMotorLCAMultiParametric(motorRAWmaterials, baseMaterials, ...
    variedMaterials, variedRanges);

% Create contour plot
figure;
contourf(results.R1, results.R2, results.TotalUniqueScore, 20);
colorbar;
xlabel('Copper (kg)');
ylabel('Electricity (kWh)');
title('Total Environmental Impact');
```

See `example_parametric_analysis.m` and `example_2D_parametric.m` for complete examples.

## Lifetime Energy Analysis

To perform LCA considering manufacturing AND lifetime energy consumption:

### Energy Formula

```
E_vie = P_nom × f_charge × t_vie
```

Where:
- `P_nom`: Nominal power (kW)
- `f_charge`: Load factor (0.3 to 0.7 typical)
- `t_vie`: Cumulative operating hours (h)

### Example

Small motor (1 kW), 20,000 h, load factor 0.5:
```
E = 1 × 0.5 × 20,000 = 10,000 kWh ≈ 10 MWh
```

### MATLAB Code

```matlab
% Motor parameters
P_nom = 1;          % 1 kW
t_vie = 20000;      % 20,000 hours
f_charge = 0.5;     % Load factor 0.5

% Calculate lifetime energy
E_vie = P_nom * f_charge * t_vie;  % = 10,000 kWh

% Define manufacturing materials
baseMaterials = {
    'market for copper, cathode', 5.2;
    'market for steel, 3.2% silicon alloy, for grain oriented electrical steel', 12.3;
    'market for permanent magnet, for electric motor', 0.8
};

% Manufacturing impact only
mfg_impacts = calculateMotorLCA(motorRAWmaterials, baseMaterials);

% Total impact (manufacturing + use phase)
total_materials = [baseMaterials; {'market for electricity, low voltage', E_vie}];
total_impacts = calculateMotorLCA(motorRAWmaterials, total_materials);

% Results
fprintf('Manufacturing: %.1f%%\n', 100*mfg_impacts.TotalUniqueScore/total_impacts.TotalUniqueScore);
fprintf('Use phase: %.1f%%\n', 100*(total_impacts.TotalUniqueScore - mfg_impacts.TotalUniqueScore)/total_impacts.TotalUniqueScore);
```

Typical result: Use phase represents 83% of total impact for this example.

### Advanced Analysis

- `example_lifetime_analysis.m`: Complete lifetime analysis with load factor and lifetime variation
- `example_lifetime_2D.m`: 2D parametric analysis (load factor × lifetime hours)
- `test_lifetime.m`: Quick test

These scripts help identify:
- At which lifetime the use phase becomes dominant
- Optimal load factor for minimum environmental impact
- Sensitivity to operating conditions

## Environmental Footprint Categories

The analysis uses EF v3.1 Normalization Factors (NF) and Weighting Factors (WF):

| Impact Category | Short Name | NF | WF |
|----------------|-----------|-----|-----|
| Acidification | Acidification | 55.6 | 6.2 |
| Climate Change | ClimateChange | 7550 | 21.06 |
| Ecotoxicity: Freshwater | EcotoxicityFreshwater | 56700 | 1.92 |
| Particulate Matter Formation | ParticulateMatterFormation | 5.95E-04 | 8.96 |
| Eutrophication: Freshwater | EutrophicationFreshwater | 1.61 | 2.8 |
| Eutrophication: Marine | EutrophicationMarine | 19.5 | 2.96 |
| Eutrophication: Terrestrial | EutrophicationTerrestrial | 177 | 3.71 |
| Human Toxicity: Carcinogenic | HumanToxicityCarcinogenic | 1.73E-05 | 2.13 |
| Human Toxicity: Non-Carcinogenic | HumanToxicityNoncarcinogenic | 1.29E-04 | 1.84 |
| Ionising Radiation: Human Health | IonisingRadiationHumanHealth | 4220 | 5.01 |
| Land Use | LandUse | 819000 | 7.94 |
| Ozone Depletion | OzoneDepletion | 0.0523 | 6.31 |
| Photochemical Oxidant Formation: Human Health | PhotochemicalOxidantFormationHumanHealth | 40.9 | 4.78 |
| Energy Resources: Non-Renewable | EnergyResourcesNonrenewable | 65000 | 8.32 |
| Material Resources: Metals/Minerals | MaterialResourcesMetalsminerals | 0.0636 | 7.55 |
| Water Use | WaterUse | 11500 | 8.51 |

**Total WF = 100%**

## Customization

### Adjusting Weighting Factors

The weighting factors (WF) are already configured according to the official EF v3.1 methodology. If you need to modify them:
1. Edit `calculateLCAImpacts.m`
2. Modify the WF values (lines 50-65)
3. Ensure the total equals 100%

### Adding New Impact Categories

1. Add the category to your CSV file
2. Update the NF and WF structures in `calculateLCAImpacts.m`

### Matching Material Names

The `calculateMotorLCA` function matches materials by the `name` field from your CSV. Use the exact names as they appear in the CSV, for example:
- `'market for copper, cathode'`
- `'market for steel, 3.2% silicon alloy, for grain oriented electrical steel'`
- `'market for permanent magnet, for electric motor'`

## Output Files

When running `example_usage.m`, the following files are generated:
- `motor_lca_results.mat`: Complete workspace with all results
- `motor_lca_summary.txt`: Text summary of the analysis
- Visualization plots showing material contributions and impact breakdown

## Requirements

- MATLAB R2016b or later
- No additional toolboxes required

## Notes

- All calculations follow the EF v3.1 methodology
- Material quantities should be in the same units as the CSV database (typically kg)
- The unique score provides a single metric for comparing different motor configurations


---

**Author**: Generated for Motor LCA Analysis
**Date**: 2026
**Version**: 1.0
