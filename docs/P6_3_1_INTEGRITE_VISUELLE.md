# P6.3.1 — Stabilisation visuelle du Colisée

> **P7.2 (nettoyage autorisé par le créateur)** : les médias de ce rapport (`docs/media/…`) ont été retirés du projet
> actif. Ils restent dans l'historique Git : `git checkout d88eac4 -- docs/media/<dossier>`.

Branche **`p6-3-1-colisee-integrite-visuelle`**, issue de `p6-3-colisee-art`.

Sont inchangés :
* Godot 4.7.2 ;
* la caméra (azimut 0°, plongée 24°, champ 30°, ×3, limites communes), le tunnel sud de 8,5 m, le mode B ;
* les ombres douces en qualité 4 ;
* les modèles Quaternius, la progression, les dialogues, le tutoriel et son saut ;
* CombatCore et les sprites ;
* F5 (forêt). Le Colisée se lance en F6.

Le quartier de ville n'est pas touché. Aucun nouvel asset.

Les **six anomalies des captures annotées** ont été reproduites dans Godot aux mêmes positions (parcours
`p6_defauts_631`). Chacune est corrigée ci-dessous, avec sa cause exacte. Il s'agit de conformité visuelle et
fonctionnelle, **pas d'une validation artistique**. Les mesures sont en rendu logiciel, **pas sur GPU**.

## Livrables

| | |
|---|---|
| Avant / après aux positions des anomalies (passage, gradins, tunnel est depuis l'arène et de l'intérieur, coursive, infirmerie) | [`defauts_avant_apres.jpg`](media/p6_3_1/defauts_avant_apres.jpg) |
| Tunnel est et coursive, visibilité active / désactivée, P6.3 et P6.3.1 | [`tunnel_est_secteurs_on_off.jpg`](media/p6_3_1/tunnel_est_secteurs_on_off.jpg) |
| Tunnel sud : éblouissement actuel / aucun / discret | [`tunnel_sud_eblouissement.jpg`](media/p6_3_1/tunnel_sud_eblouissement.jpg) |
| Mode de diagnostic (infirmerie) | [`diagnostic_infirmerie.jpg`](media/p6_3_1/diagnostic_infirmerie.jpg) |
| Vidéo de contrôle en mouvement | [`controle_p6_3_1.mp4`](media/p6_3_1/controle_p6_3_1.mp4) : vestiaires (coin, porte, aller-retour au seuil) → salle (près du mur) → tunnel sud (aller-retour) → arène → tunnel est (aller-retour) → coursive (le long du mur) → infirmerie (fond, porte, aller-retour) → coursive |

## Diagnostic et corrections

