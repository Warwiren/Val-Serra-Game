# P5.3 — sols, étape A (sans nouveaux assets) et spécifications de l'étape B

Branche `p5-3-sols`, 21/11/2026. Diagnostic préalable : `docs/P5_3_DIAGNOSTIC_SOLS.md`. Médias : `docs/media/p5_3/`.
Rendu des captures et des mesures : Vulkan **logiciel** (lavapipe, sans anticrénelage), F5 à 24°, ×3 sauf mention.
**Rien n'est validé artistiquement** ; la qualité 4 des ombres reste un **essai** jusqu'à votre test sur GPU.

## 1. Ombres

- **Ombre du terrain rétablie** (P5.2 la coupait). Sans le terrain dans la carte d'ombres, les ombres douces des arbres
  et des personnages se désagrégeaient en points.
- **Filtre des ombres douces du soleil** : qualité 4 à l'essai au démarrage de F5 ; **touche J** : qualité 2 (défaut
  du projet). Réglage global du moteur, remis à 2 en quittant la forêt.
- **Retour arrière** : **touche U** → P5.2 figé (son shader conservé à l'identique, terrain sans ombre) → sol V07
  d'origine. L'état P5.2 exact = U une fois + J (qualité 2).

Grain mesuré dans une même ombre d'arbre sur le chemin (écart à l'image floutée, plus bas = plus propre) :
P5.2 **7,91** → P5.3 qualité 2 **7,16** → P5.3 qualité 4 **5,23** (−34 %). Comparaison visuelle : `ombres_q2_q4.jpg`.

Coût (temps de rendu mesuré par le moteur, ms, **CPU émulant le GPU** : seuls les écarts relatifs ont un sens) :

| Secteur | Zoom | P5.2 (q2) | P5.3 q2 | P5.3 q4 |
|---|---|---|---|---|
| chemin | ×2 | 746 | 782 (+5 %) | 897 (+20 %) |
| chemin | ×3 | 640 | 674 (+5 %) | 709 (+11 %) |
| pente nord | ×2 | 718 | 743 (+3 %) | 822 (+14 %) |
| pente nord | ×3 | 625 | 709 (+13 %) | 753 (+20 %) |
| clairière | ×2 | 747 | 736 (−1 %) | 806 (+8 %) |
| clairière | ×3 | 699 | 695 (−1 %) | 687 (−2 %) |

Lecture : l'ombre du terrain coûte 0 à +13 % ; la qualité 4 ajoute environ +0 à +15 % de plus. Sur un GPU réel, le
filtre d'ombre est peu coûteux, mais **à mesurer chez vous** (touche J, compteur FPS du HUD).
Outil : `tools/p5/perf_ombres.gd`.

## 2. Hachures et motifs noirs autour des arbres, rochers et personnages : origine

Isolés par élimination, au même cadrage (`artefacts_origine.png`) :

| Essai | Les motifs restent ? |
|---|---|
| ombres du soleil coupées | **oui** → pas les ombres |
| silhouettes des personnages masquées | **oui** → pas les silhouettes |
| **occlusion dynamique coupée** | **non : ils disparaissent tous** |

