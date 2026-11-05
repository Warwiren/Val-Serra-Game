# Correctifs du prototype recentré et refonte du HUD de combat — compte rendu

Brief : « Val'Serra — Brief unifié, correctifs et HUD », version 1.1 du 5 novembre 2026.
Branche de travail : **`correctifs-hud`**, issue de `recentrage`. Elle **n'est pas fusionnée** : `main` est intact.

Vidéo de 34 s (contact et transition, annonce, garde, préparation, attaque, ruptures, HUD, victoire, retour) :
`docs/media/correctifs/correctifs_hud_demo.mp4`. Toutes les preuves sont dans `docs/media/correctifs/`.

---

## 1. Diagnostic, réalisé avant toute modification (§ 7.1)

### 1.1 Clignotement du Vorgane avant ses attaques (P0, § 2.1)
**Méthode.** J'ai écrit une scène de développement, `scenes/dev/vorgane_diag.tscn`. Elle rejoue 3 préparations du
Souffle annoncé, puis 3 coups de griffe, filmés à 30 images/s. Pour chaque image, je mesure la luminosité moyenne de
la zone du monstre et la part de pixels quasi blancs (`p0_mesure_avant.txt`).

**Mesure avant.** Pendant chaque préparation du Souffle, la luminosité oscille entre 105 et 166 (référence au repos :
105), et jusqu'à **46 % de la silhouette devient quasi blanche**, environ 1,4 fois par seconde. Les coups de griffe
ordinaires ne clignotent pas.

**Cause.** Une lueur additive posée sur la glande : un halo de 160 px, agrandi ×2,6 pendant l'annonce, à une opacité
qui oscillait jusqu'à 0,95 (`sin(t × 9)`). Ce halo couvrait la moitié avant du corps. Sans annonce, il restait
présent à 0,45 d'opacité, ce qui pâlissait aussi le monstre en permanence. Ce n'était ni l'AnimationPlayer, ni
l'ordre des événements du CombatCore, ni une double exécution. S'y ajoutaient des flashs d'impact et de rupture sur
**tout** le corps (0,8 et 1,0 de blanc), qui délavaient la silhouette au moment des ruptures.

**Correction** (`src/presentation/sprite_monster_view.gd`, `part_state.gdshader`) :
- l'anticipation devient identifiable : la pose de préparation est tenue et la **glande se charge** (émission cyan sur
  ses seuls pixels, montée progressive, pulsation lente) ; la frise affiche l'attaque annoncée et son délai réel ;
- la lueur est limitée à la glande (60 px) ;
- le flash d'impact est bref (0,12 s) et ne frappe que la **partie touchée** ; le corps n'en reçoit qu'un reflet (20 %).

**Mesure après** (`p0_mesure_apres.txt`, `p0_flash_avant_apres.png`) : pendant les 3 préparations, la luminosité
monte doucement de 77 à 90 au maximum, et la part de pixels blancs passe de 46 % à 3,5 % au plus. Le monstre reste
opaque et lisible.

### 1.2 Pâleur et manque de netteté du Vorgane (P0, § 2.2)
| Capture | Résultat |
|---|---|
| A — sprite brut, taille native (calques recomposés) | lavande pâle, peu de contraste interne, cristaux peu distincts du corps |
| B — Godot sans décor, lumière ni shader (`vorgane_diag.tscn -- --neutral`) | identique à A ×3 loin de la glande (écart moyen 8/255) |
| C — import et filtrage | pas de mipmaps, pas de compression avec perte, filtrage au plus proche, ×3 entier, positions au pixel entier : **aucune perte** |
| D — scène complète | la moitié avant est blanchie par le halo de la glande (écart signé +42/255, `p0_diag_brut_godot_ecart.png`) |

**Conclusion.** Il y a deux causes : le halo additif (corrigé, voir 1.1) et les **valeurs de la source elle-même**
(rendu 3D clair et peu contrasté, éloigné de la référence du pack). Le GLB n'a pas été refait. J'ai ajouté un
**étalonnage par calque** (`tools/art/vorgane_grade.py`, résultat dans `art/proto/vorgane_nuit/`, originaux
conservés) : corps sombre brun-violet, cristaux violet-magenta saturés, griffes ivoire, glande cyan. Les bornes sont
calculées sur toutes les images, donc pas de scintillement d'une image à l'autre. J'ai aussi ajouté une ombre de
contact pleine, sans flou. Comparaison avec la référence : `p0_etalonnage_vorgane.png`.

### 1.3 Encombrement du HUD
Capture de départ : `hud_avant.jpg`. Les étiquettes de parties sont permanentes et chevauchent le monstre, les
panneaux sont posés de façon ad hoc, et les couleurs sont dispersées dans le code.

