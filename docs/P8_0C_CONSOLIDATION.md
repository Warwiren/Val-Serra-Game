# P8.0-C — Validation lumineuse, performances et nettoyage maîtrisé

Branche **`p8-0c-consolidation`**, depuis `p8-0b-lumiere` (`588e90c`). Godot 4.7.2. Tout est exécuté et vérifié sous 4.7.2.

* **Décision du créateur** : le profil **B, second dosage**, est la nouvelle direction lumineuse (validation **artistique**).
* **Lancement** : la ville démarre encore en A tant que les **performances** de B ne sont pas validées sur le GPU du créateur.
* **Nettoyage** : réversible, sans régression. Avant et après, les empreintes de scène et la série de contrôles sont
  identiques.

## 1. Lumière B consolidée (commit A)

* **Valeurs** : celles du second dosage, inchangées. Elles sont marquées comme retenues dans `scenes/p8/lumiere_p80b.gd`.
* **Adoption** : quand les performances seront validées, passer `PROFIL_DEFAUT := "b"`. C'est une seule ligne, rien
  d'autre ne change.
* **A** reste accessible par `--lumiere=a` et par **F4**.
* **Réglages indépendants conservés** :
  * étapes : `--b_jusqua=1..5` ;
  * effets : `--b_soleil`, `--b_ombres`, `--b_ssao`, `--b_tonemap`, `--b_lumieres`, `--b_flou`, `--b_glow`, `--b_aa` ;
  * réglages fins ;
  * `--b_version=1` (premier dosage) ;
  * `--b_tonemap=a` (sprites traités exactement comme en A).
* **Sprites** : non modifiés.
* **Contrôle** : `tools/p8/lumiere_ab_p80c.gd`.
  * Il vérifie le profil appliqué au chargement et les valeurs du second dosage.
  * Il vérifie le cycle F4 A → B → A, avec un retour **exact** à A : environnement, soleil, MSAA, débandage, attributs de
    caméra, flou d'écran, lumières des entrées.
  * Résultat : OK en partant de A et en partant de B.

## 2. Mesures de performance (commit B)

### Commandes (1920 × 1080, avec rendu, sur votre PC)

```bash
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_A.csv
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_B.csv --lumiere=b
```

**Pour isoler le coût de chaque effet** (même outil, B avec un effet modifié) :

| Fichier | Options ajoutées à `--lumiere=b` | Ce que l'écart avec `profil_B.csv` mesure |
|---|---|---|
| `profil_B_ombres_A.csv` | `--b_ombres=0` | les 4 tranches d'ombre (ombre de A conservée) |
| `profil_B_2tranches.csv` | `--b_tranches=2` | ajustement proposé : 2 tranches au lieu de 4 |
| `profil_B_ssao0.csv` | `--b_ssao=0` | le SSAO |
| `profil_B_msaa2.csv` | `--b_aa=msaa2` | MSAA ×4 → ×2 |
| `profil_B_aa0.csv` | `--b_aa=0` | tout le MSAA |
| `profil_B_flou_ecran.csv` | `--b_flou=ecran` | la profondeur de champ (remplacée par le flou d'écran de A) |
| `profil_B3.csv` | `--b_jusqua=3` | soleil, ombres, ambiance et couleurs, sans lumières, flou ni MSAA |

Exemple : `godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_B_ssao0.csv --lumiere=b --b_ssao=0`

### Vérifications de l'outil sous Godot 4.7.2

L'outil a été vérifié en Forward+ (Vulkan logiciel) et en Compatibilité.

* **Relevés par image** : durée de l'image, temps **CPU et GPU** mesurés par le moteur
  (`viewport_get_measured_render_time_cpu/gpu`), **appels de dessin**, **primitives**, objets.
* **Par point de vue** : moyenne, p95 et maximum ; ligne **MOYENNE** en fin de CSV.
* **Conditions de mesure** : synchronisation verticale coupée et, nouveau, aucune limite d'images
  (`Engine.max_fps = 0`).
* **Corrigé et ajouté** : l'en-tête du CSV consigne :
  * la **taille réelle du rendu 3D** (`root.size`) ;
  * la résolution demandée ;
  * le **profil de lumière effectivement appliqué** (compte rendu complet de B) ;
  * les options ;
  * la carte graphique et le pilote.
* **Alerte** si le rendu n'a pas la taille demandée (fenêtre bornée par l'écran). Il faut alors relancer avec
  `--plein_ecran=1`.
  * Piège évité : en étirement `canvas_items`, `get_visible_rect()` renvoie 1280 × 720, la taille de l'interface, alors
    que la 3D est bien rendue en 1920 × 1080.

