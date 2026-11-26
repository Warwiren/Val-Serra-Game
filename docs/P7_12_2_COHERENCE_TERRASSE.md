# P7.12.2 — Cohérence architecturale, terrasse du belvédère, occultations, nettoyage

Branche **`p7-12-2-coherence-terrasse`**, depuis `p7-12-1-civique-consolidation`. Quatre commits séparés (A architecture,
B terrasse, C occultations, D nettoyage). EN ATTENTE de votre examen en jeu ; rien n'est annoncé validé.

## A. Cohérence des portes et de l'architecture (P0)

Règle appliquée : toute ouverture a une fonction compréhensible ; toute porte a un accès physiquement crédible. Aucun escalier
ajouté : une porte sans accès devient une fenêtre.

* **Administration, façade sud** : la porte des données (x 49) donnait sur le toit non praticable de l'arrière-forge, 1,3 m
  plus bas. Elle devient une **croisée** à appui (x 8,45 → 9,55 de la façade).
* **Corps de garde** : la baie centrale de l'étage, au-dessus du balcon, devient une **porte-fenêtre** (le balcon a enfin un
  accès ; l'appui de fenêtre est supprimé pour ce type de baie).
* **Couronnements** : celui du corps de garde (côté est) et celui du pavillon de l'hôtel de ville (côté ouest) traversaient le
  châtelet ; ils s'arrêtent désormais contre lui.
* **Joues grises de blockout** le long des volées C et D supprimées : les escaliers de pierre ont leurs propres murs d'échiffre.
* **`gc_palier_2_o`** : le garde-corps qui flottait au bord du palier devient une **banquette de pierre** (même collision).
* **Dessus de `socle_palier_2b`** (non praticable) : jardinière (jardin suspendu) au lieu d'un dallage qui suggérait un accès.
* Parcours de contrôle : `p7_7122_inspection`.

## B. Terrasse du belvédère (P1)

Je n'ai pas reçu vos captures annotées. J'ai retenu l'espace qui correspond à la description : le **socle `socle_palier_2`**,
au niveau du palier 2 (5,75 m), qui domine la grande place à l'est de la volée C. **À confirmer** : si l'emplacement visé est
un autre, seule la donnée de la surface est à déplacer.

* **Accès** : de plain-pied depuis le palier existant de la volée C (même hauteur, 5,75 m ; aucune marche ajoutée).
* **Données** (`tools/p7/build_ville_v07b.py`, régénérées) :
  * surface `terrasse_cafe` x 66 → 76, y 82 → 88, h 5,75 (remplace le bloc non praticable `socle_palier_2`) ;
  * garde-corps `gc_cafe_s` (bord sud, sur la place) et `gc_cafe_o` (bord ouest), hauteur 1 m, continus ;
  * trois tables `decor_cafe_1..3` (obstacles 1,3 × 1,3 m) ;
  * `emplacements_pnj` : `cafe_assis_1`, `cafe_assis_2`, `cafe_debout_3`. **Emplacements seulement**, aucun PNJ créé ;
  * examen `ex_terrasse_cafe` (description du lieu) ; zone nommée « Terrasse du belvédère ».
* **Habillage** (`civique_p712.gd`) : dallage civique, façade de soutènement (le blason de la place est conservé),
  balustrades, guéridons de fonte à plateau de pierre et tabourets (modèle Quaternius déjà importé), trois pots fleuris.
* Aucun commerce, aucun système de restauration.
* **Contrôles** (parcours `p7_7122_terrasse`, `p7_7122_terrasse_vues`) :
  * 10 points sur 10 atteints à 5,76 m ;
  * écarts entre les tables : 1,7 et 1,95 m ; entre tables et balustrade sud : 0,85 m au plus étroit ;
  * poussée vers la balustrade sud : arrêt en (70,35 ; 87,31), à 0,3 m de la main courante ;
  * poussée vers la balustrade ouest : arrêt en (66,69 ; 84,2) ;
  * axe du château dégagé, recouvrements de volumes : 0.

## C. Escamotage (P0)

**Bâtiments concernés** après la première montée (volées A et B) : la **Guilde** et l'**auberge**, au bord sud de la place,
et la tour `tour_sud_e` au passage de la porte sud. La caméra est à environ 22 m derrière Aren ; depuis le bord sud de la place,
la ligne de vue passe à environ 4 m de haut au droit de leur face nord.

