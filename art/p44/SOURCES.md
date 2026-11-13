# art/p44 — personnages P4.4 (Aren gris, Ilya verte au pistolet d'Aether, portraits)

Régénérable : `python3 tools/p44/build_chars_p44.py <dossier des packs Drive>` (voir l'en-tête du script pour
l'arborescence attendue). **Rien n'est déclaré final** : les packs Drive sont « À TESTER ».

| Dossier | Contenu | Source Drive (Art/Assets) | Traitement | Statut |
|---|---|---|---|---|
| `chars/aren/` | 24 images : repos 4 vues (+ respiration), marche 4 directions × 4 | `P4_3_ANIMATIONS_QA_v01_A_TESTER/aren_gray_corrige_4dir_5frames.png` (cellules 180 × 168) | réduction médiane ×1/2,29 → 56 px, palette 96, pieds au même point | à valider en main |
| `chars/ilya/` | 24 images, mêmes noms | `P4_3_ANIMATIONS_QA_v01_A_TESTER/ilya/ilya_exploration_4dir_5frames_RGBA.png` (256 × 288) | ×1/4,65 → 52 px | à valider en main |
| `combat/aren/` | 46 images : repos, avance, préparation, attaque, garde, touché, retour, Résonance charge / libération ; `impact_*` = fin de l'attaque | `P4_2_COMBAT_PORTRAITS_v01_A_TESTER/aren/*_strip.png` | ×1/1,43 → 56 px, affichées ×2 ; ombre peinte retirée | pas de K.O. dans la source |
| `combat/ilya/` | 38 images, 7 séquences (`sequences.json`) | `P4_4_ILYA_AETHER_COMBAT_v01_A_TESTER/atlases/ilya_*_strip_192.png` | ×1/2,65 → 54 px, ancre (82, 177) du pack | **prototype** : composites, `fire_3` écartée en jeu |
| `portraits/aren/` | 6 expressions | `P4_2…/aren/portraits` | recadrage carré, réduit à 160 px | fond peint inclus |
| `portraits/ilya/` | 6 expressions | `P4_2…/ilya/portraits` (80 × 94) ; neutre = grand portrait 219 px | petites sources gardées à leur taille | expressions peu détaillées |
| `portraits/garde/` | neutre | `P4_2…/garde/portraits/garde_portrait_neutre.png` | recadrage carré | armure validée |

Non intégré : poses directionnelles du garde (`P4_2…/garde/combat/frames`) — présentes seulement dans le ZIP P4.2
de 11,6 Mo, non téléchargeable depuis cet environnement ; combat d'Ilya du pack P4.2 (remplacé par P4.4).
