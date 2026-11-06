# Essai de décor v1 — sol recalé, grand arbre, buissons (NON intégré)

Branche **`essai-decor-v1`** (depuis `sol-illustre`). **Rien n'est intégré par défaut** : le jeu est inchangé
sans option. Pour voir l'essai : `godot --path . -- --essai=v1` (F4 : sol d'essai / fond actuel en jeu).
Comparatifs 1280 × 720 avec les vrais personnages et le Vorgane : `docs/media/essai_v1/`.

## 1. Analyse des références reçues (4 planches, `art/source/concepts_2026-11-06/`)
| Planche | Détourage | Projection / échelle | Usage dans l'essai |
|---|---|---|---|
| C — arbre, maison, buissons (1536×1024) | **vraie transparence** ; halo d'ombre douce autour des objets (supprimé par seuil) | arbre et buissons : vue de face légèrement plongeante, compatible ; maison : voir § 4 | **arbre et 5 buissons** |
| A — kit annoté (1536×1024) | transparence, mais **textes et étiquettes incrustés** | « arbre_tronc » contient en fait l'arbre entier | non utilisée (doublon de C) |
| B — kit + palette (1500×1000) | **fond gris peint opaque** (pas de transparence) | — | référence de couleurs |
| D — kit décomposé (1500×750) | **fond gris peint opaque** ; tronc nu et feuillage séparés mais pas superposables à l'arbre entier | — | non utilisée |
Toutes sont en couleurs de jour chaudes : un **étalonnage crépusculaire** est appliqué (couleurs rapprochées à 60 %
de la lisière peinte du sol), sinon elles tranchent avec le sol et l'arène.

## 2. Sol : recalage de l'esquisse v0 (`tools/essai/sol_recalage.py`)
Correction **par traitement de l'image fournie** (pas de nouvelle peinture) :
1. l'ancien chemin est effacé avec l'herbe de l'esquisse prise juste au-delà, parallèlement au tracé (même
   échelle, même perspective) ;
2. la bande de pavés de l'esquisse est reposée **sur l'axe exact** et ramenée à **2,6 m** (bordure comprise) ;
3. le gros rocher qui chevauchait la limite praticable est remplacé par de l'herbe voisine ;
4. la lumière chaude déjà peinte est conservée (`--sans-lumieres`), les ombres actuelles des objets sont ajoutées,
   sauf celle du muret, masqué dans l'essai car le sol peint son propre bord bas.
Contrôle de l'importeur (pavés repérés à la couleur) : chemin de l'esquisse décalé de (−27, −30) px, 36 % des
pavés dans le tracé → après recalage (6, −6) px, **67 %** dans le tracé (le reste : fleurs violettes repérées comme
pavés, bords).
**Défauts visibles** : coude anguleux avec une couture, une ou deux traînées d'herbe recopiée au coude. Une
version repeinte sur `chemin_trace_exact.png` restera meilleure ; ce recalage sert à juger le rendu en jeu.

## 3. Grand arbre et buissons (`tools/essai/concepts_vers_sprites.py`)
- **Arbre** (planche C) : 300 × 283 à l'écran (gabarit 307 × 331), pied posé sur le pied de l'arbre actuel ;
  **tronc et feuillage séparés** par la couleur (écorce, branches et butte du pied / feuillage). Les deux calques
  gardent l'emprise, la collision et la ligne de tri de l'arbre actuel ; le feuillage s'efface localement quand un
  personnage passe derrière (`docs/media/essai_v1/arbre_passage_derriere.png`).
- **Buissons** : 5 silhouettes différentes (feuillu clair, fleurs violettes, dense sombre, fleurs claires…), chacune
  à la place d'un buisson actuel, ×1,15 sa largeur (même emprise, sans collision).
- Limites : l'ombre portée au sol reste celle de l'ancien arbre (ronde) ; l'arbre de droite (`arbre_d`) et les
  arbres peints dans la lisière ne sont pas remplacés.

## 4. Maison : non intégrée
La planche C montre la bonne orientation (façade presque de face, **pignon gauche** visible — c'est aussi le cas du
gabarit ; nos documents disaient par erreur « côté droit », corrigé). Mais l'architecture diffère du gabarit
(`docs/media/essai_v1/maison_gabarit_contre_concept.jpg`) :
- porte **au centre** (gabarit : à gauche du centre, devant le garde) ; pas de fenêtre d'étage (gabarit : une) ;
  lanterne murale au-dessus de la porte ; cheminée décalée ;
- caisses, barriques et sacs **peints contre la maison**, alors qu'ils sont des objets séparés dans le jeu ;
- proportions de la façade et du toit différentes de l'emprise (collision).
L'intégrer changerait l'architecture : il faut une **repeinture sur `maison_gabarit.png`** avec la planche C comme
référence de matières (ardoise moussue, colombages, soubassement, lanterne), sans accessoires.

## 5. Vérifications (essai activé)
| Contrôle | Résultat |
|---|---|
| Tests automatiques | 66 / 66 |
| Parcours clavier (locomotion, collisions) | RÉUSSI |
| Approches du garde (11 cas) | 11 / 11 |
| Retour de combat (victoire, défaite) | RÉUSSI |
| Démo complète : derrière la maison, **derrière le nouvel arbre**, dialogue, combat, retour | réussie |
| Performances exploration (rendu logiciel) | 60,4 images/s contre 64,7 ; +3,8 Mo de textures ; chargement +43 ms |
| Combat (arène illustrée) | inchangé (29,7 contre 28,8 images/s) |

## 6. Ce qu'il faut fournir pour une version définitive
1. **Sol** : l'esquisse repeinte sur `docs/media/gabarits_exploration/terrain/chemin_trace_exact.png`, en PNG
   1408 × 800 (ou 2816 × 1600), sans flaques de lumière hors des 3 lanternes, avec un bord bas qui remplace le muret
   (ou un nouveau `muret.png` séparé).
2. **Arbre** : tronc **complet** (y compris les branches cachées par le feuillage) et feuillage en deux PNG
   superposables, fond transparent, sans halo ; idéalement l'ombre au sol en troisième calque.
3. **Maison** : repeinte sur le gabarit (porte, 3 fenêtres et toit aux emplacements du gabarit), sans caisses ni
   barriques, PNG transparent ; `maison_fenetres.png` pour la lumière.
4. Planches sans texte incrusté, fond transparent réel (les planches B et D ont un fond gris opaque).
