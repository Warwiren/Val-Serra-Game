# P4.7 — Corrections : taille d'Aren, Ilya (exploration et combat), Vorgane posé au sol (Godot 4.7.2)

Branche **`p4-7-corrections`**, partie de `p4-6-corrections` (laissée intacte). Date : 14 novembre 2026.
Sources nouvelles : les **planches de 8 poses fournies par le créateur** dans la demande (Ilya trois-quarts au
pistolet d'Aether, Aren, Vorgane) et la planche de présentation « Pack P4.7 ». Aucun pack P4.7 n'existe sur le Drive
(vérifié) : les planches sont copiées dans le dossier local des sources (`p47/`) et sont **à déposer sur le Drive**.
**F5** lance toujours `scenes/p4/avant_poste.tscn` (même scène, vérifié par test et au chargement).

## Vidéos et comparaisons

| Fichier | Ce qu'il montre |
|---|---|
| [`videos/aren_ilya_marche_attente_x3.mp4`](media/p4_7/videos/aren_ilya_marche_attente_x3.mp4) | Aren et Ilya à ×3 : attente, marche et arrêt dans les 4 directions (tailles comparables, cape d'Ilya) |
| [`videos/combat_ilya_planche_p47.mp4`](media/p4_7/videos/combat_ilya_planche_p47.mp4) | vue de combat réelle : attente, dégainer, tir, tir chargé, garde, touchée, K.O. d'Ilya ; actions d'Aren |
| [`videos/vorgane_plaine.mp4`](media/p4_7/videos/vorgane_plaine.mp4) | le Vorgane dans la plaine aux 3 zooms, puis le héros tourne autour |
| [`comparaisons/taille_aren_ilya.png`](media/p4_7/comparaisons/taille_aren_ilya.png) | Aren et Ilya à l'arrêt, P4.6 puis P4.7 |
| [`comparaisons/ilya_combat_p46_p47.png`](media/p4_7/comparaisons/ilya_combat_p46_p47.png) | Ilya en combat : montage P4.6, planche P4.7 |
| [`comparaisons/vorgane_p46_p47.png`](media/p4_7/comparaisons/vorgane_p46_p47.png) | Vorgane d'exploration avant / après |
| [`combat.jpg`](media/p4_7/combat.jpg), [`captures/`](media/p4_7/captures/) | écran de combat ; cour et plaine (×2,5) |

## 1. Aren plus gros qu'Ilya

À 70 px, la silhouette d'Aren dépassait celle d'Ilya de **28 %** (tête 25 px contre 23, épaules plus larges, cheveux
volumineux) ; P4.6 avait en plus gardé l'échelle des pas, la plus grande. Aren passe à **63 px** (facteur
`25.2 / 63.0`, toujours 1 px de sprite = 1 px d'écran à ×2,5) : de face, silhouette à +3 % d'Ilya et tête identique
(23 px) ; de profil et de dos, +13 à +16 % (armure et cape plus larges, tête 22–24 px contre 20–21) ; Aren n'est
plus jamais plus grand qu'Ilya. Taille constante entre l'arrêt et la marche (test P4.6 conservé). Combat : tailles
déjà comparables (Aren 56 px, Ilya 55 px).

## 2. Ilya en exploration

- **Attente** : en plus de la respiration, le **bas de la cape ondule** (le bord avance d'un côté, recule de l'autre,
  aller et retour) et la mèche bouge ; 8 images distinctes par direction.
- **Marche** : **appui** à chaque pas (le haut du corps s'abaisse d'1 px aux deux images où les pieds sont le plus
  écartés) : la marche pèse au lieu de glisser. Tête toujours stable, pieds sur la même ligne.
- Limite : les 4 images de marche restent celles du pack P4.3 (cape très soulevée, allure de course). Sans nouvelles
  images dessinées, on ne peut pas aller plus loin sans déformer le dessin.

## 3. Ilya en combat

Construite depuis **la planche fournie** (8 poses dessinées : attente A, attente B, préparation, visée, tir, tir
chargé, touchée, à terre), retournée pour regarder à droite **comme Aren** (le jeu retourne ensuite tout le groupe
face au monstre). Pistolet d'Aether conservé (lumière cyan, trait d'Aether qui part du bout du pistolet).

| Animation | Images |
|---|---|
| attente (8) | deux poses **dessinées** qui alternent (la cape bouge) + respiration + bas de cape |
| dégainer (5) | attente → préparation → visée |
| tir (7) | visée → tir (éclair dessiné) → recul (bras et arme reculent de 2 px puis 1, dérivé) → visée |
| tir chargé (8) | préparation → visée → lueur d'Aether qui grossit au bout du pistolet (tracée par l'outil) → tir chargé (anneau et rayon dessinés) |
| garde (4) | pose de préparation, garde haute, avec respiration |
| touchée (4) | pose touchée dessinée, recul du buste, retour à l'attente |
| K.O. (6) | chancelle (touchée) → genoux qui plient (dérivé) → **à terre** (pose dessinée, pistolet tombé), au sol à chaque image |

