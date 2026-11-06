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
