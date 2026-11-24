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
porche → entrée dans le Colisée. Voir le § 5 et les vidéos.

## 5. Tests et mesures

Voir le tableau en fin de document.

## Non vérifiable ici

* **Rendu sur GPU réel** (tout est en rendu logiciel, lavapipe) : intensité des lanternes et de la lumière sous la voûte,
  halo. Je n'ai mis aucun effet de bloom.
* **Ressenti au clavier** : les parcours sont joués par un pilote automatique.
