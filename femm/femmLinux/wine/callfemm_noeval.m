function callfemm_noeval(x)
%CALLFEMM_NOEVAL Exécute une commande Lua dans FEMM sans évaluer la réponse.
%   Version du pont Wine, pendant de callfemm pour les commandes dont le
%   retour n'est pas exploité.
%
%   See also callfemm, femmWineExchange, openfemm.

arguments
    x (1,:) char
end

femmWineExchange(x);
end
