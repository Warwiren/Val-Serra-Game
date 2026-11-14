# P4.8 — Une marche plus naturelle pour Aren et Ilya en exploration (Godot 4.7.2)

Branche **`p4-8-marche`**, partie de `p4-7-corrections` (laissée intacte). Date : 14 novembre 2026.
Demande : « avoir une bonne animation de déplacement pour Aren et Ilya, plus naturelle, en exploration ; inspiration
des jeux HD-2D ». Combat, carte, caméra P30 : inchangés. **F5** lance toujours `scenes/p4/avant_poste.tscn`.

## Vidéos et comparaison

| Fichier | Ce qu'il montre |
|---|---|
| [`videos/avant_apres_marche_profil.mp4`](media/p4_8/videos/avant_apres_marche_profil.mp4) | même marche de profil, P4.7 à gauche, P4.8 à droite (en boucle) |
| [`videos/marche_course_x3.mp4`](media/p4_8/videos/marche_course_x3.mp4) | à ×3 : marche dans les 4 directions avec arrêts, puis course (Maj) |
| [`comparaisons/marche_profil_p47_p48.png`](media/p4_8/comparaisons/marche_profil_p47_p48.png) | images de marche de profil : 4 images P4.7, 8 images P4.8 |

## 1. Recherche : ce que font les jeux HD-2D

