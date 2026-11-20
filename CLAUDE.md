# Consignes du projet Val'Serra

- **Moteur : Godot 4.7.2, strictement.** Toute scène, tout script et tout test se valident sous cette version.
  Ne pas modifier `config/features` dans `project.godot` sans décision explicite.
- **F5 lance la forêt V07B** (`run/main_scene = res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn`,
  caméra P30 à trois inclinaisons, occlusion, navigation libre V08A) : **décision du créateur du 15 novembre 2026**,
  consignée dans `docs/P4_9_V07B.md` (§ V08A). La démo de l'avant-poste (`scenes/p4/avant_poste.tscn`, F5 jusqu'en
  P4.8) reste jouable en F6 et garde ses tests (rencontre de bout en bout, parcours `p4` et `p4_sondes`).
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
  Ilya : cheveux courts argentés, yeux verts, **pistolet d'Aether** (jamais d'épée ni d'arc). **Identité V09C validée
  par le créateur le 19/11/2026** (`docs/P4_9_V09C.md`) : visage et silhouette féminins, athlétique ; tenue d'éclaireuse
  bleu nuit, cuir brun, pièces métalliques ; cape vert forêt à motifs dorés ; pas de grande queue-de-cheval. Les sprites
  et portraits d'Ilya en jeu sont encore l'ancienne apparence (tenue verte) jusqu'à intégration et validation du pack.
  Garde : armure sombre, bouclier, masse ; PNJ sans combat (courte ronde dans la cour).
- **Animations** : attente animée (8 images, pieds immobiles) et marche dans les 4 directions, cadence liée à la
  distance (P4.8 : 8 images pour Aren et Ilya, cadence calée sur le pas dessiné, marche 2,2 m/s, course Maj 3,6 m/s ;
  4 images pour le garde). **Aren, référence artistique du prototype (19/11/2026)** : V09B.5 96 × 112 affiché à ×0,719
  (≈ 64 px, touches B / T de la forêt), défauts connus acceptés, ne pas redessiner ni retoucher ; P4.8 conservé en
  secours ; vitesses d'essai 2,8 / 4,5 m/s (non imposées). **Démarrage de F5 pour la validation (décision du
  créateur du 19/11/2026, `docs/P4_9_V09C.md` § 9)** : Aren V09B.5 ×0,719, Ilya V09C.6 (banc d'essai), vitesses
  2,2 / 3,6 m/s, inclinaison 24°, zoom ×3 ; autres versions aux touches B / T / I / P / 1-6 ; les outils de
  non-régression gardent leur état de référence (P4.8, 30°, ×2,5) via `demarrage_v09c6 = false`. **Profil unique (19/11/2026,
  § 10)** : en V09B.5 / V09C, le profil droit sert à toutes les directions (miroir vers la gauche, dernier profil
  gardé vers le haut ou le bas, pose de marche tenue à l'arrêt) ; aucune pose générée. **Aren V2 (20/11/2026, § 11)** : vers
  le bas marche de face, vers le haut marche de dos, arrêt après le bas attente de face (`art/tests/aren_v2/`) ; Ilya :
  profil gardé tant qu'une planche face / dos dans son style n'est pas fournie. **Aren 4 directions (20/11/2026, § 12)** :
  attentes profil / face / dos de l'étude IDLE V1 et marches / courses de face et de dos **procédurales** dérivées de
  ces attentes (`art/tests/aren_4dir/`, prioritaires sur V2) ; même foulée, donc même cadence, dans toutes les directions.
  **Proposition V3 (20/11/2026, § 13)**, au démarrage de F5 après le refus des marches face / dos 4dir : pas en
  profondeur (pied avancé plus bas de face, plus haut de dos), bras en opposition, toujours **procédurale**
  (`art/tests/aren_4dir_v3/`) ; attentes et profil inchangés. **V4 (20/11/2026, § 14)**, au démarrage de F5 après
  le refus de V3 : marches de face et de dos **dessinées** (GIF du créateur), réduites à l'échelle du profil et ramenées
  à sa palette sans redessin (`art/tests/aren_4dir_v4/`, touche G : V4 / V3 / 4dir / V2) ; pas de course face / dos
  dessinée (marche, foulée ×1,25) ; arrêt haut / bas : pose dessinée tenue. Une animation dérivée par décalages d'un pixel reste « procédurale » : ne pas la présenter comme
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