---

## 2. Ce qui a été corrigé ou ajouté

| § du brief | Réalisation |
|---|---|
| 2.1 clignotement | Corrigé et mesuré (voir 1.1). |
| 2.2 netteté et intégration | Étalonnage, ombre de contact, suppression du halo (voir 1.2). |
| 2.3 cohérence des sprites | Les 4 humains viennent de la même passe du pack (même grille, même palette). Capture sans interface : `p0_coherence_sans_ui.png` (option `--no-hud`). Les silhouettes vectorielles ne sont plus dans le parcours normal. |
| 3.1 animation réelle d'Aren | **7 poses pixel art** sur un canevas commun de 64×42 avec ancrage aux pieds : repos armé (2 images de respiration), préparation, frappe, impact (suivi), garde, touché. Longueur d'épée constante (16 px natifs). Script : `tools/art/aren_poses.py`. Enchaînement : préparation → pas → frappe → impact → retour. L'effet est posé **sur la cible**, sur la couche d'effets. Preuves : `p1_aren_poses_natif.png`, `p1_aren_poses_sequence.png`. |
| 3.2 placement | Monstre à gauche, Chasseurs à droite sur trois profondeurs, ombres de contact, tri par profondeur. Le pas d'attaque est limité à 42 px pour tous : **aucune frappe ne traverse un compagnon**. |
| 3.3 scène et PNJ | La même clairière sert à l'exploration et au combat ; le garde n'apparaît pas pendant le combat. La **répétition près de la porte et de la fenêtre** est corrigée : les planches de la porte sont prolongées, sans motif répété. Retouche intégrée à `tools/art/pack_zone.py` et vérifiée identique au pixel près. |
| 4.1 identité | « Val'Serra », séparateur doré, COMBAT, nom de la zone. |
| 4.2 frise d'initiative | Séquence **ordonnée par le planificateur du moteur**, à espacement fixe, donc sans collision possible. Délais réels (« +24 ») et non des « tours ». Acteur actif en grand avec liseré or. Attaque annoncée en rouge avec libellé, votre effet en or. Au-delà de la largeur disponible : pastille « +N ». |
| 4.3 Chasseurs | 3 cartes de même taille : portrait, icône de rôle, nom, arme, PV, **Résonance** (ressource réelle du moteur, repère au coût de la compétence ; aucune barre SP inventée), états Garde et K.O. Carte active à contour or. |
| 4.4 et 4.5 ciblage | Repères discrets (petits anneaux d'intégrité). La partie visée ou survolée a une étiquette **nom + intégrité + faiblesse**, reliée par un trait fin et placée **au-dessus** de la silhouette pour ne masquer ni cristaux, ni pattes, ni tête. Les parties brisées sont marquées. |
| 4.6 PV du Vorgane | Barre ancrée en bas au centre : nom, PV, jauge, et seulement les statuts **réellement actifs** (attaque annoncée et son délai, parties brisées). |
| 4.7 menu des actions | Vertical, en bas à gauche : Attaque, Technique d'arme, Garde, Potion ×n, Pulsation d'Aether. La compétence n'est plus masquée : elle est **grisée** tant que la Résonance manque, et la raison donnée par le moteur s'affiche. |
| 4.8 description et cartes | Nom et description de l'action, cible, faiblesse. Les cartes VIF / MESURÉ / CHARGÉ n'apparaissent que pour les actions compatibles, avec délai réel, dégâts « ≈ » et rupture issus de `battle.estimate`, et la mention avant/après le Souffle. Bouton **Confirmer** (Entrée). |
| 4.9 journal | Retiré du HUD normal ; outil de développement (touche L). Plus aucun bandeau d'instructions permanent. |
| 4.10 et 5 charte | `src/presentation/ui_style.gd` est la **source unique** de la palette de l'annexe B, des polices (Inter, Caladea : licences OFL fournies dans `art/fonts/`), des tailles (16 / 13 / 12 px) et du thème Godot. Un test vérifie qu'aucune couleur n'est codée en dur dans le HUD. |

**Non modifié** : formules, cadence, défenses, ciblage, ressources et IA du CombatCore. Une seule chose a été ajoutée
pour la démo automatique : le premier Chasseur qui joue pendant une attaque annoncée se met en garde, afin de montrer
le scénario de protection dans la vidéo. Cela ne s'applique pas en jeu manuel.

**P2 (sons, finitions)** : non commencé, conformément au § 9 (en attente de votre validation de P0 et P1).

---

## 3. Tests et scénarios

**Tests automatiques : 40 tests, 40 réussis, 0 échec** (relancés sur cette branche). Ce sont les 37 précédents et
3 nouveaux :
- `test_aren_combat_poses_share_canvas` : 7 poses, canevas commun ;
- `test_graded_vorgane_matches_original_layout` : le Vorgane étalonné a les mêmes cadrages que l'original ;
- `test_combat_ui_colors_are_centralized` : aucune couleur codée en dur dans le HUD.

Ces tests ne prouvent pas l'absence de défaut artistique.

| Scénario (§ 8) | Couvert ? | Preuve |
|---|---|---|
| (a) VIF / CHARGÉ déplacent l'exécution réelle | oui | test `test_modes_change_effect_time_not_next_decision` ; délais différents sur les cartes |
| (b) attaque annoncée du Vorgane | oui, en jeu | journal t=327 « ANNONCE Souffle d'Aether » ; `apres_combat_annonce_garde.jpg` |
| (c) protection par la garde | oui, en jeu | journal t=360 « Throné se met en garde » ; pose de garde d'Aren dans `aren_diag` |
| (d) frappe sur une partie faible | oui | « ▲ Faible : perforant ×1.3 » sur les cartes et l'étiquette |
| (e) rupture de la griffe | oui, en jeu | journal t=383 |
| (f) rupture de la carapace | oui, en jeu | journal t=492 |
| (g) soin | oui, en jeu | journal t=285 « récupère 60 PV » |
| (h) baisse des PV et de la Résonance | oui, en jeu | Pulsation d'Aether utilisée deux fois (coût de 30 Résonance) ; dégâts reçus |
| (i) victoire et retour à la zone | oui, en jeu | journal t=826 ; `apres_victoire.jpg`, `apres_retour_zone.jpg` |
| (j) défaite | **non couvert visuellement** | seulement par le test moteur `test_defeat_is_reachable` |
| (k) 1280×720 et 1920×1080 | oui | `hud_apres_1280.jpg`, `hud_apres_1920.jpg` : même disposition, aucun texte tronqué |

## 4. Lancer et vérifier
- Jeu : **F5** dans Godot (avant-poste → garde → Vorgane → combat).
- Combat direct : `godot --path . -- --start=proto-battle`
- Diagnostic du Vorgane : ouvrir `scenes/dev/vorgane_diag.tscn` et appuyer sur **F6** (ajouter `-- --neutral` en ligne de commande pour la capture B).
- Diagnostic des poses d'Aren : `scenes/dev/aren_diag.tscn`, puis **F6**.
- Capture de cohérence sans interface : `godot --path . -- --start=proto-battle --no-hud`
- Tests : ouvrir `tests/test_runner.tscn`, puis **F6**.

## 5. Limites restantes
1. **Seul Aren** a de vraies poses. Ilya et Throné font un pas court avec effet, mais n'ont pas de poses propres.
   C'est conforme au § 3.1, qui demande d'abord une attaque d'Aren convaincante.
2. Les poses d'Aren sont **dérivées par script** du sprite du pack (bras redessiné, épée tracée) : elles sont propres
   et lisibles, mais une passe de retouche à la main améliorerait le bras et le mouvement de la frappe.
3. Le Vorgane reste un rendu 3D étalonné. Sa silhouette (fine, de type lézard) diffère de la référence du pack
   (trapue). L'écart est désormais de **forme**, plus de valeurs ni de netteté. Le corriger demanderait une
   recréation, qui est une décision majeure soumise à votre approbation.
4. Pendant l'exécution d'une action, la frise et les statuts montrent l'état figé au moment de la confirmation.
   L'acteur actif réapparaît au tour suivant.
5. Garde et défaite ne sont démontrées qu'en partie dans la vidéo (la défaite n'est pas montrée).
6. Les icônes du menu et des rôles sont de petites formes vectorielles provisoires.

## 6. Fichiers modifiés ou ajoutés
- **Code** : `scenes/battle/battle_scene.gd`, `scenes/proto/proto_zone.gd`, `src/presentation/{combat_hud,initiative_bar,ui_style}.gd` (nouveaux), `src/presentation/{monster_view,sprite_monster_view}.gd`, `src/presentation/part_state.gdshader`, `src/proto/pack_hunter_view.gd`, `tests/unit/test_sprites.gd`
- **Outils** : `tools/art/{vorgane_grade,aren_poses}.py` (nouveaux), `tools/art/pack_zone.py` (retouche de la porte), `scenes/dev/{vorgane_diag,aren_diag}.tscn` (développement)
- **Assets** : `art/proto/vorgane_nuit/**`, `art/proto/aren_combat/*`, `art/fonts/*` (nouveaux) ; `art/proto/zone_bg.png` (régénéré ; l'ancienne version reste dans l'historique git de `recentrage`)
