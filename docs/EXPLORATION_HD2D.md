# Exploration HD-2D — prototype expérimental

Branche **`exploration-hd2d`** (non fusionnée). Scène séparée : `scenes/explore_hd2d/zone_hd2d.tscn`.
Lancement : ouvrir la scène dans Godot puis **F6**, ou `godot --path . -- --start=hd2d-zone` (ajouter `--autoplay`
pour la démo). La boucle actuelle (F5), le CombatCore, la Résonance et le HUD de combat ne sont pas modifiés.
Seul ajout côté combat : le retour se fait vers la scène d'origine (`GameState.explore_return`).

## Méthode (reproductible)
1. `tools/explore/scene_blender.py` construit la zone dans Blender : terrain, muret de terrasse, chemin pavé,
   maison à colombages usée, arbres, buissons, clôtures, caisses, tonneaux, banc, lanternes, lisière de forêt.
   La caméra est orthographique, en plongée de 35° et tournée de 20°. L'ambiance est un crépuscule bleu-violet avec
   des lanternes chaudes. Le script rend l'image et un masque par élément, et exporte les emprises au sol
   (collisions), les lignes de tri, la zone praticable et les points de départ (`zone.json`).
2. `tools/explore/paint_pass.py` transforme le rendu en pixel art : grille de pixels, étalonnage crépusculaire,
   palette de 40 couleurs avec tramage léger, herbe peinte (touffes et fleurs), contour des éléments, puis découpe
   en fond et sprites.
