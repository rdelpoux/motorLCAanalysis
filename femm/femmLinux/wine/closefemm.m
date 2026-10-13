function closefemm()
%CLOSEFEMM Ferme FEMM et nettoie les fichiers d'échange.
%   Version du pont Wine. quit() ne produit aucune réponse puisque FEMM
%   s'arrête : la commande est déposée sans attendre d'accusé, puis ifile.txt
%   et ofile.txt sont supprimés pour laisser le lien propre.
%
%   See also openfemm, callfemm, femmWineConfig.

cfg = femmWineConfig();
binDir = fullfile(cfg.femmDir, 'bin');
ifile = fullfile(binDir, 'ifile.txt');
ofile = fullfile(binDir, 'ofile.txt');

fid = fopen(ifile, 'wt');
if fid >= 0
    fprintf(fid, 'flput(quit())');
    fclose(fid);
end

pause(1);

for fichier = {ifile, ofile}
    if isfile(fichier{1})
        delete(fichier{1});
    end
end
end
