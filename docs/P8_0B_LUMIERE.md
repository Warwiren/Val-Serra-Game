# P8.0-B — Direction lumineuse et post-production HD-2D

Branche **`p8-0b-lumiere`**, depuis `p8-0a-cadrage-ville`. EXPÉRIENCE, rien n'est validé.

* **P8.0-A clos.** La plongée de 11° et la plongée civique de 6,5° sont les références. Les autres angles restent des
  essais historiques en F6. La zone de lecture à 17° est désactivée par défaut : elle n'est active que dans sa propre
  scène F6 ou avec `--zone_lecture=`.
* **Profil par défaut** : A (P7.13), y compris dans `ville_v07b.tscn`. Le profil B ne s'active que par option, par la
  scène F6 dédiée ou par la touche F4.

## 1. Premiers plans (trois commits séparés)

| Commit | Correction | Option de comparaison |
|---|---|---|
| 1/3 | Toits de la tranche P7.6 (auberge, et les deux immeubles de la ruelle par cohérence) en matière « tuiles » à la teinte de l'appentis de la forge D, au lieu de « tuiles_a » brun foncé. Le versant à l'ombre ne forme plus une masse noire dans la ruelle des Tonneliers. | `--toits_p80b=0` |
| 2/3 | Auberge et Guilde coupées à 3,1 m au lieu de 3,5 m, soit 0,4 m sous la place et au-dessus des baies et de la porte de l'auberge (3,0 m). Le dessus de coupe est en maçonnerie arasée sombre, avec une arase élargie à 0,55 m, à la place du plancher orangé qui prolongeait le dallage. | `--coupes_p80b=0` |
| 3/3 | Tours et remparts de la porte sud coupés à 1,2 m (lecture de parapet), avec un dessus de pierre (chemin de ronde) au lieu des souches de 3,5 m au premier plan de la placette. | `--coupes_p80b=0` |

* **Mécanisme** : `ville_v07b.COUPES_P80B` / `_coupe_de` et styles de dessus de coupe dans `_chapeau`.
* **Inchangés** : les autres volumes, les règles d'escamotage, les collisions et le plan. La Guilde garde sa porte de
  3,6 m, déjà coupée à 3,5 m auparavant.

## 2. Profils de lumière (`scenes/p8/lumiere_p80b.gd`)

* **A — P7.13** : rendu actuel, relevé au chargement puis rétabli à l'identique.
* **B — P8.0-B** : construit par étapes, dans l'ordre du brief.

| Étape | Contenu de B | Couper seul |
|---|---|---|
| 1 Soleil | Même direction (composition des ombres conservée), lumière plus chaude (dosage 2 : 1,0 / 0,89 / 0,75 ; dosage 1 : 1,0 / 0,86 / 0,68 ; A : 1,0 / 0,9 / 0,78) et plus forte (1,35 au lieu de 1,1). Ombres en 4 tranches jusqu'à 160 m, biais normal 1,4. | `--b_soleil=0`, `--b_ombres=0`, `--b_ombres_m=<m>` |
| 2 Ambiance | Lumière indirecte tirée du ciel (contribution 0,55) au lieu de la couleur unie de A. Dosage 2 : couleur froide 0,58 / 0,66 / 0,88, énergie 0,5 (A : 0,62). SSAO rayon 1,5, intensité 3,0, part au soleil 0,4 (dosage 1 : 1,2 / 1,8 / 0,15). | `--b_ambiance=0`, `--b_ssao=0`, `--b_amb_rgb=`, `--b_amb_e=`, `--b_ssao_r=`, `--b_ssao_i=`, `--b_ssao_l=` |
| 3 Couleurs | A est **déjà** en Filmic (exposition 1,0, blanc 1,0, saturation 1,04, contraste 1,06). B : Filmic, blanc 3,0 ; dosage 2 : exposition 1,05, contraste 1,1, saturation 1,04 (dosage 1 : 1,15 / 1,06 / 1,08). | `--b_tonemap=filmic\|a\|agx\|aces\|lineaire`, `--b_exposition=`, `--b_blanc=`, `--b_contraste=`, `--b_saturation=` |
| 4 Lumières | Une OmniLight chaude, sans ombre, portée 5 m, devant chacune des 5 entrées fonctionnelles (Guilde, auberge, forge, boutique, hôtel de ville). | `--b_lumieres=0` |
| 5 Post-production | Profondeur de champ réelle (flou lointain dès 90 m, transition 120 m, intensité 0,05) à la place du flou d'écran vertical. Bloom coupé, sur option seulement. MSAA 3D ×4 et débandage. | `--b_flou=dof\|ecran\|aucun`, `--b_dof_m=`, `--b_dof_flou=`, `--b_glow=1`, `--b_aa=msaa4\|msaa2\|0` |

