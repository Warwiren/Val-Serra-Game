# P8.1-A — Finition du quartier avant les PNJ

Branche **`p8-1a-finition-quartier`**, depuis `p8-0c-consolidation`. Godot 4.7.2.

**Cadre conservé** :
* caméra de ville à 11°, plongée civique à 6,5° ;
* quartier civique, Colisée (intérieur), forge D, boutique P7.11 ;
* lumière B, second dosage ;
* plan, passages, trois niveaux, collisions, interactions E, occultation.

**Interdits** : aucun PNJ, aucun système de gameplay, aucun achat d'asset.

## 1. Inventaire priorisé (audit du 27/11)

### Méthode

* **Mesure objective** : relevé de toutes les géométries de la ville encore rendues avec le shader de blockout
  (`blockout_p7.gdshader`), regroupées par volume. Le script de relevé est un outil de travail, non versionné.
* **Examen visuel** : 23 points de vue le long des parcours de la dernière vidéo, en Forward+ et lumière B, caméra de
  jeu. Les images ont servi à l'examen seulement et ne sont pas livrées.

### Priorité P0 — masses provisoires majeures, identité cassée

| # | Secteur | Élément (données / code) | Constat | Remplacement proposé | Lot |
|---|---|---|---|---|---|
| P0-1 | Partout (placette, parvis, rue du Colisée, rue du chantier, terrasse de l'auberge, terrasses) | Dessus et flancs des masses de terrain (`ville_v07a._masses`, `MUR_SOUT`) | Grandes surfaces grises quadrillées (sols) ; soutènements gris-bleu à cordon blanc (volées A/B, placette, fond de la place) | Dessus en dallage de pierre (matière `dallage2` de la place, teinte par niveau) ; flancs en maçonnerie de soutènement (`socle2`), couronnement de pierre (`moulure`) | L1 |
| P0-2 | Parvis du Colisée, grande place (ouest) | Tambour extérieur du Colisée (`ville_v07a._colisee_v07`) | « Immense façade noire quadrillée » : cylindre de blockout et 88 panneaux noirs plaqués | Façade à **arcades réelles** : mur du tambour en retrait, piles et arcs en saillie, cordons et attique de pierre du Colisée ; ombres portées dans les arcades au lieu d'aplats noirs | L2 |
| P0-3 | Placette des Voyageurs | `bat_b_o_placette` (immeuble blanc), `bat_guilde` (volume bleu) | Volumes de blockout à fenêtres peintes, à l'entrée de la ville | Façades par la bibliothèque `archi_p77` (fiche de données, comme la tranche P7.6) : RDC de pierre, étages enduits, baies, toit de tuiles. Guilde en calcaire clair civique ; entrée, porte et bannières conservées | L3 |
| P0-4 | Parvis du Colisée, rue du Colisée | `bat_b_parvis_o`, `bat_b_parvis_o2`, `bat_b_parvis_s`, `bat_b_faubourg_n/s` | Immeubles blancs schématiques, socles bas gris | Même habillage par fiche ; socles bas en murets de pierre | L3 |
| P0-5 | Terrasses civiques | `bat_hotel_de_ville` (reste), `bat_b_terrasse_e`, `_e2`, `_e3`, `bat_b_porche_n`, `bat_b_arriere_forge` | Façades blanches à fenêtres peintes, bannières rouges | Même habillage, en calcaire civique pour l'hôtel de ville | L3 |
| P0-6 | Fonds de tous les secteurs | 19 volumes « paysage » | Gradins de volumes de blockout à toits simples | Habillage simplifié par fiche : enduit, RDC de pierre, rangées de baies, tuiles ; densité réduite au loin | L3 |
| P0-7 | Placette (porte sud) | `tour_sud_*`, `rempart_sud_*` (muret de 1,6 m coupé à 1,2 m) | Flancs gris-bleu de blockout ; dessus déjà en pierre (P8.0-B) | Flancs en maçonnerie de rempart | L5 |
| P0-8 | Limites du quartier | `barriere_fin_de_carte` (placette sud, rue du chantier) | Barres jaunes de blockout au premier plan | Limites crédibles, sans collision ajoutée : barrière de chantier en planches et tréteaux, charrette de livraison | L5 |

### Priorité P1 — végétation, accessoires, mobilier

| # | Secteur | Élément | Constat | Remplacement proposé | Lot |
|---|---|---|---|---|---|
| P1-1 | Placette, rue du chantier, terrasses civiques, palier, belvédère | Jardinières (`Archi.jardiniere`) et pots : arbustes en **amas de sphères** (`_spheres`) | Non validés : formes rondes répétées, couleurs artificielles | **Vocabulaire végétal réutilisable** : arbustes, plantes, fougères, groupes de fleurs, trèfle, vigne grimpante. Modèles Quaternius CC0 déjà validés dans la forêt F5, plus 3 vignes du pack Medieval Village. Variations d'échelle et de rotation, teintes recalées sur la palette de la ville | L4 |
| P1-2 | Grande place : étals 0 à 3, étal de la boutique | Marchandises en cylindres et boules colorés (`bordures_p713._etal_*`) | Géométriques et répétitives | Marchandises reconnaissables du pack Fantasy Props : cagettes de pommes et de carottes, tonneau de pommes, sacs, bourses, pots, vases, seaux, cordages, bouteilles. Peu d'objets, bien choisis, par étal | L6 |
| P1-3 | Fontaine, halle, mobilier du belvédère | — | Corrects ; à vérifier après L6 | Retouches ponctuelles seulement si nécessaire | L6 |

### Priorité P2 — finition, variations

| # | Élément | Proposition |
|---|---|---|
| P2-1 | Variations de teinte et d'usure des façades secondaires | Graine par bâtiment dans la fiche (palette, volets, hauteur d'appui) |
| P2-2 | Raccords de sols (seuils, bordures entre dallages) | Bordures de pierre aux changements de matière |
| P2-3 | Plantes grimpantes et pots aux façades, enseignes secondaires | Sur les façades vues de près seulement |

