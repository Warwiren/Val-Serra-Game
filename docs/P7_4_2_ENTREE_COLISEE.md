# P7.4.2 — Entrée monumentale du Colisée et validation des caméras

Branche **`p7-4-ville-v07a`**, à la suite de P7.4.1.

**PROPOSITION EN ATTENTE DE VOTRE EXAMEN ARTISTIQUE**, non validée. Le Colisée n'est ni reconstruit ni refait en façade.
Son architecture intérieure, le quartier, l'éclairage global et le système de transitions ne changent pas, et aucun
nettoyage n'a été fait.

## 1. L'entrée : un propylée devant la porte est

La porte publique reste sur la **façade est** du tambour, tournée vers la grande place. Devant elle, un **propylée**
(avant-corps monumental) remplace le petit porche de P7.4.1.

| Intention du brief | Réalisation |
|---|---|
| Arche principale monumentale | Deux grandes arches en plein cintre de 5,9 à 6,8 m d'ouverture : archivolte en claveaux clairs, clé saillante |
| Encadrement massif, distinct des arcades | Calcaire **clair** (les arcades du tambour sont ocre et sombres). Quatre piles à socle et chapiteau, entablement, attique |
| Porche avancé ou réorienté vers le chemin | Avant-corps de 8,5 × 10 m. L'**arche est** garde l'axe réel de la porte ; l'**arche sud** s'ouvre sur l'allée d'approche, donc face à la caméra qui regarde le nord |
| Perron et allée cohérents | L'allée arrive au pied de l'arche sud. Le perron passe sous le propylée et rejoint la porte |
| Deux bannières ou emblèmes | Deux bannières de la Guilde sur la face sud. Emblèmes dorés sur l'attique, au sud et à l'est |
| Éclairage local, sans excès | Lumière chaude sous la voûte et deux lanternes à l'arche sud, d'énergie modérée. L'éclairage global ne change pas |

Les collisions sont celles des données : quatre piles et un mur nord plein. Le passage reste libre par les deux arches.

## 2. Perspective dégagée

Depuis la grande place, le propylée se voit au-dessus des étals.

Devant le portail, en revanche, deux blocs d'étals (2,5 m) au sud et à l'est du perron passaient entre la caméra et Aren,
surtout en caméra B, décalée vers l'est. Ils sont ramenés à **0,6 m** (étals et bancs bas), sans changer leur emprise.
Aucune rue n'est élargie et le parvis n'est pas agrandi : seul le perron s'étend jusqu'aux étals (2 m).

Depuis le côté ouest du parvis, l'entrée est hors champ, parce que la caméra regarde le nord. On la découvre en avançant
vers l'allée.

## 3. Transitions inchangées

Rien n'a bougé :
* le portail `colisee_porte_publique` ;
* son déclencheur (fond du vestibule est) ;
* l'arrivée dans le Colisée : couloir de sortie (61,5 ; 23), tourné vers l'ouest ;
* le retour : perron (29,5 ; 62), tourné vers l'est. Ce point est désormais sous le propylée, hors du déclencheur ;
* le fondu ;
* le désarmement du portail inverse ;
* le tunnel sud de 9 m.

## 4. Caméras

Le profil P7.4.1 est conservé : perspective, distance unique, aucun zoom manuel, aucune limite écran. Dans le Colisée, la
plongée est de **11°**, et de **20° dans l'arène**, avec un pivot amorti autour d'Aren.

**Comparaison A / B sur le même trajet** `p7_742_approche` : grande place → allée → devant l'arche sud → perron → sous le
porche → entrée dans le Colisée.

| | A (fixe, nord) | B (semi-fixe) |
|---|---|---|
| Bonds de caméra | 0 | 0 |
| Position d'Aren à l'écran | 560–719 px, toujours dans la zone confortable | 562–718 px, toujours dans la zone confortable |
| Lecture de l'entrée | Arche sud de face, arche est de profil | Arche sud de face ; la rotation (−16°, secteur du Colisée) découvre davantage le tambour et l'arche est |
| Inconvénients | — | Les étals et volumes proches de la caméra passent plus souvent en trame, et la rotation se répète à chaque entrée dans le secteur |

