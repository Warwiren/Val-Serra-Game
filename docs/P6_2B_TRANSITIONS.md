# P6.2-B — Transitions visuelles des intérieurs (vestiaires, passage, salle d'attente, tunnel)

Branche **`p6-2b-transitions-interieurs`**, issue de `p6-2-colisee-circulation-visibilite` (conservée pour comparaison).
Godot 4.7.2, ombres douces qualité 4, azimut 0° du Colisée, collisions, parcours, dialogues, progression, combat
tutoriel et saut du tutoriel **inchangés**. F5 inchangé.

**À tester** : `scenes/p6/colisee.tscn`, F6. Le Colisée démarre en **mode B**. La **touche J** fait défiler
A → B → C au même endroit (ligne de commande : `-- --transitions=A|B|C`).

| Mode | Principe |
|---|---|
| **A — P6.2** (référence) | les pièces non visibles s'abaissent vers le sol puis disparaissent ; fond noir autour |
| **B — continu** (proposé) | rien ne bouge : architecture persistante, estompage sur place de ce qui gêne |
| **C — porte** | règles de B, appliquées d'un coup sous un bref fondu sombre au seuil vestiaires ↔ passage |

Vidéos, même trajet et même cadrage, à vitesse normale :
* [`transitions_A_B_C.mp4`](media/p6_2/transitions_A_B_C.mp4) (A, puis B, puis C, 25 s chacun) ;
* [`transitions_B_continu.mp4`](media/p6_2/transitions_B_continu.mp4) (B seul).

Le trajet : centre des vestiaires → approche de la porte nord → seuil → arrêt au milieu du passage → petit pas en arrière
dans la porte → en avant → retour dans les vestiaires → nouvelle entrée dans la salle → approche du tunnel →
découverte de l'arène. Les touches utilisées et le secteur actif sont affichés en bas de l'image.

Captures A / B aux mêmes positions : [`transitions_A_B_captures.jpg`](media/p6_2/transitions_A_B_captures.jpg).

## 1. Ce qui change en mode B

`src/explore25/secteurs25.gd` reste la base réutilisable. Il traite maintenant séparément cinq catégories :

1. **Structure persistante.** Les murs forment des groupes à part, **jamais masqués**. Les murs des pièces intérieures
   sont **prolongés jusqu'à 6 m** : partie haute assombrie, corniche à 3 m, haut en coupe sombre. Les portes
   intérieures reçoivent un **linteau**. Ces murs hauts cachent naturellement les pièces voisines situées derrière : rien
   n'a besoin de disparaître sous les yeux du joueur.
2. **Décor d'une pièce.** Il est rangé par **emprise au sol** : un élément à cheval sur deux pièces appartient aux deux
   (sols, bancs ; 24 éléments relevés au chargement). Seules les pièces situées **devant** la pièce active, entre elle et
   la caméra, sont estompées **sur place**, par transparence en 0,45 s, puis ne sont plus rendues. Les pièces situées
   derrière restent affichées.
3. **Éléments qui masquent Aren.** Seule la **partie haute** d'un mur gênant s'estompe. Le muret de 0,5 m reste, et une
   tranche sombre apparaît en même temps. C'est local, mur par mur : un mur qui ne gêne pas reste entier. Les murs
   entièrement devant la pièce active perdent aussi leur partie haute, pour éviter de grandes masses sombres au premier
   plan.
4. **Lumière.** Plafonds « ombres seulement » au-dessus des murs prolongés. Ils sont invisibles pour la caméra et jamais
   masqués : le soleil ne rentre pas, les lanternes font la lumière. Le **fond** et la **lumière ambiante** glissent
   (intérieur sombre chaud ↔ jour) au lieu de basculer.
5. **Extérieur et reste du niveau.**
   * Parvis et bâtiments lointains : masqués tant qu'on est dans une pièce intérieure.
   * L'**arène se révèle selon la position d'Aren** dans la salle d'attente : invisible à l'entrée de la salle,
     progressivement visible en approchant du tunnel, et inversement au retour. Rien n'est déclenché à un instant
     donné.
   * Au bout du tunnel, le **panneau lumineux est remplacé par une vraie lumière** (le jour de l'arène qui éclaire le
     tunnel).

**Optimisation sans disparition visible** : l'**occultation du moteur** est activée dans le Colisée. Chaque mur haut
porte un occulteur ; le moteur ne dessine pas ce qu'il cache, et l'occulteur est coupé dès que le mur s'estompe.

