# P6.3 — Amélioration artistique du Colisée (pilote, puis extension)

> **P7.2 (nettoyage autorisé par le créateur)** : les médias de ce rapport (`docs/media/…`) ont été retirés du projet
> actif. Ils restent dans l'historique Git : `git checkout d88eac4 -- docs/media/<dossier>`.

Branche **`p6-3-colisee-art`**, issue de `p6-2d-colisee-complet` (validée comme base technique).

Sont inchangés :
* la caméra (azimut 0°, plongée 24°, champ 30°, ×3, limites communes) ;
* le mode B, le tunnel sud de 8,5 m et les ombres douces en qualité 4 ;
* les dialogues, le tutoriel et son saut, la progression ;
* CombatCore, les sprites d'Aren, les autres zones ;
* F5 (forêt). Le Colisée se lance en F6 (`scenes/p6/colisee.tscn`).

Le quartier de ville n'est pas touché.

**Captures de référence du créateur** : elles ne m'ont pas été transmises (le message ne contenait que du texte). J'ai
repéré les défauts décrits avec mes propres captures et des outils de recherche.

Tout ce qui suit est de la **conformité fonctionnelle et une proposition artistique**, pas une validation. Les
mesures sont faites en rendu logiciel (lavapipe), **pas sur GPU**.

## Livrables

| | |
|---|---|
| Vidéo continue, vitesse réelle | [`parcours_complet.mp4`](media/p6_3/parcours_complet.mp4) : vestiaires → salle → tunnel sud (deux sens) → arène → tutoriel passé → tunnel est (deux sens) → coursive → infirmerie → sortie est |
| Vestiaires avant / après | [`vestiaires_avant_apres.jpg`](media/p6_3/vestiaires_avant_apres.jpg) |
| Tunnel sud avant / après | [`tunnel_sud_avant_apres.jpg`](media/p6_3/tunnel_sud_avant_apres.jpg) |
| Arène, tunnel est, coursive, infirmerie, accès, sortie | [`colisee_avant_apres.jpg`](media/p6_3/colisee_avant_apres.jpg) |
| Gros plans : bannières sous 7 angles, porte des vestiaires (fausse marche) | [`gros_plans_bannieres_marche.jpg`](media/p6_3/gros_plans_bannieres_marche.jpg) |
| Décor du combat tutoriel (avant / après, et la scène de combat elle-même) | [`decor_combat_comparaison.jpg`](media/p6_3/decor_combat_comparaison.jpg) |

## 1. Corrections prioritaires

| Défaut | Cause trouvée | Correction |
|---|---|---|
| **Fausse marche** | La plinthe du mur nord des vestiaires (36 cm de haut) courait **sur toute la largeur, porte comprise** : Aren la traversait. | Plinthe interrompue au droit de la porte (décor, aucune collision). L'outil `tools/p6/reliefs_p6.gd` cherche tout volume bas visible posé sur un sol praticable : **il n'en reste aucun**. Le tabouret de l'infirmerie, signalé par l'outil, est glissé sous la table. |
| **Bannières de la coursive** | Posées à y = 11,75 m, **à l'intérieur** du mur nord (11,6–12,0) : invisibles ou percées. | Sur la face intérieure du mur. |
| **Bannières de l'arène** | Plaques carrées plates plaquées sur la pierre. | Vraies bannières d'étoffe pendues sous le chaperon du podium, tournées vers le centre. Seule l'étoffe porte les couleurs de la Guilde. |
| **Pièces en coupe « dans le noir »** | Une pièce située devant perdait son sol avec son décor : il restait des murets autour d'un vide. Au-dessus des portes des murs de 6 m, il n'y avait pas de linteau : un trou noir montait jusqu'en haut. | Les sols sont de la structure : gardés devant (coupe), derrière (vus par une ouverture) et dans les pièces visibles. Des linteaux sont ajoutés aux ouvertures de la loge, des gradins est, de la coursive et de la sortie. |
| **Éléments muraux flottants** | Lanternes, portes et bannières restaient debout au-dessus d'un mur coupé en muret. | Ils suivent la coupe de leur mur (`Secteurs.attacher`). |
| **Tunnel est** | Les gradins au sud du passage couvraient le sol du tunnel : Aren semblait marcher dessus. | Cette tranche de gradins est un maillage séparé, coupé **seulement quand Aren est dans le tunnel est**, avec un dallage dessous. Elle reste entière vue de l'arène. |
| **Tunnel sud** | Arche en poutre droite, aucune transition de lumière. | Arc segmentaire en claveaux avec clé (trouée locale conservée), torches à l'entrée côté salle (lumière chaude, puis pénombre, puis le jour). |
| **Marques de couleur au sol** | Code couleur du plan de blockout. | Affichées seulement sans habillage. |

