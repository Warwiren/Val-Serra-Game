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
