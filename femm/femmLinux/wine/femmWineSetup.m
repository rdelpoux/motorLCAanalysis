function femmWineSetup(options)
%FEMMWINESETUP Met la boîte à outils FEMM et le pont Wine sur le path MATLAB.
%   femmWineSetup() ajoute les mfiles de FEMM puis le pont, dans cet ordre.
%
%   femmWineSetup(femmDir=chemin) utilise une autre installation de FEMM.
%   femmWineSetup(prefix=chemin) utilise un autre préfixe Wine.
%
%   L'ordre est imposé : le pont doit passer devant les mfiles d'origine pour
%   que openfemm, callfemm, callfemm_noeval et closefemm masquent les versions
%   ActiveX. Les 624 autres fonctions de FEMM sont conservées telles quelles.
%
%   Exemple :
%     femmWineSetup();
%     openfemm(0);
%
%   See also openfemm, closefemm, femmWineConfig.

arguments
    options.prefix (1,:) char = ''
    options.femmDir (1,:) char = ''
end

maj = struct();
if ~isempty(options.prefix)
    maj.prefix = options.prefix;
end
if ~isempty(options.femmDir)
    maj.femmDir = options.femmDir;
end

% Le dossier est vérifié avant d'être enregistré : un appel erroné ne doit pas
% laisser la configuration de la session pointant sur une installation absente.
candidat = femmWineConfig();
if isfield(maj, 'prefix')
    candidat.prefix = maj.prefix;
    candidat.femmDir = fullfile(maj.prefix, 'drive_c', 'femm42');
end
if isfield(maj, 'femmDir')
    candidat.femmDir = maj.femmDir;
end

dossierMfiles = fullfile(candidat.femmDir, 'mfiles');
if ~isfolder(dossierMfiles)
    error("femmWineSetup:mfilesIntrouvables", "%s", sprintf( ...
        ['Dossier mfiles de FEMM introuvable : %s\n' ...
         'Installer FEMM sous Wine, ou indiquer le bon dossier :\n' ...
         '  femmSetup(femmDir="/chemin/vers/femm42")'], dossierMfiles));
end

femmWineConfig(maj);

addpath(dossierMfiles);
addpath(fileparts(mfilename('fullpath')));  % le pont passe devant
end
