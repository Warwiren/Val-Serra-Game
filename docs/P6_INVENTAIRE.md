# P6 — Inventaire du projet et allègement (étape A)

Branche `p6-colisee-ouverture`, créée le 21/11/2026 depuis **`p5-3b-v3-hybride` @ `1f29e41`**
(« P5.3-B : V3 hybride — matières V2, forme des zones mixtes de la V1 »), dernière base stable contenant le terrain
**P5.3-B V3 hybride** et les **ombres douces qualité 4** (P5.3 étape A, `77e6f4b`, incluse).

État de départ vérifié avant toute modification :

| Vérification | Résultat |
|---|---|
| `git status` | arbre propre |
| Moteur | Godot **4.7.2** stable (`4.7.2.stable.official.ed1daf0bf`) |
| `tests/run_tests.gd` | 71 / 71 |
| `tests/e2e_p4_retour.gd` | réussi |
| `tests/p5_combat_smoke.gd` | 0 échec |

**Récupération** : rien n'est perdu. Toutes les anciennes branches restent intactes (aucune n'est modifiée) et l'état
exact de départ est aussi marqué par l'étiquette Git **`archive/avant-p6`** (= `1f29e41`). Pour retrouver un fichier
retiré : `git checkout archive/avant-p6 -- <chemin>` (ou télécharger le ZIP de la branche `p5-3b-v3-hybride`).

## 1. Ce qui est réellement utilisé

Poids du projet actif au départ (hors `.git` et `.godot`) : **≈ 350 Mo**, dont :

| Dossier | Poids | Rôle | Utilisé par |
|---|---|---|---|
| `docs/` | **190 Mo** | rapports + **médias de rapport** (captures, vidéos MP4) | personne à l'exécution |
| `ValSerra_P49_V07B_PREFLIGHT_GODOT/` | 40 Mo | forêt V07B (F5) : modèles Quaternius, géométrie, scène | F5, combat forêt (F6), tests V11 / P5.x |
| `art/` | 51 Mo | sprites, portraits, matières, sols, décor de combat | voir détail ci-dessous |
| `src/`, `scenes/`, `data/`, `tests/`, `tools/` | 1,9 Mo | code et données | — |

Scènes d'entrée (toutes conservées) : `P49_V07_Foret_Test.tscn` (F5), `scenes/p4/avant_poste.tscn`,
`scenes/p4/comparaison_camera_B28.tscn`, `scenes/battle/battle_scene.tscn`, `scenes/battle/combat_foret.tscn`,
`tests/test_runner.tscn`.

Ressources graphiques : un script de comptage des références (chemins `res://` et préfixes de dossiers dans tout
`.gd`, `.tscn`, `.json`, `.gdshader`, hors `docs/`) montre que **presque tout `art/` est référencé** :

| Dossier | Poids | Références | Statut |
|---|---|---|---|
| `art/p4/` (matières, bâtiment, accessoires, relief) | 17 Mo | `avant_poste.gd` (`T + …`), `test_p4_avant_poste.gd` | **indispensable** (et réutilisé par le Colisée) |
| `art/p53/sol`, `art/p53/sol_v2` | 12,5 Mo | shaders P5.3-B (V1 = masque des zones mixtes de la V3, V2 = matières) | **indispensable** (V3 hybride) |
| `art/p45/` (personnages, portraits, combat) | 4,2 Mo | Actor25, portraits, combat | **indispensable** |
| `art/tests/` (Aren V09B.5 / V2 / 4dir / V3 / V4, Ilya V09C) | 6,7 Mo | touches B / T / G / I de F5, tests V09 | conservé : systèmes de comparaison encore branchés (voir § 3) |
| `art/proto/` (Vorgane de nuit, Throné, fond) | 3,1 Mo | combat (`battle_scene.gd`, portraits) | conservé (Throné = futur compagnon) |
| `art/sprites/`, `art/hd/`, `art/stage/`, `art/monster/`, `art/characters/`, `art/portraits/` | 3 Mo | anciens modes de combat (A/B, HD, rig) toujours appelés par `battle_scene.gd` | conservé (systèmes existants) |
| `art/arena/lisiere`, `art/p5/combat` | 3,3 Mo | décors de combat lisière / forêt | indispensable |
| `art/fonts/` | 1,4 Mo | interface | indispensable (`Caladea-Regular` non référencée, 80 Ko, gardée avec sa licence) |

## 2. Retiré du projet actif (commit séparé « P6 nettoyage »)

**Médias de rapport des étapes terminées** — 133 fichiers, **≈ 182 Mo** (captures JPG/PNG et vidéos MP4) :