Les jeux HD-2D (Octopath Traveler I et II, Triangle Strategy, Live A Live, Dragon Quest III HD-2D) posent des sprites
en pixel art de style Super Nintendo dans des décors 3D, avec effets haute définition. Les entretiens publics parlent
du style, du coût et de la caméra, **pas du détail des cycles de marche** (nombre d'images, cadence) : la recherche
n'a trouvé aucune source fiable là-dessus, et les sites spécialisés en pixel art (Slynyrd) ne sont pas accessibles
depuis cet environnement. Les principes retenus viennent donc des guides d'animation de marche en pixel art, qui
s'accordent sur :

- **8 images par cycle** : contact, bas, passage, haut, puis la même chose sur l'autre jambe. Au-delà de 8, c'est
  un choix esthétique ;
- **rebond d'1 pixel** : le corps descend après le contact (pieds écartés) et remonte au passage ;
- les images de contact peuvent durer un peu plus que les autres ;
- le personnage doit garder **le même dessin** d'une image à l'autre : seuls les membres bougent.

Ce qu'on voit dans les jeux HD-2D, observé en jeu et non vérifié par une source : petits pas vifs, tête et buste
stables, léger rebond, pieds qui ne glissent pas, et une course distincte de la marche.

Sources : [Octopath Traveler (Wikipédia)](https://en.wikipedia.com/wiki/Octopath_Traveler) ·
[Unreal Engine, entretien Octopath Traveler II](https://www.unrealengine.com/en-US/developer-interviews/octopath-traveler-ii-builds-a-bigger-bolder-world-in-its-stunning-hd-2d-style) ·
[Unreal Engine, le style HD-2D d'Octopath Traveler](https://www.unrealengine.com/en-US/spotlights/octopath-traveler-s-hd-2d-art-style-and-story-make-for-a-jrpg-dream-come-true) ·
[Nintendo Life, producteurs de Triangle Strategy sur le HD-2D](https://www.nintendolife.com/news/2022/05/triangle-strategy-producers-talk-hd-2d-and-why-other-devs-havent-used-it) ·
[Pixelblog 50, cycle de marche humain (Slynyrd)](https://slynyrd.com/blog/2024/5/24/pixelblog-50-human-walk-cycle) ·
[Pixelblog 55, animation de personnage vu de dessus (Slynyrd)](https://www.slynyrd.com/blog/2025/3/24/pixelblog-55-top-down-character-animation) ·
[Adobe, cycle de marche](https://www.adobe.com/creativecloud/animation/discover/animation-walk-cycle) ·
[Pluralsight, 12 étapes d'un cycle de marche](https://www.pluralsight.com/blog/tutorials/12-steps-walk-cycle-animation) ·
[PixelJoint, forum sur les cycles de marche](https://pixeljoint.com/forum/printer_friendly_posts.asp?TID=12824).

## 2. Diagnostic de la marche P4.7

| Constat | Mesure | Effet à l'écran |
|---|---|---|
| Les 4 images du pack P4.3 (illustrations générées) redessinent armure, mains et cape à chaque pas | **60 à 82 %** des pixels du buste (couleur ou forme) diffèrent d'une image à l'autre ; **0 %** en P4.8 | le personnage **bouillonne** au lieu de marcher |
| 4 images seulement, sans position basse ni haute | — | le corps glisse, sans poids |
| Vitesse 3,6 m/s pour un personnage de 1,26–1,30 m | 2,8 hauteurs de corps par seconde | une **course** |
| Pas dessiné : 24 px = **0,48 m** ; cadence 0,42 m par image | le corps avançait **1,75 fois plus vite** que les pas (il aurait fallu 7,5 pas/s, le jeu en faisait 4,3) | les **pieds glissent** |

## 3. Ce qui change

**Sprites** (`tools/p45/build_p45.py`, `walk_cycle8`), pour Aren et Ilya, dans les 4 directions :
- **haut du corps stabilisé** : tête, buste, bras et haut de la cape viennent d'une seule image du pack, celle qui
  ressemble le plus aux autres. Seuls les jambes et le bas de la cape changent : le bouillonnement disparaît ;
- **8 images** : chaque image du pack donne son contact ou son passage, puis une image où le corps descend d'1 px
  (après un contact) ou remonte d'1 px (après un passage) ;
- le pas dessiné est mesuré sur les profils et enregistré dans `marche.json` (24 px pour l'un et l'autre).

**Moteur** (`src/explore25/actor25.gd`) : la cadence est calculée à partir du pas dessiné (0,12 m par image, deux pas
par cycle) et avance avec la distance réellement parcourue. Les **pieds restent posés** à toutes les vitesses de
marche ; le garde garde sa marche à 4 images.

**Vitesse** (`data/p4/avant_poste.json`) : la marche passe à **2,2 m/s**, soit 4,6 petits pas par seconde, pieds
posés. La **course** sur **Maj** reprend les 3,6 m/s de P4.7. Au-delà de 2,4 m/s, la cadence ne croît plus qu'en
racine de la vitesse (6,1 pas/s en course au lieu de 7,5), avec un léger glissement, moins visible en course. Ilya
suit au même rythme. Pour revenir à l'ancienne vitesse, il suffit de modifier `vitesse_m_s` dans les données.

## 4. Limites

| Élément | Raison | Pour aller plus loin |
|---|---|---|
| Jambes et bas de cape | ce sont toujours les 4 images du pack P4.3 (pose « coup de pied arrière » de course en profil, cape relevée) | un cycle **dessiné** à 8 images par direction |
| Bras | stabilisés avec le buste : le balancement des bras du pack disparaît | bras dessinés dans le cycle |
| Positions basse et haute | **procédurales** (décalage d'1 px), pas dessinées | — |
| Course | mêmes images que la marche, cadence plus rapide | cycle de course dessiné (buste penché) |
| Vitesse de marche | 2,2 m/s : traverser la carte prend environ 60 % de temps en plus qu'en P4.7 (Maj pour aller vite) | à régler en main par le créateur |

Pour un cycle dessiné, voici le cahier des charges à transmettre : 8 images par direction (contact, bas, passage, haut
× 2), 4 directions, pieds sur une même ligne, tête au même endroit à ±1 px, même dessin du buste d'une image à l'autre,
pas d'environ 0,4 fois la hauteur du personnage, cape qui suit le mouvement avec un temps de retard.

## 5. Tests (Godot 4.7.2)

| Vérification | Résultat |
|---|---|
| Import, chargement de F5 (`--quit-after 60`) | 0 erreur |
| Tests automatiques | **71/71** (3 nouveaux : `test_p48_marche.gd` ; test P4 sur la vitesse mis à jour : course 3,6 m/s conservée) |
| Rencontre de bout en bout | **réussie** |
| Parcours `p4` et sondes `p4_sondes`, P30 et B28 | **29/29** et **20/20** chacun |
| En mouvement | vidéos ci-dessus (rendu OpenGL logiciel) ; nouveau parcours de démonstration `p4_marche` |

Non vérifié : confort en main par une personne (vitesse de marche notamment), Forward+ sur carte graphique.

## 6. Fichiers

**Modifiés** : `tools/p45/build_p45.py`, `art/p45/chars/{aren,ilya}/` (marche à 8 images, `marche.json`),
`src/explore25/actor25.gd` (cadence et course), `src/explore25/world25.gd` (vitesse de course),
`scenes/explore25/explore_3d.gd` (Maj), `src/explore25/session25.gd` et `routes25.gd` (course dans les parcours,
parcours `p4_marche`), `scenes/p4/avant_poste.gd`, `data/p4/avant_poste.json`, tests, README, CLAUDE.md,
`art/p45/SOURCES.md`, `docs/HISTORIQUE.md`.
**Ajoutés** : `tests/unit/test_p48_marche.gd`, ce rapport, `docs/media/p4_8/`.
**Retirés** (historique Git, branche `p4-7-corrections`) : rapport et médias P4.7. La capture de la cour, celle de la
plaine et l'écran de combat sont déplacés dans `docs/media/p4_8/`.

## 7. Lancer

Branche `p4-8-marche` → Code → Download ZIP (dossier `Val-Serra-Game-p4-8-marche`) → importer dans Godot 4.7.2 →
**F5**. Flèches ou ZQSD pour marcher, **Maj** maintenue pour courir.
