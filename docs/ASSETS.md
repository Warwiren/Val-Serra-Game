# Registre des assets du prototype

Miroir technique du document 06 (Registre des ressources et licences). Chaque fichier graphique ou
sonore ajouté au dépôt a une ligne ici.

**Statut commun (Lot B)** : tous les visuels sont des **placeholders originaux** dessinés en vectoriel (SVG)
par Claude, à la main ou par script, spécifiquement pour Val'Serra. Aucun outil d'IA d'image, aucune
banque d'images, aucun asset tiers. Propriété du projet ; à remplacer par la DA finale.
Aucun son n'est encore intégré.

| Fichier(s) | Description | Source / outil | Licence | Statut |
|---|---|---|---|---|
| `art/characters/hero_m.svg`, `hero_f.svg` | Héros, bases masculine et féminine (corps sans arme) | SVG écrit à la main | Projet | Placeholder |
| `art/characters/comp_a.svg`, `comp_b.svg` | Compagnons A (rapide) et B (lourd), identités provisoires | SVG écrit à la main | Projet | Placeholder |
| `art/characters/npc.svg` | Intendante de l'avant-poste (PNJ provisoire) | SVG écrit à la main | Projet | Placeholder |
| `art/characters/weapon_*.svg` | Long sabre, dague, marteau (calques séparés, point de prise documenté) | SVG écrit à la main | Projet | Placeholder |
| `art/portraits/*.svg` | Portraits bustes (héros H/F, compagnons, PNJ) + icône du monstre | Généré par script (gabarit commun) | Projet | Placeholder |
| `art/monster/body.svg` | Vorgane des brumes, corps (monstre original provisoire) | SVG écrit à la main | Projet | Placeholder |
| `art/monster/claw*.svg`, `plate*.svg`, `gland*.svg` | 3 parties ciblables, états intact / brisé, même repère que le corps | SVG écrit à la main | Projet | Placeholder |
| `art/stage/*.svg` | Décor en 5 plans : ciel, lointain, forêt et tour, sol, premier plan | `tools/art/gen_stage.py` | Projet | Placeholder |
| `art/zone/*.svg` | Maison, caisses, lanterne, établi, palissade | `tools/art/gen_zone.py` | Projet | Placeholder |
| `art/hd/hero/*.svg` | Chasseur HD articulé, 13 calques sur canevas commun | `tools/art/gen_hero_hd.py` | Projet | Placeholder (structure finale) |
| `art/hd/vorgane/*.svg` | Vorgane HD articulé, 15 calques (dont 7 éclats de carapace, plaie, états brisés) | `tools/art/gen_vorgane_hd.py` | Projet | Placeholder (structure finale) |
| `art/hd/arena/*.svg` | Arène forestière nocturne en 8 plans + rayons de lune | `tools/art/gen_arena_hd.py` | Projet | Placeholder |
| `art/sprites/aren/*.png` | **Aren HD-2D** : 5 poses + respiration (repos, garde), effets d'arc et de glyphe | Dérivés par `tools/art/aren_sprites.py` / `aren_anims.py` de la planche « Aren – Référence de sprites » (Drive, fournie par le créateur) ; effets dessinés par script | **À consigner** : outil et conditions de la planche source | Production (test) |
| `art/3d/source/Meshy_AI_Crystalback_Drake_…glb` | **Modèle original du Vorgane**, conservé intact (SHA-256 a3a42d9b…) | Meshy 6 Lite (fourni par le créateur) | **À vérifier** selon l'offre Meshy utilisée (attribution possible en offre gratuite) | Source |
| `art/3d/blender/*.blend`, `art/3d/vorgane_rig.glb` | Vorgane riggé et animé ; parties destructibles séparées | Blender 5.2.3 (scripts `tools/blender/`) à partir du GLB Meshy | Dérivé du modèle Meshy (même conditions) | Production (test) |
| `art/sprites/vorgane/**` | **Vorgane HD-2D** : 4 animations × 6 calques (corps, carapace et griffe intactes/brisées, glande) + ancrages | Rendus Blender convertis par `tools/art/pixelize_layers.py` | Dérivé du modèle Meshy | Production (test) |
| `art/proto/source/pack_visuel.png` | **Pack visuel — Brief de recentrage** (planche de DA), conservé intact | Fourni par le créateur | **À consigner** : outil et conditions de création | Source |
| `art/proto/{aren,ilya,throne,pnj}*.png`, `portrait_*.png` | **Prototype recentré** : sprites (même grille, même palette) et portraits | Dérivés du pack par `tools/art/pack_extract.py` | Mêmes conditions que le pack | Production (test) |
| `art/proto/zone_bg.png` | Décor de l'avant-poste (zone et combat), personnages peints retirés | Dérivé du pack par `tools/art/pack_zone.py` | Mêmes conditions que le pack | Production (test) |
| `art/proto/vorgane/**` | Vorgane à l'échelle du prototype (×3) | Rendus Blender convertis par `tools/art/pixelize_layers.py` (facteur 3) | Dérivé du modèle Meshy | Production (test) |
| Lumières, particules, brume | Textures de dégradé générées dans le moteur (`src/presentation/fx.gd`) | Code | Projet | — |

Rappel : la capture d'Octopath Traveler II fournie par le créateur est une **référence d'ambiance** ;
elle n'est pas incluse dans ce dépôt et aucun de ses éléments (sprites, interface, icônes) n'a été reproduit.

## Comment remplacer un asset

Les chemins et points d'ancrage sont centralisés dans `src/presentation/art.gd`. Pour remplacer, par exemple,
le corps du héros par une illustration finale : exporter un PNG/SVG au même cadrage (pieds en bas au centre,
tourné vers la droite), l'enregistrer sous le même nom, ou changer le chemin dans `art.gd`, et ajuster
`hand` (position de la main qui tient l'arme) si nécessaire.
