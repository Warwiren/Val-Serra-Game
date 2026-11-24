# P7.4.1 — V0.7-A.1 : corrections de caméra et intégration du Colisée

Branche **`p7-4-ville-v07a`**, à la suite de la V0.7-A. **PROPOSITION EN ATTENTE DE VOTRE EXAMEN**, non validée.

Le quartier n'est pas reconstruit. Le Colisée garde son architecture, ses dialogues et son combat. Aucun nettoyage
supplémentaire n'a été fait.

| Commit | Contenu |
|---|---|
| `6573027` | 1. Caméra de la ville et lisibilité (suivi, passages vers 20 s et vers 1 min 47) |
| `ffd973e` | 3. Caméra V0.7-A adoptée dans le Colisée |
| `a67c002` | 4. Tunnel sud à 9,0 m |
| `cf9c348` | 5 à 7. Porte publique : liaison ville ↔ Colisée, portails, orientations |


## 1. Suivi de caméra : défaut bloquant corrigé

**Cause.** Dans la ville, la caméra gardait les limites écran calculées à partir de l'emprise des données (x de 0 à 140 m).
Le parvis du Colisée descend jusqu'à x = −10 : à l'ouest de x ≈ 10, le centre de l'image restait bloqué et Aren
continuait seul vers le bord.
* En caméra A, le défaut se produisait à chaque fois.
* En caméra B, il était masqué par hasard : la première rotation effaçait les limites.

Les secteurs de rotation, les interpolations et les profils n'étaient pas en cause.

**Preuve.** Même parcours de stress `p7_v07_camera` (demi-tours brusques, bords du parvis, abords du Colisée, allers-retours
aux limites de zones, angles de la place et de la terrasse) :

| | Avant la correction (`fad8ad9`) | Après |
|---|---|---|
| Position d'Aren à l'écran (x, sur 1 280 px) | −413 à 719 px | 560 à 720 px |
| Images hors écran | 2 274 | **0** |
| Images hors zone confortable (15–85 % en largeur, 20–85 % en hauteur) | 2 855 | **0** (A et B) |

**Correction.** Plus aucune limite écran dans la ville : le décor couvre toute la vue, et rien ne doit primer sur le suivi
d'Aren. La même règle vaut pour la caméra V dans le Colisée (voir le § 3).

L'outil `tools/p6/camera_continuite_p6.gd` mesure désormais :
* la position d'Aren à l'écran ;
* les images hors zone confortable et hors écran ;
* les pivots de plongée.

## 2. Lisibilité urbaine

**Vers 20 s** (première volée) : à l'est de la volée, le socle de pierre avait son dessus exactement au niveau du palier.
Il se lisait comme un chemin, mais il était bloqué. C'est désormais un **belvédère praticable** prolongeant le palier,
avec un garde-corps au-dessus de la placette.

**Vers 1 min 47** (de la place vers la rue du Colisée) : un grand bloc bas (16 × 14 m), au sud de la rue, couvrait le
chemin et Aren. Il est supprimé : **la place se prolonge jusqu'à l'embranchement**, bordée d'un garde-corps, et un volume
bas ferme le dessous. La correction est locale : aucune transparence ajoutée aux autres bâtiments.

Les interactions proches (fontaine, forge, Guilde) restent lisibles. Les invites « E » s'affichent comme avant.

## 3. Caméra V0.7-A dans le Colisée

Profil **« V »**, par défaut dans le Colisée, identique à celui de la ville :
* perspective, plongée 11°, champ 30° ;
* une seule distance (×3) ;
* altitude lissée ;
* **aucun zoom manuel** : la molette et les zooms des parcours sont sans effet (`Cam25.verrou`).

Les caméras P6 (A, B, C) restent accessibles en comparaison avec la touche C. Elles seules gardent la molette.

Vérification salle par salle, en captures V contre P24 :

| Espace | Résultat à 11° | Réglage |
|---|---|---|
| Vestiaires, passage, salle d'attente | Plus frontal, murs et portes lisibles | 11° |
| Tunnel sud | Bouche et découverte de l'arène conservées | 11° |
| **Arène et gradins** | À 11°, les gradins sud et la toiture de la galerie **cachaient Aren** près du podium | **20°** |
| Tunnel est, coursive, infirmerie, réserve, couloir de sortie | Lisibles | 11° |

Fonctionnement :
* **Profil par secteur.** La plongée passe de 11° à 20° en entrant dans l'arène (secteur S4), et inversement. C'est un
  pivot amorti autour d'Aren, recalé à chaque image : Aren ne bouge pas à l'écran. Après un téléport, le profil se recale
  sans pivot. Projection, champ et distance ne changent pas.
* **Pas de limites écran en V.** À 11°, celles du bâtiment arrêtaient le suivi au nord de l'arène.
* **Non-régression des vestiaires.** Les limites et le voile de visibilité ne sont pas modifiés :
  `tools/p6/visibilite_vestiaires_p644.gd` ne voit aucun maillage de l'arène depuis les vestiaires.

Mesures sur le parcours `p6_741_visite` (≈ 2 min) : vestiaires, salle, tunnel, allers-retours tunnel / arène, zigzags
dans l'arène, tunnel est, coursive, infirmerie, sortie.
* **0 bond**, distance constante ;
* **0 image hors zone confortable** ;
* 4 pivots de plongée sans inversion ;
* aucun blocage.

La caméra du combat n'est pas touchée.

## 4. Tunnel sud : 9,0 m de long

La dimension paramétrée dans `tools/p6/build_colisee.py` est la **longueur** du tunnel sud (variantes A 6,5 m, B 8,5 m,
C 9,5 m). La largeur, 3 m, est inchangée.

