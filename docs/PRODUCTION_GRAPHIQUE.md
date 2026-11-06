# Production graphique — proposition (arène pilote, puis exploration)

Objectif : faire progresser la **qualité artistique** sans multiplier les versions techniques. Les outils
d'intégration sont prêts ; ce qui manque maintenant, ce sont des **illustrations originales**. Les scripts ne
produiront plus de nouveaux assets « automatiques » tant qu'ils ne dépassent pas nettement l'existant.

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
