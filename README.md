# Val'Serra : Les Larmes d'Aether — démo jouable

Démo jouable du RPG narratif au tour par tour **Val'Serra**, réalisée sous **Godot 4.7.2**.

> Tous les personnages, monstres, illustrations et nombres de ce dépôt sont **provisoires et non canoniques**.
> Ce dépôt est indépendant du système Foundry du JDR (`Warwiren/Val-serra`), qui n'est pas modifié.

> Médias des étapes P4.9 à P5.3-B V2 : retirés du projet actif en P6 (`docs/P6_INVENTAIRE.md`), disponibles dans
> les branches d'origine (dernier état : `p5-3b-v3-hybride`).

## Ce qui est jouable

**F5 : la forêt stylisée V07B** (décision du créateur du 15/11/2026, étape P4.9 V08A) — terrain de 36 × 28 m,
modèles Quaternius stylisés, ruisseau, nouvelle direction HD-2D en cours d'essai :

1. **Exploration libre** avec **Aren** (cheveux bruns, armure et cape grises) et **Ilya** (cheveux courts argentés,
   cape verte, pistolet d'Aether) : chemins, clairières et butte se traversent hors des sentiers ; troncs, rochers,
   eau et vraies fortes pentes arrêtent les personnages (marche 2,2 m/s, course 3,6 m/s avec Maj, cycle de marche à
   8 images).
2. **Caméra P30** (perspective, azimut 20°, champ 30°) avec **trois inclinaisons à comparer** — 30°, 27°, 24° — et
   trois zooms.
3. **Occlusion dynamique** : un feuillage ou un buisson qui cache Aren ou Ilya s'efface en trame ; derrière un tronc
   ou un rocher, une silhouette discrète les montre.
4. **Diagnostic des collisions** (touche C) : obstacles, eau, bords et pentes du terrain.

C'est un **banc d'essai** (interface de test visible, pas de quête ni de combat). La **démo complète de l'avant-poste**
— exploration, dialogue avec le garde, combat au tour par tour contre le Vorgane (475 PV de démonstration), retour —
reste jouable en **F6** (`scenes/p4/avant_poste.tscn`, voir « Autres scènes »).


Étape en cours : **P4.9** — forêt V07B, inclinaisons et occlusion, navigation libre (V08A), locomotion V09A en essai
(comparaison V08 / V09A), **V09B.5 : nouvelles marche et course
d'Aren en comparaison** (touches B / T / P, vidéo comparative),
**V09B.6 : gabarit 64 px et plan de redessin pose par pose** (fiches et vidéo). Rapport
[`docs/P4_9_V07B.md`](docs/P4_9_V07B.md) ; vidéos : exploration libre,
inclinaisons et occlusion ;
comparatif 30° / 27° / 24°,
masque de collision avant / après.
Étapes précédentes : `docs/HISTORIQUE.md`.

## Lancer le jeu (Godot 4.7.2 obligatoire)

> **Version du moteur : Godot 4.7.2, et elle seule.** La ligne `config/features=PackedStringArray("4.5")` de
> `project.godot` est un reliquat historique, laissé tel quel volontairement.

1. Télécharger le projet (GitHub : choisir la branche **`p6-2-colisee-circulation-visibilite`**, puis **Code → Download ZIP** ;
   le dossier s'appelle `Val-Serra-Game-p6-2-colisee-circulation-visibilite`) et le décompresser.
2. Récupérer **Godot 4.7.2** (édition standard, pas « .NET ») : <https://godotengine.org/download/archive/4.7.2-stable/>.
3. Godot → **Importer** → choisir `project.godot` → **Importer et modifier** (une minute environ la première fois).
4. **F5** lance la **forêt V07B** (`ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn`), avec les
   corrections de navigation V08A et la locomotion V09A en essai (touche L pour revenir à V08). **Depuis le 19/11/2026,
   F5 démarre dans la configuration de validation** : Aren V09B.5 à 64 px, Ilya nouvelle apparence V09C.6, marche
   2,2 / course 3,6 m/s, inclinaison 24°, zoom ×3 (rien à activer ; P4.8 et les autres versions restent aux touches).
   **État validé le 20/11/2026** : profil droit (miroir vers la gauche) ; vers le bas / le haut, Aren marche de face /
   de dos (GIF dessinés, V4) et Ilya de face / de dos (pack V09C.5) ; rendu Sprite3D d'origine. **V11 (20/11/2026)** :
   **sans brouillard** au démarrage (touche F pour le revoir), **tous les rochers et les buissons hauts bloquent**, et
   le **Vorgane** se tient au sud du chemin principal (x ≈ 7,5), animé et solide, sans combat déclenché. La **démo de l'avant-poste** s'ouvre en **F6** depuis `scenes/p4/avant_poste.tscn`.
   **Branche `p5-combat` (refonte du combat, 20/11/2026)** : F5 est inchangé (forêt validée) ; le combat refondu
   s'ouvre en **F6** depuis `scenes/battle/combat_foret.tscn` (groupe à gauche, Vorgane à droite, décor forêt).
   **Branche `p5-2-environnement` (20/11/2026)** : F5 démarre avec le **nouveau sol** (matière, raccords chemin / herbe,
   pentes lisibles, pieds d'objets, horizon fermé ; touche **U** pour revoir le sol d'origine) ; le décor du combat
   forêt (F6) a le même sol, une clairière, de la profondeur et un premier plan. Rapport : `docs/P5_2_ENVIRONNEMENT.md`.
   **Branche `p5-3-sols` (21/11/2026)** : sol P5.3 (bordures sans contour, usure de l'herbe, pentes par paliers,
   pieds d'objets) et ombre du terrain rétablie, filtre des ombres en **qualité 4 à l'essai** ; **U** : P5.3 → P5.2 figé
   → V07 ; **J** : qualité 4 / 2. Rapport : `docs/P5_3_SOLS.md`.
   **Branche `p5-3b-pilote-sols` (21/11/2026)** : F5 démarre sur le **pilote des textures de sol peintes** (herbe drue,
   herbe usée, terre de chemin) dans une zone de 8 m autour du départ ; **Y** : textures sur toute la carte ; **U** :
   pilote → P5.3 → P5.2 → V07. Le combat forêt (F6) utilise les textures. Rapport : `docs/P5_3B_PILOTE.md`.
   **Branche `p5-3b-v2-sols` (21/11/2026)** : F5 démarre sur la **V2** des textures (couleurs recalées), retenue après
   comparaison ; **U** : V2 → V1 + calage → V1 brute → P5.3 → P5.2 → V07 ; combat forêt (F6) en V2. Rapport : `docs/P5_3B_V2.md`.
   **Branche `p5-3b-v2-transitions` (21/11/2026)** : F5 démarre sur la **V2 avec transitions corrigées** (bande
   d'herbe clairsemée, touffes débordantes) ; **U** : V2 transitions → V2 actuelle → V1 + calage → V1 → P5.3 → P5.2 →
   V07 ; combat forêt (F6) en V2 transitions. Rapport : `docs/P5_3B_V2_TRANSITIONS.md`.
   **Branche `p5-3b-v3-hybride` (21/11/2026)** : F5 démarre sur la **V3 hybride** (matières V2, forme des zones mixtes
   de la V1) ; **U** : V3 hybride → V2 transitions → V2 → V1 + calage → V1 → P5.3 → P5.2 → V07 ; combat forêt (F6) en
   V3 hybride. Rapport : `docs/P5_3B_V3_HYBRIDE.md`.
   **Branche `p6-colisee-ouverture` (21/11/2026)** : F5 est **inchangé** (forêt V07B, la promotion du Colisée sur
   F5 attend l'accord du créateur). **L'ouverture du jeu se lance en F6 depuis `scenes/p6/colisee.tscn`** :
   vestiaires → salle d'attente → arène → combat tutoriel guidé contre le commandant → retour en exploration →
   coursive → sortie est → quartier (transition provisoire). Aren seul. Rapport : `docs/P6_COLISEE.md` ;
   inventaire et allègement : `docs/P6_INVENTAIRE.md`.
   **Branche `p6-1-colisee-camera-art` (21/11/2026)** : F5 inchangé ; Colisée en F6 avec les réglages proposés
   (à valider) : caméra **P24 ×3** comme la forêt (touche **C** : P30 ×2,5 / P30 ×3 / P24 ×3), Aren avec
   **l'apparence de la forêt** (V09B.5 + V4 ; touche **B** : P4.8), **pilote d'habillage** (touche **H** : blockout).
   Rapport : `docs/P6_1_CAMERA_ART.md`.
   **Branche `p6-2-colisee-circulation-visibilite` (étape A, plan de circulation)** : F5 inchangé ; Colisée en F6
   comme en P6.1 (option de comparaison `-- --azimut=0`). Rapport et nouveau plan : `docs/P6_2_CIRCULATION_VISIBILITE.md`.

### Commandes — forêt V07B (F5)

| Touche | Action |
|---|---|
| Flèches / ZQSD | se déplacer ; **Maj** maintenue : courir |
| **1 / 2 / 3** | zoom ×2 / ×2,5 (référence de la caméra P30) / ×3 (démarrage) |
| **4 / 5 / 6** | inclinaison de la caméra : 30° (référence de la caméra P30) / 27° / 24° (démarrage) |
| **O** | occlusion dynamique : active (défaut) / coupée |
| **B** | animations d'Aren : **V09B.5** (démarrage) / **P4.8** (secours) — V09B.5 (marche et course distinctes, **profil droit seulement** ; autres directions et attente restent P4.8) — essai **non validé** |
| **T** | format des cycles : **96×112 — hauteur 64 px** (démarrage) / 96×112 (88–91 px) (mêmes PNG, affichés à ×0,719 : taille d'Aren P4.8) / 64×72 (réductions du pack) / **calque 64 px** (V09B.6 : poses V09B.5 à l'échelle P4.8, réduction automatique, **non dessinée**) / `dessin_64` (poses redessinées, quand elles existeront) |
| **G** | Aren vers le haut / le bas : **V4 dessinée** (démarrage, GIF du créateur du 20/11, proposition) → V3 « en profondeur » (**procédurale**) → 4dir du 20/11 (procédurale) → planche V2 → V4 |
| **U** | sol : **P5.3-B V3 hybride** (démarrage) → V2 transitions → V2 actuelle → V1 + calage → V1 brute → P5.3 → P5.2 figé → V07 d'origine — collisions identiques |
| **Y** | pilote P5.3-B : textures peintes sur **toute la carte** (test de répétition) / zone pilote |
| **J** | ombres douces du soleil : **qualité 4** (démarrage, essai à confirmer sur GPU) / 2 (défaut du projet) |
| **K** | rendu des personnages : **Sprite3D d'origine** (démarrage, choix du créateur du 20/11) / V10 (comparaison : pixels moyennés, soleil sans ternir, pas de brume sur le sprite, contour d'un pixel) — même dessin |
| **P** | vitesses : **actuelles** 2,2 / 3,6 m/s (démarrage) / **candidates** 2,8 / 4,5 m/s (marche / course) |
| **I** | Ilya (vers le haut / le bas : face / dos dessinées du pack V09C.5) : **V09C.6** (démarrage) → P4.8 → V09C.5 → V09C.6 (V09C.6 = course droite nouvelle, le reste V09C.5) ; nouvelle apparence en **banc d'essai non validé** (4 directions, échelle mesurée ×0,719, course choisie d'après sa vitesse réelle) |
| **L** | locomotion : V09A, essai **non validé** (inertie légère, Ilya suit la trace d'Aren ; défaut) / V08 (déplacement précédent) |
| **C** | diagnostic des collisions : obstacles (orange), eau (turquoise), bords (violet), pentes 35°–45° (jaune), > 45° (rouge) |
| **N** | masquer la végétation (et ses collisions) ; **M** : repères des parcours |
| **V** | eau animée (shader candidat) ; **F** : brume (coupée au démarrage depuis V11) ; **H** : interface ; **R** : retour au départ |

### Commandes — Colisée, ouverture (F6 sur `scenes/p6/colisee.tscn`)

| Touche | Action |
|---|---|
| Flèches / ZQSD | se déplacer ; **Maj** maintenue : courir |
| **E** / Entrée / Espace | parler, examiner ; faire avancer le dialogue ; ↑ / ↓ puis E : choisir une réponse |
| **Molette** (ou PgPréc / PgSuiv) | zoom ×2 / ×2,5 / ×3 |
| En combat tutoriel | Entrée / Espace / clic : suite de l'explication ; puis commandes habituelles du combat ; Échap : refusé |
| **C** / **B** / **H** | caméra (A / B / C) ; apparence d'Aren (forêt / P4.8) ; habillage (pilote / blockout) |
| **P** | parcours automatique (avant ou après le tutoriel) ; **F1** : informations |

### Commandes — démo de l'avant-poste (F6)

| Touche | Action |
|---|---|
| Flèches / ZQSD | se déplacer (8 directions) ; **Maj** maintenue : courir |
| **Molette** (ou PgPréc / PgSuiv) | zoom ×2 / ×2,5 (défaut) / ×3 |
| **E** / Entrée / Espace | parler au garde, examiner ; faire avancer le dialogue |
| ↑ / ↓ puis Entrée (dialogue) | choisir une réponse ; **Échap** : fermer |
| Marcher sur le seuil de la porte | entrer dans le bâtiment ; le seuil sud de la salle en fait ressortir |
| Toucher le Vorgane | lancer le combat |
| En combat : clic, ↑/↓ ou 1 à 5 | choisir une action ; ←/→ ou clic sur une partie : changer de cible |
| En combat : Tab | changer de mode (VIF / MESURÉ / CHARGÉ) ; **Entrée** : confirmer |
| **C** | caméra de comparaison : P30 (défaut) / B28 (orthographique 28°) / P38 |
| **T** | personnages : rendu net / ancien rendu bilinéaire (comparaison) |
| **R** | revenir à l'entrée de la zone ; **F1** : informations ; **F2** : couches et collisions |

### Autres scènes (ouvrir dans l'éditeur, puis **F6**)

| Scène | Contenu |
|---|---|
| `scenes/p6/colisee.tscn` | **P6 — ouverture du jeu** : Colisée de Val'Serra, tutoriel, sortie vers la ville |
| `scenes/battle/combat_tutoriel.tscn` | P6 — combat tutoriel seul (retourne au Colisée à la fin) |
| `scenes/p4/avant_poste.tscn` | **démo complète de l'avant-poste** (F5 jusqu'en P4.8) : exploration, dialogue, combat, retour |
| `scenes/p4/comparaison_camera_B28.tscn` | la démo de l'avant-poste avec l'ancienne caméra orthographique 28° (B28), pour comparer |
| `scenes/battle/combat_foret.tscn` | **P5 — combat refondu** : groupe à gauche, Vorgane à droite, décor = la forêt d'exploration |
| `scenes/battle/battle_scene.tscn` | combat seul (avec `--start=proto-battle --arena=lisiere` ou `--arena=foret` en ligne de commande) |
| `tests/test_runner.tscn` | tests automatiques dans l'éditeur |

## Vérifications

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

```bash
godot --headless --path . --script res://tests/e2e_p4_retour.gd
```

```bash
godot --headless --path . --script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide
```

```bash
godot --headless --path . res://scenes/p6/colisee.tscn -- --route=p6_sondes --quit --neuf --etat=tutorial_available --out=/tmp/p6
```

```bash
godot --headless --path . res://scenes/p4/avant_poste.tscn -- --route=p4 --quit --out=user://p4
```

```bash
godot --headless --path . res://scenes/p4/avant_poste.tscn -- --route=p4_sondes --quit --out=user://p4
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/traversees_v08.gd -- --out=/tmp/v08
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/occlusion_v07.gd -- --out=/tmp/occ
```

```bash
godot --headless --path . --script res://tests/v09_locomotion_smoke.gd
```

```bash
godot --headless --path . --script res://tests/v09b5_anim_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/animations_v09b5.gd -- --out=/tmp/v09b5
```

```bash
godot --headless --path . --script res://tests/v09c_ilya_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tests/v11_collisions_smoke.gd
```

```bash
godot --headless --path . --script res://tests/p5_combat_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tests/p52_sol_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tests/p53b_pilote_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/ilya_v09c.gd -- --out=/tmp/v09c
```

```bash
python3 tools/p49/v09b6_gabarit.py <dossier du pack V09B.5 décompressé>/ValSerra_V09B5_Aren_Marche_Course_Revue/
```

```bash
godot --path . res://scenes/p4/avant_poste.tscn -- --autoplay --route=p4_demo --route_retour=p4_retour
```

Dans l'ordre : tests automatiques (80, dont 9 pour P6), ouverture P6 de bout en bout (Colisée → tutoriel → retour →
sortie), sondes de collision du Colisée (10), rencontre de bout en bout de l'avant-poste (déclenchement, PV de démo,
victoire, défaite, bâtiment), parcours complet au clavier simulé (29 étapes ; `--camera=B28` ou `P38` pour
comparer), sondes de collision (20), forêt V07B : 18 traversées hors des chemins (marche et course) et 12 scénarios
d'occlusion, test de locomotion V09A, test des animations V09B.5 (12), mesures V09B.5 (vitesses, cadence, glissement
des pieds, demi-tours, Ilya ; P4.8 et V09B.5, vitesses actuelles et candidates), démonstration automatique de l'avant-poste (dialogue et combat joués seuls).