Corrections faites ensuite, après revue de mes propres gros plans :
* les lanternes projetaient des ombres, et leur cage éteignait leur propre lumière : le passage des vestiaires était
  noir ;
* la variante « anti-répétition » de la pierre faisait pivoter les briques en diagonale : je l'ai retirée ;
* l'étoffe Quaternius d'origine est bleutée : la teinte est appliquée canal par canal.

## 2. Assets Quaternius

**Accès** : l'hôte de téléchargement de Google Drive était refusé. Avec votre accord (demande d'approbation), un
environnement personnel « Val-Serra-Game » autorise désormais **uniquement** `drive.usercontent.google.com` pour ce
dépôt. Les deux archives ont été téléchargées et examinées **hors du dépôt**.

**Inventaire réellement utilisé** : 15 modèles, 17 textures (1024²), licences CC0 conservées, provenance et statut
PROVISOIRE dans [`art/p63/quaternius/SOURCES.md`](../art/p63/quaternius/SOURCES.md).

| Modèle | Où |
|---|---|
| Bench | vestiaires, salle d'attente, coursive (bancs des données) |
| WeaponStand | râteliers des vestiaires et de la salle, près du commandant |
| Peg_Rack | mur nord des vestiaires |
| Lantern_Wall | toutes les appliques murales du Colisée |
| Torch_Metal | entrée du tunnel sud |
| Chest_Wood | coffre des vestiaires, près du commandant |
| Barrel | vestiaires, coursive |
| Crate_Wooden | réserve |
| Banner_1_Cloth | coursive |
| Banner_2_Cloth | porte des vestiaires, podium de l'arène |
| Dummy | mannequin des vestiaires |
| Table_Large, Stool | infirmerie, vestiaires |
| DoorFrame_Round_Brick + Door_8_Round | toutes les portes fermées (loge, gradins est, salle, vestiaires) ; vantaux seuls, coupés, dans les murs bas côté caméra |

**Non retenus** : murs modulaires, toits et sols du Medieval Village.
* Les murs, le sol et les gradins du Colisée sont faits sur mesure (gradins ovales, murs de 6 m pour la visibilité) :
  les modules rectangulaires ne conviennent pas.
* Les toits et façades du village relèvent du style de la ville, que vous voulez repenser.

**Style et intégration** : un style peint stylisé (bois, ferronnerie, pierre), à l'échelle réelle. Il s'accorde bien
avec les textures peintes du projet et lit bien au zoom ×3. Les modèles sont plus détaillés que le blockout : la
différence de densité avec les murs encore « P4 » se voit (voir les limites).

**Collisions** : chaque meuble des données garde sa collision. Les accessoires posés par la scène (tabouret, tonneau,
coffre et râtelier du commandant) ont reçu un obstacle rond. Bancs et tonneaux de la coursive sont dans les données.

## 3. Ambiance et composition

* **Vestiaires** : bancs, mannequin, râtelier, patères, tonneau ; deux bannières de part et d'autre de la porte ;
  lanternes murales.
* **Coursive** : portes doubles ferrées dans des encadrements cintrés (loge, gradins), bannières d'étoffe rouges,
  bancs le long des murs, tonneaux près de la réserve.
