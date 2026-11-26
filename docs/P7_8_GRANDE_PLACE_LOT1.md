# P7.8 — Grande place, lot 1 : revêtement et fontaine

Branche **`p7-8-grande-place-lot1`** (depuis `p7-7-controles-composants`). Le lot 2 n'est pas commencé.

## Modifications

* **Revêtement** des surfaces de la place : `grande_place`, `place_ouest` et `place_recoin`.
  * Dallage enrichi du Colisée.
  * Bordures de pierre claire au nord et au sud, carroyage discret tous les 7 m.
  * Caniveau à grilles de fonte au pied des façades nord.
  * Compas octogonal autour de la fontaine, à joints rayonnants.
  * Voie processionnelle sur l'axe du château.
* **Fontaine octogonale à deux vasques**, à l'emplacement d'origine : bassin de 6 m, pilastres d'angle, margelle et
  emmarchement bas, pile, vasque basse à quatre bouches, fût mouluré, vasque haute, pomme de pin. Elle mesure 2,8 m.
  * Eau animée **opaque** : bruit procédural, sans transparence ni trame (`src/p7/eau_p78.gdshader`), et filets d'eau.
  * Collision : un **prisme octogonal ajusté au bassin**. L'ancienne boîte de 6 × 6 m bloquait à vide aux angles.
* **Axe du château réservé** dans les données (`axe_chateau`) : vue droite et montante depuis la place, x = 70, vers une
  future porte fortifiée centrée en y = 40. Le château n'est pas construit. `tools/p7/camera_volumes_p76.py` vérifie que
  rien ne coupe la ligne de vue (résultat : dégagé).
* **Défaut de P7.6 corrigé** : le revêtement du bras est ne s'appliquait pas, car c'est une surface surélevée. Les surfaces
  surélevées de la tranche et de la place gardent maintenant leur collision et leurs murs de soutènement, et reçoivent leur
  revêtement.
* `--place=0` : place du blockout, pour comparer.

Ce qui n'a pas changé : circulations, collisions des bâtiments, entrées fonctionnelles, trois terrasses, caméra, masquage
net.

## Fichiers principaux

* `scenes/p7/place_p78.gd` (nouveau) : revêtement, fontaine, primitives polygonales.
* `src/p7/eau_p78.gdshader` (nouveau) : eau.
* `scenes/p7/ville_v07b.gd` : branchement du lot 1 et des surfaces surélevées.
* `tools/p7/build_ville_v07b.py` et `data/p7/ville_v07b.json` : axe du château, texte d'examen de la fontaine.
* `tools/p7/camera_volumes_p76.py` : contrôle de l'axe.
* `src/explore25/routes25.gd` : parcours de contrôle `p7_78_place`, et un point de passage au sud de la fontaine pour
  les trajets.

## Tests

| Test | Résultat |
|---|---|
| Tests unitaires | 76 sur 76 |
| Ouverture P6 et saut du tutoriel | réussis |
| `p6_sondes` | 10 sur 10 |
| F5, V11 | sans erreur, 0 échec |
| Chargement V0.6, V0.7-A, V0.7-B et du catalogue | sans erreur |
| Sondes de la ville, A et B | 40 sur 40 |
| Portail ville ↔ Colisée, A et B | 4 passages |
| Recouvrements de volumes | 0 |
| Axe du château | dégagé |
| Trajets, A et B | 29 sur 29 |
| Visite complète `p7_v07b_video` et parcours des corrections `p7_76_video` | 38 sur 38, 22 sur 22 |

## Problèmes connus

1. **Trajets.** Le tronçon T3 du parcours automatique bloquait en caméra A : sa ligne droite heurtait de face une pente
   de l'octogone. Avec l'ancienne boîte, Aren glissait le long des faces. La place est en réalité plus dégagée qu'avant ;
   j'ai seulement ajouté un point de passage au sud de la fontaine (même chose dans `p7_76_video`).
2. **Rendu non vérifié en Forward+.** Toutes les vérifications visuelles ont été faites dans le rendu Compatibilité
   (OpenGL sur processeur). L'eau, le relief du dallage et les filets sont à juger sur votre GPU.
3. **Limites du lot 1.** La place touche encore du blockout : rue du Colisée, parvis et allée à l'ouest, et tous les
   bâtiments (lots 2 à 6).

## Éléments provisoires encore visibles (à remplacer avec leur secteur)

| Élément (données) | Où | Remplacement prévu |
|---|---|---|
| `barriere_chantier` (bloc **jaune** près de la jardinière) | Rue du chantier, accès A | Finition du secteur de la tranche : palissade de chantier, tréteaux, pierres en attente, panneau |
| `barriere_route_sud` (bloc orangé) | Porte sud | Secteur de la porte sud |
| `etal_0` à `etal_3` (boîtes brunes, auvents rouges) | Bords de la place | Lot 5 |
| `echoppe_no`, `echoppe_no_o`, `b_no_place` (dalles beiges) | Allée du Colisée, perron | Lot 2 (cour de la forge) et secteur du Colisée |
| `bat_forge_armurerie`, `bat_boutique_fournitures`, `bat_commerce_e2` | Nord de la place | Lots 2 et 3 |
| `socle_palier_2`, `socle_palier_2b`, `bat_b_arriere_forge`, `bat_administration`, volées C / D | Fond nord | Lot 4 |
| `gc_place_o`, `gc_place_e`, `gc_place_bras_o` (garde-corps gris) | Bord sud de la place | Lot 6 |
| Guilde, `bat_b_o_placette`, volées A / B, murs de soutènement des paliers | Placette et montée | Secteur de la placette |
| `rempart_sud_*`, `tour_sud_*` (murets sombres) | Porte sud | Secteur de la porte sud |
| Caravane, guérites, gardes | Accès B et C | Avec leurs accès |
| Volumes de paysage (blocs à toits rouges) | Arrière-plans | Après les secteurs jouables |

## Comparatif Quaternius (préparation, avant le lot 2)

Les deux archives sont sur le Drive (`ValSerra_Quaternius_MedievalVillage_Godot_glTF.zip` et
`ValSerra_Quaternius_FantasyProps_Godot_glTF.zip`, CC0). Quinze modèles en ont déjà été importés en P6.3
(`art/p63/quaternius/`).

Proposition : 4 à 6 modèles représentatifs pour les lots 2 et 3, comparés dans le catalogue F6 à nos composants, sans
remplacement automatique :
* Medieval Village : un module de mur avec fenêtre, une porte, un élément de toit ;
* Fantasy Props : enclume ou établi, tonneaux et caisses, étal de marché.

À faire lors du lancement du lot 2, avec votre accord.
