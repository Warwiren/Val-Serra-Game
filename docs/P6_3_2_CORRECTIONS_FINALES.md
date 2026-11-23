# P6.3.2 — Dernières anomalies d'intégrité visuelle

Branche **`p6-3-2-colisee-corrections-finales`**, issue de `p6-3-1-colisee-integrite-visuelle`.

Sont inchangés :
* Godot 4.7.2 et la caméra du Colisée ;
* le tutoriel et son saut, la progression ;
* les collisions ;
* F5 (forêt). Le Colisée se lance en F6.

L'éblouissement **discret** du tunnel sud est conservé (retenu provisoirement). Ni la ville ni les matériaux généraux
ne sont touchés.

**Capture à la croix bleue** : elle ne m'a pas été transmise (le message ne contenait que du texte). L'ouverture a été
localisée d'après sa description : « depuis l'arène, un sol pavé entre le dos des gradins et un grand mur extérieur ».

Les mesures sont en rendu logiciel (lavapipe), **pas sur GPU**. Il s'agit de corrections structurelles, pas d'une
validation artistique.

## Livrables

| | |
|---|---|
| Ouverture derrière les gradins : avant (masquage actif), avant sans masquage, après | [`arriere_gradins_avant_apres.jpg`](media/p6_3_2/arriere_gradins_avant_apres.jpg) |
| Vue du dessus avant / après | [`vue_dessus_avant_apres.jpg`](media/p6_3_2/vue_dessus_avant_apres.jpg) |
| Porte de la réserve depuis l'infirmerie et depuis la coursive | [`porte_reserve_avant_apres.jpg`](media/p6_3_2/porte_reserve_avant_apres.jpg) |
| Clignotements avant / après, même trajet le long des murs, vitesse réelle | [`clignotements_avant_apres.mp4`](media/p6_3_2/clignotements_avant_apres.mp4) |

## 1. Ouverture derrière les gradins

**Diagnostic.** La même vue, avec et sans masquage, montre la même ouverture : ce n'est **pas** le système de
secteurs. C'est une **lacune réelle de l'architecture**.
* L'anneau ovale des gradins était posé seul dans une enveloppe rectangulaire : le bloc de la salle au sud, la coursive
  à l'est.
* Entre son dos et ces bâtiments, il n'y avait que le sol du parvis, surtout aux quatre coins et le long du sud.

**Correction** (`habillage_p6.gd`, `_ecoincons()`) : un **massif de maçonnerie couvert** remplit ces écoinçons, comme la
substructure d'un amphithéâtre.
* **Terrasse de pierre** : elle prolonge le haut du mur de fond des gradins, **à la même hauteur à chaque angle**. Elle
  n'ajoute donc aucune occultation de l'arène.
* **Façades** : elles ferment l'enveloppe sur son pourtour.
* **Passages dégagés** : les deux tunnels et la loge restent dégagés.
* **Zones concernées** : déjà non praticables. Aucune collision n'est ajoutée ou retirée ; les sondes de collision
  restent à 10/10.

## 2. Porte de la réserve

**Diagnostic.** En P6.3.1, l'encadrement et les vantaux étaient rattachés à la **partie haute** du mur sud de la
coursive (`Secteurs.attacher`). Depuis la coursive, ce mur est devant Aren et coupé en muret : la porte disparaissait
avec lui. Depuis l'infirmerie, le mur est entier et la porte visible.

**Correction** (`_porte_habillee()`, `Secteurs.attacher_coupe()`) : chaque porte fermée a deux états, liés à la coupe
de son mur.
* **Mur entier** : porte entière (inchangé).
* **Mur coupé** : une **porte basse** (encadrement cintré et vantaux ramenés à environ 1,2 m) reste visible au même
  endroit. Elle est clairement identifiable sans masquer Aren (environ 1,7 m).

Les collisions et le verrouillage de la réserve ne changent pas. Le même principe vaut pour les portes de service de
la salle, vues depuis le tunnel.

