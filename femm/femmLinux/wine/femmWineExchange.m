function reponse = femmWineExchange(commandeLua, delai)
%FEMMWINEEXCHANGE Aller-retour d'une commande Lua avec FEMM via le lien fichiers.
%   reponse = femmWineExchange(commandeLua) dépose flput(commandeLua) dans
%   ifile.txt, attend que FEMM écrive ofile.txt, renvoie son contenu brut et
%   supprime le fichier réponse.
%
%   reponse = femmWineExchange(commandeLua, delai) impose une attente maximale
%   en secondes au lieu du délai configuré.
%
%   C'est le seul point de contact avec FEMM. Le protocole est celui du mode
%   femm.exe -filelink : une commande sans valeur de retour donne '[]', une
%   valeur donne une expression évaluable par MATLAB, et une erreur donne une
%   chaîne commençant par 'error(' qui est convertie ici en erreur MATLAB.
%
%   See also callfemm, callfemm_noeval, openfemm, femmWineConfig.

arguments
    commandeLua (1,:) char
    delai (1,1) double {mustBePositive} = Inf
end

cfg = femmWineConfig();
if isinf(delai)
    delai = cfg.timeout;
end

binDir = fullfile(cfg.femmDir, 'bin');
ifile = fullfile(binDir, 'ifile.txt');
ofile = fullfile(binDir, 'ofile.txt');

% Réponse résiduelle d'un échange interrompu : on repart propre
if isfile(ofile)
    delete(ofile);
end

fid = fopen(ifile, 'wt');
if fid < 0
    error("femmWineExchange:ecritureImpossible", ...
        "Impossible de déposer la commande dans %s.", ifile);
end
fprintf(fid, 'flput(%s)', commandeLua);
fclose(fid);

reponse = attendreReponse(ofile, delai, commandeLua, cfg.poll);
verifierErreur(reponse, commandeLua);
end

% -------------------------------------------------------------------------
function reponse = attendreReponse(ofile, delai, commandeLua, poll)
% Attend que FEMM ait écrit sa réponse, et s'assure qu'elle est complète.
chrono = tic;
while true
    contenu = lireFichier(ofile);
    if ~isempty(contenu)
        % Relecture après une pause : FEMM peut être en cours d'écriture
        pause(poll);
        if isequal(contenu, lireFichier(ofile))
            delete(ofile);
            reponse = strtrim(contenu);
            return
        end
    end
    if toc(chrono) > delai
        error("femmWineExchange:delaiDepasse", "%s", sprintf( ...
            ['Pas de réponse de FEMM après %g s.\nCommande : %s\n' ...
             'Vérifier que le processus femm.exe -filelink tourne encore ' ...
             '(pgrep -f femm.exe), ou augmenter timeout via femmWineConfig.'], ...
            delai, commandeLua));
    end
    pause(poll);
end
end

% -------------------------------------------------------------------------
function contenu = lireFichier(chemin)
% Lecture tolérante : le fichier peut ne pas exister ou être encore vide.
contenu = '';
fid = fopen(chemin, 'rt');
if fid < 0
    return
end
brut = fread(fid, [1 Inf], '*char');
fclose(fid);
contenu = brut;
end

% -------------------------------------------------------------------------
function verifierErreur(reponse, commandeLua)
% FEMM signale une erreur par une chaîne de la forme error("...").
if isempty(reponse) || reponse(1) ~= 'e'
    return
end

message = reponse;
guillemets = strfind(message, '"');
if numel(guillemets) >= 2
    message = message(guillemets(1)+1:guillemets(end)-1);
end
message = strrep(message, '\n', newline);
message = strrep(message, '\"', '"');

error("femmWineExchange:erreurFemm", "%s", sprintf( ...
    "FEMM a rejeté la commande.\n%s\nCommande Lua : %s", ...
    strtrim(message), commandeLua));
end
