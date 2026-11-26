# P7.4 — Ville V0.7-A : micro-blockout semi-circulaire, caméra fixe (A) contre caméra semi-fixe (B)

Branche **`p7-4-ville-v07a`**, issue de **`p7-3-ville-v06`** (commit de base `a0b4748`).
Elle contient le nettoyage P7.2 et le correctif des vestiaires P6.4.4.

**EXPÉRIENCE DE CONCEPTION, NON VALIDÉE.** Le quartier entier n'est pas reconstruit : seul l'itinéraire représentatif du
brief l'est.

**Ouvrir** : F6 sur `scenes/p7/ville_v07a.tscn`.

| Touche ou option | Effet |
|---|---|
| **V** ou `-- --camera_ville=A` / `B` | Caméra A (fixe) ou B (semi-fixe) |
| **L** | Libellés |
| `-- --etat=tutorial_completed` | Départ dans le Colisée ; sa sortie mène au parvis du Colisée de la V0.7-A |

## 1. Recommandation

**La caméra B est recommandée, sous conditions. A reste la référence de repli.**

La géométrie, les trajets (moins de 1 s d'écart) et la séquence sont strictement les mêmes. B apporte une chose que A ne
peut pas donner avec ce tracé : depuis l'approche de la grande place, **le Colisée entre dans le cadre** (arcades, tambour),
alors qu'en A il reste hors champ jusqu'à l'embranchement. Le critère « Colisée identifiable depuis la place » n'est
atteint qu'en B.

Mesures (outil de continuité, parcours vidéo complet) :
* **aucun bond** de caméra ;
* **aucune inversion de sens** de rotation ;
* aucun blocage ;
* Aren reste à sa place à l'écran pendant les rotations (déplacement au plus 4 px par image, comme en A).

Ce que B coûte :
* **8 rotations** sur la séquence (environ 25 s cumulées sur 246 s), à 14° par seconde au plus. C'est doux, mais présent
  à chaque passage d'une limite de secteur.
* Les volumes proches de la caméra passent plus souvent dans la zone estompée en trame : façade bleue de la Guilde à
  l'arrivée sur la place, toit de l'immeuble à l'est de la volée B.
* Le gain au château est faible : la terrasse se lit déjà bien en A. On peut retirer le second secteur sans perdre
  l'essentiel.

**Proposition** : garder **un seul secteur B**, celui de la « révélation du Colisée », et revenir à A partout ailleurs. Si
vous jugez la rotation gênante dans la vidéo, A reste valable : il faut alors accepter que le Colisée ne se découvre qu'à
l'embranchement.

## 2. Ce qui a été construit

Plan : `docs/media/p7_4/plan_v07a.png`, tiré des données par `tools/p7/plan_v07a.py`.

Il distingue les rues praticables (teinte par niveau), les volées, le bâti à collision, les volumes purement visuels, les
accès bloqués et les zones de la caméra B.

| Étape du brief | Réalisation |
|---|---|
| 1. Quartier bas, porte sud, respiration | Porte de 6 m ; **placette des Voyageurs** de 24 × 18 m ; Guilde au nord de la placette, façade face caméra |
| 2. Montée courbe / décalée, plus étroite | **Deux volées de 6 m de large**, en baïonnette (vers l'est), autour d'un **palier** à 1,75 m. Un **belvédère** domine le palier. V0.6 : une volée de 12 m |
| 3. Portion de grande place commerçante | Place de 42 × 27 m à 3,5 m (fontaine), bras vers l'est. Fronts denses : forge-armurerie face caméra, échoppes, commerce à l'est. Pas de place du marché séparée |
| 4. Embranchement ouest, vue du Colisée | Rue du Colisée (8 m), puis **parvis** au pied du tambour. Le Colisée est au nord-ouest de la place, **entrée publique au sud, face caméra** : porche, fronton, bannière de la Guilde, deux registres d'arcades, attique, bannières rouges. Volume fermé : **l'arène n'est jamais visible**. L'architecture intérieure du Colisée n'est pas touchée (instance séparée, raccord testé) |
| 5. Montée vers la terrasse haute | Deux volées de 6 m en baïonnette et un palier à 5,75 m, puis la **terrasse haute** (8 m) : avenue et porte du château fermée, château et ville haute au loin |
| 6. Ruelle secondaire | **Ruelle des Tonneliers**, 4 m : du bras est de la place, un escalier étroit descend à la rue du chantier, qui ramène à la placette. Boucle courte : place → ruelle → placette → volées |
| 7. Départs de rues futures | **Rue du chantier** (est de la placette), fermée par une barrière, un échafaudage et des matériaux. **Rue haute** (est de la terrasse), fermée par une grille. Au-delà, volumes de décor non praticables |

Tracé : la porte sud, les deux montées en baïonnette, la place puis l'embranchement vers le Colisée, et enfin la montée
vers le nord-est dessinent un arc autour de la place. Le socle n'accepte que des sols rectangulaires et des escaliers qui
montent vers le nord : la courbure vient des décalages successifs, pas de rues réellement courbes.

Hauteurs d'essai : 0 / 1,75 / 3,5 / 5,75 / 8 m. Elles restent réglables dans le générateur.

Les règles de composition de la V0.6 sont conservées :
* les bâtiments-repères ont leur façade au sud ;
* entre la caméra et les lieux d'arrêt, il n'y a que des volumes bas (murets de 1,2 m, portique de 2,5 m, toits des
  volumes bas plafonnés à 70 % de leurs murs) ;
* les volumes à moins de 12 m de la caméra s'estompent.

## 3. Le protocole de caméra

| Paramètre | A | B |
|---|---|---|
| Projection, champ, plongée | Perspective, 30°, 11° (V0.6) | Identiques |
| Distance | Une seule (×3, molette sans effet) | Identique |
| Suivi en altitude | Lissé (0,45 s) | Identique |
| Orientation | Nord, partout | Nord, sauf dans 2 secteurs des données |

Secteurs de B :
* **« révélation du Colisée »** : grande place, rue et parvis du Colisée, rotation de −16° ;
* **« montée du château »** : palier 2 et terrasse haute, rotation de +12°.

Fonctionnement de B :
* **Hystérésis** : on entre dans un secteur par son rectangle, on n'en sort qu'à 2 m au-delà. Aller-retour à la limite :
  0 inversion mesurée.
* **Rotation** : ressort à amortissement critique (0,55 s), vitesse bornée à 14° par seconde. Le cadrage est recalé à
  chaque image : Aren ne bouge pas à l'écran, la caméra tourne autour de lui.
* **Jamais de suivi du cap du personnage.** La rotation dépend seulement du secteur.
* **Commandes** : tant qu'une direction est tenue, elle garde l'azimut d'avant la rotation (la marche ne dérive pas) ;
  l'azimut est resynchronisé au relâchement. Aucune inversion n'est possible : la rotation fait au plus 16°.
* **Repli sur A** : touche V, ou B sans secteurs dans les données.

Le système de caméra du Colisée, de la forêt et des autres scènes n'est pas modifié. Le verrou des commandes
(`World25.yaw_commande_actif`) est inactif hors de la ville.

## 4. Mesures et tests

### Temps de trajet (marche 2,2 m/s, mêmes résultats en A et B à moins de 1 s près)

| Trajet | A | B |
|---|---|---|
| Porte sud → premier palier | 15,4 s | 15,4 s |
| Premier palier → grande place | 12,5 s | 12,2 s |
| Porte sud → grande place | 27,9 s | 27,6 s |
| Grande place → porche du Colisée | 28,9 s | 29,9 s |
| Grande place → porte du château | 34,9 s | 35,2 s |
| Place → ruelle → chantier → placette | 37,1 s | 36,9 s |

Pour comparaison, en V0.6 : porte sud → fontaine en 34,9 s (avec le détour par la guilde). La distance porte → première
montée est d'environ 22 m (10 s), ce qui laisse une respiration sans allonger artificiellement le parcours.

### Caméra : outil `tools/p6/camera_continuite_p6.gd`, séquence vidéo complète

L'outil a reçu deux options : `--scene=` et une mesure de la rotation.

| | A | B |
|---|---|---|
| Durée de la séquence | 243 s | 246 s |
| Bonds | 0 | 0 |
| Distance caméra–Aren | 22,39 m (constante) | 22,39 m (constante) |
| Déplacement d'Aren à l'écran, au plus | 4,1 px/image | 4,0 px/image |
| Rotations | 0 | 8 épisodes, 1 522 images, 14 °/s au plus, **0 inversion** |
| Blocages | 0 | 0 |

### Collisions : 18 sondes sur 18 en A comme en B

Ont été vérifiés :
* les façades de la guilde et de la forge ;
* le front ouest de la placette et le socle du palier ;
* les garde-corps : belvédère, place (vide de 3,5 m), palier 2 et terrasse (vide de 4,5 m) ;
* la fontaine, le front nord de la rue du Colisée et le front sud du parvis ;
* les portes du Colisée et du château, et la grille de la rue haute (fermées) ;
* la barrière du chantier, le mur de la ruelle et la barrière de la route sud.

### Non-régression

Tout passe :
* tests unitaires : 76 sur 76 ;
* ouverture P6 de bout en bout et saut du tutoriel ;
* `p6_sondes` : 10 sur 10 ;
* F5 (forêt) et V11 ;
* chargement de la V0.6 ;
* raccord Colisée → V0.7-A ;
* vestiaires P6.4.4 (`tools/p6/visibilite_vestiaires_p644.gd`) : depuis les vestiaires, **aucun groupe de maillages de
  l'arène visible**.

### Performances et occultations (relevés pendant les vidéos, rendu logiciel)

| Mesure | A | B | V0.6 |
|---|---|---|---|
| Appels de rendu (max) | 1 051 | 1 051 | 821 |
| Primitives (max) | 32 958 | 32 958 | 34 280 |
| Mémoire vidéo | 212 Mo | 212 Mo | 212 Mo |

La rotation B ne coûte rien de mesurable. Les appels de rendu augmentent de 28 % par rapport à la V0.6, pour deux raisons :
* chaque arcade du Colisée est une boîte : 44 travées × 3 registres ;
* les marches et les joues des cinq volées sont dessinées une par une.

**Avant tout habillage, il faudra fusionner ces volumes en maillages uniques.**

Le test d'occultation (rayons physiques d'Aren vers la caméra) signale deux longs tronçons, dans les deux modes :
* place → rue du Colisée : 23 s en A, 29 s en B ;
* ruelle → chantier → placette : 22 s.

Sur les images (`occultations_video_A.jpg`), **Aren reste visible**. Les rayons touchent des murets bas (1,2 m) et des
volumes déjà estompés près de la caméra, qui gardent leur collision. Seul défaut visible : au chantier, **le muret au sud de
la rue couvre les pieds d'Aren**. Il faudrait l'abaisser à 0,8 m ou le reculer.

### Limites de l'environnement

* **Rendu logiciel seulement** (lavapipe, sans GPU) : les images par seconde et le flou de distance sont à juger sur
  votre machine ; seuls les appels de rendu et les primitives ont valeur de comparaison.
* **Parcours joués par un pilote automatique** : le ressenti au clavier n'est pas mesurable ici, en particulier celui du
  verrou des commandes pendant une rotation.

## 5. Défauts et points ouverts

1. **B estompe davantage les façades proches** : la caméra pivote autour d'Aren et passe au-dessus d'autres volumes, comme
   la Guilde à l'arrivée sur la place.
2. **Le Colisée vu de près**, depuis le parvis, se lit comme un grand mur courbe. Sa courbure se lit mieux en B ou depuis
   la rue. Son sommet est coupé par le cadre (plongée de 11°).
3. **Le château** reste une silhouette d'horizon, dans les deux modes (même limite qu'en V0.6).
4. **Courbes approchées** par des rectangles décalés : une vraie rue courbe demanderait de faire évoluer le socle.
5. **Le pilote automatique** suit maintenant les directions avec l'azimut des commandes dans les deux modes, pour que A et
   B parcourent exactement les mêmes trajectoires. Pour un joueur, en A, cela ne change rien : l'azimut des commandes y
   est toujours celui de la caméra.

