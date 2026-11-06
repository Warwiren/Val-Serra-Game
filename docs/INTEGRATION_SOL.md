# Intégration du sol illustré de l'exploration

Branche **`sol-illustre`** (depuis `exploration-illustree`). Le pipeline est prêt ; **aucun sol illustré n'est
intégré** : le jeu affiche toujours le fond actuel tant qu'aucune plaque n'a été importée.

## 1. Où déposer les fichiers
Dans **`art/source/sol/`** (dossier ignoré par Godot : les sources restent intactes, hors du jeu exporté) :

| Fichier | Obligatoire | Contenu |
|---|---|---|
| `sol_plaque.png` | **oui** | terrain illustré, **opaque**, **1408 × 800** (ou 2816 × 1600, réduit une seule fois) |
| `sol_ombres.png` | non | ombres des objets, RGBA transparent, même cadre. **Absent : les ombres actuelles sont conservées** |
| `sol_lumieres.png` | non | lumière des lanternes et fenêtres sur fond noir (ajoutée), même cadre. **Absent : lumière actuelle conservée** |

Puis, depuis la racine du projet :
```
python3 tools/explore/import_sol.py --verifier     # contrôle seulement (taille, opacité, recalage)
python3 tools/explore/import_sol.py                # importe
```
Lancer le jeu (**F5**). Comparaison : `godot --path . -- (comparaison retirée)`. Retour au fond actuel :
`python3 tools/explore/import_sol.py --retirer`.

Options : `--sans-ombres`, `--sans-lumieres` si la plaque contient déjà les ombres ou la lumière des lanternes
(sinon elles seraient doublées) ; `--calques-separes` pour garder trois calques dans le jeu pendant des réglages.

