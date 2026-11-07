# P2 — Lot A : intégration de l'habitation et de la remise

Branche **`p2-environnements`**. F5 lance la carte V2 (`zone_exploration.tscn`) avec les deux bâtiments validés, à la
place des deux maisons recolorées. L'avant-poste n'est pas modifié.

## Méthode (`tools/explore/batiments_p2.py`)
- **Sources** : `art/source/batiments_2026-11-07/` (fond transparent, sans sol, sans accessoire, sans personnage).
  Le bord des illustrations est un contour sombre, sans halo blanc. Aucune partie n'a été reconstituée.
- **Pas de déformation locale** : chaque illustration est mise à l'échelle par un facteur unique, avec un léger
  cisaillement vertical (−0,028 pour l'habitation, −0,011 pour la remise) pour que la pente de la façade suive la rotation
  de 20°. Les verticales restent verticales et rien n'est étiré localement.
- **Échelle** : les portes mesurent 2,0 m (Aren 1,77 m), sans lien avec la résolution de la source.
- **Le gabarit est adapté à l'illustration**. Les arêtes au sol du soubassement donnent la largeur et la profondeur.
  Les égouts, le faîtage, les rives, la cheminée, la marche, la porte et les fenêtres sont relevés sur l'image. Les
  paramètres sont dans `docs/media/gabarits_batiments/adaptation.json`, puis `gabarits_batiments.py` régénère le gabarit,
  les zones, le trait, les repères et `gabarits.json`.
- **Fenêtres** : les vitres éclairées sont dans un calque séparé `<nom>_fenetres.png`. Le jeu fait varier lentement son
  opacité (de 0,8 à 1), désynchronisée d'un bâtiment à l'autre, sans effet sur les collisions ni sur le tri.
- **Lumière** : le calque de base est ramené à mi-chemin vers le ton moyen de la maison de l'avant-poste (crépuscule).
  Les vitres restent chaudes.

## Incompatibilités signalées : géométrie modifiée (emprise = collision)

| | Gabarit pilote | Adapté à l'illustration | Raison |
|---|---|---|---|
| Habitation | 7,2 × 5,0 m, murs 5,4 m, faîtage 7,8 m | **7,16 × 4,56 m** (soubassement compris : 7,32 × 4,72), soubassement 1,26 m, murs 5,63 m, faîtage 7,92 m | la profondeur dessinée est plus faible et le soubassement plus haut |
| Remise | 4,4 × 3,2 m, murs 2,7 m | **5,75 × 3,80 m**, murs 3,88 m, faîtage 5,35 m | à 4,4 m, la double porte dessinée ne mesurerait que 1,5 m de haut |

- Coins d'emprise **chanfreinés de 0,25 m**, comme l'emprise de l'avant-poste. Avec un rectangle, l'angle avant droit
  apparaît aigu à l'écran (≈ 65°) : le héros y restait coincé en appuyant sur ↑ (trouvé par le parcours à 60 i/s).
- Écart entre l'illustration et le gabarit, en px d'écran (2 px = 1 px natif) :
  - arêtes au sol : 0,7 à 5,3 (habitation), 1,3 à 8,2 (remise, coin arrière) ;
  - toiture : 4 à 11 ;
  - recouvrement des silhouettes : 0,96 (habitation) et 0,96 (remise).

  Le détail est dans `docs/media/gabarits_batiments/<nom>/controle.json`.

## Intégration dans la carte V2 (`build_exploration_v2.py`)
- Habitation : pied (861 ; 405), porte au bout du chemin pavé. Remise : pied (600 ; 324), porte au bout du sentier de
  terre.
- Chevauchements corrigés :
  - les sacs et le massif sont sortis de l'emprise de l'habitation ;
  - les fleurs de la remise ont été déplacées ;
  - les tonneaux ont été écartés de la remise (passage libre) ;
  - le sentier de la forêt longe la remise.

  Il ne reste aucun chevauchement d'emprise.
- **Retour arrière** : `python3 tools/explore/build_exploration_v2.py --anciens` régénère les deux anciennes maisons.
  Les anciens fichiers sont aussi dans Git (commit `b204965`).

## Vérifications

| | Résultat |
|---|---|
| F5 (scène principale) | carte V2 avec les deux bâtiments, aucune erreur |
| Tests automatiques | **70/70** (nouveau : angles d'emprise non aigus, illustration et calque des fenêtres au cadre du gabarit) |
| Parcours clavier, caméras A/B/C, 30/60/144 i/s : portes des deux bâtiments, derrière la remise, derrière et autour de l'habitation, couloir, limites, dialogue | **réussi**, 0 position interdite |
| Démo : dialogue, combat, victoire, retour | **réussi** |
| Retour de combat (victoire, défaite) ; avant-poste : locomotion, garde 11/11 | **réussi** |
| Performances (rendu logiciel, caméra A) | 74 à 75 i/s, comme la V2 (72 à 77 selon les mesures) ; 36 objets dessinés ; textures 34,5 Mo, contre 33,0 Mo avant (+1,5 Mo) |

## Limites
- **Toit** : à l'arrière, il tient dans le gabarit à 5 px d'écran près. Seule la rive arrière gauche s'écarte un peu
  (11 px d'écran) : le dessin n'est pas exactement orthographique.
- **Ton** : le violet des toits reste plus saturé que celui de l'avant-poste. C'est la matière validée ; je ne l'ai
  pas désaturé.
- **Personnages derrière les bâtiments** : la transparence locale les montre à travers le toit, comme pour l'avant-poste.
- **Tests sans affichage** : en mode `--headless`, l'animation des fenêtres n'est pas visible ; elle est vérifiée par
  le chargement sans erreur.

## Fichiers
- `art/explore_hd2d/batiments/{habitation,remise}{,_fenetres}.png`
- Captures : `docs/media/p2_lot_a/`
  - `avant_apres_*.jpg` (1280 × 720 par moitié) ;
  - `superposition_*.jpg` : illustration, trait du gabarit en cyan, emprise en rouge, porte en jaune ;
  - `apres_vue_ensemble.jpg` ;
  - `porte_*` et `derriere_*`.