## 6. Traçabilité

| Fichier | Modification |
|---|---|
| `tools/p7/build_ville_v07a.py` → `data/p7/ville_v07a.json` | Nouveau : générateur et données (secteurs de caméra compris) |
| `scenes/p7/ville_v07a.gd`, `scenes/p7/ville_v07a.tscn` | Nouveau : affichage (masses, Colisée extérieur, chantier, château déplacé), scène F6 |
| `tools/p7/plan_v07a.py` | Nouveau : plan simplifié |
| `scenes/p6/colisee.gd` | Mode « ville v07a », caméra B (`_yaw_secteurs`, `_secteur_camera`), touche V, azimut rétabli en quittant la ville |
| `src/explore25/world25.gd` | `yaw_commande_actif` / `yaw_commande`, `plan_to_input` (inactifs par défaut) |
| `src/explore25/session25.gd` | Le pilote utilise `plan_to_input` quand l'azimut des commandes est actif |
| `scenes/p7/ville_v06.gd` | `_toit(…, cap)` : toit plafonné, pour la V0.7-A seulement ; V0.6 inchangée |
| `src/explore25/routes25.gd` | Parcours `p7_v07_vues`, `p7_v07_video`, `p7_v07_trajets`, `p7_v07_sondes`, `p7_v07_raccord` |
| `tools/p6/camera_continuite_p6.gd` | Mesure de la rotation (épisodes, vitesse, inversions) |

