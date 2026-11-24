# P7.5 — Porte du Colisée et quartier central V0.7-B

Branche **`p7-5-ville-v07b`**, créée depuis l'état stabilisé de P7.4.2 (branche `p7-4-ville-v07a`).

**BLOCKOUT CONSOLIDÉ, EN ATTENTE DE VOTRE EXAMEN, non validé.** Hors périmètre, comme demandé (§ 9) :
* le Colisée n'est pas reconstruit ;
* pas d'intérieurs définitifs, d'instances de mission, de nouveau système de jeu, de foule, d'habillage détaillé ni de
  reprise de l'éclairage ;
* aucune ressource n'est supprimée.

La **V0.7-A reste intacte en référence** : `scenes/p7/ville_v07a.tscn`, `data/p7/ville_v07a.json` et son générateur.

| Commit | Contenu |
|---|---|
| `a8e5ab3` | § 2 — porte du Colisée à deux battants (commit séparé, sur la branche P7.4) |
| `bcc5cab` | Captures de la porte, vidéo de l'arène P7.4.2 |
| `1cc6d7f` | § 3 à 8 — V0.7-B : données, scène F6, parcours de test |
| (ce commit) | Ajustement de lisibilité de l'accès B, plan, comparatifs, vidéo, ce rapport |

## 1. La porte du Colisée (§ 2)

La porte est placée dans l'**arche sud du propylée**, celle qui fait face à la caméra. L'arche est en reste aveugle.
* Deux battants de bois sombre, avec bandes de fer, clous, anneaux et seuil de pierre.
* Elle est légèrement en retrait des piles, et un tympan remplit le cintre au-dessus du linteau.
* On la reconnaît de loin, dès l'allée (`docs/media/p7_5/porte_colisee_4_vues.jpg`).
* Les bannières, les lanternes et le porche sont conservés.

**Transition.** Le socle n'a pas d'animation d'ouverture. L'entrée se fait donc par **interaction (E)** devant la porte,
puis par le **fondu existant**.
* Le portail `colisee_porte_publique` ne change pas, ni l'arrivée dans le Colisée (61,5 ; 23), tournée vers l'ouest.
* Le point de retour se déplace sur le perron, devant l'angle sud-est du propylée : (34,6 ; 68,8), tourné vers l'est.
* Pas de redéclenchement : la porte se franchit par E, et l'arrivée de retour se fait hors de portée.
* Le tunnel de 9 m et la caméra provisoire ne changent pas.

## 2. Tracé de la V0.7-B (§ 3, § 4, § 8)

Plans comparés : `docs/media/p7_5/plans_v07a_v07b.png`. Plan seul : `docs/media/p7_5/plan_v07b.png`.

**Progression principale**, du sud vers le nord autour de la grande place :
1. Porte sud, puis placette d'accueil (Guilde, auberge-taverne).
2. Montée en baïonnette, en deux volées de 6 m décalées.
3. Grande place.
4. Montée civique monumentale, en deux volées de 8 m décalées.
5. Terrasse haute.
6. Accès gardé du château.

**Les trois terrasses.**

| Terrasse | Contenu |
|---|---|
| **Basse (0 m)** | Porte sud (sortie réelle, inchangée), placette d'accueil, Guilde près de l'entrée, **auberge-taverne** à l'est de la volée A avec sa terrasse, ruelle et rue du chantier en décor |
| **Moyenne (3,5 m)** | Grande place et fontaine, **forge-armurerie** au nord, **boutique de fournitures** dans un recoin au nord-est, étals en bordure (sud et est), **accès monumental du Colisée** à l'ouest (allée, propylée, porte). Aucune seconde place de marché |
| **Haute (8 m)** | **Hôtel de ville** au nord-est, **bâtiment administratif** à l'ouest, accès gardé du château au fond, château en arrière-plan |

**Boucle courte et utile** : grande place → bras est → ruelle des Tonneliers (escalier de 4 m) → terrasse de l'auberge →
placette → montée → grande place. Elle dure 49 s au pas.

