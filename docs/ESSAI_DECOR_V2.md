# Essai de décor v2 — corrections de l'essai v1 (NON intégré dans `main`)

Branche **`essai-decor-v2`** (depuis `essai-decor-v1`). Anciennes ressources conservées (fond, sprites, essai v1).

## Lancer
- **F5** lance directement l'essai : réglage du projet **`val_serra/essai_decor = "v2"`** (dans `project.godot`,
  ou Projet › Paramètres du projet › Val Serra). **Réversible** : vider la valeur (jeu normal) ou mettre `v1`.
- Ligne de commande (prioritaire) : `--essai=v2`, `--essai=v1`, `--essai=aucun`. En jeu, **F4** : sol d'essai / fond actuel.

## Corrections
| Demande | Fait |
|---|---|
| Arbre de droite | remplacé (même essence, en miroir pour éviter un jumeau visible), à l'échelle de **son** gabarit Blender (largeur 0,97 × celle du grand arbre ; `docs/media/gabarits_exploration/arbre_d/`) ; tronc et feuillage séparés, emprise, collision, tri et transparence d'origine |
| Rochers et végétation flottants | **cause : doublons**. Le sol peint contient déjà ses pierres, herbes et fleurs ; les 27 détails illustrés du lot précédent étaient recollés par-dessus, avec leurs propres ombres et un tri de personnage (d'où l'effet flottant et le passage au premier plan). Dans l'essai, seuls les **cristaux d'Aether** (absents du sol peint) sont gardés. Les gros rochers moussus du bas sont ceux **du sol peint** : ils ne passent plus devant les personnages |
| Couture du chemin | le tracé de référence est **lissé (coudes arrondis)** : plus de rupture au coude ; la bande de pavés suit une courbe continue |
| Bord inférieur | arête du talus repérée colonne par colonne et rendue légèrement irrégulière (petites avancées d'herbe) ; ombre du muret retirée (muret masqué dans l'essai) |
| Maison | **géométrie exacte du gabarit** (silhouette, toit, porte, 3 fenêtres, emprise, collision inchangés) ; matières du concept posées zone par zone (`tools/essai/maison_matieres.py`) : ardoises moussues alignées sur la pente du toit, enduit, colombages, soubassement de pierre ; **porte et fenêtres du concept redimensionnées dans les rectangles du gabarit** ; éclairage du gabarit conservé |
| Vorgane, personnages | inchangés |

## Captures en jeu (1280 × 720, actuel / v1 / v2) — `docs/media/essai_v2/`
`rochers_bas.jpg`, `arbre_gauche.jpg`, `arbre_droit_et_maison.jpg`, `maison.jpg`, `comparatif_depart_1280.jpg`,
vidéo `essai_v2_demo.mp4` (parcours clavier puis démo : maison, arbres, dialogue, combat, retour).

## Vérifications (essai v2 actif, comme avec F5)
| Contrôle | Résultat |
|---|---|
| Tests automatiques | 66 / 66 |
| Parcours clavier (déplacements, collisions) | RÉUSSI |
| Approches du garde | 11 / 11 |
| Retour de combat (victoire, défaite) | RÉUSSI |
| Démo complète (derrière la maison et l'arbre, dialogue, combat, retour) | réussie |
| Performances exploration (rendu logiciel) | 67,3 images/s (essai v2) contre 61,9 (jeu actuel) : moins d'objets à dessiner (31 contre 53) ; +5 Mo de textures |
| Combat | inchangé (29,0 contre 26,6 images/s, écart de mesure) |

## Limites restantes
- Maison : la cheminée reste celle du gabarit (bloc simple) ; le pignon gauche et le soubassement montrent des
  raccords de texture ; c'est un **transfert de matières**, pas une repeinture — une repeinture sur
  `maison_gabarit.png` sera plus fine.
- Chemin : bande un peu plus large que 2,6 m par endroits (66 % des pavés dans le tracé exact) ; recouvrement
  lumineux peint sur le chemin non lié aux lanternes.
- Ombres au sol des arbres : celles des anciens arbres (rondes).
- Mélange de finesse : décor illustré fin, personnages en gros pixels (attendus avec les nouveaux sprites).
