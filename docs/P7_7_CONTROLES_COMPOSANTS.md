# P7.7 — Contrôles techniques, composants architecturaux et plan de la grande place

Branche **`p7-7-controles-composants`**, créée depuis `p7-6-tranche-architecturale`.

Validations de votre retour du 25/11/2026 :
* la direction de la tranche (rez-de-chaussée de pierre, étages enduits, façades de plusieurs niveaux, toits de tuiles) ;
* la sortie du Colisée ;
* le muret de 0,6 m.

Cette étape fait les cinq contrôles demandés et prépare la grande place. **Elle ne l'habille pas encore** : son plan de
réalisation est à valider d'abord (§ 6). Aucune scène n'est étendue, aucun intérieur créé, aucune entrée déplacée.

## Avertissement sur le rendu de cet environnement

Ce conteneur n'a pas de carte graphique. Le journal de Godot le confirme : « Required Vulkan instance extension
VK_KHR_surface not found … switching to OpenGL 3 ». **Toutes les captures et vidéos** (celles de cette étape comme celles des
précédentes) passent donc par le **moteur de rendu « Compatibilité » (OpenGL), exécuté sur le processeur** (llvmpipe), et
non par Forward+. D'où deux conséquences :
* les temps mesurés ici ne disent rien de votre machine ;
* certaines fonctions propres à Forward+ ne s'y voient pas : c'est le cas du fondu, au § 1.

## 1. Masquage des bâtiments par la caméra : instantané ou fondu

Les deux modes sont implémentés et comparés sur le même trajet `p7_77_escamotage` : flanc de la Guilde, bras est (auberge),
ruelle, rue du chantier, montée, puis retour le long de la Guilde.

| Mode | Fonctionnement |
|---|---|
| `--escamotage=net` (**défaut, retenu**) | Le volume disparaît d'une image à l'autre |
| `--escamotage=fondu --fondu_s=0.15` | La transparence d'objet de chaque maillage du volume (`GeometryInstance3D.transparency`) passe de 0 à 1 en 0,15 s. Aucune trame |

**Stabilité**, avec chaque bascule journalisée (« P7 escamotage ») :
* chaque volume ne bascule qu'**une fois** par passage ;
* l'écart minimal entre deux bascules d'un même volume est de **6,6 s** : aucun clignotement ;
* les bascules sont identiques dans les deux modes.

**Constat sur le fondu** (`escamotage_net_fondu.jpg`, une image tous les 1/30 s) : ici, le fondu n'a **aucun effet visible**.
Le bâtiment reste opaque, puis disparaît d'un coup à la fin du fondu. C'est un retard, pas un fondu.

Je l'ai vérifié par un essai fixe (`tools/p7/essai_transparence_p77.gd`) : à 0, 0,5 puis 0,9 de transparence sur les
527 maillages de l'auberge, les trois images sont identiques. La transparence d'objet n'agit pas dans le moteur
« Compatibilité ».

