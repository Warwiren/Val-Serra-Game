# P5.3-B — V2 : correction ciblée des transitions herbe / terre (21/11/2026)

Branche `p5-3b-v2-transitions` (depuis `p5-3b-v2-sols`). Demande : dernière passe sur les **transitions** de la V2 (couleurs
olive / ocre conservées), à comparer à la V1 + calage (référence visuelle) et à la V2 actuelle. Textures V1 et V2
**inchangées** ; géométrie, collisions, déplacements, occlusion, combat : inchangés. Zone pilote seulement.
Médias : `docs/media/p5_3b_v2t/`. Rendu Vulkan logiciel, F5 24°, ×3 sauf mention.

## 1. Diagnostic : pourquoi la V2 se découpe en plaques

Le défaut vient du **shader et de la répartition des matières**, pas des textures :

1. **Hauteurs V2 sans relief interne** : les hauteurs V2 sont absolues et presque plates à l'intérieur d'une matière
   (écart type : herbe dense 0,031, terre 0,018). Avec le réglage V2 (étirement ×0,6), elles varient de ±0,02 seulement,
   bien moins que la profondeur de mélange (0,08). Le mélange « par hauteur » n'a donc rien pour découper le bord : il
   recopie le contour lisse du masque du chemin, décalé d'une constante (herbe 0,89 contre terre 0,28). D'où un trait
   continu. La V1, étirée ×4 autour de sa moyenne, a ±0,2 de relief : ses touffes découpent le bord.
2. **Bande trop étroite** : le masque du chemin vient de la carte V07 (64 px/m) et passe de 0 à 1 sur ≈ 40 cm. Toute
   bande définie sur ce masque reste étroite (vérifié par l'affichage des poids, outil `debug_poids`). De plus, la carte
   n'a pas de mipmaps exploitables pour élargir.
3. **Herbe usée sous-employée** : dans la V2, l'herbe usée n'occupe qu'un mince liseré ; or c'est la seule matière qui
   contient à la fois des touffes hautes et de la terre basse (hauteur bimodale 0,28–0,91). C'est elle qui peut faire la
   transition.

## 2. Ce qui a été modifié (shader `sol_foret_p53b.gdshader`, variante « V2 transitions » seulement)

Les autres variantes gardent exactement leurs réglages ; les nouveaux paramètres ont des valeurs par défaut neutres.

| Réglage | V2 actuelle | V2 transitions | Rôle |
|---|---|---|---|
| centre des hauteurs | 0,5 commun | moyenne de chaque matière (0,893 / 0,565 / 0,284) | chaque matière garde son relief propre |
| étirement des hauteurs | ×0,6 commun | herbe dense ×6, herbe usée ×1,3, terre ×8 | relief interne ≈ ±0,2 (comme la V1) : les touffes découpent le bord |
| priorité par matière | — | herbe usée +0,06, terre −0,02 | les touffes d'herbe usée passent au-dessus de la terre (débordement) |
| profondeur de mélange | 0,08 | 0,12 | fondu un peu plus doux entre touffes |
| largeur de transition | ≈ 40 cm (masque brut) | ≈ 0,8 à 1,6 m, variable | **proximité du chemin** : moyenne du masque sur deux anneaux de 8 lectures (0,8 m et 1,6 m) |
| répartition | herbe dense ↔ terre | herbe dense → **herbe usée** → terre | bande intermédiaire où la terre apparaît à travers l'herbe clairsemée |
| irrégularité | 2 échelles | 3 échelles modérées (≈ 9 m, 3 m, 1,3 m), rien de plus fin | bord irrégulier sans bruit |

- Transition **centrée sur le bord d'origine** du chemin ; le cœur du chemin reste en terre pleine (masque P5.3
  inchangé) : forme et largeur praticable conservées.
- Usure hors chemins (pentes, sous les arbres) : conservée telle quelle.
- Coût : 16 lectures de texture de plus par pixel dans la zone pilote.

## 3. Mesures sur les mêmes cadrages (`mesures_transitions.txt`, outil `tools/p5/mesure_transitions.py`)

Zone mixte : part de l'image où l'herbe et la terre se mêlent (plus haut = transition plus progressive). Frontière :
longueur de la limite herbe / terre (plus haut = bord moins rectiligne).

| Vue (×3) | V1 + calage | V2 actuelle | **V2 transitions** |
|---|---|---|---|
| chemin principal : zone mixte / frontière | 33,3 % / 80 | 23,1 % / 45 | **31,8 % / 62** |
| embranchement | 58,9 % / 189 | 39,5 % / 128 | **47,1 % / 135** |
| zone herbeuse | 41,8 % / 130 | 30,6 % / 93 | **39,8 % / 107** |
| pied d'arbre / bord | 39,6 % / 111 | 29,5 % / 77 | **34,2 % / 86** |
| pied de rocher | 39,9 % / 107 | 29,8 % / 75 | **34,4 % / 84** |

