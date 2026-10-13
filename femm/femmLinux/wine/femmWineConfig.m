function cfg = femmWineConfig(newCfg)
%FEMMWINECONFIG Configuration du pont MATLAB vers FEMM sous Wine.
%   cfg = femmWineConfig() renvoie la configuration courante de la session.
%
%   cfg = femmWineConfig(s) fusionne les champs de la structure s dans la
%   configuration, puis renvoie le résultat. La configuration persiste pour
%   toute la session MATLAB.
%
%   Champs :
%     prefix         - préfixe Wine hébergeant FEMM
%     femmDir        - dossier d'installation de FEMM, en chemin Linux
%     timeout        - attente maximale d'une réponse de FEMM, en secondes
%     startupTimeout - attente maximale du démarrage de FEMM, en secondes
%     poll           - période d'interrogation du fichier réponse, en secondes
%
%   Le délai par défaut est volontairement large : mi_analyze peut demander
%   plusieurs minutes sur un maillage fin.
%
%   Exemple :
%     femmWineConfig(struct('timeout', 1800));
%
%   See also openfemm, femmWineSetup, femmWineExchange.

arguments
    newCfg (1,1) struct = struct()
end

persistent stored

if isempty(stored)
    prefix = getenv('WINEPREFIX');
    if isempty(prefix)
        prefix = fullfile(getenv('HOME'), '.wine');
    end
    stored = struct( ...
        'prefix', prefix, ...
        'femmDir', fullfile(prefix, 'drive_c', 'femm42'), ...
        'timeout', 600, ...
        'startupTimeout', 90, ...
        'poll', 0.005);
end

champs = fieldnames(newCfg);
for k = 1:numel(champs)
    if ~isfield(stored, champs{k})
        error("femmWineConfig:champInconnu", ...
            "Champ de configuration inconnu : %s.", champs{k});
    end
    stored.(champs{k}) = newCfg.(champs{k});
end

% femmDir suit prefix tant qu'il n'est pas fixé explicitement
if isfield(newCfg, 'prefix') && ~isfield(newCfg, 'femmDir')
    stored.femmDir = fullfile(stored.prefix, 'drive_c', 'femm42');
end

cfg = stored;
end
