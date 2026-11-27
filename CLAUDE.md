# Consignes du projet Val'Serra

- **Moteur : Godot 4.7.2, strictement.** Toute scène, tout script et tout test se valident sous cette version.
  Ne pas modifier `config/features` dans `project.godot` sans décision explicite.
- **F5 lance la forêt V07B** (`run/main_scene = res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn`,
  caméra P30 à trois inclinaisons, occlusion, navigation libre V08A) : **décision du créateur du 15 novembre 2026**,
  consignée dans `docs/P4_9_V07B.md` (§ V08A). La démo de l'avant-poste (F5 jusqu'en P4.8) est **retirée
  en P7.2 avec l'accord du créateur (23/11/2026)** : scène, données, tests et ressources propres dans l'historique Git ;
  `scenes/p4/avant_poste.gd` reste comme **script de base** dont hérite le Colisée (ne pas le supprimer).
  **Ne pas modifier `run/main_scene` sans l'accord explicite du créateur.** Une nouvelle branche ou une nouvelle
  étape ne suffit pas à « promouvoir » une scène sur F5 : la promotion est une décision du créateur, datée et
  consignée dans le compte rendu de l'étape. Si une étape casse la scène F5, revenir à l'état stable précédent et
  le signaler.
- **Organisation** : les zones sont décrites par des données (`data/p6/*.json`, `data/p7/*.json` : mètres, niveaux,
  collisions) lues par le socle `src/explore25/` ; l'habillage de base est dans `scenes/p4/avant_poste.gd` (hérité), les shaders dans `src/p4/`, les
  ressources dans `art/p4/`, `art/p41/` et `art/p45/` (provenance et statut dans leurs `SOURCES.md`). Ajouter une
  zone = un fichier de données + ses ressources, pas un nouveau moteur. Les anciennes scènes (P1–P3, ancienne
  exploration) ont été retirées en P4.4 : elles restent dans l'historique Git (`docs/HISTORIQUE.md`).
- **Projet actif léger** : ne garder dans le dépôt que ce qui sert à l'exécution, aux tests et au développement
  courant. Planches sources, ZIP, GIF et anciennes variantes restent sur le Drive ; médias de rapport limités à
  l'étape en cours. Ne jamais réécrire l'historique Git sans accord explicite.
