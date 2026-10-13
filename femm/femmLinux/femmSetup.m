function femmSetup(options)
%FEMMSETUP Prépare l'accès à FEMM selon le système d'exploitation.
%   femmSetup() met la boîte à outils FEMM sur le path MATLAB, avec le mode de
%   pilotage adapté au système :
%
%     Windows - la boîte à outils d'origine pilote FEMM par ActiveX. Seuls ses
%               mfiles sont ajoutés ; le pont Wine est retiré du path s'il s'y
%               trouve, pour ne pas masquer les fonctions ActiveX.
%     Linux   - ActiveX n'existe pas (actxserver n'y est qu'un fichier-souche).
%               Le pont wine/ est ajouté par-dessus les mfiles : il remplace les
%               4 fonctions de transport et pilote FEMM par femm.exe -filelink.
%
%   femmSetup(femmDir=chemin) impose le dossier d'installation de FEMM.
%
%   Après cet appel, openfemm, mi_* et mo_* s'utilisent identiquement sur les
%   deux systèmes.
%
%   Exemple :
%     femmSetup();
%     openfemm(0);
%
%   See also openfemm, femmWineSetup, femmWineConfig.

arguments
    options.femmDir (1,:) char = ''
end

dossierPont = fullfile(fileparts(mfilename('fullpath')), 'wine');

if ispc
    configurerWindows(dossierPont, options.femmDir);
else
    addpath(dossierPont);
    if isempty(options.femmDir)
        femmWineSetup();
    else
        femmWineSetup(femmDir = options.femmDir);
    end
end
end

% -------------------------------------------------------------------------
function configurerWindows(dossierPont, femmDir)
% Sous Windows, le pont Wine n'a pas lieu d'être et masquerait openfemm,
% callfemm, callfemm_noeval et closefemm d'origine.
if ismember(dossierPont, strsplit(path, pathsep))
    rmpath(dossierPont);
end

if isempty(femmDir)
    femmDir = trouverFemmWindows();
end

dossierMfiles = fullfile(femmDir, 'mfiles');
if ~isfolder(dossierMfiles)
    error("femmSetup:mfilesIntrouvables", "%s", sprintf( ...
        ['Dossier mfiles de FEMM introuvable : %s\n' ...
         'Indiquer le bon dossier :\n' ...
         '  femmSetup(femmDir="C:\\chemin\\vers\\femm42")'], dossierMfiles));
end

addpath(dossierMfiles);
end

% -------------------------------------------------------------------------
function femmDir = trouverFemmWindows()
% Emplacements usuels d'une installation FEMM 4.2 sous Windows.
candidats = { ...
    'C:\femm42', ...
    fullfile(getenv('ProgramFiles'), 'femm42'), ...
    fullfile(getenv('ProgramFiles(x86)'), 'femm42')};

for k = 1:numel(candidats)
    if isfolder(fullfile(candidats{k}, 'mfiles'))
        femmDir = candidats{k};
        return
    end
end

femmDir = candidats{1};  % laisse configurerWindows produire l'erreur explicite
end
