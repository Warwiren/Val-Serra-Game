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
  le bas marche de face, vers le haut marche de dos, arrêt après le bas attente de face (`art/tests/aren_v2/`). **Aren 4 directions (20/11/2026, § 12)** :
  attentes profil / face / dos de l'étude IDLE V1 et marches / courses de face et de dos **procédurales** dérivées de
  ces attentes (`art/tests/aren_4dir/`, prioritaires sur V2) ; même foulée, donc même cadence, dans toutes les directions.
  **Proposition V3 (20/11/2026, § 13)**, au démarrage de F5 après le refus des marches face / dos 4dir : pas en
  profondeur (pied avancé plus bas de face, plus haut de dos), bras en opposition, toujours **procédurale**
  (`art/tests/aren_4dir_v3/`) ; attentes et profil inchangés. **V4 (20/11/2026, § 14)**, au démarrage de F5 après
  le refus de V3 : marches de face et de dos **dessinées** (GIF du créateur), réduites à l'échelle du profil et ramenées
  à sa palette sans redessin (`art/tests/aren_4dir_v4/`, touche G : V4 / V3 / 4dir / V2) ; pas de course face / dos
  dessinée (marche, foulée ×1,25) ; arrêt haut / bas : pose dessinée tenue. **Rendu des personnages (20/11/2026,
  § 15–16)** : le créateur garde le **rendu Sprite3D d'origine** au démarrage ; le rendu V10
  (`src/explore25/perso_v10.gdshader`) reste en comparaison (touche K). **Ilya haut / bas (20/11/2026, § 16)** : vers le
  bas / le haut, marche, course et attente de face / de dos **dessinées** du pack V09C.5 (`vues_face_dos`) ; droite /
  gauche inchangées (profil, miroir, pose tenue). **État validé par le créateur le 20/11/2026** (animations et rendu
  ci-dessus). **V11 (20/11/2026, `docs/P4_9_V11.md`)** : brouillard coupé au démarrage de F5 (touche F) ; tous les
  rochers et les buissons ≥ 0,85 m bloquent ; Vorgane placé dans la forêt (sans combat). Test : `tests/v11_collisions_smoke.gd`.
  **V11 validé par le créateur le 20/11/2026.** Une animation dérivée par décalages d'un pixel reste « procédurale » : ne pas la présenter comme
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
- **Combat P5 (branche `p5-combat`, demande du créateur du 20/11/2026, `docs/P5_COMBAT.md`)** : groupe à **gauche**
  tourné vers la droite, monstre à **droite** tourné vers la gauche (prototype, toutes arènes) ; décor adapté au lieu :
  arène « forêt » = rendu de la forêt d'exploration V07B (`tools/p5/decor_foret.gd`, `art/p5/combat/`), arène
  « lisière » (avant-poste) inchangée. F6 : `scenes/battle/combat_foret.tscn`. Règles de combat inchangées.
  **Validé provisoirement par le créateur le 20/11/2026** (avec l'état des déplacements).
- **Environnement P5.2 (branche `p5-2-environnement`, `docs/P5_2_ENVIRONNEMENT.md`)** : sol de la forêt par shader
  (`src/explore25/sol_foret.gdshader` / `sol_foret.gd`), la texture V07 sert de carte ; normales calculées sur une
  copie du maillage (collision inchangée) ; horizon fermé (arbres lointains) ; touche U : sol V07 d'origine. Le décor
  de combat forêt est rendu depuis la même forêt (même sol) avec clairière, flou d'arrière-plan et premier plan
  (`art/p5/combat/foret_clairiere*.png`). Test : `tests/p52_sol_smoke.gd`. Ne pas modifier les collisions pour le rendu.
- **Sols P5.3 (branche `p5-3-sols`, `docs/P5_3_SOLS.md`)** : P5.2 retenu comme base technique **provisoire** (non validé
  artistiquement). Shader P5.3 (moins de bruit fin, transitions et usure), P5.2 figé dans `sol_foret_p52.gdshader`
  (touche U). Ombre du terrain rétablie ; filtre des ombres douces en qualité 4 **à l'essai** (touche J : 2), à ne pas
  considérer validé avant le test GPU du créateur. Les « hachures » autour des obstacles viennent de la trame de
  l'occlusion (validée, non modifiée). Étape B : textures peintes RGBA (A = hauteur), 1024² = 4 × 4 m, pilote
  herbe drue / herbe usée / terre de chemin dans `art/p53/sol/` ; ne pas inventer de textures de remplacement.
  **P5.3 validé par le créateur le 21/11/2026 (fin de l'étape A) : ne plus retoucher `sol_foret.gdshader`.**
- **Pilote P5.3-B (branche `p5-3b-pilote-sols`, `docs/P5_3B_PILOTE.md`)** : textures du créateur (SOL-01/02/03 → herbe_drue,
  herbe_usee, terre_chemin ; hauteurs PROVISOIRES), format seulement adapté (RGBA), couleurs non retouchées ; shader
  `sol_foret_p53b.gdshader` (copie de P5.3 + mélange par hauteur) limité à une zone pilote (touche Y : carte entière) ;
  gain de couleur étalonné par mesure (0,22) ; « calage » de palette = essai de discussion, désactivé. Combat forêt :
  décor rendu avec les textures. Test : `tests/p53b_pilote_smoke.gd`. Pas de nouvelle passe sur l'occlusion.
- **P5.3-B V2 (branche `p5-3b-v2-sols`, `docs/P5_3B_V2.md`)** : V2 du créateur (`art/p53/sol_v2/`, hauteurs absolues,
  couleurs déjà recalées : **jamais de second calage**) retenue au démarrage de F5 et en combat après comparaison avec
  P5.3 et V1 + calage (référence visuelle conservée, touche U). Zone pilote seulement ; pas de remplacement global.
  **Revue du créateur (21/11/2026)** : la V2 se découpe en plaques ; préférence provisoire pour la **V1 + calage**.
- **P5.3-B V2 transitions (branche `p5-3b-v2-transitions`, `docs/P5_3B_V2_TRANSITIONS.md`)** : dernière passe ciblée,
  shader seulement (hauteurs par matière, bande d'herbe usée par proximité du chemin, matériau `materiau_p53b2t`) ;
  textures V1 / V2 inchangées. Plus naturelle que la V2, presque au niveau de la V1 + calage (moins bien aux
  embranchements). Choix final du créateur en attente ; ne pas commencer SOL-04, litière ni autres matériaux avant.
- **P5.3-B V3 hybride (branche `p5-3b-v3-hybride`, `docs/P5_3B_V3_HYBRIDE.md`)** : matières V2 (palette, calme) + forme
  des zones mixtes V1 (masque tiré du dessin de l'herbe usée V1, aucune couleur V1) ; matériau `materiau_p53b3h`, au
  démarrage de F5 et en combat ; toutes les autres variantes sur U. Aucun nouvel asset, textures inchangées.
  Retenue seulement si le créateur la juge au moins égale à la V1 + calage sur les transitions.
- **P6 Colisée (branche `p6-colisee-ouverture`, `docs/P6_COLISEE.md`)** : ouverture jouable en F6
  (`scenes/p6/colisee.tscn`, hérite de l'habillage de l'avant-poste), données `data/p6/*.json` (zone générée par
  `tools/p6/build_colisee.py` : ne pas éditer `colisee.json` à la main), progression explicite
  `src/game/progression.gd` (états dans `GameState.flags`), combat tutoriel `scenes/battle/combat_tutoriel.tscn`
  (CombatCore inchangé : le commandant est invulnérable PAR SES DONNÉES), guide `src/tutorial/guide_interface.gd`
  (cibles = composants réels du HUD, `combat_hud.guide_target`). Aren seul pendant l'introduction. F5 inchangé
  (promotion du Colisée en attente de l'accord du créateur). Tests : `tests/unit/test_p6_colisee.gd`,
  `tests/e2e_p6_ouverture.gd -- --tuto-rapide`, parcours `p6_sondes`.
- **P6.1 (branche `p6-1-colisee-camera-art`, `docs/P6_1_CAMERA_ART.md`)** : propositions EN ATTENTE de validation du
  créateur — caméra du Colisée P24 ×3 (touche C), Aren « forêt » = V09B.5 96×112 h64 + V4 (fichiers `art/tests/`,
  module `anim_v09b5.gd`, touche B ; P4.8 = `art/p45/chars/aren/`, style chibi, conservé), pilote d'habillage
  `scenes/p6/habillage_p6.gd` (touche H, ressources du dépôt seulement, décor sans collision). Garde-fou du tutoriel :
  `src/tutorial/garde_fou.gd` (attaque du commandant bornée, CombatCore inchangé). Aucun pack externe téléchargé
  (hôtes bloqués, licences non vérifiées).
- **P6.2 (branche `p6-2-colisee-circulation-visibilite`, `docs/P6_2_CIRCULATION_VISIBILITE.md`)** : **azimut 0°
  du Colisée validé par le créateur le 22/11/2026** (plongée 24°, champ 30°, ×3 ; `World25.yaw` réglable, remis à 20°
  en quittant la scène ; forêt et avant-poste à 20°). Visibilité des intérieurs : `src/explore25/secteurs25.gd`
  (secteurs en données, murs de premier plan coupés seulement s'ils cachent la pièce active, plafonds « ombres
  seulement », collisions jamais touchées) — prototype vestiaires / passage / salle / tunnel EN ATTENTE de validation ;
  ne pas l'étendre à l'arène ni à la coursive sans accord. Saut du tutoriel : `Progression.conclure_tutoriel()`
  (conclusion commune), test `tests/e2e_p6_saut_tutoriel.gd`.
- **P6.2-B (branche `p6-2b-transitions-interieurs`, `docs/P6_2B_TRANSITIONS.md`)** : le créateur a refusé les pièces
  qui descendent / remontent (mode A conservé en comparaison, touche J). Mode B « continu » proposé (EN ATTENTE) : aucune
  géométrie ne bouge ; murs = structure persistante (groupes « MUR: », prolongés à 6 m dans les intérieurs, linteaux) ;
  seules les pièces DEVANT la pièce active et l'extérieur s'estompent sur place ; arène révélée selon la position
  (`revele_ext`) ; seuils stables (0,4 m) ; occultation du moteur activée dans le Colisée. Mode C (fondu de porte)
  réservé aux vraies portes fermées. Ne pas généraliser à l'arène ni à la coursive sans accord.
- **P6.2-C (branche `p6-2c-tunnel-visibilite`, `docs/P6_2C_TUNNEL_VISIBILITE.md`)** : EN ATTENTE de validation. Caméra du
  Colisée en B / C : limites COMMUNES au bâtiment (plus de limites par pièce : bonds mesurés par
  `tools/p6/camera_continuite_p6.gd`, 0 attendu). Arène invisible depuis la salle ; tunnel = intérieur S3, arène vue par
  lignes de vue à travers la bouche (`src/p6/vue_tunnel.gdshader`, masque d'affichage seulement), découverte à la sortie ;
  arène = « zone ouverte » S4 (référence des coupes, décor resté EXT) ; murs du tunnel à 3,1 m, jamais coupés ; arc bas
  à la bouche. Le voile du niveau doit atteindre 0 / 1 exactement (sinon passe transparente). Packs Quaternius (CC0) :
  non importés, pilote limité après validation seulement.
- Après toute modification : `godot --headless --path . --script res://tests/run_tests.gd`,
  `--script res://tests/e2e_p4_retour.gd`, `--script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide`, `--script res://tests/e2e_p6_saut_tutoriel.gd`, puis les parcours `--route=p4` et `--route=p4_sondes` (voir README).
- Ne pas supprimer ni réécrire les branches existantes ; travailler sur une branche dédiée par étape.
