# P5.3-B — V3 hybride : matières V2 + forme des zones mixtes de la V1 (21/11/2026)

> **P7.2 (nettoyage autorisé par le créateur)** : les médias de ce rapport (`docs/media/…`) ont été retirés du projet
> actif. Ils restent dans l'historique Git : `git checkout d88eac4 -- docs/media/<dossier>`.

Branche `p5-3b-v3-hybride` (depuis `p5-3b-v2-transitions`). Demande : garder la palette, la sobriété et le calme de la V2,
retrouver les transitions organiques de la V1 + calage, sans ses points orange ni son bruit. Shader et répartition
seulement : **aucun nouvel asset, aucune texture modifiée**. Médias : `docs/media/p5_3b_v3h/`.

## 1. Faisabilité sans nouveaux assets : oui

Ce qui rend la V1 + calage naturelle, c'est le **dessin** de son herbe usée (îlots organiques d'herbe et de terre de
0,3 à 2 m), pas sa couleur. Ce dessin se sépare proprement : vert au-dessus du rouge = herbe (48 % des pixels), sinon
terre (mesuré sur `art/p53/sol/herbe_usee.png`). On peut donc s'en servir comme **masque** et peindre au travers les
matières V2. Aucune couleur V1 n'est affichée.

## 2. Ce que fait la V3 hybride (`sol_foret_p53b.gdshader`, matériau `materiau_p53b3h`)

Base : la V2 transitions (hauteurs normalisées par matière, bande d'herbe clairsemée calculée par proximité du chemin).
En plus :

- **Herbe clairsemée recomposée** dans la bande des chemins : masque herbe / terre tiré du dessin V1 (deux échantillons
  décalés, anti-répétition) → herbe dense V2 là où la V1 a de l'herbe, terre V2 là où elle a de la terre. La hauteur suit
  le masque (îlots d'herbe au-dessus de la terre), si bien que le mélange par hauteur découpe le bord selon ces formes.
- **Bande élargie** : proximité lue à 1,0 et 2,0 m (au lieu de 0,8 / 1,6 m).
- **Pieds d'arbres et de rochers** : même herbe clairsemée recomposée sur la litière et la mousse (poids 0,8),
  pour une intégration plus douce.
- Ailleurs (pentes, sous-bois hors litière) : herbe usée V2 inchangée. Cœur des chemins : terre V2 pleine.
- Pas de bruit ajouté : aucune échelle plus fine que celles de la V2 transitions.

Réglages : `V3H_RAYONS`, `V3H_RELIEF` (0,5), `V3H_OBJETS` (0,8) dans `src/explore25/sol_foret.gd`.

## 3. Comparaison au même cadrage (V1 + calage / V2 transitions / V3 hybride)

Vues : `comparaison_7_vues.jpg` (chemin principal, embranchement, zone herbeuse, pied d'arbre, pied de rocher, pente,
carte entière ×2), `gros_plans_x3.jpg` (1:1), `combat_foret.jpg`, `combat_vorgane_gros_plan.jpg`,
`deplacement_3_variantes.mp4`.

Transitions (`mesures_transitions.txt` ; zone mixte = part de l'image où l'herbe et la terre se mêlent ; frontière =
longueur de la limite herbe / terre) :

| Vue (×3) | V1 + calage | V2 transitions | **V3 hybride** |
|---|---|---|---|
| chemin principal | 33,3 % / 80 | 31,8 % / 62 | **33,0 % / 67** |
| embranchement | 58,9 % / 189 | 47,1 % / 135 | **51,6 % / 151** |
| zone herbeuse | 41,8 % / 130 | 39,8 % / 107 | **42,5 % / 123** |
| pied d'arbre / bord | 39,6 % / 111 | 34,2 % / 86 | **37,5 % / 98** |
| pied de rocher | 39,9 % / 107 | 34,4 % / 84 | **37,0 % / 90** |

Rappel : la V1 + calage est gonflée par ses points orange, comptés comme de la « terre » dans l'herbe.

Calme et palette (`mesures_bruit_vorgane.txt`, moyenne des 5 vues) :

| | V1 + calage | V2 transitions | V3 hybride |
|---|---|---|---|
| grain fin (1–2 px) | 12,0 | 11,0 | **11,1** |
| saturation | 64,1 | 59,9 | 61,9 |
| luminosité | 66,7 | 63,5 | 65,2 |

Lisibilité du Vorgane en combat (écart de luminosité avec le sol qui l'entoure) : V1 + calage 16 %, V2 transitions 4 %,
**V3 hybride 8 %** (le sol mixte, plus clair, le détache mieux que la V2 ; toujours moins que la V1). Le groupe reste
lisible dans les trois variantes.

## 4. Lecture

- **Palette et calme de la V2 : conservés.** Couleurs olive / ocre, grain au niveau de la V2 (11,1 contre 12,0 pour la
  V1 + calage), aucun point orange.
- **Transitions** : au niveau de la V1 + calage sur le chemin principal et les zones herbeuses ; nettement meilleures
  que la V2 transitions partout ; un peu derrière la V1 aux embranchements (51,6 contre 58,9 %, écart en partie dû au
  bruit orange de la V1). Plus d'îlots verts tachetés sur la terre : les zones mixtes ont des formes peintes.
- **Pieds d'objets** : plus doux que la V2 transitions (terre et herbe mêlées autour des rochers).
- **Limites** : à ×2 sur la carte entière, les chemins se lisent encore comme des bandes un peu plus nettes que dans la
  V1 ; la répartition générale vient toujours de la carte V07 floue. Le sol du combat reste un peu plus sombre que celui
  de la V1 (Vorgane à 8 % de contraste).

**Proposition** : retenir la V3 hybride, sous réserve de votre revue en jeu. F5 démarre dessus ; **U** : V3 hybride →
V2 transitions → V2 → V1 + calage → V1 → P5.3 → P5.2 → V07 ; **Y** : carte entière. Combat forêt (F6) en V3 hybride.

## 5. Si vous voulez aller plus loin un jour (non nécessaire pour ce choix)

- Une **carte de répartition des matériaux** peinte (PNG 8 bits, 1152 × 896 px, 32 px/m, alignée sur le terrain ;
  R = herbe dense, G = herbe clairsemée, B = terre) supprimerait l'effet de bandes encore visible à ×2.
- Un sol de combat éclairci d'environ 10 % améliorerait la lecture du Vorgane.

## 6. Tests réellement exécutés (Godot 4.7.2)

- `tests/p53b_pilote_smoke.gd` : 24 / 24 (V3 hybride au démarrage, matières V2 et masque V1, aucun calage, V2 transitions
  conservée, ordre de U sur 8 variantes, Y, collisions et déplacement inchangés) ; `tests/p52_sol_smoke.gd` : 15 / 15 ;
- `run_tests` 71 / 71 ; avant-poste de bout en bout 25 vérifications sans échec ; `p4` 29 / 29 ; `p4_sondes` 20 / 20 ;
- V09A, V09B.5, V09C, V11, P5 (combat) : 0 échec ;
- forêt : parcours principal 8 / 9, boucles 6 / 7, course 8 / 9, aucune chute (identique) ; arbres 11 / 11 ;
  occlusion 12 / 12 ; F5 sans erreur.