**Hiérarchie des largeurs.**

| Élément | Largeur |
|---|---|
| Rues principales | 8 à 12 m |
| Ruelle | 4 m |
| Volées ordinaires | 6 m |
| Montée civique | 8 m |
| Paliers et placettes | 5 à 6 m de profondeur |

Il n'y a plus d'escalier pleine largeur ni de grande avenue droite. L'ancienne rue haute, qui finissait en cul-de-sac à la
grille, est fermée par du bâti.

**Limite à vous signaler.** Le socle décrit les surfaces praticables en **rectangles**. Le « fer à cheval » se lit donc par
l'enchaînement des espaces (montées décalées, place enveloppée par les fronts bâtis, retour par la ruelle), pas par des rues
courbes. Le plan reste orthogonal. Des rues réellement courbes demanderaient des surfaces polygonales dans le socle, ce qui
est une évolution du moteur, hors du périmètre de cette étape.

**Par rapport à la V0.7-A**, la V0.7-B garde le même squelette : place, montées et Colisée au même endroit. Ses apports sont
les suivants :
* auberge, boutique, hôtel de ville et administration ;
* la boucle par la terrasse de l'auberge ;
* la fermeture de la rue haute ;
* les trois accès futurs ;
* les prolongements visuels.

C'est une consolidation, pas un nouveau plan. Si vous attendiez un tracé radicalement différent, dites-le-moi avant la suite.

## 3. Une ville plus grande que son espace jouable (§ 5)

Prolongements visuels **sans collision**, placés au-delà des fronts bâtis :
* escaliers qui montent vers des secteurs inaccessibles ;
* arches au-dessus de rues lointaines ;
* tours à mi-distance ;
* volumes de toits ;
* château en fond.

Les limites se lisent par l'architecture (façades, garde-corps, murs de terrasse), jamais par une collision invisible. Les
sondes le vérifient : chaque bord poussé s'arrête contre un volume visible.

## 4. Accès futurs (§ 6)

| Accès | Où | Obstacle | Visible depuis |
|---|---|---|---|
| **A** — quartier est | Rue du chantier, à l'est de la placette | Barrière de chantier | Placette basse |
| **B** — faubourgs ouest | Passage à l'ouest du parvis du Colisée | **Caravane** dételée (plateau, roues, bâche, caisses) | Parvis du Colisée |
| **C** — château | Fond de la terrasse haute | **Grille fermée, deux guérites et deux gardes** | Terrasse haute |

Aucun lieu ne montre les trois accès à la fois. La porte sud reste une vraie sortie.

**Correction faite pendant l'étape.** Le bâtiment au sud du passage des faubourgs cachait entièrement la caravane. Il est
ramené à un volume bas (1,2 m), et l'accès B se lit désormais depuis le parvis.

## 5. Caméra (§ 7)

C'est la caméra P7.4.1, sans changement :
* perspective, plongée 11°, distance fixe (×3) ;
* aucun zoom manuel, aucune rotation continue, aucune limite écran.

La caméra **A** (fixe) est le défaut. **B** (semi-fixe) reste en comparaison avec la touche V. Elle n'a plus qu'un secteur,
celui de la révélation du Colisée : le secteur de la montée du château n'a plus de raison d'être, car la montée est désormais
face à la caméra.

Visite complète `p7_v07b_video` (266 s : tous les secteurs, la porte du Colisée, les accès A, B et C, la boucle) :

| | A | B |
|---|---|---|
| Bonds de caméra | **0** | **0** |
| Images hors zone confortable | **0** | **0** |
| Position d'Aren à l'écran | x 560–719, y 357–486 px | x 560–719, y 358–486 px |
| Rotations | aucune | 10 épisodes, 0 inversion |

