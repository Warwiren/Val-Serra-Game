# Val'Serra MVP — Synthèse avant code (réponse à la Mission 08 §3)

*4 novembre 2026. Document de travail du dépôt de prototype : il ne remplace aucun document canonique.*

## 1. Audit des accès

| Ressource | Accès | Constat |
|---|---|---|
| 07 — Brief MVP | Lu intégralement | Périmètre de référence |
| 08 — Mission Claude | Lu intégralement | Ordre des lots A→E |
| 02 — GDD | Lu : §1–14 en survol, §19–41 en détail | Valeurs de prototype §31–35 reprises telles quelles |
| 04 — Direction artistique, 05 — Backlog | Lus intégralement | Option B (2.5D) à l'essai, A (2D) en repli |
| 01 Bible canonique, 03 Bible narrative, 06 Registre | Visibles, non lus en détail | Inutiles au Lot A (aucun lore utilisé) |
| Image de référence Octopath Traveler II | Reçue dans la conversation | Référence d'ambiance uniquement |
| Dépôt `Warwiren/Val-serra` | Cloné, examiné | Système **Foundry VTT du JDR**. Ce n'est pas un jeu : on n'y touche pas |
| Dépôt du jeu | `Warwiren/Val-Serra-Game` | Contient ce projet |

## 2. Moteur : Godot 4 (recommandé)

| Critère | Godot 4 | Unity 6 | Unreal 5 | RPG Maker MZ |
|---|---|---|---|---|
| Coût, licence | Gratuit, MIT, zéro redevance | Gratuit puis abonnement/conditions | 5 % au-delà d'1 M$ | Payant, fermé |
| 2D (sprites, squelettes 2D, parallax, lumières 2D) | Excellent, natif | Bon | Faible (Paper2D) | Bon mais rigide |
| « HD-2D » : sprites 2D dans un décor 3D avec flou de profondeur (le rendu de la référence) | Oui : Sprite3D + caméra avec profondeur de champ | Oui | Oui (Octopath est fait ainsi) | Non |
| Combat sur mesure (chronologie dynamique, parties) | Facile en GDScript | Facile en C# | Lourd | Plugins fragiles |
| Accessible à un non-développeur assisté par IA | Langage simple, scènes en **texte** lisibles et modifiables par Claude, Git propre | C# plus exigeant, scènes YAML peu lisibles | Blueprints peu adaptés à l'IA | Facile mais plafonne vite |
| Poids, démarrage | ~100 Mo, sans installation | Plusieurs Go | Dizaines de Go | Léger |
| Export PC/Steam | Oui (GodotSteam) | Oui | Oui | Oui |

**Décision proposée : Godot 4.5+ (édition standard, GDScript).** C'est l'outil qui permet le mieux de
comparer A (2D) et B (2.5D) sur le **même** code de combat, avec des fichiers que Claude peut écrire,
relire et tester en ligne de commande. Le document 04 l'envisageait déjà ; rien dans l'existant ne
l'empêche. Unreal donnerait le rendu le plus proche de la référence, mais au prix d'une complexité hors
de portée d'une petite équipe pour un MVP.

**Point technique important pour la DA.** Le rendu de la capture de référence n'est pas un décor 2D
peint : ce sont des **sprites 2D posés dans un décor 3D simple**, avec un éclairage dynamique, des
particules et un fort flou de profondeur (effet « maquette »). Pour la version B, je recommande donc de
tester cette technique (Sprite3D + plans texturés + `CameraAttributes` de profondeur de champ), plutôt
qu'un simple parallax 2D. Les sprites restent exactement les mêmes que pour la version A.

## 3. Architecture

```
            data/*.json  ──────────────►  BattleFactory
                                               │
 ┌──────────────── CombatCore (logique pure, testée) ────────────────┐
 │ Battle : horloge commune, file d'événements, aperçu, journal      │
 │ Combatant · MonsterPart · Cast · Formulas · EnemyAI               │
 └──────────────┬─────────────────────────────────────────────────────┘
                │ journal d'événements typés (hit, break, cast, interrupt…)
     ┌──────────┴──────────┬─────────────────────────┐
 Écran debug (Lot A)   BattleView 2D (A)        BattleView 2.5D (B)   ← Lots B et D
```

