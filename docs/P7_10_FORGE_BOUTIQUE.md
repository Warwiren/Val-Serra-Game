# P7.10 — Forge C+ et boutique de fournitures

Branche **`p7-10-forge-boutique`** (depuis `p7-9-forge-comparatif`). EN ATTENTE de validation de la cohérence forge /
boutique. Aucun autre bâtiment habillé ; axe du château préservé.

## Forge-armurerie C+ (base de production)

C+ est la forge par défaut de `scenes/p7/ville_v07b.tscn` (`--forge=0` : blockout ; `--forge=A|B` et les scènes
`ville_v07b_forge_a/b/c.tscn` restent pour comparaison). Emprise, dimensions générales, collisions et entrée inchangées.

* **Toit presque noir en C** : non reproductible dans le rendu Compatibilité de ce conteneur (couleur moyenne du toit
  identique en B et en C). Cause probable en Forward+ : en C, le toit (mise à l'échelle non uniforme) était fusionné avec
  les pignons et la cheminée ; la fusion recopie les normales et tangentes sans la transposée inverse, ce qui fausse
  l'éclairage de la carte de normales. Correction : le toit n'est plus fusionné, la transformation reste au nœud.
* **Terre cuite** : copie de la matière des tuiles, albédo plus chaud et moins saturé (rouge baissé), rugosité 0,9, relief
  normal à 0,6 (`forge_p79._terre_cuite`, partagée avec la boutique).
* **Cheminée** : haute souche de pierre sur le versant sud, au-dessus du faîtage, chaperon et gueule sombre.
* **Enseigne d'armurerie** : potence de fer, panneau de bois cerclé, bouclier et deux épées croisées (modèles déjà
  importés), à droite de l'entrée ; remplace l'enseigne générique.
* **Atelier extérieur** sur la plate-forme de la cour (bloc des données inchangé, non accessible) : parement de pierre et
  dallage sur le blockout, appentis de planches sur poteaux contre le mur ouest, foyer ouvert à braises et hotte, enclume
  près du foyer, bac de trempe, établi, meule, râtelier, réserve de tonneaux et de caisses.
* **Baie cintrée** : la grande baie de la façade sud devient `baie_cintree` (nouveau style de `archi_p77.gd` : arc de
  claveaux, petits bois, lueur intérieure) ; rez-de-chaussée relevé à 6,9 m pour la loger. La fonction commerciale reste
  lisible (vitrine éclairée à côté de l'entrée).

## Boutique de fournitures (`scenes/p7/boutique_p710.gd`, `--boutique=0` : blockout)

Même langage hybride, autre silhouette :

| | Forge | Boutique |
|---|---|---|
| Volume | Bas et long, faîtage parallèle à la place | Haut et étroit (3 niveaux, 12,4 m), **pignon face à la place** |
| Murs | Pierre jusqu'au toit, rez-de-chaussée à bossage | RDC pierre appareillée, étages enduits miel, volets verts |
| Toit | Tuiles terre cuite, pente 0,55 | Même terre cuite, pente plus raide (0,7), souche de cheminée |
| Signe | Enseigne d'armurerie, atelier | Potence de grenier avec palan et caisse suspendue, porte de grenier, auvent rayé vert, enseigne verte |

* Entrée fonctionnelle inchangée (x 78, avant-corps, lanternes), sous un auvent de toile verte à 6 m.
* Étal adossé au mur ouest de `bat_commerce_e2` (table, caisses, sacs, tonneau, lanterne murale), hors du passage de la
  porte. **Seule collision ajoutée** : sa boîte basse (x 79,15 → 80, y 89,7 → 92,65).
* Collision du bâtiment : celle des données ; étages et toit en affichage seul. Modèles Quaternius déjà importés
  (`Table_Large`, `Crate_Wooden`, `Barrel`, `Lantern_Wall`, `Roof_RoundTiles_8x12`, `Roof_Front_Brick8`) : aucun import.

## Fichiers

* `scenes/p7/forge_p79.gd` : C+ (toit, terre cuite, cheminée, enseigne, atelier, variante par défaut).
* `scenes/p7/boutique_p710.gd` (nouveau) : boutique.
* `scenes/p7/archi_p77.gd` : style `baie_cintree`.
* `scenes/p7/ville_v07b.gd` : branchement de la boutique, enseigne de la forge C+.
* `src/explore25/routes25.gd` : parcours de contrôle `p7_710_boutique` (aucune capture livrée).

## Appels de dessin (surfaces, hors ombres)

| Zone | Blockout | P7.9 | P7.10 |
|---|---|---|---|
| Forge + cour (x 35,5 → 58,5, y 75 → 88,6) | 34 | C : 67 | C+ : 72 |
| Boutique + étal (x 75 → 89, y 75 → 94) | 28 | — | 58 |

Maillages fusionnés par matière ; le toit de chaque bâtiment est volontairement isolé (2 surfaces). Les ~20 boîtes des
avant-corps d'entrée (code P7.6, communes aux entrées) ne sont pas fusionnées : piste de réduction si nécessaire.

## Tests

| Test | Résultat |
|---|---|
| Tests unitaires | 76 sur 76 |
| Ouverture P6 (`--tuto-rapide`) et saut du tutoriel | réussis |
| `p6_sondes` | 10 sur 10 |
| F5 (`--quit-after 60`), V11 | sans erreur |
| Sondes de la ville `p7_v07b_sondes`, caméras A et B | 40 sur 40 |
| Trajets `p7_v07b_trajets`, A et B | 29 sur 29 |
| Portail ville ↔ Colisée, A et B | 4 passages, 12 points atteints |
| Recouvrements de volumes | 0 |
| Axe du château | dégagé |

## Problèmes connus

* Rendu vérifié en mode Compatibilité seulement : la teinte de la terre cuite et la correction du toit sombre sont à
  confirmer sur votre GPU (Forward+).
* À la caméra de la ville (plongée 11°), le pignon et la potence de la boutique se lisent surtout de loin (ouest de la
  place) ; de près, on voit le rez-de-chaussée, l'auvent et l'étal.
* La façade sud de la boutique reste cachée sous 9,5 m par `bat_commerce_e2` (blockout) ; plate-forme ouest
  `bat_echoppe_no_o` et autres bâtiments encore en blockout.
* L'étal est classé avec le volume de `bat_commerce_e2` pour le masquage : il disparaît avec lui.
