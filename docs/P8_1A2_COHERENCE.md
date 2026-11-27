# P8.1-A2 — Cohérence architecturale après la finition du quartier

Branche **`p8-1a2-coherence`**, depuis `p8-1a-finition-quartier`. Godot 4.7.2. **EN ATTENTE de revue.**

**Cadre conservé** : caméra de ville 11° / 6,5° ; lumière B (second dosage) ; examens E sans saut ; collisions
(151 formes, identiques) ; portails, escamotages et organisation du plan. Forge D, boutique P7.11, tranche P7.6, quartier
civique et grande place : non retouchés, sauf la correction commune des portes et des baies (§ 1), qui passe par le
générateur.

**Interrupteur** : `--f_coherence=0` rend l'état P8.1-A exact (portes, baies, types de façades, plateformes, travées du
Colisée). La végétation dépend du lot existant `--f_vegetation`.

## 0. Contrôle de départ

La dernière réduction de végétation de P8.1-A avait été faite après la série de tests. La série complète
(`bash tools/p8/non_regression_p80c.sh`) a donc été relancée sur l'état final de P8.1-A avant tout changement :
**24 / 24 OK**.

## 1. Portes, seuils et superpositions (P0) — corrigés à la source

La correction est faite **dans le générateur commun** (`Archi._batiment`, `scenes/p7/archi_p77.gd`), et non bâtiment
par bâtiment. Elle vaut pour la tranche P7.6 et pour toutes les fiches de P8.1-A.

### Règles ajoutées

1. **Soubassement interrompu aux portes.** La saillie du soubassement s'arrête de part et d'autre de chaque porte :
   entrées des données (fonctionnelles et décoratives) et baies-portes du rez-de-chaussée.
2. **Porte au sol.** Toute porte de rez-de-chaussée (vantaux, devanture, vitrine) descend jusqu'au sol. Les
   portes-fenêtres d'étage restent sur leur balcon.
3. **Baie bornée sous l'élément du dessus.** Chaque baie, avec son linteau, sa clef ou son arc, s'arrête sous :
   * le bandeau de l'étage suivant ;
   * ou, au dernier niveau, sous la corniche ou ses consoles.
4. **Mur mitoyen aveugle.** Une baie, un balcon ou une lanterne qui tomberait dans un volume voisin est omis.
5. **Porte décorative obstruée.** Une porte décorative dont le devant est occupé par un autre bâtiment n'est pas
   dessinée. Aucune collision n'en dépendait.

### Outil de contrôle

`tools/p8/coherence_facades_p81a2.gd` (lecture seule, `--headless`) tient le registre des emprises de chaque face :
baies, volets, appuis, linteaux, bandeaux, corniches, consoles, chaînes et soubassements. Pour chaque porte, il lance
un rayon vers le sol 0,8 m devant le seuil et cherche un obstacle des données dans le passage.

| Contrôle | P8.1-A (`--f_coherence=0`) | P8.1-A2 |
|---|---|---|
| Superpositions dans le plan d'une façade | **241** | **0** |
| Soubassements traversant une porte | **7** | **0** |
| Portes hors sol (écart de plus de 0,12 m) | **1** | **0** |
| Portes obstruées | **1** | **0** |
| Baies omises sur mur mitoyen | 0 | 476 (toutes sur de vrais murs mitoyens) |

### Portes corrigées

| Porte | Défaut | Correction |
|---|---|---|
| Guilde, entrée (fonctionnelle) | Soubassement devant la porte | Soubassement interrompu |
| Auberge-taverne, entrée (fonctionnelle) | Soubassement devant la porte | Soubassement interrompu |
| `deco_placette_o` (immeuble de la placette) | Soubassement devant la porte | Soubassement interrompu |
| `deco_ruelle_e` (ruelle des Tonneliers) | Soubassement devant la porte | Soubassement interrompu |
| `bat_b_e_ruelle`, devanture sud (bâtiment à volets bleus, près de la jardinière) | Seuil à **0,52 m** au-dessus du sol ; soubassement traversant | Devanture descendue au sol ; soubassement interrompu |
| `bat_b_bras_est_e`, porte ouest | Soubassement devant la porte | Soubassement interrompu |
| `deco_guilde_o` | Donnait sur le mur de l'immeuble de la placette | Non dessinée ; façade pleine |

