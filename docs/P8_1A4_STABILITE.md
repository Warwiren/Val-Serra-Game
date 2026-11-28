# P8.1-A4 — Stabilité des décors, occultations et transitions Colisée–ville

Branche **`p8-1a4-stabilite`**, depuis `p8-1a3-fortifications`. Godot 4.7.2. **EN ATTENTE de revue en jeu.**

Cette étape est une consolidation technique et visuelle :
* aucun nouveau bâtiment, aucune végétation, aucun PNJ ;
* caméra, lumière B, collisions, portails, interactions, forge D, boutique P7.11 et enceinte A3 conservés.

## Commandes de comparaison avant / après

| Option | Effet |
|---|---|
| `--stabilite_a4=0` | Escamotage, halle et enceinte de P8.1-A3 |
| `--cache_ville=0` | Reconstruction de la ville à chaque retour du Colisée (P8.1-A3) |
| `--escamotage_delai_enceinte=<s>` | Délai de rétablissement des tours, de la porte et du toit de la halle (2,5 s par défaut) |

Mesures :
* `godot --headless --path . --script res://tools/p8/escamotage_p81a3.gd -- --route=p81a4_porte_colisee [--stabilite_a4=0]` : idem avec `p81a4_enceinte`, `p81a3_aller_retour`, `p7_v07b_video` ;
* transition : `godot --path . res://scenes/p7/ville_v07b.tscn -- --route=p7_v07_portail --quit [--cache_ville=0]`, journal `P8A4 CHARGEMENT`.

## 1. Disparitions excessives : causes confirmées

### Étal couvert (halle du quai) devant la porte du Colisée — cas prioritaire

* **Nœuds en cause** : la halle de P7.13 (`bordures_p713._halle`) formait un seul volume d'escamotage, `bat_echoppe_no_o`, de 3,95 à 9,15 m. Il contenait le quai, les poteaux, les sablières, les entraits et le toit. Sa coupe d'étage était à 7,0 m, au niveau du toit.
* **Règle en cause** :
  * devant la porte, la ligne de vue vers Aren ne frôle que l'égout ouest du toit (environ 0,2 m) ;
  * le test se fait contre la boîte englobante du volume entier ;
  * la ligne passe sous la coupe de 7,0 m, donc le volume passe en « tout » : toit, poteaux et entraits disparaissent ensemble ;
  * les marchandises, classées hors du volume, restaient seules sur le quai.
* Mesure en A3, sur le parcours `p81a4_porte_colisee` : 8 bascules de toute la halle (8 perceptibles), dont un clignotement à 0,88 s.

### Autres bascules

* **Volumes bas** : un volume sans géométrie à plus de 0,3 m de sa base gardait un sommet estimé (9,15 m pour le quai de la halle). Il basculait sans rien cacher.
* **Enceinte sud** :
  * les tours et la porte étaient rétablies dès que la vue se dégageait, puis recoupées quand Aren s'arrêtait ou faisait demi-tour au pied de l'enceinte ;
  * la porte voûtée était testée comme un bloc plein, alors que la ligne de vue vers Aren passe souvent par l'arc ;
  * une tour coupée retombait à 0,9 m, sous le chemin de ronde (1,2 m) : un « trou » dans la ligne de l'enceinte.
* **Premier plan (Guilde, fonds du parvis)** : les bascules qui restent sont nécessaires, la caméra passant dans l'emprise de ces bâtiments. Elles sont espacées d'au moins 3,9 s.

## 2. Corrections appliquées

| Cas | Correction | Code |
|---|---|---|
| Halle du quai | Quai, poteaux, sablières, entraits et marchandises jamais escamotés. Toit découpé en deux versants (`halle_toit_o`, `halle_toit_e`), escamotés séparément : seul le versant que la ligne de vue traverse disparaît | `bordures_p713._toit_halle_a4`, `ville_v07b.declarer_volume` |
| Volumes bas | Sommet réel ; jamais escamotés s'ils ne dépassent pas 0,6 m | `ville_v07b._sommet_mesure`, `coupes_camera` |
| Porte voûtée | Ouverture déclarée : la ligne de vue qui passe par l'arc n'est pas coupée | `ville_v07b._coupe_vue`, `fortifications_p81a3._porte` |
| Tours, porte, toit de la halle | Rétablis seulement quand Aren s'est éloigné de plus de 8 m, ou après 6 s de vue dégagée ; délai de 2,5 s | `ville_v07b.coupes_camera` |
| Changements de niveau | Anticipation de 0,6 m à chaque changement, pas seulement à l'entrée : une seule bascule au lieu de deux rapprochées | idem |
| Enceinte lisible | Souche des tours portée à 1,2 m (niveau du chemin de ronde), nouvelle coupe à 2,25 m (niveau du parapet). Coupées, tour et courtine restent alignées en gradins | `fortifications_p81a3` |

