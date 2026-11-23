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
