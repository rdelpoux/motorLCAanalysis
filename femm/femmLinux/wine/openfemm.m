function openfemm(bHide)
%OPENFEMM Démarre FEMM sous Wine et établit le lien par fichiers.
%   openfemm() démarre FEMM et restaure sa fenêtre.
%   openfemm(1) démarre FEMM sans restaurer sa fenêtre.
%
%   Version du pont Wine. La version livrée avec FEMM ouvre un serveur
%   ActiveX, ce que MATLAB pour Linux ne sait pas faire. On lance ici
%   femm.exe -filelink, mode natif de FEMM prévu pour le pilotage par un
%   processus sans COM : les commandes Lua transitent par ifile.txt et les
%   réponses par ofile.txt, dans le dossier bin de FEMM.
%
%   Un FEMM déjà lancé est réutilisé plutôt que dupliqué.
%
%   See also closefemm, callfemm, femmWineSetup, femmWineConfig.

arguments
    bHide (1,1) double {mustBeMember(bHide, [0 1])} = 0
end

cfg = femmWineConfig();
exeFemm = fullfile(cfg.femmDir, 'bin', 'femm.exe');
if ~isfile(exeFemm)
    error("openfemm:femmIntrouvable", "%s", sprintf( ...
        ['femm.exe introuvable dans %s.\n' ...
         'Vérifier l''installation sous Wine, ou indiquer le bon dossier :\n' ...
         '  femmWineConfig(struct(''femmDir'', ''/chemin/vers/femm42''))'], ...
        fileparts(exeFemm)));
end

if ~femmEstVivant()
    demarrerFemm(exeFemm, cfg);
end

% FEMM résout les noms de fichiers relatifs depuis son dossier courant : on
% le cale sur celui de MATLAB, traduit en chemin Windows, pour que
% mi_saveas('temp.fem') écrive là où MATLAB ira le relire.
callfemm(sprintf('setcurrentdirectory(%s)', quote(femmWinePath(pwd))));

if bHide == 0
    callfemm('main_restore()');
end

% Sans cela, certaines commandes conservent le comportement FEMM 4.0
callfemm('setcompatibilitymode(0)');
end

% -------------------------------------------------------------------------
function estVivant = femmEstVivant()
% Sonde le lien : une commande triviale avec un délai court.
cfg = femmWineConfig();
try
    femmWineExchange('0', 2);
    estVivant = true;
catch
    estVivant = false;
    % Commande jamais consommée : ne pas la laisser derrière soi
    ifile = fullfile(cfg.femmDir, 'bin', 'ifile.txt');
    if isfile(ifile)
        delete(ifile);
    end
end
end

% -------------------------------------------------------------------------
function demarrerFemm(exeFemm, cfg)
% Lance FEMM détaché de MATLAB, puis attend qu'il réponde.
commande = sprintf('%s setsid nohup wine %s -filelink > /dev/null 2>&1 &', ...
    femmWineEnv(), femmWineQuote(exeFemm));
[statut, sortie] = system(commande);
if statut ~= 0
    error("openfemm:lancementImpossible", "%s", ...
        sprintf("Échec du lancement de FEMM sous Wine :\n%s", strtrim(sortie)));
end

chrono = tic;
while ~femmEstVivant()
    if toc(chrono) > cfg.startupTimeout
        error("openfemm:demarrageTropLong", ...
            "FEMM n'a pas répondu dans les %g s suivant son lancement.", ...
            cfg.startupTimeout);
    end
end
end
