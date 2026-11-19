# V09C.6 — Ilya : course de profil droit et portraits au cadrage serré — BANC D'ESSAI (non validé)

**Statut : candidats validés artistiquement pour un test en jeu, NON intégrés définitivement.** Course : touche **I**
de la forêt F5 (P4.8 → V09C.5 → V09C.6 → P4.8 ; seul le cycle de course droite change en V09C.6). Portraits :
`Portraits.ilya_v09c` + `Portraits.ilya_cadrage` (« serre » ou « v09c5 »), désactivés par défaut. Le banc V09C.5
(`art/tests/v09c_ilya/`) et les ressources P4.8 / P4.2 ne sont pas modifiés.

Préparé par `tools/p49/v09c6_ilya_course.py` (rejouable ; mesures et SHA-256 dans `cadence_v09c6.json`).

| Élément | Origine | Traitement |
|---|---|---|
| `exploration/right/run_right_0..7.png` | `ValSerra_V09C6_Ilya_Course_Droite_CANDIDAT.zip`, `exploration/right/` (96 × 112, échelle uniforme ×0,224 depuis la planche, envols 3 et 7) | **copie sans retouche** (alpha déjà net, cycle déjà sur place : centre de la tête entre x = 60 et 62) |
| `portraits_160/serre/*.png` | même ZIP, `portraits_cadrage_serre_CANDIDATS/` (512 × 512) | réduction 160 × 160 (Lanczos), comme les portraits P4.x (l'interface affiche en filtrage linéaire sans mipmaps) |
| `portraits_160/v09c5/*.png` | `art/tests/v09c_ilya/portraits/` (V09C.5, 512 × 512) | même réduction, pour la comparaison et le secours |

Non repris dans le dépôt : planche source, spritesheets, GIF et aperçus du ZIP (restent sur le Drive), portraits
512 px au cadrage serré (sur le Drive).