## 4. Vorgane en exploration

Il semblait flotter : vue de profil strict, ombre de contact faible et cachée. Il vient désormais de **la planche
fournie** : vue **trois-quarts**, il **regarde le héros** qui arrive du pont, pattes au bas de l'image (l'ombre
peinte de la planche, une plaque grise opaque, est retirée) et **ombre de contact large et douce** posée au sol par la
scène. Boucle de 24 images : attente (le dos se soulève en respirant), il baisse la tête pour flairer, se redresse.
Taille : 150 px de long à 1 px = 1 px d'écran (×2,5). Le Vorgane de combat n'est pas modifié.

## 5. Encore provisoire

| Élément | Raison | Pour aller plus loin |
|---|---|---|
| Planches P4.7 (Ilya, Vorgane) | sources fournies dans la demande, pas encore sur le Drive ; non déclarées finales | déposer sur le Drive, revue du créateur |
| Ilya en combat : recul, lueur de charge, genoux qui plient | **dérivés** des poses dessinées | poses intermédiaires dessinées |
| Garde d'Ilya | pas de pose de garde dans la planche : pose de préparation | pose de garde dessinée |
| Marche d'Aren et d'Ilya | pack P4.3 (cape soulevée, mains variables) + appui procédural | cycles dessinés (la planche de présentation en montre, trop petits pour servir) |
| Attentes en exploration | **procédurales** (décalages d'un pixel, cape) | poses d'attente dessinées |
| Vorgane : flairer | la pose dessinée est un peu plus petite que l'attente dans la planche | pose à la même échelle |
| Aren en combat | inchangé (la planche fournie montre un design légèrement différent : armure plus claire) ; pas de K.O. | décider du design de combat d'Aren, puis intégrer sa planche (K.O. compris) |
| Garde, marche `right_2` | 6 px plus basse dans la source | redessiner |

## 6. Tests (Godot 4.7.2)

| Vérification | Résultat |
|---|---|
| Import, chargement de F5 (`--quit-after 60`) ; `run/main_scene` | 0 erreur ; `res://scenes/p4/avant_poste.tscn` |
| Références `res://` manquantes | 0 (hors tests qui vérifient l'absence des anciens dossiers) |
| Tests automatiques | **68/68** (4 nouveaux : `test_p47_corrections.gd`) |
| Rencontre de bout en bout (`tests/e2e_p4_retour.gd`) | **réussie** (475 PV de démo, données à 950) |
| Parcours `p4` — P30 / B28 | **29/29** chacun |
| Sondes `p4_sondes` — P30 / B28 | **20/20** chacun |
| En mouvement | vidéos ci-dessus (rendu OpenGL logiciel) |

Non vérifié : Forward+ sur carte graphique, confort en main par une personne.

## 7. Fichiers

**Modifiés** : `tools/p45/build_p45.py` (Aren 63 px, attente et appui d'Ilya, combat d'Ilya depuis la planche,
Vorgane d'exploration), `art/p45/` (Aren, Ilya, combat d'Ilya), `scenes/p4/avant_poste.gd` (taille d'Aren, Vorgane,
ombre de contact), `src/proto/pack_hunter_view.gd` (bout du pistolet), `src/explore25/routes25.gd` (parcours de
capture `p4_vorgane`), tests, `art/p45/SOURCES.md`, `art/p41/SOURCES.md`, README, CLAUDE.md, `docs/HISTORIQUE.md`.
**Ajoutés** : `art/p45/chars/vorgane/`, `tests/unit/test_p47_corrections.gd`, ce rapport, `docs/media/p4_7/`.
**Retirés** (historique Git) : `art/p41/chars/vorgane/` (ancien Vorgane de profil), rapport et médias P4.6
(branche `p4-6-corrections`).

## 8. Lancer

Branche `p4-7-corrections` → Code → Download ZIP (dossier `Val-Serra-Game-p4-7-corrections`) → importer dans
Godot 4.7.2 → **F5**.