## 2. Ce que fait l'importeur (`tools/explore/import_sol.py`)
- **Refuse** une taille autre que 1408 × 800 / 2816 × 1600, ou une plaque non opaque (rien n'est écrit).
- **Vérifie le recalage** : compare les contours de la plaque à ceux du gabarit et indique le décalage détecté
  (alerte au-delà de 4 px : chemin et collisions ne coïncideraient plus).
- **Conserve les ombres et la lumière actuelles** si elles ne sont pas fournies : elles sont recalculées depuis la
  scène Blender du jeu (`art/source/gabarits/` : rendu avec et sans ombres d'objets, avec et sans lanternes).
- **Fusionne** plaque + ombres + lumière en une seule texture `art/explore_hd2d/illustre/sol/sol.png` (une image plein
  écran à dessiner au lieu de trois). Les sources restent séparées : retoucher un calque = relancer l'import.
- Écrit `sol.json` (origine de chaque calque, empreinte de la source, recalage mesuré).
- Le jeu affiche le sol **1:1 à l'écran** (échelle 0,5 du monde, filtrage linéaire) : pas de pixellisation.
- **Ne touche à aucune donnée de jeu** : praticable, collisions, tri et positions viennent toujours de `zone.json`.

## 3. Gabarits utilisés (validés)
`docs/media/gabarits_exploration/` (voir `docs/GABARITS_EXPLORATION.md`) :
- **`terrain/terrain_gabarit_1408x800.png`** : base de la plaque (sol, chemin, lisière, sans objet ni ombre) ;
- `terrain/reperes_terrain.png` et `terrain/grille_sol_1m.png` : praticable, collisions, emplacements, perspective ;
- `terrain/ombres_des_objets_calque.png` : modèle de `sol_ombres.png` ;
- `terrain/profondeur_terrain_1408x800.png` : pour une génération guidée.
Rappel : la plaque ne doit contenir **ni ombres d'objets ni flaques de lumière des lanternes** si l'on garde les
calques actuels (sinon utiliser `--sans-ombres` / `--sans-lumieres`).

## 4. Vérification de la clôture gauche (signalée dans l'aperçu)
**Défaut réel**, introduit au lot précédent. La clôture gauche passe **derrière** un arbre de bord de clairière
qui est peint dans le fond (pas un objet trié). L'ancienne clôture avait été découpée là où cet arbre la cachait ;
la clôture illustrée, elle, était dessinée entière, donc par-dessus le feuillage.

**Correction** (`tools/explore/masque_decor.py`) : pour chaque accessoire illustré, on compare pixel par pixel la
profondeur du décor du fond (rendu de la scène) à celle de l'accessoire ; là où le fond est plus proche de la
caméra, l'accessoire est masqué. Résultat : la clôture gauche est masquée sur 36 % de ses pixels (la partie
derrière l'arbre) ; aucun autre accessoire n'est concerné (une touffe d'herbe : 5 pixels). Les textures communes
ne sont pas modifiées (variantes dans `art/explore_hd2d/hd/occ/`). Terrain, collisions et tri inchangés.
Captures : `docs/media/sol/cloture_avant_apres_en_jeu.png`, `cloture_avant_apres_apercu.png`.

## 5. Tests du pipeline
- `python3 tools/explore/test_import_sol.py` (dossier temporaire, n'écrit rien dans le dépôt) : taille refusée,
  plaque transparente refusée, ×2 réduite une fois, recalage détecté à (0, 0), décalage de 24 px signalé, ombres et
  lumière actuelles conservées puis remplacées si fournies, `--sans-lumieres`, `--calques-separes`, retrait.
- Godot : `test_ground_layers_fall_back_and_stack` (fond actuel sans import, une texture après fusion, trois
  calques séparés, `(comparaison retirée)`).
- **Essai complet** dans une copie temporaire du projet, avec le **gabarit lui-même comme plaque de test** (ce
  n'est pas un sol illustré, rien n'a été versionné) : import recalé à (0, 0) ; 65 tests sur 65 ; parcours clavier
  RÉUSSI ; approches du garde 11/11 ; retour de combat RÉUSSI ; démo complète (dialogue, combat, retour) ;
  performances en exploration 64,0 images/s contre 63,2 sans sol importé (rendu logiciel), +2,9 Mo de mémoire de
  textures, chargement +20 ms.

## 6. Contrôle de l'esquisse v0 (reçue le 6 novembre)
Source conservée : `art/source/sol/esquisse_sol_v0_1663x945.webp`. **Non intégrée** au jeu.

| Critère | Résultat |
|---|---|
| Taille | 1663 × 945 : bon rapport (1,76) mais pas le gabarit ; ramenée à 1408 × 800 pour l'essai. Livrer en 1408 × 800 ou 2816 × 1600, **PNG** (le WebP compressé ajoute des artefacts) |
| Contenu | terrain seul, sans maison, arbre trié, accessoire ni personnage : **conforme** |
| Perspective | cohérente avec la caméra (pas d'isométrie en losanges) : **conforme** |
| **Tracé du chemin** | **décalé d'environ 1,3 à 1,5 m vers le fond** (≈ 40 à 50 px à l'écran) sur toute sa longueur, et **plus large** (3 à 4 m au lieu de 2,6 m bordure comprise) ; le coude et l'extrémité droite sont à peu près à leur place. L'importeur le détecte (décalage estimé (8, 24) px, faible corrélation avec le gabarit) |
| Bord bas | le talus et l'eau en bas à droite ne suivent pas la ligne du muret (élément du jeu), qui flotte alors sur l'herbe |
| Rochers | un gros rocher moussu à droite chevauche la limite praticable (on le traverserait) ; quelques pierres moyennes dans le praticable |
| Lumière | lumière chaude peinte sur le chemin à des endroits qui ne correspondent pas aux trois lanternes ; à retirer de la plaque (ou à placer sur les repères) |
| Ombres d'objets | absentes de la plaque : **conforme** (les ombres actuelles sont ajoutées par l'importeur) |
| Netteté | bonne à la taille réelle (1:1, aucune pixellisation) |
| Performances (essai) | 62,8 images/s en exploration contre 63,2 avec le sol actuel (rendu logiciel) ; +2,9 Mo de mémoire de textures |
| Mécaniques (essai) | parcours clavier RÉUSSI, approches du garde 11/11 : la plaque ne change rien au jeu |

Pour corriger : poser **`docs/media/gabarits_exploration/terrain/chemin_trace_exact.png`** (pavés et bordure de
terre exacts) au-dessus de l'illustration, avec `reperes_terrain.png` (praticable, lanternes). Comparatifs :
`docs/media/sol/esquisse_v0_contre_gabarit.jpg`, `esquisse_v0_essai_en_jeu_1280.jpg`, `esquisse_v0_nettete_x3.png`.

## 7. Bascule et vérifications à l'intégration définitive
- **F4** en jeu : sol illustré / fond actuel (sans recharger) ; `(comparaison retirée)` au lancement.
- Ombres et lumières : un seul exemplaire (calques séparés des sources, fusionnés à l'import ; `--sans-ombres` /
  `--sans-lumieres` si elles sont déjà peintes).
- Collisions, praticable, points d'interaction : inchangés (`zone.json`) ; contrôlés par le parcours clavier,
  les approches du garde et le retour de combat.
- Comparatif avant/après à 1280 × 720, gros plan de netteté, mesure de performances.

## 8. Cahier de production
Le document `CAHIER_PRODUCTION_SOL_HD2D_v1.md` annoncé n'a pas été reçu (ni dans la conversation, ni dans le
Drive). Le pipeline suit le message de validation et `docs/GABARITS_EXPLORATION.md` ; il sera ajusté au cahier
dès sa réception si nécessaire.
