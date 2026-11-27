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

## 4. Réalisé (27/11)

| Lot | Commit | Contenu | Option de comparaison |
|---|---|---|---|
| Inventaire | `7024d72` | Ce document, § 1 et 2 | — |
| L1 sols et soutènements | `d9f3575` | Sols des données, sol hors les murs, terrasses, masses de terrain, garde-corps : dallage de la grande place et soutènement sali du quartier civique | `--f_sols=0` |
| L2 Colisée | `02f022f` | Façade à arcades réelles (2 registres, 28 travées, attique, couronnement, bannières) ; propylée et porte en pierre et bois | `--f_colisee=0` |
| L3 bâtiments | `7e3a245` | Bâtiments secondaires, Guilde, reste de l'hôtel de ville et 19 fonds habillés par fiche (`archi_p77`) ; socles bas ; encadrements d'entrée | `--f_batiments=0` |
| L4 végétation | `00e81b7` | Module végétal (modèles CC0 de la forêt, vignes grimpantes) branché sur toutes les jardinières | `--f_vegetation=0` |
| L5 limites | `3d61029` | Porte sud (tours, remparts, vantaux), barrières de planches, chantier, prolongements vers les faubourgs et l'est | `--f_limites=0` |
| L6 étals | `7c2a4f5` | Marchandises en modèles Fantasy Props (épices, poteries, fruits, fleurs), sacs de la halle | `--f_etals=0` |

* **Tout couper** : `--finition=0` redonne exactement P8.0-C (empreinte de scène identique, MD5).
* **Mutualisation utile** : trois modules seulement.
  * `scenes/p8/finition_p81.gd` : matières partagées, sols, façade du Colisée, **fiche de bâtiment générée**,
    remplacement de matière sans toucher à la géométrie.
  * `scenes/p8/vegetation_p81.gd` : massifs, pots, vignes.
  * `bordures_p713._marchandises_modeles`.

  Aucune réécriture des générateurs existants. La forge D, la boutique P7.11, la tranche P7.6, le quartier civique et
  la grande place ne sont pas modifiés. Seuls changent : la jardinière commune (déléguée au module végétal) et le reste
  de l'hôtel de ville, laissé en blockout par le civique.
* **Ressources** :
  * aucun achat ;
  * 3 vignes (Medieval Village) et 10 marchandises (Fantasy Props) importées depuis les archives CC0 du Drive du projet ;
  * végétation réutilisée telle quelle depuis la forêt F5 ;
  * provenance dans `art/p63/quaternius/SOURCES.md`, statut PROVISOIRE.
* **Géométries encore en matière de blockout** : 775 en P8.0-C, 157 maintenant. Le reste est hors des parcours :
  château de la V0.6 relégué à 250 m, toits lointains, reliefs d'horizon.

## 5. Contrôles

`bash tools/p8/non_regression_p80c.sh` sur l'état final : **24 / 24 OK**.

| Contrôle | Résultat |
|---|---|
| Scène F5 (forêt), 76 tests unitaires, tutoriel et saut du tutoriel | OK |
| Sondes du Colisée | 10 / 10 |
| Ville : sondes, trajets, portail ville ↔ Colisée, en caméra A et B | 40 / 40 ; 0 étape bloquée ; 4 passages |
| Examens E | **0 px**, lumière A et B |
| Profils de lumière A / B et F4 | OK |
| Escamotage | Aren jamais masqué, aucun clignotement |
| Cadrage (6 parcours) | Aren jamais masqué |
| Tests smoke (forêt, animations, sols, combat) | 0 échec |

* **Collisions** : les 151 formes de la ville sont identiques à P8.0-C après chaque lot (empreinte de scène).
* **Retour à P8.0-C** : avec `--finition=0`, l'empreinte complète est identique (MD5).

## 6. Coût d'affichage (à mesurer sur votre GPU)

Moyenne des 10 points de vue de `profil_gpu_p77.gd`. Ces chiffres ne dépendent pas de la machine. Les temps mesurés dans
le conteneur (Vulkan logiciel) ne sont **pas** reportés.

| Profil | Appels de dessin P8.0-C → P8.1-A | Primitives P8.0-C → P8.1-A |
|---|---|---|
| A | 1 350 → **1 694** (+25 %) | 249 k → **630 k** |
| B | 2 070 → **2 559** (+24 %) | 408 k → **1 036 k** |

**Répartition des triangles ajoutés** (scène chargée, sans ombres) :
* massifs végétaux : environ 124 k. L'arbuste compte 900 triangles par pied ; le trèfle et la seconde variété de fleurs
  ont été rendus plus rares ;
* façades par fiche : environ 130 k pour une cinquantaine de bâtiments et fonds ;
* marchandises : environ 40 k (cagettes de 4 000 à 5 000 triangles chacune) ;
* façade du Colisée : environ 9 k.

**Si le budget GPU est dépassé** : un lot se coupe seul (`--f_vegetation=0`, `--f_batiments=0`…) pour mesurer son coût.
Les leviers sans refonte sont :
* massifs moins denses (pas des rangs dans `vegetation_p81.garnir`) ;
* fonds sans flancs (`fiche`, genre « fond ») ;
* lumière B en 2 tranches d'ombre (`--b_tranches=2`).

**Commandes** (comme en P8.0-C), à comparer avec `--finition=0` :

```bash
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_p81_B.csv --lumiere=b
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_p80c_B.csv --lumiere=b --finition=0
```

## 7. Réserves et suite

* **À juger par le créateur** : tout est PROVISOIRE.
  * Les fiches génériques donnent une qualité homogène, mais **pas** le niveau des références forge D et boutique P7.11.
    La Guilde, future instance, mériterait un lot dédié, sur le modèle de la forge.
  * Plant_1 (feuilles larges) est à juger dans la cité.
  * Le dallage des rues reprend celui de la grande place : un motif plus petit pour les ruelles pourrait être utile.
* **Non traité (P2)** :
  * variations d'usure par façade ;
  * bordures de pierre aux changements de dallage ;
  * pots et enseignes secondaires ;
  * blockout lointain résiduel (château de la V0.6 à 250 m, toits d'horizon).
* **Inchangés, comme demandé** :
  * caméra, lumière, plan, collisions, interactions, occultation ;
  * forge D, boutique P7.11 (étal compris), Colisée intérieur, grande place et fontaine, quartier civique validé.
* **Avant P8.2 (habitants)** : relire les emplacements de PNJ (`emplacements_pnj`) au regard des nouveaux massifs et
  étals. Aucun emplacement n'a été déplacé.
