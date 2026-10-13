# Pont MATLAB → Lua → Wine pour FEMM

FEMM est un logiciel Windows. Sa boîte à outils MATLAB le pilote par **ActiveX/COM**,
ce que MATLAB pour Linux ne sait pas faire : `actxserver` n'y est qu'un fichier-souche
non exécutable (`toolbox/matlab/winfun/actxserver.m`).

Ce dossier remplace la couche de transport pour utiliser le mode **`femm.exe -filelink`**,
prévu par FEMM lui-même pour le pilotage par un processus sans COM.

## Principe

Sur les 628 fonctions de la boîte à outils FEMM, **4 seulement** touchent au transport ;
les 624 autres (`mi_*`, `mo_*`, …) ne font que fabriquer une chaîne Lua et la passer à
`callfemm`. Seuls ces 4 fichiers sont donc réécrits :

| Fichier | Rôle |
|---|---|
| `openfemm.m` | lance `wine femm.exe -filelink`, ou réutilise l'instance en cours |
| `callfemm.m` | envoie une commande Lua, évalue la réponse |
| `callfemm_noeval.m` | idem sans évaluation du retour |
| `closefemm.m` | envoie `quit()` et nettoie les fichiers d'échange |

Le protocole : MATLAB écrit `flput(<commande Lua>)` dans
`<femmDir>/bin/ifile.txt`, FEMM consomme le fichier et écrit sa réponse dans
`ofile.txt`. Une commande sans retour donne `[]`, une valeur donne une expression
évaluable par MATLAB, une erreur donne `error("...")`.

Support :

| Fichier | Rôle |
|---|---|
| `femmWineSetup.m` | met les mfiles de FEMM puis le pont sur le path, dans cet ordre |
| `femmWineConfig.m` | préfixe Wine, dossier FEMM, délais |
| `femmWineExchange.m` | aller-retour par fichiers, détection d'erreur, délai de garde |
| `femmWinePath.m` | conversion de chemin Linux → `Z:\...` |
| `femmWineEnv.m` | neutralise les `LD_LIBRARY_PATH`/`LD_PRELOAD` de MATLAB |
| `femmWineQuote.m` | protection des arguments shell |

## Utilisation

Le point d'entrée est `FEMM/femmSetup.m`, qui détecte le système : sous Windows il
met les mfiles d'origine sur le path et laisse le pilotage ActiveX en place, sous
Linux il ajoute ce pont par-dessus. Le code appelant est identique sur les deux
systèmes.

```matlab
femmSetup();       % une fois par session, portable Windows/Linux
openfemm(0);       % 0 : fenêtre FEMM visible, 1 : masquée
% ... commandes mi_* / mo_* habituelles ...
closefemm();
```

Installation FEMM ailleurs que dans l'emplacement par défaut :

```matlab
femmSetup(femmDir="/chemin/vers/femm42");   % ou "C:\femm42" sous Windows
```

`femmWineSetup` reste disponible pour forcer le pont, mais `femmSetup` est à
préférer. Voir `FEMM/main_MatlabFEMM.m` pour un cas complet.

## Prérequis

- Wine (`sudo apt install wine wine64`)
- FEMM 4.2 installé dans le préfixe Wine :
  ```
  wine femm42bin_x64_21apr2019.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART "/DIR=C:\femm42"
  ```
  soit `~/.wine/drive_c/femm42` côté Linux.

Solveur lent ? Le délai de garde par défaut est de 600 s :

```matlab
femmWineConfig(struct('timeout', 1800));
```

## Taille de l'interface FEMM (HiDPI)

FEMM dessine ses menus à 96 DPI en dur. Sous GNOME/Wayland avec
`xwayland-native-scaling`, XWayland présente à l'application un espace en pixels
natifs puis recompose en réduisant : l'interface apparaît minuscule. La fenêtre,
elle, se règle indépendamment (`main_maximize()`).

Le correctif est le DPI du préfixe Wine :

```bash
WINEPREFIX=~/.wine wine reg add "HKCU\Control Panel\Desktop" \
    /v LogPixels /t REG_DWORD /d 192 /f
```

puis relancer FEMM (`pgrep -x femm.exe | xargs -r kill`). Équivalent graphique :
`winecfg`, onglet Affichage, curseur de résolution.

La valeur vaut 96 × facteur d'échelle de l'écran utilisé. Mesures relevées sur la
fenêtre « FEMM Output » de ce poste :

| LogPixels | Fenêtre témoin | Facteur |
|---|---|---|
| 96 (défaut) | 246 × 252 | 1,00 |
| 154 | 395 × 429 | 1,61 |
| 192 (retenu) | 492 × 554 | 2,00 |

Le réglage est global au préfixe Wine : avec deux écrans d'échelles différentes,
choisir celle de l'écran où FEMM est utilisé.
