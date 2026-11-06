# Performances — premier bilan (avant / après l'intégration des décors illustrés)

Contrôle complémentaire du lot « décors illustrés » : on surveille, on n'optimise pas encore. Aucune
modification d'architecture n'a été faite pour la performance, à une exception près (voir « Corrigé »).

## Configuration de mesure — à lire avant les chiffres
- Conteneur sans carte graphique : **rendu logiciel** (Mesa llvmpipe, OpenGL 3, 4 cœurs Xeon 2,1 GHz, 16 Go).
  Les images/s ci-dessous sont donc **très pessimistes** : sur llvmpipe, chaque lumière 2D et chaque grand
  sprite coûtent du temps processeur. Elles servent à **comparer avant / après** dans les mêmes conditions,
  pas à juger l'objectif de 60 images/s sur PC.
- Godot 4.5 stable, fenêtre 1280×720, V-Sync coupée, démo automatique (déplacements, combat), 6 s de mesure
  après 30 images de chauffe, deux passes (écart entre passes ≈ 5 %).
- « Avant » = `main` au début du lot ; « après » = branche `decors-illustres`. Même script :
  `godot --path . --script res://tests/perf_probe.gd -- --perf-out=mesures.json`
- Mesures brutes : `docs/media/perf/mesures_avant.json`, `mesures_apres.json`.

## Résultats (2ᵉ passe)
| Scène | Images/s avant → après | Temps d'image p99 (ms) | Appels de dessin | Chargement (ms) |
|---|---|---|---|---|
| Exploration HD-2D | 65,2 → 65,0 | 25,2 → 19,6 | 28 → 53 | 58 → 66 (à froid : 229 → 214) |
| Combat, ancien décor | 27,5 → 28,1 | 44,9 → 45,9 | 234 → 238 | 463 → 461 ¹ |
| Combat, pilote rendu (Blender) | 16,6 → 17,3 | 73,7 → 69,6 | 255 → 254 | 272 → 210 |
| **Combat, arène illustrée** | — → **30,1** | — → 41,2 | — → 238 | — → 171 |
| Arène illustrée, lumières et particules coupées | — → 37,8 | — → 36,4 | 233 | — |

¹ Le premier combat de la série charge aussi les ressources communes du combat (sprites du Vorgane, HUD) :
c'est le **temps réel du passage exploration → combat**, environ 0,45 s ; les combats suivants ≈ 0,2 s.

**Mémoire** (moniteurs Godot) : statique ≈ 33 Mo en exploration, 42 Mo en combat (inchangé) ; textures ≈ 10,6 Mo
en exploration (+0,5 Mo), 44 à 48 Mo en combat (+1,6 Mo pour l'illustration, 1296×732 RGBA = 3,6 Mo de mémoire
graphique au maximum). **Logique de jeu** (même mesure sans rendu) : moins de 7 ms par image partout, avant
comme après — le coût est dans le dessin, pas dans les scripts.

**Lecture** : l'arène illustrée est **plus rapide** que le pilote rendu (une image au lieu de quatre plans avec
bandes de brume, lanternes moins fortes) et équivalente à l'ancien décor. En exploration, les 27 détails au sol
doublent les appels de dessin (une texture chacun) sans effet mesurable sur la fluidité. Les lumières et
particules du combat coûtent ≈ 20 % en rendu logiciel ; sur une carte graphique, ce coût est négligeable.

## Poids du projet et de l'export
| | Avant | Après |
|---|---|---|
| Dépôt (hors `.git`, `.godot`) | — | 203 Mo, dont **131 Mo de vidéos** dans `docs/media` (non exportées) |
| Export Windows (`ValSerra.exe` + `ValSerra.pck`) | 96,8 + 11,1 = **107,9 Mo** | 96,8 + 12,6 = **109,4 Mo** |
| Textures chargeables par le jeu | 1 544 fichiers, 6,9 Mo sur disque | 1 571 fichiers, 8,8 Mo sur disque |

L'exécutable (96,8 Mo) est le moteur Godot lui-même ; le contenu du jeu tient dans le `.pck`. Préréglage
d'export versionné : `export_presets.cfg` (exclut `docs/`, `tests/`, `tools/`, `art/source/`). L'export a été
produit ici avec les modèles officiels 4.5 ; il n'a pas pu être **lancé** (pas de Windows dans le conteneur).

## Textures (inventaire : `python3 tools/perf/inventaire.py`)
- Toutes les textures sont importées **sans perte** (mode 0) et sans mipmaps, sauf la texture du modèle 3D.
- Nouvelles textures : illustration de l'arène 1296×732 (1,7 Mo PNG) ; 27 accessoires et détails de 14×16 à
  266×101 px, à la taille exacte d'affichage. Les planches d'origine (WebP) sont conservées dans
  `art/source/planches_2026-11-06/`, ignorées par l'import et l'export.
- **Plus grande que l'écran** : `art/3d/vorgane_rig_Image_0.jpg` (2048², 21 Mo de mémoire graphique avec
  mipmaps si chargée). Elle n'est utilisée que par l'outil de comparaison `scenes/art/compare_ab.gd`, pas par le
  jeu, mais elle part dans l'export.
- **Doublons** : 254 groupes, tous **à l'intérieur** d'une même animation du Vorgane (images de pause répétées,
  ex. `art/proto/vorgane_nuit_p1/base`). Chaque copie est une texture chargée de plus.
- **Variantes non utilisées par le jeu** mais exportées : `art/proto/vorgane_p1/` (2,7 Mo, remplacée par
  `vorgane_nuit_p1/`) ; `art/proto/vorgane/` et `vorgane_nuit/` (1,9 Mo chacune) ne servent plus qu'aux tests
  de cadrage — à confirmer avant tout retrait (aucun fichier supprimé dans ce lot).

## Corrigé dans ce lot
- Le combat construisait **les deux décors** (ancien + pilote) même quand un seul était affiché. Le décor pilote
  n'est plus construit que s'il est affiché ; **F2** le construit à la demande pour comparer.

## Points à surveiller
1. **Mesure sur une vraie carte graphique** (même script, PC modeste) avant de conclure sur les 60 images/s.
2. Lumières 2D du combat (5 lanternes) : coût proportionnel à la surface éclairée.
3. Détails au sol de l'exploration : regrouper en une planche (atlas) si leur nombre dépasse la centaine.
4. Images répétées du Vorgane : référencer la même texture au lieu de copies (gain mémoire, pas de perte).
5. Exclure de l'export ce qui n'est pas utilisé par le jeu (texture 2048², variantes anciennes) après
   validation.
6. Vidéos de `docs/media` : 131 Mo dans le dépôt ; envisager Git LFS ou un stockage externe.
