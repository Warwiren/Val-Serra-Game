# P4.5 — Garde en armure, animations d'exploration et de combat (Godot 4.7.2)

Branche **`p4-5-animations`**, partie de `p4-4-personnages` (`6efb1b5`, laissée intacte). Date : 13 novembre 2026.
Source nouvelle : pack léger du garde (`ValSerra_Garde_P44_integration_leger.zip`, Drive). Gameplay inchangé.

**Statut :** démo jouable de bout en bout, vérifiée automatiquement et **observée en mouvement** (vidéos ci-dessous).
**F5 la lance.** Rendu en OpenGL logiciel uniquement (pas de carte graphique ici).

## Vidéos (en mouvement)

| Vidéo | Ce qu'elle montre |
|---|---|
| [`exploration_marche_attente_gros_plan.mp4`](media/p4_5/videos/exploration_marche_attente_gros_plan.mp4) | Aren et Ilya à ×3 : marche à droite, à gauche, en haut, en bas, puis attente dans chaque direction |
| [`exploration_marche_attente_x3.mp4`](media/p4_5/videos/exploration_marche_attente_x3.mp4) | la même séquence, cadre entier |
| [`garde_ronde_attente.mp4`](media/p4_5/videos/garde_ronde_attente.mp4) | garde : ronde en 4 directions avec pauses d'attente, retour à son poste quand le héros approche, dialogue |
| [`combat_actions_aren_ilya.mp4`](media/p4_5/videos/combat_actions_aren_ilya.mp4) | vraie vue de combat : attente, tir, tir chargé, garde, touchée (Ilya) ; frappe, Résonance, garde, touché (Aren) ; K.O. d'Ilya |
| [`combat_ilya_gros_plan.mp4`](media/p4_5/videos/combat_ilya_gros_plan.mp4) | Ilya agrandie (au plus proche) : attente, dégainer, tir et recul, K.O. |
| [`parcours_complet_p4_5.mp4`](media/p4_5/videos/parcours_complet_p4_5.mp4) | partie complète : cour, garde, dialogue, bâtiment, pont, plaine, combat, victoire, retour |

## 1. Corrections effectuées

**Garde** — l'ancien garde au béret est retiré du projet (sprites et dossier). Le garde en armure (heaume, bouclier,
masse, tabard rouge) vient des 20 poses du pack : ombres peintes retirées, hauteur ramenée à 75 px pour toutes les
images (les poses du pack mesuraient de 244 à 280 px), pieds sur la même ligne, tête alignée. Il fait une **courte
ronde** (carré d'1 m autour de son poste : il marche dans les 4 directions), s'arrête 1,6 s à chaque coin en attente
animée, et **regagne son poste en se tournant vers le héros** dès que celui-ci approche à moins de 4 m (le
dialogue reste toujours possible ; le point de dialogue et la collision suivent le garde). Portrait du pack.

**Aren en combat — animations coupées** : la cause était la découpe du pack P4.2 en cellules fixes de 110 × 112 px :
l'arc de lame de l'attaque, l'épée levée du retour, la tête et les jambes de l'avance y étaient rognés (comparaison
`comparaisons/combat_personnages.png`). Aucun masquage côté moteur (`clip_contents`, régions, conteneurs : vérifié,
aucun). P4.5 **redécoupe la planche d'origine** : chaque pose est détectée entière (boîte élargie de 6 px), le bleu de
la cape est recoloré en gris comme P4.2, les étiquettes de la planche sont écartées ; dans les bandes de Résonance,
où les effets d'Aether débordent d'une cellule à l'autre, chaque nappe d'effet est rattachée au personnage le plus
proche au lieu d'être coupée à la limite de cellule. Canevas commun 200 × 112 : tous les sprites ont une marge,
pieds au même niveau (tests).

**Aren — jambes écartées** : l'écart des jambes dans l'avance, l'attaque et le retour **est dessiné ainsi dans la
planche d'origine** (posture de fente). Les poses « étranges » de P4.4 (jambes tassées dans l'avance) venaient du
rognage, désormais corrigé. Pour réduire l'écart lui-même, il faudrait redessiner ces poses : non fait (déformer le
sprite aurait cassé les proportions). **Défaut documenté.**

**Ilya en combat** :
- *attente* : 8 images (les 4 du pack + respiration et léger balancement du buste) au lieu de 4 quasi figées ;
- *tir* : dégainer → visée → tir (éclair et trait d'Aether) → **recul** (2 images : bras et pistolet reculent de 2 px
  puis 1 px, le buste suit) → retour ; l'image `fire_3` du pack (changement brusque de posture) reste écartée ;
- *K.O.* : chaque image reposée au sol (le pack faisait flotter le corps pendant la chute).

