# P6.2 — Circulation et visibilité du Colisée : étape A (plan de circulation)

Branche **`p6-2-colisee-circulation-visibilite`**, depuis `p6-1-colisee-camera-art` (`6ca2c32`). Branches
précédentes intactes. F5 inchangé. **Étape A seulement** : diagnostic, comparaison des solutions, nouveau plan,
recommandation. Aucune pièce n'a été refaite. Le seul changement de code rend l'azimut réglable pour les comparaisons
(détails au § 6).

## 1. Diagnostic : pourquoi il faut deux touches

`src/explore25/session25.gd` lit 8 directions écran (touches seules ou par paires). `World25.input_to_plan`
(`src/explore25/world25.gd`) les convertit dans le plan en tournant de l'**azimut de 20°** :

* **↑** déplace Aren vers (sin 20°, −cos 20°), soit **20° à l'est du nord** ;
* **→** le déplace vers (cos 20°, sin 20°), soit **20° au sud de l'est**.

Or `tools/p6/build_colisee.py` aligne tous les couloirs sur les axes du plan (nord-sud, est-ouest). Une touche seule
fait donc **dériver Aren de tan 20° = 0,36 m par mètre** vers un mur. Le glissement de `World25.move` et
`explore_3d.step_hero` le fait ensuite longer ce mur, souvent jusqu'à un coin. **Aucune des 8 directions** ne suit un
couloir : l'écart est de 20° pour une touche seule, de 25° pour une diagonale. Corriger avec une seconde touche ne fait
que changer de mur.

Mesure (`tools/p6/circulation_p6.gd`, modèle de collision du jeu, une touche maintenue, départs décalés de −0,7 / 0 /
+0,7 m ; résultats bruts dans [`media/p6_2/circulation_mesures.txt`](media/p6_2/circulation_mesures.txt)) :

| Tronçon | Azimut 20° (actuel) | Azimut 0° |
|---|---|---|
| Vestiaires → salle d'attente | 1/3 arrivées · **74 %** du trajet contre un mur · écart 3,1 m | 3/3 · 0 % · 3,2 s |
| Salle d'attente → tunnel → arène | **0/3** · 93 % · bloqué dans un coin | 3/3 · 0 % · 5,8 s |
| Arène (commandant) → grille est | **0/3** · 87 % · dérive dans le podium | 3/3 · 0 % · 5,7 s |
| Tunnel est → coursive → sortie | **0/3** · 82 % · écart 11 m | 3/3 · 0 % · 11,4 s |

Le défaut ne vient pas du plan lui-même : le parcours est déjà construit sur deux droites, **x = 26** (vestiaires →
arène) et **y = 23** (arène → sortie). Il vient de l'écart de 20° entre ces axes et ceux de la caméra.

## 2. Solutions comparées

**A — Tourner l'agencement de 20° pour l'aligner sur la caméra.**
* Le socle `World25` ne connaît que des rectangles alignés sur les axes (surfaces, solides, sondes, tests). Il faudrait
  ajouter des rectangles orientés partout, une refonte du modèle de collision.
* Surtout, **l'effet visuel serait identique** à la solution B : seule compte l'orientation relative entre architecture
  et caméra. Seule la direction du soleil changerait.
* **Écartée** : même résultat que B, pour beaucoup plus de travail et de risque.

**B — Azimut 0° dans le Colisée, plan conservé.**
* Mesure : **une seule touche suffit sur tous les tronçons**, sans aucun contact. Le parcours complet se fait avec
  ↑ (≈ 29 m), puis → (≈ 38 m) : **un seul changement de touche**.
* Rendu ([`azimut_20_0.jpg`](media/p6_2/azimut_20_0.jpg), même plongée 24°, champ 30°, zoom ×3, mêmes positions) :
  - les murs du fond font face à la caméra, comme dans vos références d'Octopath Traveler II (salle à rayonnages,
    palais), et les pièces se lisent immédiatement ;
  - les murs latéraux deviennent des plans fuyants, qui délimitent la pièce sans la cacher ;
  - on perd la vue de biais qui donne du volume à la forêt. Elle reste à 20° (aucun changement).
* Les autres réglages ne bougent pas automatiquement : plongée 24°, champ 30°, zoom ×3. La plongée sera réévaluée dans
  le prototype de l'étape B.

