# Val'Serra — V07B, paquet de prévalidation Godot

## Statut exact
**V07B corrige des erreurs de la scène V07 d'après le code source et les fichiers réels.** Les fichiers 3D, textures, parcours et shaders ne sont pas artistiquement validés. Le moteur Godot 4.7.2 n'est **pas disponible dans l'environnement de préparation**, donc aucun test runtime, Forward+, GPU, shader d'eau ou FPS n'a été exécuté ici.

## Correction des risques bloquants de V07
1. **Marche P4.8** : `_hero_anim.set_scale_k(25.2/63)` et `_ilya_anim.set_scale_k(26/65)` sont appelés. Sans cela, `Actor25` gardait `STRIDE_M=0.42` au lieu d'environ `0.12` m/image, altérant la marche.
2. **Touche N** : elle masque le décor **ET** désactive les collisions des arbres/rochers concernés (avec mise à jour différée), puis les restaure à la réactivation.
3. **Limites de carte** : barrières relevées pour couvrir les reliefs compris entre environ 0 et 2,11 m. Les barrières elles-mêmes restent invisibles.
4. **Apparition des personnages** : hauteur initiale alignée sur le sol local (0,19 m environ) plutôt qu'à `Y=1.1`, ce qui provoquait une chute au démarrage.
5. **Repères M** : positions verticales calculées depuis le maillage du terrain, et non `Y=0.055` partout ; repères visibles sur les talus.
6. **Touche F** : coupe/active à la fois le brouillard atmosphérique et volumétrique.

## Installation dans le projet de référence
- Base : dépôt `Warwiren/Val-Serra-Game` à la branche `p4-8-marche`, moteur **Godot 4.7.2**.
- Décompresser **le dossier complet** `ValSerra_P49_V07B_PREFLIGHT_GODOT` à la racine du projet (ne pas remplacer la V07 précédente ; cette V07B est autonome).
- Ouvrir `res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn` et lancer avec **F6**.
- `F5` reste le lancement habituel de l'avant-poste, non modifié.
- Touches : ZQSD/flèches, Maj, 1/2/3, M, N, V, F, H, R.

## Smoke-test Godot reproductible
Depuis la racine du **projet Godot** :

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/V07B_SmokeTest.gd
```

Cela vérifie l'import et le chargement de la scène sans prétendre valider le rendu. Toute sortie d'erreur GDScript, GLB ou shader doit être corrigée avant la revue graphique.

## Contrôle visuel réel requis
- Avec une carte graphique et **Forward+**, observer les effets de brouillard et de glow.
- Tester marche 2,2 m/s, course 3,6 m/s, arrêt et demi-tour sur les trois parcours.
- Vérifier `N` (collisions), `M` (marqueurs), `V` (eau), `F` (brouillard) et les limites.
- Réaliser captures P30 ×2,5 et ×3 du seuil, de la clairière et du ruisseau, avec Aren/Ilya au premier plan.
- Mesurer FPS, matériel, résolution et signaler les défauts de transparence, éclairage et glissement des pieds.

## Artistique
La V07B ne remplace aucune décision artistique : les assets Quaternius CC0 restent provisoires et leur simplicité relative à l'ambition Octopath II doit être jugée en situation. Ne pas intégrer dans F5 avant validation.
