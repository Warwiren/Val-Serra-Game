# V09B.6 — gabarit 64 px d'Aren : calques d'échelle et emplacement des poses redessinées — DOSSIER DE TEST

**Statut : AUCUN ASSET.** Rien ici ne remplace les sprites P4.8 (`art/p45/chars/aren/`) ni les candidats V09B.5
(`art/tests/v09b5_aren/`).

| Élément | Origine | Statut |
|---|---|---|
| `calque_64/` (marche et course, 8 images, 128 × 96) | poses V09B.5 reconstruites depuis les planches sources du pack (`sources/*.png`, alignement du `QA_MANIFEST.json`), **réduites automatiquement** à 64 px de haut (moyenne de surface, alpha prémultiplié seuillé à 50 %, palette de 48 couleurs du 96×112, sans tramage) par `tools/p49/v09b6_gabarit.py` | **calque d'échelle et base de repixelisation : NON DESSINÉ, NON ADOPTABLE.** Sert à juger la taille en jeu (touche T) et de point de départ au redessin |
| `cadence_v09b6.json` | mesures (hauteur, ligne de sol, foulée, recul du pied d'appui image par image) de P4.8, V09B.5 et des calques ; gabarit ; plan des 8 poses cibles | mesures |
| `dessin_64/` (à créer) | **poses redessinées par l'équipe artistique**, mêmes noms (`walk_right_0..7.png`, `run_right_0..7.png`), canevas 128 × 96, pieds sur la dernière rangée, torse en x = 60 | relancer `tools/p49/v09b6_gabarit.py` : elles sont mesurées, vérifiées et apparaissent en jeu (touche T) |

Gabarit commun (référence : Aren P4.8, `idle_right.png`) : canevas 128 × 96, sol = rangée 96 (bas de l'image), torse
(bassin) en x = 60, hauteur visible 64 px (61 à 67 admis), tête 20–21 px cheveux compris (≈ un tiers de la hauteur,
comme P4.8 et V09B.5).