| # | Anomalie (capture) | Objet responsable | Fichier / fonction | Nature | Correction |
|---|---|---|---|---|---|
| A | 01 — poutre traversant la porte | Poutre haute en bois sombre du mur nord des vestiaires, construite sur **toute la largeur** (porte comprise), à 2,82 m, rangée avec le **décor** des vestiaires. Quand Aren est dans le passage, le mur nord est devant lui et coupé en muret, mais la poutre reste en l'air. | `habillage_p6.gd`, `vestiaires()` | géométrie + visibilité | Poutre interrompue au droit de la porte (le linteau prend le relais). Poutre et poteaux sont attachés au mur nord : ils suivent sa coupe. |
| B | 03 — briques des gradins | `surface_p4.gdshader` en « UV monde » : sur une face courbe, la projection bascule de x à z selon la normale (orientation incohérente, briques étirées) ; les dessus utilisent le plan xz (briques qui ne suivent pas la courbe). | `habillage_p6.gd`, `arene()` | UV / matériau | Anneaux en **UV métriques qui suivent l'arc** (`_rq`, `_rt`, longueur d'arc réelle de l'ellipse `_arc_s`), avec des matériaux distincts : contremarches et murs d'enceinte en blocs de pierre, dalles des marches et du chaperon, assises en planches posées le long de l'arc, escaliers. Les gradins et le podium sont traités ; le shader n'est pas modifié. |
| C | 04 et 05 — enceinte trouée, sol visible | La **tranche de gradins** devant le tunnel est, que P6.3 **coupait** quand Aren était dans le tunnel est. Sans secteurs, le trou disparaît : c'est la visibilité, pas un maillage manquant. | `colisee.gd`, `tranche_gradins()` | visibilité | La tranche n'est **jamais coupée** : l'enceinte reste continue. Des volumes d'occultation sans collision (en tranches le long de l'anneau) déclenchent la **trouée locale tramée** validée en forêt quand les gradins passent devant Aren. Le dallage de P6.3 est retiré. |
| D | 06 — pièce voisine exposée | Le **mur sud de la coursive** est bas (1 m), car c'est son mur côté caméra. Mais c'est le mur **du fond** de l'infirmerie et de la réserve : par-dessus, on voyait la coursive, la porte de la réserve et ses vantaux coupés. Un segment ne touchant qu'un intérieur (la réserve commence 0,6 m plus loin) restait bas. | `colisee.gd`, `_build_bloc_p6()` / `_porte_habillee()` ; `build_colisee.py` | géométrie + visibilité | Toute cloison entre deux intérieurs, et le mur sud de la coursive, est rendue **sur toute la hauteur** (affichage seulement, collision inchangée). La coupe la réduit en muret quand elle est devant la pièce active (depuis la coursive) et la garde entière quand elle est au fond (depuis l'infirmerie). Linteaux ajoutés sur le passage de l'infirmerie et sur la porte de la réserve ; porte de la réserve en pleine hauteur. Depuis l'infirmerie, la coursive ne se voit plus que par le passage. |
| E | 02 — nappe lumineuse | `vue_tunnel.gdshader` mélangeait une couleur de jour presque blanche au-delà d'une portée courte (éblouissement de 0,8 à 0,4). | `colisee.gd`, `vue_tunnel_etat()` ; shader inchangé | transparence / plein écran | Trois variantes, `-- --eblouissement=` : **actuel** (P6.3), **aucun** (lignes de vue seules), **discret**, retenu par défaut (voile chaud de 0,32 à 0,12, portée plus longue, teinte ambrée). La révélation progressive est conservée. |

**Mode de diagnostic** (outil de développement, touche **F10** ou `-- --diag`) : il affiche le secteur actif, les
secteurs en vue, les groupes rendus et masqués, les murs coupés, le nombre d'éléments translucides, les toits et la
position d'Aren. Il ne fait que lire : aucun système permanent n'est ajouté.

## Vérifications

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel` (combat tutoriel et saut) | réussis |
| `e2e_p4_retour`, parcours `p4` et `p4_sondes` | réussis |
| Sondes de collision `p6_sondes` | 10 / 10 |
| Reliefs visibles traversables | aucun |
| Circulation à une touche | 4 tronçons, 3/3, 0 % de contact mural |
| Caméra, `p6_traversee` (46 s) et parcours vidéo `p6_video_631` (62 s, allers-retours, près des murs) | **0 bond**, zoom constant |
| F5 | se charge sans erreur |

**Coût de rendu** (appels de dessin, rendu logiciel) : de −2 % à +7 % selon la position, primitives quasi identiques
(vestiaires 85 k, infirmerie 36 k).

| Position | P6.3 | P6.3.1 |
|---|---|---|
| Vestiaires | 831 | 876 |
| Tunnel sud | 364 | 364 |
| Tunnel est | 381 | 387 |
| Infirmerie | 377 | 402 (cloison pleine hauteur) |
| Coursive | 270 | 274 |

## Limites restantes

* **Tunnel est, vu de l'intérieur** : entre le dos des gradins et le mur ouest de la coursive, une bande étroite
  reste sombre. C'est le terrain extérieur, masqué depuis un intérieur. À traiter avec les matériaux et les volumes
  extérieurs (P6.4).
* **Porte de l'infirmerie** : la cloison étant maintenant haute, son estompage de 0,45 s se voit pendant les
  allers-retours au seuil (mur semi-transparent un instant). C'est le comportement normal du mode B, à juger en
  mouvement (vidéo, vers 45–55 s).
* **Trouée locale** dans les gradins quand Aren est dans le tunnel est : c'est le système validé en forêt, mais à
  juger en mouvement (vidéo).
* **Gradins** : seuls les gradins, le podium et la colonnade passent aux UV métriques. Les murs droits gardent la
  projection monde, cohérente sur des faces planes.
* **GPU** : aucune mesure. Rien n'est final.

## Décision attendue

Validez-vous ces corrections, et la variante d'éblouissement **discrète** ? P6.4 (vrais matériaux HD-2D,
éclairage, finition architecturale) n'est pas lancée.