### Ce qui est mesurable ici : appels de dessin et primitives

Ces mesures ne dépendent pas de la carte graphique. Moyenne des 10 points de vue :

| Profil | Appels de dessin | Primitives |
|---|---|---|
| A | 1 350 | 251 k |
| **B (retenu)** | **2 063 (+53 %)** | **409 k (+63 %)** |
| B `--b_ombres=0` (ombre de A) | 1 349 | 249 k |
| B `--b_tranches=2` | 1 384 (+3 %) | 265 k (+5 %) |
| B `--b_ombres_m=130` | 1 907 (+41 %) | 381 k |

* **Tout le surcoût d'appels et de primitives de B vient des 4 tranches d'ombre.** Chaque tranche redessine les objets
  qui y projettent une ombre.
* Les autres effets ne coûtent que du temps GPU, sans appel supplémentaire :
  * **SSAO** ;
  * **MSAA ×4** ;
  * **profondeur de champ** ;
  * les 5 lumières des entrées sont sans ombre, donc négligeables.
* **Temps CPU et GPU** : **non mesurables ici.** Dans ce conteneur, le rendu Vulkan se fait sur processeur (lavapipe).
  Ces temps ne sont **pas** extrapolables à votre GPU et ne sont donc pas reportés.

### Effets les plus coûteux, par ordre attendu sur un GPU, et options

Aucun de ces réglages n'est appliqué par défaut. À juger sur votre machine.

