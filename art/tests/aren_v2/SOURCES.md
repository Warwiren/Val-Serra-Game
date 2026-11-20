# Aren V2 — vues de face et de dos (même design que le profil droit V09B.5) — BANC D'ESSAI (non validé)

**Statut : test, non validé.** Utilisées par la forêt F5 au démarrage (profil unique, formats 96 × 112) pour les
déplacements vers le bas (marche de face), vers le haut (marche de dos) et l'arrêt après un déplacement vers le bas
(attente de face). Le profil droit reste V09B.5 (`art/tests/v09b5_aren/`), la gauche son miroir.

| Fichiers | Origine | Traitement (`tools/p49/aren_v2_directions.py`, rejouable) |
|---|---|---|
| `walk_face_0..7.png`, `walk_back_0..7.png`, `idle_face_0..7.png` (96 × 112) | planche « Aren – Animations de déplacement (V2) » fournie par le créateur le 20/11/2026 (1254 × 1254, **WebP avec perte**, fond blanc ; rangées 1, 2 et 5) | détourage du fond blanc relié aux bords (ombre gris clair comprise, petits reflets intérieurs gardés), bord érodé d'1 px, chaque **rangée** ramenée à 89 px de haut (taille d'Aren V09B.5 ; l'attente, dessinée ≈ 9 % plus grande, est ramenée à la même taille), réduction par moyenne de surface et palette de 64 couleurs de la planche, pieds sur la ligne de sol 101, tête centrée (balancement du corps conservé), frange blanche résiduelle retirée. **Aucun redessin.** |

Non repris : rangées « marche vers la droite » et « marche vers la gauche » de la planche (le profil V09B.5 validé et
son miroir sont conservés). Si la planche existe en PNG, relancer l'outil avec elle. Mesures et SHA-256 :
`cadence_aren_v2.json`.
