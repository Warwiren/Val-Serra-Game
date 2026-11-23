# art/p4 — provenance et statut des ressources de l'avant-poste (P4)

Régénérable par `python3 tools/p4/build_assets.py <dossier des packs Drive>`. **Aucune ressource n'est déclarée
finale** : les packs Drive sont « À TESTER », les textures générées ici sont provisoires.

| Dossier | Fichiers | Source | Statut |
|---|---|---|---|
| `mat/` | `sol_herbe`, `sol_terre`, `sol_paves`, `roche`, `eau_courante`, `eau_galets` (1024², RGB) ; `trs_herbe_terre`, `berge` (1024², RGBA) | Drive `Art/Assets/Textures_terrain/P4_MAT_v03_A_TESTER` (SOL-01 v03, SOL-02, SOL-03, REL-01 v03, EAU-01, EAU-02, TRS-01, BER-01), copiés sans retouche | à tester — intégrés et vus en jeu, non validés par le créateur |
| `vegetation/` | 12 découpes (4 arbres, 3 buissons, touffe, 2 fleurs, rocher, massettes) | Drive `P4_ENV_MODULES_v01_A_TESTER/vegetation`, copiées sans retouche | à tester ; arbres : tronc et feuillage fusionnés |
| `props/` | 10 découpes (lanterne, bannière bleue, caisse, tonneau, sacs, banc, clôture, bûches, chariot, panneau) | Drive `P4_ENV_MODULES_v01_A_TESTER/props`, copiées sans retouche | à tester ; échelle fixée en mètres dans `scenes/p4/avant_poste.gd` (`PROPS`) |
| `arbre/` | `arb01_tronc`, `arb01_feuillage_arriere`, `arb01_feuillage_avant` (512², même canevas, pivot 256 × 494) | Drive `P4_PILOTES_TECH_v01_A_TESTER/ARB-01_ARBRE` | pilote : 3 calques, feuillage animé par shader |
| `relief/` | `rel01_mur_4m_h120.glb` (4 × 1,20 × 0,50 m, sans collision) | Drive `P4_PILOTES_TECH_v01_A_TESTER/REL-01_FALAISE` | pilote : bord du plateau au nord de la plaine |
| `batiment/` | `facade_colombage`, `toit_violet`, `pierre_taille`, `porte`, `fenetre` | **générés** par `tools/p4/build_assets.py` (motifs procéduraux) | **PROVISOIRES** — à remplacer par des textures peintes ; style d'après `BAT-REF-01` (référence, non découpée) |
| `pont/` | `planches` | **généré** | **PROVISOIRE** — style d'après `BRI-REF-01/02` (référence, non découpée) |
| `fx/` | `halo` | généré | utilitaire |
| `chars/ilya/` | 6 images (repos, marche) | **dérivées** de `art/explore_hd2d/chars/ilya/` : tenue recolorée en bleu nuit, cuir conservé, mèches longues retirées | **PROVISOIRE** — voir docs/P4_AVANT_POSTE.md § Ilya |
| `art/tests/v09b5_aren/` (hors `art/p4/`) | **V09B.5** : marche et course candidates d'Aren, profil droit, 8 images, 96×112 et 64×72 | pack Drive `ValSerra_V09B5_Aren_Marche_Course_ANIMATIONS.zip`, copié sans retouche | **CANDIDAT NON VALIDÉ** — essai réversible (touche B de la forêt F5), voir `docs/P4_9_V07B.md` § V09B.5 |
| `art/tests/v09b6_aren/` (hors `art/p4/`) | **V09B.6** : calques d'échelle 64 px (poses V09B.5 réduites automatiquement) et emplacement `dessin_64/` des poses à redessiner | `tools/p49/v09b6_gabarit.py` depuis les planches du pack V09B.5 | **CALQUES NON DESSINÉS, NON ADOPTABLES** — voir `docs/P4_9_V07B.md` § V09B.6 |
| `art/tests/v09c_ilya/` (hors `art/p4/`) | **V09C** : nouvelle Ilya, 4 directions × attente / marche / course, 7 portraits | pack Drive `ValSerra_V09C5_Ilya_Pack_pour_Claude.zip` + planche de marche du 19/11/2026, préparés par `tools/p49/v09c_ilya_pack.py` | **BANC D'ESSAI NON VALIDÉ** (touche I) — voir `art/tests/v09c_ilya/SOURCES.md` |
| `art/tests/v09c6_ilya/` (hors `art/p4/`) | **V09C.6** : course droite d'Ilya (8 poses) et portraits au cadrage serré (160 px) | `ValSerra_V09C6_Ilya_Course_Droite_CANDIDAT.zip`, `tools/p49/v09c6_ilya_course.py` | **BANC D'ESSAI NON VALIDÉ** (touche I) — voir son `SOURCES.md` |
| `art/tests/aren_v2/` (hors `art/p4/`) | **Aren V2** : marche de face, marche de dos, attente de face (8 images chacune) | planche du 20/11/2026, `tools/p49/aren_v2_directions.py` | **BANC D'ESSAI NON VALIDÉ** — voir son `SOURCES.md` |
| `art/tests/aren_4dir/` (hors `art/p4/`) | **Aren 4 directions** : attentes profil / face / dos (étude IDLE V1), marches et courses de face / dos **procédurales** | `ValSerra_Aren_IDLE_V1_ETUDE.zip`, `tools/p49/aren_orientations.py` | **BANC D'ESSAI NON VALIDÉ** — voir son `SOURCES.md` |
| `art/tests/aren_4dir_v3/` (hors `art/p4/`) | **Aren face / dos V3 « en profondeur »** : marches et courses de face / dos **procédurales** (pas en profondeur, bras en opposition) | `tools/p49/aren_marche_profondeur.py` (depuis `art/tests/aren_4dir/`) | **PROPOSITION NON VALIDÉE** — voir son `SOURCES.md` |
| `art/tests/aren_4dir_v4/` (hors `art/p4/`) | **Aren face / dos V4 DESSINÉES** : marches de face et de dos des GIF du créateur (20/11/2026), réduites à l'échelle du profil et ramenées à sa palette | GIF du créateur, `tools/p49/aren_marche_gif.py` | **PROPOSITION NON VALIDÉE** — voir son `SOURCES.md` |