- **CombatCore indépendant de l'affichage** : aucune dépendance aux nœuds, animations ou sons.
  Les vues lisent l'état et rejouent le journal d'événements (dégâts, rupture, interruption…) pour
  animer. Si la 2.5D échoue, on garde la 2D sans toucher au combat.
- **Données en JSON** (`data/`), commentées par des clés `_note`, modifiables dans Godot ou tout
  éditeur de texte. Choisi plutôt que les Resources `.tres` pour la lisibilité, les diffs Git et
  l'édition sûre par IA ; une bascule vers des Resources reste possible plus tard.
- **Scènes prévues** : `Boot/HeroSelect` → `Hub` (zone semi-libre) ⇄ `Battle` (vue A ou B).
- **État de partie** (Lot C/E) : un autoload `GameState` (groupe, inventaire, monnaie, niveaux d'arme,
  drapeaux de dialogue), sérialisable en JSON pour une sauvegarde basique.
- **Dialogues** (Lot C) : JSON `{speaker, portrait, text, choices}` avec variantes d'accord
  `{m:prêt|f:prête}` résolues selon le héros choisi. Pas d'extension tierce.
- **Événements** : journal du combat pour la vue ; signaux Godot classiques entre scènes.
- **Entrées** : actions InputMap (déplacer, valider, annuler) clavier + manette dès le Lot C.
- **Moteur de rendu** : Forward+ (par défaut), nécessaire au flou de profondeur de la version B.

| Obligatoire MVP | Optionnel | Hors périmètre |
|---|---|---|
| CombatCore, écran combat, zone, suiveur, PNJ à portraits, ennemi visible, potion, forge simple, A/B | Faux contrat, sauvegarde, manette, son | Monde ouvert, plusieurs villes, créateur de personnage, 3D complète, sérums canoniques |

## 4. Plan par lots (ordre de la Mission 08)

| Lot | Contenu | Livrable testable | Dépend de |
|---|---|---|---|
| **A — Simulation** *(fait, testé ; ressenti à valider)* | Horloge, modes, garde, Résonance, sérum, parties, interruption, IA, journal, tests | Écran debug + 28 tests | — |
| **B — Combat lisible** *(fait, avec rendus A/B et micro-exploration : voir LOT_B.md)* | Écran placeholder présentable : 3 Chasseurs et monstre en formes simples, chronologie en portraits, ciblage visuel des parties, signal d'attaque annoncée, jauges, VFX/sons simples, retour | Scène Battle jouable à la souris/clavier | A validé par vous |
| **C — Exploration** | Choix héros H/F + nom, zone semi-libre avec collisions, compagnon suiveur, PNJ à portraits avec un choix, ennemi visible → combat → retour | Boucle zone ⇄ combat | B |
| **D — Comparaison A/B** | Même zone et même combat en 2D illustrée et en 2.5D (HD-2D), interrupteur de rendu, captures et vidéo, fiche comparative | 2 rendus + fiche | C + premiers assets |
| **E — Économie** | Potion achetable, récompenses, établi de forge (+1 arme), boucle complète, sauvegarde basique | Boucle bout-à-bout par un testeur | C |

E peut passer avant D si les assets graphiques ne sont pas prêts : D est le seul lot qui dépend
vraiment des illustrations. **La production des assets doit donc commencer maintenant, en parallèle.**

## 5. Assets du MVP et apport réel de l'IA

### Liste minimale (même jeu de sprites pour A et B)

| Élément | Contenu | Priorité |
|---|---|---|
| Héros masculin et féminin | Portrait buste + sprite : repos, marche (exploration), préparation, frappe, garde, dégâts, K.O. | Lot C |
| Compagnon suiveur | Mêmes poses + marche + portrait | Lot C |
| 2ᵉ compagnon | Poses de combat + portrait (pas de marche) | Lot B/D |
| PNJ | Portrait + sprite immobile | Lot C |
| Monstre (1 grande créature originale) | Découpé en calques : corps, griffe, carapace, glande ; états intact/brisé par partie ; pose de préparation (lueur) ; mini-sprite d'exploration | Lot B/D |
| Zone d'avant-poste | A : 1 décor peint + sol. B : 3–5 calques (ciel, fond, plan moyen, sol, premier plan) + accessoires (caisses, lanterne, établi) | Lot C/D |
| UI | Cadre de chronologie, icônes tranchant/impact/perforant/Aether, icônes VIF/MESURÉ/CHARGÉ, jauges, boîte de dialogue, police libre | Lot B |
| VFX et sons | Étincelles, éclats de rupture, aura de sérum, garde ; 6–8 bruitages libres de droits | Lot B |

