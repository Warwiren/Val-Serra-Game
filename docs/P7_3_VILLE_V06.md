# P7.3 — Ville V0.6 : caméra HD-2D et ville ascendante (démonstration verticale)

Branche **`p7-3-ville-v06`**, issue de **`p7-2-nettoyage`**, elle-même issue du blockout V0.1 (`p7-1-ville-blockout-v01`).
Le correctif des vestiaires (P6.4.4) et l'audit (P7.0) y sont fusionnés.

**PROTOTYPE NON VALIDÉ** : ce document décrit une démonstration à examiner en vidéo ; rien n'est présenté comme définitif.

## Ce qui a été fait

| Brief V0.6 | Réalisation |
|---|---|
| § 2 — caméra propre à la ville | Caméra de la ville seule : perspective, **plongée 11°**, **champ 30°**, une seule distance (zoom ×3 fixe ; molette et PgPréc / PgSuiv sans effet), altitude suivie lissée (0,45 s). Le Colisée, la forêt et les autres zones gardent leur caméra (rétablie en quittant la ville) |
| § 2 — comparer orthographique / perspective | Touche **C** : V0.6 perspective (proposée) / V0.6 orthographique (même plongée) / caméra V0.5 (P24 ×3) |
| § 3 — trois niveaux | Bas 0 m (porte sud, guilde, auberge-taverne), médian 3,5 m (grande place, fontaine, commerces dont la forge-armurerie, accès au Colisée à l'ouest), haut 8 m (hôtel de ville, archives, porte du château fermée). Deux montées par escaliers (10 m puis 12 m de long) |
| § 4 — espace jouable réduit | Une seule avenue nord-sud, une place, un parvis, deux seuils (guilde, auberge). Plus de place du marché indépendante ; plus de rue des Aventuriers ; aucune circulation entre bâtiments décoratifs |
| § 5 — plans de profondeur | Premier plan (fronts latéraux, estompés en trame près de la caméra), rues praticables, gradins de façades et de toits au-dessus de chaque mur de soutènement, horizon : quartier du château (décor seul) dans la brume |
| § 6 — périmètre | Parcours vertical seul : porte sud → guilde → montée → grande place → montée vers le quartier haut. Le reste du quartier n'est pas reconstruit |
| § 7 — sécurité | Branche dédiée ; Colisée, forêt et blockout V0.1 inchangés (la V0.1 reste ouvrable en F6) ; collisions des données ; aucun fichier supprimé dans cette étape |

**Ouvrir** : F6 sur `scenes/p7/ville_v06_montee.tscn`. Départ à la porte sud. Avec `-- --etat=tutorial_completed`, le départ se
fait dans le Colisée, et la sortie est mène à la rue du Colisée de la V0.6 (raccord testé). Touche **L** : libellés des
bâtiments-clés (coupés par défaut, pour juger l'image).

## 1. Choix de la projection et du cadrage

### Recommandation : perspective

| Critère | Perspective 11° / 30° | Orthographique 11° |
|---|---|---|
| Profondeur urbaine | Les plans successifs rapetissent : gradins de toits, mur de soutènement, château à l'horizon | Aplatie : tous les plans à la même échelle ; les volumes proches de la caméra deviennent des blocs |
| Horizon, bâtiments lointains | Visibles (bande d'environ 4° au-dessus de l'horizon) | **Impossibles** : en orthographique, un objet lointain sort du cadre par le haut, le château n'apparaît jamais |
| Stabilité des sprites | Aren garde la même taille à l'écran (caméra à distance constante : 22,4 m) ; les autres personnages varient légèrement avec la profondeur | Taille rigoureusement constante |
| Lisibilité des déplacements | Bonne ; nord-sud un peu « compressé » (voir les limites) | Nord-sud très compressé à 11° |

La planche `docs/media/p7_3/comparaison_avant_apres.jpg` montre les quatre cas aux mêmes positions.

### Pourquoi 11° de plongée et 30° de champ

* Avec une caméra perspective, l'horizon apparaît dans le cadre seulement si la plongée est inférieure à la moitié du champ
  (15° ici). À 18°, puis à 14° (essais), le haut du cadre restait sous l'horizon : tout ce qui dépasse la hauteur de la
  caméra (≈ 4,3 m au-dessus d'Aren) était coupé, donc ni ville haute ni château.
* À 11°, l'horizon est vers 15 % du haut de l'image : « légère visibilité vers l'horizon urbain », comme demandé, sans
  sacrifier la lecture du sol.
* Le champ de 30° est celui du Colisée et de la forêt (P24 / P30) ; la distance est calculée comme ailleurs (Aren au même
  point de l'écran, à la même taille qu'à ×3 orthographique).
* Visée : Aren un peu sous le centre (10 % de l'écran), pour voir plus loin vers le nord, c'est-à-dire vers la montée.
* Montées : l'altitude suivie par la caméra est lissée (0,45 s) ; la position au sol ne l'est pas davantage qu'avant.

Les réglages sont dans `colisee.gd` (`PLONGEE_V06`, `CHAMP_V06`, `AIM_V06`, `ZOOM_V06`) ; on peut les essayer sans modifier le
code : `-- --v06_plongee=12 --v06_champ=28 --v06_visee=0.1`.

### Règles de composition qui en découlent

La caméra est basse (environ 22 m derrière Aren et 4,3 m au-dessus de lui) et regarde toujours le nord :

1. **Une rue nord-sud ne masque jamais Aren** : rien ne se trouve entre lui et la caméra. Le praticable est donc une avenue
   nord-sud.
2. **Les bâtiments importants ont leur façade au sud, face à la caméra**, sur le front nord d'un espace ouvert : guilde,
   auberge-taverne, forge-armurerie, hôtel de ville, archives. Dans un premier essai, leurs façades donnaient sur l'avenue
   (est ou ouest) : vues de biais, elles étaient illisibles.
3. **Entre la caméra et un lieu où l'on s'arrête, tout reste bas** : muret de 1,2 m au sud de la placette de la guilde et de
   la terrasse de l'auberge, appentis de 2,6 m, échoppes de 3,5 m au sud-ouest de la place (sinon elles cachaient le
   Colisée), commerces de 4 m au nord de la place (la caméra du parvis civique passe au-dessus).
4. **Les volumes à moins de 12 m de la caméra s'estompent en trame**, comme l'occultation validée de la forêt. Un toit juste
   devant l'objectif ne couvre donc jamais l'écran.

## 2. Plan de la démonstration

Repère : x vers l'est, y vers le sud (m). Données : `tools/p7/build_ville_v06.py` → `data/p7/ville_v06.json`.

| Niveau | Praticable | Bâtiments face caméra | Paysage |
|---|---|---|---|
| Bas (0 m) | Porte sud (8 m), avenue des Voyageurs (12 × 40 m), placette de la guilde, terrasse de l'auberge | Guilde (façade sud), auberge-taverne (façade sud) | Fronts serrés, remparts dessinés coupés à 1,6 m (comme en V0.1) |
| Médian (3,5 m) | Grande place 40 × 34 m, fontaine, rue du Colisée | Forge-armurerie et échoppe au nord, encadrant la montée civique | Colisée à l'ouest (tambour de 17 m), commerces bas à l'est et à l'ouest, toits en gradins |
| Haut (8 m) | Parvis civique 36 × 22 m, avenue du château | Hôtel de ville et archives (façades sud), porte du château (grille fermée) | Château et ville haute à environ 250 m, dans la brume ; clochers lointains |

Rien n'est praticable en dehors de ces surfaces. Tout bord de praticable est une façade, un muret, un garde-corps (1 m)
ou une porte fermée.

## 3. Résultats des tests

### Collisions : 16 sondes sur 16 réussies (`--route=p7_v06_sondes`)

Ont été vérifiés :
* les fronts est et ouest de l'avenue ;
* la façade de la guilde et le muret au sud de sa placette ;
* le muret et le front ouest de la terrasse de l'auberge ;
* les garde-corps de la place (vide de 3,5 m) et du parvis (vide de 4,5 m) ;
* les fronts est et ouest de la place, la façade de la forge et la fontaine ;
* les portes du Colisée (fermées) et la façade de l'hôtel de ville ;
* la porte du château (fermée) et la barrière de la route sud.

**Défaut trouvé et corrigé** : les portes fermées étaient toujours construites à l'altitude 0. Sur le niveau médian, celle
du Colisée ne bloquait donc pas. Les portes prennent désormais l'altitude de leur seuil (champ « h » des données, 0 par
défaut : Colisée et quartier inchangés).

### Déplacements : marche réelle à 2,2 m/s, sans course ni téléport (`--route=p7_v06_trajets`)

| Trajet | Durée |
|---|---|
| Porte sud → guilde | 10,1 s |
| Guilde → pied de la montée → fontaine | 24,8 s |
| Fontaine → montée civique → hôtel de ville | 35,0 s |
| **Porte sud → hôtel de ville (parcours complet)** | **69,8 s** |
| Fontaine → portes du Colisée | 14,6 s |
| Hôtel de ville → porte du château | 17,0 s |

Aucun blocage, aucun saut de hauteur (`h_jumps` 0). Pour comparaison en V0.1 : 19,7 s de la guilde à la porte sud et 44,6 s
de la porte sud à la place.

### Caméra : 0 bond sur le parcours vidéo complet

Outil `tools/p6/camera_continuite_p6.gd -- --scene=res://scenes/p7/ville_v06_montee.tscn --route=p7_v06_video --duree=200` :
* 12 000 images, **0 bond** ;
* distance caméra–Aren constante (22,39 m : une seule distance) ;
* déplacement d'Aren à l'écran au plus 2,3 px par image, y compris dans les deux escaliers, à la montée comme à la descente.

### Occultations et performances

Voir le tableau de mesures en fin de document (parcours vidéo).

### Non-régression

Toutes réussies, après le nettoyage puis après la V0.6 :
* tests unitaires : 76 sur 76 (les 9 tests de l'avant-poste ont été retirés avec lui) ;
* ouverture P6 de bout en bout et saut du tutoriel ;
* `p6_sondes` : 10 sur 10 ;
* F5 (forêt) et V11 ;
* chargement du blockout V0.1 ;
* raccord Colisée → V0.6 (`--route=p7_v06_raccord`).

### Non réalisable dans cet environnement

* **Rendu sur GPU réel** : tout est rendu en logiciel (lavapipe). Les chiffres de performance ne valent pas pour une carte
  graphique ; le flou de distance et la brume sont à juger sur votre machine.
* **Ressenti au clavier** (confort de la caméra, lecture des déplacements) : les parcours sont joués par un pilote
  automatique.

## 4. Limites connues et points à arbitrer

1. **Accès au Colisée vu de profil** : avec une caméra fixe vers le nord, un accès à l'ouest se lit mal. Le tambour du
   Colisée n'apparaît qu'en partie, en haut à gauche, depuis la place. *Arbitrage* : garder l'accès à l'ouest, ou placer
   l'entrée publique au nord-ouest de la place, face caméra ?
2. **Déplacements nord-sud « lents » à l'écran** : à 11°, un pas vers le nord fait peu bouger Aren à l'écran (la caméra le
   suit). Le compromis est entre l'horizon visible et la lecture du sol : 12 à 13° restent possibles.
3. **Les fronts latéraux proches de la caméra sont tramés** près des bords de l'image (règle n° 4).
4. **Hauteurs des niveaux** (3,5 m puis 4,5 m) : elles sont proposées, pas imposées, et se règlent dans le générateur.
5. **Château** : dimensionné pour la bande d'horizon visible. Une silhouette plus haute serait coupée par le haut du cadre
   (limite géométrique de la plongée basse).
6. Volumes, couleurs et toits sont **provisoires** (blockout). Aucun habillage définitif.

## 5. Fichiers

| Fichier | Rôle |
|---|---|
| `tools/p7/build_ville_v06.py` → `data/p7/ville_v06.json` | Générateur et données de la V0.6 |
| `scenes/p7/ville_v06.gd` | Affichage : niveaux, toits, paysage, château, escaliers, ambiance (ciel, brume) |
| `scenes/p7/ville_v06_montee.tscn` | Scène F6 |
| `scenes/p6/colisee.gd` | Mode ville V0.6 (choix des données, caméra de zone, zoom fixe, touches C / L), portes à l'altitude du seuil, caméra orthographique de comparaison |
| `scenes/p4/avant_poste.gd` | Entrées de caméra « V06 » et « V06O » (table CAMS) |
| `src/explore25/session25.gd` | Lissage facultatif de l'altitude suivie par la caméra (désactivé par défaut) |
| `src/p7/blockout_p7.gdshader` | Estompage facultatif près de la caméra (`proche`, 0 par défaut : V0.1 inchangée) |
| `src/explore25/routes25.gd` | Parcours : vues, vidéo, trajets, sondes, raccord, équivalents V0.1 |
| `tools/p6/camera_continuite_p6.gd` | Option `--scene=` |

### Médias (`docs/media/p7_3/`)

* `ville_v06_montee.mp4` : vidéo continue, de la porte sud à la porte du château, puis redescente.
* `vues_profondeur.jpg` : les 15 vues du parcours.
* `comparaison_avant_apres.jpg` : quatre colonnes aux mêmes positions :
  * V0.1 avec la caméra d'origine ;
  * V0.6 avec la caméra V0.5 ;
  * V0.6 en orthographique ;
  * V0.6 en perspective.
* `vue_*.jpg` : vues de profondeur choisies, en pleine taille.