* **Dosages** : `--b_version=2` (défaut, 27/11, § 7) ; `--b_version=1` = premier dosage (commit `638cf52`).
* **Étapes cumulées** : `--b_jusqua=N` applique B jusqu'à l'étape N (1 = soleil seul, … 5 = tout). Cela permet de
  juger la contribution de chaque étape.
* **Commandes** :
  * B : `godot --path . res://scenes/p7/ville_v07b.tscn -- --lumiere=b`, ou F6 sur `scenes/p7/ville_v07b_p80b.tscn` ;
  * **F4** en jeu bascule A ↔ B au même endroit ; un message résume les effets actifs ;
  * parcours identique pour A et B : `--route=p80a_cadrage` (R1 ruelle et place, R3 forge et Colisée, R4 et R5
    quartier civique et château, R6 belvédère, devant la boutique).
* **Changement de zone.** B est retiré en quittant la ville (`lum.quitter()`) : le Colisée ne reçoit aucun réglage de
  B. Une recharge de la ville (touches C ou L) revient au profil demandé au lancement.

## 3. Diagnostic (lecture du code ; à confirmer en Forward+)

* **Flou actuel.** `src/p4/tilt_shift_p41.gdshader` floute le haut de l'écran selon la seule position verticale
  (intensité 0,5 pour la caméra de ville). La porte fortifiée et le château, toujours en haut du cadre, sont donc
  floutés quelle que soit leur distance. Dans B, la profondeur de champ dépend de la distance réelle :
  * jusqu'à 90 m, rien n'est flou (place, forge, porte fortifiée à environ 70 m de la place) ;
  * au-delà, flou progressif et léger (ville haute, château à environ 150 m et plus).
  * En Compatibilité, la profondeur de champ n'existe pas : B garde alors le flou d'écran.
* **Ombres anormales sur les escaliers lointains.** Le soleil n'avait qu'une ombre orthogonale, limitée à 120 m et
  effacée dès environ 96 m. Les volées lointaines entrent et sortent de l'ombre quand la caméra avance, avec une faible
  densité de texels. Dans B : 4 tranches jusqu'à 160 m avec fondu, et biais normal relevé contre l'acné des nez de
  marches (déjà constatée à l'essai `--ombres_ville` de P7.13).
* **Murs instables, fenêtres et volets qui scintillent.** Le projet n'active aucun anticrénelage 3D (`msaa_3d` absent
  de `project.godot`). Les arêtes fines (volets, appuis, encadrements de 3 à 5 cm) scintillent donc en mouvement. Les
  faces coplanaires ont été traitées en P6.3.2 et P7.13.
  * Dans B : MSAA ×4 sur les arêtes.
  * Hors de portée du MSAA : les joints procéduraux des matières (0,6 à 1,6 cm) et les environ 470 px résiduels de la
    façade ouest de la boutique (P7.13). Si ces joints scintillent encore, il faudra régler le filtrage des joints de
    `maconnerie_p64` (non modifié ici).
  * Mesure : `tools/p7/scintillement_p713.gd -- --lumiere=b`.
* **Ombres de contact.** Il n'en existe pas en ville (le Colisée a des ombres de contact locales depuis P6.4.3). Le
  SSAO de B les fournit au pied des murs, des marches et des soutènements.
* **Sprites.** Aren et les futurs PNJ sont non éclairés, avec une ombre ronde : ils ne reçoivent ni le soleil, ni le
  SSAO, ni les lumières d'entrée. Ils passent en revanche par le rendu Filmic et les réglages de couleur.
  * Leurs couleurs validées peuvent donc légèrement changer en B. **Correction du 27/11** : A est déjà en Filmic, donc
    `--b_tonemap=lineaire` les CHANGE (plus sombres). Comparer avec **`--b_tonemap=a`**, qui garde le rendu des couleurs et
    le glow de A : les sprites sont alors traités exactement comme en A (seul le MSAA touche leurs bords).
  * Le shader des personnages n'est pas modifié. Leur intégration lumineuse (rendu V10, touche K) reste un essai
    séparé.

