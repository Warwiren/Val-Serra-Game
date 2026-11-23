# P7.0 — Audit, inventaire et préparation du nettoyage

Branche **`p7-0-audit-nettoyage`**, issue du commit de référence **`d88eac4`** (fin de P6.4.3).

Cette branche **ne supprime ni ne déplace aucun fichier**. Elle ajoute seulement :
* un outil d'inventaire en lecture seule : `tools/audit/inventaire.py` ;
* ses résultats :
  * `docs/audit/inventaire_fichiers.csv` : une ligne par fichier suivi ;
  * `docs/audit/inventaire_dossiers.json` : un résumé par dossier ;
* ce document.

## A. Sécurisation

| Point de restauration | Où |
|---|---|
| État avant ces interventions | commit `d88eac4`, tête de la branche distante `p6-4-3-colisee-consolidation` |
| Étiquette `reference-avant-ville-v05` | créée **localement** sur `d88eac4`. Le dépôt distant a refusé le push d'étiquette (HTTP 403, politique du proxy), donc le point de restauration fait foi par la branche ci-dessus |
| Ancienne sauvegarde | branche distante `sauvegarde-avant-purge` (existait déjà) |

Les quatre interventions sont dans des branches séparées, toutes issues de `d88eac4` :

| Intervention | Branche |
|---|---|
| A + D (audit, nettoyage proposé) | `p7-0-audit-nettoyage` |
| B (correctif des vestiaires) | `p6-4-4-colisee-vestiaires` |
| C (blockout de la ville) | `p7-1-ville-blockout-v01` |

## Méthode

* `inventaire.py` parcourt les **1 808** fichiers suivis (hors `.import` et `.uid`, qui suivent leur ressource).
* Pour chacun, il compte les références sous la forme `res://chemin` :
  * dans le code et les données du jeu ;
  * dans les outils ;
  * dans les tests ;
  * dans la documentation.

  Il compte aussi les mentions par simple nom de fichier, une preuve plus faible.
* Un **dossier** cité comme préfixe de chemin dans le code (`"res://art/sprites/vorgane/%s/%s.png"`) signale un chargement
  **dynamique** : le fichier peut être utilisé sans apparaître en toutes lettres. Ces cas ont été vérifiés à la main
  (voir la catégorie 5).
* Les autoloads (`GameState`), la scène principale (forêt V07B), les scènes de transition et les générateurs de
  données (`tools/p6/build_colisee.py`) ont été suivis explicitement.

Le dépôt pèse 266 Mo hors `.git` / `.godot`, dont :

| Dossier | Taille |
|---|---|
| `docs` | 159 Mo, dont 150 Mo de médias de rapports |
| `art` | 65 Mo |
| Forêt V07B | 40 Mo |

## Inventaire par catégorie

### 1. Définitif, à conserver (validé par le créateur ou fondation technique)

| Élément | Fichiers | Justification |
|---|---|---|
| Forêt V07B / V11 (F5) | `ValSerra_P49_V07B_PREFLIGHT_GODOT/`, `src/explore25/sol_foret*.gd(shader)` | Scène principale ; V11 et P5.3 validés |
| Socle d'exploration 2.5D | `src/explore25/`, `scenes/explore25/`, `data/explore25/` | Utilisé par la forêt, P4, le Colisée et la ville |
| Aren V09B.5 + V4, Ilya V09C | `art/tests/v09b5_aren`, `aren_4dir_v4`, `v09c_ilya`, `v09c6_ilya`, `v09b6_aren` | Identités et animations validées les 19 et 20/11 |
| Combat P5 (validé provisoirement) et CombatCore | `scenes/battle/`, `src/combat/`, `src/presentation/`, `src/proto/`, `data/combat/`, `data/rig/`, `art/p5/`, `art/sprites/`, `art/proto/`, `art/hd/`, `art/monster/`, `art/stage/`, `art/arena/` | Chargés par la scène de combat et les tests (`test_sprites.gd`) |
| Progression, état de jeu | `src/game/`, `src/tutorial/`, `data/dialogue/` | Autoload `GameState`, tutoriel |
| Tests et outils de mesure | `tests/`, `tools/` | Non-régression ; générateurs de données (reproductibilité) |
| Polices utilisées, licences | `art/fonts/` (sauf `Caladea-Regular`, voir la liste S3) | Interface |

### 2. Provisoire, encore nécessaire

| Élément | Pourquoi on ne peut pas le retirer |
|---|---|
| Avant-poste P4 (`scenes/p4/`, `data/p4/`, `src/p4/`, `art/p4/`, `art/p41/`) | Jouable en F6, tests `p4` / `p4_sondes` / `e2e_p4_retour`. Surtout, **la scène du Colisée hérite de `avant_poste.gd`**, et les textures P4 servent encore au Colisée (états de comparaison, escaliers, parvis) |
| Colisée P6 (`scenes/p6/`, `src/p6/`, `data/p6/`, `art/p63/quaternius/`, `art/p6/combat/arene_colisee.png`) | Ouverture du jeu, en attente de validation finale |
| Variantes de sol P5.3-B (`art/p53/sol`, `sol_v2`) | Choix final du créateur en attente (touche U de la forêt) |
| Aren P4.8 (`art/p45/chars/`), sprites de combat P4.5 (`art/p45/combat/`) | Secours validé ; chargés par chemins construits |

### 3. À remplacer par le nouveau quartier (après validation de la ville)

