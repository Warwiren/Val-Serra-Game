# Production graphique — proposition (arène pilote, puis exploration)

Objectif : faire progresser la **qualité artistique** sans multiplier les versions techniques. Les outils
d'intégration sont prêts ; ce qui manque maintenant, ce sont des **illustrations originales**. Les scripts ne
produiront plus de nouveaux assets « automatiques » tant qu'ils ne dépassent pas nettement l'existant.

## 0. Planches du 6 novembre 2026 — analyse et intégration (branche `decors-illustres`)
Sources conservées intactes dans `art/source/planches_2026-11-06/` (WebP, sans transparence, fond sombre uni ;
ignorées par l'import et l'export). Rien n'a été pixellisé : chaque élément est réduit **une fois**, en qualité,
à sa taille réelle à l'écran, et affiché 1:1.

| Planche | Exploitable tel quel | À séparer / adapter | À redessiner |
|---|---|---|---|
| **4 — Arène « Lisière »** (1590×896) | **Oui** : composition, lumière et finition conformes ; centre dégagé, ligne de sol à la hauteur des combattants. Intégrée en 1296×732 (`tools/arena/import_hd_arena.py`). | Une seule image : pas de vrais plans (parallaxe, avant-plan devant les combattants, lumière par plan). | — |
| **2 — Bâtiments et accessoires** (1194×888) | **Oui pour les accessoires** : lanterne, barriques, caisses, banc, sacs, sections de clôture (découpés, `tools/explore/extract_planche.py`). | Clôtures : vues de face, **cisaillées** pour suivre le tracé en biais du jeu. Caisses et barriques : **empilées** pour recouvrir la place de l'ancien objet dans la façade. | **Maison** : perspective isométrique (~30° de chaque côté, pignon à gauche) incompatible avec la caméra du jeu (35°/20°, façade presque de face) et avec son emprise au sol. Portail, panneau, tableau d'affichage : non placés (pas d'emplacement). |
| **3 — Sols et nature** (1194×884) | **Oui pour les détails** : rochers, herbes, roseaux, fleurs, champignons, cristaux d'Aether, feuilles (posés comme petits éléments triés en profondeur). | — | **Tuiles de sol** et chemin : losanges isométriques (2:1), impossibles à raccorder au sol du jeu. La petite scène en îlot est une illustration, pas un asset. |
| **1 — Arbres et accessoires** (844×844) | **Non** : style cartoon diurne (vert vif, contour épais), différent des trois autres et du crépuscule. | — | Arbres et buissons à refaire dans la DA des planches 2 à 4. |

**Intégré**
- **Combat** : l'illustration remplace le décor du pilote (`--arena=lisiere`, défaut depuis la zone ; F2 compare
  avec l'ancien décor ; `--arena=lisiere-rendu` pour le pilote Blender). Lanternes Godot posées sur les lanternes
  peintes (elles éclairent aussi le Vorgane), lucioles, pas de brume ajoutée (déjà peinte). HUD et combat
  inchangés ; texte de Résonance lisible.
- **Exploration** (défaut ; `--decor=ancien` pour comparer) : 3 lanternes, barriques, caisses, banc et les deux
  clôtures remplacés — mêmes emprises, collisions, tri et transparence locale ; 27 détails au sol (rochers,
  fleurs, herbes, champignons, cristaux près du Vorgane).
- Captures (même cadrage, 1280×720) et vidéo : `docs/media/decors_illustres/`.

**Limites honnêtes**
- **Densité de pixels mélangée** : décor fin (illustration) et personnages en gros pixels (×3 en combat, ×2 en
  exploration). C'est l'esprit HD-2D, mais l'écart est visible ; il se réduira avec les nouveaux sprites.
- **Exploration** : le gain est réel sur les accessoires, mais le **sol, les arbres, les buissons et la maison**
  restent ceux du rendu Blender, qui contrastent désormais avec les accessoires illustrés.
- Les planches sont en WebP compressé : légers artefacts sur les bords des éléments découpés, visibles seulement
  en très gros plan.
- Arène : un seul plan. Pas de parallaxe, pas d'avant-plan qui passe devant les combattants.

**Fichiers réellement nécessaires pour la suite** (même DA que les planches 2 à 4, fond transparent si possible,
PNG sans perte plutôt que WebP)
1. **Arène en calques** (PSD/Krita, 1590×896 ou plus) : ciel + forêt lointaine, lisière (arbre, clôture, maison),
   sol, premier plan (fleurs, rochers, feuillage) — pour la parallaxe et l'avant-plan.
2. **Maison d'exploration redessinée sous la caméra du jeu** : façade presque de face, côté droit étroit, mêmes
   proportions que l'actuelle (porte, deux fenêtres, colombages), à poser sur `docs/media/exploration/hd2d_v3_*`
   comme gabarit ; ≈ 360×360 px à l'écran.
3. **Arbre d'exploration** : tronc et feuillage séparés, ≈ 260×280 px à l'écran, même angle ; puis 2 buissons
   (≈ 80×60, 60×45).
4. **Sol** : une plaque peinte de la zone entière à 1408×800 (×2 du natif), ou 3 textures de sol **sans
   perspective isométrique** (vue de dessus étirée à 35°) qui se raccordent.

## 1. Pourquoi le pilote « Lisière » reste en deçà
- **Limite de méthode** : volumes Blender simples + passe pixel par script. Les feuillages restent des boules,
  les conifères des cônes, les matières (bois, pierre, sol) des bruits procéduraux. Le script ne sait pas dessiner
  une écorce, des feuilles découpées ou des pavés usés : il faut une main.
- **Le plan « avant » est presque vide** (constat de cette revue) : les éléments de premier plan prévus sont hors
  du cadre de la caméra. Il manque donc le cadre sombre et détaillé qui donne la profondeur à l'ancien décor.
- **Densité** : l'ancien décor est une illustration très chargée (fleurs, mousses, lumière peinte) ; le pilote
  est volontairement calme au centre, mais trop pauvre sur les bords.

## 2. Solution proposée : repeindre les plans, un par un, sur la sous-couche existante
La composition, l'échelle, la palette, les lanternes et les marges du HUD sont **déjà validées** par le pilote.
Un illustrateur repeint chaque plan **au même format, par-dessus la sous-couche** ; l'intégration est
automatique (aucun code à modifier) :

```
python3 tools/arena/import_illustration.py lisiere mon_plan_peint.png
```
- Le fichier repeint est réduit si besoin, ramené à la palette commune, sans pixel semi-transparent, et copié
  dans `art/arena/lisiere/peint/lisiere.png`. Le jeu l'utilise **à la place** du plan rendu.
- Le script vérifie que la silhouette du plan est respectée et que les **lanternes n'ont pas bougé** (les lumières
  Godot et l'éclairage du Vorgane en dépendent).
- Comparaison en jeu : `--arena=lisiere` (plans repeints) / `--arena=lisiere-rendu` (rendu seul) /
  `--arena=ancien` ; **F2** pendant le combat (ancien / pilote). Supprimer le fichier `peint/` pour revenir.
- Le circuit a été vérifié de bout en bout (aller-retour identique au pixel, plan repeint chargé par le jeu).

**Ordre de production conseillé (on valide après chaque étape)**
1. **Plan `lisiere`** (le plus visible : grand arbre, sous-bois, rochers, palissade, porte, maison de garde).
   C'est la première illustration à faire : elle seule doit montrer le saut de qualité.
2. **Plan `avant`** : un vrai cadre de premier plan (feuillage sombre en haut à gauche, herbes hautes, pierres et
   fleurs dans les coins bas), sans entrer dans les rectangles des combattants.
3. **Plan `base`** : sol (terre battue, pavés usés, herbe, flaques avec reflets) et ciel.
4. **Plan `loin`** : silhouettes de forêt variées, brume.

## 3. Ressources à fournir — arène pilote
Kit de travail prêt : `docs/media/arena/kit_illustrateur/` (sous-couches natives et ×4, silhouettes, repères du
HUD et des combattants, palette de 56 couleurs). Régénération : `python3 tools/arena/illustrator_kit.py`.

| Fichier à livrer | Dimensions | Contenu | Utilisation |
|---|---|---|---|
| `lisiere.png` | **432×244** (pixel art, recommandé) ou 1728×976 (peinture ×4) | grand arbre de lisière (écorce, racines, feuillage en grappes découpées), sous-bois, 4 rochers moussus, palissade de rondins taillés, porte avec bannière, maison de garde éclairée ; fond transparent | plan moyen, derrière les combattants |
| `avant.png` | idem | cadre sombre : branches et feuilles en haut à gauche, herbes hautes, pierres, fleurs violettes dans les coins bas ; fond transparent ; rien dans les rectangles orange des combattants | devant les combattants (parallaxe inverse) |
| `base.png` | idem, **opaque** | ciel crépusculaire (dégradé violet → bleu nuit, lune discrète en haut à gauche) ; sol : terre battue au centre, chemin pavé usé, herbe, flaques qui reflètent les lanternes, ombres des objets | fond fixe |
| `loin.png` | idem | 2 ou 3 rangées de silhouettes de forêt (feuillus et conifères variés), voile de brume ; fond transparent | plan lointain, parallaxe la plus forte |

Règles : même cadrage que la sous-couche (calques par-dessus) ; lanternes aux mêmes endroits ; lumière froide
de la lune en haut à gauche, accents chauds seulement près des lanternes et des fenêtres ; ombres bleu-violet,
jamais noires ; contours sombres d'1 px sur les silhouettes extérieures seulement ; pas de semi-transparence.
**Livrer les calques séparés** (PSD/Aseprite/Krita) en plus des PNG, pour pouvoir retoucher un élément.

## 4. Exploration — plan limité
Les ressources les plus faibles, par ordre d'impact : les **arbres** (`el_arbre_g` 129×141, `el_arbre_d`
125×106), les **buissons** (`el_buisson_0..4`, 39×33 à 46×38), la **texture d'herbe** du sol (`fond.png`,
points répétitifs), le **muret** du premier plan (`el_muret`, peu lisible). La maison, le chemin et les lanternes
sont acceptables pour le moment.

