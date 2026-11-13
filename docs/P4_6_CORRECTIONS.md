# P4.6 — Corrections : taille constante à l'arrêt et en marche, Ilya de face en combat (Godot 4.7.2)

Branche **`p4-6-corrections`**, partie de `p4-5-animations` (laissée intacte). Date : 13 novembre 2026.
Demande : « lorsque l'on fait un déplacement, la taille du personnage change, il faudrait qu'elle reste comme elle
est. J'aimerais qu'Ilya ait le corps de face comme pour Aren. » Gameplay, carte, caméra P30, PV de démo : inchangés.
**F5** lance toujours `scenes/p4/avant_poste.tscn` (même scène, sprites corrigés).

## Vidéos et comparaisons

| Fichier | Ce qu'il montre |
|---|---|
| [`videos/marche_arret_taille_constante_x3.mp4`](media/p4_6/videos/marche_arret_taille_constante_x3.mp4) | Aren et Ilya à ×3 (agrandi au plus proche) : départ, marche et arrêt dans les 4 directions |
| [`videos/combat_ilya_de_face.mp4`](media/p4_6/videos/combat_ilya_de_face.mp4) | vue de combat réelle : attente, tir, tir chargé, garde, touchée et K.O. d'Ilya ; actions d'Aren |
| [`comparaisons/aren_taille_arret_marche.png`](media/p4_6/comparaisons/aren_taille_arret_marche.png) | Aren à l'arrêt et en marche, P4.5 puis P4.6 |
| [`comparaisons/ilya_combat_profil_face.png`](media/p4_6/comparaisons/ilya_combat_profil_face.png) | Ilya en combat : profil P4.5, face P4.6 |
| [`combat.jpg`](media/p4_6/combat.jpg) | écran de combat : Aren, Ilya et Throné tournés vers le Vorgane |

## 1. Taille qui change au déplacement

**Cause** : dans le pack P4.3 d'Aren, la pose de repos (utilisée par toute l'attente) est dessinée à une autre
échelle que les 4 pas de marche : tête et épaules ~18 % plus petites, jambes plus longues. Avec un facteur de
réduction unique, Aren « grandissait » en démarrant (tête de 23 → 27 px, hauteur jusqu'à +5 px de dos et de profil)
et « rapetissait » à l'arrêt. Ilya et le garde n'ont pas ce défaut (tête identique à l'arrêt et en marche, mesuré).

**Correction** (`tools/p45/build_p45.py`, `idle_to_walk_scale`) : si la tête de la pose de repos diffère de plus de
6 % de celle des pas, le haut du corps (tête, épaules, buste jusqu'à la ceinture) est réduit à l'échelle des pas et
les jambes sont tassées verticalement pour que la hauteur totale égale celle des pas. Toujours une réduction (aucun
agrandissement). Les 8 images d'attente en découlent. Résultat, Aren : tête 27 px à l'arrêt comme en marche, hauteur
à ±1 px dans les 4 directions. Ilya et garde : inchangés (déjà constants).

Côté moteur rien ne changeait la taille : mêmes canevas, même facteur `k`, caméra P30 qui garde le héros à distance
constante (les autres personnages varient seulement avec la profondeur, comme tout le décor).

## 2. Ilya de face en combat

Le pack de combat P4.4 est un **profil strict** ; Aren est de face (trois-quarts). Aucune planche d'Ilya verte de
face en combat n'existe sur le Drive (les 32 poses de référence sont dans l'ancien design bleu ; les poses P4.2 font
44 px et ne pourraient être qu'agrandies, ce qui est exclu). Le pack P4.4 étant lui-même un **montage** (base verte
approuvée + pistolet peint, d'après son manifeste), P4.6 applique le même principe avec la **base verte de face** du
pack P4.3 (pose de repos, 251 px, réduite à 55 px) :

- *attente, dégainer, touchée* : corps de face, pistolet tenu bas dans la main droite ; respiration conservée ;
  touchée : buste rejeté d'1 px, entailles rouges du pack ;
- *visée, tir, tir chargé, garde* : le bras droit pendant est effacé (la cape qu'il cachait est repeinte) et le bras
  armé du pack part de l'épaule droite, tendu vers l'ennemi ; éclair, charge et bouclier d'Aether du pack ; recul du
  tir conservé ; le trait d'Aether part du bout du pistolet (`MUZZLE` 48, −68) ;
- *K.O.* : bascule en arrière (loin de l'ennemi), reposée au sol à chaque image, le pistolet tombe à côté.

Même design partout : cheveux courts argentés, yeux verts, cape verte et cuir, **pistolet d'Aether** (ni épée ni
arc) ; Ilya ne ressemble pas à Aren. Agrandissement au plus proche ×2 en combat, comme avant.

## 3. Encore provisoire

| Élément | Raison | Pour aller plus loin |
|---|---|---|
| **Combat d'Ilya de face** | **montage** (corps de face P4.3 + bras armé P4.4), pas un dessin : le bras tendu est fin, l'épaule se lit mal à ×2 | poses de combat d'Ilya dessinées de face / trois-quarts |
| K.O. d'Ilya | rotation rigide de la pose debout | vraie chute dessinée |
| Repos d'Aren (exploration) | **proportions retouchées** (buste agrandi par rapport aux jambes) pour suivre les pas du pack | repos dessiné à l'échelle des pas |
| Attentes (3 personnages, exploration ; Ilya en combat) | **procédurales** (décalages d'un pixel) | poses d'attente dessinées |
| Marche d'Aren et d'Ilya | images du pack P4.3 (cape et mains variables) | cycle dessiné |
| Marche du garde | profil droit, image 2 : 6 px plus basse dans la source | redessiner `right_2` |
| Jambes écartées d'Aren (avance, attaque, retour) | dessinées ainsi dans la planche | redessiner les poses de fente |

## 4. Tests (Godot 4.7.2)

| Vérification | Résultat |
|---|---|
| Import, chargement de F5 (`--quit-after 60`) | 0 erreur |
| Tests automatiques | **65/65** (2 nouveaux : `test_p46_corrections.gd`) ; sur les sprites P4.5, le test P4.6 relève 11 écarts |
| Rencontre de bout en bout (`tests/e2e_p4_retour.gd`) | **réussie** (475 PV de démo, données à 950) |
| Parcours `p4` — P30 / B28 | **29/29** chacun, 0 saut d'altitude |
| Sondes `p4_sondes` — P30 / B28 | **20/20** chacun |
| En mouvement | vidéos ci-dessus (rendu OpenGL logiciel) |

Non vérifié : Forward+ sur carte graphique, confort en main par une personne.

## 5. Fichiers

**Modifiés** : `tools/p45/build_p45.py` (repos à l'échelle des pas ; combat d'Ilya de face), `art/p45/chars/aren/`
(attente), `art/p45/combat/ilya/` (toutes les images), `src/proto/pack_hunter_view.gd` (bout du pistolet), tests,
`art/p45/SOURCES.md`, README, CLAUDE.md (référence du rapport), `docs/HISTORIQUE.md`.
**Ajoutés** : `tests/unit/test_p46_corrections.gd`, ce rapport, `docs/media/p4_6/`.
**Retirés** (historique Git, branche `p4-5-animations`) : `docs/P4_5_ANIMATIONS.md`, `docs/media/p4_5/` (deux
captures du décor, toujours valables, déplacées dans `docs/media/p4_6/captures/`).

## 6. Lancer

Branche `p4-6-corrections` → Code → Download ZIP (dossier `Val-Serra-Game-p4-6-corrections`) → importer dans
Godot 4.7.2 → **F5**.
