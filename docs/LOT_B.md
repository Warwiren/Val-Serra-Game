# Lot B — Combat présentable, micro-boucle d'exploration, rendus A/B : compte rendu

*4 novembre 2026 · Godot 4.5.1 · branche `lot-b`*

## 1. Ce qui fonctionne (vérifié)

| Demande | Réalisé | Vérification |
|---|---|---|
| 3 Chasseurs et le monstre visibles, composition claire | Chasseurs à gauche en formation décalée, monstre à droite, cadrage 3/4 fixe | Captures, vidéo |
| Arène / décor illustré crédible | Lisière d'avant-poste au crépuscule, 5 plans de décor originaux | Captures A/B |
| Chronologie visuelle avec portraits | Axe **proportionnel au temps** ; portraits = décisions, losanges = effets, rouge ⚠ = attaque annoncée, or = votre choix | Captures, vidéo |
| PV, Résonance, ennemi, parties | Rangées du groupe (PV, Résonance, repère du coût de sérum), barre du monstre, alerte « ⚠ Souffle dans N » | Captures |
| Ciblage visuel d'une partie | Cercles sur Griffe / Carapace / Glande avec anneau d'intégrité ; clic ou ←/→ ; réticule doré ; ▲/▼ selon l'arme du Chasseur actif | Captures |
| Rupture perceptible | Échange de l'illustration (intacte → brisée), flash, éclats, onde, zoom, bannière « RUPTURE ! », croix sur le marqueur | Vidéo |
| Animations minimales | Respiration au repos, élan + coup d'arme (arme en calque séparé), recul aux dégâts, garde (bouclier d'Aether), aura de charge, lancement de sérum (onde + orbe), K.O., souffle du monstre, mort du monstre | Vidéo |
| Impacts | Chiffres de dégâts, flash blanc, secousse proportionnelle aux dégâts, zoom léger sur coups chargés et ruptures | Vidéo |
| Lisibilité des modes | 3 cartes VIF / MESURÉ / CHARGÉ : barre de délai, « Effet dans +N », dégâts et rupture estimés, **✔ avant / ✘ après le Souffle** ; le losange or bouge sur la chronologie | Captures |
| Journal secondaire | Petit panneau translucide (L pour l'agrandir) ; n'est plus nécessaire pour comprendre | — |
| Variante A (2D) et B (2.5D), même CombatCore | Bascule **F2** à tout moment (zone et combat) ; seuls décor, lumière et particules changent | Captures A/B, vidéos |
| Micro-exploration | Zone avec héros contrôlable, compagnon suiveur, PNJ, ennemi visible qui rôde, déclenchement du combat, retour avec récompenses et nouvelles répliques | Vidéo de la boucle |
| Dialogue à portraits | Portraits héros (gauche) / PNJ (droite), locuteur mis en avant, texte progressif, choix de réponse, accords {m:…\|f:…} | Vidéo, tests |
| 2 bases de héros | Homme / femme : corps, portrait, nom, accords | Captures, tests |

**Tests automatisés : 32 / 32** (les 28 du Lot A + 4 nouveaux : accords, noms par défaut, récompenses,
cohérence du fichier de dialogue). La simulation console donne toujours le même combat qu'au Lot A :
les règles n'ont pas changé, seul le journal transmet désormais les valeurs à afficher.

## 2. Preuves visuelles

| Fichier | Contenu |
|---|---|
| `docs/media/lotB_boucle_complete_rendu_B.mp4` | Boucle complète en 2.5D (1 min 48) : choix du héros → zone → dialogue → approche du Vorgane → combat entier (annonce du Souffle, ruptures, soin, victoire) → retour, récompenses, nouvelles répliques |
| `docs/media/lotB_combat_rendu_A.mp4` | Le même combat en rendu 2D (1 min 20) |
| `docs/captures/lotB_combat_A.png` / `_B.png` | Même instant du combat en A et en B |
| `docs/captures/lotB_zone_A.png` / `_B.png` | Même instant de la zone (héroïne) en A et en B |

Les vidéos sont des démonstrations automatiques (option `--autoplay`), enregistrées à 30 images/s fixes.

## 3. Comment tester

Voir le **README**, section 3 (« Jouer la démo ») et le scénario conseillé de 15 minutes.

## 4. Limites connues

- **Illustrations provisoires** : dessinées en vectoriel par Claude pour valider la structure (calques,
  ancrages, états brisés) et l'ambiance ; elles n'ont pas la finesse d'illustrations peintes.
- **Animation par calques simples** : corps + arme séparés. Pas encore de bras, jambes ou tête articulés
  (Skeleton2D) : les frappes sont lisibles mais raides. Marche = rebond, sans cycle de pas dessiné.
- **Une seule pose par personnage** : pas de pose de garde, de coup ou de K.O. dessinée (effets et
  transformations à la place).
- **Monstre** : deux états par partie (intacte / brisée), pas d'état « endommagé » intermédiaire.
- **Aucun son.**
- **Équilibrage** : le combat reste plutôt facile avec une stratégie correcte (cf. Lot A).
- **Exploration** : écran unique sans défilement ; collisions simplifiées (zone de marche + PNJ) ;
  le compagnon passe à travers les décors.
- **Performances** : mesurées uniquement dans un environnement de capture logiciel (sans carte
  graphique), donc non représentatives. Touche **F3** pour lire les images/s sur votre machine, en A et en B.
- Le rendu B est une **2.5D par calques 2D** (parallax, flou, brume, lumières). La technique « HD-2D »
  (sprites dans un vrai décor 3D, comme la référence) n'a pas été essayée : voir recommandations.
- Les fenêtres de résultat et de dialogue se pilotent à la souris et au clavier ; la manette n'est pas gérée.

## 5. Mon avis

### Lisibilité du combat — bonne, à affiner
La chronologie **à l'échelle du temps** est le point fort : on voit d'un coup d'œil qu'un coup VIF tombe
avant l'attaque annoncée et qu'un coup CHARGÉ tombe après. Les cartes de mode rendent la décision
explicite (✔/✘), et le joueur n'a plus besoin du journal. À améliorer :
- quand plusieurs événements sont proches, les étiquettes de la chronologie se chevauchent ;
- les trois marqueurs de parties toujours affichés chargent un peu l'image : les afficher en grand
  seulement pendant le ciblage serait plus élégant ;
- le bandeau inférieur est dense ; il faudra le tester sur un écran plus petit.

### Viabilité du rendu 2D (A) — oui, solide en plan de secours
Lisible, contrasté, rapide à produire : un décor = une illustration. C'est un repli sûr, mais plat :
l'ambiance « chasse au crépuscule » perd beaucoup.

### Viabilité du rendu 2.5D (B) — oui, c'est le meilleur rapport coût / effet
Pour un surcoût modeste (découper chaque décor en 4–5 plans et placer quelques lumières), B donne la
profondeur, la lumière et la vie que vous visiez : les personnages se détachent du fond, l'Aether brille,
la scène respire. Points d'attention :
- les lumières et la brume doivent être réglées scène par scène (brume un peu trop laiteuse dans la zone) ;
- l'interface et les marqueurs sont déjà placés sur une couche non assombrie, il faut garder ce principe ;
- cela impose une discipline d'assets : chaque décor livré en calques.

### Recommandation pour la suite
1. **Retenir B (2.5D par calques) comme direction principale**, A comme repli. Les deux restent disponibles
   sans coût de maintenance, car seul le décor change.
2. **Ne pas engager le « vrai » HD-2D (décor 3D) maintenant.** Il serait plus proche de la référence (vraie
   perspective, éclairage 3D), mais coûte un pipeline 3D (modélisation des décors, caméra, ombres).
   À réévaluer après la DA finale, sur une seule scène test.
3. **Prochaine étape artistique** : faire produire (illustrateur ou IA + retouche) **un** Chasseur en calques
   articulés (tête, torse, bras avant/arrière, jambes, arme) et **une** partie de monstre avec ses trois
   états. On l'intègre à la place des placeholders pour juger le rendu final avant de multiplier les assets.
4. **Prochain lot technique** : le Lot E (économie : achat de potion, établi de forge pour améliorer une arme,
   sauvegarde) pour boucler la démonstration, puis le polissage du ressenti (sons, poses dédiées,
   équilibrage) d'après vos retours.

## 6. Fichiers principaux

| Rôle | Fichier |
|---|---|
| Scène de combat (traduit le journal du CombatCore en animations) | `scenes/battle/battle_scene.gd` |
| Interface de combat | `src/presentation/battle_hud.gd`, `timeline_view.gd` |
| Vues Chasseur / monstre | `src/presentation/hunter_view.gd`, `monster_view.gd` |
| Décor A/B, flou de profondeur | `src/presentation/stage.gd`, `depth_blur.gdshader` |
| Effets | `src/presentation/fx.gd` |
| Choix du héros, zone, dialogue | `scenes/explore/*.gd`, `src/explore/dialogue_box.gd`, `data/dialogue/intendante.json` |
| État de partie | `src/game/game_state.gd` |
| Illustrations et générateurs | `art/`, `tools/art/` |
