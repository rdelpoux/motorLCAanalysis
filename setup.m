%% SETUP - Motor LCA Analysis Toolbox
% This script adds the necessary paths to use the Motor LCA functions
%
% Run this script once at the beginning of your MATLAB session:
%   >> setup
%
% Authors: Hugo HELBLING <hugo.helbling@univ-lyon1.fr>
%          Romain DELPOUX <romain.delpoux@insa-lyon.fr>
%          Maîtres de Conférences, Laboratoire Ampere
% Date: March 2026

% Get the current directory
currentDir = fileparts(mfilename('fullpath'));

% Add subdirectories to path
addpath(fullfile(currentDir, 'functions'));
addpath(fullfile(currentDir, 'database'));
addpath(fullfile(currentDir, 'examples'));

% Confirm setup
fprintf('===== Motor LCA Analysis Toolbox =====\n');
fprintf('Setup complete!\n');
fprintf('Added to path:\n');
fprintf('  - functions/\n');
fprintf('  - database/\n');
fprintf('  - examples/\n\n');
fprintf('You can now use all functions and run examples.\n');
fprintf('Type "help <function_name>" for help on any function.\n\n');
fprintf('Quick start:\n');
fprintf('  >> test_functions       %% Test all main functions\n');
fprintf('  >> example_usage        %% Complete example\n');
fprintf('  >> test_lifetime        %% Test lifetime analysis\n\n');
fprintf('Authors: Hugo HELBLING & Romain DELPOUX\n');
fprintf('         Laboratoire Ampere\n');
fprintf('License: CC BY-NC 4.0\n');
fprintf('======================================\n');