### Déjà au niveau (non modifié)

* La tranche P7.6 (auberge, ruelle, maison du bras est), la forge D, la boutique P7.11.
* La grande place (dallage, fontaine), le quartier civique (administration, corps de garde, porte fortifiée, ville
  haute), le belvédère et la buvette.

## 2. Ordre des lots (un commit par lot, tests après chaque lot important)

1. **L1** : sols et soutènements (P0-1). C'est le plus grand gain, partout à la fois.
2. **L2** : façade extérieure du Colisée (P0-2).
3. **L3** : habillage des bâtiments secondaires et des fonds par fiche de données (P0-3 à P0-6). C'est la mutualisation
   utile : un module, des fiches.
4. **L4** : vocabulaire végétal (P1-1).
5. **L5** : limites du quartier et porte sud (P0-7, P0-8).
6. **L6** : marchandises et accessoires de la grande place (P1-2, P1-3).

## 3. Règles de production

* **Collisions** : rien n'est ajouté ni retiré. Le décor reste dans l'emprise de son obstacle.
* **Escamotage** : tout ce qu'un bâtiment dessine reste rattaché à son volume. Il est classé par position ou par la méta
  `vol`, et le contrôle d'escamotage doit rester à 0 image masquée.
* **Draw calls** : les maillages sont fusionnés par matière et par bâtiment (`Archi.fusionner`, `_fusion_gltf`). Le
  surcoût est mesuré avec `profil_gpu_p77.gd`.
* **Comparaison** : chaque lot a une option pour revenir à l'état P8.0-C, avec `--finition=0` pour tous les lots.
* **Contrôle** : `bash tools/p8/non_regression_p80c.sh` après chaque lot important.