3. `tools/explore/build_chars.py` prépare les personnages à l'échelle : Aren est réextrait de ses planches à 29 px
   (environ 58 px à l'écran, 4 directions retouchées) ; Ilya, Throné, le garde et le Vorgane sont des réductions provisoires.

## Scène Godot
- **Affichage** : monde en pixels natifs, caméra ×2 au plus proche voisin, qui suit le groupe en douceur et reste
  bornée au décor. Pas de parallaxe : le terrain est fixe par rapport aux collisions.
- **Profondeur** : chaque élément contournable est un sprite trié selon la ligne de ses pieds. Les personnages
  passent devant ou derrière l'arbre, la maison, les lanternes et les clôtures.
- **Collisions** : zone praticable et emprises au sol projetées depuis Blender. Le personnage glisse le long des
  obstacles.
- **Déplacement** : 8 directions, vitesse verticale réduite, animation de marche pilotée par la distance
  parcourue. Aren utilise ses 4 directions.
- **Groupe** : Ilya et Throné suivent la trace d'Aren avec les mêmes collisions.
- **Interactions** : le garde parle avec la boîte de dialogue à deux portraits et un choix ; le contact avec
  le Vorgane lance le combat existant, puis ramène à cette scène.

## Tests
- Les 46 tests automatiques passent.
- Démo automatique exécutée dans Godot (vidéo de 46 s) : diagonales, passage derrière l'arbre puis derrière la
  maison, dialogue avec choix, contact avec le Vorgane, combat.

## Limites
- **Rendu** : plus riche et cohérent que le mini-test, mais encore loin des références. Les feuillages gardent des
  volumes ronds et lisses, venus de la 3D. Le sol scintille de points clairs (texture d'herbe et bruit de rendu).
  Le muret du premier plan se lit mal. Les dalles de pierre semées au sol paraissent posées.
- **Personnages** : Ilya, Throné et le garde sont des réductions des anciens sprites de face : pas de directions,
  pas de vraie marche à cette taille.
- **Profondeur** : quand le groupe passe derrière la maison, il disparaît entièrement. Il n'y a pas de silhouette
  ni de transparence pour le retrouver.
- **Zone** : un seul niveau praticable ; la caméra défile peu, car la zone fait 704×400 natifs pour une vue de
  640×360.

## Itération 2 (retours de l'analyse critique)
- **Occlusion** : une maison ou un arbre qui cache un membre du groupe devient translucide (alpha 0,5, transition
  douce), et une silhouette bleutée du personnage reste visible au-dessus du décor.
- **Dialogue** : il faut être à moins de 14 px natifs du garde pour lui parler (contre 26 avant). Plus loin, une
  bulle « … » signale seulement sa présence.
- **Monstre** : teinte crépusculaire et ombre de contact pleine sous le corps.
- **Décor** : le scintillement du sol est supprimé (pixels isolés trop clairs remplacés par la médiane locale) ;
  les feuillages reçoivent des grappes de feuilles peintes (arc éclairé, creux sombre) au lieu de volumes lisses.
- **Tests** : 46 sur 46.

Restent dépendants d'assets dessinés : sprites directionnels d'Ilya, Throné et du garde à l'échelle d'exploration ;
feuillages et matières vraiment peints (le volume 3D reste perceptible dans les arbres).

## Itération 3 : fiabilisation et harmonisation
**Dialogue**
- `_open_dialog()` vérifie lui-même la distance (`can_talk`, 14 px natifs). Joueur, démo et tests passent tous
  par cette règle.
- La démo n'a plus de raccourci. Chaque étape doit être réellement atteinte : l'itinéraire contourne les
  obstacles (A* sur les mêmes collisions que le joueur), et une étape non atteinte arrête la démo en le
  signalant. Le dialogue s'est ouvert à 11 px du garde.
- Vérification par touches simulées (`--autoplay --check-talk`) : E à 223 px ne fait rien, E à 12,7 px ouvre le
  dialogue, Échap le ferme (`docs/media/exploration/verification_dialogue_touches.txt`).

**Occlusion**
- Blender rend maintenant aussi le **terrain seul** : les objets sont invisibles pour la caméra, mais leurs
  ombres restent au sol. `fond.png` ne contient plus aucun objet ; chaque objet est une couche séparée, avec
  la même palette.
- Transparence **locale et douce** : ellipse autour de chaque personnage réellement recouvert, avec une opacité
  minimale de 0,5. L'objet reste lisible devant lui.
- La silhouette de secours ne sert plus qu'au-delà de 3 personnages cachés derrière un même objet.
- Correction d'un défaut : le shader multipliait deux fois la texture, ce qui assombrissait les objets.

**Vorgane**
- Rendu original depuis son modèle Blender (`tools/explore/vorgane_explore.py`), sous la même projection que le
  décor (35°, 20°) et le même éclairage, avec une ombre portée réelle et un repos en 8 images.
- Il est tourné de trois-quarts vers la droite et mesure environ 1,5 fois la hauteur d'Aren (même rapport qu'en
  combat). Ses pieds sont calés sur le point au sol.
- Il est solide (on ne le traverse pas). Le combat se déclenche au contact de son emprise au sol, élargie de
  6 px.
- Conversion en pixel art : `tools/explore/vorgane_pixel.py`.

**Tests** : 49 sur 49, dont 3 nouveaux dans `test_explore.gd` : dialogue impossible de loin et possible de près,
contact avec le monstre à une distance visuelle cohérente, fond sans duplication de la maison.

**Limites restantes**
- Feuillages et matières : encore issus de volumes 3D retouchés ; ils doivent être illustrés (voir
  `SPEC_ASSETS_EXPLORATION.md`).
- Ilya, Throné et le garde : sprites provisoires, sans vues directionnelles. Ilya est proposée comme pilote, au
  format défini dans la spécification.
- Le Vorgane d'exploration n'a qu'une animation de repos (pas de marche ni de réaction).
- Quand un objet devant la maison (par exemple un arbre) devient transparent, la zone de la maison qu'il
  recouvrait apparaît vide (terrain), car la maison n'est dessinée que là où elle est visible dans le rendu.

## Itération 4 : locomotion (P0) — branche `exploration-hd2d-polish`
Diagnostic **mesuré** avant correction, avec un parcours clavier reproductible
(`scenes/explore_hd2d/locomotion_course.gd`) : de vraies touches simulées (le même chemin que le joueur, sans
autoplay), départs, arrêts, lignes droites, diagonales, virages, demi-tour, glissement contre la façade, tour
complet de la maison, relâchements de touches décalés. Le script mesure chaque image : orientation, image de pas,
distance réellement parcourue, espacement du groupe, positions interdites, ordre de profondeur.

Le code de déplacement du joueur et du suivi est **identique en v2 et en v3** (vérifié par `git diff`) : la
régression perçue dans la vidéo v3 vient surtout de la nouvelle démo A*, mais le parcours clavier révèle aussi
des défauts présents depuis la v1.

**Défauts confirmés et corrections**
| Défaut (v3) | Cause | Correction |
|---|---|---|
| Démo : 291 images de repos au milieu de la marche d'Aren, 53 orientations de moins de 0,15 s | un arrêt complet (et la remise à zéro des pas) à chaque cellule A* de 4 px | itinéraire A* simplifié en segments droits (visibilité directe, mêmes collisions) parcourus sans arrêt |
| Pas désynchronisés (compagnons : 0,67 image par 6 px) | images avancées selon 72 px/s théoriques, pas la distance | les pas avancent avec le déplacement réel de l'image (glissement, blocage, diagonales, vertical) |
| Compagnons : ~110 arrêts-relances par parcours, écart 14 à 47 px | cible = n-ième point de trace (espacement variable) + vitesse 1,05 + arrêt près du meneur | position à une distance fixe **le long de la trace** (20 px par rang) : même vitesse que le héros, arrêt à écart constant |
| Orientation parasite en lâchant deux touches à quelques images d'écart | orientation recalculée à chaque image | hystérésis (les diagonales restent de profil) + une orientation doit tenir 0,06 s ; arrêts de moins de 0,1 s ignorés |
| Accroché à l'angle arrière gauche de la maison (à 30 i/s, flèche « haut » seule) | un axe nul « réussissait » sur place dans le glissement | axe nul ignoré, puis pas tourné de ±45°/±60° pour longer un angle |
| Personnage contre la façade dessiné derrière la maison (43 images), qui devient alors translucide | tri sur une seule ligne horizontale (y maximal de l'emprise) alors que la façade est en biais | tri sur le bord avant réel de l'emprise à l'abscisse du personnage |
| Au retour de combat, compagnons placés à −18 px sans vérification | position non testée | file placée sur des positions libres et trace amorcée |

**Mesures (parcours clavier, 60 i/s ; détails dans `docs/media/exploration/locomotion/mesures_*.json`)**
| | v3 | corrigé |
|---|---|---|
| Images de repos en pleine marche (Aren / Ilya / Throné) | 0 / 110 / 100 | 0 / 0 / 0 |
| Arrêts d'un compagnon pendant que le héros marche | 115 / 102 | 0 / 0 |
| Pas / distance (1,00 = synchronisé) | 1,08 / 0,67 / 0,70 | 0,98 / 0,98 / 0,98 |
| Écart Aren–Ilya en marche : moyenne, écart-type | 24,7 px, 5,4 | 18,6 px, 2,9 |
| Images mal triées en profondeur (Aren) | 43 | 0 |
| Étapes du parcours non atteintes à 30 i/s | 6 (accroché à l'angle) | 0 |
| Démo : images de repos parasites / orientations brèves (Aren) | 291 / 53 | 0 / 0 |

Résultats identiques à 30, 60 et 144 i/s. L'occlusion (transparence locale) n'est pas modifiée, conformément à
la décision du 6 novembre ; seul l'ordre « devant / derrière » est corrigé.

**Vidéos** (`docs/media/exploration/locomotion/`) : `locomotion_manuel_clavier.mp4` (touches affichées),
`comparatif_manuel_v3_corrige.mp4` et `comparatif_demo_v3_corrige.mp4` (côte à côte, même parcours),
`demo_auto_corrigee.mp4` (démo, dialogue, contact, combat). Reproduction : `tools/explore/record_locomotion.sh`.

**Défauts restants**
- Demi-tour : le héros repasse à travers ses compagnons pendant 3 à 5 images (comportement classique d'une file
  qui suit la trace ; il n'y a pas de collisions entre membres du groupe).
- Ilya et Throné n'ont qu'un profil (retourné) : en marche verticale, ils gardent leur dernier profil.
- Quatre orientations seulement pour Aren : les diagonales sont jouées de profil.
- « Sur le toit » derrière la maison : ce n'est pas une erreur de position (les pieds sont au sol, derrière le mur,
  et le tri est correct) ; c'est l'effet de la transparence locale, qui montre le personnage à travers le toit.
  Il est conservé tel quel (décision du 6 novembre).
- Un personnage qui traverse le buisson au pied de l'angle gauche de la maison peut passer devant le feuillage
  pendant une image : la maison et le buisson ne peuvent pas être ordonnés autrement avec un seul niveau par objet.

## Itération 5 : interaction avec le garde (P0) — branche `interaction-pnj-art`
**Reproduction** au clavier (`--course=pnj` : on marche vers le garde depuis la gauche, la droite, le bas et
en diagonale, on s'arrête quand les deux personnages se touchent, puis E) : **4 approches sur 9** réussissaient.

**Deux causes**
1. **Sprite décalé** (bug) : `Walker._anim()` sortait avant de caler les pieds du sprite quand l'animation
   demandée était déjà celle par défaut. Le garde, qui ne marche jamais, était dessiné **25 px plus bas et 7 px
   plus à droite** que sa position réelle (collision, dialogue). Le joueur visait le dessin : il fallait se placer
   « derrière » lui. Le même décalage touchait chaque personnage jusqu'à son premier pas.
2. **Zone trop étroite** : un cercle de 14 px refuse un personnage arrêté juste à côté (15 à 17 px entre les deux
   pieds).

**Correction** : pieds toujours calés ; zone de dialogue **elliptique 22 × 16 px natifs** (≈ 1,1 m sur les côtés,
plus courte en profondeur à cause de la perspective) **et** ligne de vue au sol (aucun bâtiment, clôture ou
objet entre le héros et le PNJ). L'invite « E  Parler », la touche E, la démo et les tests utilisent la même
règle (`can_talk_now()`). À plus de 34 px, aucune invite ; entre les deux, une bulle « … ».

**Résultat** : 9 sur 9 (gauche, droite, bas, deux diagonales, en longeant le mur, contre lui ; refus à 32 px et
derrière la maison). Carte vérifiée : aucune case accessible de l'ellipse n'est masquée par un obstacle.
Démonstration : `docs/media/exploration/pnj/approches_pnj_clavier.mp4`, `approches_pnj.jpg`, résultats JSON.
Tests ajoutés : approches naturelles, refus à travers un obstacle, pieds calés dès l'apparition.

Autre correction : avec F5 sur la zone, `--start=hd2d-zone` chargeait la scène deux fois.