### Mesures

Les bascules **perceptibles** sont celles dont la partie qui change couvre au moins 1 % de l'écran. Elles sont mesurées par projection de la géométrie réelle du volume par la caméra de jeu.

| Parcours | Bascules perceptibles A3 → A4 | Bascules A3 → A4 | Clignotements (< 1 s) A3 → A4 | Aren masqué |
|---|---|---|---|---|
| Porte du Colisée, aller-retour (`p81a4_porte_colisee`) | 8 (halle entière) → **7** (un versant de toit) | 8 → 8 | 1 → **0** | 0 |
| Enceinte sud, aller-retour (`p81a4_enceinte`) | 40 → **26** | 40 → **32** | 0 → 0 | 0 |
| Forge-Colisée, aller-retour (`p81a3_aller_retour`) | 10 → **9** | 30 → 30 | 0 → 0 | 0 |
| Visite complète (`p7_v07b_video`) | 22 → **18** | 41 → **40** | 0 → 0 | 0 |
| Trajets (`p7_v07b_trajets`) | 13 → **10** | 24 → 24 | 0 → 0 | 0 |

Devant la porte du Colisée, poteaux, entraits, quai et marchandises ne bougent plus. Seul un versant du toit est retiré quand Aren passe derrière lui, et il n'est rendu qu'une fois Aren éloigné.

## 3. Coût des volumes découpés

En A3, chaque volume était découpé au chargement. Ses maillages restaient en plusieurs morceaux par niveau, même quand rien n'était escamoté : c'était la principale cause des +14 % d'appels de dessin.

