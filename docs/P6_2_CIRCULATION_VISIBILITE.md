# P6.2 — Circulation et visibilité du Colisée

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


---

# Étape B — Prototype vestiaires + salle d'attente (22/11/2026)

Décisions du créateur appliquées :
* **caméra du Colisée validée** : azimut 0°, plongée 24°, champ 30°, zoom ×3. `scenes/p6/colisee.tscn` et
  `colisee_azimut0.tscn` démarrent ainsi ; `colisee_azimut20.tscn` garde l'ancienne référence pour comparer. La forêt
  et l'avant-poste restent à 20° : l'azimut est remis à 20° en quittant la scène du Colisée.
* **plan validé** : le passage entre les vestiaires et la salle d'attente fait 3 m, les accès sont alignés et le trajet
  principal est dégagé.

Médias : [`pieces_planche.jpg`](media/p6_2/pieces_planche.jpg) et `media/p6_2/piece_*.jpg` (12 positions),
[`pieces_circulation_visibilite.mp4`](media/p6_2/pieces_circulation_visibilite.mp4),
[`eclairage_avant_apres.jpg`](media/p6_2/eclairage_avant_apres.jpg),
[`saut_tutoriel.mp4`](media/p6_2/saut_tutoriel.mp4).

## 1. Système de visibilité par secteurs (réutilisable)

Module `src/explore25/secteurs25.gd`, piloté par les données (`p6.secteurs` dans `data/p6/colisee.json`, généré par
`tools/p6/build_colisee.py`). Pour un nouveau bâtiment, il suffit de déclarer des rectangles, des voisins et une ambiance.

| Secteur | Pièce | Voisins affichés | Fond | Plafond d'ombre |
|---|---|---|---|---|
| S1 | Vestiaires | passage | sombre | 3,4 m |
| P12 | Passage (3 m) | vestiaires, salle | sombre | 3,2 m |
| S2 | Salle d'attente | passage, tunnel | sombre | 3,4 m |
| S3 | Tunnel des combattants | salle, **arène** | ciel | 2,9 m |
| EXT | Tout le reste (arène, coursive…) | tout, comme en P6.1 | — | — |

Le module distingue les quatre cas demandés :

1. **Murs visibles** depuis la pièce active : murs du fond et des côtés, en **pleine hauteur**.
2. **Murs qui cachent la caméra** : un mur est coupé (réduit à un muret de 0,5 m coiffé d'une **tranche sombre**) seulement
   si sa projection vers l'arrière-plan (hauteur / tan 24°) recouvre le sol de la pièce active. Ce n'est pas un
   abaissement général : dans les vestiaires, seul le mur sud est coupé ; dans la salle, son mur sud et le mur nord
   des vestiaires.
3. **Murs et décor des secteurs non visibles** : leur groupe n'est plus rendu du tout. Le décor composé pour une pièce y est
   rattaché explicitement (poutres, bannières, casiers) ; seuls les murs, qui sont des frontières, peuvent appartenir à
   deux secteurs.
4. **Collisions** : les corps physiques ne sont jamais déplacés, réduits ni masqués (vérifié par les sondes).

Transitions : le groupe qui disparaît s'abaisse vers le sol et celui qui apparaît s'en élève, en 0,35 s ; les murs
coupés descendent de la même façon. Rien ne disparaît d'un coup. Les limites de caméra glissent vers celles de la pièce,
et l'ambiance (fond, lumière ambiante) suit.

Résultats :
* **Vestiaires** : la pièce entière, la recrue, le garde et la porte encadrée par deux bannières de la Guilde. Ni
  l'arène, ni la salle, ni l'extérieur. La caméra est quasi fixe : la pièce tient dans le cadre.
* **Passage** : les deux pièces se voient par l'ouverture ; Aren est visible dans l'embrasure.
* **Salle d'attente** : la salle et ses trois Chasseurs. Les vestiaires disparaissent. Au fond, le tunnel et une lueur
  chaude, la lumière de l'arène, qui donne la direction.
* **Tunnel** : l'arène se révèle en grand, la salle reste derrière.

**Occlusion visible d'Aren** (`tools/p6/occlusion_visuelle_p6.gd`, rayons du buste et de la tête vers la caméra contre
ce qui est affiché) :

| | P6.1 (20°, sans secteurs) | P6.2 |
|---|---|---|
| Vestiaires | 4 % | 2 % (derrière le râtelier et le mannequin ; le trou de visibilité prend le relais) |
| Passage | 0 % | 0 % |
| Salle d'attente | **36 %** | **0 %** |
| Ensemble | 14,8 % | **1,2 %** |

## 2. Éclairage intérieur

* **Plafonds « ombres seulement »** au-dessus des pièces couvertes : invisibles pour la caméra, ils arrêtent le soleil. Ils
  sont indépendants de l'affichage : un plafond n'est jamais masqué, il ne fait qu'ombrer.
