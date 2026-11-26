# P7.9 — Comparatif de la forge-armurerie

Branche **`p7-9-forge-comparatif`** (depuis `p7-8-grande-place-lot1`). Seule la forge est traitée.

## Corrections du lot 1

* Quadrillage secondaire du pavage atténué : bandes de 0,18 m au lieu de 0,28 m, teinte proche du dallage.
* Jets d'eau : chute en deux segments plus épais, écume aux points d'impact, petit jet au sommet.
* Vasques : lèvres plus claires, ombre sous la lèvre, eau plus claire que celle du bassin.
* La géométrie de la fontaine et le dallage sont inchangés.

## Les trois variantes

Ce qui est commun aux trois :

| Élément | Valeur |
|---|---|
| Emprise | x 44 → 58, y 76 → 88 |
| Murs | 3,5 → 7,5 m |
| Entrée | x 51 : piédroits et collisions des données |
| Caméra, lumière | inchangées |

Les accessoires de la cour sont posés sur la plate-forme basse existante, à l'ouest : aucune collision n'est ajoutée.

| | A — bibliothèque du projet | B — Quaternius | C — hybride |
|---|---|---|---|
| Murs | Maçonnerie procédurale du Colisée (bossage, corniche à consoles) | Brique irrégulière gris-bleu (modules de 2 m, hauteur portée de 3,12 à 4 m) | Comme A |
| Toit | Tuiles procédurales : se lisent **presque noires** à 22 m | Tuiles orangées texturées : **très lisibles**, avec pignons enduits | Toit et pignons Quaternius |
| Baies | Grande baie d'atelier éclairée, fenêtre cintrée, barreaux | Baies cintrées à volets ouverts, lueur de forge | Comme A |
| Entrée | Avant-corps de calcaire | Encadrement de brique cintré, vantaux de bois | Avant-corps de calcaire et vantaux Quaternius |
| Cour | Accessoires simples (boîtes, cylindres) | Enclume, établi, meule, tonneaux, caisse, seau, râtelier, bouclier, épée | Comme B |
| Cohérence avec le Colisée et la tranche | Totale (mêmes matières) | Faible : brique froide, autre palette | Bonne (les murs restent ceux du Colisée) |
| Surfaces dessinées dans la zone forge + cour (blockout : 34) | 52 | 51 | 67 |

**Lecture proposée.**
* B est le plus « fini » au premier coup d'œil, grâce au toit et aux accessoires. Mais sa brique gris-bleu rompt avec le
  calcaire ocre du Colisée et de la tranche.
* C prend les deux vrais gains de Quaternius, la toiture et les accessoires, sans perdre la cohérence des murs.
* Le principal défaut de A est sa toiture trop sombre. On peut le corriger dans la bibliothèque (teinte des tuiles), à
  arbitrer.

Je recommande **C** comme direction, sous réserve de votre essai en jeu.

## Modèles Quaternius utilisés

**Réutilisés de P6.3** (aucun doublon) : `Barrel`, `Crate_Wooden`, `WeaponStand`, `DoorFrame_Round_Brick`, `Door_8_Round`.

**Ajoutés** (liste et statut dans `art/p63/quaternius/SOURCES.md`) :
* `mv/` (Medieval Village) : `Wall_UnevenBrick_Straight`, `Wall_UnevenBrick_Window_Wide_Round`, `Wall_UnevenBrick_Door_Round`,
  `Corner_Exterior_Brick`, `Roof_RoundTiles_8x12`, `Roof_Front_Brick8`, `Prop_Chimney`, `Window_Wide_Round1`,
  `WindowShutters_Wide_Round_Open` ;
* `fp/` (Fantasy Props) : `Anvil`, `Workbench`, `Whetstone`, `Bucket_Metal`, `Shield_Wooden`, `Sword_Bronze`.

Textures réduites à 1024², importées avec mipmaps. Licence CC0, aucune dépendance payante.

## Problèmes connus

* Les modules de mur de B sont étirés en hauteur (×1,28) pour garder la hauteur de 4 m de la forge.
* Les arrière-plans de la cour (plate-forme des étals) restent en blockout.
* Les surfaces sont comptées hors ombres, dans la zone x 35,5 → 58,5, y 75 → 88,6, au-dessus de 3,4 m (entrée, cour et
  libellé compris). C est la plus coûteuse (deux familles de matières), mais l'écart reste faible à l'échelle de la place.
* Rendu vérifié seulement en mode Compatibilité (OpenGL sur processeur) : les textures et les normales Quaternius sont à
  juger sur votre GPU en Forward+.