## 4. Performances

Ces coûts n'ont pas été mesurés dans ce conteneur.

* **Commandes de mesure**, avec rendu, sur votre machine :

```bash
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_A.csv
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_B.csv --lumiere=b
godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080 --sortie=profil_B3.csv --lumiere=b --b_jusqua=3
```

* En jeu : `--print-fps` (option du moteur) et touche F3 (limite d'images coupée).
* **Coûts attendus en Forward+**, par ordre décroissant :
  * SSAO (demi-résolution par défaut) ;
  * MSAA ×4 ;
  * profondeur de champ ;
  * 4 tranches d'ombre au lieu d'une ;
  * les 5 lumières locales sont sans ombre, donc négligeables.
* Si le budget est serré : `--b_aa=msaa2`, `--b_ombres_m=130`.

## 5. Tests (exécutés le 27/11 sous Godot 4.7.2.stable.official.ed1daf0bf)

| Vérification | Résultat |
|---|---|
| `godot --headless --path . --quit-after 60` | chargement sans erreur de script |
| `tests/run_tests.gd` | 76 / 76 |
| `e2e_p6_ouverture.gd -- --tuto-rapide`, `e2e_p6_saut_tutoriel.gd` | RÉUSSI (0 échec) |
| parcours `p6_sondes` | 10 sondes sur 10 |
| ville en A puis en `--lumiere=b` | sans erreur de script ; `Environment.TONE_MAPPER_AGX` et `RenderingServer.get_current_rendering_method()` existent |
| F4 A -> B -> A | retour exact à A (environnement, soleil, MSAA, attributs de caméra, flou, lumières éteintes) |
| `stabilite_interactions_p7121.gd -- --route=p7_7121_interactions --quit`, en A et en B | **0 px** sur 7 examens |
| `escamotage_p7122.gd` | Aren jamais masqué, aucun clignotement ; `tour_sud_e` : 3 bascules (5 en P8.0-A), intervalle minimal 10,2 s (1,1 s en P8.0-A) |
| `tools/p8/cadrage_p80a.gd -- --route=p80a_cadrage`, en A et en B | Aren jamais masqué, aucun clignotement, aucun blocage (l'outil ne compilait pas : corrigé) |

* `talk_failed` (« ex_*_fermeture ») dans le compte rendu du parcours d'interactions : identique sur `p8-0a-cadrage-ville`,
  donc antérieur à P8.0-B.
* Avertissement d'ancres de `avant_poste._build_tilt` et fuites à la fermeture : déjà présents en A et sur P8.0-A.

## 6. Réserves à vérifier en Forward+

* **Sans effet en Compatibilité**, donc jamais vu dans ce conteneur : SSAO, profondeur de champ. Glow et MSAA y
  diffèrent.
* **Réglages proposés**, à juger et ajuster : exposition et blanc du rendu Filmic, contraste, saturation, énergie
  d'ambiance.
* **Constantes moteur** : confirmées en 4.7.2.
* **Rendu de B** : vu le 27/11 en Forward+ par Vulkan logiciel (images justes, temps non significatifs) et en
  Compatibilité. Le jugement artistique reste celui du créateur, en jeu.

## 7. Reprise du 27/11 (retour du créateur sur la vidéo de B)

### 7.1 Porte sud : dessus bleu-noir

* **Cause.** Les tours et remparts de la porte sud ne sont dessinés qu'en **muret de 1,6 m coiffé d'une tranche sombre**
  de 8 cm (`ville_blockout.gd`, 0,12 / 0,11 / 0,10), la collision des données restant à 9-12 m. La coupe P8.0-B à 1,2 m
  et son dessus « pierre » (`_chapeau`) n'étaient affichés qu'en mode d'escamotage « haut ». Or, au départ de la
  placette, la visée passe **entre** les deux tours : les volumes ne sont pas escamotés, le muret entier reste affiché
  avec sa tranche sombre, que le ciel bleute.
* **Correction** (commit distinct) : le style « pierre » est une coupe **permanente**. La partie haute (0,4 m et la tranche
  sombre) est toujours masquée, et le chemin de ronde de pierre toujours affiché. Collision inchangée ; `--coupes_p80b=0`
  rend l'état P8.0-A.
* **Réserve** : les faces du muret restent en matière de blockout gris-bleu (hors périmètre : pas d'architecture hors des
  premiers plans identifiés).

### 7.2 Sol de la grande place, uniforme et orangé : part de chaque étape

Mesures sur le dallage (Aren au centre de la place, x 50, y 104). R/B = rouge / bleu (orangé) ; soleil / ombre = contraste
entre dallage au soleil et ombre de la fontaine ; écart-type = relief du dallage.

| Rendu | Variante | R/B | soleil / ombre | écart-type |
|---|---|---|---|---|
| Compatibilité | A | 1,40 | 2,12 | 22,2 |
| | B étape 1 (soleil) | **1,54** | 2,15 | 22,3 |
| | B étapes 1-2 (ambiance) | 1,38 | **1,92** | 23,5 |
| | B étapes 1-3 (Filmic 1,15) | 1,43 | 1,96 | **20,8** |
| Forward+ | A | 1,54 | 1,28 | 12,9 |
| | B dosage 1 | 1,58 | 1,28 | 14,1 |
| | **B dosage 2** | **1,46** | **1,31** | **14,4** |

* **Orangé** : il vient du soleil chaud (étape 1). En Forward+, A est déjà orangé (1,54) : le dosage 1 l'accentuait.
* **Uniformité** : l'ambiance du ciel (étape 2) relève les ombres, et l'exposition 1,15 (étape 3) pousse le dallage
  dans l'épaule du Filmic, qui le comprime. La saturation de 1,08 réchauffait aussi les ombres, qui ne devenaient pas
  froides. En Forward+, l'écart entre soleil et ombre est faible dès A (1,28).
* **Dosage 2** (défaut de B) : soleil moins orangé, ambiance froide et plus basse (0,5), exposition 1,05, contraste
  1,1, saturation 1,04. L'image reste plus chaude et plus contrastée que A, sans dominante orange.

### 7.3 Ombres de contact (SSAO)

* Avec le dosage 1, le SSAO ne changeait presque rien : rapport pied de façade / façade de la forge 0,66 avec SSAO,
  contre 0,68 sans. En effet, le SSAO n'agit que sur l'ambiance, et sa part au soleil était de 0,15.
* **Dosage 2** : rayon 1,5, intensité 3,0, part au soleil 0,4. Le rapport passe à 0,59 (0,67 en A). Les nez de marches
  et le pied de la forge sont nettement plus marqués, sans halo visible. Les réglages intermédiaires restent possibles :
  `--b_ssao_i=2.5 --b_ssao_r=1.2 --b_ssao_l=0.3` donne 0,61.

### 7.4 Aren et les sprites

* A applique déjà un Filmic (exposition 1,0, blanc 1,0) et un glow de 0,22. B change l'exposition et le blanc, et coupe
  le glow. `--b_tonemap=lineaire` ne reproduit donc pas A.
* **`--b_tonemap=a`** garde le rendu des couleurs et le glow de A : à utiliser pour juger la lumière de B avec des
  sprites inchangés. Le shader des personnages n'est pas modifié.

### 7.5 Coûts de rendu (à mesurer sur la machine du créateur)

* Commandes : § 4 (`profil_gpu_p77.gd`, A puis `--lumiere=b`, puis `--b_jusqua=3` et `--b_ombres=0` pour isoler les
  ombres).
* **Indice indépendant de la machine** (Forward+, 10 points du profil) : B dessine environ **+50 % d'appels**
  (placette 1 925 -> 2 764 ; grande place 1 162 -> 1 778) et environ +55 % de primitives. Ces surcoûts viennent surtout des
  4 tranches d'ombre, qui redessinent les objets dans chaque tranche. Le SSAO, le MSAA et la profondeur de champ ne
  pèsent, eux, que sur le GPU.
* Temps GPU dans le conteneur (Vulkan logiciel sur processeur) : A ≈ 160 ms, B ≈ 410 ms par image. **Non significatif**
  pour une vraie carte graphique, mais cohérent avec un coût sensible de SSAO + MSAA ×4.
* Si le budget est serré : `--b_ombres_m=130`, `--b_aa=msaa2`, `--b_ssao=0` (à comparer au rendu).

### 7.6 Ce qui reste à juger par le créateur

* Le dosage 2 contre le dosage 1 (`--b_version=1`), étape par étape (`--b_jusqua=1..5`).
* La profondeur de champ et le MSAA en mouvement : non jugés ici (images fixes seulement).
* **La direction lumineuse n'est pas validée.** A reste le profil par défaut.
