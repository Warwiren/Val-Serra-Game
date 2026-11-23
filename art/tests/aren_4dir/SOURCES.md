# Aren — jeu complet d'orientations (profil, face, dos) cohérent avec V09B.5 — BANC D'ESSAI (non validé)

**Statut : test, non validé.** Actif au démarrage de la forêt F5 (formats 96 × 112). Le profil droit en mouvement
reste V09B.5 (`art/tests/v09b5_aren/`), la gauche son miroir ; la planche V2 (`art/tests/aren_v2/`) reste
disponible (`jeu_vues = "v2"`).

| Fichiers | Origine | Traitement (`tools/p49/aren_orientations.py`, rejouable) | Nature |
|---|---|---|---|
| `idle_right_0..3`, `idle_face_0..3`, `idle_back_0..3` | étude « Aren IDLE V1 » (`ValSerra_Aren_IDLE_V1_ETUDE.zip`, 20/11/2026) : profil droit recomposé à partir d'un vrai sprite V09B.5 ; face et dos = études de design aux proportions du profil | copie ; seule retouche : frange de détourage retirée (pixels quasi blancs au bord, gris neutres au bord de la tête ; 2 à 32 px par image) | attentes de l'étude (respiration d'1 px) |
| `walk_face_0..7`, `walk_back_0..7`, `run_face_0..7`, `run_back_0..7` | dérivés de `idle_face_0` / `idle_back_0` | jambes séparées sous la hanche, levées alternativement (marche 3 px, course 5 px), corps soulevé (1 / 2 px) et basculé d'1 px vers la jambe d'appui ; image 0 = attente | **PROCÉDURAUX** : aucun pixel nouveau, ce ne sont pas des poses dessinées |

Mesures et SHA-256 : `cadence_aren_4dir.json`. Points à reprendre en dessin pour une version définitive : bras
immobiles de face / dos, pas de course de face / dos dessinée, bras et cape de l'attente de profil (recomposée).
