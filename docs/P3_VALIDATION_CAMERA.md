# Validation de la caméra A / C — audit de reprise et rapport avant verrouillage (Godot 4.7.2)

Branche **`p3-validation-camera`**, partie de `p3-camera-profondeur` (commit `56c532c`, laissée intacte).
Date : 11 novembre 2026. Références : documents Drive 01, 04, 07, 09, 10 et 12 ; `docs/P3_CAMERA_PROFONDEUR.md`.

**Statut : la caméra n'est PAS verrouillée.** Ce rapport établit tout ce qui peut l'être sans joueur et sans carte
graphique. Deux points restent à la main du créateur : **le confort en jeu** et **les performances GPU**
(`docs/PROTOCOLE_VALIDATION_CAMERA_GPU.md`, environ 25 minutes). Le pilote artistique P4 n'est pas commencé.

Ni le combat, ni la carte d'exploration principale, ni `project.godot` ne sont modifiés. **F5 lance toujours
`scenes/explore_hd2d/zone_exploration.tscn`.**

## 1. Résumé

| Question | Réponse | Niveau de preuve |
|---|---|---|
| Le projet fonctionne-t-il sous Godot 4.7.2 ? | Oui : import sans erreur, 90/90 tests, retour de combat réussi, F5 chargé sans erreur | rejoué ici |
| C casse-t-il quelque chose par rapport à A ? | Non : parcours 26/26, collisions 15/15, 0 saut d'altitude, 0 image hors décor, mêmes occultations | rejoué ici |
| C montre-t-il plus loin devant ? | Oui en montant à l'écran (+15 % de temps d'anticipation) ; **non en descendant (−21 à −23 %)** | mesuré en marche simulée |
| Le point faible de C | Marche vers le bas de l'écran à ×3 : 1,7 s d'anticipation en moyenne (A : 2,2 s), 1,1 s au minimum | mesuré |
| C dans la petite instance | Sans effet à ×2 ; effet partiel à ×2,5 et ×3 (le rapport P3-07 disait « aucun effet ») | captures |
| Le rendu Compatibility (OpenGL) fonctionne-t-il avec le paysage ? | Oui, sans erreur de rendu | rejoué ici (rendu logiciel) |
| Le rendu Forward+ | **Jamais vérifié par un agent** : aucune machine de test n'avait de GPU Vulkan | à faire sur le PC |
| Performances GPU | **Non mesurées** | à faire sur le PC |
| Confort en main | **Non établi** | à faire par le créateur |

**Recommandation provisoire : C reste la candidate**, à confirmer par le test manuel. Si la marche vers le bas à ×3
gêne, tester un décentrage plus faible (héros vers 58 %) avant de revenir à A. Détail au § 7.

## 2. Audit de reprise

### Ce qui a été rejoué sous Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`)

| Vérification | Résultat annoncé (P3-07) | Résultat rejoué |
|---|---|---|
| Import du projet (`--headless --import`) | — | 0 erreur |
| Tests automatiques | 89/89 | **89/89**, puis 90/90 avec le test ajouté ici |
| Retour de combat (`tests/e2e_zone_retour.gd`) | réussi | **réussi** |
| Chargement de la scène F5 (`--quit-after 60`) | sans erreur | **sans erreur** |
| Parcours complet `temoin`, variantes A et C | 26/26 | **26/26** chacune |
| Collisions ciblées `sondes`, variantes A et C | 15/15 | **15/15** chacune |
| Sauts d'altitude, positions hors surface (héros, compagnon) | 0 | **0** |
| Images montrant du vide hors décor | 0 | **0** (parcours, limites, petite instance, aux trois zooms) |

La variante B (plongée 28°) n'a pas été rejouée : elle est écartée par les documents 07 et 12.

### Godot 4.7.2 et `config/features`

- `project.godot` déclare toujours `config/features=PackedStringArray("4.5")`. L'import et les tests en ligne de
  commande sous 4.7.2 **ne réécrivent pas** ce fichier. Je ne l'ai pas modifié.
- L'éditeur 4.7.2 réécrira probablement cette ligne en `"4.7"` la première fois que les paramètres du projet seront
  enregistrés depuis l'interface. C'est sans effet sur le jeu, mais cela rend le projet « plus récent » pour un
  Godot 4.5. **Décision à prendre par le créateur** ; en attendant, ne pas valider ce changement s'il apparaît dans Git.
- L'import sous 4.7.2 ajoute trois clés à `art/3d/vorgane_rig.glb.import` (nouvelles options d'import). Sans effet
  constaté ; non validé dans Git, pour ne pas toucher à un fichier du combat.