**Découpe différée** (`ville_v07b._preparer`) :
* la géométrie compacte d'origine (« entier ») est affichée tant que le volume n'est pas coupé ;
* la copie découpée (« decoupe », maillages partagés jusqu'à la coupe, chapeaux) est préparée après le chargement, un volume par image et les plus proches d'Aren d'abord, ou immédiatement s'il doit être escamoté ;
* la copie découpée est cachée et ne coûte aucun appel tant qu'elle n'est pas affichée ;
* les volumes bas ne sont jamais découpés.

Effets :
* les 0,26 s de découpe sortent du chargement ;
* une ville sans escamotage revient au nombre d'appels de A2.

Les surfaces statiques restent fusionnées par matière, comme avant, et aucune matière nouvelle n'est créée par la découpe.

PERF_TABLEAU

## 4. Transition Colisée ↔ ville

### Instrumentation

Le journal `P8A4 CHARGEMENT` (`colisee._rapport_chrono`) couvre :
* le fondu au noir ;
* la libération ou la conservation de l'instance ;
* les données JSON ;
* la construction des éléments, avec les plus lourds ;
* le décor de zone : pour la ville, décor de base, prolongements, entrées, quartier civique, bordures et enceinte, volumes d'escamotage, lumière ;
* les PNJ, secteurs et caméra ;
* la téléportation d'Aren ;
* les quatre premières images.

### Diagnostic (avant, P8.1-A3)

| Passage | Sans rendu (construction seule) | Avec rendu (Forward+, Vulkan logiciel du conteneur) |
|---|---|---|
| Ville → Colisée (1er) | 1,29 s | 15,7 s, dont 13,0 s de première image (compilation des pipelines) |
| Colisée → ville (1er) | 1,32 s : éléments 0,61, décor de base 0,19, volumes 0,26, première image 0,18 | **8,4 s** : éléments 2,2, décor 1,3, volumes 0,6, images 3,1 |
| Ville → Colisée (2e) | 0,32 s | 3,0 s (shaders déjà compilés) |
| Colisée → ville (2e) | 1,27 s | **9,0 s** : aucun gain à chaud |

**Conclusion** : le retour en ville coûte la **reconstruction complète de la ville** à chaque passage, y compris au second retour. Ce sont des milliers de maillages et de matières générés puis envoyés au rendu. Ce n'est ni le chargement des ressources (JSON en 4 ms) ni les shaders, déjà compilés au second retour.

Les 8,4 à 9 s mesurées ici en rendu logiciel sont du même ordre que les 8,6 s de votre vidéo. C'est une coïncidence : on ne peut pas transposer les temps du conteneur à votre GPU.

### Optimisation retenue : la ville gardée (réutilisation)

Code : `colisee._garder_zone` et `_reprendre_zone`, `ville_v07b.reprendre`.
* **En quittant la ville**, son instance et l'état de scène qui lui est propre (monde, volumes, lumières, listes de fondus) sont **détachés de l'arbre au lieu d'être détruits**.
* **Au retour**, l'instance est rattachée telle quelle, sans aucune reconstruction. On réapplique la lumière B, l'environnement, la caméra de zone et la position d'Aren (arrivée et déclencheurs comme au premier chargement), et les volumes d'escamotage sont remis à zéro.
* Le Colisée reste reconstruit à chaque entrée, comme avant, avec un coût moindre.

| Passage | Avant (sans rendu / avec rendu logiciel) | Après (sans rendu / avec rendu logiciel) |
|---|---|---|
| Colisée → ville (1er) | 1 317 ms / 8 351 ms | **34 ms / 3 702 ms** |
| Colisée → ville (2e) | 1 265 ms / 8 980 ms | **48 ms / 3 741 ms** |

Après correction, il ne reste dans le conteneur que le rendu des premières images de la ville : environ 0,6 s par image en rendu logiciel, plus la première (1,6 s), qui recrée les ombres. Sur votre GPU, ce poste se compte en images, pas en secondes. Nous ne donnons pas d'estimation chiffrée.

L'arrivée d'Aren (position, orientation, déclencheurs armés), la porte publique (interaction E) au second passage et la progression sont identiques. Les contrôles portail et retour sont dans la série (§ 5).

**Transition visuelle** : le fondu au noir existant est conservé. Le fondu retour attend que les premières images après le chargement soient prêtes (escamotage et ombres posés), pour ne pas montrer un état intermédiaire.

**Non fait, et non nécessaire au vu des mesures** : streaming, chargement progressif. La première entrée au Colisée reste coûteuse dans le conteneur (compilation initiale des pipelines) ; c'est à juger sur votre GPU.

**Mémoire** : la ville reste en mémoire pendant le séjour au Colisée.

## 5. Tests

`bash tools/p8/non_regression_p80c.sh` : les 24 contrôles, les 4 contrôles A3 et 3 nouveaux contrôles A4.

RESULTATS_NR

Contrôles A4 :
* **Porte du Colisée** : Aren jamais masqué, aucun clignotement, au plus 8 bascules perceptibles, et aucune bascule du volume de la halle (structure et marchandises stables).
* **Enceinte sud** : Aren jamais masqué, aucun clignotement, au plus 30 bascules perceptibles (A3 : 40).
* **Retour Colisée → ville** : ville gardée, retours de moins de 400 ms sans rendu, arrivée et déclencheurs conformes. Mesuré sur le journal du test portail (deux allers-retours, interaction E de la porte publique au second passage).

## 6. Réserves

* Les **temps de transition** sont mesurés dans le conteneur, sans rendu et en rendu logiciel. Ils ne préjugent pas des temps sur votre GPU.
* La **première entrée au Colisée** n'est pas optimisée. Le Colisée est reconstruit à chaque entrée : 3 s au second passage en rendu logiciel, 0,3 s sans rendu.
* La **ville gardée** reste en mémoire pendant le séjour au Colisée. C'est sans conséquence mesurée ici, mais la mémoire vidéo est à vérifier sur votre machine.
* **Restent visibles** :
  * l'escamotage d'un versant du toit de la halle quand Aren passe derrière ;
  * les coupes des tours et de la porte quand Aren longe l'enceinte au plus près (souche à 1,2 m, alignée sur le chemin de ronde) ;
  * les étages de la Guilde quand la caméra passe dans son emprise.
* **Nœuds tenus** : les tours, la porte et le toit de la halle restent coupés jusqu'à 6 s après la fin du masquage si Aren reste à moins de 8 m. C'est voulu, contre les clignotements.
