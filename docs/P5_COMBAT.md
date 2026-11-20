# P5 — refonte du combat (branche `p5-combat`, 20/11/2026)

Demande du créateur (20/11/2026) : « nouvelle branche -> refonte du combat, on va placer plutôt les héros sur la
gauche et le monstre sur la droite et adapter le décor à l'environnement. Demande-moi si tu as besoin d'assets. »
Point de départ : `p4-9-v07-test` (forêt V11 validée le 20/11/2026). F5 inchangé.

## 1. Disposition

Prototype (Aren, Ilya, Throné contre le Vorgane), **toutes arènes** :
- groupe à **gauche**, tourné vers la droite : Aren (380, 500), Ilya (252, 468), Throné (130, 492) ;
- Vorgane à **droite**, tourné vers la gauche : (950, 506).
Mêmes écarts qu'avant, en miroir (avant P5 : groupe à droite, monstre à gauche). Les vues gèrent déjà les deux
orientations (bond du Vorgane, pas en avant et frappes, tir d'Ilya, textes flottants) : vérifié sur un combat
automatique complet. Interface inchangée.

## 2. Décor adapté au lieu

- **Forêt** (nouveau, `GameState.arena = "foret"`) : le décor est **la forêt d'exploration elle-même** (V07B validée :
  mêmes modèles, même lumière, sans brouillard), rendue depuis une caméra de combat (`tools/p5/decor_foret.gd`) :
  clairière ouest, lisière dense d'arbres, rochers et buissons au fond, chemin et herbe au premier plan où se tiennent
  les combattants (≈ 87 px / m : les personnages ont la même taille relative qu'en forêt). Arène
  `src/presentation/arena_foret.gd` (même interface que l'arène peinte) : soleil haut à droite qui éclaire aussi le
  Vorgane, poussière dorée discrète, lieu affiché « Forêt de la lisière ».
- **Lisière de l'avant-poste** (illustration peinte, nuit) : inchangée, utilisée pour la rencontre de l'avant-poste
  (F6) ; la nouvelle disposition s'y applique aussi (`docs/media/p5/combat_lisiere_miroir.png`).

Ouvrir : **F6** sur `scenes/battle/combat_foret.tscn` (ou `--start=proto-battle --arena=foret`).

## 3. Ce qui manque (assets demandés au créateur)

1. **Aren et Ilya de combat dans leur apparence validée** : en combat, ce sont encore les poses P4.5 / P4.7
   (`art/p45/combat/`, Aren « gris », Ilya à cape verte de l'ancienne apparence), alors qu'en exploration ils ont
   l'apparence V09B.5 / V09C. Séquences nécessaires (profil droit, tournés vers la droite, même échelle que les
   planches actuelles) : attente de combat (4–8 images), préparation, avance, attaque, impact / retour, garde, touché,
   K.O., technique d'Aether (charge + libération) ; pour Ilya : dégainer, tir (avec recul), tir chargé.
2. **Throné** : design non revu depuis P4 ; à confirmer (il garde son apparence actuelle en attendant).
3. **Décor forêt** : le rendu est un premier jet tiré des modèles du jeu. Une illustration peinte de la forêt de
   jour (comme la lisière de l'avant-poste), avec un premier plan séparé (feuillage devant les combattants), donnerait
   un rendu plus riche.

## 4. Tests

`tests/p5_combat_smoke.gd` (nouveau) : F6 ouvre le combat, arène forêt, groupe à gauche / Vorgane à droite, orientations,
lieu affiché. Non-régression : `run_tests` 71/71, avant-poste de bout en bout (combat, victoire, défaite, retour),
`p4` 29/29, `p4_sondes` 20/20, V09A, V09B.5, V09C, V11, F5 sans erreur, `simulate_battle` (règles inchangées).

Médias (`docs/media/p5/`) : `combat_foret.png`, `combat_lisiere_miroir.png`, `combat_foret_auto.mp4` (40 s de combat
automatique dans la forêt).