**Exploration — attente** : 8 images par direction pour les trois personnages (respiration, transfert du poids,
mèche ou haut de cape), dans la dernière direction regardée ; pieds immobiles.

**Exploration — marche** :
- images alignées sur la **tête** (et non plus sur les pieds ou le torse, que la cape et les bras faussaient) : la
  tête bouge de 2 px au plus d'une image à l'autre, contre 11 px chez Aren de profil ;
- cadence liée à la distance réellement parcourue (0,42 m par image, ~2 cycles/s à la vitesse de marche) : pas de
  glissement si le personnage ralentit ou bute ;
- transition attente → marche : le premier pas part immédiatement (jambe levée), l'attente repart de la pose neutre.

**Netteté** : sprites d'exploration à **1 pixel de sprite = 1 pixel d'écran à ×2,5** (Aren 70 px, Ilya 65, garde 75)
au lieu d'une réduction ×0,5 ; tailles à l'écran inchangées. Contour d'Ilya assombri. Aucun agrandissement
bilinéaire. Gain net à ×3 (visage d'Ilya lisible), modeste à ×2 et ×2,5 : la caméra P30 est en perspective, la taille
apparente varie légèrement avec la profondeur, donc un rééchantillonnage subsiste (`comparaisons/nettete_*`).

## 2. Encore provisoire

| Élément | Raison | Pour aller plus loin |
|---|---|---|
| Attentes (3 personnages, exploration ; Ilya en combat) | **procédurales** : décalages d'un pixel d'une même pose, pas un dessin | poses d'attente dessinées (2–4 images par direction) |
| Marche d'Aren et d'Ilya | images du pack P4.3, issues d'illustrations générées : la cape et les mains varient d'une image à l'autre | cycle dessiné image par image |
| Marche du garde | pack léger : le profil droit (image 2) est plus bas de 6 px dans la source, petit « tassement » visible | redessiner `right_2` |
| Jambes écartées d'Aren (avance, attaque, retour) | dessinées ainsi dans la planche | redessiner les poses de fente |
| Recul du tir d'Ilya | dérivé (bras et pistolet déplacés de 1–2 px) ; le pack ne redessine pas les bras | poses de tir articulées |
| K.O. d'Ilya | rotation rigide de la pose debout (pack) ; désormais au sol | vraie chute dessinée |
| K.O. d'Aren | absent de la planche (la pose « touché » sert de K.O.) | pose de K.O. |
| Garde | pas d'animation de combat (non demandée, PNJ) | — |

## 3. Tests (Godot 4.7.2)

| Vérification | Résultat |
|---|---|
| Import, chargement de F5 | 0 erreur |
| Références `res://` manquantes (tout le code et les données) | 0 |
| Tests automatiques | **63/63** (8 tests P4.5 ; la suite signale désormais un fichier de test illisible au lieu de l'ignorer) |
| Rencontre de bout en bout (`tests/e2e_p4_retour.gd`) | **réussie** : combat chargé, **475 PV** (données à 950), victoire, défaite, dialogue, bâtiment |
| Parcours complet `p4` — P30 / B28 | **29/29** chacun, dialogue avec le garde réussi ; 0 saut d'altitude ; 0 position hors surface |
| Sondes de collision `p4_sondes` — P30 / B28 | **20/20** chacun |
| Animations observées en mouvement | vidéos ci-dessus (exploration à ×3, garde, combat, partie complète) |

Non vérifié : Forward+, performances GPU, confort en main par une personne.

## 4. Fichiers

**Ajoutés** : `art/p45/` (personnages, combat, portraits, `SOURCES.md`), `tools/p45/` (`build_p45.py`,
`planche.py`), `tests/unit/test_p45_animations.gd`, ce rapport et `docs/media/p4_5/`.

**Modifiés** : `scenes/p4/avant_poste.gd` (sprites P4.5, ronde du garde), `src/explore25/actor25.gd` (attente animée,
cadence), `src/explore25/routes25.gd` (parcours de démonstration `p4_anim`, `p4_garde`), `src/proto/pack_hunter_view.gd`
(combat P4.5), `src/proto/portraits.gd`, tests, README, CLAUDE.md, `docs/HISTORIQUE.md`, `art/p41/SOURCES.md`.

**Retirés** (historique Git, branche `p4-4-personnages`) : `art/p44/` (remplacé par `art/p45/`), ancien garde
(`art/p41/chars/pnj/`, `art/proto/pnj*.png`), `tools/p44/`, test P4.4, rapport et médias P4.4.

## 5. Lancer

Branche `p4-5-animations` → Code → Download ZIP → importer dans Godot 4.7.2 → **F5** (démo P4.5, caméra P30).
Comparaison caméra : touche **C** ou scène F6 `scenes/p4/comparaison_camera_B28.tscn`.
