# P5.3 — diagnostic graphique des sols (avant modification), 21/11/2026

Branche `p5-3-sols` (depuis `p5-2-environnement`, base technique provisoire). **Aucun changement de rendu à ce
stade** : seul l'outil de captures (`tools/p5/captures_sol.gd`) a gagné des vues rapprochées et des variantes d'ombre.
Rendu Vulkan logiciel (lavapipe), F5 à 24°, ×3. Médias : `docs/media/p5_3/`.

## 1. Ombre du terrain (point technique demandé)

En P5.2, le terrain ne projetait plus d'ombre, pour supprimer des « hachures ». **Mesure : c'était un mauvais
remède.**

| Variante (même cadrage) | Grain dans une ombre d'arbre sur le chemin* | Auto-ombrage du relief |
|---|---|---|
| P5.2 : terrain sans ombre | 7,91 | aucun |
| terrain avec ombre (réglages du soleil inchangés) | 7,19 (−9 %) | oui (1 à 4 % de l'écran, −14 à −20 % de lumière) |
| terrain avec ombre + filtre d'ombre douce qualité 4 | 5,30 (−33 %) | oui |

\* écart moyen à l'image floutée (2 px) sur la même zone d'ombre ; plus bas = plus propre.

- **Cause réelle des hachures de P5.2** : le micro-relief (normales perturbées par le bruit) sous un soleil rasant,
  déjà retiré en P5.2. Le terrain qui projette son ombre ne crée pas d'hachures (+0,03 à +0,2 de grain global).
- **Effet secondaire de P5.2** : sans le terrain dans la carte d'ombres, les ombres douces des arbres et des
  personnages se **désagrègent en points** (voir `diagnostic_ombres.png`, ombre des personnages sur le chemin), et le
  relief perd son auto-ombrage (pentes à contre-jour).
- **Solution mesurée proposée** : rétablir l'ombre du terrain et passer le filtre des ombres douces du soleil de la
  qualité 2 (défaut) à 4 (ombres plus propres de 33 %, même forme et même douceur ; coût GPU modéré, à vérifier
  sur votre machine).

## 2. Diagnostic des matières (vues rapprochées, `diagnostic_sol_vues_proches.png`)

1. **Herbe** : une seule nappe olive avec de grandes taches (« camouflage ») ; il manque la densité (herbe drue /
   clairsemée), l'usure près des chemins et sous les arbres, un grain de brins lisible de près.
2. **Chemins** : le liseré sombre continu et le bord net donnent l'effet « découpé » ; il manque une bande de
   transition (20 à 60 cm) où l'herbe se clairsème et où la terre apparaît par plaques.
3. **Pentes** : la terre / roche se lit comme un gravier rose uniforme (bruit fin) ; passage net herbe → roche ; pas de
   strates ni de végétation accrochée.
4. **Pieds d'objets** : disques de litière trop réguliers sous les arbres ; rochers sans mousse ni terre remontée ;
   plantes posées sans touffe au sol.
5. **Combat** : le décor est rendu depuis la forêt ; il hérite automatiquement de tout progrès du sol.

## 3. Le shader suffit-il ?

- **Pour la logique** (où mettre la transition, l'usure, la roche, le contact) : **oui**, le shader et les cartes
  existantes suffisent ; c'est ce que je peux améliorer tout de suite.
- **Pour la matière de près en HD-2D** (brins d'herbe, terre tassée, roche stratifiée, litière) : **non, pas
  sérieusement**. Un bruit procédural donne du « camouflage » ou du « gravier » ; augmenter le bruit ne le règle pas.
  Les textures Quaternius du projet sont des atlas de couleurs, inutilisables pour un sol.

## 4. Assets demandés (ce qui changerait sensiblement le résultat)

Emplacement prévu : `art/p53/sol/` (textures) et `art/p53/decals/` (éléments). Style : peint, cohérent avec les
modèles Quaternius et la palette de la forêt ; **vue de dessus, éclairage neutre (sans ombre ni reflet peints)**.

| # | Asset | Dimensions | Format | Répétable | Transparence | Usage |
|---|---|---|---|---|---|---|
| 1 | herbe courte dense | 1024 × 1024 (couvre 4 × 4 m) | PNG 8 bits sRGB | oui, sans raccord | non | base de l'herbe |
| 2 | herbe clairsemée / usée (terre entre les touffes) | 1024 × 1024 | PNG | oui | non | bords de chemin, sous les arbres, passages |
| 3 | terre de chemin tassée (petits cailloux, traces) | 1024 × 1024 | PNG | oui | non | chemins |
| 4 | roche de pente (roche stratifiée et terre) | 1024 × 1024 | PNG | oui | non | pentes non praticables |
| 5 | litière de sous-bois (aiguilles, feuilles mortes) | 1024 × 1024 | PNG | oui | non | pieds d'arbres, sous les couverts |
| 1h–5h | carte de hauteur de chacune (même nom + `_h`) | 1024 × 1024 | PNG 8 bits niveaux de gris | oui (alignée sur sa texture) | non | transitions organiques : l'herbe « passe au-dessus » de la terre au lieu d'un fondu |
| 6 | planche « bordures de chemin » : 12 à 16 éléments séparés (touffes débordantes, pierres plates, racines) | 2048 × 1024 | PNG RGBA | non | oui (fond transparent, bords nets) | posés le long des chemins |
| 7 | planche « pieds d'objets » : 4 à 6 couronnes (racines, mousse, terre remontée) | 1024 × 1024 | PNG RGBA | non | oui | sous les arbres et rochers |

**Minimum utile** : 1, 2, 3, 4 avec leurs cartes de hauteur. 5, 6 et 7 sont un plus.

## 5. Ce que je propose ensuite (au choix du créateur)

- **A — sans attendre d'assets** : ombre du terrain rétablie + filtre qualité 4 ; bandes de transition progressives
  sur les chemins (herbe qui se clairsème, plaques de terre), liseré allégé ; herbe à densité et usure variables ;
  pentes : transition herbe → terre → roche par la pente et l'altitude ; contacts moins réguliers. Comparaisons avant /
  après mesurées, vidéo, tests. La matière restera procédurale.
- **B — avec les assets ci-dessus** : même logique de mélange, mais la matière vient des textures peintes (mélange par
  hauteur) ; résultat attendu nettement plus proche de la direction HD-2D. A peut être fait d'abord : le travail de
  transitions est réutilisé tel quel par B.
