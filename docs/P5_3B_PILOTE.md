# P5.3-B — pilote d'intégration des textures de sol peintes (21/11/2026)

Branche `p5-3b-pilote-sols` (depuis `p5-3-sols`). **P5.3 validé par le créateur comme fin de l'étape A (21/11/2026)** ;
l'étape A n'est plus retouchée (shader `sol_foret.gdshader` inchangé, touche U). Pack reçu :
`ValSerra_P53B_Pilote_Sols.zip` (statut : pilote, hauteurs PROVISOIRES). Médias : `docs/media/p5_3b/`.
Rendu des captures : Vulkan logiciel (lavapipe), F5 24°, ×3 sauf mention.

## 1. Ce qui est intégré

| Matière du pilote | Fichier du pack | Fichier intégré |
|---|---|---|
| herbe drue | SOL-01 herbe dense | `art/p53/sol/herbe_drue.png` |
| herbe usée | SOL-02 herbe clairsemée | `art/p53/sol/herbe_usee.png` |
| terre de chemin | SOL-03 chemin / terre tassée | `art/p53/sol/terre_chemin.png` |

SOL-04 (roche) et TRS-01 (transitions) ne font pas partie du pilote : non intégrés.

**Adaptation de format seulement** (`tools/p5/pack_sols_p53b.py`) : couleur RGB + hauteur L → un PNG RGBA (A = hauteur),
comme spécifié en § 6 de `docs/P5_3_SOLS.md` ; aucune retouche de couleur, d'échelle ni de dessin. Import Godot :
sans perte, mipmaps, « Fix Alpha Border » et « Premult Alpha » désactivés. Échelle : 1024 px = 4 m (256 px/m).

## 2. Comment c'est branché (`src/explore25/sol_foret_p53b.gdshader`)

- Copie du shader P5.3 ; seules l'herbe et la terre de chemin sont remplacées, **dans une zone pilote** de 8 m de rayon
  autour de (−10 ; 1) (départ, croisement ouest, chemin, herbe, pieds d'arbres et de rochers), fondu de 1,5 m.
  Pentes, ruisseau, pieds d'objets et reste de la carte : P5.3 inchangé.
- **Mélange par hauteur** entre les trois matières, pondéré par les masques P5.3 (chemin, bande d'usure, usure de l'herbe).
- **Anti-répétition** : second échantillon décalé, à 0,83 de l'échelle, choisi par hauteur selon un bruit large. Pas de
  rotation, car la peinture contient du volume éclairé.
- **Couleurs** : décodées en linéaire et **étalonnées par mesure** : couleur unie = moyenne peinte de la terre, sol plat
  au soleil. Gain 0,30 → affiché (143, 74, 42) ; gain 0,40 → (160, 82, 47) ; retenu 0,22 pour la luminosité peinte.
  La teinte reste réchauffée par le soleil orangé de la scène, comme tout le reste.
- **F5** démarre sur le pilote. **U** : pilote → P5.3 (étape A) → P5.2 → V07. **Y** : textures sur toute la carte (test
  de répétition) / zone pilote. J : qualité des ombres (inchangé).
- **Combat** : décor re-rendu avec les textures sur tout le cadre (`decor_foret.gd --pilote=carte`).

## 3. Réponse à la question du pilote

**Le pack fonctionne techniquement et apporte une vraie matière** : touffes et brins d'herbe, terre tassée, petits
cailloux, lisibles à ×2, ×2,5 et ×3, sans scintillement (mipmaps, anisotrope). Le saut de qualité par rapport aux aplats
P5.3 est net. **En revanche, les couleurs livrées ne tiennent pas encore dans le biome** : sur le même cadrage, la zone
pilote se détache nettement du reste de la forêt. C'est un problème de palette, pas de technique.

### Répétition
- Aux zooms de jeu (×2 à ×3), **pas de grille visible** sur l'herbe drue ni sur la terre, avec ou sans anti-répétition
  (`repetition_carte_entiere.jpg`).
- Défauts des fichiers, mesurés (`art/p53/sol/mesures_pack.json`) :
  - **bords assombris** : −7 % (herbe drue), −17 % (herbe usée), −21 % (terre) de luminosité sur les 64 px de bord par
    rapport au centre ; sur une grande étendue de terre, cela peut dessiner des bandes sombres tous les 4 m ;
  - **bords en miroir** : la colonne 0 est identique à la colonne 1023, et la colonne 1 à la 1022. Au raccord, la
    texture se reflète (motif « papillon ») et une colonne est doublée.
- **Herbe usée (SOL-02)** : îlots d'herbe de 1 à 2 m, reconnaissables ; sur le banc 3 × 3, sa répétition saute aux yeux.
  En jeu, elle n'occupe que la bande d'usure (étroite), donc peu visible aujourd'hui, mais elle le serait sur une grande
  zone usée.

### Transitions
- Le bord herbe / terre est net et découpé par les touffes, sans fondu flou ni contour : c'est le meilleur raccord
  obtenu jusqu'ici.
- Les **hauteurs provisoires** jouent peu : écart type 0,05 (herbe) et 0,03 (terre, presque plate) sur une échelle 0 à 1.
  Le shader les étire (×4) pour qu'elles comptent ; c'est donc surtout le masque qui dessine le bord.

### Compatibilité avec le shader
- Totale : aucune modification du système de sol, ni des collisions, ni du gameplay ; P5.3 reste disponible (U).
- Ombres, objets et pentes inchangés. Les pentes (P5.3, beige) jurent davantage à côté de matières peintes saturées :
  attendu, puisque SOL-04 n'est pas dans le pilote.

### Couleurs (le point principal)
Moyennes peintes contre palette actuelle de la forêt (sRGB) :

| Matière | Peinte | Palette forêt (P5.3) |
|---|---|---|
| herbe drue | (46, 84, 53) : vert bleuté, sombre | ≈ (85, 95, 50) : olive |
| herbe usée | (76, 76, 51) | ≈ (128, 116, 72) |
| terre de chemin | (117, 68, 51) : rouille | ≈ (140, 110, 74) : ocre |

À l'écran : chemin rouille, herbe vert froid très sombre à l'ombre. Le Vorgane (violet sombre) ressort moins sur l'herbe
sombre en combat.

**Essai de calage** (`essai_calage_couleur.jpg`, et 3e image de `combat_avant_apres.jpg`) : uniquement pour la
discussion, désactivé dans le pilote. La teinte moyenne de chaque matière est ramenée à la palette de la forêt, le détail
peint restant intact. Le rendu s'intègre alors au biome et garde toute la matière.

## 4. Ajustements recommandés sur les textures (avant le pack complet)

1. **Palette** : rapprocher les moyennes de la palette de la forêt (tableau ci-dessus), soit en repeignant, soit en
   validant le calage par le shader (plus rapide, réversible). **À vous de choisir.**
2. **Bords** : supprimer l'assombrissement des bords et le miroir. Il faut un vrai raccord périodique (décalage de la
   moitié de la tuile puis retouche des coutures), pas un fondu vers les bords.