Le bâtiment à volets bleus près de la jardinière est `bat_b_e_ruelle`. Les portes visibles à 14–21 s dans la vidéo
n'ont pas été identifiées une à une sur la vidéo : la correction s'applique à toutes les portes de la liste. Aucune porte
n'est devenue jouable.

### Superpositions corrigées (241 avant)

| Bâtiment | Superpositions | Nature |
|---|---|---|
| `bat_guilde` | 56 | Baies cintrées dans le bandeau, la corniche et les consoles ; baies d'un niveau sur celles du niveau supérieur |
| `bat_hotel_de_ville_reste` | 52 | Baies dans le bandeau, la corniche et les consoles |
| `bat_auberge_taverne` | 22 | Linteaux et volets dans la corniche et le bandeau |
| `bat_b_o_placette` | 18 | Baies du dernier niveau dans la corniche |
| `bat_b_terrasse_e`, `bat_b_terrasse_e3` | 14 | Baies du dernier niveau dans la corniche |
| Fonds (`paysage_1`, `_4`, `_7`, `_13`, `_16`) | 79 | Rangée haute dans la corniche |

Le bâtiment à volets rouges de la ruelle n'a pas été identifié sur la vidéo ; la règle s'applique à toutes les façades
générées, y compris la tranche P7.6.

Par nature : 150 contre une corniche, 50 contre un bandeau, 27 contre des consoles, 14 baies l'une sur l'autre.

## 2. Variantes de façades (P1)

Quatre types d'immeubles. Chaque type garde une logique structurelle constante sur tout le bâtiment ; les dimensions
varient dans la plage du type selon la graine. Code : `finition_p81.TYPES`, `type_de`, `fiche`.

| Type | Travées | Rez-de-chaussée | Étages | Volets | Couronnement | Enduits |
|---|---|---|---|---|---|---|
| Ordinaire | 2,6 à 2,9 m | Pierre, soupiraux | Fenêtres moyennes | Pleins | Corniche simple | Ocre, gris chaud, rose, terre |
| Aisée | 3,0 à 3,2 m | Bossage | Étage noble plus haut, avec portes-fenêtres sur un balcon filant au centre de la façade sur rue ; étage supérieur plus bas | Persiennes | Corniche à consoles | Crème, miel |
| Commerce | 2,7 à 3,0 m | Devantures et vitrines sur les faces libres | Ordinaires | Pleins | Corniche simple | Miel, ocre, rose |
| Service | 3,4 à 3,8 m | Pierre, soupiraux | Petites fenêtres sans croisée | Fermés | Corniche simple | Gris chaud, terre |

**Attribution** :

| Type | Bâtiments |
|---|---|
| Civique (inchangé) | Guilde, administration, corps de garde, hôtel de ville |
| Commerce | `bat_b_o_placette` (entrée de la ville, sur la placette des Voyageurs) |
| Aisée | `bat_b_terrasse_e` |
| Ordinaire | `bat_b_porche_n`, `bat_b_parvis_o`, `bat_b_faubourg_s`, `bat_b_terrasse_e2`, `bat_b_terrasse_e3` |
| Service | `bat_b_arriere_forge`, `bat_b_faubourg_n` |

**Deux types imposés, justifiés** :
* **Commerce sur la placette.** `bat_b_o_placette` est le seul bâtiment habillé dont toutes les devantures donnent de
  plain-pied sur un sol praticable, sans obstacle. Un essai systématique de chaque bâtiment en commerce avec l'outil de
  cohérence l'a montré : les autres donnent sur le vide, la caravane, les piles du porche, un garde-corps ou l'enceinte
  du Colisée.
* **`bat_b_terrasse_e3` ordinaire**, pour éviter deux maisons aisées accolées sur la terrasse est.

La forge D, la boutique P7.11 et la tranche P7.6 sont préservées.

## 3. Plateformes et socles (P0)