En Forward+, elle agirait, mais en faisant passer le bâtiment **dans la passe transparente** pendant 0,15 s. Les pièces d'un
même bâtiment (murs, encadrements, volets, toit) n'y sont plus triées par profondeur : c'est la « transparence incorrecte »
que vous voulez éviter. Un fondu tramé est exclu (c'est le tramage).

**Recommandation : garder le masquage net**, stable, lisible et sans artefact. Le fondu reste disponible pour un essai sur
votre machine (§ 2, point 4) : s'il vous paraît propre en Forward+, il suffit de changer la valeur par défaut.

## 2. Profilage du secteur pilote

**Outil fourni : `tools/p7/profil_gpu_p77.gd`.** Il parcourt dix points de vue, sept dans la tranche et trois témoins en
blockout. Pour chacun, la caméra de jeu se stabilise 2 s, puis l'outil mesure pendant 4 s, synchronisation verticale coupée.

| Grandeur relevée | Source |
|---|---|
| Durée réelle de l'image | horloge, entre deux images |
| Temps de rendu CPU et GPU mesurés par le moteur | `RenderingServer.viewport_get_measured_render_time_cpu` / `_gpu` |
| Appels de dessin, primitives, objets | `RenderingServer.get_rendering_info` |
| Mémoire vidéo, identité de la carte et du pilote | moteur |

Sortie : un tableau dans la console et un CSV (moyenne, p95, max par point).

**Ce que l'environnement permet de mesurer ici** : seulement les compteurs, qui ne dépendent pas de la carte. Les temps
(130 à 200 ms par image, rendu sur le processeur) ne sont pas significatifs.

| Point de vue | Blockout | Tranche P7.6 (sans fusion) | Tranche P7.7 (avec fusion) |
|---|---|---|---|
| T1 terrasse de l'auberge | 1 304 appels | **3 129** | **1 319** |
| T2 pied de la ruelle | 1 205 | 3 076 | 1 234 |
| T6 rue du chantier | 1 248 | 3 255 | 1 287 |
| T7 placette | 1 524 | 3 062 | 1 530 |
| Primitives (T1) | 26 000 | 82 000 | 86 000 |

**Défaut trouvé et corrigé.** Chaque pierre d'encadrement, volet ou barre était un maillage séparé : la tranche
multipliait les appels de dessin par **2,4**. Les composants **fusionnent maintenant les maillages statiques par matière**,
bâtiment par bâtiment (`Archi.fusionner`).
* La tranche revient au niveau du blockout : environ +1 à +3 % d'appels.
* Le rendu est identique au pixel près sur 6 des 8 vues de la tranche. Les deux différences corrigent un défaut de P7.6 :
  des fenêtres de la maison du bras est et les murs d'échiffre de l'escalier étaient rattachés au mauvais bâtiment, et
  disparaissaient avec lui.
* Sans fusion : `--fusion=0`.

CSV : `profil_llvmpipe_*.csv`.

**À relever sur votre machine** (avec rendu, pas `--headless` ; fermer les autres applications) :
1. Commandes, en 1920 × 1080 puis en 1280 × 720 :
   * `godot --path . --script res://tools/p7/profil_gpu_p77.gd -- --resolution=1920x1080`
   * puis la même avec `--tranche=0` (blockout), pour obtenir le coût propre de la tranche.

   Le CSV est écrit dans `user://` ; son chemin s'affiche à la fin.
2. Pour chaque point, sur la ligne « PROFIL » : image moyenne et p95 (ms), GPU moyen et p95 (ms), CPU (ms), appels,
   primitives. Et la ligne « PROFIL MACHINE » : carte, pilote, API, processeur, mémoire vidéo.
3. Dans l'éditeur, lancer `scenes/p7/ville_v07b.tscn` (F6), puis ouvrir le panneau **Débogueur** :
   * **Profileur visuel**, sur la terrasse de l'auberge et au pied de la ruelle : temps GPU des passes « Opaque »,
     « Shadow » et « Sky », et part des matières procédurales ;
   * **Moniteurs** : « Draw Calls », « Primitives » et « Video Mem », en marchant dans la tranche.
4. Juger à l'œil `--escamotage=fondu` contre le mode par défaut, en passant sous l'auberge depuis le bras est : artefacts de
   tri pendant 0,15 s ou non.

**Seuils proposés pour autoriser la généralisation** : à 1080p sur votre machine, image p95 ≤ 16,7 ms (60 i/s), et coût de
la tranche (avec contre sans) ≤ 15 % du temps GPU.

## 3. Raccord visuel du vestibule de sortie du Colisée

Contrôle sur huit points de vue (`vestibule_controle_8_vues.jpg`) : arène est, tunnel est, coursive, coursive sud, couloir,
vestibule, porte et infirmerie.
* Les murs se raccordent sans jour et sans face confondue.
* La porte se lit : encadrement, battants rabattus, jour sur le seuil.
* Le vestibule suit la même convention que les autres pièces : fond sombre, murs côté caméra coupés bas, plafond en ombre
  seulement.

**Aucune correction nécessaire.** Rien n'est modifié dans le Colisée.

## 4. Muret bas : finition

Le muret garde ses 0,6 m. La haie uniforme de volumes verts devient une **jardinière plantée** (composant
`Archi.jardiniere`) :
* couvre-sol continu ;
* touffes d'arbustes de tailles et de verts variés, sur deux rangs ;
* taches de fleurs (lavande, ocre, blanc) ;
* deux pots de terre cuite ;
* lisière de pierre.

Hauteur au plus 0,8 m. Le tirage est déterministe, et tout tient en deux maillages groupés.

Média : `muret_haie_vs_jardiniere.jpg`. La haie de P7.6 reste visible avec `--muret=haie`.

## 5. Composants architecturaux réutilisables

**Bibliothèque `scenes/p7/archi_p77.gd`**, sans état de scène ni collision. Elle a été extraite de la tranche, qui la
réutilise : ses valeurs par défaut reproduisent la tranche P7.6 au pixel près. Un bâtiment se décrit par un dictionnaire ;
le format est documenté en tête du fichier.

| Famille | Variantes |
|---|---|
| Palettes (enduit, volets) | miel, ocre, gris chaud (P7.6), rose, crème, terre |
| Rez-de-chaussée / étages | pierre, bossage, enduit / enduit, pierre |
| Modénature | bandeaux d'étage, corniche simple ou à consoles, chaînes d'angle ou non, soubassement |
| Fenêtres | croisée, simple, cintrée (arc de claveaux), porte-fenêtre, œil-de-bœuf, grille à barreaux, grande baie de salle |
| Volets | pleins, persiennes, fermés, aucun |
| Portes | planches, cloutée (pentures), vitrée, cochère (cintrée), devanture fermée, vitrine de boutique à auvent rayé |
| Balcons | sur consoles avec garde-corps de fer, balustrade de pierre, balconnet |
| Toitures | deux versants (faîtage est-ouest ou nord-sud), croupes, appentis ; cheminées |
| Divers | lanterne murale, jardinière plantée, fusion des maillages par matière |

**Catalogue F6 : `scenes/p7/catalogue_archi_p77.tscn`.** Il utilise l'éclairage et la caméra de la ville, sur six vues
(← / →). Médias : `catalogue_facades.jpg` (six façades complètes, et la rangée à 22 m) et `catalogue_baies_portes.jpg`.

**Limites, à arbitrer avant la grande place.**
* Les arcs et l'œil-de-bœuf sont faits de claveaux en boîtes : la silhouette se lit à 22 m, mais on voit les facettes de près.
* L'auvent de vitrine est rayé de la couleur des volets.
* La toiture « croupe » et l'« appentis » n'ont pas encore servi dans la ville.

## 6. Plan de réalisation de la grande place (P7.8, à valider)

Plan annoté : `plan_grande_place.png`. Les emplacements, les collisions et les entrées fonctionnelles (forge à x 51, boutique
à x 78) restent ceux de la V0.7-B. Les trois terrasses ne changent pas.

| Lot | Contenu | Règles |
|---|---|---|
| **1. Sol et fontaine** | Dallage `dallage2` à calepinage de place (bandes de pierre, cercle autour de la fontaine, caniveaux). **Fontaine aboutie** : bassin octogonal à margelle, pile centrale à deux vasques, quatre bouches, surface d'eau animée sans transparence (un petit shader dédié) | La collision de la fontaine (6 × 6 m) devient un octogone ajusté au bassin : aucune collision invisible aux angles. Élément central ≤ 2,8 m et élancé (moins de masquage d'Aren que la colonne actuelle) |
| **2. Forge-armurerie** | Rez-de-chaussée de pierre en bossage, grande baie d'atelier à lueur de foyer (émissive), entrée fonctionnelle conservée, enseigne à l'enclume, haute cheminée de forge. Cour de l'atelier à l'ouest (sur les étals bas) : appentis de tuiles, établi, râtelier, tas de charbon | Volumes de décor plus hauts que leurs collisions seulement là où l'on ne peut pas marcher (fond nord) |
| **3. Boutique de fournitures et recoin** | Deux niveaux, vitrine à auvent, porte vitrée (entrée conservée), caisses et tonneaux contre la façade. Commerce voisin à trois niveaux, balcon | Accessoires posés contre les façades, avec collision ; circulation du recoin inchangée |
| **4. Fond nord** | Montée civique traitée en escalier monumental de pierre (balustres, socle), arrière-forge en terrasse balustrée, façade sud de l'administration (étages de pierre, corniche à consoles) | Hauteurs libres : c'est le fond de l'image |
| **5. Étals de bordure** | Les quatre étals deviennent des échoppes de bois à auvent, avec des marchandises | Pas de seconde place de marché ; aucun étal sur les axes |
| **6. Bord sud** | Parapet balustré au-dessus du vide de 3,5 m (côté caméra) | Hauteur ≤ 1 m, ajouré : Aren reste visible depuis la placette et la montée |

