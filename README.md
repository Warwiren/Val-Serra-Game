# Val'Serra : Les Larmes d'Aether — démo jouable

Démo jouable du RPG narratif au tour par tour **Val'Serra**, réalisée sous **Godot 4.7.2**.

> Tous les personnages, monstres, illustrations et nombres de ce dépôt sont **provisoires et non canoniques**.
> Ce dépôt est indépendant du système Foundry du JDR (`Warwiren/Val-serra`), qui n'est pas modifié.

> Médias des étapes P4.9 à P5.3-B V2 : retirés du projet actif en P6 (`docs/P6_INVENTAIRE.md`), disponibles dans
> les branches d'origine (dernier état : `p5-3b-v3-hybride`).

## Ce qui est jouable

**F5 : la forêt stylisée V07B** (décision du créateur du 15/11/2026, étape P4.9 V08A) — terrain de 36 × 28 m,
modèles Quaternius stylisés, ruisseau, nouvelle direction HD-2D en cours d'essai :

1. **Exploration libre** avec **Aren** (cheveux bruns, armure et cape grises) et **Ilya** (cheveux courts argentés,
   cape verte, pistolet d'Aether) : chemins, clairières et butte se traversent hors des sentiers ; troncs, rochers,
   eau et vraies fortes pentes arrêtent les personnages (marche 2,2 m/s, course 3,6 m/s avec Maj, cycle de marche à
   8 images).
2. **Caméra P30** (perspective, azimut 20°, champ 30°) avec **trois inclinaisons à comparer** — 30°, 27°, 24° — et
   trois zooms.
3. **Occlusion dynamique** : un feuillage ou un buisson qui cache Aren ou Ilya s'efface en trame ; derrière un tronc
   ou un rocher, une silhouette discrète les montre.
4. **Diagnostic des collisions** (touche C) : obstacles, eau, bords et pentes du terrain.

C'est un **banc d'essai** (interface de test visible, pas de quête ni de combat). L'ancienne démo de l'avant-poste P4
a été retirée en P7.2 (accord du créateur) ; elle reste dans l'historique Git (commit `d88eac4`).


Étape en cours : **P4.9** — forêt V07B, inclinaisons et occlusion, navigation libre (V08A), locomotion V09A en essai
(comparaison V08 / V09A), **V09B.5 : nouvelles marche et course
d'Aren en comparaison** (touches B / T / P, vidéo comparative),
**V09B.6 : gabarit 64 px et plan de redessin pose par pose** (fiches et vidéo). Rapport
[`docs/P4_9_V07B.md`](docs/P4_9_V07B.md) ; vidéos : exploration libre,
inclinaisons et occlusion ;
comparatif 30° / 27° / 24°,
masque de collision avant / après.
Étapes précédentes : `docs/HISTORIQUE.md`.

## Lancer le jeu (Godot 4.7.2 obligatoire)

> **Version du moteur : Godot 4.7.2, et elle seule.** La ligne `config/features=PackedStringArray("4.5")` de
> `project.godot` est un reliquat historique, laissé tel quel volontairement.

1. Télécharger le projet (GitHub : choisir la branche **`p8-1a-finition-quartier`**, puis **Code → Download ZIP** ;
   le dossier s'appelle `Val-Serra-Game-p8-1a-finition-quartier`) et le décompresser.
2. Récupérer **Godot 4.7.2** (édition standard, pas « .NET ») : <https://godotengine.org/download/archive/4.7.2-stable/>.
3. Godot → **Importer** → choisir `project.godot` → **Importer et modifier** (une minute environ la première fois).
4. **F5** lance la **forêt V07B** (`ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn`), avec les
   corrections de navigation V08A et la locomotion V09A en essai (touche L pour revenir à V08). **Depuis le 19/11/2026,
   F5 démarre dans la configuration de validation** : Aren V09B.5 à 64 px, Ilya nouvelle apparence V09C.6, marche
   2,2 / course 3,6 m/s, inclinaison 24°, zoom ×3 (rien à activer ; P4.8 et les autres versions restent aux touches).
   **État validé le 20/11/2026** : profil droit (miroir vers la gauche) ; vers le bas / le haut, Aren marche de face /
   de dos (GIF dessinés, V4) et Ilya de face / de dos (pack V09C.5) ; rendu Sprite3D d'origine. **V11 (20/11/2026)** :
   **sans brouillard** au démarrage (touche F pour le revoir), **tous les rochers et les buissons hauts bloquent**, et
   le **Vorgane** se tient au sud du chemin principal (x ≈ 7,5), animé et solide, sans combat déclenché.
   **Branche `p5-combat` (refonte du combat, 20/11/2026)** : F5 est inchangé (forêt validée) ; le combat refondu
   s'ouvre en **F6** depuis `scenes/battle/combat_foret.tscn` (groupe à gauche, Vorgane à droite, décor forêt).
   **Branche `p5-2-environnement` (20/11/2026)** : F5 démarre avec le **nouveau sol** (matière, raccords chemin / herbe,
   pentes lisibles, pieds d'objets, horizon fermé ; touche **U** pour revoir le sol d'origine) ; le décor du combat
   forêt (F6) a le même sol, une clairière, de la profondeur et un premier plan. Rapport : `docs/P5_2_ENVIRONNEMENT.md`.
   **Branche `p5-3-sols` (21/11/2026)** : sol P5.3 (bordures sans contour, usure de l'herbe, pentes par paliers,
   pieds d'objets) et ombre du terrain rétablie, filtre des ombres en **qualité 4 à l'essai** ; **U** : P5.3 → P5.2 figé
   → V07 ; **J** : qualité 4 / 2. Rapport : `docs/P5_3_SOLS.md`.
   **Branche `p5-3b-pilote-sols` (21/11/2026)** : F5 démarre sur le **pilote des textures de sol peintes** (herbe drue,
   herbe usée, terre de chemin) dans une zone de 8 m autour du départ ; **Y** : textures sur toute la carte ; **U** :
   pilote → P5.3 → P5.2 → V07. Le combat forêt (F6) utilise les textures. Rapport : `docs/P5_3B_PILOTE.md`.
   **Branche `p5-3b-v2-sols` (21/11/2026)** : F5 démarre sur la **V2** des textures (couleurs recalées), retenue après
   comparaison ; **U** : V2 → V1 + calage → V1 brute → P5.3 → P5.2 → V07 ; combat forêt (F6) en V2. Rapport : `docs/P5_3B_V2.md`.
   **Branche `p5-3b-v2-transitions` (21/11/2026)** : F5 démarre sur la **V2 avec transitions corrigées** (bande
   d'herbe clairsemée, touffes débordantes) ; **U** : V2 transitions → V2 actuelle → V1 + calage → V1 → P5.3 → P5.2 →
   V07 ; combat forêt (F6) en V2 transitions. Rapport : `docs/P5_3B_V2_TRANSITIONS.md`.
   **Branche `p5-3b-v3-hybride` (21/11/2026)** : F5 démarre sur la **V3 hybride** (matières V2, forme des zones mixtes
   de la V1) ; **U** : V3 hybride → V2 transitions → V2 → V1 + calage → V1 → P5.3 → P5.2 → V07 ; combat forêt (F6) en
   V3 hybride. Rapport : `docs/P5_3B_V3_HYBRIDE.md`.
   **Branche `p6-colisee-ouverture` (21/11/2026)** : F5 est **inchangé** (forêt V07B, la promotion du Colisée sur
   F5 attend l'accord du créateur). **L'ouverture du jeu se lance en F6 depuis `scenes/p6/colisee.tscn`** :
   vestiaires → salle d'attente → arène → combat tutoriel guidé contre le commandant → retour en exploration →
   coursive → sortie est → quartier (transition provisoire). Aren seul. Rapport : `docs/P6_COLISEE.md` ;
   inventaire et allègement : `docs/P6_INVENTAIRE.md`.
   **Branche `p6-1-colisee-camera-art` (21/11/2026)** : F5 inchangé ; Colisée en F6 avec les réglages proposés
   (à valider) : caméra **P24 ×3** comme la forêt (touche **C** : P30 ×2,5 / P30 ×3 / P24 ×3), Aren avec
   **l'apparence de la forêt** (V09B.5 + V4 ; touche **B** : P4.8), **pilote d'habillage** (touche **H** : blockout).
   Rapport : `docs/P6_1_CAMERA_ART.md`.
   **Branche `p6-2-colisee-circulation-visibilite` (étape A, plan de circulation)** : F5 inchangé ; Colisée en F6
   **azimut 0° validé le 22/11/2026** (`colisee.tscn` ; ancienne référence 20° : `-- --azimut=20`).
   **Étape B** : vestiaires et salle d'attente en vrais intérieurs (visibilité par secteurs, murs de premier plan coupés,
   lanternes à ombres douces), tutoriel qu'on peut passer (dialogue du commandant, ou Échap en combat avec confirmation). Rapport et nouveau plan : `docs/P6_2_CIRCULATION_VISIBILITE.md`.
   **Branche `p6-2b-transitions-interieurs`** : F5 inchangé ; `colisee.tscn` (F6) démarre avec les transitions
   **continues** (mode B : architecture persistante, estompage sur place) ; **touche J** : A (P6.2) / B / C (fondu de porte).
   Rapport : `docs/P6_2B_TRANSITIONS.md`.
   **Branche `p6-2c-tunnel-visibilite`** : F5 inchangé ; `colisee.tscn` (F6), mode B : **caméra sans bonds** (limites
   communes au bâtiment), **arène invisible depuis la salle**, vue **cadrée par la bouche du tunnel** (lignes de vue
   réelles), découverte de l'arène **à la sortie**, plus de grands murs devant Aren dans l'arène. Rapport :
   `docs/P6_2C_TUNNEL_VISIBILITE.md` ; mesure de continuité : `tools/p6/camera_continuite_p6.gd`.
   **Branche `p6-2d-colisee-complet`** : F5 inchangé ; `colisee.tscn` (F6) = **Colisée complet** traité (vestiaires
   fermés, tunnel sud de **8,5 m** proposé avec vue par la bouche et découverte au débouché, arche et murs hauts revus,
   arène, tunnel est, coursive, infirmerie, réserve et sortie est en intérieurs, caméra continue partout). Longueurs
   du tunnel à comparer en F6 : `colisee_tunnel_A_6_5m.tscn` / `_B_8_5m` / `_C_9_5m`. Rapport : `docs/P6_2D_COLISEE_COMPLET.md`.
   **Branche `p6-3-colisee-art`** : F5 inchangé ; `colisee.tscn` (F6) = Colisée **habillé** (pilote artistique étendu) :
   mobilier, lanternes, portes et bannières Quaternius (CC0, sélection de 15 modèles, `art/p63/quaternius/`), arc en
   claveaux et torches du tunnel sud, fausse marche et bannières corrigées, décor du combat tutoriel actualisé.
   Rapport : `docs/P6_3_COLISEE_ART.md`.
   **Branche `p6-3-1-colisee-integrite-visuelle`** : F5 inchangé ; `colisee.tscn` (F6) corrigé (poutre des vestiaires,
   gradins en UV le long de l'arc, enceinte continue au tunnel est, infirmerie fermée par ses cloisons, éblouissement
   discret du tunnel sud). **F10** : diagnostic de visibilité. Rapport : `docs/P6_3_1_INTEGRITE_VISUELLE.md`.
   **Branche `p6-3-2-colisee-corrections-finales`** : F5 inchangé ; `colisee.tscn` (F6) avec les écoinçons maçonnés derrière
   les gradins, la porte de la réserve visible depuis la coursive (porte basse quand le mur est coupé) et moins de
   scintillement (mipmaps des textures de matières, faces confondues des murs). Rapport : `docs/P6_3_2_CORRECTIONS_FINALES.md`.
   **Branche `p6-4-colisee-direction-artistique`** (pilote de direction artistique, EN ATTENTE de validation) : F5 inchangé ;
   `colisee.tscn` (F6) avec la galerie couverte des écoinçons (toiture de tuiles, contreforts, corniche), les portes
   fermées vues en coupe (vantaux tranchés + silhouette transparente) et des matériaux procéduraux sur trois zones pilotes
   (gradins sud-ouest, mur nord des vestiaires et sa porte, coursive et son dallage). **M** : pilote P6.4 / état P6.3.2 ;
   **U** : porte en coupe (silhouette / coupe seule / porte basse P6.3.2). Rapport : `docs/P6_4_DIRECTION_ARTISTIQUE.md`.
   **Branche `p6-4-1-colisee-second-pilote`** (second pilote, EN ATTENTE de validation) : F5 inchangé ; `colisee.tscn` (F6)
   démarre sur le second pilote : galerie A (petites tuiles, palette sombre, travées irrégulières), porte C (coupe sobre,
   ferrure, petit cadenas discret à l'approche), dallage enrichi et mur avec détails peints, lumière des accès.
   **M** : P6.3.2 / premier pilote / second pilote ; **K** : galerie A / B (structure mixte) / premier pilote ;
   **U** : porte C / A / B / P6.3.2. Rapport : `docs/P6_4_1_SECOND_PILOTE.md`.
   **Branche `p6-4-2-colisee-extension`** (EN ATTENTE de validation artistique) : F5 inchangé (forêt) ; `colisee.tscn` (F6)
   démarre sur l'**extension à tout le Colisée** des choix retenus après P6.4.1 : galerie **B** (structure mixte), porte
   **C**, matières hybrides adaptées à chaque zone (vestiaires, salle, tunnels, arène et gradins entiers, coursive,
   infirmerie, réserve, sortie), toits des intérieurs en terrasses dallées, lumière des accès dans chaque pièce, décor du
   combat tutoriel régénéré. **M** : P6.3.2 / premier pilote / second pilote / extension ; **K** : galerie B → premier
   pilote → A ; **U** : porte. Rapport : `docs/P6_4_2_COLISEE_EXTENSION.md`.
   **Branche `p6-4-3-colisee-consolidation`** (EN ATTENTE de validation) : F5 inchangé ; `colisee.tscn` (F6) = Colisée
   P6.4.2 consolidé : vue du tunnel sud sans éléments isolés, gradins fermés aux accès (plus de sol visible dessous), arc
   et grille du tunnel est rattachés à l'arène, sable enrichi (traces d'usage, cercle d'évaluation ; `-- --sable=0` pour
   comparer), ombres de contact des personnages. Rapport : `docs/P6_4_3_COLISEE_CONSOLIDATION.md`.
   **Branche `p7-1-ville-blockout-v01`** (PROTOTYPE de circulation, NON validé) : F5 inchangé ; **F6 sur
   `scenes/p7/ville_v05_blockout.tscn`** = blockout V0.1 du quartier central (plan V0.5) : départ à la porte sud, guilde,
   commerces, place, Colisée (parvis), deux boucles, accès château et quartier est fermés. `-- --etat=tutorial_completed` :
   départ dans le Colisée, dont la sortie mène au parvis. `colisee.tscn` (F6) inchangé (quartier provisoire).
   Rapport : `docs/P7_1_VILLE_BLOCKOUT_V01.md`.
   **Branche `p6-4-4-colisee-vestiaires`** (ticket distinct de la ville) : F5 inchangé ; `colisee.tscn` (F6) : l'arène n'est
   plus visible depuis les vestiaires, le passage et la salle d'attente (voile de l'extérieur forcé après un recalage).
   Rapport : `docs/P6_4_4_COLISEE_VESTIAIRES.md`.
   **Branche `p7-2-nettoyage`** : avant-poste P4 et médias des étapes terminées retirés (accord du créateur) ; F5 inchangé.
   **Branche `p7-3-ville-v06`** (PROTOTYPE de caméra et de ville ascendante, NON validé) : F5 inchangé ; **F6 sur
   `scenes/p7/ville_v06_montee.tscn`** = démonstration verticale V0.6 : porte sud → guilde → montée → grande place →
   montée vers le quartier civique (hôtel de ville, porte du château fermée), trois niveaux (0 / 3,5 / 8 m), caméra propre
   à la ville (perspective, plongée 11°, champ 30°, distance unique ×3 : molette sans effet). **C** : V0.6 perspective /
   V0.6 orthographique / caméra V0.5 (comparaison) ; **L** : libellés. `-- --etat=tutorial_completed` : départ dans le
   Colisée, dont la sortie mène à la rue du Colisée de la V0.6. Rapport : `docs/P7_3_VILLE_V06.md`.
   **Branche `p7-4-ville-v07a`** (EXPÉRIENCE, NON validée) : F5 inchangé ; **F6 sur `scenes/p7/ville_v07a.tscn`** = micro-blockout
   V0.7-A semi-circulaire : porte sud, placette et guilde, montée en baïonnette, grande place, embranchement vers le parvis du
   Colisée (vue extérieure), montée vers la terrasse haute et la porte du château, ruelle, rues futures fermées (chantier,
   grille). **V** : caméra A (fixe, nord) / B (semi-fixe, 2 secteurs) ; **L** : libellés. Rapport : `docs/P7_4_VILLE_V07A.md`.
   **P7.4.1** (même branche, EN ATTENTE) : suivi de caméra corrigé dans la ville ; caméra V0.7-A adoptée dans le Colisée
   (`colisee.tscn`, profil V : distance fixe, molette sans effet, 20° dans l'arène ; touche C : caméras P6 en comparaison) ;
   tunnel sud de 9 m ; **porte publique** sur la façade est du Colisée, liaison réelle ville ↔ Colisée dans les deux sens.
   Rapport : `docs/P7_4_1_CAMERA_COLISEE.md`.
   **Branche `p7-5-ville-v07b`** (BLOCKOUT CONSOLIDÉ, NON validé) : F5 inchangé. **Porte du Colisée** à deux battants dans
   l'arche sud du propylée (V0.7-A et V0.7-B) : **E** devant la porte pour entrer. **F6 sur `scenes/p7/ville_v07b.tscn`** =
   quartier central V0.7-B : porte sud, placette (Guilde, auberge-taverne), montée, grande place (fontaine, forge-armurerie,
   boutique de fournitures, étals ; Colisée à l'ouest), montée civique, terrasse haute (hôtel de ville, administration),
   accès gardé du château ; boucle par la ruelle et la terrasse de l'auberge ; accès futurs bloqués : A chantier (est),
   B caravane (faubourgs ouest), C gardes et grille (château). **V** : caméra A / B ; **L** : libellés. La V0.7-A reste en
   référence (`ville_v07a.tscn`). Rapport : `docs/P7_5_VILLE_V07B.md`.
   **Branche `p7-6-tranche-architecturale`** (PILOTE, NON validé) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** :
   la V0.7-B consolidée (sortie du Colisée par un vestibule et une porte au sud, arrivée devant les grandes portes, portail
   dégagé, faux passage du bras est fermé, anomalies d'affichage corrigées, volumes entre la caméra et Aren escamotés),
   entrées des bâtiments (E au seuil : instance à venir) et **première tranche architecturale** autour de l'auberge-taverne
   et de la ruelle des Tonneliers (`--tranche=0` : blockout ; `--coupe_ville=0` : trame d'origine). Le Colisée (F6
   `scenes/p6/colisee.tscn`) a son nouveau vestibule de sortie. Rapport : `docs/P7_6_TRANCHE_ARCHITECTURALE.md`.
   **Branche `p7-7-controles-composants`** : F5 inchangé. Contrôles avant la grande place : masquage net des bâtiments
   conservé (`--escamotage=fondu` : essai), maillages de la tranche fusionnés par matière, muret à jardinière plantée
   (`--muret=haie` : P7.6), profilage `tools/p7/profil_gpu_p77.gd` (à lancer sur votre machine), **catalogue des composants
   en F6 : `scenes/p7/catalogue_archi_p77.tscn`** (← / →). Plan de la grande place à valider. Rapport :
   `docs/P7_7_CONTROLES_COMPOSANTS.md`.
   **Branche `p7-8-grande-place-lot1`** : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** : grande place revêtue et
   fontaine octogonale à deux vasques (lot 1 ; `--place=0` : blockout). Rapport : `docs/P7_8_GRANDE_PLACE_LOT1.md`.
   **Branche `p7-9-forge-comparatif`** : F5 inchangé. Comparatif de la forge-armurerie en **F6** :
   `scenes/p7/ville_v07b_forge_a.tscn` (bibliothèque du projet), `…_forge_b.tscn` (Quaternius), `…_forge_c.tscn`
   (hybride) ; `scenes/p7/ville_v07b.tscn` garde la forge du blockout. Rapport : `docs/P7_9_FORGE_COMPARATIF.md`.
   **Branche `p7-10-forge-boutique`** (EN ATTENTE de validation) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** :
   forge-armurerie **C+** (base de production : toit en terre cuite, cheminée, enseigne, atelier de la cour, baie cintrée)
   et **boutique de fournitures** (`--forge=0` : forge du blockout ; `--boutique=0` : boutique du blockout). Les scènes
   `ville_v07b_forge_a/b/c.tscn` restent pour comparaison (C = C+). Rapport : `docs/P7_10_FORGE_BOUTIQUE.md`.
   **Branche `p7-10-1-forge-refonte`** (EN ATTENTE de validation artistique) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** :
   forge-armurerie **D** (refonte de C+ : entrée en embrasure dans un avant-corps de pierre, façade maçonnée en épaisseur,
   foyer à hotte et souche de cheminée, enseigne en fer forgé). Avant / après : `scenes/p7/ville_v07b_forge_c.tscn` (C+ de
   P7.10) ou `--forge=C` ; `--forge=0` : blockout. Boutique inchangée. Rapport : `docs/P7_10_1_FORGE_REFONTE.md`.
   **Branche `p7-11-boutique`** (EN ATTENTE de validation artistique) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** :
   forge D (approuvée, avec son correctif de pignon et d'appentis) et **boutique de fournitures P7.11** : devanture peinte en
   embrasure, étages en pan de bois sur encorbellement, pignon sur rue, enseigne au flacon, étal déplacé à l'angle ouest.
   Avant / après : `scenes/p7/ville_v07b_boutique_710.tscn` (boutique P7.10) ou `--boutique=710` ; `--boutique=0` :
   blockout. Rapport : `docs/P7_11_BOUTIQUE.md`.
   **Branche `p7-12-quartier-civique`** (EN ATTENTE de validation artistique) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** :
   forge D et boutique P7.11 approuvées ; **quartier civique et perspective du château** (volées et soutènements de pierre,
   balustrades, administration à porche, corps de garde, porte fortifiée, remparts, château lointain sur l'axe ; `--civique=0` :
   état P7.11). Rapports : `docs/P7_12_QUARTIER_CIVIQUE.md`, audit du projet `docs/AUDIT_P7_12.md`.
   **Branche `p7-12-1-civique-consolidation`** (EN ATTENTE) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** : cadrage stable
   pendant les examens, escamotage des seules parties hautes des bâtiments, porte ouverte sur une rampe et un château
   lointain (plongée adoucie sur la terrasse et l'avenue), corps de garde et pavillon de raccord en calcaire clair. Options :
   `--visee_dialogue=1`, `--escamotage_partiel=0`, `--plongee_civique=0` (comportements précédents). Rapport :
   `docs/P7_12_1_CONSOLIDATION_CIVIQUE.md`.
   **Branche `p7-12-2-coherence-terrasse`** (EN ATTENTE) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** : portes et
   ouvertures du quartier civique rendues cohérentes, **terrasse du belvédère** accessible de plain-pied depuis le palier de la
   volée C (tables, balustrades, vue sur la place), escamotage avec marge de réapparition et coupe finie (plancher et arase de
   pierre). Options : `--escamotage_partiel=0` (escamotage P7.6), `--escamotage_delai=<s>` (marge de réapparition, 0,6 s).
   Rapport : `docs/P7_12_2_COHERENCE_TERRASSE.md`.
   **Branche `p7-13-bordures-place`** (EN ATTENTE) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** : buvette du belvédère,
   herse du château baissée (grille retirée), portes et pignons corrigés, bordures de la grande place (draperie, étals de
   marché, halle sur quai), scintillements de faces coplanaires corrigés. Options : `--herse=relevee` (porte P7.12.2),
   `--bordures=0` (bordures en blockout), `--ombres_ville=200` (essai d'ombres en 4 tranches, à juger sur GPU).
   Rapport : `docs/P7_13_BORDURES_PLACE.md`.
   **Branche `p8-0a-cadrage-ville`** (EXPÉRIENCE, aucun angle retenu) : F5 inchangé, ville et Colisée inchangés par
   défaut. Comparaison des plongées de la ville : **F6 sur `scenes/p7/ville_v07b.tscn`** = 11° (référence P7.13, plongée
   civique 6,5° comprise), **`ville_v07b_p80a_16.tscn` / `_20` / `_24`** = 16° / 20° / 24° (même champ, même zoom, même
   suivi ; plongée civique coupée pour comparer à angle constant). Options : `--plongee_ville=<degrés>`,
   `--plongee_civique=1|0`. Parcours de comparaison : `--route=p80a_cadrage` (ou `p80a_cadrage_course`). Rapport :
   `docs/P8_0A_CADRAGE.md`.
   **P8.0-A2** (même branche) : 11° reste la référence. Essais **`ville_v07b_p80a_13.tscn` / `_14.tscn`** (13° / 14°, plongée
   civique 6,5° conservée) et zone de lecture facultative sur la terrasse du belvédère **`ville_v07b_p80a2_zone17.tscn`**
   (`--zone_lecture=17|18`) ; parcours `p80a_cadrage` complété (R6 belvédère). Diagnostic des premiers plans : rapport § P8.0-A2.
   **Branche `p8-0b-lumiere`** (EXPÉRIENCE, P8.0-A clos : 11° et 6,5° retenus) : F5 inchangé. Premiers plans corrigés (toits de la
   tranche en terre cuite, coupes de l'auberge et de la Guilde sous la place, parapet de la porte sud ; `--toits_p80b=0`,
   `--coupes_p80b=0`). Profils de lumière : **A = P7.13** (défaut), **B = proposition HD-2D** (`--lumiere=b` ou F6
   **`scenes/p7/ville_v07b_p80b.tscn`** ; **touche F4** : A <-> B en jeu ; étapes `--b_jusqua=1..5`, effets séparés `--b_*`).
   **Reprise du 27/11** (vérifiée sous Godot 4.7.2) : dessus de pierre de la porte sud corrigé ; B en **second dosage**
   (moins orangé, ombres plus froides et plus profondes, SSAO renforcé ; `--b_version=1` : premier dosage) ;
   `--b_tonemap=a` : sprites traités exactement comme en A. Rapport : `docs/P8_0B_LUMIERE.md` (§ 7).
   **Branche `p8-0c-consolidation`** : F5 inchangé. **Lumière B (second dosage) retenue** par le créateur ; la ville démarre
   encore en A tant que les performances de B ne sont pas validées sur GPU (F6 `ville_v07b_p80b.tscn` ou `--lumiere=b` pour B,
   F4 pour comparer). Mesures, nettoyage du code et contrôles : `docs/P8_0C_CONSOLIDATION.md`.
   **Branche `p8-1a-finition-quartier`** (EN ATTENTE de revue) : F5 inchangé. **F6 sur `scenes/p7/ville_v07b.tscn`** (ou
   `ville_v07b_p80b.tscn` en lumière B) : quartier finalisé avant les PNJ. Sols et soutènements en pierre, façade du Colisée à
   arcades, bâtiments secondaires et fonds habillés, jardinières plantées, limites en bois et pierre, marchandises
   reconnaissables. Comparaison : `--finition=0` (état P8.0-C) ou un lot seul, `--f_sols|f_colisee|f_batiments|f_vegetation|f_limites|f_etals=0`.
   Rapport : `docs/P8_1A_FINITION.md`.

### Commandes — forêt V07B (F5)

| Touche | Action |
|---|---|
| Flèches / ZQSD | se déplacer ; **Maj** maintenue : courir |
| **1 / 2 / 3** | zoom ×2 / ×2,5 (référence de la caméra P30) / ×3 (démarrage) |
| **4 / 5 / 6** | inclinaison de la caméra : 30° (référence de la caméra P30) / 27° / 24° (démarrage) |
| **O** | occlusion dynamique : active (défaut) / coupée |
| **B** | animations d'Aren : **V09B.5** (démarrage) / **P4.8** (secours) — V09B.5 (marche et course distinctes, **profil droit seulement** ; autres directions et attente restent P4.8) — essai **non validé** |
| **T** | format des cycles : **96×112 — hauteur 64 px** (démarrage) / 96×112 (88–91 px) (mêmes PNG, affichés à ×0,719 : taille d'Aren P4.8) / 64×72 (réductions du pack) / **calque 64 px** (V09B.6 : poses V09B.5 à l'échelle P4.8, réduction automatique, **non dessinée**) / `dessin_64` (poses redessinées, quand elles existeront) |
| **G** | Aren vers le haut / le bas : **V4 dessinée** (démarrage, GIF du créateur du 20/11, proposition) → V3 « en profondeur » (**procédurale**) → 4dir du 20/11 (procédurale) → planche V2 → V4 |
| **U** | sol : **P5.3-B V3 hybride** (démarrage) → V2 transitions → V2 actuelle → V1 + calage → V1 brute → P5.3 → P5.2 figé → V07 d'origine — collisions identiques |
| **Y** | pilote P5.3-B : textures peintes sur **toute la carte** (test de répétition) / zone pilote |
| **J** | ombres douces du soleil : **qualité 4** (démarrage, essai à confirmer sur GPU) / 2 (défaut du projet) |
| **K** | rendu des personnages : **Sprite3D d'origine** (démarrage, choix du créateur du 20/11) / V10 (comparaison : pixels moyennés, soleil sans ternir, pas de brume sur le sprite, contour d'un pixel) — même dessin |
| **P** | vitesses : **actuelles** 2,2 / 3,6 m/s (démarrage) / **candidates** 2,8 / 4,5 m/s (marche / course) |
| **I** | Ilya (vers le haut / le bas : face / dos dessinées du pack V09C.5) : **V09C.6** (démarrage) → P4.8 → V09C.5 → V09C.6 (V09C.6 = course droite nouvelle, le reste V09C.5) ; nouvelle apparence en **banc d'essai non validé** (4 directions, échelle mesurée ×0,719, course choisie d'après sa vitesse réelle) |
| **L** | locomotion : V09A, essai **non validé** (inertie légère, Ilya suit la trace d'Aren ; défaut) / V08 (déplacement précédent) |
| **C** | diagnostic des collisions : obstacles (orange), eau (turquoise), bords (violet), pentes 35°–45° (jaune), > 45° (rouge) |
| **N** | masquer la végétation (et ses collisions) ; **M** : repères des parcours |
| **V** | eau animée (shader candidat) ; **F** : brume (coupée au démarrage depuis V11) ; **H** : interface ; **R** : retour au départ |

### Commandes — Colisée, ouverture (F6 sur `scenes/p6/colisee.tscn`)

| Touche | Action |
|---|---|
| Flèches / ZQSD | se déplacer ; **Maj** maintenue : courir |
| **E** / Entrée / Espace | parler, examiner ; faire avancer le dialogue ; ↑ / ↓ puis E : choisir une réponse |
| **Molette** (ou PgPréc / PgSuiv) | zoom ×2 / ×2,5 / ×3 |
| En combat tutoriel | Entrée / Espace / clic : suite de l'explication ; puis commandes habituelles du combat ; Échap : refusé |
| **C** / **B** / **H** / **J** | caméra (A / B / C) ; apparence d'Aren (forêt / P4.8) ; habillage (pilote / blockout) ; transitions des intérieurs (A / B / C) |
| **P** | parcours automatique (avant ou après le tutoriel) ; **F1** : informations |

### Autres scènes (ouvrir dans l'éditeur, puis **F6**)

Classement de l'audit P7.12 (`docs/AUDIT_P7_12.md`). Aucun chemin ne change ; les retraits attendent la validation du
créateur.

**Scènes jouables**

| Scène | Contenu |
|---|---|
| `scenes/p7/ville_v07b.tscn` | **Ville de référence (V0.7-B, P7.5 à P7.12)** : grande place et fontaine, forge D, boutique P7.11, quartier civique et porte du château, tranche de l'auberge et ruelle des Tonneliers, entrées des bâtiments, caméras A / B (touche V) |
| `scenes/p7/ville_v07b_p80b.tscn` | **P8.0-B — ville, lumière B** (proposition HD-2D ; F4 : A <-> B) |
| `scenes/p7/ville_v07b_p80a_13.tscn` | **P8.0-A2 — ville, plongée 13°** (plongée civique 6,5° conservée) |
| `scenes/p7/ville_v07b_p80a_14.tscn` | **P8.0-A2 — ville, plongée 14°** (plongée civique 6,5° conservée) |
| `scenes/p7/ville_v07b_p80a2_zone17.tscn` | **P8.0-A2 — 11° + zone de lecture à 17° sur la terrasse du belvédère** (facultative) |
| `scenes/p7/ville_v07b_p80a_16.tscn` | **P8.0-A — ville, plongée 16°** (expérience de cadrage ; 11° = `ville_v07b.tscn`) |
| `scenes/p7/ville_v07b_p80a_20.tscn` | **P8.0-A — ville, plongée 20°** (proche de l'arène du Colisée) |
| `scenes/p7/ville_v07b_p80a_24.tscn` | **P8.0-A — ville, plongée 24°** (essai fortement plongeant) |
| `scenes/p6/colisee.tscn` | **P6 — ouverture du jeu** : Colisée de Val'Serra, tutoriel, sortie vers la ville |
| `scenes/battle/combat_tutoriel.tscn` | P6 — combat tutoriel seul (retourne au Colisée à la fin) |
| `scenes/battle/combat_foret.tscn` | **P5 — combat refondu** : groupe à gauche, Vorgane à droite, décor = la forêt d'exploration |
| `scenes/battle/battle_scene.tscn` | combat seul (avec `--start=proto-battle --arena=lisiere` ou `--arena=foret` en ligne de commande) |

**Outils de développement**

| Scène | Contenu |
|---|---|
| `scenes/p7/catalogue_archi_p77.tscn` | **P7.7 — catalogue des composants architecturaux** : façades, fenêtres, volets, portes, balcons, toits (← / →) |
| `tests/test_runner.tscn` | tests automatiques dans l'éditeur |

**Comparaisons et prototypes — options en ligne de commande** (scènes F6 retirées en P7.12.2 ; restauration :
`docs/P7_12_2_COHERENCE_TERRASSE.md` § D)

| Scène | Contenu |
|---|---|
| `scenes/p7/ville_v07b.tscn` + `--forge=C` | P7.10 — forge C+ « avant » la refonte D (comparaison) |
| `scenes/p7/ville_v07b.tscn` + `--lumiere=a\|b` | P8.0-B — profils de lumière A (référence) / B (retenu) ; F4 en jeu |
| `scenes/p6/colisee_tunnel_A_6_5m.tscn` | P6.2-D — tunnel sud de 6,5 m (comparaison ; `colisee.tscn` = 9 m depuis P7.4.1) — proposé séparément |
| `scenes/p6/colisee_tunnel_B_8_5m.tscn` | P6.2-D — tunnel sud de 8,5 m (comparaison) — proposé séparément |
| `scenes/p6/colisee_tunnel_C_9_5m.tscn` | P6.2-D — tunnel sud de 9,5 m (comparaison) — proposé séparément |

**Retirés en P8.0-C** (historique Git, commit `588e90c`) : villes V0.1 / V0.6 / V0.7-A (`--ville=v05|v06|v07a`), forges A / B
(`--forge=A|B`), boutique P7.10 (`--boutique=710`). Détail : `docs/P8_0C_CONSOLIDATION.md`.

Les options s'ajoutent après `--` (par exemple `godot --path . res://scenes/p6/colisee.tscn -- --etat=tutorial_completed`,
ou `godot --path . res://scenes/p7/ville_v07b.tscn -- --forge=C`) ; dans l'éditeur : **Débogage → Personnaliser les instances
d'exécution** (arguments de lancement), puis F6 sur la scène indiquée.

## Vérifications

**Série complète de non-régression (P8.0-C)**, une ligne OK / ÉCHEC par contrôle (≈ 25 min) :

```bash
bash tools/p8/non_regression_p80c.sh
```

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

```bash
godot --headless --path . --script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide
```

```bash
godot --headless --path . --script res://tests/e2e_p6_saut_tutoriel.gd
```

```bash
godot --headless --path . res://scenes/p6/colisee.tscn -- --route=p6_sondes --quit --neuf --etat=tutorial_available --out=/tmp/p6
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/traversees_v08.gd -- --out=/tmp/v08
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/occlusion_v07.gd -- --out=/tmp/occ
```

```bash
godot --headless --path . --script res://tests/v09_locomotion_smoke.gd
```

```bash
godot --headless --path . --script res://tests/v09b5_anim_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/animations_v09b5.gd -- --out=/tmp/v09b5
```

```bash
godot --headless --path . --script res://tests/v09c_ilya_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tests/v11_collisions_smoke.gd
```

```bash
godot --headless --path . --script res://tests/p5_combat_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tests/p52_sol_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tests/p53b_pilote_smoke.gd
```

```bash
godot --headless --path . --fixed-fps 60 --script res://tools/p49/ilya_v09c.gd -- --out=/tmp/v09c
```

```bash
python3 tools/p49/v09b6_gabarit.py <dossier du pack V09B.5 décompressé>/ValSerra_V09B5_Aren_Marche_Course_Revue/
```

Dans l'ordre : tests automatiques (80, dont 9 pour P6), ouverture P6 de bout en bout (Colisée → tutoriel → retour →
sortie), sondes de collision du Colisée (10), forêt V07B : 18 traversées hors des chemins (marche et course) et 12 scénarios
d'occlusion, test de locomotion V09A, test des animations V09B.5 (12), mesures V09B.5 (vitesses, cadence, glissement
des pieds, demi-tours, Ilya ; P4.8 et V09B.5, vitesses actuelles et candidates).

## Où trouver quoi

| Sujet | Fichiers |
|---|---|
| Forêt V07B (F5) : scène, modèles, manifeste | `ValSerra_P49_V07B_PREFLIGHT_GODOT/` (`godot/`, `assets/`, `docs/V07_WORLD.json`) ; occlusion `src/occlusion/` ; diagnostic des collisions `src/diag/` ; outils de test `tools/p49/` |
| Habillage de base (hérité par le Colisée) | `scenes/p4/avant_poste.gd` ; shaders `src/p4/` (avant-poste retiré en P7.2) |
| Socle d'exploration 2.5D | `src/explore25/` (monde, session, caméra, acteurs, parcours), `scenes/explore25/explore_3d.gd` |
| Personnages (exploration, combat, portraits) | `art/p45/` (`SOURCES.md`), outil `tools/p45/build_p45.py` ; Vorgane d'exploration `art/p45/chars/vorgane/` |
| Décor de la zone | `art/p4/` (`SOURCES.md`), décor nettoyé `art/p41/decor/` ; outils `tools/p4/`, `tools/p41/` |
| Combat | `scenes/battle/`, règles `src/combat/`, données `data/combat/`, présentation `src/presentation/`, `src/proto/` |
| Arène de combat | `art/arena/lisiere/`, `src/presentation/arena_layers.gd`, outils `tools/arena/` |
| Dialogues | `data/p6/dialogues_colisee.json`, `data/dialogue/` ; portraits : `src/proto/portraits.gd` |
| Tests | `tests/` |

## Documentation

| Document | Contenu |
|---|---|
| `docs/P4_9_V07B.md` | **P4.9** : forêt V07B (intégration, Forward+), inclinaisons 30° / 27° / 24° et occlusion, navigation libre V08A (18 traversées, corrections, F5) |
| `docs/P4_9_V09C.md` | **V09C** : décisions du 19/11/2026 (Aren V09B.5 ×0,719 retenu, nouvelle identité d'Ilya), besoins techniques et cahier des charges du pack d'Ilya, vérificateur `tools/p49/verif_pack_v09c.py` |
| `docs/HISTORIQUE.md` | où retrouver les rapports et médias des étapes précédentes (branches Git) |
| `docs/ASSETS.md` | registre des ressources et de leurs conditions d'usage |
