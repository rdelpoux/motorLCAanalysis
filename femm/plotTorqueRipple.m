function fig = plotTorqueRipple(results, outDir)
%PLOTTORQUERIPPLE Trace et enregistre les couples SynRM / PMa-SynRM d'un run torqueRipple.
%   fig = plotTorqueRipple(results) trace, sur une même figure à fond clair,
%   le couple en fonction de la position du rotor pour chaque variante
%   contenue dans la structure results produite par torqueRipple.m (ou
%   chargée depuis results/torqueRipple_<tag>.mat).
%
%   fig = plotTorqueRipple(results, outDir) enregistre en plus la figure
%   dans outDir sous torqueRipple_<tag>.png et .eps.
%
%   Exemple :
%     S = load('results/torqueRipple_Is10A_beta45deg.mat');
%     plotTorqueRipple(S.results, 'results');
%
%   See also torqueRipple, motorConfig.

arguments
    results (1,1) struct
    outDir (1,:) char = ''
end

op = results.operatingPoint;
tag = sprintf('Is%gA_beta%gdeg', op.Is, op.betaDeg);
types = fieldnames(results);
types = types(~ismember(types, {'operatingPoint', 'problem'}));

fig = figure('Theme', 'light', 'Name', ['Ondulation de couple ' tag]);
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
for v = 1:numel(types)
    r = results.(types{v});
    plot(ax, r.thetaDeg, r.torque, 'LineWidth', 1.5, 'DisplayName', ...
        sprintf('%s : T_{moy} = %.3f Nm, ondulation = %.1f %%', ...
        types{v}, r.torqueMean, 100*r.torqueRipple));
end
xlabel(ax, 'Position du rotor \theta_{m} [°]');
ylabel(ax, 'Couple [Nm]');
title(ax, sprintf('Couple sur 1/8 de tour mécanique, I_s = %g A, \\beta = %g°', op.Is, op.betaDeg));
legend(ax, 'Location', 'best');
xlim(ax, [0 rad2deg(op.sweepRad)]);

if ~isempty(outDir)
    exportgraphics(fig, fullfile(outDir, ['torqueRipple_' tag '.png']), 'Resolution', 150);
    exportgraphics(fig, fullfile(outDir, ['torqueRipple_' tag '.eps']));
end
end
