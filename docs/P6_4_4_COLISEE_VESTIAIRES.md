# P6.4.4 — Colisée : l'arène ne doit pas être visible depuis les vestiaires

Branche **`p6-4-4-colisee-vestiaires`**, issue de `p6-4-3-colisee-consolidation` (commit de référence `d88eac4`).

Ce ticket est distinct du blockout de la ville (`p7-1-ville-blockout-v01`), comme demandé.

Le rendu est en **logiciel (lavapipe), sans GPU** : le contrôle du sable de P6.4.3 sur un GPU réel **n'a pas pu être fait
ici**.

## Constat

Depuis les vestiaires, on voyait l'arène et les gradins au-dessus du mur du fond : partiellement au zoom ×3,
entièrement au zoom ×2. C'était aussi le cas depuis le passage et la salle d'attente, et ce dès le **départ normal du
jeu**, sans téléportation.

## Cause

C'est un défaut que **j'ai introduit en P6.4.2**.
* Pour corriger l'aplat brun de la vidéo P6.4.1, `colisee.teleport()` fait une mise à jour **immédiate** des secteurs
  (`_maj_secteur(true)`).
* Or `teleport()` est aussi appelée à la fin de chaque chargement, pour placer Aren.
* Cette mise à jour immédiate rend à nouveau visibles, à pleine opacité, les groupes de l'extérieur, dont l'arène.
* Le voile de l'extérieur, qui doit les cacher depuis un intérieur, valait déjà 1. `regler_voile_ext()` ignore une
  valeur inchangée, donc il **n'était pas réappliqué**.
* L'arène restait affichée jusqu'au premier changement réel de voile, c'est-à-dire l'entrée dans le tunnel.

Mesure : un diagnostic (`tools/p6/visibilite_vestiaires_p644.gd`) liste les maillages de l'arène
visibles quand Aren est aux vestiaires, voile = 1 :

| | Maillages de l'arène visibles |
|---|---|
| Avant | 94 (groupes EXT et EXT/S3/S5) |
| Après | 0 |

Le seul élément restant est `Plafond_S3`, un plafond qui ne sert qu'aux ombres et que la caméra ne voit pas.

## Correction (locale)

`colisee.teleport()` **force** maintenant la réapplication du voile, exactement comme le fait déjà le chargement :
`voile_ext = -1`, puis `regler_voile_ext(...)`.

Rien d'autre ne change :
* géométrie ;
* éclairage ;
* contre-jour de la bouche du tunnel ;
* système de secteurs ;
* caméra.

## Livrables

| | |
|---|---|
| Vidéo avant / après côte à côte, départ normal du jeu : vestiaires ×2 puis ×3, passage, salle d'attente ×2, tunnel, débouché | [`vestiaires_avant_apres.mp4`](media/p6_4_4/vestiaires_avant_apres.mp4) |
| Captures avant / après : vestiaires ×3 et ×2, passage ×2 | [`vestiaires_avant_apres.jpg`](media/p6_4_4/vestiaires_avant_apres.jpg) |

Sur la vidéo, la vue par la bouche du tunnel, son contre-jour et la découverte de l'arène au débouché sont
**identiques** avant et après.

## Tests (branche du correctif)

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide` (ouverture complète, combat tutoriel) | réussi (0 échec) |
| `e2e_p6_saut_tutoriel` | réussi (0 échec) |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` | réussis |
| Sondes de collision `p6_sondes` | 10 / 10 |
| F5 (`--quit-after 60`) | sans erreur |
| Caméra, traversée complète `p6_traversee` | 0 bond |
| Diagnostic de visibilité aux vestiaires | 0 maillage de l'arène visible (94 avant) |
| Transitions vestiaires → passage → salle → tunnel → arène, zooms ×2 et ×3 | vérifiées sur la vidéo : identiques à P6.4.3, sans l'arène derrière le mur |

## Fichiers modifiés

* `scenes/p6/colisee.gd` : `teleport()` force le voile.
* `src/explore25/routes25.gd` : parcours de contrôle `p6_644_vestiaires` et `p6_644_video`.
* `docs/P6_4_4_COLISEE_VESTIAIRES.md`, `docs/media/p6_4_4/`.