**Adaptation de géométrie : non retenue.** Pour ne plus couper, il faudrait abaisser ces bâtiments sous 3,5 m ou les reculer
de plusieurs mètres, c'est-à-dire changer l'implantation de la place, hors périmètre. L'escamotage des seules parties hautes
(P7.12.1) reste donc la solution ; il est fini et stabilisé :

* **Marge de réapparition** : masquer reste immédiat (Aren d'abord) ; ré-afficher attend que la vue soit dégagée depuis
  0,6 s (`--escamotage_delai=<s>`). Plus de bascule aux arrêts et demi-tours.
* **Finition de la coupe** : quand les étages sont escamotés, un « chapeau » couvre le rez-de-chaussée : plancher de bois de
  l'étage et arase de pierre de 0,35 m sur le pourtour, posés au sommet réel de la partie conservée. Plus de dessus de blockout
  ni de ciel visible à travers la coupe. Le chapeau est caché dès que les étages réapparaissent.
* Le fondu reste expérimental (`--escamotage=fondu`, Forward+), non généralisé.
* Comparaison : `--escamotage_partiel=0` (escamotage P7.6, volume entier).

**Mesure** : `tools/p7/escamotage_p7122.gd` (nouveau) sur `p7_7122_aller_retour` (montée et descente, en marchant puis en
courant ; dix arrêts le long du bord sud de la place ; demi-tours). Le pilote de parcours accepte `"run": true` (Maj maintenue).

| Caméra, mode | Images où un volume visible masque Aren | Bascules (Guilde / auberge / tour) | Plus court intervalle |
|---|---|---|---|
| A, P7.12.2 | **0** | 4 / 4 / 5 | 1,1 s (tour) |
| A, `--escamotage_partiel=0` | 838 (auberge) | 4 / 4 / 4 | 3,4 s |
| B, P7.12.2 | **0** | 4 / 10 / 5 | 0,9 s (auberge) |
| B, `--escamotage_partiel=0` | 636 (Guilde 583, auberge 53) | 4 / 8 / 4 | 3,4 s |

Les intervalles courts restants ne sont pas des clignotements : ce sont les passages successifs haut → entier → aucun quand
Aren descend la volée B ou passe la porte sud (progression continue, sans retour en arrière).

**Interactions** : `tools/p7/stabilite_interactions_p7121.gd` (7 examens sur les trois niveaux) : écart du centre de caméra
**0 px**, caméras A et B.

## Appels de dessin

Zone du fond nord (x 26 → 118, y 8 → 89) : **686** surfaces, contre 638 en P7.12.1 (+48 : mobilier et pots de la terrasse,
balustrades, banquette, jardinière, baies). Les chapeaux de coupe (une surface fusionnée par matière et par volume) sont cachés
hors escamotage partiel.

## Fichiers

* `scenes/p7/civique_p712.gd` : baies, couronnements, banquette, jardinière, terrasse (soutènement, mobilier, pots).
* `scenes/p7/ville_v07a.gd`, `ville_v07b.gd` : joues de blockout, mobilier, marge de réapparition, chapeaux de coupe.
* `tools/p7/build_ville_v07b.py`, `data/p7/ville_v07b.json` : terrasse, garde-corps, tables, emplacements de PNJ.
* `src/explore25/session25.gd` (course dans les parcours), `routes25.gd` (parcours `p7_7122_*` ; trajet T3 de
  `p7_v07b_trajets` : point de contournement de la fontaine, voir Problèmes).
* `tools/p7/escamotage_p7122.gd` (nouveau).

## Problèmes

* Emplacement de la terrasse déduit de la description (captures annotées non reçues) : à confirmer.
* **Parcours `p7_v07b_trajets`** : le trajet T3 traversait la fontaine à 1,4 m de son centre et comptait sur le glissement
  du personnage. Avec les corps physiques ajoutés par la terrasse, l'ordre des contacts change et Aren s'arrête contre la
  vasque (26 points sur 29). Un point de contournement est ajouté (30 points sur 30, A et B). La collision de la fontaine
  n'a pas changé.
* Rendu contrôlé en mode Compatibilité seulement ; teintes du plancher de coupe et du mobilier à juger sur votre GPU.
* Les murets gris du palier visibles depuis le palier de la volée B restent du blockout (hors des corrections demandées).
