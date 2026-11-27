# P8.0-A — Expérimentation du cadrage de la ville

Branche **`p8-0a-cadrage-ville`**, depuis `p7-13-bordures-place`. EXPÉRIENCE : aucun angle n'est retenu, la décision revient
au créateur après examen des vidéos sur GPU.

## 1. Changements

* **Plongée de base de la ville choisie au chargement** (`scenes/p6/colisee.gd`, `plongee_ville()`) :
  `--plongee_ville=<degrés>`, sinon métadonnée `plongee_ville` de la scène, sinon `v06_plongee` (11°).
* **Plongée locale civique** (`plongee_civique_active()`) : active par défaut à 11° (P7.13 exact), coupée par défaut aux
  angles d'essai pour comparer à angle constant. `--plongee_civique=1` la force (transition base → 6,5° sur la terrasse
  civique), `--plongee_civique=0` la coupe.
* **Scènes F6** : `scenes/p7/ville_v07b_p80a_16.tscn`, `_20.tscn`, `_24.tscn`. Seule différence avec `ville_v07b.tscn` : la
  métadonnée de plongée.
* **Parcours** `p80a_cadrage` (marche) et `p80a_cadrage_course` (course), dans `src/explore25/routes25.gd`. Les cinq
  parcours de la demande, avec des points repris des trajets validés de P7.5 :
  * R1 : porte sud → Guilde → volée A ;
  * R2 : ruelle des Tonneliers → grande place ;
  * R3 : grande place → forge → Colisée ;
  * R4 : grande place → montée civique → château ;
  * R5 : retour du quartier civique vers la place.
* **Outil de mesure** `tools/p8/cadrage_p80a.gd` (lecture seule), par parcours :
  * Aren : masqué, hors du cadre, position à l'écran ;
  * escamotages : nombre, dont « tout », durée cumulée et durée moyenne, bascules, clignotements ;
  * horizon et sol visible devant Aren ;
  * Colisée, porte fortifiée et château : dans le cadre, et dégagés des volumes d'escamotage ;
  * toitures et terrasses vues de dessus.

**Inchangés** : champ (30°), zoom (×3), visée (0,1), suivi, Colisée (`v06_plongee`, arène à 20°), bâtiments, toitures,
terrasses, éclairage, matériaux, flou, collisions, interactions, escamotage. `ville_v07b.tscn` sans option = P7.13.

**Pourquoi le choix se fait au chargement seulement.** Les cartes, ombres rondes et sprites du décor sont dimensionnés
selon la plongée à leur construction (`1 / cos`). Une bascule en cours de partie fausserait la comparaison.

## 2. Commandes

| Angle | Éditeur (F6) | Ligne de commande |
|---|---|---|
| 11° (référence P7.13) | `scenes/p7/ville_v07b.tscn` | `godot --path . res://scenes/p7/ville_v07b.tscn` |
| 16° | `scenes/p7/ville_v07b_p80a_16.tscn` | `… res://scenes/p7/ville_v07b.tscn -- --plongee_ville=16` |
| 20° | `scenes/p7/ville_v07b_p80a_20.tscn` | `… -- --plongee_ville=20` |
| 24° | `scenes/p7/ville_v07b_p80a_24.tscn` | `… -- --plongee_ville=24` |

* **Parcours de comparaison**, identique pour chaque angle : ajouter `--route=p80a_cadrage` (ou `p80a_cadrage_course`).
* **Mesures** :
  `godot --headless --path . --script res://tools/p8/cadrage_p80a.gd -- --route=p80a_cadrage --plongee_ville=16`.
* **Stabilité des examens** :
  `godot --headless --path . --script res://tools/p7/stabilite_interactions_p7121.gd -- --route=p7_7121_interactions --quit --plongee_ville=16`.

## 3. Géométrie (calcul, indépendant du rendu)

Hypothèses : champ vertical de 30°, cadre de 12 m de haut au plan d'Aren (720 px, ×3), caméra à ≈ 22 m. La visée de 0,1
et l'azimut sont négligés, ce qui donne une approximation d'environ 1°. Aren est sur la grande place (65 ; 106 ; 3,5).