- **Caméra d'exploration** : P30 par défaut depuis P4.4 (Camera3D perspective, plongée 30°, champ 30°, azimut 20°,
  flou de distance léger en haut de l'écran seulement), rotation fixe, zooms ×2 / ×2,5 / ×3 (×2,5 par défaut).
  (B28, orthographique 28°, et sa scène de comparaison ont été retirés avec l'avant-poste en P7.2.)
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
- **P6.2-D (branche `p6-2d-colisee-complet`, `docs/P6_2D_COLISEE_COMPLET.md`)** : EN ATTENTE de validation. Système B
  étendu à tout le Colisée (secteurs S5 tunnel est, S6 coursive, S7 infirmerie, S8 réserve, S9 sortie ; toits des
  intérieurs vus de l'arène ; pièces latérales non rendues depuis un intérieur). Tunnel sud de longueur paramétrable
  (`TUNNEL_RETENU` dans `tools/p6/build_colisee.py`, B = 8,5 m proposé ; bloc sud décalé par `decalage_sud`, appliqué
  aux PNJ, au décor de l'habillage et aux parcours « p6 » par `Routes.sud`). Vue du tunnel par la seule position d'Aren
  (masque fermé au seuil salle / tunnel). Arche de la bouche jamais coupée (trouée locale). Gradins sud-est abaissés à
  l'affichage. Décor du combat tutoriel non régénéré (combat hors périmètre).
- **P6.3 (branche `p6-3-colisee-art`, `docs/P6_3_COLISEE_ART.md`)** : P6.2-D validé comme base technique le 22/11/2026.
  Habillage EN ATTENTE de validation : sélection Quaternius CC0 (`art/p63/quaternius/`, 15 modèles, textures 1024²,
  licences et `SOURCES.md` ; ne pas importer les packs entiers), placée par `colisee.modele()` ; mobilier des données
  remplacé par les modèles (collisions des données inchangées), accessoires posés par la scène = obstacle rond
  (`_solide_rond`) : aucun relief visible traversable (`tools/p6/reliefs_p6.gd`). Éléments muraux attachés à la coupe de
  leur mur (`Secteurs.attacher`) ; sols = groupes « SOL: » (devant, derrière, visibles). Luminaires sans ombre portée.
  Décor du combat tutoriel régénéré (l'ancien `arene_colisee_p6.png` est retiré en P7.2, historique Git). Le quartier de ville n'est PAS à développer : il
  sera repensé à partir d'un plan séparé.
- **P6.3.1 (branche `p6-3-1-colisee-integrite-visuelle`, `docs/P6_3_1_INTEGRITE_VISUELLE.md`)** : EN ATTENTE de validation.
  Anneaux de l'arène en UV métriques le long de l'arc (`habillage_p6._rq / _rt`, matériaux `mat_uv`) ; tranche de gradins
  du tunnel est jamais coupée (trouée locale par volumes d'occultation) ; cloisons entre deux intérieurs et mur sud de
  la coursive rendus pleine hauteur (collision inchangée) ; éblouissement du tunnel « discret » par défaut
  (`--eblouissement=actuel|aucun|discret`) ; diagnostic de visibilité F10 / `--diag` (outil, lecture seule).
  Ne pas lancer P6.4 sans accord.
- **P6.3.2 (branche `p6-3-2-colisee-corrections-finales`, `docs/P6_3_2_CORRECTIONS_FINALES.md`)** : éblouissement discret
  retenu provisoirement. Écoinçons entre l'anneau des gradins et l'enveloppe rectangulaire maçonnés (`habillage_p6._ecoincons`,
  affichage seul) ; portes fermées : variante basse visible quand leur mur est coupé (`Secteurs.attacher_coupe`) ;
  textures de matières P4 du Colisée importées AVEC mipmaps (cause principale du scintillement) ; moulures et bouts de
  murs décalés de quelques mm (faces confondues). Outils : `coplanaires_p6.gd`, `clignotements_p6.py`,
  `--isoler=ombres|occultation|trouee|fondus`. Corrections structurelles terminées : attendre l'accord pour P6.4.
- **P6.4 (branche `p6-4-colisee-direction-artistique`, `docs/P6_4_DIRECTION_ARTISTIQUE.md`)** : PILOTE EN ATTENTE de validation
  artistique. Galerie couverte des écoinçons (`habillage_p6._galerie_p64`, toiture de tuiles en appentis, contreforts, corniche ;
  affichage seul, aucune collision). Portes fermées en coupe (`colisee._en_coupe` / `_en_fantome`, shaders
  `src/p6/coupe_p64.gdshader`, `fantome_p64.gdshader` ; touche U). Matériaux procéduraux `src/p6/maconnerie_p64.gdshader`
  (calepinage en mètres, joints filtrés, grain de `art/p4/mat/roche.png`) LIMITÉS aux zones pilotes (`P64_MURS`, `P64_SOLS`,
  `P64_GRADINS`) : ne pas généraliser avant accord. Touche M / `--p64=0` : état P6.3.2. Mipmaps et faces de P6.3.2 conservés.
- **P6.4.1 (branche `p6-4-1-colisee-second-pilote`, `docs/P6_4_1_SECOND_PILOTE.md`)** : retour du créateur du 23/11/2026 :
  principe de la galerie couvert VALIDÉ, toiture du premier pilote refusée ; porte B (silhouette « hologramme ») refusée,
  A préférée provisoirement ; direction calcaire ocre / gris chaud retenue, mur des vestiaires = bonne base ; dallage trop
  régulier. Second pilote EN ATTENTE : galeries A / B (`habillage_p6._galerie_v2`, touche K), porte C (coupe sobre, ferrure,
  cadenas discret à l'approche, jamais sur l'axe du passage ; touche U ; aucune mini-porte), matières hybrides
  (`mur2`, `mur_haut2`, `dallage2`, `socle2` : calepinage procédural + détails peints tirés de `sol_terre.png` /
  `sol_herbe.png`), lumière des accès de la coursive. Touche M : P6.3.2 / pilote 1 / pilote 2 (`--p64=0|1|2`).
  Ne pas généraliser ni étendre les lumières avant validation.
- **P6.4.2 (branche `p6-4-2-colisee-extension`, `docs/P6_4_2_COLISEE_EXTENSION.md`)** : décisions du créateur du 23/11/2026
  après P6.4.1 : galerie **B** (structure mixte ; A réservée aux couvertures complètes justifiées, jamais mêlée
  arbitrairement), porte **C**, mur et dallage du second pilote, logique de lumière des accès. Extension EN ATTENTE de
  validation : `--p64=3` (défaut ; touche M : 0 / 1 / 2 / 3) ; matières par zone `habillage_p6.mz(nom, zone)` et
  `P642_ZONES` (même calepinage hybride, palette / usure / salissure selon la pièce ; pas de troisième variante de dallage) ;
  `lumiere_p642()` (accès et axes, aucune lumière qui suit Aren) ; toits des intérieurs en terrasses (`Secteurs.mat_toit`).
  Téléportation = visibilité recalée sans fondu (`colisee.teleport`). Le quartier de ville reste hors périmètre.
- **P6.4.3 (branche `p6-4-3-colisee-consolidation`, `docs/P6_4_3_COLISEE_CONSOLIDATION.md`)** : consolidation EN ATTENTE de
  validation, corrections locales seulement. Rectangle jamais masqué de la vue du tunnel à 37,3 (plan non décalé) dans
  `build_colisee.py` ; joues des gradins aux accès (`habillage_p6._joue_gradins`) ; arc et grille du tunnel est classés
  EXT ; calque du sable `src/p6/sable_p643.gdshader` (`--sable=0`) ; ombres de contact locales au Colisée
  (`colisee._ombres_contact`, shader commun inchangé). Ne pas annoncer le Colisée validé ; la ville attend son plan directeur.
- **P7.1 (branche `p7-1-ville-blockout-v01`, `docs/P7_1_VILLE_BLOCKOUT_V01.md`)** : BLOCKOUT V0.1 du quartier central d'après le
  plan directeur V0.5 (validé comme base fonctionnelle) ; PROTOTYPE NON VALIDÉ. Données générées par
  `tools/p7/build_ville_v05.py` (ne pas éditer `data/p7/ville_v05.json` à la main ; échelle tirée des durées cibles à 2,2 m/s),
  affichage `scenes/p7/ville_blockout.gd` + `src/p7/blockout_p7.gdshader`, `--ville=v05` (scène F6 retirée en P7.12.2)
  (`colisee.gd`, `ville_v05 = true`). Le Colisée garde le quartier provisoire par défaut. Pas d'habillage définitif, pas
  d'intérieurs, pas de foule ; le quartier P4 provisoire n'est ni figé ni reconstruit.
- **P6.4.4 (branche `p6-4-4-colisee-vestiaires`, `docs/P6_4_4_COLISEE_VESTIAIRES.md`)** : `colisee.teleport()` (appelé aussi en fin
  de chargement) FORCE le voile de l'extérieur après sa mise à jour immédiate des secteurs (sinon l'arène restait visible
  depuis les vestiaires, le passage et la salle). Diagnostic : `tools/p6/visibilite_vestiaires_p644.gd`.
- **P7.2 (branche `p7-2-nettoyage`)** : nettoyage S1–S5 de l'audit P7.0 et retrait de l'avant-poste P4, avec l'accord du
  créateur (23/11/2026) ; tout reste dans l'historique Git (`d88eac4`). S6–S9 restent conditionnels.
- **P7.3 (branche `p7-3-ville-v06`, `docs/P7_3_VILLE_V06.md`)** : démonstration verticale V0.6 (brief V0.6), PROTOTYPE NON
  VALIDÉ. Le blockout V0.1 n'est qu'une référence fonctionnelle. Données `tools/p7/build_ville_v06.py` -> `data/p7/ville_v06.json`
  (ne pas éditer à la main), affichage `scenes/p7/ville_v06.gd`, `--ville=v06` (scène F6 retirée en P7.12.2). Caméra de la
  VILLE seulement (`colisee._camera_de_zone`, CAMS « V06 » / « V06O ») : perspective, plongée 11°, champ 30°, zoom ×3 fixe,
  altitude lissée (`Session25.cam_lissage_h`, 0 ailleurs) ; Colisée, forêt et autres zones gardent leur caméra.
  Règle de composition : bâtiments importants façade au sud (face caméra), volumes bas entre la caméra et les lieux
  d'arrêt. Ne pas reconstruire le quartier entier avant validation de la vidéo par le créateur.
- **P7.4 (branche `p7-4-ville-v07a`, `docs/P7_4_VILLE_V07A.md`)** : V0.7-A, EXPÉRIENCE NON VALIDÉE (brief P7.4) : micro-blockout
  semi-circulaire (`tools/p7/build_ville_v07a.py` -> `data/p7/ville_v07a.json`, `scenes/p7/ville_v07a.gd`, `--ville=v07a` (scène F6 retirée en P7.12.2),
  plan `tools/p7/plan_v07a.py`). Caméra A = caméra V0.6 ; B = même caméra, orientation propre à 2 secteurs des données
  (`zones_camera`, hystérésis, rotation amortie, commandes verrouillées pendant la rotation : `World25.yaw_commande_actif`,
  inactif hors de la ville). Ne pas reconstruire le quartier avant la décision de la direction sur l'agencement et la caméra.
- **P7.4.1 (branche `p7-4-ville-v07a`, `docs/P7_4_1_CAMERA_COLISEE.md`)** : EN ATTENTE. Caméra de la ville et caméra « V »
  (V0.7-A) du Colisée SANS limites écran (le suivi d'Aren prime ; outil de continuité : zone confortable). Caméra V0.7-A
  adoptée provisoirement dans le Colisée (`cam_p6 = "V"` par défaut, `Cam25.verrou` : ni molette ni zoom des parcours ;
  plongée par secteur `PLONGEE_SECTEURS` : 20° dans l'arène S4, 11° ailleurs). Tunnel sud : LONGUEUR retenue 9,0 m
  (`TUNNEL_RETENU_M`, largeur inchangée ; variantes A / B / C conservées). Porte publique de la V0.7-A sur la façade EST
  du tambour (même axe réel que la sortie est du Colisée) ; portail « colisee_porte_publique » (sorties de données,
  orientation d'arrivée `orientation`, déclencheur inverse désarmé à l'arrivée). Test `--route=p7_v07_portail`.
- **P7.5 (branche `p7-5-ville-v07b`, `docs/P7_5_VILLE_V07B.md`)** : porte du Colisée à deux battants dans l'arche sud du propylée
  (entrée par interaction E, portail `colisee_porte_publique` inchangé, arrivée de retour sur le perron). V0.7-B = BLOCKOUT
  CONSOLIDÉ NON VALIDÉ : `tools/p7/build_ville_v07b.py` -> `data/p7/ville_v07b.json` (ne pas éditer à la main),
  `scenes/p7/ville_v07b.gd` (hérite de la V0.7-A), F6 `scenes/p7/ville_v07b.tscn` ; la V0.7-A reste la référence. Accès futurs
  bloqués par des obstacles crédibles (A chantier, B caravane, C gardes) ; prolongements visuels sans collision. Parcours
  `p7_v07b_sondes|trajets|vues|video`. Pas d'intérieurs, de foule, d'habillage détaillé ni de reprise de l'éclairage.
- **P7.6 (branche `p7-6-tranche-architecturale`, `docs/P7_6_TRANCHE_ARCHITECTURALE.md`)** : V0.7-B retenue comme référence générale
  de la ville (plan non refait). Colisée : couloir de sortie + VESTIBULE, porte de la ville au SUD (déclencheur `sortie_est` sur le
  seuil, y 29,1 -> 29,8) ; retour en ville devant les grandes portes, tourné vers le sud. Entrées des bâtiments en données
  (`ENTREES` : fonctionnelles = instances futures, examen au seuil, aucune transition ; décoratives). Volumes entre la caméra et
  Aren ESCAMOTÉS (`ville_v07b.coupes_camera`, remplace la trame « proche » en V0.7-B ; `--coupe_ville=0`). Outil
  `tools/p7/camera_volumes_p76.py` : recouvrements de volumes = 0 attendu. TRANCHE PILOTE (`scenes/p7/tranche_p76.gd`, enduit
  `src/p7/enduit_p76.gdshader`, maçonnerie du Colisée) limitée à l'îlot de l'auberge et à la ruelle des Tonneliers : NE PAS
  étendre matières et façades au reste de la ville avant validation (`--tranche=0` : blockout).
- **P7.7 (branche `p7-7-controles-composants`, `docs/P7_7_CONTROLES_COMPOSANTS.md`)** : direction de la tranche APPROUVÉE par le
  créateur le 25/11/2026 (RDC pierre, étages enduits, plusieurs niveaux, toits de tuiles), ainsi que la sortie du Colisée et le
  muret de 0,6 m. Composants réutilisables `scenes/p7/archi_p77.gd` (les valeurs par défaut = tranche P7.6 au pixel près ;
  catalogue F6 `scenes/p7/catalogue_archi_p77.tscn`) ; TOUJOURS fusionner les maillages par matière (`Archi.fusionner`,
  sinon ×2,4 appels de dessin). Masquage des volumes : NET retenu (`--escamotage=fondu` : essai Forward+ seulement).
  Profilage `tools/p7/profil_gpu_p77.gd` (les captures de ce conteneur passent par le rendu Compatibilité OpenGL sur
  processeur : temps non significatifs). Prochaine tranche : grande place, selon le plan du rapport, APRÈS validation du
  plan ; ne pas habiller le reste de la ville, entrées et intérieurs inchangés.
- **P7.8 (branche `p7-8-grande-place-lot1`, `docs/P7_8_GRANDE_PLACE_LOT1.md`)** : décisions du 25/11/2026 : masquage NET conservé
  (fondu expérimental), lot 1 de la grande place SEUL autorisé (revêtement + fontaine octogonale à deux vasques,
  `scenes/p7/place_p78.gd`, eau opaque `src/p7/eau_p78.gdshader`, `--place=0`) ; NE PAS commencer le lot 2 sans validation.
  Axe du château RÉSERVÉ (`axe_chateau` des données, x 70 ; contrôle dans `camera_volumes_p76.py`) : ne rien construire
  qui coupe la vue, ne pas construire le château. Avant le lot 2 : comparatif ciblé de quelques modèles Quaternius (Drive),
  sans import complet ni remplacement automatique. LIVRABLES : résumé concis, branche et commits, fichiers, tests
  synthétiques, problèmes non résolus, commandes si elles changent ; PAS de vidéos ni de montages, pas de médias non demandés.
- **P7.9 (branche `p7-9-forge-comparatif`, `docs/P7_9_FORGE_COMPARATIF.md`)** : lot 1 accepté comme base (quadrillage atténué, jets et
  vasques retouchés). Comparatif de la FORGE SEULE (`scenes/p7/forge_p79.gd`) : A bibliothèque, B Quaternius, C hybride (murs A + toit,
  vantaux, cheminée, accessoires Quaternius) ; `--forge=A|B|C` (scènes F6 retirées en P7.12.2). Modèles Quaternius
  ajoutés listés dans `art/p63/quaternius/SOURCES.md` (provisoires, mipmaps) ; maillages fusionnés par matière. Accès au Drive :
  environnement « Val-Serra-Game » (`drive.usercontent.google.com`). NE PAS habiller les autres commerces avant décision.
- **P7.10 (branche `p7-10-forge-boutique`, `docs/P7_10_FORGE_BOUTIQUE.md`)** : variante C retenue comme base de production
  (C+ = forge par défaut de `ville_v07b.tscn`, `--forge=0` : blockout) : toit Quaternius NON fusionné en terre cuite désaturée
  (`forge_p79._terre_cuite`), cheminée de pierre, enseigne d'armurerie, atelier de la cour, baie cintrée (`baie_cintree`
  dans `archi_p77.gd`) ; emprise, collisions et entrée inchangées. Boutique de fournitures (`scenes/p7/boutique_p710.gd`,
  `--boutique=0`) : maison haute à pignon sud, étal adossé à `bat_commerce_e2` (seule collision ajoutée). EN ATTENTE de
  validation de la cohérence forge / boutique : NE PAS habiller d'autres bâtiments ; axe du château préservé.
- **P7.10.1 (branche `p7-10-1-forge-refonte`, `docs/P7_10_1_FORGE_REFONTE.md`)** : progrès techniques de P7.10 validés, qualité
  artistique de la forge NON validée. Refonte D (`scenes/p7/forge_p7101.gd`, défaut de `ville_v07b.tscn` ; `--forge=C` = C+ avant) : façade sud maçonnée en épaisseur (0,45 m, baies en retrait, arcs segmentaires),
  entrée dans un avant-corps de la saillie des piédroits à collision (0,35 m), pierre chaude, porte de bois sombre ferrée,
  seuil raccordé au dallage ; foyer à hotte + souche sur le pignon ouest, lumière du foyer (OmniLight sans ombre), fumée ;
  pignons de pierre (maillage triangulé fusionné À PART : la fusion avec les boîtes le perd) ; tuiles `src/p7/tuiles_p7101.gdshader`.
  Emprise, collisions, interaction inchangées. **Refonte D APPROUVÉE par le créateur (26/11/2026) : nouvelle référence
  architecturale de Val'Serra.** Correctif local (commit distinct) : pignons assis sur la corniche latérale (0,42 m), angles de
  corniche d'équerre, rampants de rive en pierre, appentis couvert de tuiles canal (matière « tuiles » du Colisée, UV en mètres)
  sous les corbeaux. Ne plus refondre la forge.
- **P7.11 (branche `p7-11-boutique`, `docs/P7_11_BOUTIQUE.md`)** : passe artistique de la boutique de fournitures, forge D comme
  référence de qualité. `scenes/p7/boutique_p711.gd` (défaut ; `--boutique=710` = P7.10 ;
  `--boutique=0` : blockout) : RDC de pierre en épaisseur, devanture de bois peint (poteaux = piédroits à collision), porte vitrée
  en embrasure, étages en pan de bois sur encorbellement (0,4 m) aux hourdis miel, pignon sur rue, potence de grenier, enseigne
  au flacon ; étal (seule collision ajoutée) déplacé à l'angle ouest (x 73,9 -> 76,45, y 88,05 -> 89,05), hors de l'ombre de
  `bat_commerce_e2`. Éléments rattachés au volume d'escamotage par la méta « vol » (`ville_v07b._classer_volumes`), sommet du
  volume porté à 17,5 m. **Approuvée par le créateur (26/11/2026) : deuxième référence architecturale** (pan de bois, trois
  niveaux, entrée, matériaux). Réserves pour les lots de bordure : enseignes au flacon à différencier, profondeur des
  fenêtres éclairées, visibilité de la boutique et de l'étal à préserver en traitant `bat_commerce_e2`, étals provisoires.
- **P7.12 (branche `p7-12-quartier-civique`, `docs/P7_12_QUARTIER_CIVIQUE.md`)** : lot 4 (fond nord, montée civique, administration)
  et perspective du château : `scenes/p7/civique_p712.gd` (`--civique=0` : état P7.11) ; volées C / D par `Tranche.escalier`,
  terrasses dallées avec voie processionnelle sur l'axe x 70, soutènements, balustrades (collisions `gc_*` inchangées),
  administration à porche, corps de garde (`bat_b_terrasse_no`), porte fortifiée (châtelet, herse, tours rondes, ardoise),
  courtines, ville haute (affichage seul, méta « vol » = « aucun ») ; château lointain recentré (x 70, générateur).
  Cadrage : seule la bande 8 -> 14 m de la porte est visible depuis la place (≈ 4° au-dessus de l'horizon). Hôtel de ville
  NON traité (autre lot). Nettoyage : audit `docs/AUDIT_P7_12.md`, suppressions EN ATTENTE de l'accord du créateur.
- **P7.12.1 (branche `p7-12-1-civique-consolidation`, `docs/P7_12_1_CONSOLIDATION_CIVIQUE.md`)** : EN ATTENTE. Caméra : `Cam25.visee_fixe`
  (ville et caméra V du Colisée) : plus de recentrage de 72 px aux examens (mesure `tools/p7/stabilite_interactions_p7121.gd`,
  0 attendu ; `--visee_dialogue=1` : P3). Occultation : volumes coupés à h0 + 3,5 m au chargement, escamotage des SEULES parties
  hautes quand la ligne de vue vers les pieds d'Aren passe au-dessus, volume entier sinon ; escamotage aussi si le volume coupe
  la ligne de vue (`--escamotage_partiel=0` : P7.6). Pas de transparence ni de trame. Plongée locale de la ville : 11° -> 6,5° sur
  la terrasse civique et l'avenue (`colisee._profil_ville`, `--plongee_civique=0`). Château décoratif à ≈ 150 m derrière la porte,
  vu par l'arc (herse relevée, accès fermé par la grille des données et les gardes) ; ardoise RÉSERVÉE au château. Corps de garde
  et pavillon de raccord (partie ouest de l'hôtel de ville, reste en blockout retinté pierre) en calcaire clair, façades
  maçonnées en épaisseur, comme l'administration.
- **P7.12.2 (branche `p7-12-2-coherence-terrasse`, `docs/P7_12_2_COHERENCE_TERRASSE.md`)** : EN ATTENTE. Règle : toute ouverture a une
  fonction compréhensible, toute porte un accès crédible (porte sans accès -> fenêtre, porte-fenêtre derrière un balcon). Terrasse du
  belvédère (`terrasse_cafe` des données, x 66 -> 76, y 82 -> 88, h 5,75, de plain-pied avec le palier 2 ; tables `decor_cafe_*` ;
  `emplacements_pnj` = emplacements seulement, aucun PNJ). Escamotage : marge de réapparition (`--escamotage_delai`, 0,6 s ; masquer
  reste immédiat), coupe finie par un « chapeau » (plancher + arase) ; mesure `tools/p7/escamotage_p7122.gd`. Fondu toujours expérimental. Nettoyage : scènes F6 des comparatifs forge / boutique et
  des villes V0.5 / V0.6 / V0.7-A retirées (options `--forge`, `--boutique`, `--ville` conservées ; restauration depuis `d0e387a`).
- **P7.13 (branche `p7-13-bordures-place`, `docs/P7_13_BORDURES_PLACE.md`)** : P7.12.2 validé globalement par le créateur. EN ATTENTE.
  Belvédère : buvette `decor_buvette` adossée à la boutique (emplacements PNJ : 2 clients + serveur, aucun PNJ). Château : herse
  baissée, grille des données non dessinée (collision gardée ; `--herse=relevee`). Bordures (`scenes/p7/bordures_p713.gd`,
  `--bordures=0`) : draperie sur `bat_commerce_e2` (plus basse que le blockout), étals 0 à 3, halle sur `bat_echoppe_no_o`.
  Cohérence : pas d'échiffre plaqué contre un mur (`CONTRE_MUR`), soubassement civique interrompu aux portes. Rendu : faces
  coplanaires corrigées par décalages de quelques mm ; outils `tools/p7/scintillement_p713.gd` (détecteur au rendu) et
  `coplanaires_p713.gd/.py`. Ombres : `--ombres_ville` = essai non activé, à juger en Forward+.
- **P8.0-A (branche `p8-0a-cadrage-ville`, `docs/P8_0A_CADRAGE.md`)** : EXPÉRIENCE, AUCUN angle retenu. Plongée de base de la ville
  au chargement (`colisee.plongee_ville()` : `--plongee_ville=`, méta `plongee_ville`, défaut 11° = P7.13) ; scènes F6
  `scenes/p7/ville_v07b_p80a_16|20|24.tscn` ; plongée civique 6,5° active par défaut à 11° seulement (`--plongee_civique=1|0`) ;
  parcours `p80a_cadrage(_course)`, mesure `tools/p8/cadrage_p80a.gd`. Colisée, champ, zoom, visée, géométrie, éclairage inchangés.
  Ne pas changer la plongée par défaut sans décision du créateur.
- **P8.0-A2 (même branche)** : 11° = référence artistique retenue par le créateur (27/11/2026). Essais 13° / 14° (scènes F6
  `ville_v07b_p80a_13|14.tscn`, plongée civique conservée jusqu'à 14°, `PLONGEE_CIVIQUE_MAX`) ; zone de lecture FACULTATIVE sur la
  terrasse du belvédère (`--zone_lecture=17`, scène `ville_v07b_p80a2_zone17.tscn`, désactivée par défaut). Diagnostic des premiers
  plans (souches des tours sud, chapeau de coupe de l'auberge au niveau de la place, versant sombre de l'auberge) : rapport § P8.0-A2.
  Aucun changement permanent de caméra avant le retour du créateur.
- Après toute modification : `godot --headless --path . --script res://tests/run_tests.gd`,
  `--script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide`, `--script res://tests/e2e_p6_saut_tutoriel.gd`, puis le parcours
  `--route=p6_sondes` du Colisée (voir README ; l'avant-poste et ses parcours `p4` / `p4_sondes` sont retirés depuis P7.2).
- Ne pas supprimer ni réécrire les branches existantes ; travailler sur une branche dédiée par étape.
