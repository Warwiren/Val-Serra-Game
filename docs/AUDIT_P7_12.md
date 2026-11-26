# Audit du projet et nettoyage contrôlé (P7.12, étapes A à D)

Branche **`p7-12-quartier-civique`**, commit de nettoyage séparé de celui du quartier civique.

Règle suivie : **aucune suppression de fichier suivi par Git** sans l'accord du créateur. Ce document fournit la liste
des candidats et leurs dépendances vérifiées. Le seul nettoyage effectué est non destructif (§ 5).

## 1. Méthode (étape A)

Points vérifiés :

* `project.godot` : scène F5 (forêt V07B) et autoload unique `GameState`.
* Chaque `.tscn` : recherche de son nom dans les scripts, scènes, données, outils et tests (hors documentation).
* Chaînes d'**héritage** des scripts (`extends "res://…"`) et **préchargements** (`preload`).
* **Chargements dynamiques** : noms construits à l'exécution, par exemple `DIR + key + "_combat/"` ou `"idle_%d.png"`.
* Données lues par les tests unitaires, parcours automatiques (`routes25.gd`), générateurs `tools/`, transitions
  (portails, `progression.gd`).
* Ressources (`art/`, `data/`) : un dossier n'est déclaré inutilisé que si ni son chemin ni aucun de ses fichiers n'est
  cité. Le nom d'un fichier ne suffit pas : beaucoup d'animations sont chargées par motif.

## 2. Dépendances essentielles (à conserver)

| Élément | Pourquoi il est indispensable |
|---|---|
| `scenes/p4/avant_poste.gd` | Script de base : `colisee.gd` en **hérite**. Toute ville et le Colisée en dépendent. |
| `scenes/p7/ville_blockout.gd` → `ville_v06.gd` → `ville_v07a.gd` → `ville_v07b.gd` | **Chaîne d'héritage** de la ville actuelle. Malgré leurs numéros de phase, les trois premiers scripts sont indispensables. |
| `scenes/p7/archi_p77.gd`, `tranche_p76.gd`, `place_p78.gd`, `forge_p79.gd`, `forge_p7101.gd`, `boutique_p711.gd`, `civique_p712.gd` | Composants de la ville actuelle : bibliothèque, tranche, place, forge D (et ses utilitaires Quaternius), boutique, quartier civique. |
| `scenes/p6/colisee.gd`, `habillage_p6.gd`, `colisee.tscn` | Colisée, tutoriel, transitions ville ↔ Colisée ; `colisee.gd` porte aussi la ville (`ville_v07b = true`). |
| `data/p6/colisee.json`, `quartier_initial.json`, `pnj_colisee.json`, `dialogues_colisee.json`, `tutoriel_colisee.json` | Colisée et tutoriel. `quartier_initial.json` est la sortie est du Colisée lancé seul. |
| `data/p6/colisee_tunnel_A/B/C.json` | **Lus par les tests unitaires** (`tests/unit/test_p6_colisee.gd`). |
| `data/p7/ville_v07b.json` + `tools/p7/build_ville_v07b.py` | Ville de référence et son générateur. |
| `tools/p7/camera_volumes_p76.py`, `profil_gpu_p77.gd` | Contrôles en cours : volumes, axe du château, profilage. |
| `scenes/battle/*`, `src/`, `ValSerra_P49_V07B_PREFLIGHT_GODOT/` | Combats, systèmes, forêt (F5). Aucune modification. |
| `art/proto/throne_combat/` | Semblait inutilisé : il est en réalité **chargé dynamiquement** (`pack_hunter_view.gd` : `DIR + key + "_combat/"`). |
| `tools/p4`, `tools/p41`, `tools/p45`, `tools/audit` | Outils de production lancés à la main (`tools/p45/build_p45.py` est cité par CLAUDE.md). |

## 3. Scènes et ressources conservées

**Jouables.**
* Forêt V07B (F5).
* `scenes/p6/colisee.tscn`.
* `scenes/p7/ville_v07b.tscn` : **scène de référence de la ville**.
* `scenes/battle/combat_tutoriel.tscn`, `combat_foret.tscn`, `battle_scene.tscn`.

**Outils de développement.**
* `scenes/p7/catalogue_archi_p77.tscn` : catalogue des composants, utile pour les prochains lots.
* `tests/test_runner.tscn`.
* Options en ligne de commande de la ville : `--forge`, `--boutique`, `--place`, `--tranche`, `--civique`.

## 4. Candidats à la suppression (EN ATTENTE de votre validation)

### Lot 1 — scènes de comparaison terminées (sûr : rien ne les charge)

