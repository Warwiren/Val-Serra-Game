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