* **Arène** : bannières d'étoffe tout autour du podium. Le **commandant** est mis en valeur par une lumière chaude
  dirigée, un coffre et un râtelier.
* **Tunnel sud** : arc en claveaux, torches à l'entrée, jour au bout.

**Comparaison avec les références (Octopath Traveler II)**, première lecture :
* **Ce qui se rapproche** : des objets lisibles et peints, une lumière localisée (lanternes, torches, jour au bout du
  tunnel), des portes et des arches qui donnent une architecture.
* **Ce qui manque encore** :
  * la richesse des matières des murs et du sol (pierre P4 teintée) ;
  * la variation des volumes (corniches, contreforts) ;
  * les effets d'atmosphère (poussière dans la lumière, profondeur de champ en intérieur) ;
  * des toits dessinés vus de l'arène.

## 4. Combat tutoriel

`art/p6/combat/arene_colisee.png` est régénéré depuis l'arène habillée (colonnade, bannières, braseros). Les
accessoires du commandant sont masqués pour ce rendu. L'ancien décor est conservé : `arene_colisee_p6.png`.

Les règles, l'interface et les étapes ne changent pas. Dans la capture de la vraie scène de combat
(`tools/p6/capture_combat_p6.gd`), Aren, le commandant et l'interface restent lisibles.

## 5. Vérifications

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel` | réussis |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` | réussis |
| Sondes `p6_sondes` | 10 / 10 |
| Reliefs visibles traversables (`reliefs_p6`) | aucun |
| Circulation à une touche (4 tronçons) | 3/3 partout, 0 % de contact mural |
| Caméra, traversée complète (`p6_traversee`, 46 s) | 0 bond, zoom constant |
| Bannières sous 7 angles | voir les gros plans |
| F5 | se charge sans erreur |

**Coût de rendu** (appels de dessin, rendu logiciel) :

| Position | P6.2-D | P6.3 | Primitives P6.2-D → P6.3 |
|---|---|---|---|
| Vestiaires | 878 | 831 | 15 k → 85 k |
| Salle d'attente | 251 | 250 | 3 k → 33 k |
| Tunnel sud | 384 | 364 | 21 k → 37 k |
| Arène (centre) | 304 | 327 | 20 k → 28 k |
| Coursive | 246 | 270 | 3 k → 24 k |
| Infirmerie | 337 | 377 | 4 k → 35 k |
| Couloir de sortie | 224 | 247 | 3 k → 26 k |

Le nombre d'appels de dessin reste stable. Les **primitives** augmentent nettement (modèles détaillés avec ombres) et
la mémoire vidéo passe de 221 à 286 Mo (textures 1024²). C'est raisonnable sur GPU, mais **à vérifier sur votre
machine**.

## 6. Problèmes restants

* **Murs et sol** : toujours en matières P4 teintées. La répétition des briques est visible sur les grands pans ; c'est
  la priorité pour la suite.
* **Toitures vues de l'arène** : encore des aplats provisoires.
* **Couleur des bannières** : obtenue par teinte d'une étoffe d'origine bleutée. Un vrai motif (emblème de la Guilde)
  demanderait une texture dédiée.
* **Vieilles cartes peintes** (bannières à l'emblème, bûches, sacs) : elles sont retirées des vestiaires au profit des
  modèles, à l'exception des bûches. À rediscuter si l'emblème vous tient à cœur.
* **Arche de la bouche** : elle se troue autour d'Aren quand elle passe devant lui (trame validée en forêt). À juger
  en mouvement.
* **Coupe de la tranche de gradins du tunnel est** : lisible, mais architecturalement abrupte.
* **Rien n'est validé sur GPU.** Rien n'est final.

## 7. Décision attendue

1. Le style Quaternius vous convient-il pour le mobilier et les portes ?
2. Passe-t-on ensuite aux **matières des murs et des sols** (le plus gros écart avec les références) ?