**Méthode.**
* Composants de la bibliothèque seulement, avec fusion par matière.
* Budget mesuré par l'outil de profilage, auquel s'ajoutent des points de vue sur la place : appels de dessin au plus +15 %
  par rapport au blockout.
* Sondes et trajets existants, et camera_volumes_p76 (0 recouvrement attendu).
* Captures avant / après et vidéo de traversée.
* Commits séparés par lot.
* Le reste de la ville reste en blockout.

## Tests (état final)

| Test | Résultat |
|---|---|
| Tests unitaires | 76 sur 76 |
| Ouverture P6, saut du tutoriel | réussis |
| `p6_sondes` | 10 sur 10 |
| F5 (chargement), V11 | sans erreur, 0 échec |
| Arène depuis les vestiaires | aucun maillage visible |
| Chargement V0.5, V0.6, V0.7-A, V0.7-B et du catalogue | sans erreur |
| Sondes V0.7-B, A et B | 40 sur 40 |
| Trajets V0.7-B, A et B | 28 sur 28 |
| Portail ville ↔ Colisée, A et B | 4 passages alternés |
| Parcours des corrections P7.6 | 21 étapes sur 21 |
| Recouvrements de volumes | 0 |
| Refactorisation (8 vues de la tranche) | identique au pixel près |

## Fichiers

| Fichier | Contenu |
|---|---|
| `scenes/p7/archi_p77.gd` | Composants, variantes, jardinière, fusion |
| `scenes/p7/catalogue_archi_p77.gd` / `.tscn` | Catalogue F6 |
| `scenes/p7/tranche_p76.gd` | Descriptions de la tranche sur la bibliothèque ; muret à jardinière ; fusion des sols, de l'escalier et du muret |
| `scenes/p7/ville_v07b.gd` | Masquage net ou fondu, journal des bascules |
| `scenes/p6/colisee.gd` | Transmission du pas de temps au masquage |
| `tools/p7/profil_gpu_p77.gd` | Profilage |
| `tools/p7/essai_transparence_p77.gd` | Essai de la transparence d'objet |
| `tools/p7/plan_grande_place_p77.py` | Plan des lots |
| `src/explore25/routes25.gd` | Parcours `p7_77_escamotage`, `p7_77_muret`, `p7_77_vestibule` |