| Effet | Coût attendu | Ajustement possible | Effet visuel à vérifier |
|---|---|---|---|
| Ombres 4 tranches, 160 m | CPU (appels) et GPU (passes d'ombre) | `--b_tranches=2` : coût presque égal à A | ombres un peu moins fines près de la caméra ; la distance de 160 m est gardée (escaliers lointains) |
| SSAO (r 1,5, i 3,0) | GPU, proportionnel à la résolution | la qualité « demi-résolution » est déjà celle par défaut ; sinon réglage du projet `rendering/environment/ssao/quality` | ombres de contact au pied des murs et des marches |
| MSAA ×4 | GPU (mémoire, bande passante) | `--b_aa=msaa2` | scintillement des arêtes fines (volets, appuis) |
| Profondeur de champ | GPU, modéré | `--b_dof_flou` plus bas ; ou `--b_flou=ecran` | netteté du château et de la ville haute |
| Ombres jusqu'à 160 m | modéré | `--b_ombres_m=130` | ombres des volées lointaines |

**Recommandation** : mesurer d'abord A, B et `B --b_tranches=2`. Si B dépasse le budget, comparer d'abord l'image de
`--b_tranches=2`, qui est le gain le plus net pour la plus petite différence visuelle attendue. Viennent ensuite
`--b_aa=msaa2`, puis le SSAO.

## 3. Audit des dépendances (étape A)

### Méthode

* **Graphe des références `res://`** de chaque fichier suivi (scènes, scripts, shaders, données, outils, tests). Il
  inclut les préfixes de dossier, c'est-à-dire les chargements dynamiques construits à l'exécution.
* **Points d'entrée** : F5 (`project.godot`), toutes les scènes `.tscn` (F6), les tests et les outils.
* **Héritage** (`extends`) et **redéfinitions** : une fonction de base redéfinie sans `super()` est morte, même si son nom
  est cité ailleurs.
* **Fonctions et constantes sans appelant** : aucune occurrence du nom ailleurs, ni en appel direct, ni en chaîne
  (`call`, `connect`, `has_method`).
* **Options de lancement et parcours** : chaque parcours de `routes25.gd` est comparé au plan de la seule ville restante.
* **Empreinte de scène** (`tools/p8/empreinte_scene_p80c.gd`, nouveau) : condensé de toute la géométrie, des matières, des
  lumières, des collisions et de l'environnement.
  * Relevé sur **19 configurations** avant tout changement : F5, Colisée (deux états), ville A, B et B1, scènes F6 P8.0-A
    et P8.0-B, options de comparaison, catalogue, tunnel, combats.
  * Puis comparé après chaque lot.

### Résultats

* **Fichiers** : tout le code est atteint par une scène, un test ou un outil. Il n'y a pas de fichier « orphelin » : le
  code mort se trouvait dans des **branches d'options** et des **fonctions**.
* **Héritage de la ville** : `ville_blockout` → `ville_v06` → `ville_v07a` → `ville_v07b`. Les trois premiers scripts sont
  **indispensables**, malgré leur numéro de phase. Seuls deux corps de `decorer()`, redéfinis sans `super()`, et leurs
  utilitaires étaient morts.
* **Ancien nom, encore utile** : `tools/p7/plan_v07a.py` n'est **pas** mort. `plan_grande_place_p77.py` l'appelle pour
  dessiner le plan de la V0.7-B.

## 4. Suppressions et simplifications (commits C0 à C3, D)

| Lot | Élément | Justification (références réelles) |
|---|---|---|
| C1 | `forge_p79.gd` : variantes **A** et **B**, soit `_accessoires_archi`, `_cyl`, `_quaternius`, `_porte_quaternius`, `_accessoires_quaternius` et les branches non hybrides de `_archi` (−159 lignes) | Atteintes seulement par `--forge=A\|B`. Comparatif P7.9 clos ; forge D approuvée. |
| C1 | `scenes/p7/boutique_p710.gd` (121 lignes) | Chargé seulement par `--boutique=710` ; boutique P7.11 approuvée. |
| C2 | `data/p7/ville_v05.json`, `ville_v06.json`, `ville_v07a.json` (6 194 lignes) | Chargés seulement par `--ville=v05\|v06\|v07a` ou les exports correspondants de `colisee.gd`. Aucune scène, aucun test, aucune transition. |
| C2 | `tools/p7/build_ville_v05.py`, `build_ville_v06.py`, `build_ville_v07a.py` (886 lignes) | Générateurs de ces seules données. `build_ville_v07b.py` est autonome : il régénère ses données à l'identique. |
| C2 | `colisee.gd` : exports `ville_v05`, `ville_v06`, `ville_v07a`, constantes et branches de version (−45 lignes) | Une seule ville. `_zone_ville()` et le chargement de la ville sont simplifiés. |
| C2 | `ville_blockout.decorer` et `ville_v06.decorer`, `_niveau`, `_colisee`, `_niveaux` | Redéfinis par `ville_v07a.decorer` sans `super()`. Un stub est gardé pour l'héritage. |
| C2 | `routes25.gd` : 11 parcours des plans V0.5 / V0.6 et `V06_VUES` (−184 lignes) | Coordonnées d'un plan retiré ; aucune référence dans les tests ni les outils. |
| C3 | `forge_p7101._fenetre_plaquee`, `look25.shade` (+ `AMBIENT`, `DIFFUSE`), `secteurs25.groupes_masques`, `elements_rendus`, `world25.trigger_at`, `game_state.hero_portrait`, `occlusion_dynamique.set_camera`, `test_p46_corrections._symmetry` | Aucun appelant, direct ou par nom. |
| D | `_cyl` des bordures et du civique → `Archi.cylindre()` ; tests `get_script() == Boutique711` → `bo != null` | Doublon identique ; condition devenue toujours vraie. |

**Bilan** (depuis `588e90c`) :
* GDScript : −779 lignes, dont environ −700 dans le code du jeu ; les nouveaux outils de contrôle ajoutent environ
  +330 lignes.
* Python : −886 lignes.
* Données : −6 194 lignes.
* Options retirées : `--ville=v05|v06|v07a`, `--forge=A|B`, `--boutique=710` (cette dernière affiche désormais P7.11).
* Tout reste restaurable depuis l'historique Git (commit `588e90c`).

**Incident de commit, signalé** : la suppression de `boutique_p710.gd`, indexée trop tôt, est partie dans le commit B
(`1704fb2`). Elle a été rétablie à l'identique dans le commit suivant (`c4db483`), puis retirée avec sa justification
au lot C1. L'historique n'a pas été réécrit. Seul le commit `1704fb2`, pris isolément, ne se charge pas.

## 5. Dépendances importantes conservées

| Élément | Raison |
|---|---|
| `scenes/p4/avant_poste.gd` | Script de base du Colisée et de la ville (héritage). |
| `ville_blockout.gd`, `ville_v06.gd`, `ville_v07a.gd` | Chaîne d'héritage de `ville_v07b.gd` : escaliers, toits, château, ambiance, caméra, `decorer()` de la V0.7-A. |
| `forge_p79.gd` | Forge **D** (défaut), forge **C** (`--forge=C`, comparaison avant / après) et **utilitaires Quaternius partagés** (`_modele`, `_fusion_gltf`, `_terre_cuite`), utilisés par la forge D, la boutique P7.11, les bordures et le civique. |
| `tools/p7/plan_v07a.py` | Dessin du plan des données ; appelé par `plan_grande_place_p77.py`. Son défaut est passé à la V0.7-B. |
| Parcours `p7_v07_*` (V0.7-A) | Coordonnées du plan V0.7-B ; `p7_v07_portail` teste le portail ville ↔ Colisée. |
| Caméras `V06O` et `P24` (touche C dans la ville) | Comparaisons de caméra, hors périmètre. |
| `data/p6/colisee_tunnel_A/B/C.json` | Lus par les tests unitaires. |
| `scenes/p6/colisee_tunnel_A_6_5m.tscn`, `_B_8_5m.tscn`, `_C_9_5m.tscn` | **Incertain** : lot 4 de l'audit P7.12, toujours en attente de votre décision. Conservés. |
| `art/` (tous les dossiers) | Beaucoup de ressources sont chargées par motif de nom. Aucune suppression de ressource. |
| `catalogue_archi_p77.tscn` | Outil de revue des composants, base de l'industrialisation (§ 8). |
| Constantes documentaires `colisee.PLONGEES_VILLE`, `archi_p77.TYPES_BAIES` | Non lues, mais elles documentent les essais d'angle et le vocabulaire des baies. Conservées. |
| Combat : `sprite_monster_view._set_flash_all`, `stage.light_nodes` | Sans appelant, mais le combat est hors périmètre (CLAUDE.md). Signalées seulement. |

## 6. Dette restante

* **`colisee.gd`** (2 765 lignes) porte à la fois le Colisée et la ville : caméra, portail, profils.
  * Une séparation « ville » / « Colisée » serait la vraie réduction de complexité, mais c'est une réorganisation
    majeure, hors périmètre.
  * Le libellé de mesure `s.arch = "P7.3 — Ville V0.6 · …"` est historique, sans effet sur le jeu.
* **Chaîne d'héritage à quatre niveaux** pour une seule ville. On pourrait l'aplatir en fusionnant les scripts, mais le
  risque est réel pour un gain de lecture seulement. À faire avec l'industrialisation (§ 8), sous contrôle d'empreinte.
* **Doublons dans les références validées** :
  * `_pierre` (forge D / civique, 99 % identiques) ;
  * `_mur_perce` (forge D / boutique, 62 %) ;
  * prismes de pignons ;
  * habillage des toits Quaternius.

  À mutualiser dans la phase d'industrialisation, pas ici.
* **Erreur antérieure** dans l'ancien combat (`battle_scene.tscn`) : affectation de `targeted` sur `hunter_view.gd`. Elle
  est présente avant P8.0-C et touche le combat, hors périmètre.
* **Options historiques encore présentes** : `--tranche=0`, `--place=0`, `--civique=0`, `--bordures=0`, `--coupes_p80b=0`,
  `--toits_p80b=0`, `--plongee_ville`, `--zone_lecture`, `--escamotage=fondu`, `--escamotage_partiel=0`.
  * Ce sont des comparaisons avant / après de lots validés ou des essais encore utiles.
  * À retirer seulement quand vous les jugerez inutiles.
* **Comptes rendus des branches passées** dans `README.md` (« Lancer le jeu ») : ils citent encore les options retirées
  à titre historique. Le tableau des comparaisons est à jour.

## 7. Tests de non-régression

### Série complète

`bash tools/p8/non_regression_p80c.sh` (nouveau) : **24 / 24 OK** sur l'état final.

| Contrôle | Résultat |
|---|---|
| Scène F5 (forêt) chargée sans erreur de script | OK |
| Tests unitaires | **76 / 76** |
| Tutoriel (e2e ouverture) et saut du tutoriel | RÉUSSIS (0 échec) |
| Sondes du Colisée | 10 / 10 |
| Ville : sondes (bords, façades, gardes, grille) | **40 / 40**, caméra A et B |
| Ville : trajets (porte sud → place → Colisée → château → ruelle) | aucune étape bloquée, A et B |
| Portail ville ↔ Colisée (`p7_v07_portail`) | 4 passages, aucune étape bloquée, A et B |
| Examens E sans saut de caméra | **0 px**, lumière A et B |
| Profils de lumière A / B et F4 | OK |
| Escamotage | Aren jamais masqué, aucun clignotement |
| Cadrage (6 parcours) | Aren jamais masqué, aucun blocage |
| Tests smoke : collisions V11, locomotion, animations V09B.5, Ilya V09C, sols P5.2 et P5.3-B, combat P5 | 0 échec |

### Avant / après, mêmes commandes sur `588e90c` et sur l'état final

* **Parcours de la ville et du Colisée** : résultats identiques (sondes, étapes, séquence des portails).
* **Empreintes de scène** : **identiques** sur les 19 configurations.
  * Deux exceptions attendues : `--forge=A` (devenu le blockout) et `--boutique=710` (devenu P7.11), deux options
    retirées.
* **Outils de la ville** : `camera_volumes_p76.py` donne l'axe du château dégagé et 0 recouvrement. Les données V0.7-B
  régénérées sont identiques, le plan aussi.
* **Note sur les parcours de ville** : ils se lancent **sans** `--etat=tutorial_completed`, car la scène fixe elle-même
  l'état. Avec cette option, Aren reste bloqué au départ, avant comme après le nettoyage.

## 8. Proposition technique : industrialiser bâtiments et décors (étape C, NON implémentée)

### État actuel

* **Bibliothèque partagée** : `archi_p77.gd`.
  * Matières : `macon`, `enduit`, `plein`.
  * Faces et boîtes : `face`, `boite`.
  * Composants : baies (13 types), volets, balcons, lanternes, cheminées, toits (2 pans, croupe, appentis), jardinières.
  * `fusionner`, qui regroupe les maillages par matière.
  * Bâtiment décrit par dictionnaire (`batiment(r, h0, d)`), utilisé par la tranche P7.6.
* **Les deux références sont écrites à la main**, avec des outils locaux en double :
  * la **forge D** (`forge_p7101.gd`, 32 fonctions) ;
  * la **boutique P7.11** (`boutique_p711.gd`, 28 fonctions).
* **Utilitaires Quaternius mal placés** : ils vivent dans `forge_p79.gd`. Bordures, civique et boutique reçoivent donc la
  forge (`fo`) en paramètre.

### Proposition, en cinq étapes indépendantes

Chaque étape est vérifiée par l'empreinte (MD5 identique pour la forge D et la boutique).

1. **Module de modèles** : `scenes/p7/modeles_p8.gd` regroupe `_modele`, `_fusion_gltf` et `_terre_cuite`, extraits de
   `forge_p79.gd`. Bordures, civique et boutique n'ont plus besoin de la forge.
2. **Maçonnerie en épaisseur dans `Archi`**, sur le modèle de la forge D :
   * `mur_perce(face, ouvertures, épaisseur)`, qui unifie les deux `_mur_perce` ;
   * `claveaux` et arc segmentaire ;
   * chaînes d'angle ;
   * corniche sur consoles ;
   * prisme de pignon ;
   * `pierre(nom, base, teinte, réglages)` avec cache, qui remplace les deux `_pierre`.
3. **Vocabulaire du pan de bois dans `Archi`**, sur le modèle de la boutique P7.11 :
   * encorbellement ;
   * pièces de bois en façade (`_piece`) ;
   * croisées éclairées ;
   * devanture peinte en embrasure ;
   * potence ;
   * enseigne (forme paramétrée : flacon, enclume…).
4. **Fiche bâtiment en données** : étendre le dictionnaire de `Archi.batiment` aux deux langages.
   * Langages : « RDC pierre en épaisseur + étages enduits ou pan de bois », toiture `tuiles_p7101` avec rives, enseigne,
     lanternes.
   * Un nouveau commerce serait alors une fiche plus quelques accessoires propres, au lieu d'un générateur de 600 à
     800 lignes.
   * La forge D et la boutique resteraient des générateurs dédiés, mais construits sur ces composants.
5. **Catalogue F6** (`catalogue_archi_p77.tscn`) : ajouter les composites des références (façade de forge, devanture,
   pignon sur rue), pour la revue artistique de chaque nouveau composant.

**Ce que la proposition évite** :
* convertir la ville en scènes éditables ;
* réécrire tous les générateurs d'un coup ;
* modifier l'occultation : la méta `vol` et `_classer_volumes` restent le contrat d'escamotage de tout composant.

**Effort indicatif** :
* étape 1 : une demi-journée ;
* étapes 2 et 3 : 2 à 3 jours chacune, avec contrôle d'empreinte ;
* étape 4 : 2 jours ;
* étape 5 : une demi-journée.

## 9. Risques et travaux reportés

* **Performances de B** : seuls les appels de dessin et les primitives sont connus ici (+53 % et +63 %, dus aux ombres).
  * Les temps réels du SSAO, du MSAA et de la profondeur de champ restent à mesurer sur votre GPU (commandes du § 2).
  * Avant de passer `PROFIL_DEFAUT` à "b", vérifier aussi les scènes F6 et le Colisée : la lumière B n'agit que dans la
    ville.
* **Scènes de tunnel** du Colisée (lot 4 de l'audit P7.12) : décision toujours en attente.
* **Ressources graphiques** : aucun nettoyage, faute de preuve d'inutilité, car les chargements se font par motif.
  * Exemple : `art/portraits/hero_*.svg` était aussi construit par `hero_portrait()` (retiré). Il reste chargé par
    `src/presentation/art.gd`, par un motif : un simple contrôle de nom de fichier l'aurait déclaré inutile à tort.
* **`colisee.gd`** : sa séparation en « Colisée » et « ville » est à envisager avant que P8.1 n'y ajoute la vie urbaine.

## 10. Prochaine phase technique proposée (non implémentée)

**P8.1-T — Socle de la vie urbaine**, avant d'y mettre des PNJ :

1. **Lumière** : adoption de B par défaut (`PROFIL_DEFAUT`) une fois le profil GPU validé, puis budget d'affichage fixé
   à partir des CSV : appels de dessin, temps GPU au 95e centile.
2. **Séparation de la ville hors de `colisee.gd`**, dans un script de zone « ville » qui hérite du socle. Comportement
   identique, contrôlé par l'empreinte et `non_regression_p80c.sh`.
3. **Emplacements de PNJ** : les données `emplacements_pnj` existent déjà (belvédère, buvette). Il faut :
   * un format commun pour les emplacements, les trajets et les horaires ;
   * un contrôle de navigation (collisions des données) ;
   * un budget de sprites mesuré avec le profil B.
4. **Ensuite seulement**, l'étape 1 de l'industrialisation (§ 8), si de nouveaux bâtiments sont prévus avant la vie
   urbaine.

## 11. Commits

| Commit | Lot |
|---|---|
| `b7880ef` | A : lumière B retenue, `PROFIL_DEFAUT`, contrôle des profils et de F4 |
| `1704fb2` | B : profilage 1920 × 1080 (taille réelle, profil, moyenne), option `--b_tranches=2` |
| `c4db483` | B : rétablit `boutique_p710.gd` (incident, § 4) |
| `a45f9ed` | C0 : outil d'empreinte de scène |
| `cb13fd7` | C1 : forges A et B, boutique P7.10 |
| `31f24af` | C2 : villes V0.1, V0.6 et V0.7-A |
| `948eabb` | C3 : fonctions sans appelant |
| `8a2fe4a` | D : simplifications, série de non-régression |
| (suivant) | D : documentation (ce rapport, README, CLAUDE.md) |