## 3. Clignotements des murs

**Méthode.**
* **Parcours** `p6_clignotements` : le long des casiers des vestiaires, des murs de la salle et du mur ouest de la
  coursive, en vitesse réelle.
* **Isolation** de chaque cause candidate (`-- --isoler=ombres|occultation|trouee|fondus`).
* **Mesure** image par image (`tools/p6/clignotements_p6.py`) : un pixel « cligne » s'il change nettement puis revient
  à sa valeur à l'image suivante. Le défilement de la caméra n'est pas compté.
* **Recherche statique** des faces confondues (`tools/p6/coplanaires_p6.gd`).

| Variante (avant correction) | Clignotants / image (moyenne) | p95 |
|---|---|---|
| Rendu normal | 831 | 1 463 |
| Ombres coupées | 1 430 | 2 274 |
| Occultation du moteur coupée | 832 | 1 475 |
| Trouée tramée coupée | 831 | 1 463 |
| Fondus de visibilité coupés | 810 | 1 465 (le pic isolé baisse) |

**Ce n'est ni la lumière, ni les ombres, ni l'occultation, ni la trame d'occlusion.** La carte des pixels clignotants
couvre toutes les surfaces texturées, en fines lignes (joints de briques, planches). Deux causes :

1. **Cause principale : textures sans mipmaps.** Les six textures de matières du Colisée (pierre de taille, pavés,
   terre, planches, toit, façade, dans `art/p4/`) étaient importées sans mipmaps. Au zoom ×3, elles sont réduites à
   l'écran, et chaque déplacement de caméra d'une fraction de pixel fait sauter le motif d'un texel à l'autre : c'est le
   scintillement des joints. Le shader demande un filtrage mipmap, mais ceux-ci n'existaient pas.
   * Correction : `mipmaps/generate=true` dans leurs fichiers `.import`.
   * Ces textures servent aussi à la démo de l'avant-poste (P4), qui en profite. La forêt a ses propres textures et
     n'est pas concernée.
2. **Faces confondues dans les murs**, de même orientation et dans le même plan (z-fighting) :
   * la face extrême des pilastres coïncidait avec celle du mur ;
   * aux angles, plinthes, corniches, bandeaux, chaperons et tranches de deux murs perpendiculaires tombaient dans le
     même plan ;
   * là où deux murs de pièces voisines se chevauchent, une face d'extrémité tombait dans le plan de l'autre mur.

   Correction (`_mur_continu()`) : moulures des murs nord-sud décalées de 7 mm, pilastres dépassant de 3 cm, corps des
   murs nord-sud prolongés de 7 mm. Les paires de faces confondues entre murs passent de 384 à 168 ; celles qui restent
   sont cachées sous les chaperons.

**Résultat** : 831 → **424** pixels clignotants par image en moyenne, 1 463 → **863** au 95e centile. Les murs, la
moitié haute de l'image, sont nets.

Le **filtrage anisotrope** a été essayé puis **écarté** : il aggrave la mesure (480), en rendant les joints plus nets.
Les ombres douces (qualité 4) et la trame d'occlusion validée ne sont pas modifiées.

**Reste** : un scintillement résiduel sur les sols vus en angle rasant (planches, pavés). Il relève des matériaux et
de la résolution des textures, donc de P6.4. Le pic isolé de la mesure correspond à la téléportation du parcours de
test, pas au jeu.

## Vérifications

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel` | réussis |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` | réussis |
| Sondes de collision `p6_sondes` | 10 / 10 |
| Passages dans les deux sens (`p6_video_631` : seuils, tunnels, infirmerie) | 0 bond de caméra, aucun blocage |
| Circulation à une touche | 4 tronçons, 0 % de contact mural |
| Reliefs visibles traversables | aucun |
| F5 | se charge sans erreur |

## Décision attendue

Les trois anomalies sont traitées, et les corrections structurelles s'arrêtent ici. P6.4 (matériaux, éclairage,
direction artistique HD-2D) n'est pas lancée.