`colisee.json` est désormais écrit à **9,0 m** (`TUNNEL_RETENU_M`) :
* le bloc sud (salle d'attente, passage, vestiaires, leur mobilier et leurs lumières) est décalé de 2,5 m d'un seul
  tenant ;
* les collisions, les raccords, la vue du tunnel et les parcours « p6 » suivent par `decalage_sud` ;
* le test unitaire vérifie la longueur et la largeur.

Les autres tunnels ne changent pas. Les fichiers de variantes A, B et C restent (leur retrait est la suppression S6, non
autorisée).

## 5 à 7. Porte publique : ville ↔ Colisée

**Axes réels.**
* **Colisée** : la sortie publique est la porte **est** du couloir de sortie (x = 63,6 à 65 m). C'est l'accès « à droite »
  à l'écran, et il est réellement à l'est.
* **Ville** : le Colisée est à l'ouest de la grande place ; sa façade tournée vers la place est donc l'**est**.

La porte publique de la ville quitte la façade sud (V0.7-A) pour la **façade est du tambour**. Elle ouvre sur un
**perron**, relié au parvis par une allée. Les deux portes regardent ainsi le même axe réel. On sort du Colisée vers l'est,
on réapparaît devant la façade est, tourné vers l'est. Ni le Colisée ni son passage ne sont reconstruits.

**Portail `colisee_porte_publique`** : le système de sorties existant est réutilisé (déclencheur de données, fondu,
désarmement à l'arrivée), sans positions codées dans le script.

| Sens | Déclencheur | Arrivée | Orientation |
|---|---|---|---|
| Ville → Colisée | `portail_colisee_public` (fond du vestibule est) | couloir de sortie (61,5 ; 23), au sol | vers l'ouest (vers l'intérieur) |
| Colisée → Ville | `sortie_est` (porte est) | perron (29,5 ; 62), à 3,5 m | vers l'est |

* L'arrivée dans chaque instance se fait hors du déclencheur inverse, qui reste réarmé : aucun déclenchement immédiat.
* L'orientation est un champ « orientation » des données. Le socle la transmet ; la scène tourne Aren et Ilya après le
  chargement.
* La porte de la ville n'est plus « refermée après la sortie » : le message correspondant n'apparaît plus dans la V0.7-A.
  Le quartier provisoire est inchangé.

Pour que la porte se lise avec une caméra tournée vers le nord, alors qu'elle regarde l'est, le porche est un **avant-corps
de 3 m** sur le perron, avec colonnes, entablement, deux lanternes allumées et la bannière de la Guilde.

Deux volumes de la V0.7-A gênaient à proximité :
* le bloc au sud de l'allée est supprimé ;
* les étals à l'est du perron sont abaissés (2,5 m), sinon la caméra B, décalée vers l'est, passait derrière eux.

**Test `p7_v07_portail`**, deux allers-retours complets, en A comme en B : sorties dans l'ordre
`portail_colisee_public`, `sortie_est`, `portail_colisee_public`, `sortie_est`. Arrivées exactes :
* Colisée : (61,5 ; 23 ; 0), vers l'ouest ;
* ville : (29,5 ; 62 ; 3,5), vers l'est ;
* déclencheur inverse armé, aucun déclenchement en double.

Les états de jeu sont conservés : progression, objectif, porte de sortie du Colisée ouverte après le tutoriel.

## Résultats des tests (état final, commit `cf9c348`)

| Test | Résultat |
|---|---|
| Tests unitaires (`run_tests.gd`), dont le tunnel de 9 m | 76 sur 76 |
| Ouverture P6 de bout en bout, saut du tutoriel | réussis |
| Sondes du Colisée `p6_sondes` | 10 sur 10 |
| Forêt F5 (chargement), V11 | sans erreur, 0 échec |
| Vestiaires P6.4.4 : maillages de l'arène visibles depuis les vestiaires | aucun |
| Sondes de la ville `p7_v07_sondes`, A et B | 22 sur 22 dans les deux modes |
| Portail ville ↔ Colisée `p7_v07_portail`, A et B | 4 passages alternés, 4 arrivées exactes |
| Raccord Colisée → ville `p7_v07_raccord` | 4 étapes sur 4 |
| Caméra de la ville, parcours de stress, A | 0 bond, 0 image hors zone confortable, aucun blocage |
| Caméra de la ville, parcours de stress, B | 0 bond, 0 image hors zone confortable, aucun blocage |
| Caméra du Colisée (V), `p6_741_visite` | 0 bond, 0 image hors zone confortable, 4 pivots sans inversion, aucun blocage |
| Trajets de la ville, A et B | 24 étapes sur 24 |
| V0.6 (chargement) | sans erreur |

## Non vérifiable ici

* **Rendu sur GPU réel** : tout est en rendu logiciel (lavapipe). Les lanternes, la brume et le flou sont à juger sur votre
  machine.
* **Ressenti au clavier** : les pivots de plongée de l'arène et les rotations B sont joués par un pilote automatique.

## Points à arbitrer

1. **Plongée de l'arène** : 20° est proposé. Les essais à 16° et 20° sont comparés aux mêmes positions. 11° garde la
   cohérence stricte avec la ville, mais cache Aren près des gradins sud.
2. La **porte publique regarde l'est**. Avec la caméra fixe A, on la voit de biais (l'avant-corps compense en partie). Avec
   B, le secteur du Colisée, étendu au perron, la tourne de 16° vers la caméra.
3. Les **parcours de démonstration P6** imposaient des zooms (×2 / ×3), désormais ignorés en caméra V. Le parcours
   `p6_video_643_apres` ne démarre pas seul (déjà le cas avant, quelle que soit la caméra), car il suppose la scène de fin
   du tutoriel.