| Plongée | Caméra au-dessus du buste | Horizon à l'écran | Bord haut du cadre | Sol visible devant Aren |
|---|---|---|---|---|
| 11° | 4,3 m | 14 % du haut | 4° au-dessus de l'horizon | jusqu'à l'horizon |
| 16° | 6,2 m | hors cadre (−4 %) | 1° sous l'horizon | ≈ 390 m |
| 20° | 7,7 m | hors cadre (−18 %) | 5° sous l'horizon | ≈ 78 m |
| 24° | 9,1 m | hors cadre (−33 %) | 9° sous l'horizon | ≈ 43 m |

Conséquence probable, à vérifier en vidéo : **depuis la grande place, dès 16°, ni le ciel ni le haut de la porte fortifiée
ou du château n'entrent dans le cadre**. À 11°, ils y sont tout juste. Le gain de lisibilité du sol et la perte du
lointain varient donc en sens inverse.

## 4. Tests

**NON EXÉCUTÉS dans ce conteneur** : le lancement de Godot 4.7.2 y a été refusé par les permissions de la session. À
lancer avant toute conclusion :

```bash
godot --headless --path . --quit-after 60
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide
godot --headless --path . --script res://tests/e2e_p6_saut_tutoriel.gd
```

Lancer ensuite le parcours `--route=p6_sondes` du Colisée, puis `tools/p8/cadrage_p80a.gd` et
`stabilite_interactions_p7121.gd` pour chacun des quatre angles.

## 5. Points d'attention

* **Plongée civique.** Aux angles d'essai, la terrasse civique et l'avenue gardent l'angle de base. Pour juger « plongée
  plus forte en bas, 6,5° en haut », ajouter `--plongee_civique=1`. La transition est alors plus ample (jusqu'à 17,5° à
  24°) et se fait sur 12 m de marche.
* **Ombre ronde d'Aren.** Depuis `colisee.tscn`, elle est dimensionnée à la plongée du Colisée (11°). Écart de taille en
  ville : environ 1 % à 16°, 4 % à 20° et 7 % à 24°. Ouvrir les scènes de la ville directement pour comparer.