| Fichier | Dépendances vérifiées | Justification |
|---|---|---|
| `scenes/p7/ville_v07b_forge_a.tscn`, `_b.tscn`, `_c.tscn` | Aucune (F6 seulement ; mentionnées dans le README et les rapports) | Comparatif P7.9 clos : forge D approuvée. Les variantes restent accessibles par `--forge=A\|B\|C` tant que le code existe. |
| `scenes/p7/ville_v07b_boutique_710.tscn` | Aucune (F6 seulement) | Boutique P7.11 approuvée. P7.10 reste accessible par `--boutique=710`. |

### Lot 2 — anciennes villes V0.5, V0.6, V0.7-A (scènes sûres ; données et code à traiter ensemble)

| Fichier | Dépendances vérifiées | Justification |
|---|---|---|
| `scenes/p7/ville_v05_blockout.tscn`, `ville_v06_montee.tscn`, `ville_v07a.tscn` | Aucun chargement : ni test, ni transition. Citées seulement en commentaire dans `colisee.gd`, `routes25.gd`, `camera_continuite_p6.gd`. | Prototypes dépassés : la V0.7-B est la référence. **Leurs scripts sont conservés** (héritage, § 2). |
| `data/p7/ville_v05.json`, `ville_v06.json`, `ville_v07a.json` | Chargés par `colisee.gd` **seulement** avec les drapeaux `ville_v05/v06/v07a` ou `--ville=v05\|v06\|v07a`. | À retirer **avec** les branches correspondantes de `colisee.gd`, sous forme d'une modification de code testée. |
| `tools/p7/build_ville_v05.py`, `build_ville_v06.py`, `build_ville_v07a.py`, `plan_v07a.py` | Générateurs de ces seules données ; non importés par `build_ville_v07b.py`. | Avec les données. |
| Parcours `p7_v05_equiv`, `p7_v06_*`, `p7_v07_camera\|raccord\|sondes\|trajets\|video\|vues`, `p7_raccord`, `p7_camera`, `p7_trajets`, `p7_video`, `p7_vues` | Utilisés uniquement avec ces scènes. **`p7_v07_portail` sert à la V0.7-B : à garder.** | Avec les scènes, en vérifiant chaque parcours. |

### Lot 3 — code des variantes abandonnées (après le lot 1)

| Élément | Justification |
|---|---|
| `forge_p79.gd` : variantes A et B, `_accessoires_archi`, `_quaternius`, `_porte_quaternius` | Seules C (avant D) et D sont encore utiles. Retrait **sans** toucher aux utilitaires `_modele`, `_fusion_gltf` et `_terre_cuite`, dont dépendent la forge D et les boutiques. |
| `scenes/p7/boutique_p710.gd` | Boutique P7.10, utilisée par `--boutique=710` seulement. |

### Lot 4 — proposé séparément, comme demandé : variantes du tunnel du Colisée

| Fichier | Dépendances | Proposition |
|---|---|---|
| `scenes/p6/colisee_tunnel_A_6_5m.tscn`, `_B_8_5m.tscn`, `_C_9_5m.tscn` | Aucun chargement : F6 et option `--tunnel`. | Longueur retenue de 9 m depuis P7.4.1 : les trois scènes peuvent sortir du projet actif. |
| `data/p6/colisee_tunnel_A/B/C.json` | **Lus par les tests unitaires.** | **À conserver**, sauf réécriture des tests (non proposée). |

### Ressources graphiques

Aucun dossier de `art/` n'est démontrablement inutilisé : tous sont cités, souvent par des motifs de noms.

* `art/tests/` (études d'animation V2 à V4, banc V09C) : encore utilisés par `anim_v09b5.gd` et `anim_v09c.gd`, au
  démarrage de F5.
* Leur retrait suppose d'abord une décision sur ces versions d'animation : hors périmètre.

## 5. Nettoyage non destructif effectué (commit dédié)

* **Identifiants `.uid` générés** par l'import Godot pour les scripts et shaders P7.9 à P7.12 qui n'en avaient pas.
  Le dépôt suit les `.uid` : sans eux, chaque ouverture de l'éditeur crée des fichiers non suivis.
* **README** : le tableau « Autres scènes » est réorganisé en trois groupes (jouables, outils de développement,
  comparaisons et prototypes **candidats au retrait**). Aucun chemin ne change.
* **Ce document** : inventaire, dépendances, candidats.

Aucun fichier n'est déplacé, renommé ou supprimé, et aucun fichier non suivi n'est effacé.

## 6. Ordre proposé après validation

1. Lot 1 : supprimer les quatre scènes, mettre à jour le README, vérifier le chargement de la ville.
2. Lot 3 : retirer le code des variantes A, B et P7.10, puis faire tourner tous les tests.
3. Lot 2 : retirer les scènes V0.5, V0.6 et V0.7-A, puis leurs données, générateurs, branches de `colisee.gd` et
   parcours. Les scripts restent, l'héritage restant intact.
4. Lot 4, si vous le validez : les trois scènes de tunnel seulement.

Chaque étape fera l'objet d'un commit distinct et de la série complète de tests.