- En rendu Compatibility, Godot signale `2D MSAA is not yet supported for GLES3` : le réglage `msaa_2d` du projet y
  est ignoré. Sans conséquence sur les scènes 3D testées.

### Informations obsolètes corrigées

- `README.md` : la section « Lancer le jeu » annonçait Godot 4.5 à 4.7 et la branche `p2-environnements`. Elle
  indique maintenant Godot 4.7.2 obligatoire, la branche courante, ce que lance F5 et comment ouvrir les scènes F6.
  Le nombre de tests (61) est mis à jour.
- `CLAUDE.md` : l'ancienne règle « F5 doit toujours lancer la dernière version » contredisait les briefs P3, P3-07
  et celui-ci. Elle est remplacée par : **F5 reste sur l'exploration stable jusqu'à l'accord explicite du créateur ;
  les scènes expérimentales s'ouvrent avec F6.** `run/main_scene` n'a pas été touché.

### Écarts relevés par rapport au rapport P3-07

1. **Rendu réellement utilisé.** Sur une machine sans Vulkan, Godot bascule de lui-même sur le rendu
   **Compatibility (OpenGL)**. Les captures et vidéos de cette branche sont donc en Compatibility, et c'était très
   probablement déjà le cas pour P3-07. Conséquence : le rendu Compatibility avec paysage est vérifié, mais **Forward+,
   le rendu par défaut du projet, ne l'a été que par les essais du créateur**.
2. **Petite instance.** « C n'y a aucun effet » n'est exact qu'à ×2. À ×2,5 et ×3, le cadre a un peu de jeu dans les
   limites et C décale légèrement la vue (voir § 5).
3. **Passage de 0,5 m devant la maison.** Il n'est pas « étroit » : il est **infranchissable** (rayon du héros
   0,28 m, soit 0,56 m nécessaires). Le test `sondes` vérifie d'ailleurs que le héros y est arrêté.
4. **Ligne d'aide en bas de l'écran.** Elle est coupée à droite à 1280 × 720 et ne mentionne pas les touches V et L.

## 3. Ce qui a été ajouté sur cette branche

