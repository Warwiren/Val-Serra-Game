# P6.4 — Pilote de direction artistique HD-2D du Colisée

> **P7.2 (nettoyage autorisé par le créateur)** : les médias de ce rapport (`docs/media/…`) ont été retirés du projet
> actif. Ils restent dans l'historique Git : `git checkout d88eac4 -- docs/media/<dossier>`.

Branche **`p6-4-colisee-direction-artistique`**, issue de `p6-3-2-colisee-corrections-finales`.

C'est un **pilote**, en attente de votre validation artistique : rien n'est final et rien n'est généralisé. Le reste du
Colisée garde les matières de P6.3.2.

Sont inchangés :
* la caméra, les déplacements, CombatCore, les personnages, la progression et le tutoriel ;
* Godot 4.7.2 et les ombres douces en qualité 4 ;
* F5 (forêt). Le Colisée se lance en F6.

Les mipmaps et les corrections de faces confondues de P6.3.2 sont conservés. Rien n'a été fait sur la ville. Aucun pack
n'a été importé.

**Comparer en jeu** :
* **M** : alterne entre le pilote P6.4 et l'état P6.3.2 (`-- --p64=0`) ;
* **U** : change la représentation de la porte en coupe (`-- --porte_coupe=silhouette|coupe|p632`).

**Captures non reçues** :
* La **capture à la croix bleue** ne m'est toujours pas parvenue (message sans pièce jointe). Elle n'est pas non plus
  sur le Drive du projet : la seule image récente est `APERCU_PaintedSpells.jpg`, sans rapport. J'ai donc vérifié huit
  cadrages depuis l'arène (planche 1), dont les deux angles sud où la terrasse était la plus visible. Si le cadrage
  exact diffère, envoyez-la-moi et je le reproduirai.
* Je n'ai pas reçu non plus les **références HD-2D** mentionnées : la comparaison se fait avec la forêt et avec ce que
  je sais du style d'Octopath Traveler II.

Les mesures sont faites en rendu logiciel (lavapipe), **pas sur GPU**.

## Livrables

| | |
|---|---|
| 1. Terrasse plate (P6.3.2) et galerie couverte (P6.4), quatre vues de l'arène | [`galerie_ecoincons_avant_apres.jpg`](media/p6_4/galerie_ecoincons_avant_apres.jpg) |
| 1 bis. Vue du dessus avant / après | [`vue_dessus_avant_apres.jpg`](media/p6_4/vue_dessus_avant_apres.jpg) |
| 2. Porte de la réserve : P6.3.2, coupe seule, coupe et silhouette (infirmerie et coursive) | [`porte_reserve_coupe_comparaison.jpg`](media/p6_4/porte_reserve_coupe_comparaison.jpg), gros plan [`porte_reserve_gros_plan.jpg`](media/p6_4/porte_reserve_gros_plan.jpg) |
| 3. Trois zones pilotes avant / après | [`zones_pilotes_avant_apres.jpg`](media/p6_4/zones_pilotes_avant_apres.jpg) |
| 4. Vidéo, Aren en mouvement près des éléments pilotes (P6.3.2 à gauche, P6.4 à droite, vitesse réelle, 36 s) | [`pilote_mouvement_avant_apres.mp4`](media/p6_4/pilote_mouvement_avant_apres.mp4) |
| 5. Comparaison avec la forêt | [`comparaison_foret.jpg`](media/p6_4/comparaison_foret.jpg) |

## 1. Raccord entre les gradins et les bâtiments : une galerie couverte

En P6.3.2, les écoinçons étaient fermés par une terrasse plate de pierre claire : une grande plaque technique.

En P6.4, ils sont couverts par une **galerie** (`habillage_p6._galerie_p64`), comme la substructure couverte d'un
amphithéâtre :
* **Toiture en appentis** de tuiles canal. Elle part de sous la corniche du mur de fond des gradins et descend vers les
  façades. Ses rangs de tuiles suivent l'anneau, avec des UV en mètres : longueur d'arc au rayon courant, distance
  depuis l'anneau. Les tuiles ne sont donc pas déformées.
* **Pente** : elle est bornée à 30 % de la hauteur, si bien que l'égout reste haut au sud, où les gradins sont abaissés.
* **Contreforts rayonnants** tous les 15°. Ils naissent dans le mur de fond, suivent la pente et finissent en
  **pilastres** débordant sur la façade. La toiture est ainsi découpée en travées.
