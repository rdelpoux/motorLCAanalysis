function s = femmWineQuote(texte)
%FEMMWINEQUOTE Protège une chaîne pour la passer en argument à un shell.
%   Encadre le texte de guillemets simples et échappe ceux qu'il contient,
%   afin que les espaces et caractères spéciaux d'un chemin ne soient pas
%   réinterprétés par /bin/sh.
%
%   See also femmWineEnv, femmWinePath.

arguments
    texte (1,:) char
end

s = ['''' strrep(texte, '''', '''\''''') ''''];
end
