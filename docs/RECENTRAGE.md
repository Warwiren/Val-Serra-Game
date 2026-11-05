# Recentrage du prototype — compte rendu

Objectif : une base **plus simple, plus propre et cohérente visuellement**, inspirée d'Octopath Traveler II
(ambiance seulement — aucun élément du jeu n'est copié), construite à partir du **pack visuel** fourni.

**Boucle jouable** (scène principale, lancée directement par F5, sans menu) :
avant-poste → parler au garde → toucher le Vorgane → combat dans la même clairière → victoire → retour
à l'avant-poste, le monstre a disparu et le garde a une réplique de remerciement.

Vidéo (63 s, combat accéléré ×2,5) : `docs/media/recentrage/prototype_recentre.mp4`
Captures : `docs/media/recentrage/01_zone.jpg` … `07_retour.jpg`

## Commandes
| Exploration | |
|---|---|
| Flèches ou ZQSD | se déplacer (les compagnons suivent) |
| E ou Entrée près du garde | parler ; E/Espace : suite ; Échap : fermer |
| Toucher le Vorgane | lance le combat (zoom + flash, puis fondu) |

Combat : souris ou 1–4 (action), Tab (VIF/MESURÉ/CHARGÉ), Entrée (exécuter), Espace maintenu (accélérer).

## Ce qui a été retiré ou désactivé (rien n'est supprimé du dépôt)
- **Menus de lancement** : l'écran de choix du héros n'est plus la scène principale (toujours accessible
  dans `scenes/explore/hero_select.tscn`).
- **Variantes visuelles concurrentes** dans la boucle jouable : rendu A/B (F2 désactivé en mode prototype),
  personnages vectoriels « cartoon », prototype HD articulé, visionneuse de rig. Ils restent lançables en
  ligne de commande (`--start=battle`, `--start=hd2d`, `--start=artproto`, `--start=rigviewer`).
- **Interface de démonstration** dans le combat : journal, aide clavier, bouton de rendu, jauge de Résonance,
  étiquettes permanentes sur les trois parties (seule la partie visée est nommée).
- **Capacité de sérum** masquée dans le menu (elle existe toujours dans le CombatCore).

## Ce qui a été modifié
- **Personnages** : Aren, Ilya, Throné et le garde viennent tous de la rangée « Style & Échelle » du pack,
  passés sur **la même grille de pixels** (1,73 px du pack = 1 px natif), **la même palette** (64 couleurs),
  affichés **×3 au plus proche voisin** et positionnés sur la grille (jamais de demi-pixel). Hauteur du
  héros : 37 px natifs → **111 px** à l'écran (fourchette du pack : 96–112). Respiration sur 2 images,
  sautillé de marche, ombre au sol en pixels pleins. Script : `tools/art/pack_extract.py`.
- **Décor** : panneau « Exploration » du pack ramené sur la même grille (427×240 natifs ×3 = 1280×720) ;
  les personnages peints, la bulle et la mini-carte ont été retirés par recopie de motifs réels de l'image
  (pas de flou). Script : `tools/art/pack_zone.py`. Lumières chaudes animées aux lanternes, lucioles.
- **Monstre** : le Vorgane Blender (production précédente) re-pixelisé au facteur ×3 (≈165 px de haut,
  fourchette du pack 160–220), contraste relevé pour la nuit, tourné vers la droite.
- **Combat** : même clairière que la zone, groupe à droite tourné vers la gauche, monstre à gauche ;
  portraits du pack dans la chronologie et les fiches ; écran de fin « Retour à l'avant-poste ».
- **Nouveaux fichiers** : `scenes/proto/proto_zone.tscn/.gd`, `src/proto/pack_hunter_view.gd`,
  `data/dialogue/pnj_proto.json`, `art/proto/**` (+ source du pack dans `art/proto/source/`).

## Ce qui a été conservé
- **CombatCore intact** (règles, chronologie, parties brisables, récompenses) — 37 tests passent
  (36 anciens + 1 nouveau sur l'échelle commune des sprites).
- Déplacement, suiveurs, combat au contact, système de dialogue, transitions, `GameState`.
- Les anciennes scènes et assets (copie conservée, rien n'a été écrasé).

## Problèmes restants (honnêtement)
1. **Une seule pose par personnage** : le mouvement en combat est porté par la respiration, le sautillé,
   les élans et les effets — pas encore de vraies images d'attaque/coup reçu dans ce style.
2. **Le Vorgane est un rendu 3D pixelisé** ; il est à la bonne échelle et dans la même grille, mais son
   modelé reste un peu plus « lisse » que les personnages peints du pack. C'est l'écart de cohérence le plus visible.
3. **Décor** : une petite répétition de fenêtre/porte près de la maison, là où le garde peint a été effacé.
4. Pendant une attaque, l'élan d'un personnage peut passer devant un autre membre du groupe.
5. L'interface de combat (chronologie, cartes de mode) reste celle du Lot B, épurée mais pas redessinée
   dans le style du pack.

## Prochaine étape logique
Produire, **dans le style du pack**, 3 à 4 images par personnage (attaque, coup reçu, garde, K.O.) et une
version dessinée du Vorgane à partir de ses rendus Blender (pose de repos + attaque), puis redessiner la
chronologie et le menu de combat dans la même direction artistique.

## Provenance des ressources
Le pack visuel (« Brief de recentrage ») a été **fourni par le créateur** ; ses conditions de création
(outil, licence) sont **à consigner** dans le registre (document 06). Voir `docs/ASSETS.md`.