**Masquage.** La mesure brute (un rayon d'Aren vers la caméra) compte aussi les volumes bas tout proches de la caméra,
pourtant tramés à l'affichage. Elle donne un masquage continu de 14 à 18 s au plus, du même ordre que la V0.7-A (16 à 18 s).
Sur les captures, Aren reste visible partout. Un seul masquage réel, et bref : la colonne de la fontaine, quand Aren passe
juste derrière.

## 6. Tests (état final)

| Test | Résultat |
|---|---|
| Tests unitaires (`run_tests.gd`) | 76 sur 76 |
| Ouverture P6 de bout en bout (`--tuto-rapide`), saut du tutoriel | réussis |
| Sondes du Colisée `p6_sondes` | 10 sur 10 |
| Forêt F5 (chargement), V11 | sans erreur, 0 échec |
| Arène invisible depuis les vestiaires (`visibilite_vestiaires_p644.gd`) | aucun maillage de l'arène |
| Chargement de la V0.6, de la V0.7-A et de la V0.7-B | sans erreur de script |
| Sondes de la V0.7-B `p7_v07b_sondes` (bords, façades, caravane, gardes, guérites, grille), A et B | **34 sur 34** dans les deux modes |
| Trajets de la V0.7-B `p7_v07b_trajets`, A et B | **28 étapes sur 28** dans les deux modes |
| Portail ville V0.7-B ↔ Colisée (`p7_v07_portail`, deux allers-retours), A et B | 4 passages alternés, 4 arrivées exactes, aucun redéclenchement |
| Caméra, visite complète, A et B | 0 bond, 0 image hors zone confortable |

**Temps de trajet au pas (2,2 m/s), mesurés.**

| Trajet | V0.7-B | V0.7-A |
|---|---|---|
| Porte sud → grande place | 25 s (par la Guilde) | 28 s |
| Grande place → porte du Colisée | 38 s | 29 s |
| Fontaine → accès du château | 34 s | 35 s |
| Boucle (place → ruelle → auberge → placette → place) | 49 s | — (pas de boucle fermée) |

## 7. Médias (`docs/media/p7_5/`)

* `porte_colisee_4_vues.jpg` : la porte, de loin et de près.
* `plan_v07b.png`, `plans_v07a_v07b.png` : plans tirés des données.
* `comparaison_v07a_v07b.jpg` : huit lieux équivalents, V0.7-A à gauche et V0.7-B à droite.
* `v07b_16_vues.jpg` : seize vues de la V0.7-B en caméra A (porte sud, auberge, chantier, place, boutique, Colisée,
  faubourgs, montée civique, château, ruelle).
* `visite_v07b_camera_A.mp4` : la visite complète.

## 8. Fichiers

* `tools/p7/build_ville_v07b.py` et `data/p7/ville_v07b.json` : le quartier (données générées, à ne pas éditer à la main).
* `scenes/p7/ville_v07b.gd` : caravane, guérites, gardes, escaliers, arches et tours de décor. Hérite de la V0.7-A.
* `scenes/p7/ville_v07b.tscn` : la scène F6.
* `scenes/p6/colisee.gd` : version « v07b » de la ville (chargement, caméra, portail).
* `scenes/p7/ville_v06.gd` : faîtages des toits partagés avec la V0.7-B.
* `src/explore25/routes25.gd` : parcours `p7_v07b_sondes`, `p7_v07b_trajets`, `p7_v07b_vues`, `p7_v07b_video` et
  `p7_v07b_diag`.
* `tools/p7/plan_v07a.py` : accepte un fichier de données en second argument.

## Non vérifiable ici

* **Rendu sur GPU réel** : tout est en rendu logiciel (lavapipe).
* **Ressenti au clavier** : les parcours sont joués par un pilote automatique.
* **Lecture des accès et de l'échelle par un joueur** : à juger par vous.

## Points à arbitrer

1. Le tracé orthogonal (voir la limite au § 2) suffit-il, ou faut-il des rues courbes, donc des surfaces non
   rectangulaires dans le socle ?
2. Le trajet grande place → Colisée passe de 29 à 38 s, car l'allée part de l'ouest de la place. Faut-il le raccourcir ?
3. Caméra B : faut-il la garder en comparaison, alors qu'elle n'a plus qu'un secteur ?