| Élément signalé | Identification | Fonction réelle | Traitement |
|---|---|---|---|
| Grande plateforme claire près du Colisée (vidéo 48–60 s) | `bat_b_parvis_s` (x −10 → 14, y 104 → 112) et `bat_b_parvis_o2` (x −24 → −10, y 100 → 104) : blocs de 1,2 m entre le bord sud du parvis et les immeubles de fond | Aucune. Ces blocs ont été abaissés pour que la caméra passe au-dessus ; ils se lisaient comme une esplanade interdite | **Annexes basses en appentis** adossées au mur aveugle du fond : égout côté parvis, faîtage contre le mur, trois sections variées, parapet de pierre côté parvis. La masse claire quitte le premier plan et ne masque plus Aren. |
| Petits socles de pierre (ouest de la grande place, près de la porte du Colisée) | `bat_b_no_place` (x 36 → 40, y 56 → 76, 0,6 m) | Étals bas (P7.4.2) | **Quai de marchandises** dans le prolongement des quais de la halle et de la cour de la forge, avec caisses, tonneaux et sacs. Pas de marches : la collision ne permet pas d'y monter. |
| Deux socles rectangulaires de la placette des Voyageurs | `tour_sud_o` et `tour_sud_e` : tours de la porte sud, collision de 12 m, coupées en permanence à 1,2 m pour la caméra (P8.0-B) | Tours de la porte de ville | **Non modifiées.** Elles relèvent des fortifications : voir la proposition du § 6, pour P8.1-A3. |

Les autres blocs bas des données ont une fonction déjà lisible et ne sont pas modifiés :
* `bat_b_e_placette` : muret de la rue du chantier ;
* `echoppe_no` et `echoppe_no_o` : halle et étals de P7.13.

**Collisions** : identiques. Aucune surface praticable n'a été ajoutée.

## 4. Végétation (P1)

Code : `scenes/p8/vegetation_p81.gd`, `civique_p712._pots`.

* **Massifs plus bas.** Arbustes de 0,6 à 0,8 m au lieu de 0,9 à 1,1 m (Aren mesure environ 1,7 m). Les arbustes sont
  moins nombreux au fond des jardinières.
* **Variation naturelle** :
  * 14 % de vides, donc plus de masse continue ;
  * couvre-sol mêlé : herbe courte, herbe fine, trèfle, petite fougère ;
  * une nuance de feuillage par massif (trois nuances discrètes, couleurs des fleurs inchangées), pour que deux
    jardinières voisines ne se répètent pas. Les matières nuancées sont partagées : aucun appel de dessin en plus.
* **Belvédère.** La « plante cubique » était le feuillage en cubes des trois pots de terre cuite de la terrasse. Les pots
  sont conservés et reçoivent des plantes du module végétal. Avec `--f_vegetation=0`, les cubes de P7.12 reviennent.
* **Lisibilité.** Les massifs restent dans leurs jardinières : chemins et accès inchangés.

## 5. Colisée (P1)

Code : `finition_p81._travee_p81a2`. Ce sont des retouches locales : arcades, silhouette, entrée publique et enceinte
des données sont inchangées.

* **Parapet à l'étage.** Un parapet plein à tablette ferme le bas de chaque arc de l'étage, comme le garde-corps des
  galeries antiques. Les grands vides sombres de l'étage sont ainsi coupés en deux.
* **Fond des travées du rez-de-chaussée.** L'ouverture du fond, vers les escaliers, est encadrée de pierre de taille.
* **Suite irrégulière de travées particulières**, sans motif répété à l'œil :
  * passages fermés par une grille de fer ;
  * travées murées en retrait, avec une petite porte de service en bois ;
  * niches à statue au fond de la galerie de l'étage.
* **Fond des galeries éclairci.** La galerie reçoit la lumière du sud : il n'y a plus d'aplat noir.

## 6. Fortifications de la porte sud — proposition pour P8.1-A3 (non construite)

### Constat