| Élément | Dépendances vérifiées |
|---|---|
| `data/p6/quartier_initial.json` (rue de transition de 28 × 8 m) | Sortie par défaut du Colisée (`colisee.gd` : `ZONE_QUARTIER`) ; générateur `tools/p6/build_colisee.py` (`quartier()`) ; `tests/e2e_p6_ouverture.gd` (arrivée et porte fermée côté quartier) ; `tests/unit/test_p6_colisee.gd` (zone « quartier ») ; parcours `p6_apres` et `p6_video_complet_apres` |
| PNJ `habitant_quartier` et son dialogue | `data/p6/pnj_colisee.json`, `data/p6/dialogues_colisee.json` |
| Branches « quartier » de `colisee.gd` | Message de fermeture des portes, panneau provisoire de la Guilde |
| Silhouettes de ville autour du Colisée (`habillage_p6.exterieur()` : façades à colombages, parvis P4) | Décor provisoire ; le blockout de la ville ne l'utilise pas |

### 4. Anciens prototypes et ressources apparemment inutilisés

Voir la liste ci-dessous : S1 à S5, sûrs ; S6 à S9, conditionnels.

### 5. Dépendances incertaines (à ne pas toucher sans vérification supplémentaire)

| Élément | Pourquoi |
|---|---|
| `art/proto/vorgane_nuit_p1/` (313 fichiers), `art/sprites/` (232), `art/hd/` | 300 fichiers sans référence littérale, mais chargés par chemins construits (`battle_scene.gd`, `sprite_monster_view.gd`, `stage.gd`, `data/rig/hero_hd.json`) et contrôlés par `test_sprites.gd` |
| `art/proto/throne_*.png` | Compagnon « lourd » du combat prototype (`PROTO_SPRITES`) : nom construit à l'exécution |
| Modèles de la forêt (37 fichiers sans référence) et `art/p63/quaternius/` (47) | Textures référencées **à l'intérieur** des `.glb` / `.gltf` |
| `art/p4/relief/rel01_mur_*.png` | Textures du modèle `rel01_mur_4m_h120.glb` |
| `data/p6/colisee_tunnel_B.json`, `_C.json` | Chargés par `"colisee_tunnel_%s.json"` |
| Outils sans référence (`tools/p4`, `p41`, `p45`, `p49`, `p5`, `p6`, `ValSerra…/tools`) | Générateurs et mesures : nécessaires pour reproduire les ressources |

## D. Suppressions proposées (À VALIDER — rien n'est supprimé)

**Sûres** : aucune dépendance d'exécution, de test ni de générateur.

| # | Fichiers | Gain | Dépendances vérifiées | Effet secondaire |
|---|---|---|---|---|
| S1 | `docs/media/` des étapes terminées : `p5_3b_v3h`, `p6`, `p6_1`, `p6_2`, `p6_2c`, `p6_2d`, `p6_3`, `p6_3_1`, `p6_3_2`, `p6_4`, `p6_4_1`, `p6_4_2` (109 fichiers) | ≈ 146 Mo | Aucune référence du jeu, des tests ni des outils ; seulement les liens des anciens comptes rendus `docs/*.md` | Liens morts dans les anciens rapports. Proposition : une note en tête de chaque rapport, « médias dans l'historique Git, commit `d88eac4` ». C'est conforme à la règle « médias de rapport limités à l'étape en cours » |
| S2 | `art/p6/combat/arene_colisee_p6.png` (+ `.import`) | 1,1 Mo | Ancien décor du combat tutoriel (P6.2-D) ; seules des mentions dans `CLAUDE.md` et `docs/P6_3_COLISEE_ART.md` | Aucun |
| S3 | `art/fonts/Caladea-Regular.ttf` (+ `.import`) | 82 ko | Seule `Caladea-Bold` est utilisée (`ui_style.gd`) | Garder `LICENCE_Caladea_OFL.txt` |
| S4 | `scenes/p6/colisee_azimut20.tscn` | — | Ancienne référence 20°. Azimut 0° validé le 22/11/2026. Seulement un commentaire de `colisee.gd` et le README | Mettre à jour le tableau « Autres scènes » du README |
| S5 | `scenes/p6/colisee_azimut0.tscn` | — | Doublon de `colisee.tscn` (azimut 0° par défaut) ; README seulement | Idem |

**Conditionnelles** : à faire seulement après la décision indiquée.

| # | Élément | Condition | Ce qu'il faudra modifier en même temps |
|---|---|---|---|
| S6 | Variantes de longueur du tunnel : `scenes/p6/colisee_tunnel_{A,B,C}_*.tscn`, `data/p6/colisee_tunnel_{A,B,C}.json` | Tunnel de 8,5 m définitivement retenu | `build_colisee.py` (écriture des variantes), `test_tunnel_variantes`, option `--tunnel`, README |
| S7 | Quartier provisoire (catégorie 3) | Ville validée et branchée à la sortie du Colisée | `colisee.gd`, tests e2e et unitaires, PNJ, dialogues, générateur, parcours |
| S8 | Variantes refusées d'Aren : `art/tests/aren_v2/`, `aren_4dir/`, `aren_4dir_v3/` (≈ 1,3 Mo) | Accord du créateur (V4 validée le 20/11, les autres ne restent qu'en comparaison, touche G) | Code de la touche G, `tests/v09b5_anim_smoke.gd` |
| S9 | Chemins de comparaison du Colisée : pilotes P6.4 / P6.4.1 (`--p64=0/1/2`), galeries A / premier pilote, portes A / B / P6.3.2, transitions A / C, éblouissement « actuel » | Validation finale du Colisée | `colisee.gd`, `habillage_p6.gd`, README, consignes |

Le nettoyage définitif fera l'objet d'un **commit spécifique**, après votre validation de cette liste. Je propose de
commencer par S1 à S5, puis de faire S6 à S9 au fil des validations.
