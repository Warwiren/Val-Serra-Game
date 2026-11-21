# Historique des étapes (documents et médias retirés du projet actif en P4.4)

Le nettoyage P4.4 (puis P4.5 à P4.9) a retiré du dossier de travail (`git rm`, sans réécrire l'historique) les comptes rendus, captures
et vidéos des étapes précédentes. Ils restent intacts dans Git, sur les branches de chaque étape :

| Étape | Branche | Documents (dans `docs/` de la branche) |
|---|---|---|
| Lots A / B, recentrage, prototype artistique | `main`, `sauvegarde-avant-purge` | `LOT_A.md`, `LOT_B.md`, `RECENTRAGE.md`, `PROTO_ARTISTIQUE.md`, `PLAN_MVP.md`, `CORRECTIFS_HUD.md` |
| P1 caméra / exploration HD-2D | `p1-camera-hd2d`, `exploration-v2` | `P1_CAMERA.md`, `P1_SUITE.md`, `EXPLORATION_HD2D.md`, `EXPLORATION_V2.md`, `DECOR_EXPLORATION.md` |
| P2 environnements | `p2-environnements` | `P2_LOT_A_GABARITS.md`, `P2_LOT_A_INTEGRATION.md`, `GABARITS_EXPLORATION.md`, `INTEGRATION_SOL.md` |
| P3 prototype 2.5D, caméra | `p3-prototype-25d`, `p3-camera-profondeur`, `p3-validation-camera` | `P3_PROTOTYPE_25D.md`, `P3_CAMERA_PROFONDEUR.md`, `P3_VALIDATION_CAMERA.md`, `PROTOCOLE_VALIDATION_CAMERA_GPU.md` |
| P4 avant-poste | `p4-avant-poste` | `P4_AVANT_POSTE.md` (+ `docs/media/p4/`) |
| P4.1 finitions | `p4-1-finitions` | `P4_1_FINITIONS.md` (+ `docs/media/p4_1/`) |
| P4.4 personnages, nettoyage | `p4-4-personnages` | `P4_4_PERSONNAGES.md` (+ `docs/media/p4_4/`) ; sprites `art/p44/` |
| P4.5 garde, animations | `p4-5-animations` | `P4_5_ANIMATIONS.md` (+ `docs/media/p4_5/` : vidéos de marche, ronde du garde, combat, parcours complet) |
| P4.6 taille à l'arrêt, Ilya de face (montage) | `p4-6-corrections` | `P4_6_CORRECTIONS.md` (+ `docs/media/p4_6/`) |
| P4.7 taille d'Aren, combat d'Ilya (planche), Vorgane au sol | `p4-7-corrections` | `P4_7_CORRECTIONS.md` (+ `docs/media/p4_7/`) |
| P4.8 marche d'Aren et d'Ilya (8 images, course) | `p4-8-marche` | `P4_8_MARCHE.md` (+ `docs/media/p4_8/`) |

| P4.9 forêt V07B, V08A, V09A–V09C, V11 | `p4-9-v07-test` et suivantes | `P4_9_V07B.md`, `P4_9_V09C.md`, `P4_9_V11.md` (présents) ; médias `docs/media/p4_9/` retirés en P6 |
| P5 combat, P5.2, P5.3, P5.3-B (pilote, V2, V2 transitions) | `p5-combat`, `p5-2-environnement`, `p5-3-sols`, `p5-3b-*` | rapports présents ; médias `docs/media/p5*/` retirés en P6 (sauf `p5_3b_v3h`, référence actuelle) |

Nettoyage P6 (21/11/2026) : voir `docs/P6_INVENTAIRE.md`. Pour récupérer les médias retirés :
`git checkout origin/p5-3b-v3-hybride -- docs/media/p4_9` (même chose pour `p5`, `p5_2`, `p5_3`, `p5_3b`, `p5_3b_v2`, `p5_3b_v2t`).

Exemple : `git show p4-1-finitions:docs/P4_1_FINITIONS.md`, ou `git checkout p4-1-finitions -- docs/media/p4_1`.
Les planches sources (concepts, packs) sont sur le Drive du projet (`Art/`, `Art/Assets/`).
