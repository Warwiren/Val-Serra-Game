# P7.10.1 — Refonte artistique de la forge-armurerie

Branche **`p7-10-1-forge-refonte`** (depuis `p7-10-forge-boutique`). EN ATTENTE de validation artistique : rien n'est
déclaré validé. La boutique de fournitures n'est pas modifiée.

Refonte = variante **D** (`scenes/p7/forge_p7101.gd`), forge par défaut de `scenes/p7/ville_v07b.tscn`.
* Avant / après : C+ de P7.10 avec `--forge=C` ou la scène F6 `scenes/p7/ville_v07b_forge_c.tscn`.
* Blockout : `--forge=0`.

Ce qui ne change pas : implantation, emprise (x 44 → 58, y 76 → 88), hauteur des murs (3,5 → 7,5 m), position et échelle du
toit, collisions (bloc des données, piédroits de l'entrée), interaction (examen au seuil), caméra, déplacements, place,
fontaine, Colisée, boutique.

## Modifications

**Entrée (refaite).**
* L'encadrement gris clair est supprimé.
* La porte est dans un **avant-corps de pierre chaude** (x 49,35 → 52,65). Sa saillie de 0,35 m est exactement celle
  des piédroits à collision.
* L'embrasure fait 0,8 m de profondeur : l'avant-corps plus la façade épaisse.
* Arc segmentaire de 11 claveaux alternés, avec sommiers et une clef saillante.
* Piédroits en blocs harpés en retour dans l'épaisseur.
* Glacis sous la corniche.
* **Porte de bois sombre** : douze planches de trois tons qui suivent l'intrados, joint central. Ferrures : pentures à
  extrémité en losange, clous, gonds dans les piédroits, deux anneaux sur platines.
* **Seuil** de pierre usée dans l'embrasure, marche devant, dalle de franchissement du caniveau de la place.

**Façade.**
* Le mur sud est maçonné en **épaisseur réelle** (0,45 m) : la vitrine, la petite fenêtre et la porte sont en retrait.
* Arcs segmentaires appareillés, appuis saillants sur corbeaux.
* Soubassement chanfreiné.
* **Chaînes d'angle harpées** avec retour sur les faces latérales.
* **Corniche sur corbeaux** sous le débord du toit (sud, est, ouest), plus saillante au-dessus de l'avant-corps.
* Pierre de taille chaude en deux tons, sans joints dans la pièce. Mur courant plus chaud et plus irrégulier : pierres
  de réparation, salissures et coulures du matériau du Colisée.
* Face est : fenêtres à barreaux en embrasure plaquée.
* Face ouest : porte de service cintrée vers la cour.

**Toit et pignons.**
* Les pignons de brique Quaternius sont remplacés par des **pignons de pierre** au nu des rives.
* Les tuiles Quaternius sont gardées, avec une nouvelle matière (`src/p7/tuiles_p7101.gdshader`) :
  * terre cuite désaturée ;
  * lichen vert de la texture ramené au gris-brun ;
  * plaques de variation et tuiles délavées en coordonnées monde, contre la répétition ;
  * suie autour de la souche.

**Identité de forge.**
* **Foyer** maçonné adossé au pignon ouest : braises de deux intensités et **hotte de pierre en encorbellement** sur
  deux piles, dessous noirci.
* **Souche de cheminée** qui monte du foyer le long du pignon et dépasse le faîtage, avec mitrons, suie et fumée légère.
* **Lumière orangée** du foyer : une seule OmniLight, sans ombre, portée 5 m.
* Enclume Quaternius sur billot, face au foyer ; bac de trempe ; soufflet ; outils au mur (tenailles, marteaux,
  ringard) ; sol noirci.
* Appentis de planches abaissé sous la corniche.
* Côté place : meule et râtelier d'armes. Réserve réduite : un tonneau et une caisse.
* **Enseigne** en fer forgé à droite de l'entrée : platine, bras, jambe de force, traverse, chaînes. Bouclier ×1,5 et
  épées croisées, lisibles depuis la place.
* Deux lanternes de fer encadrent l'avant-corps.

**Vitrine.**
* Le principe est conservé, en retrait de 0,45 m.
* Carreaux gradués : plus chauds et plus vifs en bas, plus doux en haut et dans l'imposte cintrée.
* Silhouette d'établi derrière les carreaux, petits bois, barreaux de fer dans l'embrasure.

## Correctif après examen (refonte approuvée par le créateur, commit distinct)

Raccord suspect vu depuis l'ouest, sous le bord gauche de la toiture, près du pignon et de l'appentis. Causes trouvées :

1. Le pignon de pierre débordait du mur sans appui, et son pied flottait au-dessus de la corniche.
2. Les corniches sud et ouest s'arrêtaient en décalé à l'angle sud-ouest, ce qui montrait leurs extrémités.
3. La couverture de l'appentis montait jusqu'à 6,9 m contre le mur, en plein dans les corbeaux et la corniche. Elle se
   lisait comme un plan brun uni.

Corrections :

* Les corniches latérales ont 0,42 m de saillie : les pignons sont **assis** dessus, sur toute leur longueur.
* La corniche sud est retournée jusqu'au nu des corniches latérales : angles d'équerre.
* **Finition de rive** : rampants de pierre de taille sous la rive des tuiles, et sommiers au pied des pignons.
* L'appentis est couvert de **tuiles canal**, avec la matière « tuiles » de la galerie B du Colisée teintée sur la terre
  cuite de la forge et des UV en mètres. Dessous : voligeage, planche d'égout, planches de rive.
  * La couverture passe **sous les corbeaux** (6,5 m au mur), et sa pente est plus lisible.
  * La sablière, les poteaux et les chevrons sont recalés.
  * La porte de service est abaissée de 0,25 m pour rester sous la couverture.

Ce qui ne change pas : silhouette et palette du toit, façade, entrée, atelier, lumières, collisions, interactions.

## Fichiers

* `scenes/p7/forge_p7101.gd` (nouveau) : refonte D.
* `src/p7/tuiles_p7101.gdshader` (nouveau) : tuiles.
* `scenes/p7/forge_p79.gd` : variante D par défaut, entrée dessinée par la refonte.
* `scenes/p7/ville_v07b.gd` : boutique active avec C ou D (code de la boutique inchangé).
* `README.md`, `CLAUDE.md`.

Aucun nouvel asset. Modèles déjà importés réutilisés : `Roof_RoundTiles_8x12`, `Anvil`, `Barrel`, `Bucket_Metal`,
`Whetstone`, `WeaponStand`, `Crate_Wooden`, `Shield_Wooden`, `Sword_Bronze`.

## Appels de dessin

Surfaces, hors ombres, dans la zone forge et cour (x 35,5 → 58,5, y 75 → 88,6, au-dessus de 3,4 m) :

| Variante | Surfaces |
|---|---|
| Blockout | 34 |
| C+ (P7.10) | 75 |
| **D** | **52** |

Ajouts hors de ce compte : une lumière omnidirectionnelle sans ombre et un émetteur de 14 particules (fumée).

## Tests

| Test | Résultat |
|---|---|
| Tests unitaires | 76 sur 76 |
| Ouverture P6 (`--tuto-rapide`) et saut du tutoriel | réussis |
| `p6_sondes` | 10 sur 10 |
| F5 (`--quit-after 60`), V11 | sans erreur |
| Sondes de la ville (bords, façades, collisions), caméras A et B | 40 sur 40 |
| Trajets, A et B | 29 points sur 29 |
| Portail ville ↔ Colisée, A et B | 4 passages, 12 points sur 12 |
| Chargement des scènes F6 `ville_v07b_forge_a/b/c` | sans erreur |
| Recouvrements de volumes (masquage) | 0 |
| Axe du château | dégagé |

## Défauts restants

* **Rendu vérifié en mode Compatibilité seulement** (OpenGL sur processeur). À juger sur votre GPU en Forward+ : teinte
  du toit, lumière du foyer, émission de la vitrine, fumée.
* La fumée n'a pas été vue en mouvement ici.
* À l'ouest de la cour, la plate-forme `bat_echoppe_no_o` reste en blockout (hors périmètre).
* Les pignons sont un maillage triangulé fusionné à part : fusionnés avec les boîtes, ils disparaissaient.
* À la caméra de jeu, la souche se lit surtout depuis l'ouest de la place et depuis la cour ; de face, elle dépasse le
  faîtage à gauche.
