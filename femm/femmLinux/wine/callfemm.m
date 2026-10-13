function z = callfemm(x)
%CALLFEMM Exécute une commande Lua dans FEMM et renvoie son résultat.
%   Version du pont Wine. Elle remplace l'implémentation livrée avec FEMM,
%   qui passe par ActiveX : sous Linux, MATLAB n'a pas de COM et actxserver
%   n'est qu'un fichier-souche non exécutable. Le transport passe donc par le
%   mode -filelink de femm.exe.
%
%   Les 624 autres fonctions de la boîte à outils FEMM (mi_*, mo_*, ...) sont
%   utilisées telles quelles : elles ne font que fabriquer la chaîne Lua et
%   la transmettre ici.
%
%   See also callfemm_noeval, femmWineExchange, openfemm.

arguments
    x (1,:) char
end

reponse = femmWineExchange(x);

z = [];
if isempty(reponse)
    return
end

% FEMM note l'unité imaginaire I, MATLAB l'attend en i
z = eval(strrep(reponse, 'I', 'i'));
end
