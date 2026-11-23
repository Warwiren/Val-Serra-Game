# P6.2-D — Intérieurs consolidés et Colisée complet

> **P7.2 (nettoyage autorisé par le créateur)** : les médias de ce rapport (`docs/media/…`) ont été retirés du projet
> actif. Ils restent dans l'historique Git : `git checkout d88eac4 -- docs/media/<dossier>`.

Branche **`p6-2d-colisee-complet`**, issue de `p6-2c-tunnel-visibilite`.

Ce qui reste conservé :
* **Moteur et caméra** : Godot 4.7.2 ; azimut 0°, plongée 24°, champ 30°, ×3 ; limites de caméra communes au bâtiment.
* **Rendu et visibilité** : ombres douces qualité 4 ; système de visibilité B.
* **Jeu** : CombatCore, tutoriel et saut du tutoriel, progression, dialogues, sprites d'Aren, caméra de la forêt.
* **F5** : inchangé (forêt).

**À tester (F6)** : `scenes/p6/colisee.tscn`, avec le tunnel sud de 8,5 m (proposition). Pour comparer les longueurs :
`colisee_tunnel_A_6_5m.tscn`, `colisee_tunnel_B_8_5m.tscn`, `colisee_tunnel_C_9_5m.tscn`.

Ce qui suit est une **conformité fonctionnelle**, pas une validation artistique. Toutes les mesures d'image ont été
faites en rendu logiciel (lavapipe), **pas sur GPU**.

## Livrables

| | |
|---|---|
| Vidéo continue, vitesse réelle | [`parcours_complet.mp4`](media/p6_2d/parcours_complet.mp4) : vestiaires → salle → tunnel sud (aller, retour, aller) → arène → tutoriel passé au dialogue → tunnel est (aller, retour, aller) → coursive → infirmerie (porte) → sortie est → quartier |
| Vestiaires avant / après (centre, 4 coins, portes) | [`vestiaires_avant_apres.jpg`](media/p6_2d/vestiaires_avant_apres.jpg) |
| Longueurs du tunnel A / B / C, mêmes positions relatives | [`tunnel_longueurs_ABC.jpg`](media/p6_2d/tunnel_longueurs_ABC.jpg) |
| Vue du dessus du Colisée complet | [`colisee_vue_dessus.jpg`](media/p6_2d/colisee_vue_dessus.jpg) |
| Arène, tunnel est, coursive, accès secondaires, sortie : avant / après | [`colisee_avant_apres.jpg`](media/p6_2d/colisee_avant_apres.jpg) |
| Décor du combat tutoriel / arène actualisée | [`decor_combat_comparaison.jpg`](media/p6_2d/decor_combat_comparaison.jpg) |
| Continuité de la caméra sur la traversée complète | [`camera_traversee.png`](media/p6_2d/camera_traversee.png) |

## Phase A — Corrections ciblées

### A1. Vestiaires : plus de bâtiment extérieur visible

On voyait, à droite, des murs d'autres parties du bâtiment (infirmerie, couloir de sortie, coursive) et, au-dessus du
mur nord, le haut des murs de 6 m de la salle.

Cause : en mode B, **tous** les murs étaient de la « structure persistante », donc jamais masqués, y compris ceux
qu'aucune ouverture ne justifie de voir.

Règle corrigée, depuis une pièce intérieure :
* les murs du reste du niveau suivent le voile de l'extérieur (invisibles depuis une pièce fermée) ;
* les murs d'une pièce non visible située **derrière** ne sont plus rendus ;
* ceux des pièces situées **devant** restent, en muret ;
* une pièce « derrière » n'est conservée que si elle est aussi **dans la largeur** de la pièce active, car son mur du
  fond ne cache rien sur le côté ;
* un élément posé exactement sur la ligne d'un mur (bannière, bandeau de porte) appartient à la pièce la plus proche.

Résultat : depuis le centre, les quatre coins et les deux portes, seule la pièce est rendue, ainsi que le passage par
la porte nord. Aren, les PNJ et les meubles restent lisibles. Aucune zone n'a été « noircie » : le fond sombre est celui
qui existait déjà autour du bâtiment.

### A2. Tunnel sud : longueur et révélation de l'arène

**Diagnostic du masque de vue** (`src/p6/vue_tunnel.gdshader`), aux six questions posées :

1. **Activation.** Il n'était actif qu'en salle, dans le tunnel et dans l'arène (selon le secteur). Il dépend
   maintenant de la **seule position d'Aren** : actif dans le tunnel, il s'efface sur les 2,4 m après la bouche et
   s'éteint un mètre après l'entrée côté salle.
2. **Durée.** Il reste actif pendant toute la traversée (vérifié aux six positions de la comparaison).
3. **Dépendance au secteur.** Il n'en dépend plus. La lumière ambiante non plus : elle suit la position (pas de
   bascule de luminosité au seuil de l'arène).