3. **Herbe usée** : îlots plus petits et plus nombreux (au plus 30 à 50 cm), sans forme reconnaissable.
4. **Hauteurs** : utiliser toute l'échelle. Herbe : sommets des touffes vers 0,7–1,0, creux vers 0,2–0,4. Terre :
   0,2–0,5, cailloux plus hauts. Que l'herbe soit en moyenne plus haute que la terre : c'est ce qui fait déborder les
   touffes sur le chemin.

## 5. Tests réellement exécutés (Godot 4.7.2)

- `tests/p53b_pilote_smoke.gd` (nouveau) : 14 / 14 — trois textures 1024 × 1024 avec mipmaps et canal A, import sans
  perte et alpha non retouché, pilote actif au démarrage, matières branchées, zone limitée (8 m), couleurs telles que
  peintes, touche Y aller-retour, collisions inchangées, déplacement inchangé dans la zone (3,19 m en 1,5 s) ;
- `tests/p52_sol_smoke.gd` : 16 / 16 (P5.3, P5.2, V07 toujours accessibles par U) ;
- `run_tests` 71 / 71 ; avant-poste de bout en bout 25 vérifications sans échec ; `p4` 29 / 29 ; `p4_sondes` 20 / 20 ;
- V09A, V09B.5, V09C, V11, P5 (combat) : 0 échec ;
- forêt : parcours principal 8 / 9, boucles 6 / 7, course 8 / 9, aucune chute (identique) ; arbres 11 / 11 ;
  occlusion 12 / 12 ; F5 sans erreur.

## 6. Médias (`docs/media/p5_3b/`)

`exploration_avant_apres.jpg` (5 vues, cadrage identique), `vues_rapprochees_avant_apres.jpg` (1:1),
`pilote_trois_zooms.jpg`, `repetition_carte_entiere.jpg` (avec et sans anti-répétition), `essai_calage_couleur.jpg`,
`combat_avant_apres.jpg` (P5.3 / pilote / essai de calage), `pilote_deplacement.mp4` (même trajet, côte à côte).

## 7. Suite proposée

1. Votre décision sur la **palette** (repeindre ou caler par le shader) et les retouches des bords, de l'herbe usée
   et des hauteurs (§ 4).
2. Puis, comme prévu : roche de pente, litière, bordures, pieds d'objets, et une passe plus large.