Aucun fichier supprimé ; aucune ressource P4 réintégrée ni retirée ; S6 à S9 non exécutés.

### Dépendances résiduelles du Colisée envers `scenes/p4/avant_poste.gd` (relevé, sans refactorisation)

`colisee.gd` hérite de ce script. Il en utilise :
* des **fonctions de construction** : `_surf` (14 appels), `_tinted` (25), `_card` (9), `_faces` (31), `_light`, `_halo`,
  `_env`, `_build_tilt`, `_build_ui`, `_make_actor` ;
* des **méthodes redéfinies qui appellent la version de base** : `_ready`, `_load`, `_build`, `_decor_floor`,
  `_apply_variante`, `apply_camera`, `_sync_sprite`, `_unhandled_input`, `_physics_process`, `_process`, `_switch`,
  dialogues ;
* des **tables** : `CAMS`, `CHARS`, `MATS` ;
* un **shader** : `SURF_SH`, aussi utilisé par `habillage_p6.gd`.

Les parties de ce script propres à l'avant-poste (eau, berges, arbres, maisons P4, garde, monstre) ne sont plus
appelées. Elles pourront être retirées lors d'un futur refactoring, à décider.

### Médias (`docs/media/p7_4/`)

* `ville_v07a_camera_A.mp4` et `ville_v07a_camera_B.mp4` : même séquence, même résolution (1280 × 720, 30 i/s).
* `ab_entree_place_colisee.jpg`, `ab_montee_chateau_retour.jpg`, `ab_autres_reperes.jpg` : captures A/B aux mêmes repères.
* `plan_v07a.png` : plan simplifié.
* `occultations_video_A.jpg` : images de la vidéo A aux tronçons signalés par le test d'occultation.