* **Corniche de pierre** le long de l'anneau, à la jonction avec le mur de fond.
* **Façades** avec un égout débordant, et **retours de mur** aux bords des passages (tunnels sud et est, loge).

**Ce qui est conservé** :
* Le sol derrière les gradins reste entièrement caché, sous tous les angles testés et en vue du dessus.
* Rien ne dépasse le haut du mur de fond des gradins : aucune occultation nouvelle de l'arène.
* Les tunnels et la loge restent dégagés.
* **Aucune collision** n'est ajoutée ni retirée : ces zones n'étaient déjà pas praticables.

**Limite** : vue de très près, la toiture reste un grand pan de tuiles régulières (voir § 5, indice 0,81). La
prochaine étape serait de la varier : tuiles déplacées ou cassées, mousse dans les noues, faîtage, quelques lucarnes ou
une terrasse aménagée sur une travée.

## 2. Porte de la réserve en coupe

**Problème de P6.3.2** : la porte basse de 1,2 m réduisait physiquement la porte. Elle ressemblait à un coffre.

**Proposition P6.4** : une coupe architecturale, avec la porte **à sa taille réelle** (`colisee._en_coupe`,
`_en_fantome`).
* **Encadrement** : les jambages restent entiers jusqu'à la naissance de l'arc (1,85 m), puis sont tranchés. Le dessus
  des jambages montre la tranche sombre des murs coupés (le même poché).
* **Vantaux** : ils sont tranchés au niveau du muret (0,54 m), avec la même tranche sombre.
* **Seuil** : un seuil de pierre est encastré à fleur du sol, des deux côtés. Aucun relief n'est praticable, et l'outil
  `reliefs_p6` ne signale rien.
* **Variante B, « silhouette »** (retenue par défaut) : la partie retirée (haut des vantaux et arc) reste visible en
  **transparence** (32 %, légèrement désaturée), à sa vraie taille.
  * La porte se lit fermée et entière.
  * Aren reste visible derrière : voir le gros plan, où il se tient contre la porte, côté coursive.
* **Variante A, « coupe seule »** : jambages, seuil et vantaux tranchés, sans silhouette. Elle est plus « dessin
  d'architecte », mais une porte fermée se lit moins bien.

**Comparaison** :
* **Depuis l'infirmerie** : les trois versions sont identiques. Le mur est entier et la porte est complète.
* **Depuis la coursive** : la variante B est la seule où la porte reste identifiable à sa vraie taille.

Ce traitement s'applique à toutes les portes fermées du Colisée, par cohérence (loge, gradins est, portes de service).
Les collisions et le verrouillage de la réserve ne changent pas : la sonde « réserve fermée » est réussie.

**Défaut corrigé pendant le pilote** : l'un des deux vantaux est un modèle en miroir (échelle négative), et ses faces
s'affichaient en noir. Le shader de coupe en tient compte (`miroir`).

## 3. Matériaux du pilote

**Matériau unique** : `src/p6/maconnerie_p64.gdshader`, un matériau **procédural**.
* **Calepinage en mètres** : assises inégales en cycles de trois, longueurs de blocs variables d'une assise à l'autre,
  décalage propre à chaque assise.
* **Variation par élément** : teinte, deux familles de pierre (calcaire ocre et gris chaud), modelé peint (haut plus
  clair, bas plus sombre).
* **Grain peint** : la luminance seule de `art/p4/mat/roche.png`, décalée pour chaque pierre.
* **Arêtes et salissure** : arêtes usées ou épaufrées ; pied des murs sali et verdi ; coulures sous les arêtes hautes.
* **Joints filtrés** et **relief** par dérivées d'écran (biseaux, joints creux, tuiles bombées), affaibli avec la
  distance.

Quatre motifs (appareil de pierre, dallage, planches, tuiles) et onze préréglages sont regroupés dans
`P64_PRESETS`. Les UV restent cohérentes avec la géométrie :
* faces planes en UV monde ;
* anneaux des gradins et galerie en UV métriques qui suivent l'arc (`_rq`, `_rt`).

