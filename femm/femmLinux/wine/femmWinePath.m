function cheminWindows = femmWinePath(cheminLinux)
%FEMMWINEPATH Convertit un chemin Linux en chemin Windows vu par Wine.
%   Le dossier courant de MATLAB doit être communiqué à FEMM sous la forme
%   Z:\... pour que les noms de fichiers relatifs (mi_saveas('temp.fem'))
%   pointent au même endroit des deux côtés du pont.
%
%   See also openfemm, femmWineEnv.

arguments
    cheminLinux (1,:) char
end

[statut, sortie] = system(sprintf('%s winepath -w %s 2>/dev/null', ...
    femmWineEnv(), femmWineQuote(cheminLinux)));
if statut ~= 0
    error("femmWinePath:conversionImpossible", "%s", ...
        sprintf("winepath a échoué sur %s :\n%s", cheminLinux, strtrim(sortie)));
end

% Wine émet des séquences ANSI de contrôle du curseur autour de sa sortie :
% les laisser passer casserait la chaîne Lua envoyée à FEMM.
sortie = regexprep(sortie, '\x1B\[[0-9;?]*[A-Za-z]', '');

lignes = strtrim(splitlines(sortie));
lignes = lignes(~cellfun(@isempty, lignes));
if isempty(lignes)
    error("femmWinePath:reponseVide", ...
        "winepath n'a rien renvoyé pour %s.", cheminLinux);
end

cheminWindows = lignes{end};
end
