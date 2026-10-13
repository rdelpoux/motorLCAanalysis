function prefixe = femmWineEnv()
%FEMMWINEENV Préfixe de commande shell pour lancer Wine depuis MATLAB.
%   MATLAB impose ses propres LD_LIBRARY_PATH et LD_PRELOAD, qui font échouer
%   les binaires système appelés par system(). On les retire et on fixe le
%   préfixe Wine attendu.
%
%   See also openfemm, femmWinePath, femmWineConfig.

cfg = femmWineConfig();
prefixe = sprintf('env -u LD_LIBRARY_PATH -u LD_PRELOAD WINEPREFIX=%s WINEDEBUG=-all', ...
    femmWineQuote(cfg.prefix));
end
