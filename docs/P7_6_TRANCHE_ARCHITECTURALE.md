# P7.6 — Consolidation du blockout V0.7-B et première tranche architecturale

Branche **`p7-6-tranche-architecturale`**, créée depuis `p7-5-ville-v07b`.

La V0.7-B reste la référence générale de la ville et le plan n'est pas refait. La tranche est un **pilote en attente de
votre examen** : ses matières et ses façades ne s'étendent pas au reste de la ville. Aucun nouveau système de jeu, aucune
instance, aucun intérieur.

| Commit | Contenu |
|---|---|
| `d4bbfab` | A1 — Colisée : sortie intérieure par un vestibule, porte de la ville au sud |
| `a59f691` | A1 (côté ville), A2, A3, A4 — arrivée devant les portes, portail dégagé, faux passage fermé, anomalies d'affichage |
| `624b978` | B — entrées des bâtiments (fonctionnelles et décoratives), plan des portes |
| `e68e579` | C — tranche architecturale, escamotage des volumes proches, médias et ce rapport |

## A1. Sortie intérieure du Colisée

**Avant.** La porte de la ville était au bout d'un couloir, à droite, dans le noir.

**Après.**
* Le couloir de sortie est raccourci (x 56 à 58,5). Il débouche sur un **vestibule** (x 58,5 à 63,5, y 21,5 à 28,5) dont la
  porte est dans le **mur sud** : on la rejoint en **descendant à l'écran**.
* La porte a un encadrement de calcaire et un linteau, des battants ouverts rabattus contre le mur (solides) et une tache de
  jour sur le seuil.
* Le déclencheur `sortie_est` est sur le seuil, au-delà de la porte. Le portail `colisee_porte_publique` est inchangé.
* **Cohérence avec l'extérieur** : on sort du bâtiment à son extrémité est, vers le sud. C'est la situation de la porte
  publique de la ville, dans l'arche sud du propylée, contre la façade est du tambour.
* Retour en ville : Aren apparaît **directement devant les grandes portes**, sur le perron (30,45 ; 68,9), **tourné vers la
  ville** (le sud : l'allée et la grande place).
* Entrée inverse : arrivée dans le vestibule (61 ; 26,8), tourné vers l'intérieur, hors du déclencheur.

Rien d'autre ne change dans le Colisée : le garde de la porte, la porte fermée pendant le tutoriel, le secteur S9 (étendu
au vestibule) et ses collisions.

Médias : `a1_sortie_colisee_avant_apres.jpg`, `a1_arrivee_devant_les_portes.jpg`.

## A2. Dégagement du portail extérieur

Le « volume brun » était un bloc d'étals de 0,6 m dont l'angle nord-ouest touchait le passage entre l'allée et le perron.
* Il est **abaissé à 0,45 m**.
* Sa partie ouest **recule de 3 m** vers le sud.
* L'angle libéré (6 × 9 m) devient praticable, au niveau du perron. Le parvis n'est pas agrandi au-delà.

Média : `a2_portail_avant_apres.jpg`.

## A3. Faux passage

**Identification.** En tête de la ruelle des Tonneliers (le premier escalier de la visite), le bras est de la place se
prolongeait de 2 m vers l'est (x 84 à 86). Il aboutissait entre deux volumes de décor sans collision : un vide où la rue
**semblait continuer vers la droite**, mais où une limite invisible arrêtait le joueur.

**Correction.** Ce n'est pas une connexion prévue (les accès futurs sont A, B et C). La géométrie est donc corrigée :
* le bras est s'arrête à x 84, dans l'alignement de la ruelle ;
* un **vrai bâtiment** à collision (x 84 à 98, deux niveaux) ferme le bout ;
* aucune collision invisible.

## A4. Anomalies d'affichage — causes confirmées

Chaque cause a été vérifiée par un essai avant d'être corrigée. Diagnostics :
* bascules `--sans_proche` (sans la trame des volumes proches), `--sans_ombres` et `--sans_cordons` ;
* outils `tools/p7/camera_volumes_p76.py` et `tools/p7/camera_offset_p76.gd`.

