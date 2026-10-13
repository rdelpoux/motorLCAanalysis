function configureBarriers(cfg)
%CONFIGUREBARRIERS Remplit les barrières de flux du modèle FEMM ouvert (air ou aimants).
%   configureBarriers(cfg) affecte aux régions de barrières de flux listées
%   dans cfg.barrierLabels le matériau aimant cfg.magnet (créé dans le
%   modèle) si cfg.useMagnets vaut true, ou 'Air' sinon. Le modèle FEMM doit
%   être ouvert (opendocument) avant l'appel.
%
%   Exemple :
%     cfg = motorConfig(useMagnets=true);
%     opendocument(cfg.femFile);
%     configureBarriers(cfg);
%
%   See also motorConfig, matlabFEMM, torqueRipple.

arguments
    cfg (1,1) struct
end

if cfg.useMagnets
    % mu_x, mu_y, H_c, J, Cduct, Lam_d, Phi_hmax, lam_fill, LamType, Phi_hx, Phi_hy
    mi_addmaterial(cfg.magnet.name, cfg.magnet.muR, cfg.magnet.muR, cfg.magnet.Hc, ...
        0, cfg.magnet.sigma, 0, 0, 1, 0, 0, 0);
    blockMaterial = cfg.magnet.name;
    magDir = cfg.magnet.dirDeg;
else
    blockMaterial = 'Air';
    magDir = 0;
end

for k = 1:size(cfg.barrierLabels, 1)
    mi_clearselected();
    mi_selectlabel(cfg.barrierLabels(k,1), cfg.barrierLabels(k,2));
    % blockname, automesh, meshsize, incircuit, magdir, group, turns
    mi_setblockprop(blockMaterial, 1, 0, '<None>', magDir, cfg.rotorGroup, 0);
end
mi_clearselected();
end
