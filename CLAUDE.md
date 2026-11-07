# Consignes du projet Val'Serra

- **F5 doit toujours lancer la dernière version voulue.** À chaque nouvelle branche ou étape, mettre à jour
  `run/main_scene` dans `project.godot` vers la scène la plus récente, ainsi que la section « Lancer le jeu » du
  `README.md` (nom de la branche et du dossier ZIP `Val-Serra-Game-<branche>`, ce que montre F5).
  Vérifier ensuite avec `godot --headless --path . --quit-after 60` que la scène principale se charge sans erreur.
- Ne pas supprimer ni réécrire les branches existantes ; travailler sur une branche dédiée par étape.
