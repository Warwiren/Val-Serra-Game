# Consignes du projet Val'Serra

- **Moteur : Godot 4.7.2, strictement.** Toute scène, tout script et tout test se valident sous cette version.
  Ne pas modifier `config/features` dans `project.godot` sans décision explicite.
- **F5 lance l'exploration stable** (`run/main_scene = res://scenes/explore_hd2d/zone_exploration.tscn`).
  **Ne pas modifier `run/main_scene` sans l'accord explicite du créateur.** Une nouvelle branche ou une nouvelle
  étape ne suffit pas à « promouvoir » une scène sur F5 : la promotion est une décision du créateur, datée et
  consignée dans le compte rendu de l'étape.
  (Cette règle remplace l'ancienne consigne « F5 doit toujours lancer la dernière version », qui contredisait les
  briefs P3, P3-07 et suivants.)
- **Les scènes expérimentales** (prototypes P3, variantes de caméra, pilote artistique P4…) restent ouvrables dans
  l'éditeur avec **F6**, sans argument de ligne de commande. Les lister dans le tableau « Autres scènes » du README.
- À chaque nouvelle branche ou étape, mettre à jour la section « Lancer le jeu » du `README.md` : nom de la branche
  et du dossier ZIP `Val-Serra-Game-<branche>`, ce que montre F5, quelles scènes ouvrir avec F6.
  Vérifier ensuite avec `godot --headless --path . --quit-after 60` que la scène principale se charge sans erreur.
- Ne pas toucher au combat ni à la carte d'exploration principale dans le cadre d'un travail sur les scènes
  expérimentales, sauf demande explicite.
- Ne pas supprimer ni réécrire les branches existantes ; travailler sur une branche dédiée par étape.