**Cause : le fondu tramé de l'occlusion** (`src/occlusion/fondu_trame.gdshader`). Un tronc ou un feuillage qui cache
un personnage retire une partie de ses pixels selon une trame de Bayer 4 × 4, jusqu'à 60 % (opacité minimale 0,4). Les
pixels gardés d'un feuillage sombre forment une grille régulière de points noirs, qui se lit comme des hachures.
C'est le fonctionnement validé de l'occlusion, pas un défaut d'ombre ni de transparence. Je ne l'ai **pas modifié**
(hors périmètre de l'étape A).

Second artefact, distinct : les **points dans les ombres douces** venaient de l'absence d'ombre du terrain (P5.2). Il
est corrigé (voir § 1).

Pistes pour la trame, à décider après votre test GPU (aucune n'est appliquée) :
1. trame en **bruit bleu** au lieu de Bayer : même principe, sans motif régulier (pas d'« hachures ») ;
2. **anticrénelage temporel (TAA)** sur GPU, qui fond la trame en transparence douce (à évaluer : il peut adoucir le
   pixel art des personnages) ;
3. le repli « alpha » déjà présent dans l'occlusion a été testé : **erreurs de tri** (tronc et feuillage mal
   superposés), non retenu.

## 3. Sols : ce qui a changé (`src/explore25/sol_foret.gdshader`)

Principe : **moins** de bruit fin, plus de logique.
- **Bordures de chemin** : plus de liseré sombre ni de contour net ; bande d'usure où l'herbe se clairsème et jaunit,
  puis plaques de terre (≈ 1 m), puis terre ; irrégularités du bord à grande échelle seulement (3 à 9 m).
- **Usure de l'herbe** : herbe drue (sombre, saturée) ou usée (claire, jaunie) selon la proximité des chemins, les pentes,
  le couvert des arbres et de larges zones ; herbe plus drue au pied des buissons.
- **Pentes** : paliers herbe → herbe clairsemée → terre → roche selon la pente ; le gravier en points a disparu. Un essai
  de strates rocheuses (bandes par l'altitude) se lisait comme des courbes de niveau : retiré.
- **Objets** : pieds en lobes (formes irrégulières calculées par l'angle, sans bruit) ; racines courtes rayonnantes et
  litière sous les arbres ; terre remontée et mousse au pied des rochers ; ombre de contact.
- Supprimés : grain fin, cailloux en points, liseré, micro-relief.

Mesures sur 11 vues, avant P5.2 → après P5.3 (`mesures_sol.json`) :
- **grain fin** (1–2 px) : **−3 à −8 %** sur toutes les vues (aucun bruit ajouté) ;
- **variations moyennes** (2–12 px : taches, transitions) : −1 à +2 % (conservées) ;
- **luminosité moyenne** : identique à ±1 sur 255.

**Combat** : le décor est re-rendu depuis la forêt (même sol P5.3, même ombre du terrain) ; bords du chemin plus doux,
herbe usée le long du chemin (`combat_avant_apres.jpg`, `combat_sol_rapproche.jpg`). Personnages et interface
inchangés.

## 4. Tests réellement exécutés (Godot 4.7.2)

- `tests/p52_sol_smoke.gd` (complété) : 15 / 15 — sol P5.3 au démarrage, ombre du terrain, qualité 4, touches U et J,
  collision du terrain inchangée (90 240 triangles), 97 obstacles, déplacement inchangé (3,19 m en 1,5 s), décor ;
- `run_tests` 71 / 71 ; avant-poste de bout en bout 25 vérifications sans échec ; `p4` 29 / 29 ; `p4_sondes` 20 / 20 ;
- V09A, V09B.5, V09C, V11 (collisions, Vorgane), P5 (combat) : 0 échec ;
- forêt : parcours principal 8 / 9, boucles 6 / 7, course 8 / 9, aucune chute (identique) ; arbres 11 / 11 ;
  occlusion 12 / 12 ; F5 sans erreur.

## 5. Limites restantes

1. **Matière** : herbe, terre et roche restent des aplats nuancés ; sans textures peintes, pas de brins, de terre
   tassée ni de roche lisible de près (étape B).
2. **Roche des pentes** : couleur seule (strates retirées).
3. **Trame de l'occlusion** : motifs réguliers autour des obstacles qui cachent un personnage (§ 2), inchangés.
4. **Bord de chemin** : la bande d'usure suit la carte V07 floue ; la forme générale des chemins ne change pas.
5. Mesures de performance sur rendu logiciel ; à refaire sur GPU.

## 6. Étape B : spécifications définitives des textures peintes

### Échelle et dimensions
- Caméra : 1 m de sol ≈ **125 px d'écran à ×2,5**, 150 px à ×3 (720p) ; 225 px à ×3 en 1080p.
- Densité visée : **256 px par mètre** (plus fine que l'écran au zoom maximal, sans gaspillage).
- Chaque texture : **1024 × 1024 px = 4 × 4 m de sol**.

### Format et canaux
- **PNG 8 bits RGBA**, un fichier par matériau :
  - **RGB = couleur (albédo) en sRGB**, sans lumière peinte (ni ombre portée, ni reflet, ni occlusion directionnelle) ;
  - **A = hauteur** (0 = creux, 255 = sommet), linéaire, non prémultipliée ; c'est elle qui pilote les transitions
    (l'herbe recouvre la terre là où elle est haute).
- Noms : `art/p53/sol/<materiau>.png` (ex. `herbe_drue.png`). Sources (PSD, Krita…) sur le Drive.

### Méthode de mélange
- Le shader garde ses masques actuels (chemin, bande d'usure, pente, objets) et mélange **par hauteur** : pour chaque
  matériau, poids du masque + hauteur ; le plus haut l'emporte avec un fondu court (≈ 0,1). Résultat : des touffes
  d'herbe qui débordent sur la terre, des plaques de terre entre les touffes, sans fondu flou.
- La variation à grande échelle (taches de 3 à 20 m, usure, assombrissement) reste dans le shader ; pas besoin de la
  peindre.
- Projection : vue de dessus (coordonnées monde XZ) sur le sol ; **triplanaire** pour la roche des pentes (la texture
  de roche doit donc tenir vue de côté comme de dessus).
- Anti-répétition : léger décalage et rotation par cellules de quelques mètres (pavage stochastique) dans le shader.

### Import et filtrage dans Godot
- Import « Texture2D », **mipmaps activés**, compression **sans perte** pendant le pilote (puis VRAM haute qualité si
  validé), « Fix Alpha Border » et « Premult Alpha » **désactivés** (l'alpha est une hauteur), `detect_3d` sans
  compression automatique.
- Échantillonnage dans le shader : **linéaire + mipmaps + anisotrope**, répétition activée. C'est un sol 3D, pas un
  sprite : le « pixel net » des personnages ne s'y applique pas.

### Répétition
- Raccord **parfait sur les deux axes**.
- Aucun élément identifiable seul (grosse pierre, fleur isolée, tache) : éléments de **2 à 25 cm** maximum,
  répartition homogène.
- Variation de luminosité interne modérée (±15 à 20 %), pas de dégradé d'un bord à l'autre.

### Palette et niveau de détail (caméra actuelle)
Moyennes visées (sRGB affiché au soleil, mesurées sur le sol actuel) :

| Matériau | Moyenne visée (R, G, B) |
|---|---|
| herbe drue | (75–95, 85–105, 45–55) |
| herbe usée / sèche | (125–135, 112–120, 68–74) |
| terre de chemin, bords | ≈ (112, 86, 58) |
| terre de chemin, centre | ≈ (150, 120, 82) |
| roche de pente | ≈ (122, 118, 108) |
| litière | ≈ (92, 66, 40) |

- Saturation modérée, aucun noir pur (sombres ≥ 25 sur 255), aucun blanc pur.
- Détail : en dessous de 2 cm (≈ 4 px de texture), il disparaît ou scintille ; viser des groupes de brins de 3 à 8 cm,
  des cailloux de 2 à 6 cm, des fissures d'au moins 1 cm d'épaisseur. **Pas de bruit d'un pixel** (il reproduit le grain).
- Style : peint, contours doux, cohérent avec les modèles Quaternius (formes simples, aplats nuancés).

### Pilote (avant le pack complet)
1. `herbe_drue.png`, 2. `herbe_usee.png` (terre visible entre les touffes), 3. `terre_chemin.png` — trois RGBA
1024 × 1024 selon ce qui précède. La transition herbe / terre se fait par les hauteurs : **pas de texture de
transition séparée**. Je les intègre sur une scène de test et en F5 (touche de comparaison), avec les mêmes mesures
qu'ici. Ensuite : roche de pente, litière, puis les planches d'éléments (bordures, pieds d'objets).
