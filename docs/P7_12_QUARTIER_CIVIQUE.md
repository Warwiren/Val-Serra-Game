# P7.12 — Quartier civique et perspective du château

Branche **`p7-12-quartier-civique`**, depuis `p7-11-boutique`. EN ATTENTE de validation artistique.

Lot 4 de la grande place : fond nord, montée civique, administration. S'y ajoutent la porte fortifiée et les remparts
autorisés par le brief. Le nettoyage du projet fait l'objet d'un commit séparé (`docs/AUDIT_P7_12.md`).

* Module : `scenes/p7/civique_p712.gd`, branché dans `ville_v07b.gd`.
* `--civique=0` : état P7.11, pour comparer.

## Perspective

Depuis la grande place, l'axe x 70 se lit d'un trait :

1. voie processionnelle de la place ;
2. socle du palier, au blason de la ville ;
3. volée D et balustrades ;
4. voie processionnelle de la terrasse civique et de l'avenue ;
5. **porte fortifiée**, centrée sur la silhouette lointaine du château. Cette silhouette est recentrée sur l'axe :
   `chateau` passe de x 100 à x 70 dans `tools/p7/build_ville_v07b.py`, et les données sont régénérées (seule cette valeur
   change).

Le parcours existant (volée C, palier, volée D, terrasse, avenue) est inchangé, comme ses collisions.

**Contrainte de cadrage.** La caméra de la ville ne montre qu'environ 4° au-dessus de l'horizon. Depuis la place,
à environ 85 m, seule la bande de 8 à 14 m de la porte entre dans le cadre. On y lit l'arc de 6,4 m, la herse baissée,
la grille des données, les gardes, les guérites et le blason. Les tours, mâchicoulis, créneaux et toits d'ardoise se
découvrent en montant, depuis la terrasse et l'avenue.

## Modifications

* **Volées C et D** : escalier de pierre de la tranche (`Tranche.escalier`) : marches, nez, murs d'échiffre. Collisions
  identiques au socle.
* **Terrasses** (palier, terrasse civique, avenue, pieds de volées) :
  * corps en pierre de soutènement, dallage civique ;
  * voie processionnelle de longues dalles claires sur l'axe, qui prolonge celle de la place ;
  * bordure au bord sud de la terrasse.
* **Murs de soutènement** (`socle_palier_2`, `socle_palier_2b`, `bat_b_arriere_forge`) :
  * soubassement, pilastres plats (saillie de 0,08 m, aucun relief traversable), cordon, couronnement, dessus dallé ;
  * **blason de Val'Serra** sur l'axe.
* **Garde-corps** (`gc_*`, collision d'1 m inchangée) : balustrades de pierre (socle, balustres tournés, main courante,
  dés).
* **Administration** (`bat_administration`, collision inchangée) :
  * deux pavillons et un corps central ;
  * rez-de-chaussée à bossage, étages de calcaire, corniche à consoles, toit en croupe de tuiles ;
  * **porche en retrait** sur la terrasse : arc appareillé, porte cochère au fond, 1 m d'embrasure, lanternes, blason ;
  * balcon de pierre au-dessus du porche ;
  * la porte décorative des données est dessinée en porte cloutée.
* **Corps de garde** (`bat_b_terrasse_no`, flanc ouest de l'avenue, collision inchangée) :
  * même langage que la porte : bossage, fenêtres à barreaux ou cintrées, archères sur l'avenue, mâchicoulis et
    créneaux ;
  * c'est le flanc du châtelet. Sans lui, la porte restait encadrée par un grand volume bleu de blockout.
* **Porte fortifiée** (décor seul ; la grille, les gardes et le texte « fermé » des données sont inchangés) :
  * châtelet en pierre du château : façade de 1,2 m d'épaisseur, arc en plein cintre de 15 claveaux, herse de chêne
    baissée devant un passage sombre, archères, cordon, blason, mâchicoulis, parapet et créneaux ;
  * deux tours rondes (talus, corbeaux, parapet crénelé, toits coniques d'ardoise) avec des bannières.
* **Guérites** (collisions des données) : loges de pierre à toit d'ardoise, ouvertes sur l'avenue.
* **Remparts** : deux courtines crénelées et deux tours carrées.
* **Ville haute au-delà des remparts** : six maisons, dont seuls les toits dépassent. Affichage seul, jamais praticable.
* **Escamotage** : tout le décor situé au-delà de la porte est exclu des volumes (méta « vol »). L'administration et le
  corps de garde gardent leur volume.

Matériaux :
* calcaire civique, plus froid et plus régulier que la forge ;
* pierre du château, plus grise et plus salie ;
* ardoise réservée au château et à sa porte ; la ville garde la terre cuite.

## Ce qui ne change pas

Trois terrasses, circulations, collisions, interactions (garde, porte fermée), grande place, fontaine, forge D,
boutique P7.11, Colisée, caméra, occultation. L'hôtel de ville et son entrée fonctionnelle restent en blockout : c'est un
autre lot.

## Fichiers

* `scenes/p7/civique_p712.gd` (nouveau).
* `scenes/p7/ville_v07b.gd` : branchement (terrasses, volées, socles, garde-corps, administration, corps de garde,
  guérites, portes décoratives, décor de la porte).
* `tools/p7/build_ville_v07b.py` et `data/p7/ville_v07b.json` : château recentré.
* `src/explore25/routes25.gd` : parcours de contrôle `p7_712_civique`.

## Appels de dessin

Zone du fond nord, de la porte et de la ville haute (x 26 → 118, y 8 → 89), surfaces hors ombres :

| Version | Surfaces |
|---|---|
| Sans le lot (`--civique=0`) | 534 |
| **Avec le lot** | **568** (+34) |

## Tests

| Test | Résultat |
|---|---|
| Tests unitaires | 76 sur 76 |
| Ouverture P6 (`--tuto-rapide`) et saut du tutoriel | réussis |
| `p6_sondes` (Colisée) | 10 sur 10 |
| F5 (forêt, `--quit-after 60`), V11 | sans erreur |
| Sondes de collision de la ville (bords, garde-corps, grille, guérites), caméras A et B | 40 sur 40 |
| Trajets (dont T4 : volée C, palier, volée D, terrasse, accès du château), A et B | 29 points sur 29 |
| Portail ville ↔ Colisée, A et B | 4 passages, 12 points sur 12 |
| Chargement de toutes les scènes F6 de `scenes/p7` | sans erreur |
| Recouvrements de volumes | 0 |
| Axe du château | dégagé |

## Réserves

* Rendu vérifié en mode Compatibilité seulement. Teintes du calcaire et de l'ardoise à juger sur votre GPU.
* L'avenue est encore bordée à l'est par l'hôtel de ville en blockout bleu, qui relève de son propre lot.
* Les étals provisoires (dont l'étal 3, devant le blason) restent ceux du blockout ; ils relèvent du lot 5.
* Le porche de l'administration se voit de biais depuis la terrasse ; il fait face à la terrasse, pas à la place.
* Les reliefs de façade de l'administration et du corps de garde viennent de la bibliothèque (baies plaquées). Seuls le
  porche et la porte du château sont maçonnés en épaisseur, comme la forge D.
* Réserves de P7.11 consignées pour les lots de bordure (enseignes au flacon, fenêtres éclairées, `bat_commerce_e2`,
  étals) : non traitées ici, comme demandé.