**C — Garder 20° avec une aide locale de couloir** (aimantation de la direction sur l'axe du couloir, comme l'aide
d'escalier existante).
* Elle corrige le déplacement, mais **pas l'image** : les couloirs restent en biais à l'écran, et une touche verticale
  produirait un mouvement visiblement oblique.
* C'est aussi une modification des commandes pour compenser le plan, ce que vous souhaitiez éviter.
* **Non retenue** ; elle reste envisageable plus tard pour un cas isolé.

**Recommandation : B.** Azimut 0° pour le Colisée, et plus généralement pour **les intérieurs et l'architecture**
(Guilde, maisons, commerces, palais). 20° pour les extérieurs naturels (forêt). Le passage de l'un à l'autre se fait
aux transitions de zone (fondu existant), jamais en pleine marche : il n'y a pas de rotation automatique en cours de
jeu.

## 3. Nouveau plan

[`plans_ancien_nouveau.png`](media/p6_2/plans_ancien_nouveau.png) : plan actuel et plan proposé côte à côte. Il montre
les pièces, couloirs, portes (vert ouvert, jaune scénarisé, rouge fermé), la sortie vers la ville, les PNJ, les axes du
monde avec la direction des touches à l'écran, les secteurs de visibilité S1–S8 et le parcours d'Aren avec les touches
à chaque tronçon.

Parcours idéal d'Aren (azimut 0°) :

| Tronçon | Touche | Longueur |
|---|---|---|
| Départ → porte nord des vestiaires (S1) | ↑ | ≈ 5,5 m |
| Passage → salle d'attente (S2) → tunnel (S3) | ↑ | ≈ 14 m |
| Tunnel → arène, jusqu'au commandant (S4) | ↑ | ≈ 9 m |
| *(tutoriel)* | | |
| Commandant → grille est → tunnel est (S5) | → | ≈ 18 m |
| Coursive (S6) → couloir de sortie (S7) → ville | → | ≈ 20 m |

Les diagonales restent disponibles pour circuler librement dans les pièces (arène, coursive), mais aucun passage
ordinaire ne les exige.

## 4. Modifications architecturales proposées

La topologie est conservée : vestiaires → salle d'attente → tunnel → arène → coursive → sortie est → ville, arène
ovale, coursive qui distribue les accès secondaires.

1. **Azimut 0° dans le Colisée.** Plongée, champ et zoom seront testés dans les pièces pilotes.
2. **Axe nord-sud x = 26 dégagé sur 3 m** de bout en bout :
   - passage vestiaires → salle d'attente élargi de 2,5 à 3 m (les seuils des deux côtés s'alignent alors sur la porte
     nord de la salle et sur le tunnel) ;
   - mobilier et PNJ hors de l'axe (déjà le cas, sauf le tapis, à placer en bordure).
3. **Axe est-ouest y = 23 dégagé sur 3 m** : grille est, tunnel est, coursive, couloir de sortie. C'est déjà le cas ;
   les piliers et les PNJ de la coursive restent hors de l'axe.
4. **Secteurs de visibilité S1 à S8**, un par pièce ou couloir, délimités par des **seuils** au droit des portes :
   S1 vestiaires, S2 salle d'attente, S3 tunnel sud, S4 arène, S5 tunnel est, S6 coursive, S7 couloir de sortie,
   S8 infirmerie. Réserve, loge et gradins restent fermés et non affichés.
5. **Classement des murs** de chaque secteur :
   - fond (nord) : pleine hauteur, décoré ;
   - côtés : pleine hauteur ;
   - premier plan (sud) : **coupé**, réduit à un muret de 0,6 m avec une coupe sombre et épaisse, pour qu'on ne
     croie pas pouvoir passer dessus ;
   - murs des secteurs non visibles : masqués.
   - Dans tous les cas, **les collisions sont inchangées et indépendantes** de l'affichage.
6. **Plafonds** des secteurs intérieurs (S1–S3, S5–S8) : invisibles pour la caméra, mais **projetant des ombres**.
   Ils coupent la lumière extérieure dans les intérieurs. L'arène reste à ciel ouvert.
7. **Limites de caméra par secteur** (rectangle du secteur plus une petite marge), avec un glissement doux au
   franchissement d'un seuil. Au-delà des murs d'un intérieur, rien d'autre que l'ombre : c'est la convention des
   intérieurs HD-2D de vos références, et elle remplace la vue sur le parvis et les bâtiments lointains.
8. **Ce que montrent les ouvertures** :
   - depuis S2, l'entrée du tunnel S3 et, au fond, un aperçu de l'arène qui grandit à l'approche ;
   - depuis S3, l'arène ;
   - depuis S4, la bouche des deux tunnels ;
   - depuis S6, le tunnel est, la porte de l'infirmerie et le couloir de sortie.
   - Les autres secteurs ne sont pas affichés.

## 5. Visibilité : principe technique proposé (étape B)

Ce que je propose, sans système de portails :

* Un **découpage par secteurs** de la géométrie : un nœud par secteur, avec ses murs classés (fond, côtés, premier
  plan) et ses objets.
* Le secteur actif est celui de la surface sous Aren (déjà connue : `hero_region`), et ses voisins visibles sont
  déclarés dans les données.
* Changement de secteur : fondu de la visibilité (≈ 0,3 s) et glissement des limites de caméra.
* Les nœuds masqués **ne sont pas rendus** (économie d'appels de dessin) ; leurs collisions restent actives.
* Le trou de visibilité autour d'Aren est conservé pour les rares cas restants (piliers, mobilier haut).
* Le module serait réutilisable tel quel pour la Guilde et les autres bâtiments : un fichier de données décrit
  secteurs, seuils et voisins.

## 6. Changements de code de l'étape A

| Fichier | Changement |
|---|---|
| `src/explore25/world25.gd` | `const YAW` reste la référence (20°) ; ajout de `static var yaw` utilisée par la projection et les commandes. `explore_3d.gd`, `avant_poste.gd` et `paysage25.gd` lisent `World25.yaw`. Rien ne change pour la forêt, l'avant-poste ou les tests (81 / 81). |
| `scenes/p6/colisee.gd` | option `-- --azimut=0` (comparaison), azimut remis à 20° en quittant la scène |
| `tools/p6/circulation_p6.gd` | mesure de circulation au clavier |
| `tools/p6/plan_p6.py` | génération des plans |
| `src/explore25/routes25.gd` | parcours `p6_az` (captures de comparaison) |

## 7. Décision attendue

1. **Valider la solution B** (azimut 0° pour le Colisée et les intérieurs, 20° conservé pour la forêt) et le
   **nouveau plan**.
2. Ensuite, étape B : prototype vestiaires + salle d'attente avec secteurs, murs coupés, plafonds d'ombre, limites de
   caméra, placement des objets, premier éclairage intérieur, vidéo de circulation et de visibilité.
3. Le **saut du tutoriel** (étape D) ne touche pas à la géométrie : il peut être développé indépendamment, en parallèle
   de l'étape B, si vous le souhaitez.
