# P7.1 — Quartier central : blockout V0.1 (prototype de circulation)

Branche **`p7-1-ville-blockout-v01`**, issue du commit de référence **`d88eac4`** (fin de P6.4.3). Le correctif des
vestiaires (`p6-4-4-colisee-vestiaires`) et l'audit (`p7-0-audit-nettoyage`) sont dans des branches séparées.

**Ce prototype n'est pas validé** : c'est un outil de décision.
* Volumes neutres et libellés temporaires.
* Aucune texture finale, aucun intérieur, aucune foule, aucune boutique fonctionnelle, aucun dialogue.

Les mesures sont faites en **rendu logiciel (lavapipe), sans GPU**.

## Lancer

* **F6** sur `scenes/p7/ville_v05_blockout.tscn`. La scène démarre dans la ville, juste à l'intérieur de la porte sud,
  après le Colisée. L'état de jeu est « sorti du Colisée », avec l'objectif de la Guilde.
* `-- --etat=tutorial_completed` démarre dans le Colisée. Sa sortie est mène alors au **parvis** de la ville.
* `colisee.tscn` (F6) est **inchangé** : sa sortie mène toujours au quartier provisoire. Aucune scène validée n'est
  remplacée.
* F5 (forêt) : inchangé.

## Livrables

| | |
|---|---|
| Plan de blockout annoté : accès, boucles, niveaux, escaliers, accès fermés, durées mesurées | [`plan_blockout_annote.jpg`](media/p7_1/plan_blockout_annote.jpg) |
| Plan directeur V0.5 de référence | [`plan_directeur_v05_reference.jpg`](media/p7_1/plan_directeur_v05_reference.jpg) |
| Vue A (arrivée sud), B (place → hôtel de ville), C (parvis → Colisée), zooms ×3 et ×2 | [`vues_ABC.jpg`](media/p7_1/vues_ABC.jpg) |
| Autres contrôles : Guilde, commerces, marché, escaliers, avenue haute, ruelle, passage est | [`vues_controle.jpg`](media/p7_1/vues_controle.jpg) |
| Vidéo continue, marche réelle : arrivée sud, guilde, commerces, auberge, marché, place (×2), Colisée, boucle ouest, boucle est, accès est, hôtel de ville, avenue haute, accès nord | [`ville_blockout_parcours.mp4`](media/p7_1/ville_blockout_parcours.mp4) |

## 1. Points de raccord et conflits avec le plan V0.5

* **Colisée → ville** : la sortie est du Colisée (couloir de sortie, `sortie_est`) mène au **parvis**, devant l'entrée
  publique, à l'est de l'enceinte. C'est l'implantation du plan : Colisée à l'ouest, parvis public tourné vers la place.
  * Le raccord est testé en marche réelle (parcours `p7_raccord`) : couloir du Colisée, porte est, parvis, grande place.
* **Ville → Colisée** : l'entrée publique est fermée après la sortie (`fermee_a_partir_de: coliseum_exited`), comme dans
  le quartier provisoire : « les portes se sont refermées ».
  * Avant cet état, la porte est ouverte et un passage de 4 m sous l'enceinte ramène au couloir de sortie du Colisée.
* **Conflits relevés** :
  * **Enceinte du Colisée** : l'instance réelle est un bâtiment rectangulaire de 64 × 48 m (vestiaires au sud, coursive
    et sortie à l'est). Le plan dessine une enceinte ronde. Vue de la ville, je l'ai représentée par un tambour elliptique
    de 58 × 52 m. Les deux restent cohérents en position et en taille (sortie est, au milieu de la façade), mais la forme
    extérieure définitive est à décider.
  * **Porte sud** : le plan l'indique « ouverte » vers l'extérieur, mais il n'existe pas de carte extérieure. Elle est
    ouverte et matérialisée, sans fausse transition : un examen indique « transition prévue, pas encore reliée », et
    une barrière de chantier visible ferme la route 6 m plus loin.
  * **Quartier provisoire P4** : non utilisé, non modifié, non figé. Il reste la destination par défaut du Colisée hors
    de la scène du blockout.

## 2. Échelle et dimensions

L'échelle vient des **données du jeu**, pas du dessin :
* marche 2,2 m/s (`vitesse_m_s` du Colisée) ;
* Colisée réel de 64 × 48 m.

