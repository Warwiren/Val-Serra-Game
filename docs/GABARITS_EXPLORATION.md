# Gabarits de l'exploration HD-2D — sol, maison, grand arbre

Branche **`exploration-illustree`** (depuis `decors-illustres`). Étape 1 de la refonte artistique de
l'exploration : **gabarits seulement**. Aucune illustration n'est intégrée, aucun élément du jeu n'est modifié.
Objectif de qualité : l'arène de combat illustrée (`art/arena/lisiere/peint/hd_base.png`).

Kit : **`docs/media/gabarits_exploration/`** (≈ 5,6 Mo). Reproduction :
```
python tools/explore/gabarits_blender.py <rendus> 32          # Blender (module bpy 5.2.3), ≈ 6 min
python3 tools/explore/gabarits_reperes.py <rendus>             # assemble le kit et gabarits.json
```
Les gabarits sont rendus depuis **la scène Blender qui a produit le décor actuel** (`tools/explore/scene_blender.py`,
géométrie inchangée), avec la même caméra et la même lumière : ils correspondent exactement au jeu.

## 1. Cadre, échelle et perspective (communs à tous les assets)
| | Valeur |
|---|---|
| Monde du jeu (natif) | **704 × 400** px ; 20 px natifs par mètre au sol |
| Affichage | ×2 → **1408 × 800 px** : c'est la taille de référence de toutes les illustrations (1 px d'image = 1 px d'écran) |
| Écran visible | 1280 × 720 : la caméra suit le groupe et parcourt les 1408 × 800 ; **tout le cadre doit être peint** |
| Caméra | **orthographique**, plongée **35°**, rotation **20°** vers la droite — pas d'isométrie 2:1, pas de point de fuite |
| Conséquences | les verticales restent verticales ; 1 m de hauteur = 16,4 px natifs = **32,8 px à l'écran** ; au sol, 1 m vers la droite = (37,6 ; −7,8) px écran, 1 m vers le fond = (−13,7 ; −21,6) px écran (`terrain/grille_sol_1m.png`) |
| Lumière | lune froide (bleu-blanc) en haut à gauche, contre-jour violet, lanternes et fenêtres chaudes ; ombres bleu-violet, jamais noires |
| Échelle de lecture | Aren ≈ 58 px de haut à l'écran ; porte de la maison ≈ 68 px |

La projection du sol est **affine** (caméra orthographique) : `gabarits.json` donne la matrice qui convertit un
point au sol (mètres) en pixels natifs, pour placer n'importe quel élément au bon endroit.

## 2. Gabarit A — terrain (`terrain/`)
| Fichier | Contenu | Usage |
|---|---|---|
| `terrain_gabarit_1408x800.png` | sol, chemin, lisière de forêt du fond et buissons du bas, **sans aucun objet ni ombre d'objet** | base de repeinture ou de génération guidée |
| `terrain_avec_ombres_1408x800.png` | idem avec les ombres portées de la maison, des arbres, des lanternes… | référence de lumière |
| `ombres_des_objets_calque.png` | ombres des objets seules (calque transparent) | à garder **séparé** (voir § 5) |
| `profondeur_terrain_1408x800.png` | profondeur (blanc = proche) | génération guidée (ControlNet « depth ») |
| `grille_sol_1m.png` | grille au sol (1 m fin, 5 m épais) + axes | respecter la perspective 35°/20° |
| `reperes_terrain.png` | limite praticable (jaune), obstacles (rouge, = collisions), éléments sans collision (cyan), lignes de tri (magenta), départ du groupe, garde, Vorgane, lanternes, **zones à garder dégagées** autour du garde et du Vorgane | à poser au-dessus pendant le travail |
| `terrain_gabarit_avec_reperes.jpg` | les trois superposés | lecture rapide |
| `terrain_actuel_en_jeu_x2.png` | le fond actuel du jeu, ×2 | comparaison |

