# V09C — Ilya, nouvelle apparence : BANC D'ESSAI (non validé)

**Statut : ressources de test, NON VALIDÉES, non intégrées définitivement.** Activées par la touche **I** de la forêt
F5 (Ilya P4.8 par défaut) et, pour les portraits, par `Portraits.ilya_v09c` (désactivé par défaut). Les sprites et
portraits P4.8 / P4.2 d'Ilya (`art/p45/`) ne sont ni modifiés ni remplacés.

Préparées par `tools/p49/v09c_ilya_pack.py` (rejouable à l'identique ; détail des opérations dans
`cadence_v09c.json` : décalages, nettoyage, mesures, SHA-256).

| Élément | Origine | Traitement |
|---|---|---|
| `exploration/{right,left,face,back}/idle_*`, `walk_*` (sauf `walk_right`), `run_*` | Drive `Assets/ValSerra_V09C5_Ilya_Pack_pour_Claude.zip` (`exploration/`, 96 × 112) | copie ; **recalage horizontal par translation entière** (aucun pixel redessiné) : marche et course de profil sur le centre de la tête, attentes sur les pieds, seulement à partir de 2 px d'écart ; face et dos en mouvement non recalés |
| `exploration/right/run_right_4.png`, `run_right_6.png` | idem | + effacement de 3 aplats quasi noirs de détourage (32 et 59 px, rectangles listés dans l'outil) |
| `exploration/right/walk_right_*` | planche de marche (2 × 4 poses, profil droit) fournie par le créateur le 19/11/2026, **WebP avec perte** 1774 × 887 | transparence nette (seuil 50 %), recalage horizontal sur le visage et le buste (−28 / +2 / 0 / +3 / −18 / −1 / 0 / 0 px source), réduction × 0,228 (hauteur médiane 89 px, comme le pack) par moyenne de surface, palette de 64 couleurs de la planche, sans tramage ; pieds sur la ligne de sol 104 |
| `portraits/*.png` (7, 512 × 512) | pack V09C.5 (`portraits/`) | copie sans retouche |

Non repris dans le dépôt : combat (`combat/`, `combat_COMPAT_42_PROTOTYPE/`, hors périmètre), `ui/`, `fx/`, planches
et GIF de revue (restent sur le Drive). Si la planche de marche existe en PNG, relancer l'outil avec elle.

Limites connues (voir `docs/P4_9_V09C.md`) : tailles normalisées artificiellement dans le pack (course et profil
gauche), course sans phase aérienne, poses 4 / 5 de la marche en double contact, attentes face / dos / gauche à
2 poses répétées, style plus pictural de la nouvelle marche que le reste du pack.
