# Historique des étapes (documents et médias retirés du projet actif en P4.4)

Le nettoyage P4.4 (puis P4.5 et P4.6) a retiré du dossier de travail (`git rm`, sans réécrire l'historique) les comptes rendus, captures
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

Exemple : `git show p4-1-finitions:docs/P4_1_FINITIONS.md`, ou `git checkout p4-1-finitions -- docs/media/p4_1`.
Les planches sources (concepts, packs) sont sur le Drive du projet (`Art/`, `Art/Assets/`).