Avec le propylée, l'entrée se lit **dans les deux modes**, parce que l'arche sud fait face à la caméra. L'avantage de B
pour l'entrée devient secondaire. **Je recommande A pour l'entrée.** B reste utile pour découvrir le Colisée depuis la
place (P7.4) ; à vous d'arbitrer.

**Défaut trouvé et corrigé.** À l'arrivée dans le Colisée, Aren apparaissait décalé (jusqu'à 939 px), puis la caméra
glissait pendant 0,5 s. Le socle calait en effet la caméra avec les limites de l'instance, alors que la porte d'arrivée
est près d'un bord. La caméra est désormais recalée sans limites dès la mise en place du monde et après chaque téléport.
Plus aucune image n'est décentrée.

## 5. Tests et mesures (état final)

| Test | Résultat |
|---|---|
| Tests unitaires (tunnel de 9 m compris) | 76 sur 76 |
| Ouverture P6 de bout en bout, saut du tutoriel | réussis |
| Sondes du Colisée `p6_sondes` | 10 sur 10 |
| Forêt F5, V11, chargement de la V0.6 | sans erreur, 0 échec |
| Arène invisible depuis les vestiaires (`visibilite_vestiaires_p644.gd`) | aucun maillage de l'arène |
| Sondes de la ville (piles et mur du propylée compris), A et B | 24 sur 24 dans les deux modes |
| Portail `colisee_porte_publique`, deux allers-retours, A et B | 4 passages alternés, 4 arrivées exactes, aucun redéclenchement |
| Raccord Colisée → ville | 4 étapes sur 4 |
| Approche de l'entrée (`p7_742_approche`), A et B | 0 bond, 0 image hors zone confortable |
| Caméra de la ville, parcours de stress (côtés du parvis, demi-tours, limites), A et B | 0 bond, 0 image hors zone confortable |
| Colisée, `p6_741_visite` (intérieurs, tunnel, arène) | 0 bond, 0 image hors zone confortable, aucun blocage |
| Arène, `p6_742_arene` (pivots 11° ↔ 20°, gradins sud) | 0 bond, 0 image hors zone confortable, 3 pivots sans inversion |
| Trajets de la ville, A et B | 24 étapes sur 24 |

## 6. Médias (`docs/media/p7_4_2/`)

* `entree_1_depuis_la_place.jpg`, `entree_2_mi_chemin.jpg`, `entree_3_devant_le_portail.jpg` : les trois captures
  demandées, en caméra A.
* `entree_comparaison_A_B.jpg` : six positions (place, mi-chemin, devant le portail, parvis ouest, parvis est, sous le
  porche), A à gauche et B à droite.
* `approche_entree_camera_A.mp4`, `approche_entree_camera_B.mp4` : même trajet, de la grande place à l'entrée dans le
  Colisée.
* `arene_plongee_20.mp4` et `arene_plongee_20.jpg` : démonstration de l'arène (tunnel à 11°, pivot, gradins sud à 20°,
  retour).

## 7. Fichiers modifiés

* `tools/p7/build_ville_v07a.py` et `data/p7/ville_v07a.json` : propylée, perron, étals bas.
* `scenes/p7/ville_v07a.gd` : dessin du propylée, collisions des piles.
* `scenes/p6/colisee.gd` : recalage de la caméra sans limites au chargement et au téléport.
* `src/explore25/routes25.gd` : parcours `p7_742_entree`, `p7_742_approche`, `p6_742_arene`, sondes.
* `docs/media/p7_4/plan_v07a.png`, ce rapport.

## Non vérifiable ici

* **Rendu sur GPU réel** (tout est en rendu logiciel, lavapipe) : intensité des lanternes et de la lumière sous la voûte,
  halo. Je n'ai mis aucun effet de bloom.
* **Ressenti au clavier** : les parcours sont joués par un pilote automatique.