| Zone pilote | Éléments | Matières P6.4 |
|---|---|---|
| **1. Gradins et galerie** | Portion sud-ouest des gradins (95°–185°) et du podium ; toute la galerie des écoinçons | Contremarches en appareil de calcaire, dalles usées, assises en lames de bois le long de l'arc, socle du podium en gros blocs ; tuiles canal, contreforts en gros appareil, corniches |
| **2. Vestiaires** | Mur nord (deux pans) et linteau, plinthe ; **porte nord** | Appareil de calcaire, assises hautes plus sombres, corniche et chaperon en moulure claire, soubassement ; **nouvel encadrement de pierre** (jambages en saillie, bases, impostes, plate-bande à 7 claveaux avec clé), qui suit la coupe du mur |
| **3. Coursive** | Murs nord et ouest, linteau de la loge, **dallage** de toute la pièce | Appareil de calcaire ; grandes dalles gris ocre à joints sombres, polies au centre, verdies dans les joints |

**Palette** : un calcaire ocre doré, mêlé de gris chaud, à la place du gris-violet des textures P4. La valeur générale
a été baissée (0,8) après un premier essai trop clair. Les personnages restent bien lisibles sur le dallage
(contraste de valeur et de teinte, voir la planche 3 et la vidéo).

**Comparaison avec la forêt** (`comparaison_foret.jpg`) :
* **Rapprochements** : les matières sont peintes et chaudes, et les ombres sont douces.
* **Différences voulues** : la forêt reste plus saturée, avec des verts et des terres. Le Colisée est plus minéral et
  plus sombre en intérieur, éclairé par des sources locales chaudes.
* **Rapprochements avec Octopath Traveler II** : chaque pierre est lisible, les joints sombres sont marqués, les
  lumières sont chaudes et localisées.
* **Ce qui manque encore** : des textures réellement peintes à la main (le grain procédural reste propre), des éléments
  de récit sur les murs (graffitis, affiches, réparations), et la profondeur de champ en intérieur.

## 4. Lumière locale

Seulement dans les zones pilotes, avec des lumières fixes, sans ombre portée ni scintillement de flamme. L'éclairage
global n'est pas modifié.
* **Vestiaires** : la salle d'attente éclaire le passage (lumière chaude derrière la porte), ce qui détache
  l'encadrement. Une lumière d'appoint douce est ajoutée devant le mur.
* **Coursive** : une lumière froide zénithale douce sépare le dallage des murs, et deux halos chauds sont placés sous
  les lanternes du mur nord.
* **Gradins sud-ouest** : une lueur courte et chaude sort des braseros sur le podium et les premiers rangs.

## 5. Répétition et scintillement

**Répétition** (`tools/p6/repetition_p64.py`) : on calcule l'autocorrélation de la luminance d'une zone de la
capture, après avoir retiré l'éclairage. L'indice est le plus fort pic secondaire **isolé**, de 0 à 1.
* Au-dessus de 0,45, une tuile répétée est visible.
* Le rythme régulier des joints horizontaux n'est pas compté.

| Zone (même cadrage) | P6.3.2 | P6.4 |
|---|---|---|
| Mur nord des vestiaires | **0,82** (tuile de 256 px visible) | **0,10** |
| Mur nord de la coursive | 0,28 | 0,14 |
| Dallage de la coursive | 0,17 | 0,23 (rangs réguliers de dalles, pas de tuile) |
| Écoinçon sud-ouest : terrasse / galerie | 0,43 | **0,81** : régularité du motif des tuiles canal (canaux de 20 cm), pas une texture répétée, mais une lecture encore mécanique (voir § 1) |