**Décision de DA à prendre bientôt :** sprites **pixel art** (comme la référence : moins de dessin par
pose, cohérence plus facile) ou **illustrations HD découpées** (articulées en squelette 2D, plus
proches d'une peinture, mais découpe et raccords plus coûteux). Cela change le pipeline d'assets,
pas le code.

### Ce que l'IA peut réellement faire

| Tâche | Claude | IA d'image (Midjourney, GPT-image, Flux…) | Travail humain indispensable |
|---|---|---|---|
| Code, outils, tests, données, shaders, particules, UI | Oui, c'est l'essentiel | — | Ressenti, équilibrage |
| Placeholders cohérents (formes, silhouettes, icônes simples SVG) | Oui | — | — |
| Moodboards, concept arts, palettes | Conseils, briefs | Très bon | Choix, cohérence |
| Portraits de dialogue | — | Bon | Retouches, cohérence entre personnages |
| Décors en calques | Assemblage, parallax, éclairage | Bon (générer chaque calque séparément) | Raccords, découpe |
| Sprites cohérents sur plusieurs poses | Outils d'import et de découpe | **Difficile** : visages, mains et armes dérivent d'une pose à l'autre | Retouche pose par pose, ou dessin |
| Monstre découpé en parties + états brisés | Intégration, états, VFX | Partiel (illustration d'ensemble) | Découpe des calques, zones cachées redessinées |
| Conversion d'une illustration 2D en modèle 3D jouable | — | Non fiable | — (non requis pour le MVP) |

Chaque asset ajouté sera tracé dans `docs/ASSETS.md` (source, outil, licence, statut provisoire/final),
en miroir du document 06. Vérifier les conditions d'usage commercial de chaque outil d'IA utilisé.

## 6. Risques principaux

1. **Sprites incohérents entre les poses** (IA) : limiter les poses, garder un seul style, accepter des
   placeholders propres avant les assets finaux.
2. **Chronologie illisible** : traité dès le Lot B (portraits, couleurs + symboles, aperçu).
3. **Monstre multi-parties illisible en grand** : calques séparés, surbrillance de la partie visée.
4. **Rendu 2.5D incohérent** si une seule illustration sert de pseudo-modèle : caméra fixe, calques prévus.
5. **Code IA non vérifié** : tests automatisés obligatoires à chaque lot, rien n'est « terminé » sans eux.

## 7. Hypothèses prises (modifiables)

- Chasseurs et monstre **provisoires** (« Compagnon A/B », « Vorgane des brumes ») ; aucun nom canonique.
- Attaque ordinaire : effet à 10 % de C, +8 Résonance. Technique d'arme : ×1,4 dégâts, ×1,5 rupture,
  **sans gain de Résonance** (pour qu'elle ne remplace pas l'attaque).
- Sérum de test unique « Pulsation d'Aether » : coût 30, recul de 15 % de l'initiative de la cible.
- Égalités : effets avant décisions, puis Vitesse la plus haute, puis Chasseurs avant monstres.
- Coût en Résonance et potion consommés à la décision (perdus si l'action est interrompue).
- Un acteur ne redevient jamais prêt avant la résolution de sa propre préparation.

## 8. Ce qu'il me faut de votre part

1. ~~Dépôt GitHub~~ : fait (`Warwiren/Val-Serra-Game`). ~~Godot pour les tests~~ : fait.
2. Jouer quelques combats dans l'écran de débogage et me dire si la chronologie et le choix VIF/CHARGÉ
   ont du sens, avant que je lance le Lot B.
3. Plus tard : trancher pixel art ou illustration HD pour les sprites.