Non repris (et pourquoi) : les planches `BAT-REF-*` et `BRI-REF-*` (concepts sur fond peint, vues non concordantes),
les modules `relief/` et `eau/` de P4_ENV (non calibrés, non bouclables), l'atlas `Ilya_exploration_walk_4dir` de
`P4_PERSONNAGES_EXPLORATION_v01` (Ilya blonde, refusée), les 32 poses `P4_ILYA_REFERENCE_32POSES_v02` (proportions
« chibi » agrandies, incompatibles avec les sprites en jeu), l'atlas Aren v01 (non vérifié en mouvement ; les sprites
d'Aren en jeu sont conservés).

**P6.4 (Colisée, pilote)** : `mat/roche.png` est aussi lu par `src/p6/maconnerie_p64.gdshader` comme **grain de luminance
seulement** (basse fréquence, décalé par pierre) pour les matériaux procéduraux des zones pilotes. Aucune nouvelle image ;
statut inchangé (à tester). Les matériaux P6.4 eux-mêmes sont **PROVISOIRES** (pilote en attente de la revue du créateur).

**P6.4.1 (Colisée, second pilote)** : `mat/sol_terre.png` et `mat/sol_herbe.png` sont aussi lus par
`src/p6/maconnerie_p64.gdshader` comme **calques de détails peints** (variations autour de leur moyenne : salissures et
mousse des matières pilotes). Aucune image modifiée ni ajoutée ; statut inchangé (à tester). Matières P6.4.1 PROVISOIRES.

## P7.2 — retrait de l'avant-poste (accord du créateur, 23/11/2026)

Retirés du projet actif (restent dans l'historique Git, commit `d88eac4`) parce qu'ils ne servaient qu'à l'avant-poste :
`mat/eau_courante.png`, `mat/eau_galets.png`, `mat/berge.png`, `mat/trs_herbe_terre.png`, `relief/` (REL-01),
`arbre/arb01_feuillage_arriere.png`, `arbre/arb01_feuillage_avant.png`, `vegetation/` (buissons, fleurs, herbes, massette).
Gardés : matières et bâtiments utilisés par le Colisée, `props/`, et les entrées de `tools/p41/decor_p41.py`
(`arbre/arb01_tronc.png`, `vegetation/arb0*_*.png`, `vegetation/roc01_rocher.png`).