| Anomalie | Cause confirmée | Preuve | Correction |
|---|---|---|---|
| **Ligne claire en pointillés** sur toute la façade du Colisée (vue de la ville) | Couvercle supérieur des **cordons** du tambour : des anneaux de 96 facettes, 1,2 % plus larges que lui, dont le bord n'apparaissait que par morceaux | La ligne **reste sans les ombres** et **disparaît sans les cordons** | Cordons sans couvercles (tambour et couronnement gardent les leurs) |
| **Bandes et toits qui percent des façades** | **7 recouvrements** de volumes (emprises et hauteurs superposées) : toit du faubourg nord dans la façade du parvis, faces confondues au fond de la rue du chantier, deux tours noyées dans des bâtiments, et un volume de décor **flottant à 8 m** au-dessus du perron | Outil de recouvrements : 7 → **0** | Volumes séparés ; volume flottant posé au niveau de la place ; tours invisibles retirées |
| **Tramage et transparence des volumes proches** | La caméra est **dans** un bâtiment ou contre lui sur **1 130 des 5 016 points praticables** (Guilde : 408, auberge, décor du parvis). La trame de P7.3 (« proche », 12 m) ne les cachait qu'à moitié, et des écrans tramés couvraient la rue | Outil caméra / volumes, sur tout l'espace praticable (pas d'1 m) | **Escamotage des volumes** : voir ci-dessous |

**Escamotage des volumes** (V0.7-B seulement ; `--coupe_ville=0` rend la trame d'origine) :
* chaque volume bâti regroupe ses maillages, classés par emprise comme les secteurs du Colisée ;
* il est masqué **en entier** quand la caméra est dedans ou le frôle (2,6 m) **et** qu'il se trouve entre elle et Aren ;
* une hystérésis (4 m) évite le clignotement ;
* les façades latérales restent pleines ; aucune collision ne change ;
* le trou d'occlusion autour d'Aren (validé) est inchangé.

**Deux essais écartés (non retenus).**
* **Plan proche de la caméra reculé à 11 m** : il évidait aussi les façades latérales de la ruelle.
* **Noyaux sombres de coupe** : quand la caméra est dans un volume, ils obscurcissent l'écran.

Le premier reste disponible en comparaison : `--near_ville=11`.

Médias : `a4_anomalies_avant_apres.jpg`, six lieux.

## B. Entrées des bâtiments

Les entrées sont décrites en données (`ENTREES` dans `tools/p7/build_ville_v07b.py`) et toutes placées sur des façades sud,
face à la caméra.

**Entrées fonctionnelles**, chacune réservée à une instance future :

| Bâtiment | Instance future |
|---|---|
| Guilde | `guilde_interieur` |
| Auberge-taverne | `auberge_interieur` |
| Forge-armurerie | `forge_interieur` |
| Boutique de fournitures | `boutique_interieur` |
| Hôtel de ville | `hotel_de_ville_interieur` |

Chacune comporte :
* un avant-corps de calcaire en saillie, dont les piédroits ont une collision réelle ;
* des battants ferrés en retrait, un emmarchement et des lanternes (verre émissif, aucune lumière ajoutée) ;
* une enseigne propre au bâtiment : bannières pour la Guilde et l'hôtel de ville, enseigne en potence pour les commerces.

Un **examen** au seuil (E) annonce l'entrée et l'intérieur à venir. Il n'y a ni transition ni intérieur.

**Portes décoratives** : six, fermées, affleurantes, sans interaction.

**Inchangés** : l'accès gardé du château (grille, gardes, guérites), la caravane des faubourgs (B), le chantier du quartier
est (A) et la porte sud.

Un étal masquait la porte de la boutique : il est déplacé dans le recoin.

Médias : `plan_portes_v07b.png` (plan des portes, accès A, B et C, porte du Colisée) et `b_entrees_batiments.jpg`.

## C. Tranche architecturale (pilote)

**Lieu : l'îlot de l'auberge-taverne et la ruelle des Tonneliers**, raccordés à la grande place par le bras est.

| Demande | Réalisation |
|---|---|
| Petite rue montante | La ruelle des Tonneliers (4 m de large), du pied de la terrasse de l'auberge au bras est de la place |
| Escalier et murs de soutènement | Escalier de pierre (dalles, contremarches) et **murs d'échiffre** en gradins le long des deux façades |
| Façades de deux à quatre niveaux | Auberge (3 niveaux), maison de la ruelle (3), maison du bras est (2) |
| Toiture, fenêtres, balcons, détails | Toits de tuiles canal, versant sud face à la caméra, faîtière, rives et cheminées. Baies à encadrement de pierre (clef, appui), croisées, volets ouverts. Balcons sur consoles avec garde-corps de fer. Bandeaux d'étage, corniches, chaînes d'angle, lanternes murales, devanture fermée |
| Commerce à l'entrée lisible | L'**auberge-taverne** : avant-corps d'entrée, enseigne en potence, lanternes, grande baie de la salle éclairée, balcon. Examen au seuil |
| Raccord avec la grande place | Bras est dallé, bordure de pierre au seuil de la place (blockout). Les deux montées (ruelle et montée principale) encadrent l'îlot |

**Cohérence avec le Colisée.** La tranche reprend les **mêmes matières procédurales** (`src/p6/maconnerie_p64.gdshader`) :
* calcaire ocre et gris chaud du second pilote validé (`mur2`, `moulure`, `socle2`, `dalle`, `dallage2`) ;
* tuiles canal (`tuiles_a`).

S'y ajoute un **enduit à la chaux** pour les étages (`src/p7/enduit_p76.gdshader`) : marbrures à basse fréquence,
salissure au pied et sous la corniche, coulures.

**Lecture HD-2D.**
* Les silhouettes et le rythme des baies se lisent à 22 m.
* Aucun détail n'est plus petit qu'un pixel ; barreaux et balustres sont groupés en un seul maillage par série.
* La pierre est éclaircie et réchauffée pour l'éclairage de la ville, qui n'est pas modifié.

**Limites de la tranche.**
* Le reste de la ville est en blockout. La couture se voit au bord de la tranche, par exemple contre la Guilde et la grande
  place.
* `--tranche=0` affiche le blockout dans la zone, pour comparer.
* Les collisions sont celles des données. Seul le muret du sud de la rue du chantier change : abaissé de 1,2 à 0,6 m (côté
  caméra), il porte désormais une haie.

Médias : `c_tranche_blockout_vs_pilote.jpg` (six vues, blockout à gauche et tranche à droite) et
`parcours_corrections_p76.mp4`.

**Parcours `parcours_corrections_p76.mp4`** (1 min 43) :
1. Porte du Colisée (E).
2. Vestibule, puis sortie par la porte sud.
3. Arrivée devant les grandes portes, tourné vers la ville.
4. Angle dégagé du perron, place, bras est fermé.
5. Ruelle de la tranche, puis examen de l'entrée de l'auberge.
6. Placette, puis montée vers la grande place.

## Tests (état final)

| Test | Résultat |
|---|---|
| Tests unitaires (dont l'accès à la sortie, déplacée sur le seuil) | 76 sur 76 |
| Ouverture P6 (`--tuto-rapide`), saut du tutoriel | réussis |
| Sondes du Colisée `p6_sondes` | 10 sur 10 |
| Forêt F5, V11 | sans erreur, 0 échec |
| Arène depuis les vestiaires | aucun maillage visible |
| Chargement V0.5, V0.6, V0.7-A, V0.7-B | sans erreur |
| Sondes V0.7-B (portes fermées, bout du bras est, angle du perron, muret, balcon de la ruelle compris), A et B | **40 sur 40** |
| Trajets V0.7-B, A et B | 28 sur 28 |
| Portail ville ↔ Colisée (deux allers-retours), A et B | 4 passages alternés. Arrivées exactes : vestibule (61 ; 26,8) vers le nord ; perron (30,45 ; 68,9) vers le sud |
| Raccord Colisée → ville V0.7-A | 4 sur 4 |
| Circulation du Colisée, une touche maintenue, azimut 0° | arrivée 3 sur 3 sur chaque tronçon, dont « vestibule → seuil » (touche bas) |
| Parcours des corrections `p7_76_video` | 21 étapes sur 21 |
| Caméra, visite complète V0.7-B, A et B (267 s) | **0 bond**, 0 image hors zone confortable ; B : 10 rotations, 0 inversion |
| Caméra, Colisée `p6_741_visite` (avec le vestibule) | 0 bond, 0 image hors zone confortable, 4 pivots |
| Caméra, parcours des corrections | 0 image hors zone confortable. Deux recentrages de 0,1 s (moins de 3 px par image) quand on ouvre et ferme l'examen de l'auberge : c'est le verrou d'interface existant, pas une modification de P7.6 |
| Recouvrements de volumes (`camera_volumes_p76.py`) | 7 → 0 |

## Non vérifiable ici

* **Rendu sur GPU réel** : tout est en rendu logiciel (lavapipe). Le relief des joints, les lanternes émissives et la
  valeur des matières sont à juger sur votre machine.
* **Coût d'affichage** : le rendu logiciel ne rapporte pas les appels de dessin. La tranche ajoute de nombreux petits
  maillages (baies, volets, consoles), non comptés ; seuls les barreaux sont groupés. À mesurer sur votre GPU avant de
  l'étendre.
* **Ressenti au clavier**, surtout l'escamotage des volumes en mouvement : les parcours sont joués par un pilote
  automatique.

## Points à arbitrer

1. **Escamotage des volumes** contre la trame de P7.3. Un volume disparaît en entier, sans fondu. Faut-il ajouter un fondu
   (transparence) ?
2. **Direction de la tranche** : rez-de-chaussée de pierre et étages enduits, couleurs des volets par maison. Faut-il
   l'étendre, et dans quel ordre (Guilde, grande place) ?
3. **Muret à jardinet** de la rue du chantier : 0,6 m et une haie. Est-ce acceptable comme bord de rue côté caméra ?
