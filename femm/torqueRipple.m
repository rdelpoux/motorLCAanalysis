%% Ondulation de couple : SynRM sans aimants vs PMa-SynRM (même géométrie)
% Simule un point de fonctionnement (type "one_OP" de SetProblemType) sur un
% quart de tour mécanique (un pas polaire, p = 2) pour les deux variantes de la
% machine : barrières de flux en air (SynRM) puis remplies d'aimants
% (PMa-SynRM). Le couple est relevé à chaque position du rotor, les deux
% courbes sont tracées et toutes les grandeurs (couple, courants, flux,
% tensions, composantes dq) sont enregistrées pour le post-traitement.
%
% Conventions (reprises du script d'origine Collab_Laplace/hbk_synrel) :
%   i_k = Is cos(p theta + beta - phaseShift_k), machine diphasée
%   rotation du rotor par la condition d'entrefer cfg.gapBoundary
%   couple = mo_gapintegral (déjà ramené à la machine complète)
%   flux et tensions de circuit multipliés par nSym (modèle 1/4 de machine)
%
% See also motorConfig, configureBarriers, SetProblemType, matlabFEMM.

clearvars; clc;

% Se placer dans le dossier du script : FEMM résout les chemins relatifs
% (tmp/, fichier .fem) depuis le dossier courant de MATLAB au moment de openfemm
cd(fileparts(mfilename('fullpath')));
addpath(fullfile(pwd, 'femmLinux'));
femmSetup();

showFemm = false;
if ~exist('tmp', 'dir'),     mkdir('tmp');     end
if ~exist('results', 'dir'), mkdir('results'); end

%% Point de fonctionnement
Is       = 10;          % [A] amplitude du courant
betaDeg  = 45;          % [°] angle de courant, idq = Is [cos(beta) sin(beta)]'
sweep    = pi/2;        % [rad] quart de tour mécanique = un pas polaire (p = 2)
nSteps   = 90;          % positions du rotor sur le balayage (pas de 1°)
variants = [false true]; % useMagnets : SynRM puis PMa-SynRM

problem = SetProblemType("one_OP", nSteps, Is, deg2rad(betaDeg), sweep);
beta = problem.betaMin;
stepAngle = problem.theta/problem.thetaN;   % [rad] pas de rotation

%% Simulation des deux variantes
results = struct();
results.operatingPoint = struct('Is', Is, 'betaDeg', betaDeg, 'sweepRad', sweep, 'nSteps', nSteps);
results.problem = problem;

for v = 1:numel(variants)
    cfg = motorConfig(useMagnets = variants(v));
    p = cfg.p; m = cfg.m;
    fprintf('\n=== Variante %s (useMagnets = %d) ===\n', cfg.motorType, cfg.useMagnets);

    femFile = fullfile('tmp', ['femm_torque_' cfg.motorType '.fem']);

    openfemm(~showFemm);
    main_resize(800, 800);
    opendocument(cfg.femFile);
    smartmesh(cfg.smartMesh);
    configureBarriers(cfg);
    mi_probdef(0, 'meters', 'planar', 1.e-8, cfg.L_active, 30, 0);
    mi_saveas(femFile);
    nNodes = mi_createmesh;
    fprintf('Nombre de noeuds FEMM = %d\n', nNodes);

    % Préallocation
    theta     = zeros(nSteps, 1);
    torque    = zeros(nSteps, 1);   % [Nm] intégrale d'entrefer
    torqueMst = zeros(nSteps, 1);   % [Nm] tenseur de Maxwell sur le rotor (contrôle)
    iPhase    = zeros(nSteps, m);   % [A]
    vPhase    = zeros(nSteps, m);   % [V]
    fluxPhase = zeros(nSteps, m);   % [Wb]

    for step = 1:nSteps
        thetaS = (step-1)*stepAngle;
        i = Is*cos(p*thetaS + beta - cfg.phaseShift);
        for k = 1:m
            mi_modifycircprop(cfg.circuits{k}, 1, i(k));
        end
        mi_modifyboundprop(cfg.gapBoundary, 10, rad2deg(thetaS));

        mi_saveas(femFile);
        mi_analyse(1);
        mi_loadsolution();

        torque(step) = mo_gapintegral(cfg.gapBoundary, 0);
        mo_clearblock();
        mo_groupselectblock(cfg.rotorGroup);
        torqueMst(step) = cfg.nSym*mo_blockintegral(22);
        mo_clearblock();
        for k = 1:m
            val = mo_getcircuitproperties(cfg.circuits{k});  % [I V Flux]
            iPhase(step, k)    = val(1);
            vPhase(step, k)    = cfg.nSym*val(2);
            fluxPhase(step, k) = cfg.nSym*val(3);
        end
        theta(step) = thetaS;
        mo_close();

        fprintf('%s : position %3d/%d, theta = %5.1f°, couple = %.4f Nm\n', ...
            cfg.motorType, step, nSteps, rad2deg(thetaS), torque(step));
    end
    closefemm();

    % Grandeurs dq (transformation de Park directe) et statistiques
    r = struct();
    r.cfg = cfg;
    r.theta = theta;
    r.thetaDeg = rad2deg(theta);
    r.torque = torque;
    r.torqueMaxwell = torqueMst;
    r.iPhase = iPhase;
    r.vPhase = vPhase;
    r.fluxPhase = fluxPhase;
    r.idq = park_transform(iPhase, theta, p, false);
    r.vdq = park_transform(vPhase, theta, p, false);
    r.fluxdq = park_transform(fluxPhase, theta, p, false);
    r.torqueMean = mean(torque);
    r.torqueMin = min(torque);
    r.torqueMax = max(torque);
    r.torqueRipple = (max(torque) - min(torque))/abs(mean(torque));  % [-] crête à crête / |moyen|
    r.torquePeakToPeak = max(torque) - min(torque);              % [Nm]
    results.(cfg.motorType) = r;
end

%% Bilan et tracé
fprintf('\n%-10s %12s %12s %12s %14s\n', 'Variante', 'T moyen', 'T min', 'T max', 'ondulation c-c');
types = fieldnames(results);
types = types(~ismember(types, {'operatingPoint', 'problem'}));
for v = 1:numel(types)
    r = results.(types{v});
    fprintf('%-10s %9.4f Nm %9.4f Nm %9.4f Nm %12.1f %%\n', types{v}, ...
        r.torqueMean, r.torqueMin, r.torqueMax, 100*r.torqueRipple);
end

tag = sprintf('Is%gA_beta%gdeg', Is, betaDeg);
fig = figure('Name', ['Ondulation de couple ' tag]);
hold on; grid on;
for v = 1:numel(types)
    r = results.(types{v});
    plot(r.thetaDeg, r.torque, 'LineWidth', 1.5, 'DisplayName', ...
        sprintf('%s : T_{moy} = %.3f Nm, ondulation = %.1f %%', types{v}, r.torqueMean, 100*r.torqueRipple));
end
xlabel('Position du rotor \theta_{m} [°]');
ylabel('Couple [Nm]');
title(sprintf('Couple sur un pas polaire, I_s = %g A, \\beta = %g°', Is, betaDeg));
legend('Location', 'best');
xlim([0 rad2deg(sweep)]);

%% Sauvegarde des données et de la figure
outMat = fullfile('results', ['torqueRipple_' tag '.mat']);
save(outMat, 'results');
exportgraphics(fig, fullfile('results', ['torqueRipple_' tag '.png']), 'Resolution', 150);
exportgraphics(fig, fullfile('results', ['torqueRipple_' tag '.eps']));
fprintf('\nRésultats enregistrés : %s (+ .png / .eps)\n', outMat);
