# Consignes du projet Val'Serra

- **Moteur : Godot 4.7.2, strictement.** Toute scène, tout script et tout test se valident sous cette version.
  Ne pas modifier `config/features` dans `project.godot` sans décision explicite.
- **F5 lance l'avant-poste P4** (`run/main_scene = res://scenes/p4/avant_poste.tscn`), promu par le brief P4 du
  12 novembre 2026 après vérifications (voir `docs/P4_AVANT_POSTE.md`).
  **Ne pas modifier `run/main_scene` sans l'accord explicite du créateur.** Une nouvelle branche ou une nouvelle
  étape ne suffit pas à « promouvoir » une scène sur F5 : la promotion est une décision du créateur, datée et
  consignée dans le compte rendu de l'étape. Si une étape casse la scène F5, revenir à l'état stable précédent et
  le signaler.
- **Organisation** : la zone P4 est décrite par des données (`data/p4/*.json`, mètres, niveaux, collisions) lues
  par le socle `src/explore25/` ; l'habillage est dans `scenes/p4/avant_poste.gd`, les shaders dans `src/p4/`, les
  ressources dans `art/p4/` et `art/p41/` (provenance et statut dans leurs `SOURCES.md`). Ajouter une zone = un fichier de
  données + ses ressources, pas un nouveau moteur. Les prototypes P3 (`scenes/explore25/`) et l'ancienne
  exploration (`scenes/explore_hd2d/`) sont conservés tels quels.
- **Caméra d'exploration** : Camera3D orthographique, plongée 28°, azimut 20° (variante B de P3-07, « B28 »),
  rotation fixe, zooms ×2 / ×2,5 / ×3 (×2,5 par défaut). Ne pas confondre avec « l'architecture B » des rapports P3.
  Les variantes en perspective P30 / P38 (P4.1) sont des **comparaisons** : ne pas en faire le défaut sans
  validation visuelle du créateur.
- **Personnages** : sprites à la résolution des planches (`art/p41/`), réduits à l'écran avec le shader « pixel
  net » ; ne jamais agrandir une image réduite avec un filtre bilinéaire. Une même apparence en exploration, en
  combat et en portrait.
- **Ressources graphiques** : une planche conceptuelle n'est pas un asset. Ne rien déclarer « final » sans revue
  du créateur ; signaler tout élément provisoire dans `art/p4/SOURCES.md` et dans le rapport de l'étape.
  Ilya : cheveux courts argentés, yeux verts, tenue bleu nuit et cuir — jamais un personnage ressemblant à Aren.
- **Les scènes expérimentales** (prototypes P3, variantes de caméra, ancienne exploration, diagnostics…) restent ouvrables dans
  l'éditeur avec **F6**, sans argument de ligne de commande. Les lister dans le tableau « Autres scènes » du README.
- À chaque nouvelle branche ou étape, mettre à jour la section « Lancer le jeu » du `README.md` : nom de la branche
  et du dossier ZIP `Val-Serra-Game-<branche>`, ce que montre F5, quelles scènes ouvrir avec F6.
  Vérifier ensuite avec `godot --headless --path . --quit-after 60` que la scène principale se charge sans erreur.
- Ne pas toucher au combat dans le cadre d'un travail sur l'exploration, sauf demande explicite.
- Après toute modification : `godot --headless --path . --script res://tests/run_tests.gd`,
  `--script res://tests/e2e_p4_retour.gd`, puis les parcours `--route=p4` et `--route=p4_sondes` (voir README).
- Ne pas supprimer ni réécrire les branches existantes ; travailler sur une branche dédiée par étape.