| Élément | Données | Affichage actuel |
|---|---|---|
| Courtines `rempart_sud_o` / `rempart_sud_e` | x 10 → 53 et x 67 → 120, y 152 → 155 (3 m d'épaisseur), collision de 9 m | Muret coupé à 1,2 m, dessus de pierre |
| Tours `tour_sud_o` / `tour_sud_e` | 4 × 7 m, de part et d'autre d'une baie de 6 m (x 57 → 63), collision de 12 m | Coupées à 1,2 m |

La caméra de ville regarde vers le nord et se tient au sud d'Aren. **Dès qu'Aren est sur la placette des Voyageurs,
l'enceinte sud est entre la caméra et lui.** C'est pour cela qu'elle est coupée en permanence à 1,2 m depuis P8.0-B. Ses
tronçons se lisent alors comme deux socles et un muret, sans fonction défensive.

### Proposition retenue : rempart terrassé sur fossé sec

Val'Serra monte vers le château par terrasses successives. La proposition prolonge cette logique : **la ville est
assise sur une terrasse, et l'enceinte sud en est le mur d'escarpe.**

1. **Courtines.**
   * Côté ville, le sol de la placette est de plain-pied avec le chemin de ronde. Il ne reste donc, au-dessus,
     qu'un **parapet crénelé** de 1,2 m (hauteur actuelle de la coupe) : merlons d'environ 1,4 m de large, créneaux
     de 0,6 m à hauteur d'appui, tablette de pierre de taille.
   * Côté extérieur, la hauteur défensive est donnée **par le bas** et non par le haut : escarpe maçonnée sur un fossé
     sec, d'environ 5 à 6 m sous la placette, avec un talus en pied et un cordon sous le parapet.
   * Le haut du mur ne dépasse donc jamais 1,2 m au-dessus de la placette, et Aren n'est jamais masqué. La face
     tournée vers la caméra peut être haute sans rien cacher, puisqu'elle est sous le niveau de la ville.
2. **Épaisseur et continuité.**
   * L'épaisseur de 3 m des données est gardée telle quelle : 0,6 m de parapet et 2,4 m de chemin de ronde.
   * La courtine est continue de x 10 à x 120 et ne s'interrompt qu'à la porte.
   * Les collisions de 9 et 12 m restent des limites invisibles, sans changement.
3. **Tours.**
   * Tours de flanquement en saillie sur le fossé (vers le sud), au même niveau que la courtine.
   * Plateforme crénelée sur le dessus, archères dans la face extérieure, talus à la base.
   * Le cas échéant, une échauguette basse de 2,4 m au plus, dans le volume d'escamotage existant, sur la tour
     opposée à l'axe de visée seulement.
4. **Porte.**
   * Piles de porte et vantaux ouverts conservés (P8.1-A, L5).
   * **Pont dormant** de pierre sur le fossé, dans l'axe x 60, avec un tablier de bois en avant (pont-levis abaissé).
   * Aucun arc ni châtelet au-dessus de la baie : il serait au premier plan à chaque entrée en ville.
   * L'examen « Porte sud » reste au même endroit, et la sortie reste non reliée.
5. **Raccords.**
   * **Ouest** : entre l'immeuble de la placette (y 150) et la courtine (y 152), une bande de 2 m devient les **lices**,
     fermées par une grille basse, sans collision ajoutée.
   * **Est** : les maisons de la rue du chantier (y 144 → 152) sont **adossées au rempart**, et le parapet ne se voit
     qu'entre elles. Le muret de 0,6 m de `bat_b_e_placette` reste la limite de la rue.
   * **Extrémités** (x 10 et x 120) : retour d'angle de la courtine vers le nord, au contact des masses de fond, sans
     tour d'angle.
6. **Circulation et perspective.**
   * Au départ, la caméra est au-dessus du fossé : on voit le pont, le parapet crénelé, puis la ville qui monte vers le
     château. L'entrée en ville se lit comme le franchissement du pont.
   * Depuis la placette, l'enceinte n'occupe que le bas de l'écran.
   * L'axe du château (x 70) n'est pas concerné.

### Variantes écartées

| Variante | Raison |
|---|---|
| Courtines et tours à pleine hauteur (9 et 12 m), escamotées quand elles cachent Aren | Elles seraient escamotées presque en permanence depuis la placette et au départ. On retrouverait les souches massives au premier plan (P8.0-A2) ou un clignotement aux seuils. |
| Coupe actuelle à 1,2 m, simplement maçonnée | C'est l'état actuel. On garde la lecture « socles et muret » signalée dans le brief. |
| Châtelet à arc au-dessus de la porte | Il serait au premier plan à chaque entrée en ville et masquerait la placette. |

### Lots de P8.1-A3, si la proposition est acceptée

1. Parapet crénelé, tablette et cordon des courtines et des tours (maillages fusionnés par matière).
2. Escarpe, talus et fossé sec avec sa contrescarpe : affichage seul, au sud de y 155.
3. Pont dormant et tablier.
4. Raccords : lices ouest, maisons adossées est, retours d'angle.

**Contrôles** :
* collisions identiques (151 formes) ;
* escamotage et cadrage : Aren jamais masqué ;
* examens E à 0 px ;
* série de non-régression.

**Coût estimé** : environ 60 merlons et quelques dizaines de boîtes, fusionnés, soit 3 à 4 appels de dessin.

**À vérifier en début de P8.1-A3** : ce que la caméra voit au sud de y 157 au départ. Le fond actuel doit pouvoir
recevoir le fossé.

**Décisions attendues du créateur** :
* fossé sec ou en eau (l'eau opaque de la fontaine, `eau_p78`, existe déjà) ;
* échauguette ou non ;
* profil des merlons.

## 7. Contrôles sur l'état final

| Contrôle | Résultat |
|---|---|
| Série complète `bash tools/p8/non_regression_p80c.sh` (24 contrôles) | **24 / 24 OK** (Colisée 10/10, ville 40/40 en caméras A et B, trajets et portails sans blocage, examens E à 0 px en A et B, escamotage et cadrage : Aren jamais masqué) |
| Collisions (lignes « C » de l'empreinte, comparées à la référence de P8.1-A) | **Identiques** : 151 formes |
| Cohérence des façades (`coherence_facades_p81a2.gd`) | 0 superposition, 0 porte hors sol, 0 soubassement traversant, 0 obstacle (19 portes, 94 faces) |

### Coût d'affichage

Mesure en Forward+ avec Vulkan logiciel (lavapipe) : les temps ne sont pas significatifs, seuls les appels de dessin et
les primitives le sont. Rendu en 640 × 360, outil `tools/p7/profil_gpu_p77.gd`.

| Profil | Appels P8.1-A | Appels P8.1-A2 | Primitives P8.1-A | Primitives P8.1-A2 |
|---|---|---|---|---|
| A | 1 694 | 1 664 | 629 515 | 531 917 |
| B | 2 559 | 2 531 | 1 036 147 | 883 230 |

**Aucun coût ajouté.** Les appels baissent un peu (−30 en A, −28 en B) et les primitives d'environ 15 % (massifs plus
bas et moins denses, baies omises sur les murs mitoyens), malgré les annexes, le quai et les travées du Colisée. Le
jugement des performances reste à faire sur votre GPU.

## 8. Fichiers

| Fichier | Rôle |
|---|---|
| `scenes/p7/archi_p77.gd` | Générateur commun : soubassement interrompu, portes au sol, baies bornées, murs mitoyens, registre des façades |
| `scenes/p7/ville_v07b.gd` | Branchement de la cohérence (`_point_libre`, `_entree_obstruee`), types de façades, annexes et quai |
| `scenes/p8/finition_p81.gd` | Types de façades (`TYPES`, `type_de`, `fiche`, `_baie_type`) ; `annexes`, `quai` ; travées du Colisée (`_travee_p81a2`) |
| `scenes/p8/vegetation_p81.gd` | Massifs plus bas, vides, nuances, couvre-sol varié |
| `scenes/p7/civique_p712.gd` | Pots du belvédère plantés |
| `tools/p8/coherence_facades_p81a2.gd` | Contrôle de cohérence des façades et des portes (nouveau) |

## 9. Réserves

* **Murs mitoyens** : 476 baies sont omises sur de vrais murs mitoyens. Certains fonds montrent de ce fait de grands
  pans aveugles ; c'est logique, mais à juger visuellement.
* **Colisée** : la suite de travées particulières est fixe (`TRAVEES_P81A2`). Statues et grilles sont des volumes
  simples de pierre et de fer, sans modèle sculpté.
* **Plantes en pot du belvédère** : plante feuillue ou fleurs, selon la graine de chaque pot.
* Les tours de la porte sud gardent leur aspect de socles jusqu'à P8.1-A3.
