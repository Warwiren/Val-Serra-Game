# P6.2-C — Caméra, tunnel et découverte de l'arène

> **P7.2 (nettoyage autorisé par le créateur)** : les médias de ce rapport (`docs/media/…`) ont été retirés du projet
> actif. Ils restent dans l'historique Git : `git checkout d88eac4 -- docs/media/<dossier>`.

Branche **`p6-2c-tunnel-visibilite`**, issue de `p6-2b-transitions-interieurs` (conservée).

Sont inchangés :
* Godot 4.7.2 ;
* le mode B comme base provisoire ;
* l'azimut 0°, la plongée 24°, le champ 30° et le zoom ×3 ;
* les ombres douces en qualité 4 ;
* les collisions, les dialogues, la progression, CombatCore et le saut du tutoriel ;
* F5 (forêt).

Le prototype porte uniquement sur les vestiaires, la salle d'attente, le tunnel et l'entrée immédiate de l'arène. La
coursive et la sortie est ne sont pas modifiées.

**À tester** : ouvrir `scenes/p6/colisee.tscn` avec F6. La touche J (A / B / C) reste disponible pour comparer.

## Livrables

| | |
|---|---|
| Vidéo continue, 12 étapes, vitesse réelle | [`tunnel_p6_2c.mp4`](media/p6_2c/tunnel_p6_2c.mp4) |
| Même trajet avant / après, côte à côte | [`tunnel_avant_apres.mp4`](media/p6_2c/tunnel_avant_apres.mp4) |
| Captures : salle, milieu du tunnel, sortie, seuil, arène | [`captures_avant_apres.jpg`](media/p6_2c/captures_avant_apres.jpg) |
| Mesure de la caméra image par image | [`camera_continuite.png`](media/p6_2c/camera_continuite.png) (CSV régénérable : `tools/p6/camera_continuite_p6.gd -- --route=p6_tunnel --etat=tutorial_completed --csv=…`) |

Le trajet (`--route=p6_tunnel`) enchaîne :
1. départ au centre des vestiaires ;
2. approche de la porte nord ;
3. passage dans la salle ;
4. arrêt juste après le seuil ;
5. pas en arrière, puis nouveau franchissement ;
6. traversée de la salle ;
7. entrée dans le tunnel ;
8. arrêt au milieu ;
9. sortie progressive ;
10. marche jusqu'au commandant ;
11. retour vers le tunnel ;
12. nouveau franchissement du seuil.

Les touches utilisées et le secteur actif sont affichés en bas de l'image.

## 1. Sauts de caméra

### Mesure

`tools/p6/camera_continuite_p6.gd` relève, à chaque image physique :
* la position 3D réelle de la caméra, sa vitesse et son accélération ;
* son recul le long de son axe (un changement de recul = un changement de zoom) ;
* la position d'Aren à l'écran.

Une image est comptée comme un **bond** dans l'un de ces cas :
* la caméra va plus vite qu'Aren + 1 m/s ;
* elle accélère de plus de 30 m/s² au-delà de l'accélération d'Aren ;
* Aren immobile se déplace de plus de 6 px à l'écran.

Le suivi normal (zone morte, lissage) reste sous ces seuils.

| | P6.2-B | **P6.2-C** |
|---|---|---|
| Images en bond (trajet de 30,8 s) | **134** | **0** |
| Vitesse maximale de la caméra | 38,2 m/s | 2,2 m/s (= Aren) |
| Déplacement maximal d'Aren à l'écran en une image | 39 px | 1,4 px |
| Recul de la caméra (zoom) | constant | constant |

### Cause

Les **limites de caméra par pièce** de P6.2 :
* La salle (12 m) et les vestiaires sont **plus étroits que la vue** à ×3 (21 m). Cam25 fige alors le centre de la caméra
  au milieu de la pièce.