* **Lanternes murales** à ombres douces, avec la même qualité 4 que le soleil (aussi pour les lumières ponctuelles).
  Elles sont posées contre les murs latéraux et de part et d'autre de la porte, plus aucune devant les casiers, et
  produisent des flaques de lumière chaude, des coins plus sombres et des ombres du mobilier.
* Ambiance intérieure plus basse que dehors (0,42 contre 0,62), fond sombre, plancher moins saturé.

Avant / après au même endroit : [`eclairage_avant_apres.jpg`](media/p6_2/eclairage_avant_apres.jpg).

## 3. Placement du décor des vestiaires

Composition resserrée :
* casiers contre les murs nord et ouest ;
* deux bancs (le troisième, collé au mur sud, est retiré des données) ;
* râtelier garni ; mannequin ;
* coffre, caisse, sacs et tonneau dans les angles ; bûches déplacées entre les casiers et le râtelier.

Retirés :
* le tapis, qui encombrait l'axe ;
* les lanternes sur pied, plantées dans les casiers ;
* les carrés bleus du blockout et le bloc jaune au sud.

Le garde reste bien visible à droite de la porte ; la sortie est encadrée par les bannières.

## 4. Saut du tutoriel (commit séparé)

* Dans le dialogue du commandant, après la réponse au choix : **« Commencer l'entraînement » / « Passer le
  tutoriel »**. L'effet est porté par la réponse (`data/p6/dialogues_colisee.json`).
* Pendant le combat : bouton **« Passer le tutoriel (Échap) »** et touche Échap → **confirmation** (`src/tutorial/
  confirmation.gd`, « Non » sélectionné par défaut, ← → / Entrée / Échap / souris). « Non » : le tutoriel continue.
* **Conclusion commune** `Progression.conclure_tutoriel()` pour les trois cas (fin normale, saut en combat, saut dans le
  dialogue) : résultat `tutorial_completed`, retour au Colisée, puis le chemin habituel du retour (état, objectif Guilde,
  Aren devant le commandant, dialogue de fin, accès ouverts).
* CombatCore n'est pas modifié ; le commandant reste intact ; pas de victoire ni de défaite, pas de récompense.

## 5. Tests et mesures

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | **82 / 82** (+1 : secteurs) |
| `tests/e2e_p6_ouverture.gd -- --tuto-rapide` | réussi (Échap → confirmation → « Non » : on reste en combat) |
| `tests/e2e_p6_saut_tutoriel.gd` (nouveau) | réussi : saut dans le dialogue (aucun combat chargé) et en combat (confirmation), même état final, pas de relance |
| Sondes P6 `p6_sondes` | 10 / 10 (collisions inchangées) |
| Circulation à une touche (`tools/p6/circulation_p6.gd`) | 4 tronçons sur 4, 0 % de contact mural |
| P4 : e2e, `p4` 29 / 29, `p4_sondes` 20 / 20 ; P5 ; forêt V09B.5, V09C, V11 ; P5.2 ; P5.3-B | réussis |
| F5 | inchangé, se charge sans erreur |

**Performances** (`tools/p6/perf_pieces_p6.gd`, rendu logiciel, à confirmer sur votre GPU) :

| Position | Sans secteurs | Avec secteurs |
|---|---|---|
| Vestiaires | 825 appels de dessin · 29 k primitives | **347 · 7 k** |
| Passage | 707 · 24 k | 611 · 7 k (deux pièces visibles) |
| Salle d'attente | 638 · 23 k | **143 · 1 k** |
| Tunnel | 470 · 21 k | 450 · 21 k (arène visible) |

Les ombres des lanternes passent en mode « double paraboloïde » (2 passes au lieu de 6) ; seules celles du secteur
affiché sont actives. Mémoire vidéo : 182 → 214 Mo (cartes d'ombres). Les transitions ne coûtent qu'une animation
d'échelle par groupe.

## 6. Limites et points à valider visuellement

* La vidéo des pièces a été enregistrée juste avant le dernier réglage (ambiance 0,30 au lieu de 0,42) : le jeu est un
  peu plus clair que la vidéo. Les captures sont à jour.
* Au-dessus des murs du fond, c'est le noir (convention des intérieurs de vos références). Un haut de mur se perdant dans
  l'ombre, ou un plafond visible en coupe, pourrait l'adoucir : à décider.
* La lueur du tunnel est un simple panneau lumineux : à remplacer lors de la passe graphique.
* Arène, coursive et sorties restent en « EXT » (comportement P6.1) jusqu'à votre validation : depuis l'arène, on voit
  encore les pièces pilotes à l'ancienne.
* Rendu logiciel uniquement : ombres douces, lumières et performances à vérifier sur GPU.

## 7. Décisions attendues

1. Valider la méthode sur les deux pièces : secteurs, murs coupés seulement s'ils cachent la pièce, tranche sombre,
   plafonds d'ombre, transitions et éclairage.
2. Le noir au-dessus des murs du fond : à garder, ou à traiter (haut de mur dans l'ombre) ?
3. Ensuite, étape C : extension à l'arène, à la coursive et à la sortie, puis régénération du décor du combat tutoriel.
