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

Non repris (et pourquoi) : les planches `BAT-REF-*` et `BRI-REF-*` (concepts sur fond peint, vues non concordantes),
les modules `relief/` et `eau/` de P4_ENV (non calibrés, non bouclables), l'atlas `Ilya_exploration_walk_4dir` de
`P4_PERSONNAGES_EXPLORATION_v01` (Ilya blonde, refusée), les 32 poses `P4_ILYA_REFERENCE_32POSES_v02` (proportions
« chibi » agrandies, incompatibles avec les sprites en jeu), l'atlas Aren v01 (non vérifié en mouvement ; les sprites
d'Aren en jeu sont conservés).
