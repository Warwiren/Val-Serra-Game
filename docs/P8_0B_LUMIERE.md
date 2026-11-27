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
| 1 Soleil | Même direction (composition des ombres conservée), lumière plus chaude (1,0 / 0,86 / 0,68) et plus forte (1,35 au lieu de 1,1). Ombres en 4 tranches jusqu'à 160 m, biais normal 1,4. | `--b_soleil=0`, `--b_ombres=0`, `--b_ombres_m=<m>` |
| 2 Ambiance | Lumière indirecte tirée du ciel (contribution 0,55, énergie 0,62 au lieu de 0,85) : ombres plus froides et plus profondes. SSAO rayon 1,2, intensité 1,8, avec un léger effet au soleil pour les ombres de contact. | `--b_ambiance=0`, `--b_ssao=0` |
| 3 Couleurs | Rendu Filmic, exposition 1,15, blanc 3,0, contraste 1,06, saturation 1,08. | `--b_tonemap=filmic\|agx\|aces\|lineaire`, `--b_exposition=`, `--b_blanc=` |
| 4 Lumières | Une OmniLight chaude, sans ombre, portée 5 m, devant chacune des 5 entrées fonctionnelles (Guilde, auberge, forge, boutique, hôtel de ville). | `--b_lumieres=0` |
| 5 Post-production | Profondeur de champ réelle (flou lointain dès 90 m, transition 120 m, intensité 0,05) à la place du flou d'écran vertical. Bloom coupé, sur option seulement. MSAA 3D ×4 et débandage. | `--b_flou=dof\|ecran\|aucun`, `--b_dof_m=`, `--b_dof_flou=`, `--b_glow=1`, `--b_aa=msaa4\|msaa2\|0` |

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
  * Leurs couleurs validées peuvent donc légèrement changer en B. Comparer avec `--b_tonemap=lineaire`, qui les laisse
    identiques.
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

## 5. Tests

**NON EXÉCUTÉS** : Godot 4.7.2 n'est pas disponible dans ce conteneur.

* **Vérification faite** : syntaxe de tous les scripts modifiés ou ajoutés avec `gdparse` (gdtoolkit 4.5), sans
  erreur. Cette analyse ne vérifie ni les types ni l'exécution.
* **À lancer avant tout examen** :
  * `godot --headless --path . --quit-after 60` ;
  * `tests/run_tests.gd`, `e2e_p6_ouverture.gd -- --tuto-rapide`, `e2e_p6_saut_tutoriel.gd`, parcours `p6_sondes` ;
  * `tools/p7/stabilite_interactions_p7121.gd -- --route=p7_7121_interactions --quit [--lumiere=b]` (0 px attendu) ;
  * `tools/p7/escamotage_p7122.gd` (les coupes de 3,1 m et 1,2 m changent les bascules haut / tout de ces volumes).

## 6. Réserves à vérifier en Forward+

* **Sans effet en Compatibilité**, donc jamais vu dans ce conteneur : SSAO, profondeur de champ. Glow et MSAA y
  diffèrent.
* **Réglages proposés**, à juger et ajuster : exposition et blanc du rendu Filmic, contraste, saturation, énergie
  d'ambiance.
* **Constantes moteur** : `Environment.TONE_MAPPER_AGX` et `RenderingServer.get_current_rendering_method()` sont
  supposées présentes en 4.7.2, à confirmer au premier chargement.
* **Rendu de B** : aucune image n'a été vue. Tout est à juger en jeu, d'abord étape par étape avec `--b_jusqua=1` à 5,
  puis effet par effet.
