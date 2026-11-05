# Vorgane des brumes — audit du GLB Meshy, préparation Blender, choix de rendu

*Outils : Blender 5.2.3 LTS (module officiel `bpy` de la Blender Foundation, piloté par scripts Python),
Godot 4.5.1. Le GLB original est conservé intact : `art/3d/source/` (SHA-256 `a3a42d9b…0945`).*

## 1. Audit du modèle (mesures réelles)

| Point | Résultat | Commentaire |
|---|---|---|
| Fichier | `Meshy_AI_Crystalback_Drake_1104223020_texture.glb`, 3,5 Mo | Meshy 6 Lite |
| Objets | 1 maillage, aucun squelette, aucune animation | À rigger entièrement |
| Dimensions | 1,08 (largeur) × 1,89 (longueur) × 0,85 m (hauteur) | Échelle réaliste, pas de correction |
| Orientation | Le monstre regarde vers **−Y** (Blender), Z vers le haut | Conforme, pas de rotation nécessaire |
| Polygones | 21 512 triangles (tout triangulé), 20 030 sommets à l'import | Budget correct pour un jeu |
| Topologie réelle | Après fusion des sommets dédoublés aux coutures UV : **10 769 sommets, 1 maillage fermé**, 34 arêtes de bord, 5 non-manifold | Sain. Les « 1 224 îlots » vus à l'import brut sont un artefact des coutures UV |
| Fragment isolé | 1 îlot de 13 sommets près de la nuque | Sans conséquence, conservé |
| Normales | 0 incohérence détectée ; recalcul vers l'extérieur appliqué à la copie de travail | — |
| UV / textures | 1 jeu d'UV, 1 matériau PBR, 1 texture 2048×2048 RGBA | Exploitable tel quel |
| Pattes | 4 appuis nets : avant à y ≈ −0,52 (x ±0,40), arrière à y ≈ +0,24 (x ±0,33) | Bonne base de rig |
| Mâchoire | **Non séparée** : gueule sculptée fermée, crocs modelés | Ouverture limitée (≈ 15°) sans étirement visible |
| Queue | Fine, relevée en fin (y 0,47 → 0,94) | Rigguée en 4 segments |
| Carapace | Cristaux soudés au dos (pas d'objets séparés), très nombreux | Isolés par la texture (voir §3) |
| Glandes | Deux glandes d'Aether, une par épaule | La glande visible (flanc +X) est la partie ciblable |

Rendus sous 4 angles : `docs/vorgane_3d/vue_face.png`, `vue_profil.png`, `vue_arriere.png`, `vue_trois_quarts.png`.

**Défauts réellement observés** : mâchoire non séparée ; quelques arêtes ouvertes (34) et non-manifold (5),
sans impact visible ; fragment flottant de 13 sommets ; cristaux soudés au corps (pas de découpe propre
possible sans retouche). **Aucun remaillage n'a été fait** : le modèle est exploitable tel quel.

## 2. Squelette et animations

- 23 os : racine, bassin, colonne, poitrail, cou, tête, mâchoire, 4 segments de queue, 3 segments par patte.
- **Échec constaté** : la pondération automatique de Blender (« Bone Heat ») ne trouve aucune solution sur ce
  maillage (auto-intersections des cristaux). Remplacée par une **pondération géométrique contrôlée**
  (distance aux os, mélange doux, restrictions anatomiques gauche/droite, queue, tête, mâchoire) :
  **10 769 / 10 769 sommets pondérés**, répartition symétrique.
- Animations : **repos** (respiration, queue, mâchoire), **coup de griffe** (armé, frappe vers l'avant, bond),
  **impact** (recul), **marche** (cycle à 4 pattes). Contrôlées par rendu (`coup_de_griffe_controle.png`) :
  une première version levait la patte cachée par le corps, puis plantait les griffes sur le crâne ;
  corrigées et revérifiées.
- Fichiers : `art/3d/vorgane_rig.blend` (modifiable), `art/3d/vorgane_parts.blend` (avec parties séparées),
  `art/3d/vorgane_rig.glb` (animé, pour la solution A).

## 3. Parties destructibles (intact / endommagé / brisé)

Solution retenue, **non destructive pour l'animation** : les faces de chaque partie sont isolées d'après la
texture puis copiées en **objets séparés qui gardent le même squelette et les mêmes poids** (ils se déforment
exactement comme le corps). Le corps de base est rebouché par une « plaie » sombre sous chaque partie.

| Partie | Faces | Intact | Endommagé (< 50 % d'intégrité) | Brisé |
|---|---|---|---|---|
| Carapace (cristaux du dos) | 9 850 | Calque cristaux | Assombri + fissures rougeoyantes (shader Godot) | Cristaux **arasés en moignons** (géométrie dédiée) |
| Griffe (patte avant visible) | 425 | Calque griffes | Idem | **Serres raccourcies** (géométrie dédiée) |
| Glande d'Aether (épaule visible) | 259 | Calque glande + lueur | Idem | **Glande éteinte** (traitement de couleur) |

Godot permute les calques quand le CombatCore signale la rupture (`break_part`) ; l'état endommagé suit
l'intégrité en continu. Rendu de contrôle : `docs/vorgane_3d/parties_calques.png`.

## 4. Solution A (3D en direct) ou B (sprites rendus) ?

Test limité réalisé pour chacune, dans la même arène, à côté du même sprite d'Aren :
`comparaison_solution_A.png` et `comparaison_solution_B_test.png`.

| Critère | A — GLB animé dans Godot | B — rendu Blender converti en pixel art |
|---|---|---|
| Cohérence avec Aren (pixel art) | ❌ Modelé lisse : deux styles à l'écran | ✅ Même densité de pixels, palette réduite, contour |
| Qualité perçue | Très bonne en soi | Bonne, fidèle au modèle |
| Animations | Fluides, interpolées | Images clés (8 à 12 par animation), style pixel art |
| Parties destructibles | Possibles (objets / matériaux en 3D) | Calques pré-rendus (6 par image) |
| Coût de production | Faible après le rig | + rendu par lots (~1 h CPU) à chaque modification |
| Performances | Rendu 3D + SubViewport | Simples sprites |
| Maintenance | Modifier l'animation = réexporter le GLB | Modifier = rerendre les calques (automatisé) |

**Recommandation : solution B**, pour la cohérence artistique avec les sprites HD-2D. La solution A reste
utilisable si l'on choisit plus tard des personnages en 3D stylisée.

## 5. Ce qui reste à faire
- Une vraie animation de **souffle** (gueule grande ouverte) : la mâchoire sculptée fermée la limite ;
  un retopo léger de la gueule serait nécessaire pour l'ouvrir franchement.
- Vérifier les **conditions d'utilisation Meshy** selon l'offre utilisée (les modèles générés avec une offre
  gratuite peuvent être soumis à une licence d'attribution ; les offres payantes accordent généralement
  l'usage commercial — à confirmer sur votre compte).
