# P6.4.2 — Extension artistique du Colisée

Branche **`p6-4-2-colisee-extension`**, issue de `p6-4-1-colisee-second-pilote`. Elle étend à tout le Colisée les choix
retenus par le créateur après le second pilote (23/11/2026) :
* **galerie B**, structure mixte (maçonnerie dominante, terrasse, parapets, arcades, bande couverte près des gradins) ;
* **porte C** de la réserve (coupe à taille réelle, seuil, jambages, ferrure, petit cadenas d'approche) ;
* **mur** des vestiaires du second pilote (calcaire ocre et gris chaud, détails peints discrets) comme référence ;
* **dallage enrichi** du second pilote (pas de troisième variante) ;
* **lumière des accès** : portes, passages, axes de circulation ; rien qui suive Aren.

C'est une **extension en attente de validation artistique** : rien n'est déclaré final.

Sont inchangés : Godot 4.7.2 ; caméra du Colisée (azimut 0°, plongée 24°, champ 30°, ×3) et ses limites communes ;
tunnel sud de 8,5 m ; mode B de visibilité ; ombres douces qualité 4 ; collisions, circulation, dialogues, progression,
CombatCore, combat tutoriel et son saut ; sprites et animations ; F5 (forêt) et sa caméra. **Aucun asset importé**,
aucun modèle ajouté, aucune texture inventée. Rien n'a été fait sur la ville.

Les mesures sont faites en **rendu logiciel (lavapipe), sans GPU** : elles ne valent pas validation GPU.

**Comparer en jeu** (F6, `scenes/p6/colisee.tscn`) : la scène démarre sur l'extension.
* **M** : P6.3.2 → premier pilote → second pilote → **extension P6.4.2** (`-- --p64=0|1|2|3`) ;
* **K** : galerie (B par défaut en P6.4.2 ; `-- --galerie=A|B|p64`) ;
* **U** : porte (C par défaut).

## Livrables

| | |
|---|---|
| Rapport | ce fichier |
| Avant / après, mêmes cadrages (avant = second pilote P6.4.1 tel que livré, après = extension) | planches ci-dessous, `docs/media/p6_4_2/` |
| Vidéo continue, vitesse réelle : vestiaires → salle d'attente → tunnel sud → arène → tutoriel passé → tunnel est → coursive (infirmerie, réserve) → sortie est | [`colisee_continu_p642.mp4`](media/p6_4_2/colisee_continu_p642.mp4) |
| Décor du combat tutoriel régénéré (gameplay inchangé) | `art/p6/combat/arene_colisee.png`, comparaison [`decor_combat_avant_apres.jpg`](media/p6_4_2/decor_combat_avant_apres.jpg) |

Planches avant / après (à gauche P6.4.1, à droite P6.4.2) :

| Zone | Planche |
|---|---|
| 1. Vestiaires · 2. Salle d'attente · 3. Tunnel sud | [`avant_apres_1_vestiaires_salle_tunnel.jpg`](media/p6_4_2/avant_apres_1_vestiaires_salle_tunnel.jpg) |
| 4. Arène et gradins · 5. Galerie et toiture (sud-ouest, sud-est, nord) | [`avant_apres_2_arene_galerie.jpg`](media/p6_4_2/avant_apres_2_arene_galerie.jpg) |
| 6. Tunnel est · 7. Coursive · 10. Sortie est | [`avant_apres_3_tunnel_est_coursive_sortie.jpg`](media/p6_4_2/avant_apres_3_tunnel_est_coursive_sortie.jpg) |
| 8. Infirmerie · 9. Réserve (depuis la coursive, depuis l'infirmerie) | [`avant_apres_4_infirmerie_reserve.jpg`](media/p6_4_2/avant_apres_4_infirmerie_reserve.jpg) |

Les captures sont faites par le parcours `p6_extension_captures` (`-- --p64=2` puis `--p64=3`), donc aux mêmes positions.

## 1. Anomalie de la vidéo P6.4.1 (vers 18 s)

**Diagnostic** : ce n'est **pas un défaut de la marche normale**, mais un défaut réel du **téléport**, que le montage
utilisait entre deux séquences (arène → coursive).
* Le grand fond brun est le **toit plat de la coursive** (`Toit_S6`), affiché tant qu'on est dans l'arène.
* Une téléportation ne recalait pas le système de visibilité : il basculait vers la coursive par son **fondu habituel**
  (≈ 0,3 s). Pendant ce temps, le toit recouvrait encore la pièce, et les murs de la coursive n'étaient pas encore
  revenus. D'où le grand aplat brun et l'architecture absente sur quelques images.
* En marche normale, on franchit les seuils pas à pas (arène → tunnel est → coursive) : le toit est retiré dès le
  tunnel est, avant que la coursive soit à l'écran. La vidéo continue de cette étape ne montre pas le défaut.

**Correction** (sans toucher à la caméra) : `colisee.teleport()` recale maintenant la visibilité **immédiatement**,
sans fondu, comme au chargement. Cela couvre les parcours de test, le montage et une éventuelle réapparition.

## 2. Ce qui a été étendu

### Principe : une matière par fonction, pas une matière partout

Toutes les surfaces visibles du Colisée passent dans les **matières hybrides du second pilote** : calepinage procédural
en mètres pour la stabilité, détails peints tirés de `sol_terre.png` et `sol_herbe.png` pour les nuances.

Ce qui varie d'une zone à l'autre (`habillage_p6.P642_ZONES`, appliqué par `mz(nom, zone)`) :
* la palette ;
* la valeur ;
* la salissure ;
* la mousse ;
* les coulures ;
* les réparations et les fissures ;
* le sol.

Le calepinage ne varie pas : on ne multiplie pas les variantes de matériaux.

| Zone | Murs | Sol | Intention |
|---|---|---|---|
| Vestiaires | mur du second pilote, **inchangé** (référence) | **plancher** procédural (lames de 18–22 cm, crasse dans les joints), bordure de dalles | chaleureux, intime |
| Salle d'attente | même appareil, un peu plus neutre et plus propre (mousse ÷ 2,5) | dallage enrichi | intérieur de service |
| Tunnels sud et est | plus sombres (valeur × 0,84), suie et humidité (coulures × 1,6, pied verdi), quelques fissures | **pavage de tunnel** : pierres plus petites, très usées, crasse dans les joints | passage sous les gradins |
| Arène, gradins, loge | pierre plus claire et chaude (× 1,06), lavée par la pluie (coulures × 1,35), peu de crasse ; **bois des assises grisé** par le soleil | sable inchangé ; dallage sous le sable visible aux bouches | à ciel ouvert |
| Coursive | réglages du second pilote, **inchangés** (référence) | dallage enrichi | circulation |
| Infirmerie | pierre plus claire et entretenue (crasse ÷ 2, mousse quasi nulle) | plancher clair, récuré | lieu de soins |
| Réserve | plus brute, poussiéreuse, plus de pierres de réparation et de fissures | plancher sombre et sale | pièce fermée |
| Couloir de sortie | un peu plus exposé (coulures, mousse) | dallage enrichi | proche de la rue |

### 2.1 Galerie, toiture et raccords architecturaux
* **Galerie B** sur tout le pourtour (variante du second pilote, réglages inchangés).
  * Les raccords entre gradins et galerie, les exclusions des passages et la fermeture des écoinçons restent ceux de P6.4.1.
  * Aucun sol n'est visible derrière les gradins sous les angles testés.
* **Variante A** : elle n'est **utilisée nulle part** en P6.4.2.
  * Aucune partie actuelle du bâtiment ne justifie une couverture complète en pente.
  * Les toits des intérieurs vus de l'arène sont plats. Les couvrir de tuiles sans pente aurait contredit la consigne sur
    les pentes.
  * A reste sur la touche K, et je n'ai pas mêlé A et B.
* **Toits des intérieurs** (vus de l'arène) : ce n'est plus un aplat brun uni, mais une **terrasse dallée**, de même
  matière que la terrasse de la galerie B. Le bâtiment se lit comme un ensemble de terrasses maçonnées.
* **Murs, corniches, soubassements, pilastres et linteaux** de toutes les pièces, dans l'appareil de leur zone. Les
  linteaux prennent la zone de la pièce la plus proche.
  * Les murs prolongés en mode B gardent leur découpage : assise moyenne, assise sombre, corniche, chaperon.
  * Les tranches des murs coupés gardent leur poché sombre.

### 2.2 Arène et gradins
* **Tout l'anneau** prend les matières de la portion pilote : contremarches en appareil, dalles des marches, assises de
  bois le long de l'arc, escaliers, podium (soubassement, chaperon, moulure). La « tranche » de gradins devant le tunnel
  est garde ses maillages séparés (coupe dans le tunnel), avec les mêmes matières.
* **Pilastres du podium** en gros appareil, **colonnade et architrave** du nord en moulure claire, **arcs** des accès
  combattants (clé légèrement dorée), **loge** (corps en grand appareil, balustrade et colonnes en moulure).
* Plus aucune surface P6.3 (`pierre_taille.png` teintée, briques en losange) ne reste à côté des nouvelles matières.

### 2.3 Vestiaires et salle d'attente
* Vestiaires : le mur du second pilote reste la référence ; **plancher procédural**, avec une bordure de dalles du
  Colisée à la place de la texture de planches P4. Les casiers, bancs et accessoires sont inchangés.
* Salle d'attente : murs, linteaux, **piédroits de l'entrée du tunnel** et **dallage enrichi** (au lieu des pavés violets
  P4).

### 2.4 Tunnels
* **Tunnel sud** et **tunnel est** : appareil sombre et humide, pavage de tunnel, naissances de voûte en moulure assombrie,
  arc de la bouche en claveaux clairs. Les murs du tunnel sud restent à 3,1 m (rendu), jamais coupés.

### 2.5 Coursive
* Elle était déjà la zone pilote : murs et dallage sont inchangés.
* Les **murs restants** (est, sud) et les **quatre piliers** passent dans le même appareil : fût, base en soubassement et
  chapiteau mouluré. La coursive est désormais entièrement homogène.

### 2.6 Infirmerie et pièces secondaires
* **Infirmerie** : murs clairs et entretenus, plancher clair.
* **Réserve** : murs plus bruts et plancher sombre, visibles par la coupe de la porte C.
* **Couloir de sortie** : murs et dallage.
* **Porte C** : inchangée, appliquée à toutes les portes fermées.
  * Le cadenas reste contre le jambage, à côté de la porte, et non sur l'axe du passage ; il ne se superpose pas à Aren.
  * La sonde « réserve fermée » est réussie.

### 2.7 Harmonisation lumineuse
Même logique qu'en P6.4.1 : des lumières fixes, sans ombre portée ni scintillement, qui désignent les **accès** et les
**axes**. Aucune ne suit Aren.

Progression du parcours :

| Zone | Lumière |
|---|---|
| Vestiaires | **chaleureux**, inchangé : lanternes et passage éclairé par la salle |
| Salle d'attente | **intérieure**, plus douce : deux portes de service marquées, axe vers le tunnel |
| Tunnel sud | **plus sombre** : torches de l'entrée, pénombre au milieu, jour au bout (inchangé) |
| Arène | **naturelle** : pas de lumière ajoutée sur le sable, une lueur chaude courte à chaque bouche d'accès ; les braseros gardent leur lueur courte |
| Tunnel est, coursive | **ponctuelle** : accès de la coursive (loge, réserve, débouché du tunnel est) et allée centrale, inchangés |
| Infirmerie | lumière plus **blanche et calme** au-dessus des lits ; porte marquée |
| Réserve | une seule **lueur faible**, chaude |
| Couloir de sortie | la porte de la coursive marquée ; le jour de la ville entre par la porte est (inchangé) |

Les transitions d'exposition restent celles du système validé : la lumière ambiante dépend de la distance à l'arène, et
non du franchissement d'un seuil.

## 3. Points de vigilance vérifiés

**Architecture**
* Les raccords gradins / galerie, les corniches et les contreforts sont ceux de B, validés.
* Les toits n'ont pas de motif répétitif visible : ce sont des terrasses dallées irrégulières.
* Les portes restent identifiables : encadrements, porte C, cadenas.
* Les murs coupés gardent leur tranche sombre.

**Matériaux**
* Les UV sont inchangées : en mètres, en UV monde pour les faces planes, le long de l'arc pour les anneaux.
* Les joints et le grain sont filtrés, donc pas de nouveau crépitement.
* Le sens des assises est le même partout : horizontal sur les murs, lames du plancher selon x.

**Lumière**
* Pas de halo autour d'Aren : le halo visible dans le tunnel sud est l'éblouissement « discret » de P6.3.1, inchangé.

## 4. Défauts et éléments encore provisoires

* **Pièces secondaires vues en coupe** : la réserve et le couloir de sortie, vus depuis la coursive, se détachent encore
  sur le **noir** du hors-champ.
  * Sous la caméra, il n'y a ni sol extérieur ni rue. C'est l'état validé du système B, inchangé ici.
  * La ville étant hors périmètre, je n'ai rien ajouté côté rue.
  * C'est le défaut « pièce qui semble flotter » qui reste le plus visible.
* **Murs extérieurs du tunnel sud vus de l'arène** : ce sont deux longues lames sombres, à l'ombre des gradins. Leur
  matière est maintenant celle du tunnel, mais leur volume reste celui de P6.2-D.
* **Bandes fines autour de la bouche du tunnel sud** (vue depuis la salle) : chaperons des murs nord de la salle, coupés
  en muret.
  * Elles existaient déjà en P6.4.1 (voir la planche 1, à gauche) et ne sont pas des régressions.
  * Elles pourraient être raccourcies dans une passe de finition.
* **Tuiles de la bande couverte B** : en angle rasant (premier plan sud), elles gardent un léger moiré en rendu
  logiciel. Il faut vérifier sur GPU.
* **Bois des assises** : il est grisé pour atténuer le contraste orange / calcaire. Il reste le principal accent coloré
  de l'arène.
* **Sable, bannières, mobilier, portes** : inchangés (P5.3-B, Quaternius).
* **Parvis et bâtiments lointains** : textures P4, hors périmètre (ville).

## 5. Tests exécutés

Tous les tests ont été exécutés sur l'état final de la branche, sous Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`).

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` (tests unitaires) | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide` (ouverture de bout en bout, **combat tutoriel normal**) | réussi (0 échec) |
| `e2e_p6_saut_tutoriel` (**saut du tutoriel**, au dialogue et en combat) | réussi (0 échec) |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` (non-régression P4) | réussis |
| Sondes de collision `p6_sondes` (dont « réserve fermée ») | 10 / 10 |
| `tests/v11_collisions_smoke.gd` (forêt) | réussi |
| F5 (`--quit-after 60`) : la forêt se charge | sans erreur |
| Circulation à une touche (`circulation_p6`), azimut 0° | 4 tronçons, 3/3, 0 % de contact mural (inchangé) |
| Caméra (`camera_continuite_p6`), traversée complète `p6_traversee` | **0 bond** (2 760 images) |
| Caméra, parcours de contrôle `p6_video_631` | **0 bond** (3 736 images) |
| Reliefs visibles traversables (`reliefs_p6`) | aucun (seules les 6 étiquettes de débogage, comme avant) |
| Faces confondues (`coplanaires_p6`) | 469 paires, dont 168 entre murs : identique à P6.3.2 (géométrie inchangée) |

Seul l'avertissement connu de `avant_poste.gd:1115` (taille d'un contrôle) apparaît, comme avant l'étape.

Les commits 1 à 7 séparent les ensembles de travail (galerie, arène, vestiaires et salle, tunnels, coursive, pièces
secondaires, lumière). Ils sont découpés à partir d'un même état final : **seul l'état final est testé**.

## 6. Coût de rendu

Mesures en **rendu logiciel** (lavapipe, llvmpipe 256 bits, 4 cœurs) : appels de dessin, primitives et mémoire vidéo
sont fiables ; le temps d'image (≈ 133 ms, saturé) ne l'est pas. **Pas de GPU disponible ici : aucune validation GPU.**

Parcours de captures (13 positions, même parcours) :

| | Second pilote (P6.4.1) | Extension (P6.4.2) |
|---|---|---|
| Appels de dessin, maximum | 1 198 | 1 178 |
| Primitives, maximum | 162 k | 171 k |
| Mémoire vidéo | 303,4 Mo | 303,5 Mo |

* **Aucune texture nouvelle** : les matières de zone réutilisent `roche.png`, `sol_terre.png` et `sol_herbe.png`, déjà
  chargées par le second pilote. La mémoire vidéo est donc inchangée.
* **Matériaux** : une quarantaine de variantes du même shader, qui ne diffèrent que par leurs paramètres. Le nombre de
  pipelines de shader ne change pas.
* **Coût par pixel** : toutes les surfaces du Colisée utilisent maintenant le shader hybride, avec deux
  échantillonnages peints de plus que les textures P4. C'est le coût à surveiller **sur GPU**, en particulier :
  * l'arène face aux gradins, quasi plein écran de shader procédural ;
  * les vestiaires, plancher et murs.

Coût par pièce (`perf_pieces_p6`, mêmes positions, `--p64=2` puis `--p64=3`) :

| Position | Second pilote : appels / primitives | Extension : appels / primitives |
|---|---|---|
| vestiaires | 1161 / 128 k | 1146 / 128 k |
| passage | 1057 / 110 k | 1040 / 110 k |
| salle d'attente | 479 / 76 k | 471 / 76 k |
| tunnel | 435 / 70 k | 426 / 70 k |
| sortie du tunnel | 401 / 68 k | 392 / 68 k |
| arène (entrée) | 455 / 48 k | 446 / 48 k |
| arène (centre) | 357 / 47 k | 348 / 47 k |
| tunnel est | 433 / 55 k | 431 / 57 k |
| coursive | 306 / 40 k | 307 / 40 k |
| infirmerie | 623 / 76 k | 619 / 78 k |
| couloir de sortie | 418 / 73 k | 425 / 76 k |

* **Appels de dessin** : ils baissent de 8 à 17 dans les pièces du sud et dans l'arène. Ils sont stables dans la
  coursive (+1) et augmentent un peu dans le couloir de sortie (+7), qui reçoit les nouvelles lumières d'accès.
* **Primitives** : elles sont identiques, sauf + 2 à 3 k vues depuis le tunnel est, l'infirmerie et le couloir de sortie.
  Ce sont des objets un peu plus nombreux à l'écran (lumières, éléments déjà existants mieux éclairés), pas de géométrie
  nouvelle : les faces confondues restent identiques.
* La mémoire vidéo est stable (302–303 Mo dans les deux cas).

## 7. Fichiers modifiés

| Fichier | Changement |
|---|---|
| `scenes/p6/habillage_p6.gd` | `extension`, `P642_ZONES`, `mz()` / `mm()` / `mat_sol()`, préréglages `plancher` et `dallage_tunnel`, arène et loge, vestiaires, `lumiere_p642()` |
| `scenes/p6/colisee.gd` | état `--p64=3` par défaut (galerie B, porte C), murs / sols / linteaux / piliers / voûtes par zone, toits, téléport sans fondu, décor du combat pris depuis l'arène, `--neuf` / `--etat` non réappliqués au retour du tutoriel (outil vidéo) |
| `src/explore25/secteurs25.gd` | `mat_toit` (matière des toits fournie par l'habillage) |
| `src/explore25/routes25.gd` | parcours `p6_extension_captures`, `p6_video_642_apres` |
| `art/p6/combat/arene_colisee.png` | décor du combat tutoriel régénéré |
| `src/p6/*.gdshader.uid` | identifiants générés par Godot 4.7.2 à l'import |

## 8. Décisions artistiques à prendre

1. **Palette par zone** : l'écart entre les zones est volontairement modéré, pour que le bâtiment reste un. Faut-il
   l'accentuer ou l'atténuer ? Par exemple, l'infirmerie plus blanche, ou le tunnel plus sombre.
2. **Toits des intérieurs** : terrasses dallées (cohérentes avec B), ou de vraies toitures en pente de petites tuiles (A)
   sur certains volumes ? La seconde option demanderait de la géométrie nouvelle.
3. **Bois des gradins** : faut-il le garder grisé, le rendre plus chaud, ou passer à des assises de pierre ?
4. **Hors-champ des pièces secondaires** : faut-il un traitement du noir sous la coursive (ombre portée, sol extérieur
   sombre) ? Il dépendra du plan de la ville.
5. **Vestiaires** : garder le plancher procédural, ou revenir à la texture de planches P4 (touche M, état 2) ?

L'étape s'arrête ici : pas de nouvelle phase ni de travail sur la ville avant votre validation.
