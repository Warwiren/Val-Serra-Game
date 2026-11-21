# P6.1 — Caméra, apparence d'Aren et pilote d'habillage du Colisée

Branche **`p6-1-colisee-camera-art`**, depuis `p6-colisee-ouverture` (`dc5e10e`, conservée comme référence
fonctionnelle). Godot **4.7.2**. F5 inchangé ; le Colisée reste en F6 (`scenes/p6/colisee.tscn`).
Structure, parcours, dialogues, progression, tutoriel et collisions : **inchangés**.

Dans cette branche, le Colisée démarre avec les réglages **proposés** ci-dessous, tous réversibles en jeu :

| Touche | Bascule | Démarrage (proposition) |
|---|---|---|
| **C** | caméra A — P30 ×2,5 (P6) → B — P30 ×3 → C — P24 ×3 (forêt) | **C** |
| **B** | Aren : « forêt » (V09B.5 + V4) ↔ P4.8 (`art/p45/chars/aren/`) | **forêt** |
| **H** | habillage : pilote P6.1 ↔ blockout P6 | **pilote** |

Ligne de commande équivalente : `-- --cam_p6=A|B|C --aren=foret|p48 --habillage=pilote|blockout`.

## Étape A — Caméras

Mêmes six positions, même état du jeu, même rendu : [`cameras_comparaison_1.jpg`](media/p6_1/cameras_comparaison_1.jpg)
(vestiaires, salle d'attente, entrée de l'arène), [`cameras_comparaison_2.jpg`](media/p6_1/cameras_comparaison_2.jpg)
(centre de l'arène, coursive, sortie est) ; vidéo en déplacement A → B → C (même trajet vestiaires → coursive) :
[`cameras_deplacement.mp4`](media/p6_1/cameras_deplacement.mp4).

La caméra C reprend exactement la formule de la forêt : perspective, plongée 24°, azimut 20°, champ 30°, et une hauteur
de vue de 720 / (20 × zoom) m. Au même zoom, la taille d'Aren à l'écran est donc **identique** à celle de la forêt :
≈ 76 px de haut à ×3, contre ≈ 63 px à ×2,5 en A.

| Critère | A — P30 ×2,5 | B — P30 ×3 | C — P24 ×3 |
|---|---|---|---|
| Taille d'Aren / lisibilité des PNJ | petits | = forêt | = forêt |
| Portes, marques au sol | très lisibles | lisibles | lisibles, plus écrasées |
| Hauteur apparente des murs | faible | faible | **plus hauts**, plus « architecture » |
| Gradins | vus d'au-dessus | idem | **profil des rangs mieux lu** |
| Aren caché par le décor (mesure, `tools/p6/occlusion_p6.gd`) | 12,7 % | 13,2 % | **17,2 %** |
| Vide hors du niveau (blockout) | important | moindre | moindre ; **supprimé par le pilote** (parvis, bâtiments) |
| Suivi, limites, confort | bon | bon | bon (même logique de suivi) |

Occlusion en C, par pièce : vestiaires 6 %, arène 9 %, coursive 27 %, **salle d'attente 46 %**, tunnel sud 33 %.
La cause est identifiée : le **mur nord des vestiaires (3 m), vu de dos**, masque le sud de la salle d'attente, et il en va
de même pour les murs nord de la coursive. Le trou de visibilité autour d'Aren le montre toujours, mais il apparaît plus
souvent.

**Recommandation : C (P24 ×3)**, pour retrouver la sensation de la forêt, **avec une règle de murs coupés** : un mur
haut qu'on voit de dos, avec une pièce praticable juste derrière, serait abaissé (comme les murs sud), sans changer les
dimensions ni les collisions. Petites pièces : ×3 convient (les vestiaires de 20 × 8,5 m tiennent presque entiers à
l'écran) ; je ne propose pas de zoom intérieur différent.

## Étape A — Aren

[`aren_comparaison_sources.png`](media/p6_1/aren_comparaison_sources.png) : sources brutes, même hauteur à l'écran,
agrandissement au plus proche. [`aren_en_jeu.jpg`](media/p6_1/aren_en_jeu.jpg) : rendu dans le Colisée, même caméra,
même lumière et même position (immobile, marche, course, face), et référence de la forêt.

**Ce que P6 affichait réellement** : `art/p45/chars/aren/` (`idle_*`, `walk_*` : 8 images, 63 px), chargé par Actor25
(surcharge de l'avant-poste `CHARS["aren"]`), carte « pixel net » `src/p4/perso_p41.gdshader` avec la teinte du
crépuscule de l'avant-poste. Ces fichiers sont **identiques octet pour octet** à ceux de la branche `p4-8-marche`
(empreintes Git vérifiées) : c'est bien l'apparence P4.8 historique, au rendu « chibi » (grosse tête, armure gris-bleu).

**Ce que la forêt affiche au démarrage depuis le 19/11** : un autre dessin.

| Vue | Fichiers |
|---|---|
| profil marche | `art/tests/v09b5_aren/walk_96x112/walk_right_0..7.png` |
| profil course | `art/tests/v09b5_aren/run_96x112/run_right_0..7.png` |
| affichage | ×0,719 (≈ 64 px) |
| face / dos | marche V4 dessinée, `art/tests/aren_4dir_v4/walk_{face,back}_0..7.png` |
| arrêt | pose de marche tenue |
| module | `src/explore25/anim_v09b5.gd`, format `96x112_h64` |

Ce dessin a des proportions plus élancées, une cape et une écharpe ; il est **cohérent avec les portraits**
(`art/p45/portraits/aren/`).

Mon interprétation : le design que vous préférez est celui de la forêt, que le projet appelle « V09B.5 » et non
« P4.8 ». Je l'ai donc branché dans le Colisée **sans rien redessiner** : mêmes fichiers, même module que F5. P4.8 reste
à la touche B. À confirmer visuellement.

Animations : marche et course de profil (V09B.5) et marche de face / de dos (V4) existent.

**Manquent dans ce design :**
- une attente animée (pose de marche tenue) ;
- une course de face / de dos (la marche est jouée, foulée allongée) ;
- **les poses de combat** : le tutoriel utilise encore `art/p45/combat/aren/` (P4.5), du même style chibi que P4.8.
  Il y a donc une incohérence à combler par une planche de combat dans le nouveau design (non générée ici).

Aucune variante n'a été supprimée.

## Étape B — Audit des ressources

| | Ressources |
|---|---|
| **1. Présentes, réutilisables telles quelles** | `art/p4/batiment/pierre_taille.png` (murs, podium, gradins) ; `art/p4/mat/sol_paves.png` (couloirs, parvis) ; `art/p4/pont/planches.png` (planchers, assises) ; **`art/p53/sol_v2/terre_chemin.png`** (sable de l'arène, très crédible) ; accessoires peints de l'avant-poste `art/p4/props/` (tonneau, caisse, sacs, bûches, lanterne, bannière bleue) ; halo et lumières de l'avant-poste |
| **2. Présentes, à adapter** | `facade_colombage.png` / `toit_violet.png` (bâtiments lointains, recolorés) ; `roche.png` (soubassements) ; modèles Quaternius de la forêt : **nature seulement** (arbres, buissons, rochers), utilisables au mieux en jardinières ou en bord de parvis, pas pour l'architecture |
| **3. Réellement manquantes** | **modèles 3D d'architecture** : arcs, colonnes sculptées, escaliers de gradins, portes et grilles détaillées, torches murales, râteliers d'armes, mannequins d'entraînement, statues |

**Packs extérieurs :** ni le réseau de cet environnement ni l'outil de lecture web n'atteignent `quaternius.com`,
`kaylousberg.com` ou `kenney.nl` (hôtes non autorisés). **Je n'ai donc pu vérifier ni les licences, ni le contenu
gratuit, ni les formats**, et **rien n'a été téléchargé**.

Sur la base de leur réputation, à **revérifier au téléchargement** :

| Pack | Licence attendue | Style et usage |
|---|---|---|
| Kenney Castle Kit | CC0, gratuit | couleurs unies, très « jouet » (risque de rupture avec les textures peintes) |
| KayKit Dungeon Remastered | CC0 pour la partie gratuite (une partie payante existe) | atlas de dégradés ; murs, colonnes, portes, torches, râteliers, tonneaux, bannières |
| Quaternius MegaKits | version « Standard » annoncée CC0, sources payantes | à vérifier : les conditions ont changé récemment |

**Proposition, si un pack devient nécessaire :** **KayKit Dungeon Remastered** comme pack principal. C'est
l'architecture intérieure la plus proche du besoin : colonnes, arcs, portes, torches, râteliers. Ses matériaux seraient
remplacés par nos textures (`pierre_taille`, `planches`) pour rester cohérents. Coût estimé : 1 à 2 jours, une
vingtaine de modèles retenus. Poids : quelques Mo en GLB, en ne copiant que les fichiers utilisés.

Le pilote ci-dessous montre toutefois que **les ressources du dépôt suffisent pour une première passe**. Le pack n'est
utile que pour les objets du point 3.

## Étape C — Pilote d'habillage (ressources du dépôt uniquement)

Module `scenes/p6/habillage_p6.gd` (touche H). Avant / après, même caméra :
[`habillage_avant_apres.jpg`](media/p6_1/habillage_avant_apres.jpg), qui inclut la référence de la forêt. Vues :
`media/p6_1/pilote_*.jpg`.

**Lumière** (rapprochée de la forêt) :
- tonalité filmique, ambiance plus basse, soleil chaud, ombres qualité 4 conservées ;
- ciel procédural, léger éclat lumineux ;
- la teinte gris-violet des murs venait de l'éclairage du crépuscule de l'avant-poste et a disparu.

**Arène** :
- sable `terre_chemin`, sol tassé et ombré au pied du podium ;
- podium avec chaperon et pilastres, bannières bleues et rouges de la Guilde, braseros allumés ;
- gradins avec assises en bois et escaliers tous les 30°, colonnade et architrave au nord ;
- arc à claveaux sur l'accès est ; loge à colonnes, balustrade, dais rouge et or.
- La forme ovale et les dimensions sont inchangées.

**Vestiaires** (intérieur pilote) :
- plancher et bordure de dalles, plinthes, poutres et potelets ;
- casiers à portes, râtelier garni (lames, boucliers), tapis ;
- tonneau, caisse, sacs, bûches, lanternes et bannières de la Guilde (accessoires peints existants) ;
- éclairage intérieur chaud.

**Extérieur** : parvis pavé et bâtiments lointains au nord, à l'ouest et à l'est (aucun au sud, où ils passeraient
devant la caméra). **Le vide noir a disparu.**

Murs de tout le Colisée en pierre calcaire avec soubassement, pour la cohérence. Murs du tunnel sud **rendus** à 1,7 m
(la collision reste à 2,6 m) ; pas d'arc au sud, qui masquait l'arène.

| Vérification | Résultat |
|---|---|
| Collisions | sondes P6 **10 / 10**, ouverture de bout en bout **réussie avec le pilote actif** ; aucune collision ajoutée ni retirée |
| Occlusion | identique au blockout (le décor ajouté n'a pas de collision ; matières avec trou de visibilité) |
| Coût | appels de dessin 435 → **929**, primitives 11 700 → 30 700, mémoire vidéo 142 → 184 Mo. Négligeable sur GPU, mais les petits blocs sont à **fusionner** avant de généraliser |
| Mesure sur une vraie carte graphique | **non faite** (aucun GPU ici, rendu logiciel lavapipe) : à vérifier de votre côté, ombres qualité 4 incluses |

**Limites du pilote :**
- plancher des vestiaires encore trop chaud ;
- herbe peinte de la texture de pierre (taches vertes) un peu trop visible sur les grandes surfaces ;
- aucun modèle sculpté (statues, torches murales, mannequin réaliste) : c'est la catégorie 3 ;
- salle d'attente, coursive et sortie n'ont reçu que les murs et la lumière.

**Comparaison avec la forêt :** même lumière chaude, même sensation de caméra, matières peintes de même famille.
La forêt reste plus riche en **volumes organiques et en ombres portées** ; le Colisée gagne en lisibilité architecturale.
L'écart restant tient surtout à l'absence de modèles sculptés.

## Points techniques (§ 8)

* **« Souffle »** : les cartes de tempo affichent maintenant le nom réel de l'attaque annoncée
  (« + avant « Assaut d'entraînement » »). Le texte du Vorgane est inchangé (« le Souffle »), et « Souffle annulé » est
  généralisé.
* **Tutoriel imperdable par construction** : `src/tutorial/garde_fou.gd` borne, avant chaque décision du joueur, l'attaque
  du commandant (un « coup retenu ») pour que **3 coups de puissance maximale sans garde** restent inférieurs aux PV
  d'Aren. Aucune règle du CombatCore n'est modifiée. Test : 60 tours avec chaque comportement autorisé (attaque seule,
  technique chargée, garde seule, mélange avec potions) → Aren debout, commandant intact.

## Tests

| Commande | Résultat |
|---|---|
| `tests/run_tests.gd` | **81 / 81** (+1 : garde-fou du tutoriel) |
| `tests/e2e_p6_ouverture.gd -- --tuto-rapide` | réussi (caméra C, Aren « forêt », pilote actif) |
| parcours `p6_sondes` | 10 / 10 |
| `e2e_p4_retour`, `p4` (29 / 29), `p4_sondes` (20 / 20), `p5_combat`, `v11`, `v09b5` | réussis |
| F5 (`--quit-after 60`) | sans erreur |

Les tests automatiques ne valident pas l'aspect artistique.

## Étape D — Décisions attendues

1. **Caméra** : C (P24 ×3) avec la règle des murs coupés vus de dos ? Ou B ?
2. **Aren** : confirmer que le bon design est celui de la forêt (V09B.5 + V4) et non P4.8. Si oui : planche de combat
   à produire dans ce design.
3. **Habillage** : étendre le pilote au reste du Colisée (salle d'attente, coursive, infirmerie, sortie), avec
   fusion des maillages ? Autoriser l'accès réseau aux sites de packs pour vérifier licence et contenu de KayKit
   Dungeon Remastered ?
4. **F5** : toujours en attente.