4. **Référence.** C'est la position d'Aren, pas la caméra. La caméra est 22 m en arrière et en hauteur, au-dessus d'un
   tunnel sans plafond visible : selon elle, toute l'arène serait visible. Le masque représente ce que **le
   personnage** voit par l'ouverture. C'est un choix de mise en scène, et il est assumé.
5. **Architecture.** Le tunnel a maintenant :
   * une voûte vue en coupe (naissances sur les murs) ;
   * des piédroits à l'entrée côté salle ;
   * une arche de sortie ;
   * le jour comme seule lumière au bout.

   Un vrai plafond rendu cacherait Aren : la géométrie seule ne peut pas fermer la vue depuis la caméra. Le masque
   reste donc nécessaire, mais il ne fait plus qu'appliquer les lignes de vue à travers une ouverture réelle.
6. **Apparition de toute l'arène, puis disparition.** C'était un vrai défaut, désormais corrigé :
   * au seuil salle / tunnel, l'arène passait de masquée à visible par un fondu de transparence (0,4 s) ;
   * un objet transparent n'écrit pas de profondeur, donc le masque le croyait au loin et le laissait passer ;
   * maintenant, le seuil se franchit sous un **masque fermé**, et l'arène y passe instantanément de masquée à rendue,
     sans jamais être montrée pendant le changement.

   Autre défaut corrigé : le vide autour du bâtiment (aucune géométrie) passait pour du « ciel au loin » et faisait
   des taches lumineuses de part et d'autre de la salle.

**Progression obtenue** :
* **Salle** : aucune vue sur l'arène.
* **Entrée du tunnel** : une ouverture lumineuse.
* **Milieu** : la lumière du jour, et la silhouette du commandant dans cette lumière.
* **Fin** : les premiers mètres de sable se dégagent.
* **Débouché** : l'éblouissement s'efface, et les gradins, la loge et l'enceinte se découvrent sur 2,4 m.

Au retour, c'est le même principe en sens inverse.

**Longueurs comparées**. Le bloc sud (salle, passage, vestiaires) est décalé d'un seul tenant dans les données
(`decalage_sud`) ; PNJ, décor, parcours et sondes suivent.

| | A — 6,5 m | **B — 8,5 m** | C — 9,5 m |
|---|---|---|---|
| Partie couverte | 5,5 m | 7,5 m | 8,5 m |
| Traversée à la marche | 2,5 s | **3,4 s** | 3,9 s |
| Lecture | entrée et sortie se touchent presque | un vrai passage, sans longueur | passage marqué, commence à se faire sentir |

**Proposition : B (8,5 m).** Elle donne le temps d'une montée vers la lumière, sans devenir pénible au fil des parties.
C est défendable si l'on veut plus de solennité. Le choix vous revient (scènes F6).

### A3. Arche et murs hauts

* **Arche de la bouche** : c'est désormais la fin de la voûte (bandeau et sommiers). Elle n'est plus coupée au
  franchissement. Si elle passe devant Aren, une **trouée locale** s'ouvre dans la pierre : c'est la trame de
  l'occlusion déjà validée en forêt. Aucune collision n'est ajoutée ; seul un volume d'occultation, sans collision,
  déclenche la trouée.
* **Murs de 6 m** :
  * deux assises (moyenne, puis sombre) au lieu d'un aplat noir, avec un bandeau entre les deux ;
  * corniche à 3 m ;
  * chaperon de pierre au sommet au lieu de la tranche noire « maquette » ;
  * pilastres aux extrémités des murs longs (angles et piédroits).

  Les collisions ne changent pas.

## Phase B — Colisée complet

| Espace | Traitement |
|---|---|
| **Arène** (S4, zone ouverte) | Pièce de référence des coupes : les murs du bâtiment situés devant elle perdent leur partie haute. Les gradins **sud-est** sont abaissés à l'affichage, comme ceux du sud : ils couvraient le tunnel est et Aren. Les intérieurs non visibles portent une **toiture** au lieu de laisser voir leur sol par-dessus les murs. |
| **Tunnel est** (S5) | Passage couvert sous les gradins, avec la lumière du jour côté arène. L'arène et la coursive restent en vue à ses deux bouts. Il n'a pas d'effet de révélation propre. |
| **Coursive** (S6) | Galerie intérieure : murs prolongés, plafond d'ombre, torches à ombres douces. L'arène, vue par la bouche du tunnel est, **s'efface selon la distance au seuil** (sans bascule). Les pièces fermées ne sont plus visibles. Gardes et Chasseurs restent lisibles. |
| **Infirmerie** (S7) | Intérieur, ouvert sur la coursive. La réserve voisine n'est plus visible. |
| **Réserve** (S8) | Jamais active (porte fermée). Vue en coupe depuis la coursive. |
| **Couloir de sortie** (S9) | Intérieur, avec la lumière du jour au bout, vers le quartier. Le déclenchement de la sortie et le blocage du retour sont inchangés (test de bout en bout). |

**Circulation à une touche** (`tools/p6/circulation_p6.gd`), à 0° :

