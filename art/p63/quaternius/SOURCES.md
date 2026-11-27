# Quaternius — sélection P6.3 (Colisée)

**Provenance** : deux packs préparés par le créateur sur le Drive du projet. Ce sont les versions gratuites
**Standard**, téléchargées le 22/11/2026 :
* `ValSerra_Quaternius_FantasyProps_Godot_glTF.zip` (Fantasy Props MegaKit, 94 modèles) ;
* `ValSerra_Quaternius_MedievalVillage_Godot_glTF.zip` (Medieval Village MegaKit, 176 modèles).

**Licence** : CC0 1.0 Universal (domaine public), « Models by @Quaternius » — <https://quaternius.com>.
Le fichier `License_Standard.txt` d'origine est conservé dans chaque dossier.

**Ce qui est importé** : seulement les modèles ci-dessous, avec leurs `.bin` et les textures qu'ils utilisent. Les
packs ne sont **pas** importés en entier : les archives restent sur le Drive.

| Dossier | Modèles | Textures (jeux « trim ») |
|---|---|---|
| `fp/` (Fantasy Props) | Bench, WeaponStand, Peg_Rack, Lantern_Wall, Torch_Metal, Chest_Wood, Barrel, Crate_Wooden, Banner_1_Cloth, Banner_2_Cloth, Dummy, Table_Large, Stool | Trim_Furniture, Trim_Metal, Trim_Cloth |
| `mv/` (Medieval Village) | DoorFrame_Round_Brick, Door_8_Round | RockTrim, WoodTrim, MetalOrnaments |

**Modifications** :
* textures **réduites de 2048² à 1024²** (Lanczos), pour garder le projet léger ; au zoom ×3 du Colisée, la différence
  n'est pas visible ;
* aucune géométrie, UV ni matériau glTF n'est modifié ;
* les teintes et l'échelle de chaque usage sont réglées par la scène (`scenes/p6/habillage_p6.gd`).

**Statut** : **PROVISOIRE**, essai du pilote artistique P6.3, en attente de la revue du créateur. Rien n'est
« final ».

## Ajout P7.9 — comparatif de la forge-armurerie (25/11/2026)

Même provenance (archives Standard du Drive, CC0). Ne sont importés que les modèles du comparatif, dans les dossiers
existants (aucun doublon des quinze modèles de P6.3, qui sont réutilisés : `Barrel`, `Crate_Wooden`, `WeaponStand`,
`DoorFrame_Round_Brick`, `Door_8_Round`).

| Dossier | Modèles ajoutés | Textures ajoutées (1024², avec mipmaps) |
|---|---|---|
| `mv/` | Wall_UnevenBrick_Straight, Wall_UnevenBrick_Window_Wide_Round, Wall_UnevenBrick_Door_Round, Corner_Exterior_Brick, Roof_RoundTiles_8x12, Roof_Front_Brick8, Prop_Chimney, Window_Wide_Round1, WindowShutters_Wide_Round_Open | UnevenBrick, Plaster, RoundTiles, Brick |
| `fp/` | Anvil, Workbench, Whetstone, Bucket_Metal, Shield_Wooden, Sword_Bronze | Trim_Props |

**Statut** : PROVISOIRE, comparatif P7.9 seulement (`scenes/p7/forge_p79.gd`). Aucune généralisation avant décision.

## Ajout P8.1-A — végétation de la cité (27/11/2026)

Même provenance (archive Standard du Drive, Medieval Village MegaKit, CC0). Seule une sélection est importée.

| Dossier | Modèles ajoutés | Texture ajoutée |
|---|---|---|
| `mv/` | Prop_Vine1, Prop_Vine2, Prop_Vine4 (plantes grimpantes de façade) | T_VineLeaf_png (512², taille d'origine) |

Les arbustes, plantes, fleurs et couvre-sols de la cité réutilisent les modèles Quaternius de la forêt F5
(`ValSerra_P49_V07B_PREFLIGHT_GODOT/assets/models/`, CC0, licence dans `ValSerra_P49_V07B_PREFLIGHT_GODOT/docs/`), sans
copie. Module : `scenes/p8/vegetation_p81.gd`. **Statut** : PROVISOIRE, en attente de la revue du créateur.

## Ajout P8.1-A — marchandises des étals (27/11/2026)

Même provenance (archive Standard du Drive, Fantasy Props MegaKit, CC0). Modèles seuls (`.gltf` + `.bin`) : ils
utilisent les textures « trim » déjà présentes dans `fp/` (Props, Furniture, Metal, Cloth, 1024²) ; aucune texture
ajoutée.

| Dossier | Modèles ajoutés |
|---|---|
| `fp/` | FarmCrate_Apple, FarmCrate_Carrot, Barrel_Apples, Bag, Pouch_Large, Pot_1, Vase_2, Vase_4, Bucket_Wooden_1, Bottle_1 |

Utilisés par `scenes/p7/bordures_p713.gd` (`_marchandises_modeles`, étals 0 à 3, halle). **Statut** : PROVISOIRE.