* **Toitures.** Elles deviennent visibles par le dessus aux angles forts : faîtages et toits plats du blockout. Les relever
  en vidéo (mesure « toits vus de dessus » de l'outil).
* **Hauteurs d'escamotage.** Le test d'escamotage dépend de la hauteur de la caméra. Il s'applique tel quel, mais ses
  marges ont été réglées à 11° : des escamotages tardifs ou inutiles restent possibles.

---

# P8.0-A2 — Validation finale de la caméra de ville

Même branche. Décision du créateur après les vidéos 11 / 16 / 20 / 24° : **11° reste la référence artistique**. Dernière
expérience avant P8.0-B (éclairage). Rien n'est validé ; le défaut reste 11° (P7.13 exact).

## 1. Changements

* **13° et 14°** : scènes F6 `scenes/p7/ville_v07b_p80a_13.tscn` / `_14.tscn` (ou `--plongee_ville=13|14`).
* **Plongée civique de 6,5°** conservée par défaut jusqu'à 14° (`PLONGEE_CIVIQUE_MAX`). Les essais forts de P8.0-A
  (16°, 20°, 24°) restent à angle constant. `--plongee_civique=1|0` force ou coupe la plongée civique.
* **Zone de lecture facultative** (désactivée par défaut) :
  * terrasse du belvédère, rectangle `terrasse_cafe` (x 66 → 76, y 82 → 88, h 5,75), à `--zone_lecture=17` (ou 18) ;
  * scène F6 `scenes/p7/ville_v07b_p80a2_zone17.tscn` (base 11°) ;
  * montée sur les 2,5 premiers mètres de la terrasse, lissage critique de 0,6 s, pivot autour d'Aren, sans zoom ;
  * retour symétrique en sortant.
* **Parcours** `p80a_cadrage` : 6e segment **R6 belvédère** (entrée, tables, buvette, sortie).
* **Outil** `tools/p8/cadrage_p80a.gd`, mesures ajoutées par parcours :
  * plongée minimale et maximale ;
  * vitesse maximale de variation (°/s) ;
  * écart vertical d'Aren à l'écran d'une image à l'autre pendant une variation de plongée.

Suivi, visée, champ, zoom, Colisée, bâtiments, collisions, matériaux, éclairage et interactions sont inchangés.

## 2. Sprites, accessoires 2D et ombres quand la plongée varie (lecture du code)

* **Aren et les compagnons.** Leur taille est recalculée à chaque image selon la plongée courante
  (`colisee._sync_sprite`, `explore_3d._sync_sprite`). Leur taille à l'écran reste constante pendant une transition.
* **Cartes 2D du décor** (gardes, accessoires) **et ombres rondes.** Elles sont dimensionnées une fois, au chargement
  (`1 / cos`). Leur hauteur apparente suit ensuite cos(plongée courante) / cos(plongée de chargement) :
  * zone à 17° depuis 11° : −2,6 %, progressif ;
  * plongée civique depuis 13° : +2,0 % ; depuis 14° : +2,4 % (depuis 11° : +1,2 %, déjà le cas en P7.12.1) ;
  * soit 1 à 2 px pour une carte d'environ 64 px.
* Aucune compensation n'est ajoutée. Si l'écart se voit en jeu, on pourra recalculer ces cartes à chaque variation, comme
  pour Aren.

## 3. Estimation géométrique (à confirmer par l'outil et en jeu)

Hypothèses : champ de 30°, caméra à ≈ 22 m, visée négligée (≈ ±2°). Un repère est « dans le cadre » si son angle
au-dessus de l'axe de visée est inférieur à 15°.

| Point de vue | 11° | 13° | 14° | 17° |
|---|---|---|---|---|
| Grande place (65 ; 106) : sommet de la porte fortifiée | limite (15,0°) | hors cadre | hors cadre | hors cadre |
| Terrasse du belvédère : sommet du châtelet | dans le cadre (14,4°) | hors cadre (15,7°) | hors cadre | hors cadre |
| Terrasse du belvédère : tête des gardes de la porte | oui | oui | oui | oui (14,0°) |
| Terrasse du belvédère : château lointain | oui (13,9°) | hors cadre (15,7°) | hors cadre | hors cadre |

**Conséquence probable.** Dès 13°, le haut de la porte et le château quittent le cadre depuis la place et le belvédère,
alors qu'ils sont tout juste dans le cadre à 11°. La zone de lecture à 17° garde la porte et ses gardes, mais pas son
couronnement ni le château. **Elle ne remplit donc probablement pas la condition « sans affecter la lecture des
monuments ».** Elle est livrée pour juger la sensation, pas pour être retenue.

## 4. Diagnostic des trois premiers plans signalés (vidéos du 27/11)

### a. Les deux blocs de la placette des Voyageurs

* **Identification.** `tour_sud_o` (x 53 → 57, y 150 → 157, 12 m), `tour_sud_e` (x 63 → 67) et les remparts
  `rempart_sud_o` / `rempart_sud_e` (9 m) de la porte sud. Entre les deux : les vantaux ouverts (bois brun). En bas de
  l'écran : la barrière jaune de l'accès fermé.
* **Cause : géométrie provisoire et escamotage partiel.** Au départ, la caméra est hors les murs (≈ 22 m au sud
  d'Aren, y ≈ 165). Tours et remparts, en blockout, sont donc entre elle et Aren. `_decouper` les coupe à
  h0 + 3,5 m (`COUPE_ETAGE`), règle prévue pour un rez-de-chaussée d'habitation. On voit alors deux souches de 3,5 m
  au dessus sombre (blockout), sur toute la largeur du premier plan.
* **Corrections locales recommandées**, sans reconstruction :
  1. coupe propre aux fortifications : environ 1,2 m, lecture de parapet ; ou escamotage entier tant que la caméra est
     hors les murs ;
  2. dessus de coupe en pierre (chemin de ronde) plutôt qu'en plancher ;
  3. à terme, point d'apparition décalé de quelques mètres vers le nord, pour que la caméra soit dans la ville dès la
     première image.

### b. Le grand pan « de toiture » à l'arrivée sur la place

* **Identification.** Ce n'est pas un toit : c'est le **chapeau de coupe** de `bat_auberge_taverne` (x 68 → 80,
  y 115 → 132). Il s'agit du plancher de bois de l'étage, posé par `_chapeau` (P7.12.2) quand l'escamotage partiel
  retire les étages et le toit.
* **Cause : escamotage, composition.** En haut de la volée B, l'auberge est entre la caméra et Aren, donc ses étages
  sont escamotés. La coupe est à h0 + 3,5 = 3,5 m, **exactement le niveau de la place**. Le plancher prolonge donc le
  dallage sous forme d'une grande plate-forme de bois orangé (≈ 12 × 17 m) qui occupe le quart inférieur droit de l'écran.
  La Guilde (x 32 → 56, mêmes hauteurs) peut produire le même effet à gauche.
* **Corrections locales recommandées :**
  1. coupe abaissée pour les volumes dont la coupe tombe au niveau d'un sol praticable voisin : environ 2,6 m, pour
     créer une marche visible sous la place ;
  2. plancher moins saturé et plus sombre, arase de pierre plus large : la coupe doit se lire comme un mur arasé, pas
     comme un sol ;
  3. ou, pour ces deux volumes seulement, escamotage entier en haut de la volée.

### c. Le volume sombre près de la ruelle des Tonneliers (16° et plus)

* **Identification.** Le versant de toit de `bat_auberge_taverne` (tranche P7.6), au-dessus de sa façade ouest enduite
  aux volets verts, en montant la volée B.
* **Cause : composition et matière provisoire, pas l'escamotage.** L'auberge est **à côté** d'Aren, pas entre lui et la
  caméra : l'escamotage n'a pas à la retirer.
  * À 11°, on n'en voit que l'égout.
  * Dès 16°, la caméra monte d'environ 2 m et le versant entre dans le cadre en grand. Ce versant est hors soleil
    (soleil d'ouest-sud-ouest) et couvert des tuiles brun foncé de la tranche P7.6 (`tuiles_a`, antérieures à la
    terre cuite de la forge D) : il se lit comme une masse presque noire.
* **Corrections recommandées :**
  1. à 11°, rien d'urgent ;
  2. à 13° ou 14°, vérifier en jeu ;
  3. en P8.0-B (éclairage), relever l'ambiance des versants à l'ombre ;
  4. à terme, aligner les tuiles de la tranche P7.6 sur la terre cuite de la forge D (référence validée).

## 5. Commandes P8.0-A2

| Essai | F6 | Ligne de commande |
|---|---|---|
| 11° (référence) | `scenes/p7/ville_v07b.tscn` | sans option |
| 13° | `scenes/p7/ville_v07b_p80a_13.tscn` | `-- --plongee_ville=13` |
| 14° | `scenes/p7/ville_v07b_p80a_14.tscn` | `-- --plongee_ville=14` |
| 11° + zone de lecture à 17° | `scenes/p7/ville_v07b_p80a2_zone17.tscn` | `-- --zone_lecture=17` (ou 18) |

* **Parcours** : `--route=p80a_cadrage` (R1 à R6).
* **Mesures** :
  `godot --headless --path . --script res://tools/p8/cadrage_p80a.gd -- --route=p80a_cadrage --plongee_ville=13 [--zone_lecture=17]`.
* **Stabilité des examens** :
  `godot --headless --path . --script res://tools/p7/stabilite_interactions_p7121.gd -- --route=p7_7121_interactions --quit --plongee_ville=13`.

## 6. Tests

**NON EXÉCUTÉS** : Godot 4.7.2 n'est toujours pas disponible dans ce conteneur. Les commandes de la section 4 de P8.0-A
s'appliquent telles quelles. À lancer avant toute conclusion.