Les trois durées cibles du brief donnent ensemble **0,145 m par pixel** du plan, soit un quartier de **190 × 168 m**.

| Élément | Dimension |
|---|---|
| Avenue des Portes, avenue haute | 13 m de large (escaliers de 9 m) |
| Rues des boucles (Combattants, rue est) | 6 à 8 m |
| Ruelles | 3 à 4 m (praticables) |
| Grande place | 43 × 33 m, fontaine-repère de 7 m |
| Parvis du Colisée | 24 × 16 m |
| Marché | 39 × 24 m, 4 étals |
| Fronts bâtis | 6 m (2 étages), 9 m (3), 12–13 m (4) : maisons, commerces, hôtel de ville |
| Remparts et tours | 8 à 13 m ; porte sud 9 m, porte du château 9 m, accès est 6 m |

**Niveaux** : bas −1 / centre 0 / haut +1 du plan, recalés en 0 / 1 / 2 m.

| Niveau | Contenu | Hauteur |
|---|---|---|
| Sud | porte, guilde, commerces, auberge | 0 |
| Centre | Colisée, parvis, place, marché, hôtel de ville | 1 m |
| Nord | avenue haute, archives, porte du château | 2 m |

* Les bords de terrasse sont des **murs de soutènement visibles**, franchis par 4 escaliers de 3 m :
  * avenue des Portes ;
  * rue des Combattants ;
  * rue est ;
  * avenue haute.
* Pas de mur invisible : les limites sont les remparts, l'enceinte du Colisée, les bâtiments et les portes fermées.

Le plan V0.5 n'est **pas reproduit au pixel**. Les rues courbes sont ramenées à des rues orthogonales, car le socle ne
gère que des sols rectangulaires. L'organisation, les distances relatives et les liaisons sont conservées.

## 3. Services (sans doublon)

| Service | Emplacement |
|---|---|
| Guilde des Chasseurs | Sud-est, entrée côté avenue, par un parvis dallé, à 19,7 s de la porte sud |
| Forge-armurerie | Rangée sud, **unique** |
| Auberge-taverne | Sud-ouest de l'avenue, **unique** |
| Marchand d'objets, herboriste, atelier | Rangée sud, au pied du marché |
| Marché | Sous la grande place, avec 4 étals |
| Hôtel de ville, archives | Hôtel de ville au nord-est de la place ; archives sur la terrasse haute |
| Accueil de l'arène, logements | Rue des Combattants |

Les volumes sont colorés par fonction (repères de lecture tirés du plan). Les bâtiments importants portent un
**libellé temporaire**.

## 4. Temps de trajet réels

Mesures du parcours `p7_trajets` :
* marche à 2,2 m/s au clavier (8 directions), sans course ;
* chaque tronçon part d'un placement, puis se fait en marche continue.

| Parcours | Cible | Mesuré |
|---|---|---|
| Guilde → porte sud | 15–25 s | **19,7 s** |
| Porte sud → grande place | 30–45 s | **44,6 s** (haut de la fourchette) |
| Grande place → entrée publique du Colisée | 20–35 s | **20,4 s** (bas de la fourchette) |
| Porte → guilde → forge-armurerie → auberge-taverne → porte | — | 100,7 s |
| Boucle ouest (place / Colisée / rue des Combattants / marché / place) | — | 63,7 s |
| Boucle est (place / rue du Conseil, hôtel de ville / rue est / marché / place) | — | 69,5 s |
| Place → porte du château (fermée) | — | 28,8 s |
| Place → accès du quartier est (fermé) | — | 45,2 s |

* **Aucun blocage**.
* **Aucun saut de hauteur** (`h_jumps` = 0).
* Toutes les étapes sont atteintes.

**Défaut trouvé et corrigé pendant l'étape** : Aren butait au pied des escaliers. Le palier bas d'un escalier du socle
n'a pas de dessous physique, et le sol bas s'arrêtait au bord : la sonde de rebord voyait un vide. Une bande de sol
(0,4 m) sous chaque palier bas corrige le problème, dans les données (générateur).

## 5. Caméra, occultation, lisibilité

* **Caméra** : celle du Colisée, sans changement (azimut 0°, plongée 24°, champ 30°), avec les limites du niveau.
  Zooms ×3 et ×2 vérifiés sur les vues et dans la vidéo.