| Dossier retiré | Fichiers | Poids | Rapport concerné (toujours présent) |
|---|---|---|---|
| `docs/media/p4_9/` | 90 | 121 Mo | `P4_9_V07B.md`, `P4_9_V09C.md`, `P4_9_V11.md` |
| `docs/media/p5/` | 3 | 6 Mo | `P5_COMBAT.md` |
| `docs/media/p5_2/` | 5 | 8 Mo | `P5_2_ENVIRONNEMENT.md` |
| `docs/media/p5_3/` | 11 | 12 Mo | `P5_3_SOLS.md`, `P5_3_DIAGNOSTIC_SOLS.md` |
| `docs/media/p5_3b/` | 7 | 10 Mo | `P5_3B_PILOTE.md` |
| `docs/media/p5_3b_v2/` | 9 | 13 Mo | `P5_3B_V2.md` |
| `docs/media/p5_3b_v2t/` | 8 | 12 Mo | `P5_3B_V2_TRANSITIONS.md` |

Justification : consigne du projet (« médias de rapport limités à l'étape en cours ») ; **aucune référence** depuis le
code, les scènes, les données ou les tests (vérifié par recherche ; seul `tools/p49/v09b6_gabarit.py` y écrit par
défaut, il recrée le dossier au besoin). Les rapports `.md` restent ; leurs liens d'images pointent vers des fichiers
disponibles dans les branches d'origine et sous l'étiquette `archive/avant-p6` (indiqué dans `docs/HISTORIQUE.md`).

Conservé : `docs/media/p5_3b_v3h/` (12 Mo) — référence visuelle **actuelle** du terrain (V3 hybride retenue).

Effet : projet actif ≈ **350 → 170 Mo** (ZIP téléchargé environ deux fois plus léger). L'historique Git, lui, ne change
pas de taille (aucune réécriture d'historique).

## 3. Proposé, **non retiré** (décision du créateur)

Ces éléments sont obsolètes ou expérimentaux, mais encore **branchés à du code** (touches de comparaison, tests) :
les retirer demande de modifier les scènes concernées. Rien n'est supprimé sans accord.

| Élément | Poids | Pourquoi il pourrait partir | Ce qu'il faudrait modifier |
|---|---|---|---|
| `art/tests/aren_4dir/`, `art/tests/aren_4dir_v3/` | 0,55 Mo | marches face / dos **procédurales refusées** (V4 dessinée retenue) | `anim_v09b5.gd` (cycle de la touche G), `tests/v09b5_anim_smoke.gd` |
| `art/tests/aren_v2/` | 0,16 Mo | planche V2, remplacée par V4 | idem (touche G) |
| `art/tests/v09b6_aren/` | 0,09 Mo | calque 64 px « non dessiné » (étude) | `anim_v09b5.gd` (touche T) |
| Variantes de sol P5.2 figé, P5.3, V1, V1 + calage, V2, V2 transitions | shaders, < 0,1 Mo | V3 hybride retenue provisoirement | cycle de la touche U de F5 — **à garder** tant que la V3 n'est pas validée face à la V1 + calage |
| `ValSerra_P49_V07B_PREFLIGHT_GODOT/tools/*.py`, `docs/*.json` d'intégrité | 0,3 Mo | outils de génération du lot V07B, inutiles à l'exécution | aucun (documentation du lot) |
| Modes de combat anciens (rendu A/B, HD, « art proto », rig) et leurs SVG | ≈ 3 Mo | le prototype n'utilise plus que le mode « proto » | `battle_scene.gd`, `battle_hud.gd`, tests de combat — **refonte à part**, hors P6 |

Recommandation : retirer les deux premières lignes après la prochaine revue des animations d'Aren ; garder le reste.

## 4. Découpage technique retenu pour le Colisée

* **Données** : `data/p6/colisee.json` (format du socle `src/explore25/` : surfaces, murs, portes, sorties, PNJ),
  généré par `tools/p6/build_colisee.py` (l'ellipse de l'arène est approchée par des segments de mur) ;
  `data/p6/dialogues_colisee.json` (toutes les répliques, choix compris) ; `data/p6/tutoriel_colisee.json`
  (étapes du tutoriel) ; `data/combat/monster_commandant.json` (adversaire du tutoriel).
* **Exploration** : `scenes/p6/colisee.tscn` / `colisee.gd` — hérite de l'habillage de l'avant-poste
  (`scenes/p4/avant_poste.gd` : caméra P30, sprites « pixel net », matières P4, boîte de dialogue à portraits) ;
  Aren seul (pas de compagnon), plusieurs PNJ.
* **Progression** : `src/game/progression.gd` — états explicites `intro_not_started`, `tutorial_available`,
  `tutorial_in_progress`, `tutorial_completed`, `coliseum_exited` et objectif courant, stockés dans
  `GameState.flags` (dictionnaire simple, prêt pour la sauvegarde).
* **Combat tutoriel** : `scenes/battle/combat_tutoriel.tscn` — hérite de la scène de combat existante, **CombatCore
  inchangé** ; le commandant ne perd pas de PV **par ses données** (affinités et résistances à 0) ;
  résultat `tutorial_completed` distinct de la victoire / défaite.
* **Guidage d'interface** : `src/tutorial/guide_interface.gd` (voile, découpe et contour animé autour d'un composant,
  bulle du commandant), cibles résolues à chaque image depuis les composants réels du HUD (aucune position codée en dur).