Note : les chiffres de la V1 + calage sont un peu gonflés par les points orange du calage, qui comptent comme de la
« terre » dans l'herbe.

**Lecture.** La V2 transitions est **nettement plus naturelle que la V2 actuelle** sur toutes les vues (zone mixte
+5 à +9 points, frontière +12 à +38 %). Elle **rejoint presque la V1 + calage** sur le chemin principal et les zones
herbeuses, mais **reste derrière elle aux embranchements** et sur les vues larges à ×2, où les chemins se lisent encore
comme des bandes plus nettes. À ×3 de près, la bande intermédiaire produit par endroits de petits îlots verts sur la
terre, plus « tachetés » que les touffes de la V1.

**Performances** (rendu logiciel, carte entière, qualité 4 ; `perf_4_variantes.txt`) : V2 transitions +4 à +9 % par
rapport à la V2 actuelle (anneaux de proximité), +8 à +23 % par rapport à P5.3. À confirmer sur GPU.

**Combat** (`combat_3_variantes.jpg`, `combat_sol_rapproche.jpg`) : bords du chemin nettement adoucis par rapport à la
V2 ; la remarque sur la lisibilité du Vorgane (sol V2 plus sombre) reste valable pour les deux V2.

## 4. Verdict honnête et choix

- Critère « visiblement plus naturelle que la V2 actuelle » : **atteint**.
- Critère « au moins aussi convaincante que la V1 + calage sur les transitions » : **presque, pas entièrement**
  (embranchements, vues larges).
- F5 démarre sur la **V2 transitions** pour que vous puissiez trancher en jeu ; **U** : V2 transitions → V2 actuelle →
  V1 + calage → V1 brute → P5.3 → P5.2 → V07 ; **Y** : carte entière. Le décor de combat forêt est en V2 transitions.
  Si votre revue confirme que la V1 + calage reste meilleure, la bascule est d'une ligne (démarrage F5 et décor de combat).

## 5. Assets qui permettraient de finir (si la V2 est retenue)

Le shader et les trois matières ont atteint leur limite sur ce point. Pour des transitions aussi organiques que la V1 :

1. **Carte de répartition des matériaux** (le plus efficace) : PNG 8 bits, **1152 × 896 px** (32 px/m sur la carte de
   36 × 28 m, alignée sur les UV du terrain : x de −18 à 18 m, z de −14 à 14 m), canaux : R = herbe dense, G = herbe
   usée, B = terre, peints à la main avec des bords irréguliers ; non répétable, sans transparence. Elle remplacerait
   le masque flou V07 pour la répartition, en gardant le mélange par hauteur pour le détail.
2. **Carte de hauteur de l'herbe usée V2 retravaillée** : 1024 × 1024, 8 bits niveaux de gris, répétable, même cadrage
   que `herbe_usee.png` ; touffes 0,7–1,0, terre 0,1–0,3, **transitions douces de 3 à 6 px** autour des touffes (les
   bords actuels sont presque binaires, ce qui donne les petits îlots nets).
3. (Optionnel) **Planche de touffes de bordure** : 2048 × 1024 RGBA, 12 à 16 touffes séparées, fond transparent, à poser
   le long des chemins.

Aucun de ces assets n'a été créé ; les textures V1 et V2 n'ont pas été modifiées.

## 6. Tests réellement exécutés (Godot 4.7.2)

- `tests/p53b_pilote_smoke.gd` : 22 / 22 (V2 transitions au démarrage, textures V2 d'origine, aucun calage, V2 actuelle
  sans bande intermédiaire, ordre de U sur 7 variantes, Y sur toutes, collisions et déplacement inchangés) ;
- `tests/p52_sol_smoke.gd` : 15 / 15 ;
- `run_tests` 71 / 71 ; avant-poste de bout en bout 25 vérifications sans échec ; `p4` 29 / 29 ; `p4_sondes` 20 / 20 ;
- V09A, V09B.5, V09C, V11, P5 (combat) : 0 échec ;
- forêt : parcours principal 8 / 9, boucles 6 / 7, course 8 / 9, aucune chute (identique) ; arbres 11 / 11 ;
  occlusion 12 / 12 ; F5 sans erreur.

## 7. Médias

`transitions_x3.jpg` (chemin principal, embranchement, zone herbeuse, pieds d'arbre et de rocher),
`transitions_rapprochees_x3_1-1.jpg`, `carte_entiere_et_pentes.jpg` (×2), `combat_3_variantes.jpg`,
`combat_sol_rapproche.jpg`, `deplacement_3_variantes.mp4`, `mesures_transitions.txt`, `perf_4_variantes.txt`.
