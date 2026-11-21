# art/p53 — textures de sol peintes (étape P5.3-B)

| Fichier | Origine | Traitement | Statut |
|---|---|---|---|
| `sol/herbe_drue.png` | pack `ValSerra_P53B_Pilote_Sols` (21/11/2026) : SOL-01 herbe dense (P4 MAT v03, périodisée) + hauteur provisoire | RGB + hauteur en A (`tools/p5/pack_sols_p53b.py`), aucune retouche | **PILOTE, NON VALIDÉ** ; hauteur provisoire |
| `sol/herbe_usee.png` | SOL-02 herbe clairsemée + hauteur provisoire | idem | **PILOTE, NON VALIDÉ** |
| `sol/terre_chemin.png` | SOL-03 chemin / terre tassée (P4 MAT v03, périodisée) + hauteur provisoire | idem | **PILOTE, NON VALIDÉ** |
| `sol/mesures_pack.json` | mesures des fichiers (moyennes, bords, miroir, SHA-256 des sources) | — | — |

Sources et références du pack (dont SOL-04, TRS-01) : sur le Drive, non intégrées. Note de licence du pack : ne pas
considérer ces fichiers comme validés pour une diffusion commerciale sans revue du responsable.

## V2 corrective (`sol_v2/`)

| Fichier | Origine | Traitement | Statut |
|---|---|---|---|
| `sol_v2/herbe_drue.png`, `herbe_usee.png`, `terre_chemin.png` | pack `ValSerra_P53B_V2_CORRECTION_TEST` (21/11/2026) : couleurs recalées sur la palette de la forêt, raccord à 1/2 tuile, herbe usée recomposée (touffes 30–50 cm), hauteurs algorithmiques absolues en A | copiés tels quels (aucune conversion) | **PILOTE, NON VALIDÉ** ; retenus au démarrage de F5 (meilleur résultat mesuré) |
| `sol_v2/manifest_v2.json` | manifeste du pack + SHA-256 des fichiers intégrés | — | — |