Kit pilote (format détaillé dans `docs/SPEC_ASSETS_EXPLORATION.md` : projection 35°/20°, 20 px par mètre,
lumière, palette, ancrage) :

| Fichier | Dimensions natives | Remplace | Intégration |
|---|---|---|---|
| `arbre_tronc.png` + `arbre_feuillage.png` | 30×70 et 120×95 | `el_arbre_g` | tronc trié par ses pieds (collision inchangée), feuillage en calque séparé qui devient transparent quand on passe derrière |
| `buisson_a.png`, `buisson_b.png` | 36×24, 28×20 | `el_buisson_0` et `_1` | même position, même tri |
| `sol_variations.png` | 3 tuiles 64×32 raccordables | herbe de `fond.png` | recomposition du fond sous les ombres existantes |
| `herbe_touffes.png`, `pierres.png` | 8 touffes de 6×5 à 10×8 ; 6 pierres de 6×4 à 16×10 | points répétitifs du sol | semis par script (positions reproductibles) |
| ancrages `.json` | — | — | point de contact au sol de chaque élément |

Le script d'intégration de ce kit (tronc et feuillage séparés, recomposition du sol) sera écrit **à réception
du premier arbre**, pour l'adapter au dessin réel plutôt que de deviner. On juge l'arbre en jeu avant de
commander la suite.

**Personnages** : Ilya d'abord (planche au format de celles d'Aren : face, dos, profil gauche, profil droit,
4 images de marche par direction, environ 140 à 190 px de haut sur la planche, fond uni, personnages espacés de
20 px et alignés sur une ligne de sol). Throné et le garde ensuite, au même format.

## 5. Ce qui a été fait sans attendre les illustrations
- Lisibilité du texte flottant « +N Résonance » : contour épais, ombre portée, teinte éclaircie ; il reste
  lisible devant la maison éclairée (`src/presentation/fx.gd`, option `strong`).
- Rien d'autre n'a été produit automatiquement : un nouveau rendu par script n'apporterait pas le saut de qualité
  demandé.
