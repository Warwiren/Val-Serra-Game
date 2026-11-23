# Décision DA — V07

**Verdict : amélioration réelle du décor et bon candidat pour un premier test P30, mais NON VALIDÉ artistiquement comme cible Octopath II.**

L'intégration dans Godot Forward+ doit être notre prochain jalon, sans passer du temps sur une V08 procédurale avant de voir le vrai rendu. À ce stade, on peut juger les silhouettes et le placement. On ne peut pas encore juger l’illumination, les ombres, les reflets ou le pixel art in situ.

### Porte de qualité
1. P30 ×2.5 : chemin et héros lisibles, aucune couronne parasite qui masque le joueur.
2. Marcher et courir sur les trois parcours, notamment à la lisière du ruisseau ; collision tronc / rocher cohérente.
3. Aucun scintillement d’alpha des arbres, ni disparition des végétaux au mouvement de caméra.
4. Comparer avec et sans brume, shader d’eau animé ON/OFF, et zoom ×3.
5. Vérifier FPS sur machine équipée GPU, log import, et captures PNG du **vrai moteur**.
6. Comparaison cote à cote avec les quatre références : juger composition, échelle, profondeur et direction lumineuse ; toute comparaison doit distinguer moteur réel et prévisualisation externe.

### Ordre des corrections après les premiers tests
- Priorité 1 : lumière / ombres / qualité de terrain et transitions, pas davantage de petits objets.
- Priorité 2 : bande riveraine et arbres à fortes silhouettes ; améliorer les modèles réellement visibles en P30.
- Priorité 3 : sprites/animations, puis extension aux bâtiments et autres zones.

Aucune mission Claude n’a été envoyée. Une seule tâche d’intégration se justifiera après revue des captures F6 si des erreurs restent à corriger.
