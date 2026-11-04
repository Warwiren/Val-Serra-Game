# Prototype artistique « HD » — analyse avant production

*Objectif : vérifier si la qualité de l'illustration conceptuelle (Chasseurs détaillés, Vorgane cristallin,
forêt nocturne profonde, effets d'Aether) est **reproductible en jeu**, et à quel coût, sans toucher au
système de combat.*

## 1. Principe technique retenu : « cut-out » articulé (comme Spine ou Live2D, mais natif Godot)

Une illustration fixe ne s'anime pas telle quelle. Elle doit être **redessinée en calques** : un calque par
segment du corps, posés sur **le même canevas** (comme un fichier Photoshop/Krita), avec les zones cachées
complétées (l'épaule sous le bras, la hanche sous le manteau…). Dans Godot :

- un **Skeleton2D** avec des **Bone2D** (bassin → torse → tête ; épaules → bras → avant-bras ; hanches →
  cuisses → jambes ; cape ; arme) ;
- chaque calque est accroché à son os ; l'**AnimationPlayer** anime les rotations des os
  (repos, frappe, garde, impact, capacité, K.O.) ;
- les animations sont décrites en **données** (`data/rig/*.json`) : la même animation « épée » sert à tout
  Chasseur qui a le même squelette. **C'est ce qui rend la production reproductible.**

Aucune conversion en 3D n'est faite ni nécessaire.

## 2. Assets à créer

| Asset | Contenu exact | Volume par personnage |
|---|---|---|
| **Chasseur articulé** | 12–14 calques sur un canevas commun : tête (cheveux inclus), torse, bassin/pans de manteau, cape, bras avant (haut + avant-bras/main), bras arrière (idem), jambe avant (cuisse + jambe/botte), jambe arrière (idem), arme séparée. Zones cachées complétées. Fiche de pivots (articulations). | 1 illustration découpée (≈ 1 à 2 jours d'illustrateur, ou ½ à 1 jour avec IA + retouche) |
| **Monstre articulé** | Corps, tête, mâchoire, cou, pattes, queue, et pour **chaque partie ciblable** : état intact, état brisé, et éclats séparés si elle doit voler en morceaux. Chair/blessure sous les plaques. | 1 illustration découpée + 2 à 3 états par partie (≈ 2 à 4 jours) |
| **Arène 2.5D** | 6 à 8 plans peints séparément : ciel/lune, crêtes lointaines, forêt lointaine, forêt moyenne + tour/lanternes, arbres de cadrage, sol, premier plan. Chaque plan déborde un peu du cadre (pour le parallax). | ≈ 1 à 2 jours par arène (moins avec IA + recadrage) |
| **Effets (VFX)** | Arc de taille, étincelles, onde, glyphe d'Aether, éclats de cristal | Réutilisables partout ; en grande partie générés par le moteur |
| **Interface** | Icônes d'actions, de types de dégâts, cadres de portraits | Une fois pour tout le jeu |

## 3. Ce que l'IA d'image peut produire, et ce qui reste manuel

| Tâche | IA d'image (Midjourney, GPT-image, Flux…) | Travail manuel indispensable |
|---|---|---|
| Recherche de style, concept arts, moodboards | ✅ Très bien (votre illustration en est la preuve) | Choix, cohérence de la charte |
| Plans de décor d'arène | ✅ Bien, si chaque plan est généré à part (ou image entière puis séparation) | Découpe des plans, **complétion des zones cachées** (inpainting), raccords, bords qui débordent pour le parallax |
| Portraits de dialogue / chronologie | ✅ Bien | Cohérence d'un portrait à l'autre, recadrage |
| Chasseur « de profil en pose neutre » à découper | ⚠️ Possible comme base | **Découpe en calques, redessin des articulations et des zones cachées**, correction des mains et de l'arme, alignement des pivots |
| Même personnage sous plusieurs angles / poses | ❌ Peu fiable (le visage, la tenue et l'arme dérivent) | Inutile avec le cut-out : **une seule pose de référence suffit**, les animations viennent du squelette |
| États brisés d'un monstre | ⚠️ Incohérent d'une image à l'autre | Dessiner l'état brisé **sur le calque intact** (retouche), découper les éclats |
| Effets (étincelles, ondes, arcs) | ⚠️ Possible en textures | Le moteur les produit mieux (particules, shaders) |
| Conversion d'une illustration en modèle 3D jouable | ❌ Non fiable, et non nécessaire ici | — |

## 4. Ce que Claude peut réellement intégrer

- **Oui** : le squelette Godot (Skeleton2D/Bone2D), les animations (AnimationPlayer, générées à partir de
  données), les shaders (lumière de contour, flou de profondeur, brume), les particules, la caméra, les
  effets de rupture (éclats qui volent), l'intégration au combat existant, les outils d'import et la fiche de
  découpe que devra suivre l'illustrateur ou l'IA.
- **Oui, mais avec une limite de qualité** : dessiner moi-même les calques (en vectoriel, style « cel-shading »).
  C'est ce que je fais pour ce prototype : la **structure** est exactement celle d'un asset final (mêmes calques,
  mêmes pivots, même canevas), mais le **rendu** reste celui d'un dessin vectoriel propre, pas d'une peinture
  numérique comme votre illustration.
- **Non** : produire une peinture numérique de qualité commerciale. Pour l'atteindre, il faudra remplacer mes
  calques par des calques peints (illustrateur, ou IA + retouche) **au même cadrage** : c'est un remplacement de
  fichiers, sans changer le code.

## 5. Ce que le prototype va démontrer

1. Un Chasseur (le héros) entièrement articulé : repos, frappe, garde, impact, capacité, K.O.
2. Le Vorgane redessiné et articulé (tête, mâchoire, griffe, queue), dont la **carapace éclate en morceaux**.
3. Une arène forestière nocturne en plusieurs plans : lune, rayons de lumière, brume animée, lanternes, cristaux.
4. Une capacité d'Aether : charge en spirale, projectile, impact, flash lumineux, mouvement de caméra.
5. L'interface du Lot B conservée, avec quelques améliorations (mention « FAIBLESSE ! », lisibilité).

Le tout **jouable**, branché sur le même CombatCore, accessible depuis l'écran d'accueil.

---

# Résultats du prototype (réalisé)

## Ce qui est jouable

| Scène | Accès | Contenu |
|---|---|---|
| **Combat « prototype artistique HD »** | Écran d'accueil → **✦ Prototype artistique HD** | Le vrai combat (même CombatCore, même interface) avec le héros articulé, le Vorgane articulé, l'arène nocturne, les effets d'Aether |
| **Atelier d'animation** | Écran d'accueil → **✦ Atelier d'animation** | Boutons pour déclencher chaque animation du Chasseur (repos, frappe, garde, impact, marche, K.O., capacité d'Aether) et du Vorgane (coup de griffe, annonce, souffle, rupture de chaque partie), affichage du squelette |

## Ce qui a été construit

| Élément | Réalisation | Fichiers |
|---|---|---|
| Chasseur articulé | 13 calques sur un canevas commun, 14 os (Skeleton2D/Bone2D), 7 animations (AnimationPlayer) générées depuis des données, liseré de lumière lunaire (shader) | `art/hd/hero/`, `data/rig/hero_hd.json`, `data/rig/anim_sword.json`, `src/presentation/rig_hunter_view.gd`, `rim_light.gdshader` |
| Vorgane articulé | 15 calques, 6 os (corps, queue, tête, mâchoire, patte, griffe), animations procédurales (repos vivant, coup de griffe, souffle gueule ouverte, impact, mort) ; **carapace en 7 éclats** qui s'envolent et révèlent la plaie ; griffe et glande avec état brisé | `art/hd/vorgane/`, `data/rig/vorgane_hd.json`, `src/presentation/rig_monster_view.gd` |
| Arène 2.5D nocturne | 8 plans (ciel et lune, crêtes, deux rangées de forêt, tour éclairée / palissade / bannière / lanternes, arbres de cadrage, sol, premier plan) + rayons de lune additifs, brume animée, flou de profondeur, 8 lumières, particules | `art/hd/arena/`, `tools/art/gen_arena_hd.py`, `src/presentation/stage.gd` |
| Capacité d'Aether | Charge en spirale de particules autour de la main, geste de lancer, onde, projectile en arc avec traînée, impact (double onde + gerbe), **éclair lumineux qui éclaire réellement le décor**, zoom et secousse de caméra | `rig_hunter_view.gd`, `battle_scene.gd`, `rig_viewer.gd` |
| Interface | Conservée ; ajout de la mention **« FAIBLESSE ! »** sur les coups efficaces, marqueurs de parties plus transparents (la glande reste visible), traînée de lame | `battle_scene.gd`, `monster_view.gd`, `fx.gd` |
| Contrôle qualité des assets | Tests automatiques des fiches de squelette (calques présents, os valides, animations cohérentes) | `tests/unit/test_rig.gd` |

## Mon évaluation

**Ce qui atteint l'objectif.** L'*ambiance* et la *mise en scène* de l'illustration sont reproduites par le
moteur : nuit bleutée, lune et rayons, profondeur par plans et brume, lanternes chaudes, cristaux lumineux,
liseré de lumière sur les silhouettes, impacts, éclats, flash d'Aether, caméra. Les animations articulées
donnent du poids aux frappes (armé, fente, suivi) et la rupture de la carapace est très lisible.

**Ce qui n'atteint pas l'objectif.** Le *rendu des illustrations elles-mêmes* : mes calques sont des dessins
vectoriels en aplats ; l'illustration conceptuelle est une peinture numérique (volumes, textures, anatomie
fine, détails d'équipement). Cet écart ne se comble pas avec du code : il faut des calques **peints**.

**Est-ce reproductible sans production irréaliste ?** Oui, à condition de respecter la fiche de découpe :
- **Chasseurs** : un squelette commun et des animations partagées par famille d'arme. Chaque nouveau
  personnage = une illustration découpée (½ à 2 jours) + une fiche de pivots (½ jour). C'est réaliste pour
  4 Chasseurs.
- **Monstres** : plus coûteux (squelette propre, états brisés, éclats), 1 à 4 jours chacun. Réaliste pour un
  petit bestiaire de démonstration, à surveiller pour la version complète (privilégier des familles de
  monstres partageant un squelette).
- **Arènes** : 8 plans par lieu, mais réutilisables avec variations de lumière (nuit, aube, brouillard).

**Risques identifiés.**
1. Cohérence de style entre personnages si l'IA est utilisée : fixer une charte (palette, épaisseur de contour,
   lumière) et retoucher systématiquement.
2. Mélange de styles en jeu tant que tous les personnages ne sont pas refaits (visible ici : les deux
   compagnons sont restés en style Lot B).
3. Performances à vérifier sur une vraie machine (flou et liseré sont des shaders) : touche **F3**.
4. Les animations du monstre sont pour l'instant écrites en code (tweens) ; pour un illustrateur-animateur,
   il faudra les passer en AnimationPlayer comme le héros (même principe, prévu).

**Recommandation.** Valider cette chaîne avec **un vrai calque peint** : faire produire (illustrateur ou IA +
retouche) le héros selon la fiche de découpe, le déposer à la place de mes fichiers, et comparer dans
l'Atelier d'animation. Si le résultat tient, la direction « 2.5D illustrée articulée » est confirmée pour la
production.