* Le passage et le tunnel n'ont pas de limites propres, donc la caméra se remet à suivre Aren.
* À chaque seuil, les limites changent. Le cadrage est alors recalé **après** le lissage (`clamp_center` appliqué à la
  fin de `Cam25.update`). Résultat : un saut de 37 m/s au seuil, puis un recentrage de 1 à 2 s, Aren arrêté (20 m/s).
* La zone de stabilité de 0,4 m n'y pouvait rien : elle retarde la bascule, mais ne l'adoucit pas.

### Correction

En modes B et C, les limites sont **communes à tout le bâtiment** (celles du niveau). La caméra suit Aren partout avec
le même lissage, et un franchissement de seuil n'a plus d'effet sur elle. Le mode A garde ses limites par pièce, pour
comparaison. La caméra de la forêt n'est pas touchée.

Après un arrêt, la caméra rejoint Aren en environ 0,4 s (lissage existant), sans dépassement ni oscillation. Sur un
petit pas en arrière, il n'y a pas de tremblement : la zone morte de 18 × 10 px absorbe le mouvement.

## 2. Découverte de l'arène

* **Salle d'attente** : la révélation progressive de P6.2-B (`revele_ext`) est supprimée. Depuis la salle, on voit les
  Chasseurs, la porte et le début du tunnel. Le linteau et le mur nord (6 m) ferment la vue : pas de gradins ni de loge.
* **Tunnel** : c'est désormais un intérieur (secteur S3 sombre, couvert). L'arène n'y est vue que par des **lignes de vue
  réelles à travers la bouche** (`src/p6/vue_tunnel.gdshader`) :
  * un point de l'arène n'est affiché que si le segment Aren → point, vu du dessus, passe par l'ouverture (3 m) ;
  * le reste prend la teinte sombre de l'intérieur, comme derrière les murs ;
  * au milieu du tunnel, on voit un cône étroit, dans l'axe, avec le commandant au bout et la lumière du jour qui entre ;
  * plus Aren avance, plus le cône s'ouvre : rien n'est déclenché, tout dépend de la position.
* **Sortie du tunnel** : entre la bouche (y = 32) et 2,4 m plus loin, le masque s'efface progressivement. On découvre
  alors le sable, puis les gradins de part et d'autre, la loge et les murs d'enceinte. Au retour, la vue se referme de
  la même façon.

Ce n'est pas un fondu global : à tout instant, ce qui est affiché est ce qu'Aren pourrait voir par la bouche.

Mise en œuvre :
* un quad plein écran dessiné après la scène ;
* la position de chaque pixel est reconstruite depuis la profondeur ;
* aucun maillage, matériau ni collision n'est modifié.

Correction associée : le voile du reste du niveau restait bloqué à 0,014 au lieu de 0. L'arène était donc rendue dans la
passe transparente (plus cher, et sans profondeur). Les extrémités sont maintenant exactes.

## 3. Grands murs à l'entrée de l'arène

Cause : dans l'arène, le secteur actif devenait « EXT ».
* Plus aucun mur n'était coupé, donc le mur nord de la salle et son linteau (prolongés à 6 m en P6.2-B) masquaient tout
  le sol de l'arène sur 6 à 13 m au-delà du tunnel. Aren y disparaissait entièrement (captures « avant », positions 5
  à 7).
* Les murs du tunnel, classés « intérieur » parce qu'ils touchent la salle, montaient aussi à 6 m.

Corrections, architecturales :
* **L'arène devient une « zone ouverte » S4.** C'est la pièce de référence pour les coupes : les murs du bâtiment situés
  devant elle perdent leur partie haute (muret de 0,5 m conservé). Son décor reste celui du niveau, ce qui ne change
  rien pour la coursive.
* **Les murs du tunnel sont ramenés à hauteur de voûte (3,1 m)** et ne sont jamais coupés. Ils encadrent la vue sans
  former de grandes lames.
* **Un arc bas à la bouche** (2,3 à 3,1 m) encadre la vue depuis l'intérieur. Il est coupé dès qu'Aren est dans l'arène,
  pour ne pas barrer son chemin à l'écran.