## Où trouver quoi

| Sujet | Fichiers |
|---|---|
| Forêt V07B (F5) : scène, modèles, manifeste | `ValSerra_P49_V07B_PREFLIGHT_GODOT/` (`godot/`, `assets/`, `docs/V07_WORLD.json`) ; occlusion `src/occlusion/` ; diagnostic des collisions `src/diag/` ; outils de test `tools/p49/` |
| Avant-poste (F6) : scène et habillage | `scenes/p4/avant_poste.gd` ; données `data/p4/` ; shaders `src/p4/` |
| Socle d'exploration 2.5D | `src/explore25/` (monde, session, caméra, acteurs, parcours), `scenes/explore25/explore_3d.gd` |
| Personnages (exploration, combat, portraits) | `art/p45/` (`SOURCES.md`), outil `tools/p45/build_p45.py` ; Vorgane d'exploration `art/p45/chars/vorgane/` |
| Décor de la zone | `art/p4/` (`SOURCES.md`), décor nettoyé `art/p41/decor/` ; outils `tools/p4/`, `tools/p41/` |
| Combat | `scenes/battle/`, règles `src/combat/`, données `data/combat/`, présentation `src/presentation/`, `src/proto/` |
| Arène de combat | `art/arena/lisiere/`, `src/presentation/arena_layers.gd`, outils `tools/arena/` |
| Dialogues | `data/p4/dialogue_garde.json`, `data/dialogue/` ; portraits : `src/proto/portraits.gd` |
| Tests | `tests/` |

## Documentation

| Document | Contenu |
|---|---|
| `docs/P4_9_V07B.md` | **P4.9** : forêt V07B (intégration, Forward+), inclinaisons 30° / 27° / 24° et occlusion, navigation libre V08A (18 traversées, corrections, F5) |
| `docs/P4_9_V09C.md` | **V09C** : décisions du 19/11/2026 (Aren V09B.5 ×0,719 retenu, nouvelle identité d'Ilya), besoins techniques et cahier des charges du pack d'Ilya, vérificateur `tools/p49/verif_pack_v09c.py` |
| `docs/HISTORIQUE.md` | où retrouver les rapports et médias des étapes précédentes (branches Git) |
| `docs/ASSETS.md` | registre des ressources et de leurs conditions d'usage |
