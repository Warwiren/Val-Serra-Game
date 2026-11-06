# Spécifications des assets à illustrer : exploration HD-2D

Ce document décrit des assets de petite taille, à dessiner pour remplacer les éléments provisoires de la zone de
test `scenes/explore_hd2d/`. Une fois livrés au format ci-dessous, ils s'intègrent par script, sans modifier le code.

## Règles communes
- **Projection** : la même pour tous les assets. Vue de trois-quarts surélevée, plongée de **35°**, caméra
  tournée de **20°** vers la droite. Un cube de 1 m montre son dessus aplati, une grande face avant et une
  face latérale droite étroite.
- **Échelle** : **20 px natifs par mètre** au sol. Une hauteur verticale de 1 m vaut ≈ 16 px (cos 35°).
  Repères : Aren mesure 28 px de haut, une porte ≈ 34 px.
- **Affichage** : ×2 au plus proche voisin (1280×720). Il faut dessiner à la taille **native**, sans
  agrandissement ni flou. PNG RGBA, fond transparent, aucun pixel semi-transparent sauf les ombres.
- **Lumière** : crépuscule. La lune froide (bleu-blanc) vient du **haut à gauche**, un contre-jour violet vient
  du fond, et les accents chauds (orange) ne figurent que du côté des lanternes. Les ombres sont teintées
  bleu-violet, jamais noires pures.
- **Contour** : 1 px sombre (≈ #10101E) sur la silhouette extérieure seulement. Les détails intérieurs sont
  marqués par des valeurs, pas par des traits.
- **Palette** : 32 à 40 couleurs au plus pour l'ensemble du kit. Les feuillages vont du vert-bleu sombre
  (#14262A) au vert clair froid (#8CA070), avec des reflets de ciel discrets (#8C8AA8).
- **Ancrage** : chaque fichier est accompagné du point de contact au sol (pied du tronc, base de la pierre), en
  pixels, dans un fichier `.json` ou dans le nom du fichier.

## Kit de végétation (premier lot de test)
| Asset | Taille native indicative | Contenu | Remarques |
|---|---|---|---|
| `arbre_tronc.png` | 30×70 | tronc, départs de branches, racines | la base du tronc sert de ligne de tri et de collision |
| `arbre_feuillage.png` | 120×95 | feuillage en **grappes de feuilles dessinées** (5 à 8 masses, bords découpés en feuilles, trouées laissant voir le ciel ou les branches) | calque séparé, posé sur le tronc ; c'est lui qui devient transparent quand un personnage passe derrière |
| `buisson_a.png`, `buisson_b.png` | 36×24, 28×20 | buisson rond, buisson bas fleuri (fleurs violettes) | pas de collision : on passe devant ou derrière |
| `herbe_touffes.png` | planche de 8 touffes, 6×5 à 10×8 chacune | touffes d'herbe hautes | posées en semis sur le sol |
| `pierres.png` | planche de 6 pierres, 6×4 à 16×10 | pierres et galets avec mousse | ombre portée de 1 px vers le bas à droite |
| `sol_variations.png` | 3 tuiles de 64×32 | herbe rase, herbe et terre, mousse | se raccordent sans couture (tuiles) |

Je ne peux pas produire ce feuillage dessiné à la main de façon convaincante avec les outils actuels. Les essais
par script (grappes posées sur un volume 3D) gardent des volumes ronds de rendu 3D. Ces assets sont donc à
créer séparément.

## Production d'un compagnon : Ilya (pilote)
Même format que les planches d'Aren déjà intégrées (`art/proto/source/aren/`), découpées par
`tools/art/aren_sheets.py` :
- **Exploration** : repos face, dos, profil gauche et profil droit ; marche en 4 images pour chacune des
  4 directions. Dessin au format illustré (environ 140 à 190 px de haut sur la planche), sur fond uni sombre,
  personnages espacés d'au moins 20 px, alignés sur une ligne de sol.
- **Combat** (lot suivant) : repos, préparation, attaque aux dagues, impact, retour, garde, touché.
- **Identité à conserver** : cheveux argentés longs, tenue rouge sombre et cuir, dagues jumelles ; mêmes
  proportions et même finition qu'Aren.
- **Réglage d'intégration** : seuls les rectangles des bandes changent dans le script. Ilya sera réduite à
  ≈ 26 px de haut en exploration, puis retouchée avec la même méthode qu'Aren (yeux, frange, contours).