* Au retour vers le tunnel, la partie haute des murs revient (estompage de 0,45 s), le tunnel se referme autour d'Aren
  et la vue se recadre par la bouche.

Le ciel réel est rendu dans S4, comme auparavant dans l'arène.

Les **PNJ** appartiennent désormais à la pièce où ils se tiennent. Leur emprise de sprite débordait sur le reste du
niveau : avec la nouvelle règle, les Chasseurs de la salle auraient été masqués.

## 4. Tests

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | **83 / 83**, tests de secteurs mis à jour : arène S4, salle sans révélation, voile exact, murs coupés dans l'arène (salle, arc) et jamais ceux du tunnel |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel` | réussis |
| Sondes `p6_sondes` | 10 / 10 : collisions inchangées |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` | réussis |
| F5 | se charge sans erreur |
| Continuité de la caméra | 0 bond sur le trajet de 12 étapes |

Ces tests ne valident pas l'aspect artistique.

Coût de rendu, en appels de dessin, mesuré en **rendu logiciel lavapipe (pas une validation GPU)** :

| Position | P6.2-B | **P6.2-C** |
|---|---|---|
| Vestiaires | 931 | 936 |
| Passage | 784 | 796 |
| Salle d'attente | 482 | **219** (arène plus rendue) |
| Milieu du tunnel | 441 | **409** |
| Sortie du tunnel | 431 | **398** |
| Entrée de l'arène | 817 | **365** (bâtiment coupé, arène en passe opaque) |

Mesures prises par `tools/p6/perf_pieces_p6.gd`, état `tutorial_completed`, même outil et même état des deux côtés.
Elles ne sont pas comparables aux chiffres du rapport P6.2-B, pris dans un autre état. Le masque du tunnel ajoute un seul
quad plein écran.

## 5. Limites

* Le masque de vue s'appuie sur la profondeur. Un objet en cours d'estompage ou un sprite transparent est jugé d'après ce
  qui se trouve derrière lui. Cela ne concerne en pratique que les fondus de 0,45 s.
* La lumière ambiante est celle de l'intérieur tant qu'Aren est dans le tunnel : l'arène vue par la bouche est un peu
  plus sombre, puis s'éclaire à la sortie (adaptation, 0,2 s). À juger.
* L'arc de la bouche passe brièvement au-dessus d'Aren, à l'écran, dans le premier mètre de l'arène, avant d'être coupé.
* Aucun test GPU n'a été possible ici.
* L'étape C (arène entière, coursive) n'est pas commencée.

## 6. Packs Quaternius (CC0)

La notice du Drive a été lue. Les deux archives (40 et 56 Mo) n'ont **pas pu être téléchargées** : l'hôte de
téléchargement de Google Drive est refusé par le réseau de cet environnement de travail, et l'outil Drive renvoie les
fichiers en base64, ce qui n'est pas praticable à cette taille. Rien n'a donc été importé ni examiné visuellement.

Avant d'envisager une intégration, il faudra vérifier les points suivants :
* proportions des modèles au zoom ×3 ;
* matières « low-poly » stylisées face aux textures peintes et aux sprites ;
* rendu sous les lanternes ;
* coût en appels de dessin.

Les modèles prioritaires de la notice sont pertinents d'abord pour les **vestiaires et la salle** : Bench, WeaponStand,
Peg_Rack, Lantern_Wall, Dummy, Chest_Wood, Barrel, et pour l'encadrement des portes, Wall_Arch et DoorFrame_Round_Brick.
Les modules rectangulaires ne conviennent pas aux gradins ovales.

Le pilote prévu, après validation de cette étape :
* sur une branche dédiée ;
* avec seulement les modèles choisis et `License_Standard.txt` dans `art/` ;
* avec une comparaison avant / après dans les vestiaires.

## 7. Décision attendue

1. Caméra : retenez-vous les limites communes au bâtiment ?
2. Tunnel : la vue par la bouche, puis la découverte à la sortie, vous convient-elle ?
3. Arène : l'arc bas et les murs du tunnel à 3,1 m vous conviennent-ils ?