| Fichier | Contenu |
|---|---|
| `src/explore25/routes25.gd` | parcours `validation` : 8 directions avec demi-tours, escalier (montée et descente), tour de la maison, tour de l'arbre, pont dans les deux sens, sortie, 4 coins de la petite instance, retour |
| `src/explore25/session25.gd` | mesures de cadrage en marche (place du héros dans l'écran, anticipation par direction et par tronçon), épisodes d'occultation localisés, position des à-coups de caméra |
| `scenes/explore25/explore_3d.gd` | option `--tag=`, description de la machine dans le fichier de mesures (carte graphique, pilote, rendu obtenu, V-Sync) |
| `tools/perf/mesure_gpu.bat`, `.sh`, `resume_gpu.gd` | mesure GPU en un double-clic et tableau de synthèse |
| `tests/unit/test_validation_camera.gd` | le parcours couvre le brief et ne vise que des points praticables ; F5 inchangé |
| `docs/PROTOCOLE_VALIDATION_CAMERA_GPU.md` | protocole de test manuel et de mesure GPU |
| `docs/media/validation_camera/` | vidéos A / C côte à côte aux trois zooms, planches de limites et de petite instance, mesures brutes |

Les règles de déplacement, de collision, de caméra et les variantes A / B / C elles-mêmes ne sont pas modifiées.

## 4. Comparaison A / C en déplacement

Parcours `validation`, clavier simulé (8 directions), 63 s de marche par série, une série par zoom et par variante.
Vidéos côte à côte, même parcours, mêmes instants :
[×2](media/validation_camera/validation_AC_x2.mp4) ·
[×2,5](media/validation_camera/validation_AC_x2-5.mp4) ·
[×3](media/validation_camera/validation_AC_x3.mp4).

Mesures brutes : `docs/media/validation_camera/mesures/`.

### Place du héros dans la hauteur de l'écran (0 % = haut)

| | ×2 | ×2,5 | ×3 |
|---|---|---|---|
| A — moyenne (minimum à maximum) | 55,8 % (46 à 74) | 54,3 % (45 à 79) | 53,9 % (44 à 78) |
| C — moyenne (minimum à maximum) | 61,4 % (50 à 74) | 62,1 % (49 à 79) | 62,4 % (49 à 78) |

Le héros ne s'approche jamais à moins de 10 % d'un bord latéral, de 15 % du haut ni de 12 % du bas, dans aucune série. Les
maximums (74 à 79 %) sont identiques en A et en C : ils viennent des butées de cadrage au bord sud et dans la petite
instance, pas du décentrage.

### Anticipation : temps de marche entre le héros et le bord du cadre, dans le sens de la marche

C'est le temps dont dispose le joueur entre l'apparition d'un obstacle à l'écran et le moment où il l'atteint
(vitesse de marche 3,6 m/s). Valeurs moyennes, minimum entre parenthèses.

| Direction à l'écran | A ×2 | C ×2 | A ×2,5 | C ×2,5 | A ×3 | C ×3 |
|---|---|---|---|---|---|---|
| Vers le haut | 4,5 s (2,7) | **5,0 s** (3,3) | 3,5 s (2,1) | **4,0 s** (2,6) | 2,8 s (1,7) | **3,3 s** (2,1) |
| Diagonales hautes | 5,8 s (2,6) | 5,9 s (2,6) | 4,6 s (2,3) | 4,7 s (2,6) | 3,8 s (1,8) | 3,9 s (2,3) |
| Gauche et droite | 4,5 s (1,8) | 4,5 s (1,8) | 3,5 s (1,8) | 3,5 s (1,8) | 2,8 s (1,5) | 2,8 s (1,5) |
| Diagonales basses | 5,5 s (2,6) | 4,7 s (2,0) | 4,5 s (2,0) | 3,7 s (1,5) | 3,7 s (1,6) | 3,0 s (1,2) |
| **Vers le bas** | 3,4 s (2,3) | **2,9 s** (1,8) | 2,7 s (1,4) | **2,2 s** (1,4) | 2,2 s (1,3) | **1,7 s** (1,1) |

Lecture :

- **Vers le haut**, C gagne environ une demi-seconde à tous les zooms (+10 à +18 %).
- **Latéralement**, A et C sont identiques, comme attendu.
- **Vers le bas**, C perd environ une demi-seconde (−17 % à ×2, −21 % à ×2,5, −23 % à ×3). À ×3, il reste
  1,7 s en moyenne, soit environ 6 m de sol devant le héros. C'est le seul endroit où C est nettement moins bon que A.
- En A comme en C, la direction la plus pauvre est déjà « vers le bas » : l'écran est plus large que haut.

Par tronçon, à ×2,5 (moyenne) : escalier A 3,0 s / C 3,3 s ; maison A 3,6 s / C 3,4 s ; arbre A 3,7 s / C 3,2 s ;
pont A 3,7 s / C 3,7 s ; petite instance A 3,7 s / C 3,7 s.

### Suivi de caméra

| | A | C |
|---|---|---|
| À-coups de caméra en marche (variation de vitesse > 100 px/s entre deux images) | 0 | 0 |
| Accélération maximale du cadre | 2 195 px/s² à ×2,5 | 2 195 px/s² à ×2,5 (écart de 1 % à ×2) |
| Recentrage pendant le dialogue | sans objet | transition de 0,33 s, sans à-coup mesuré |

Un à-coup est compté à ×3 dans les deux variantes : il se produit à la toute première image, quand le test impose
le zoom de départ. Ce n'est pas un défaut en jeu.

## 5. Limites de cadrage, occultation, petite instance

### Limites de cadrage

Sept positions de bord, trois zooms, A et C :
[×2](media/validation_camera/limites_AC_x2.jpg) ·
[×2,5](media/validation_camera/limites_AC_x2-5.jpg) ·
[×3](media/validation_camera/limites_AC_x3.jpg).

- Aucune vue ne montre de vide : le paysage couvre tout ce que le cadre peut atteindre.
- Près du bord **sud**, le décentrage de C cède à la butée : A et C donnent la même image.
- Près du bord **nord** (terrasse), C monte plus haut que A et montre davantage le quartier en gradins.

### Occultation

Les volumes étant identiques, **A et C masquent le héros exactement aux mêmes endroits et aussi longtemps**.

| Lieu | Durée continue pendant laquelle le héros est caché |
|---|---|
| Derrière la maison | 1,9 s sur le parcours `validation`, 2,3 s sur le parcours `temoin` |
| Derrière l'arbre | 1,6 s |
| Sur la place, près de l'arbre (occultant non identifié) | 0,8 s |

Ce qui reste insatisfaisant, dans les deux variantes :

1. **Derrière la maison, le héros disparaît entièrement** ; seule la silhouette bleue le signale, plaquée sur le
   toit. C'est l'aide « artificielle » déjà relevée par le document 12.
2. **Les jambes sont masquées par le garde-corps avant du pont** et par les **haies du bord sud** : la silhouette
   bleue y apparaît en permanence sur les pieds.
3. La transparence locale (touche **O**, troisième mode) existe mais n'est pas le réglage par défaut et n'a pas été
   jugée en main.

Ces points relèvent du pilote P4 (masquage localisé, hauteur des garde-corps et des haies), pas du choix A / C.

### Petite instance (placette de 10 × 7 m)

[×2](media/validation_camera/instance_AC_x2.jpg) ·
[×2,5](media/validation_camera/instance_AC_x2-5.jpg) ·
[×3](media/validation_camera/instance_AC_x3.jpg).

- À **×2**, le cadre est entièrement contraint : image fixe, identique en A et en C. La placette occupe environ un
  tiers de l'écran, entourée de façades.
- À **×2,5 et ×3**, le cadre suit un peu le héros, et C décale la vue vers le haut de quelques dizaines de pixels.
- Arrivée et retour : recentrage immédiat, sans glissade, zoom conservé.
- Aucun vide. La question ouverte est artistique : une instance plus petite que l'écran donne une vue presque fixe,
  quelle que soit la variante.

## 6. Performances

**Aucune mesure GPU n'a pu être faite** : la machine de travail n'a pas de carte graphique. Les seules valeurs
disponibles sont en rendu logiciel et ne valent pas mesure : environ 9 images par seconde, 330 appels de dessin et
250 000 primitives par image avec le paysage (ombres comprises), identiques en A et en C à l'unité près.

Ce qui est établi : **A et C dessinent la même scène**, donc le choix de la variante ne devrait pas changer le coût.
Ce qui ne l'est pas : le coût réel du paysage, des ombres et de la brume sur le PC cible, en Forward+ et en
Compatibility.

Mesure à faire : `tools\perf\mesure_gpu.bat` (8 minutes, sans intervention), décrit dans
`docs/PROTOCOLE_VALIDATION_CAMERA_GPU.md`. Le fichier `mesures_gpu\RESUME_GPU.md` complétera cette section.

## 7. Recommandation avant verrouillage

1. **C reste la candidate.** Elle n'introduit aucune régression, aucune occultation supplémentaire, aucun à-coup,
   et elle améliore la lecture vers le haut de l'écran, là où se trouvent le relief et le paysage.
2. **Son coût est réel et localisé** : environ une demi-seconde d'anticipation en moins quand on marche vers le bas
   de l'écran, sensible surtout à ×3. Seul un essai en main dit si c'est gênant.
3. **Si c'est gênant**, la première chose à essayer est un décentrage plus faible (héros vers 58 % au lieu de 63 %),
   qui partage la différence. C'est un changement d'une valeur dans `src/explore25/variantes25.gd` ; je ne l'ai pas
   ajouté pour ne pas multiplier les variantes avant le retour du créateur.
4. **Ne pas verrouiller** tant que le protocole manuel et la mesure GPU ne sont pas revenus.

## 8. Problèmes connus et corrections nécessaires

| # | Problème | Gravité | Quand le traiter |
|---|---|---|---|
| 1 | Performances GPU et rendu Forward+ non vérifiés par un agent | bloquant pour le verrouillage | protocole, maintenant |
| 2 | Confort de C non jugé en main | bloquant pour le verrouillage | protocole, maintenant |
| 3 | Héros entièrement caché derrière la maison ; silhouette bleue artificielle | à corriger | P4 (masquage localisé) |
| 4 | Jambes masquées par le garde-corps du pont et les haies du bord sud | à corriger | P4 |
| 5 | Passage de 0,5 m devant la maison infranchissable | à décider : l'élargir à 0,8 m au moins, ou le fermer visiblement | avant P4 si la maison est habillée |
| 6 | Vue presque fixe dans une instance plus petite que l'écran | à décider : taille minimale d'instance ou marge de décor | règle de level design |
| 7 | La rivière s'arrête net au bord du plateau | cosmétique | P4 si elle est dans le cadre |
| 8 | Ligne d'aide coupée à droite, touches V et L absentes | mineur | à la prochaine retouche de l'interface de test |
| 9 | `config/features` encore à « 4.5 » | décision du créateur | quand il le souhaite |
| 10 | Le parcours simulé marche à vitesse constante en lignes droites : il ne remplace pas un joueur | limite de méthode | protocole manuel |

## 9. Reproduire

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

```bash
godot --headless --path . res://scenes/explore25/camera_variante_C.tscn -- --route=validation --zoom=1 --quit --nodebug --tag=z1 --out=/tmp/validation
```

```bash
godot --path . res://scenes/explore25/camera_variante_C.tscn -- --route=limites --quit --nodebug --out=/tmp/validation
```

```bash
godot --path . res://scenes/explore25/camera_variante_C.tscn -- --route=captures --instance=res://data/explore25/instance_2_fictive.json --quit --nodebug --out=/tmp/validation
```

`--zoom=0`, `1` ou `2` choisit ×2, ×2,5 ou ×3. Remplacer `_C` par `_A` pour la référence. Les mesures de cadrage ne
dépendent pas du rendu : elles sont identiques avec ou sans `--headless`.
