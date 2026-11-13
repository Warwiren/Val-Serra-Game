# art/p45 — personnages P4.5 / P4.6 (Aren, Ilya, garde) : exploration, combat, portraits

Régénérable : `python3 tools/p45/build_p45.py <dossier des sources>` (arborescence attendue dans l'en-tête du
script). Méthode : réduction par couleur médiane (jamais d'agrandissement), palette commune par personnage, ancrage
fixe. **Rien n'est déclaré final** : les packs Drive sont « À TESTER ».

| Dossier | Contenu | Source (Drive Art / Art/Assets) | Traitement | Statut |
|---|---|---|---|---|
| `chars/aren/` | 4 directions : attente 8 images, marche 4 images | `P4_3_ANIMATIONS_QA_v01/aren_gray_corrige_4dir_5frames.png` | 70 px (1 px = 1 px d'écran à ×2,5), alignement sur la tête ; **P4.6** : pose de repos remise à l'échelle des pas (le pack la dessine ~18 % plus petite : tête et buste réduits à l'échelle des pas, jambes tassées verticalement) | marche du pack ; attente **procédurale** ; repos **retouché** (proportions) |
| `chars/ilya/` | idem | `P4_3_ANIMATIONS_QA_v01/ilya/ilya_exploration_4dir_5frames_RGBA.png` | 65 px, contour assombri | idem |
| `chars/garde/` | idem | pack léger `ValSerra_Garde_P44_integration_leger.zip` (`garde/combat/frames/{down,up,left,right}_{0..4}`) | 75 px, ombres peintes retirées | idem ; profil droit : image 2 plus basse (source) |
| `combat/aren/` | 50 images : repos, avance, préparation, attaque, impact, retour, garde, touché, Résonance charge / libération | planche d'origine `Art/Aren/Aren_sprites_combat.png`, bleu recoloré en gris (comme P4.2) | découpe complète (rien n'est rogné), effets d'Aether rattachés au bon personnage, 56 px affichés ×2 | pas de K.O. dans la source |
| `combat/ilya/` | attente 8, dégainer 5, tir 7, tir chargé 8, garde 4, touchée 4, K.O. 6 | **P4.6, de face** : corps = pose de repos de face `P4_3_ANIMATIONS_QA_v01/ilya/frames/down_idle.png` ; bras armé, pistolet et effets = `P4_4_ILYA_AETHER_COMBAT_v01/atlases/ilya_*_strip_192.png` | montage : bras droit pendant effacé en visée (cape repeinte), bras tendu depuis l'épaule ; attente : respiration ; tir : 2 images de recul dérivées (`fire_3` écartée) ; K.O. : bascule en arrière (rotation au plus proche), au sol, pistolet tombé | **prototype, montage** (à redessiner) |
| `portraits/{aren,ilya,garde}/` | 6 + 6 + 1 | `P4_2_COMBAT_PORTRAITS_v01` ; garde : pack léger | carré, 160 px au plus | expressions d'Ilya : sources 80 px |