## 2. Stabilité aux seuils

* **Zone de stabilité de 0,4 m** : le secteur actif est conservé tant qu'Aren reste à moins de 0,4 m de ses limites.
* Un arrêt au milieu du passage, un pas en arrière dans la porte ou un pas en avant ne provoquent **aucune bascule
  répétée** : vidéo, et test unitaire « stabilité ».
* Une transition commencée s'inverse proprement : chaque estompage repart de l'état courant, sans saut.
* Le cadrage glisse vers les limites de la pièce, sans à-coup.

## 3. Mode C (porte)

C'est un bref fondu sombre (0,14 s, puis 0,22 s) au seuil vestiaires ↔ passage, avec la nouvelle pièce appliquée d'un
coup. Il est utilisable pour une **vraie porte fermée** ou un changement d'intérieur. Les ouvertures continues
(passage → salle, salle → tunnel) gardent le comportement B : pas d'écran sombre dans un couloir ouvert.

**Avis** : sur ces pièces, toutes reliées par des ouvertures, **C n'apporte pas d'avantage réel sur B**. Je le garde comme
outil pour les futures portes fermées (Guilde, maisons, commerces).

## 4. Mesures

**Occlusion visible d'Aren** (`tools/p6/occlusion_visuelle_p6.gd`) : le gain de P6.2 est conservé.

| | P6.1 | A | **B** |
|---|---|---|---|
| Vestiaires | 4 % | 2 % | **2 %** |
| Salle d'attente | 36 % | 0 % | **0 %** |
| Ensemble | 14,8 % | 1,2 % | **1,2 %** |

**Coût de rendu** (`tools/p6/perf_pieces_p6.gd`, rendu logiciel lavapipe, à confirmer sur GPU), en appels de dessin :

| Position | Sans secteurs | A | **B** | C |
|---|---|---|---|---|
| Vestiaires | 825 | 389 | **545** | 545 |
| Passage | 707 | 651 | **781** | 1051 (pendant le fondu) |
| Salle d'attente | 638 | 182 | **501** (arène à demi révélée) | 501 |
| Tunnel | 470 | 450 | **462** | 462 |

B coûte plus que A, parce que les pièces situées derrière restent rendues et que l'arène se révèle. Il reste **sous la
version sans secteurs** dans les pièces (−34 % dans les vestiaires, −21 % dans la salle). C'est le compromis « sobre,
même légèrement plus coûteux » demandé.

Le surcoût le plus net est au passage (781 contre 707), seul endroit où les deux pièces sont visibles en même temps.

Transparences : seulement pendant les 0,45 s d'un estompage, puis les objets masqués ne sont plus rendus. Lumières :
celles des pièces estompées sont éteintes avec elles. Ombres : lanternes en double paraboloïde, qualité 4.

## 5. Tests

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | **83 / 83** (+1 : mode B — pièces derrière conservées, pièces devant estompées, murs jamais masqués, arène progressive, stabilité au seuil, éléments à cheval) |
| `e2e_p6_ouverture` (`--tuto-rapide`), `e2e_p6_saut_tutoriel` | réussis |
| Sondes de collision `p6_sondes` | **10 / 10 dans chacun des modes A, B et C** : les collisions ne dépendent pas de l'affichage |
| Circulation à une touche | 4 / 4 tronçons, aucun contact mural |
| P4 (e2e, `p4` 29 / 29, `p4_sondes` 20 / 20), P5, forêt (V09B.5, V09C, V11), P5.2, P5.3-B | réussis |
| F5 | inchangé, sans erreur |

Ces tests ne valident pas l'aspect artistique.

## 6. Limites

* Le libellé de zone « Salle d'attente » apparaît dès le passage : sa zone nommée inclut le passage (données P6).
* Depuis le tunnel, les montants de la porte de la salle restent hauts de part et d'autre : à revoir avec l'habillage
  du tunnel.
* Les silhouettes d'autres parties du bâtiment (murs de la coursive) apparaissent en bordure de cadre depuis les
  vestiaires. C'est voulu, pour la continuité, mais à juger.
* Arène, coursive et sortie ne sont pas traitées (étape C non commencée).
* Aucun test GPU possible ici.

## 7. Décision attendue

1. Retenez-vous le **mode B** ?
2. Le mode C doit-il être réservé aux futures **portes fermées** ?
3. Ensuite seulement, l'étape C sur l'arène et la coursive.
