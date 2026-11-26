# P7.11 — Boutique de fournitures

Branche **`p7-11-boutique`**, depuis `p7-10-1-forge-refonte` après le correctif de la forge, qui est un commit distinct
sur cette branche. EN ATTENTE de validation artistique.

La forge D sert de référence de qualité : matériaux, embrasures, relief, raccords, profondeur. La boutique a sa propre
identité : la forge est une masse de pierre basse, la boutique une maison de marchand haute et étroite à pan de bois.

* Module : `scenes/p7/boutique_p711.gd`, défaut de `scenes/p7/ville_v07b.tscn`.
* Avant / après : scène F6 `scenes/p7/ville_v07b_boutique_710.tscn` (boutique P7.10), ou `--boutique=710`.
* Blockout : `--boutique=0`.

Ce qui ne change pas : emprise (x 76 → 88, y 76 → 88), collision du bâtiment, entrée fonctionnelle (x 78) et ses piédroits
à collision, examen, trois niveaux, terrasses, place, Colisée, circulations, axe du château.

## Modifications

**Entrée et devanture.**
* Le rez-de-chaussée est en pierre chaude, maçonné en épaisseur (0,45 m).
* Devanture de bois peint vert :
  * deux poteaux à panneaux en creux, sur socles de pierre et sous chapiteaux, qui **sont** les piédroits à collision ;
  * bandeau d'enseigne à deux filets dorés et emblème au flacon, corniche.
* **Porte vitrée à deux vantaux** au fond d'une embrasure de 0,8 m : piédroits et linteau de pierre, soubassements à
  panneaux, petits carreaux éclairés, imposte vitrée à grille de fer.
* Seuil, marche, dalle sur le caniveau de la place. Lanterne de fer.
* L'ancienne entrée générique (calcaire clair) n'est plus dessinée pour cette boutique.

**Étages.**
* **Pan de bois sur encorbellement** de 0,4 m. Dessous : sablière de chêne, abouts de solives, consoles.
* Poteaux, sablières, décharges en croix ; hourdis enduits miel, plus chauds sur la rue.
* Croisées en retrait de 0,4 m (meneau, traverse, encadrement de chêne, appui saillant), volets verts ouverts, deux
  fenêtres éclairées.
* Face ouest, le long du palier : pan de bois plaqué, croisées, volets, sans encorbellement au-dessus du palier.

**Pignon et toit.**
* Pignon sur rue en pan de bois : entrait, poinçon, arbalétriers, entrait retroussé, lucarne.
* Planches de rive : finition différente des rampants de pierre de la forge.
* Porte de chargement et potence de grenier (poulie, corde, caisse suspendue).
* Tuiles Quaternius avec la matière de la forge (`tuiles_p7101`), plus brune et un peu plus variée ; débord de 0,5 m
  sur la rue. Souche de pierre.

**Enseigne.** Panneau ovale pendu à l'angle sud-ouest, sous l'encorbellement, avec un flacon vert en relief sur les deux
faces. Il est lisible depuis la place et répond à l'emblème du bandeau.

## Occultation

* **Étal.** `bat_commerce_e2`, un blockout de 6 m devant la façade, cachait l'étal posé au pied de son mur ouest dès que
  la caméra venait de l'est de la place.
  * Le même mobilier, sans ajout d'objets, est déplacé à l'angle ouest de la boutique, devant le socle du palier :
    x 73,9 → 76,45, y 88,05 → 89,05, entre l'étal 3 et la porte, hors des circulations.
  * Il garde sa seule collision basse ; il est couvert d'un auvent rayé accroché au mur du socle.
* **Façade.** Sous 9,5 m, la partie est de la façade (x 80 → 88) reste cachée par ce même bloc. La boutique se lit par
  sa travée ouest (devanture, enseigne, étal), par l'encorbellement et le dernier étage, entiers au-dessus du bloc, et
  par le pignon. Abaisser `bat_commerce_e2` relève de son propre lot, qui n'est pas commencé.
* **Escamotage.**
  * Le toit Quaternius de la boutique P7.10 n'était rattaché à aucun volume : la boutique escamotée, il serait resté
    affiché.
  * Tous les éléments de la boutique, toit compris, portent maintenant la méta « vol » et sont rangés dans son volume
    (`ville_v07b._classer_volumes`). Le sommet du volume est porté à 17,5 m.
  * Vérifié : caméra devant la boutique et Aren sur la terrasse haute, les 34 éléments s'escamotent ensemble.

## Fichiers

* `scenes/p7/boutique_p711.gd` (nouveau) : boutique P7.11.
* `scenes/p7/ville_v07b_boutique_710.tscn` (nouveau) : comparaison « avant ».
* `scenes/p7/ville_v07b.gd` : choix de la boutique, entrée générique désactivée pour P7.11, méta « vol » au classement
  des volumes, sommet du volume de la boutique.
* `README.md`, `CLAUDE.md`.

Aucun nouvel asset. Réutilisés : les matières de la forge D, `Roof_RoundTiles_8x12`, et `Table_Large`, `Crate_Wooden` et
`Barrel` (mobilier de l'étal P7.10).

## Appels de dessin

Surfaces, hors ombres, dans la zone de la boutique (x 73 → 89, y 75 → 94, au-dessus de 3,4 m) :

| Version | Surfaces |
|---|---|
| Blockout | 28 |
| Boutique P7.10 | 58 |
| **Boutique P7.11** | **43** |

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
| Chargement des scènes F6 `ville_v07b_forge_a/b/c` et `ville_v07b_boutique_710` | sans erreur |
| Recouvrements de volumes | 0 |
| Axe du château | dégagé |
| Escamotage de la boutique (Aren sur la terrasse, caméra devant la façade) | 34 éléments sur 34, toit compris |

## Réserves

* Rendu vérifié en mode Compatibilité seulement (OpenGL sur processeur). La façade sud est souvent à l'ombre ; la teinte
  des hourdis, des tuiles et des vitres éclairées est à juger sur votre GPU.
* `tools/p7/camera_volumes_p76.py` raisonne sur le bloc des données (8,5 m) : il ne voit ni les étages ni le toit, qui
  montent à 16,6 m. Le masquage en jeu, lui, utilise maintenant le volume porté à 17,5 m.
* Le pan de bois est une nouveauté dans la ville. C'est à vous de dire s'il convient au langage de Val'Serra.
