# Décors de combat — pilote « Lisière de l'avant-poste » au crépuscule

Branche **`exploration-hd2d-polish`** (non fusionnée). Proposition à valider avant toute autre arène.
Lancement : `godot --path . -- --start=proto-battle --arena=lisiere` (ou une rencontre depuis la zone HD-2D avec
`--arena=lisiere`). **F2** bascule en direct entre le décor actuel et le pilote. Sans l'option, rien ne change.

## Ce qui est modifié — et ce qui ne l'est pas
- Présentation seulement : `src/presentation/arena_layers.gd` (plans, brume, lanternes, lucioles, parallaxe),
  trois points d'accroche dans `scenes/battle/battle_scene.gd` (construction, parallaxe, F2) et l'option
  `--arena=` dans `GameState`.
- **Inchangés** : CombatCore, initiative dynamique, Résonance, ciblage anatomique, parties destructibles, HUD,
  positions des combattants (`HUNTER_POS_PROTO`, `MONSTER_POS_PROTO`), sprites et Vorgane.

## Constat sur le décor actuel
`art/proto/zone_bg.png` est **une seule image** de 427×240 tirée du pack visuel (×3) : pas de plans, donc pas de
profondeur ; ambiance jaune-vert chaude, éloignée du crépuscule bleu-violet validé pour l'exploration ; lanternes
« peintes » dont la position est recopiée à la main (`PROTO_LIGHTS`) ; détail très dense derrière les combattants,
qui gêne leur lecture ; conditions d'usage liées au pack.

## Méthode (reproductible : `tools/arena/build_arena.sh`)
1. `tools/arena/arena_blender.py` : la scène est construite dans Blender avec **les mêmes matières et la même
   lumière** que l'exploration (lune froide en haut à gauche, contre-jour violet, lanternes chaudes), mais avec
   **une caméra de combat** : perspective 35 mm, vue latérale trois-quarts (8°), légère plongée calculée pour que
   la ligne de combat tombe exactement sous les pieds des combattants. Ce n'est pas la vue d'exploration recadrée.
2. Chaque **plan est rendu complet** (non découpé par les plans plus proches), avec les ombres de tous les objets
   sur le sol : base (ciel + sol, terre battue, chemin pavé, flaques), loin (forêt), lisière (grand arbre,
   rochers moussus, sous-bois, palissade, porte de l'avant-poste et maison de garde), avant (cadre bas sombre).
3. `tools/arena/arena_paint.py` : **même passe pixel que l'exploration** (étalonnage, grappes de feuilles,
   touffes d'herbe, fleurs, contour d'1 px) et **palette commune** : 48 couleurs tirées des assets de
   l'exploration + 8 teintes de ciel ; perspective atmosphérique sur le plan lointain.
4. Godot : affichage ×3 au plus proche voisin (même densité de pixels que les sprites), brume en bandes entre
   les plans, lanternes Godot posées sur les lanternes rendues (les mêmes positions éclairent le Vorgane),
   parallaxe légère quand la caméra tremble.

## Composition
- Espace central dégagé et sombre (terre battue) : Vorgane à gauche, Chasseurs à droite, lisibles en silhouette.
- Profondeur : sol → lisière → brume → forêt → ciel ; la porte et la maison chaudes à droite répondent à
  l'avant-poste de l'exploration.
- Le haut (initiative, panneaux du groupe) et le bas (actions) restent calmes : voir
  `docs/media/arena/guide_illustration.png` (zones du HUD, pieds des combattants, lanternes).

## Captures et vidéo (`docs/media/arena/`)
`avant_apres_arene.jpg` (même combat, même instant) · `pilote_lisiere_1280.jpg` · `combat_lisiere_pilote.mp4`
(30 s de combat automatique) · `apercu_natif.png` (432×244) · `guide_illustration.png`.

## Tests
3 tests (`tests/unit/test_arena.gd`) : plans de même taille couvrant l'écran, base opaque, lumières posées sur
les lanternes peintes, palette limitée. 58 sur 58.

## Avis critique et limites
- **Gagné** : cohérence de palette et de lumière avec l'exploration, vraie profondeur, combattants plus lisibles,
  éclairage du Vorgane relié au décor, pipeline reproductible et aucun asset tiers.
- **Pas atteint** : la finition « illustrée » des références. Feuillages en boules, conifères géométriques,
  ciel uniforme : c'est la limite des volumes 3D retouchés par script, la même qu'en exploration.
- Lisibilité : le texte flottant bleu (« +8 Résonance ») se lit mal devant la maison éclairée ; à régler par un
  contour plus fort du texte ou une maison un peu moins lumineuse.
- Le Vorgane n'a pas d'ombre portée cohérente avec la lanterne gauche (ombre de contact seulement).
- **Recommandation** : garder ce rendu comme **sous-couche de composition et de lumière**, puis faire
  **repeindre chaque plan** par un illustrateur, au même format (432×244, RGBA, palette fournie) : l'intégration
  est alors automatique (on remplace les PNG), sans toucher au code ni aux ancrages.
