# Protocole de validation — caméra A / C et mesure GPU (Godot 4.7.2)

À faire **sur le PC de jeu** (Windows, carte graphique), avec **Godot 4.7.2** exactement. Durée : environ 25 minutes.
Rien n'est modifié dans le projet : F5 reste l'exploration stable, tout se passe dans des scènes ouvertes avec **F6**.

Ce protocole complète `docs/P3_VALIDATION_CAMERA.md` : les mesures automatiques y sont déjà faites ; il reste ce
qu'une machine sans carte graphique et sans joueur ne peut pas établir — **le confort en main** et **les
performances réelles**.

## 0. Préparation (2 min)

1. Télécharger la branche `p3-validation-camera` et l'ouvrir dans Godot 4.7.2 (**Importer et modifier**).
   Attendre la fin de la réimportation.
2. Vérifier en haut à droite de l'éditeur que le moteur de rendu affiché est **Forward+**.
3. Si l'éditeur propose de convertir ou de mettre à jour le projet : **refuser** et me le signaler.

## 1. Mesure GPU automatique (8 min, sans intervention)

1. Fermer l'éditeur Godot (pour ne pas fausser la mesure) et les applications lourdes.
2. Dans l'explorateur Windows, ouvrir `tools\perf\` et **glisser `Godot_v4.7.2-stable_win64.exe` sur
   `mesure_gpu.bat`** (ou double-cliquer sur `mesure_gpu.bat` et coller le chemin de l'exécutable).
3. Sept parcours automatiques d'environ une minute s'enchaînent. Ne pas toucher au clavier ni à la souris et
   laisser la fenêtre du jeu au premier plan.
4. À la fin, **m'envoyer `mesures_gpu\RESUME_GPU.md`** (ou tout le dossier `mesures_gpu`).

| Parcours | Variante | Rendu demandé | Paysage | Ce que cela établit |
|---|---|---|---|---|
| 1 | C | Forward+ | 3D + brume | la mesure de référence |
| 2 | A | Forward+ | 3D + brume | A et C coûtent-ils pareil ? (attendu : oui) |
| 3 | C | Compatibility (OpenGL) | 3D + brume | le rendu de repli fonctionne-t-il, et à quel coût ? |
| 4 | A | Compatibility (OpenGL) | 3D + brume | idem |
| 5 | C | Forward+ | aucun | le coût propre du paysage non jouable |
| 6 | C | Forward+ | 3D + brume, plein écran | le coût à la définition réelle de l'écran |
| 7 | C | Forward+ | 3D + brume, V-Sync activée | la régularité réelle à l'écran |

Chaque fichier contient : images par seconde (moyenne, minimum), frametime moyen / p95 / maximum, appels de
dessin, primitives, mémoire vidéo, carte graphique et pilote, moteur de rendu réellement obtenu.

**Seuils proposés** (à ajuster ensemble) : frametime p95 ≤ 16,7 ms (60 i/s tenus) sur les parcours 1, 3 et 6 ;
aucune différence sensible entre A et C ; moins de 300 Mo de mémoire vidéo pour ce blockout.

## 2. Test manuel A contre C (15 min)

Ouvrir `scenes/explore25/camera_variante_C.tscn`, puis **F6**.

| Touche | Action |
|---|---|
| Flèches / ZQSD | marcher (8 directions) |
| Molette (ou PgPréc / PgSuiv) | zoom ×2 / ×2,5 / ×3 |
| **V** | variante suivante, sur place : C → A → B → C (ignorer B) |
| **L** | paysage : 3D + brume → plans 2D → aucun (rester sur 3D + brume) |
| **O** | aide à l'occultation : aucune → silhouette → silhouette + transparence locale |
| E | parler / examiner · **R** : retour à l'entrée · **F1** : informations · **F3** : limite d'images par seconde |

Faire le parcours **une première fois en C à ×2,5**, puis refaire chaque étape en appuyant sur **V** pour comparer
avec A au même endroit, puis à **×2** et **×3**. Noter pour chaque étape : **C mieux / égal / A mieux**.

| # | Étape | Ce qu'il faut regarder | ×2 | ×2,5 | ×3 |
|---|---|---|---|---|---|
| 1 | Place centrale : marcher dans les 8 directions, avec des demi-tours brusques | la caméra suit-elle sans à-coup ? le héros « flotte »-t-il trop bas ? | | | |
| 2 | **Marcher vers le bas de l'écran** sur 10 m (de la terrasse vers le sud de la place) | voit-on assez loin devant soi ? (point faible attendu de C) | | | |
| 3 | Escalier : monter, redescendre, s'arrêter au milieu | marches lisibles ? pied de l'escalier visible depuis le haut ? | | | |
| 4 | Parler au PNJ sur la terrasse | le recentrage pendant le dialogue est-il discret ou gênant ? | | | |
| 5 | Faire le tour de la maison (passer derrière) | durée pendant laquelle on perd le héros ; essayer **O** | | | |
| 6 | Tourner autour de l'arbre, passer derrière | idem ; la silhouette bleue est-elle acceptable provisoirement ? | | | |
| 7 | Traverser le pont dans les deux sens | les deux rives et la sortie sont-elles visibles à temps ? | | | |
| 8 | Sortir par l'est, parcourir les 4 coins de la petite instance, revenir | pas de vide, pas de saut de cadrage à l'arrivée ni au retour | | | |
| 9 | Longer les quatre bords de la scène témoin | le cadrage se bloque-t-il de façon naturelle près des bords ? | | | |
| 10 | Changer de zoom en marchant, à plusieurs endroits | transition douce ? pas de saut vertical en C ? | | | |

Questions de synthèse :

1. Après 5 minutes de marche, C est-il **plus confortable, équivalent ou moins confortable** que A ?
2. À ×3, la marche vers le bas de l'écran est-elle acceptable en C ? (c'est là que C montre le moins : voir le rapport)
3. Sensation de mal des transports, de dérive ou de « caméra qui traîne » ?
4. Le paysage visible en plus en haut de l'écran vaut-il ce qui est perdu en bas ?
5. Décision : **verrouiller C**, **garder A**, ou **tester un décentrage intermédiaire** (héros vers 58 %) ?

Si possible, enregistrer 30 à 60 secondes d'écran (Xbox Game Bar : **Win + Alt + R**) du parcours en C à ×2,5.

## 3. Ce qu'il faut me renvoyer

- `mesures_gpu\RESUME_GPU.md` ;
- le tableau de l'étape 2 rempli (même à la main, en photo) et les cinq réponses de synthèse ;
- la vidéo d'écran si elle existe ;
- tout message d'erreur ou d'avertissement affiché par Godot à l'ouverture du projet.

## Variante en ligne de commande (facultatif)

```bash
tools/perf/mesure_gpu.sh /chemin/vers/godot
```

Une seule mesure :

```bash
godot --path . --rendering-method forward_plus --disable-vsync --resolution 1280x720 res://scenes/explore25/camera_variante_C.tscn -- --route=temoin --quit --nodebug --paysage=3d --tag=essai --out=mesures_gpu
```

Le parcours `--route=validation` (8 directions, escalier, maison, arbre, pont, petite instance ; ajouter
`--zoom=0`, `1` ou `2`) écrit en plus les mesures de cadrage décrites dans le rapport.