**Scintillement** (`tools/p6/clignotements_p6.py`, même méthode qu'en P6.3.2) : nombre de pixels qui « clignotent »
par image, médiane par tranches de 100 images. Les mêmes parcours ont été rendus avec P6.3.2 et avec P6.4.

| Parcours / tronçon | P6.3.2 | P6.4 |
|---|---|---|
| `p6_video_64`, vestiaires (images 0–300) | 0–24 | 0–23 |
| `p6_video_64`, abords des gradins sud-ouest et de la galerie (300–400) | 1 730 | **849** (−51 %) |
| `p6_video_64`, arène, hors pilote (400–500) | 1 385 | 1 460 (+5 %) |
| `p6_video_64`, coursive (500–800) | 626 / 646 / 639 | **379 / 413 / 507** |
| `p6_video_64`, coursive, retour (1000–1094) | 635 | **375** |
| `p6_clignotements`, le long du mur ouest de la coursive (500–734) | 663 / 570 / 424 | **410 / 523 / 232** |
| `p6_clignotements`, moyenne de tout le parcours | 626 | 565 |

**Pourquoi la baisse** : les joints et le grain sont filtrés. Quand un joint devient plus fin qu'un pixel, sa teinte
moyenne remplace le trait, au lieu de sauter d'un texel à l'autre. Le bruit fin s'éteint lui aussi à distance.
L'éclairage n'a pas été utilisé pour masquer quoi que ce soit.

**Scintillement qui reste** :
* sur les planchers et les sols hors pilote (textures P4) ;
* dans l'arène hors pilote, où il est stable.

**Gradins sud-ouest vus de dos** : vus presque de dos et en angle rasant, les gradins sud-ouest laissent paraître
leurs assises « en tronçons ». C'est le facettage de 2,5° des anneaux. Le défaut est identique en P6.3.2, et il est
aussi présent sans secteurs et sans ombres : il ne vient pas du pilote. Il se corrigerait par un anneau plus finement
facetté, au moins pour les assises.

## 6. Inventaire des ressources utilisées

**Aucune nouvelle image, aucun nouveau modèle, aucun pack importé.**

| Ressource | Statut | Usage P6.4 |
|---|---|---|
| `src/p6/maconnerie_p64.gdshader` | **nouveau**, procédural, PROVISOIRE | Toutes les matières des zones pilotes et de la galerie |
| `src/p6/coupe_p64.gdshader`, `src/p6/fantome_p64.gdshader` | **nouveaux** | Portes fermées en coupe : partie tranchée, puis silhouette |
| `art/p4/mat/roche.png` (1024², Drive REL-01 v03, « à tester ») | existant | Grain de **luminance** seulement, décalé pour chaque pierre (noté dans `art/p4/SOURCES.md`) |
| `art/p63/quaternius/mv/DoorFrame_Round_Brick`, `Door_8_Round` (CC0, textures RockTrim, WoodTrim, MetalOrnaments) | existants | Encadrement et vantaux des portes en coupe et en silhouette (mêmes textures, matériau remplacé à l'exécution) |
| Autres modèles Quaternius (bancs, lanternes, bannières…) | existants | Inchangés |
| Textures P4 (`pierre_taille`, `sol_paves`, `planches`…) | existantes, provisoires | **Hors pilote seulement** : le reste du Colisée |

## 7. Tests et mesures de rendu

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel`, `e2e_p4_retour` | réussis |
| Parcours `p4` et `p4_sondes` | réussis |
| Sondes de collision `p6_sondes` (dont « réserve fermée ») | 10 / 10 |
| Reliefs visibles traversables (`reliefs_p6`) | aucun (seules les étiquettes de debug sont listées, comme avant) |
| Circulation à une touche, azimut 0° | 4 tronçons, 3/3, 0 % de contact mural |
| Caméra, `p6_video_631` (62 s) | 0 bond |
| F5 | se charge sans erreur |

**Coût de rendu** (`perf_pieces_p6`, rendu logiciel, appels de dessin et primitives) :

| Position | P6.3.2 | P6.4 |
|---|---|---|
| Vestiaires | 876 / 85 k | 924 / 86 k |
| Tunnel sud | 387 / 53 k | 421 / 79 k |
| Arène (entrée) | 411 / 31 k | 431 / 50 k |
| Arène (centre) | 331 / 29 k | 351 / 48 k |
| Coursive | 275 / 24 k | 291 / 35 k |
| Infirmerie | 405 / 36 k | 404 / 36 k |

* Les appels de dessin augmentent de 0 à 9 %, et la mémoire vidéo de 288 à 293 Mo.
* Les primitives augmentent surtout à cause de la galerie : elle ajoute de 20 à 26 k triangles selon la vue, et les corniches et
  contreforts sont rendus des deux côtés.
* Le **coût des fragments** du shader procédural (plusieurs bruits, une texture de grain, relief par dérivées) ne se
  mesure pas en rendu logiciel. Le temps d'image lavapipe est saturé (environ 133 ms, identique avant et après). **À
  vérifier sur votre GPU.** Les endroits à regarder : la coursive, et l'arène face à la galerie.

## Décision attendue

Pilote arrêté ici pour validation artistique. Quatre questions :
1. **Galerie couverte** des écoinçons : la retenir ? Avec quelle variation de toiture ?
2. **Porte en coupe** : la variante B (coupe et silhouette), la A, ou une autre piste ?
3. **Matières** : la palette calcaire ocre et gris, le dallage de la coursive et l'appareil des murs vous conviennent-ils
   pour être étendus au reste du Colisée ? Ou préférez-vous des textures peintes à la main (à fournir), avec le même
   calepinage ?
4. **Lumière locale** : faut-il l'étendre de la même manière ?