## 3. Gabarit B — maison (`maison/`)
Rectangle dans le cadre : **x 597–1000, y 0–381** (403 × 381 px). Le toit touche le bord haut du cadre : la
caméra ne monte jamais plus haut, il est inutile de peindre au-delà.
| Fichier | Contenu |
|---|---|
| `maison_complete_cadre_1408x800.png` | maison **complète**, à sa place dans le cadre, fond transparent |
| `maison_gabarit.png` | la même, recadrée |
| `maison_zones.png` + `legende_zones.json` | carte des matières : ardoise, enduit, colombages, soubassement de pierre, porte et volets, vitres, mousse, enseigne |
| `maison_trait.png` | trait (contours des matières et silhouette) |
| `maison_profondeur.png` | profondeur |
| `maison_reperes.png`, `maison_gabarit_avec_reperes.jpg` | emprise au sol = collision (rouge), ligne de tri, **porte et trois fenêtres** (deux au rez-de-chaussée, une à l'étage) ; coordonnées dans `gabarits.json` |
| `ombre_au_sol_cadre_1408x800.png` | ombre de la maison seule |
| `maison_actuel_en_jeu.png` | la maison actuelle du jeu : elle est **trouée** là où les caisses, la lanterne et les barriques la cachaient au rendu |

Emprise (natif) : façade de (353,5 ; 178,9) à (477,6 ; 153,0), arête arrière droite jusqu'à (444,7 ; 101,3) ; ligne de tri
y = 178,9. Ces valeurs **ne changent pas** : la maison illustrée se pose sur ce gabarit.

## 4. Gabarit C — grand arbre (`arbre/`, élément `arbre_g`)
Rectangle : **x 72–379, y 137–468** (307 × 331 px). Pied du tronc et emprise (collision) : (110,6 à 127,0 ;
213,5 à 222,9) natif, ligne de tri y = 222,9.
| Fichier | Contenu |
|---|---|
| `arbre_complete_cadre_1408x800.png`, `arbre_gabarit.png` | arbre complet, fond transparent |
| `masque_tronc.png`, `masque_feuillage.png` | séparation tronc / feuillage |
| `arbre_zones.png`, `arbre_trait.png`, `arbre_profondeur.png` | matières, trait, profondeur |
| `arbre_reperes.png`, `arbre_gabarit_avec_reperes.jpg` | pied du tronc, emprise, ligne de tri |
| `ombre_au_sol_cadre_1408x800.png` | ombre de l'arbre seule |

## 5. Méthode d'intégration recommandée
**Calques recalés sur le cadre 1408 × 800**, affichés 1:1 comme l'arène de combat (pas de pixellisation) :
1. Chaque illustration est livrée **à la taille du cadre** (ou ×2 : 2816 × 1600, réduite une seule fois en
   Lanczos), avec l'objet **à sa place**. Plus de coordonnées à recopier : l'importeur découpe le calque à sa
   zone utile et calcule sa position.
2. **Sol** : remplace `fond.png` (affiché ×2 aujourd'hui) par une plaque 1408 × 800 à l'échelle 0,5 du monde.
   Les **ombres des objets** et les **flaques de lumière des lanternes** dans deux calques à part (multiplication
   et addition) : on peut retoucher un objet sans repeindre le sol.
3. **Maison** : une image **complète**, non coupée par les accessoires. Le tri de profondeur s'occupe des
   recouvrements : le défaut actuel (terrain vide quand la transparence locale s'applique devant un objet) disparaît.
   Les fenêtres éclairées dans un petit calque séparé permettent une respiration lumineuse discrète.
4. **Arbre** : tronc et feuillage en deux calques, triés sur la même ligne (pied du tronc) ; la transparence
   locale s'applique au feuillage comme aujourd'hui. Collision et ligne de tri inchangées.
5. Les **collisions, lignes de tri et le praticable** restent ceux de `zone.json` : aucune donnée de jeu ne vient
   de l'illustration. L'importeur vérifiera que la silhouette respecte l'emprise (pas de mur peint hors de la
   collision, ni de collision dans le vide).
6. Contrôle à chaque asset : capture avant/après au même cadrage, parcours clavier (`--course=manuel`),
   approches du garde (`--course=pnj`), retour de combat, mesure de performances (`tests/perf_probe.gd`).

Mémoire graphique estimée : plaque de sol 4,5 Mo, maison 0,6 Mo, arbre 0,4 Mo — négligeable.

**Production externe possible** : tout l'aspect illustré (peinture ou génération guidée puis retouche). Les
gabarits sont prévus pour les deux : repeinture directe sur `*_gabarit*.png`, ou génération guidée par
`*_profondeur.png` + `*_trait.png`, en respectant `reperes_*`. De notre côté : découpe, recalage, intégration,
contrôles.

## 6. Fichiers à fournir (dans l'ordre de validation)
Formats : **PNG sans perte**, RGBA (fond transparent sauf le sol), sRGB, **1408 × 800 recalé** (ou 2816 × 1600),
sans texte, sans personnage, sans PNJ ni monstre. Source en calques (PSD/Krita) en plus si possible.

| # | Fichier | Contenu attendu | Contraintes |
|---|---|---|---|
| 1 | `sol_plaque.png` (opaque) | herbe variée, terre, chemin de pavés usés et irréguliers aux bords fondus, racines, pierres, mousse, zones humides ; lisière de forêt en haut, sol bas et buissons en bas | chemin et praticable aux mêmes endroits ; **pas** d'ombres d'objets ni de lumière des lanternes ; zones autour du garde et du Vorgane lisibles |
| 1b | `sol_ombres.png` | ombres des objets (maison, arbres, lanternes, clôtures…) en noir/violet transparent | calquées sur `ombres_des_objets_calque.png` |
| 1c | `sol_lumieres.png` | flaques de lumière chaude des 3 lanternes et des fenêtres | centrées sur les repères « lanterne » |
| 2 | `arbre_tronc.png`, `arbre_feuillage.png` | écorce, racines, branches ; grappes de feuilles organiques, tons froids, accents lumineux discrets | pied du tronc au repère, tronc dans `masque_tronc`, feuillage à peu près dans `masque_feuillage` (peut déborder un peu) |
| 3 | `maison.png` (+ `maison_fenetres.png`) | colombages et bois patinés, enduit texturé, soubassement de pierre, ardoise usée et moussue, porte et trois fenêtres éclairées **aux emplacements du gabarit** | silhouette et façade du gabarit ; **côté gauche** étroit visible (et non le droit : voir le gabarit) ; même construction que la maison de l'arène |
| 4 | puis : `buisson_*.png`, `muret.png` | après validation des trois grands éléments | — |

## 7. Arrêt pour validation
Rien n'est intégré tant que les gabarits ne sont pas validés. Prochaine étape après votre retour : l'importeur
de calques recalés, puis le **sol seul**, avec comparatif avant/après dans Godot.