| Tronçon | Arrivée | Contact mural |
|---|---|---|
| Vestiaires → salle | 3/3 | 0 % |
| Salle → tunnel sud → arène | 3/3 | 0 % |
| Arène → grille est | 3/3 | 0 % |
| Tunnel est → coursive → sortie | 3/3 | 0 % |

**Caméra** (`tools/p6/camera_continuite_p6.gd`, parcours `p6_traversee` de 46 s, avec arrêts et demi-tours aux
seuils de toutes les pièces) :
* **0 bond** ;
* zoom constant (recul de la caméra identique du début à la fin) ;
* vitesse maximale 2,6 m/s, c'est-à-dire un rattrapage lissé après un arrêt ;
* au plus 4 px de déplacement d'Aren à l'écran par image.

Le critère de bond a été précisé : une caméra plus rapide que la marche. Le rattrapage lissé après un arrêt (environ
2 m/s, qui décroît) n'est pas compté. Le trajet du tunnel garde 0 bond.

## Lumière

* **Vestiaires et salle** : lanternes chaudes, à ombres douces.
* **Tunnel sud** : sombre, avec le jour au bout.
* **Arène** : soleil.
* **Tunnel est** : le jour côté arène.
* **Coursive** : torches.
* **Couloir de sortie** : le jour au bout.

La lumière ambiante suit la distance au seuil de l'arène : l'arène ne change pas de luminosité quand Aren franchit une
limite. Les ombres douces restent en qualité 4.

## Performances

En appels de dessin, rendu logiciel lavapipe. Ce n'est pas une mesure GPU.

| Position | P6.2-C | **P6.2-D** |
|---|---|---|
| Vestiaires | 936 | 878 |
| Passage | 796 | 839 |
| Salle d'attente | 219 | 251 |
| Tunnel sud | 409 | 384 |
| Sortie du tunnel | 398 | 369 |
| Arène (entrée) | 365 | 383 |
| Arène (centre) | 282 | 304 |
| Tunnel est | 384 | 375 |
| **Coursive** | 395 | **246** |
| **Infirmerie** | 592 | **337** |
| **Couloir de sortie** | 341 | **224** |

Les primitives tombent de 21 000 à 3 000 environ dans la coursive et la sortie. La mémoire vidéo est stable
(221 Mo).

Les gains viennent de ce qui n'est plus rendu, pas de transparences. Les estompages durent 0,45 s, puis les objets
ne sont plus dessinés. Il n'y a toujours qu'**une** passe plein écran (le masque du tunnel sud), active seulement dans
le tunnel. L'occultation du moteur est conservée.

## Tests

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | **85 / 85**. Nouveaux tests : variantes du tunnel, Colisée complet (pièces latérales, toits vus de l'arène, voile de la coursive, tunnel est) |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel` | réussis (tunnel B) |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` | réussis |
| Sondes `p6_sondes` | 10 / 10 (seuils décalés avec le bloc sud) |
| Parcours complet joué (`p6_video_complet_avant` puis `_apres`) | vestiaires → … → quartier, sans blocage |
| F5 | se charge sans erreur |

Les tests unitaires de géométrie utilisent la variante A (coordonnées de référence). Un test dédié vérifie que B et C
en sont des décalages exacts.

## Restent à faire, ou à juger

* **Validation visuelle**, et sur **GPU** (ombres qualité 4, coût réel).
* **Masque du tunnel** : il s'appuie sur la profondeur. Un objet en cours d'estompage (0,45 s) est jugé d'après ce qui
  se trouve derrière lui.
* **Arche** : quand Aren passe sous elle, elle se troue autour de lui (trame validée en forêt). À juger en mouvement.
* **Pièces fermées situées devant** (réserve vue de la coursive, vestiaires vus de la salle) : elles apparaissent en
  coupe (murets, sol estompé), donc comme un vide sombre. C'est cohérent avec le mode B, mais à juger.
* **Décor du combat tutoriel** : c'est encore le rendu blockout de P6. L'arène habillée est très différente
  (comparaison jointe). Il est à régénérer avec `--decor_combat --sans_secteurs` une fois l'arène validée ; je ne l'ai
  pas fait, car le combat n'est pas dans le périmètre.
* **Toitures vues de l'arène** : ce sont des aplats provisoires.
* **Murs** : silhouettes plus solides, mais toujours en pierre P4 teintée. Aucun nouvel asset.
* **Packs Quaternius** : non récupérés. L'hôte de téléchargement de Google Drive reste refusé par le réseau de
  l'environnement, et les archives (40 et 56 Mo) sont trop lourdes pour l'outil Drive. Rien n'a été examiné ni utilisé.
  Pour les récupérer : autoriser `drive.usercontent.google.com` dans les réglages réseau de l'environnement.

## À améliorer graphiquement plus tard

* Matériaux des murs (corniches, chaperons, pilastres).
* Toitures vues de l'arène.
* Voûte du tunnel.
* Portes des pièces fermées.
* Torches de la coursive.
* Habillage de la coursive (bancs, râteliers).
* Infirmerie.
* Loge vue de près.
* Décor du combat tutoriel.
* Lumière du jour aux sorties.