* **Occultation** : les façades ont la trouée tramée de la forêt autour d'Aren, sans nouveau système.
* **Mur face à la caméra** : le rempart sud et les tours de la porte sud sont **dessinés coupés à 1,6 m** (convention des
  intérieurs du Colisée), collisions inchangées.
  * Sans cela, ils cachaient toute l'arrivée sud : premier rendu de la vue A, corrigé.
* **Sols** : un premier rendu était surexposé (sols presque blancs). Les teintes ont été baissées.
* **Lisibilité des niveaux** :
  * murs de soutènement plus sombres ;
  * escaliers marqués (texture d'escalier du socle P4, provisoire) ;
  * quadrillage au sol de 1 m et 5 m pour juger les distances.

## 6. Performances (rendu logiciel)

| | Blockout de la ville | Colisée (P6.4.3, mêmes outils) |
|---|---|---|
| Appels de dessin, maximum | 159 | 947 |
| Primitives, maximum | 19 k | 190 k |
| Mémoire vidéo | 217 Mo | 304 Mo |

Le blockout est très léger : des volumes simples, un seul shader, aucune texture. Le temps d'image (≈ 133 ms) est saturé
par le rendu logiciel et **n'a pas de sens sans GPU**.

## 7. Tests

TESTS_P71

## 8. Fichiers

| Fichier | Rôle |
|---|---|
| `tools/p7/build_ville_v05.py` (nouveau) | Générateur des données : échelle, niveaux, escaliers, bâtiments, remparts, portes, examens, repères |
| `data/p7/ville_v05.json` (généré) | Zone « ville » au format du socle (sols, escaliers, obstacles, sorties, portes) |
| `scenes/p7/ville_blockout.gd` (nouveau) | Affichage du blockout : volumes par fonction, tambour du Colisée, fontaine, remparts coupés au sud, libellés |
| `scenes/p7/ville_v05_blockout.tscn` (nouveau) | Scène F6 (hérite de la scène du Colisée, `ville_v05 = true`) |
| `src/p7/blockout_p7.gdshader` (nouveau) | Matériau de blockout : couleur unie, quadrillage d'1 m, étages et baies schématiques, trouée d'occlusion |
| `scenes/p6/colisee.gd` | Branchement **optionnel** de la ville (`ville_v05` / `--ville=v05`). Sans cette option, comportement inchangé |
| `src/explore25/routes25.gd` | Parcours `p7_trajets`, `p7_vues`, `p7_video`, `p7_raccord` |

## 9. Défauts ouverts et éléments provisoires

| Priorité | Point |
|---|---|
| Moyenne | **Rues orthogonales** : les rues courbes du plan sont approchées par des rectangles. Pour des diagonales, il faudrait des sols non rectangulaires dans le socle (évolution technique à décider) |
| Moyenne | **Arrivée sud** : la vue A laisse voir l'avenue et la ville en profondeur, mais pas encore de « grande cité » au-delà. Pas de silhouettes lointaines dans le blockout, volontairement |
| Basse | **Escaliers** : ils gardent la texture du socle P4 (violacée), un placeholder |
| Basse | **Libellés** : de taille fixe, ils se chevauchent parfois avec le nom de zone (« Grande place ») |
| Basse | **Grande place** : un vaste aplat, la fontaine seule ne suffit pas à la structurer (sujet de direction artistique) |
| Info | **Toits** : plats ; pas de toitures |

## 10. Arbitrages de conception à décider

1. **Taille du quartier** : 190 × 168 m, calée sur les durées cibles. Porte → place est en haut de fourchette (44,6 s), et
   place → Colisée en bas (20,4 s). Faut-il resserrer le sud ou éloigner le Colisée ?
2. **Niveaux** : faut-il garder trois terrasses de 1 m, ou des dénivelés plus marqués (2–3 m), plus lisibles en HD-2D
   mais avec des escaliers plus longs ?
3. **Forme extérieure du Colisée** : tambour elliptique, comme le plan, ou enveloppe rectangulaire, comme l'instance ?
4. **Géométrie des rues** : faut-il étendre le socle aux sols non rectangulaires pour les rues courbes du plan ?
5. **Porte sud** : vers quelle carte extérieure relier la transition ?
6. **Entrée de la Guilde** : sur un parvis à l'ouest, côté avenue, comme ici, ou sur la rue des Aventuriers ?
