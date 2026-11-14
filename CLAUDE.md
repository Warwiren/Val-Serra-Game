# Consignes du projet Val'Serra

- **Moteur : Godot 4.7.2, strictement.** Toute scène, tout script et tout test se valident sous cette version.
  Ne pas modifier `config/features` dans `project.godot` sans décision explicite.
- **F5 lance la démo de l'avant-poste** (`run/main_scene = res://scenes/p4/avant_poste.tscn`, caméra P30), configurée
  par les briefs P4.4 et P4.5 du 13 novembre 2026 après vérifications ; corrections P4.6 à P4.8 dans la même scène
  (voir `docs/P4_8_MARCHE.md`, rapports précédents dans `docs/HISTORIQUE.md`).
  **Ne pas modifier `run/main_scene` sans l'accord explicite du créateur.** Une nouvelle branche ou une nouvelle
  étape ne suffit pas à « promouvoir » une scène sur F5 : la promotion est une décision du créateur, datée et
  consignée dans le compte rendu de l'étape. Si une étape casse la scène F5, revenir à l'état stable précédent et
  le signaler.
- **Organisation** : la zone P4 est décrite par des données (`data/p4/*.json`, mètres, niveaux, collisions) lues
  par le socle `src/explore25/` ; l'habillage est dans `scenes/p4/avant_poste.gd`, les shaders dans `src/p4/`, les
  ressources dans `art/p4/`, `art/p41/` et `art/p45/` (provenance et statut dans leurs `SOURCES.md`). Ajouter une
  zone = un fichier de données + ses ressources, pas un nouveau moteur. Les anciennes scènes (P1–P3, ancienne
  exploration) ont été retirées en P4.4 : elles restent dans l'historique Git (`docs/HISTORIQUE.md`).
- **Projet actif léger** : ne garder dans le dépôt que ce qui sert à l'exécution, aux tests et au développement
  courant. Planches sources, ZIP, GIF et anciennes variantes restent sur le Drive ; médias de rapport limités à
  l'étape en cours. Ne jamais réécrire l'historique Git sans accord explicite.
- **Caméra d'exploration** : P30 par défaut depuis P4.4 (Camera3D perspective, plongée 30°, champ 30°, azimut 20°,
  flou de distance léger en haut de l'écran seulement), rotation fixe, zooms ×2 / ×2,5 / ×3 (×2,5 par défaut).
  B28 (orthographique 28°) reste en comparaison (touche C, scène F6 `comparaison_camera_B28.tscn`).
- **Personnages** : sprites réduits depuis les sources (`art/p45/`, outil `tools/p45/build_p45.py`), 1 pixel de
  sprite = 1 pixel d'écran à ×2,5 en exploration (shader « pixel net »), ×2 (entier, au plus proche) en combat ; ne jamais agrandir une image réduite avec un filtre
  bilinéaire. Une même apparence en exploration, en combat et en portrait. Aren : cheveux bruns, tenue grise/noire.
  Ilya : cheveux courts argentés, yeux verts, tenue verte et cuir, **pistolet d'Aether** (jamais d'épée ni d'arc).
  Garde : armure sombre, bouclier, masse ; PNJ sans combat (courte ronde dans la cour).
- **Animations** : attente animée (8 images, pieds immobiles) et marche dans les 4 directions, cadence liée à la
  distance (P4.8 : 8 images pour Aren et Ilya, cadence calée sur le pas dessiné, marche 2,2 m/s, course Maj 3,6 m/s ;
  4 images pour le garde). Une animation dérivée par décalages d'un pixel reste « procédurale » : ne pas la présenter comme
  dessinée. Toute animation se vérifie en mouvement (vidéo), pas sur une capture fixe.
- **Ressources graphiques** : une planche conceptuelle n'est pas un asset. Ne rien déclarer « final » sans revue
  du créateur ; signaler tout élément provisoire dans `art/p4/SOURCES.md` et dans le rapport de l'étape.
  Ilya ne doit jamais ressembler à Aren.
- **Les scènes de comparaison** (variantes de caméra, diagnostics) s'ouvrent dans l'éditeur avec **F6**, sans
  argument de ligne de commande, et sont listées dans le tableau « Autres scènes » du README. Jamais en F5.
- À chaque nouvelle branche ou étape, mettre à jour la section « Lancer le jeu » du `README.md` : nom de la branche
  et du dossier ZIP `Val-Serra-Game-<branche>`, ce que montre F5, quelles scènes ouvrir avec F6.
  Vérifier ensuite avec `godot --headless --path . --quit-after 60` que la scène principale se charge sans erreur.
- Ne pas toucher au combat dans le cadre d'un travail sur l'exploration, sauf demande explicite.
- Après toute modification : `godot --headless --path . --script res://tests/run_tests.gd`,
  `--script res://tests/e2e_p4_retour.gd`, puis les parcours `--route=p4` et `--route=p4_sondes` (voir README).
- Ne pas supprimer ni réécrire les branches existantes ; travailler sur une branche dédiée par étape.
