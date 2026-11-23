# P6.4.1 — Second pilote artistique du Colisée

Branche **`p6-4-1-colisee-second-pilote`**, issue de `p6-4-colisee-direction-artistique`. Elle répond au retour
du créateur du 23/11/2026 sur le premier pilote :
* **galerie** : principe validé, toiture refusée ;
* **porte** : variante B refusée, A préférée provisoirement ;
* **matières** : calcaire ocre et gris chaud retenu, mur des vestiaires retenu comme base, dallage trop régulier.

C'est un **second pilote**, en attente de validation : rien n'est généralisé au Colisée.

Sont inchangés :
* la caméra, les déplacements, CombatCore, le tutoriel et la progression ;
* les ombres douces en qualité 4 et Godot 4.7.2 ;
* F5 (forêt). Le Colisée se lance en F6.

Rien n'a été fait sur la ville. Aucune nouvelle image, aucun nouveau modèle, aucun pack importé.

**Comparer en jeu** : la scène démarre sur le second pilote.
* **M** : P6.3.2 → premier pilote → second pilote (`-- --p64=0|1|2`) ;
* **K** : galerie A → B → premier pilote (`-- --galerie=A|B|p64`) ;
* **U** : porte C → A → B → P6.3.2 (`-- --porte_coupe=C|coupe|silhouette|p632`).

Les mesures sont faites en rendu logiciel (lavapipe), **pas sur GPU**.

## Livrables (mêmes cadrages que le premier pilote)

| | |
|---|---|
| Galerie actuelle / toiture A / structure mixte B (trois vues de l'arène et vue du dessus) | [`galerie_actuelle_A_B.jpg`](media/p6_4_1/galerie_actuelle_A_B.jpg), gros plans [`galerie_gros_plan.jpg`](media/p6_4_1/galerie_gros_plan.jpg) |
| Porte A / nouvelle variante C (infirmerie, coursive) | [`porte_A_C.jpg`](media/p6_4_1/porte_A_C.jpg), gros plan [`porte_A_C_gros_plan.jpg`](media/p6_4_1/porte_A_C_gros_plan.jpg) |
| Dallage actuel / dallage enrichi | [`dallage_actuel_enrichi.jpg`](media/p6_4_1/dallage_actuel_enrichi.jpg) |
| Mur actuel / mur avec détails picturaux discrets | [`mur_actuel_details.jpg`](media/p6_4_1/mur_actuel_details.jpg) |
| **Vidéo en mouvement**, vitesse réelle, 36 s : premier pilote / second pilote avec galerie A et porte C / second pilote avec galerie B | [`second_pilote_mouvement.mp4`](media/p6_4_1/second_pilote_mouvement.mp4) |

## 1. Galerie couverte

Les deux propositions (`habillage_p6._galerie_v2`) gardent l'emprise, les exclusions et la fermeture complète des
écoinçons : aucun sol n'est visible, aucune collision n'est créée, et rien ne dépasse le mur de fond des gradins.

**A — Toiture de petites tuiles.**
* **Tuiles canal** : 13 cm de large, en rangs de 20 cm (contre 20 et 32 cm au premier pilote).
* **Palette** : terre cuite sombre et rompue, deux familles de tuiles mêlées, au lieu des grandes surfaces rouge orangé.
* **Usure discrète** : recouvrements irréguliers, environ 4 % de tuiles plus neuves et autant de tuiles noircies,
  lichen par plaques qui rompt la teinte sans l'éclaircir, mousse peinte dans les creux.
* **Travées moins mécaniques** :
  * le pas des contreforts varie (15° ± 3,5°) ;
  * les contreforts sont **bas et sombres**, 16 cm au-dessus des tuiles, au lieu de chaperons clairs qui dessinaient un
    éventail ;
  * chaque travée a une légère flèche (6 cm).
* **Filtrage** : à distance, le bombé et l'ombre des recouvrements rejoignent leur valeur moyenne, sans quoi des bandes
  de moiré apparaissaient.

**B — Structure mixte.**
* **Bande couverte étroite** (2,2 m) le long des gradins. Elle s'ouvre vers l'extérieur par une **arcade** : une baie
  cintrée sombre par travée.
* **Au-delà**, une **terrasse maçonnée** dallée, 1,45 m plus bas, bordée d'un **parapet** (60 cm, chaperon).
* **Piles de maçonnerie massives** (60 cm) qui dépassent le parapet.
* La toiture n'est plus qu'un liseré, et la maçonnerie domine. La terrasse se lit comme une promenade haute, et non plus
  comme une plaque de remplissage.

**Indice de répétition** (écoinçon sud-ouest, même cadrage) :

| Premier pilote | A | B |
|---|---|---|
| 0,81 | 0,66 | 0,22 |

## 2. Porte de la réserve : variante C

La variante B est retirée du démarrage. Elle reste sur la touche U pour mémoire.

La **variante C** reprend la coupe de A, sans transparence et sans mini-porte. Tout est à taille réelle.
* **Jambages** : entiers jusqu'à la naissance de l'arc (1,85 m), tranchés au-dessus (tranche sombre des murs coupés).
* **Seuil** de pierre encastré, à fleur du sol.
* **Vantaux** tranchés au niveau du muret.
* **Ferrure de verrouillage** sur la tranche des vantaux, des deux côtés : barre de fer et moraillon au point de
  rencontre. On lit « fermée à clé » sans rien ajouter de flottant.
* **Indication d'interaction discrète** : un petit cadenas dessiné au pixel (24 × 24, généré par la scène, aucun
  fichier) apparaît à l'approche d'Aren (moins de 2,4 m), en fondu.
  * Il est placé **à côté de la porte, contre le jambage**, jamais sur l'axe du passage : il ne se superpose pas à
    Aren. Un premier essai centré sur la porte se superposait à lui et a été corrigé.
  * Il complète l'invite « E  Examiner » existante.

Ce traitement vaut pour toutes les portes fermées du Colisée.

**Depuis l'infirmerie**, A et C sont identiques : le mur est entier et la porte est complète. **Depuis la coursive**,
la porte reste à sa vraie largeur et la tranche se lit.

Les collisions et le verrou de la réserve ne changent pas : la sonde « réserve fermée » est réussie.

## 3. Matières : approche hybride

Le shader procédural garde le **calepinage** (en mètres) et la **stabilité du rendu** (joints et grain filtrés). Les
**nuances, l'usure et les salissures** sont **peintes** : elles viennent de textures peintes déjà présentes dans le
dépôt.
* `art/p4/mat/sol_terre.png` donne les salissures. Seules ses variations autour de sa moyenne sont utilisées, sur une
  teinte de crasse neutre ; elles sont placées par plaques, au pied des murs, dans les joints des sols et en coulures.
* `art/p4/mat/sol_herbe.png` donne la mousse, dans les joints et au pied des murs.

Aucune texture de remplacement n'a été inventée.

**Mur des vestiaires** (`mur2`, `mur_haut2`, `socle2`) : il garde le calepinage, la palette et les joints du premier
pilote, retenus. Les ajouts restent **discrets** :
* plaques de salissure peinte et coulures sur la hauteur visible (les casiers cachent le pied du mur) ;
* environ 5 % de pierres de réparation, d'une teinte et d'un grain différents ;
* quelques fissures fines filtrées ;
* joints très légèrement irréguliers.

L'indice de répétition est inchangé (0,10 → 0,10) : les détails n'introduisent aucun motif.

**Dallage de la coursive** (`dallage2`) :
* **dalles recoupées** : 60 % en longueur à une position aléatoire, 30 % en paires de demi-hauteur ; les tailles sont
  donc réellement inégales ;
* **joints taillés à la main**, au bord légèrement ondulé ;
* **dalles légèrement gauchies** : chacune accroche la lumière à sa façon ;
* environ 7 % de dalles fissurées et 5 % de pierres de réparation ;
* salissure et mousse peintes dans les joints et par plaques.

Le dallage reste en **assises**, comme un dallage romain par rangs. S'il paraît encore trop régulier, l'étape suivante
serait un vrai pavage irrégulier, que je peux proposer en troisième essai. L'indice de répétition passe de 0,23 à 0,22 :
la régularité qui reste est celle des rangs.

## 4. Lumière

Les essais locaux sont conservés et ne sont pas étendus au bâtiment. Dans la coursive, la lumière sert maintenant la
lecture :
* **accès mis en valeur** : porte de la loge, porte de la réserve, débouché du tunnel est (halos chauds courts) ;
* **allée centrale** éclairée, là où circulent les personnages ;
* **fond zénithal froid plus discret** : les murs restent un peu plus sombres que le sol, et les silhouettes s'en
  détachent.

Les sprites des personnages ne reçoivent pas la lumière (rendu Sprite3D d'origine, validé) : on les met en valeur par
le contraste du sol et du fond autour d'eux, pas par un éclairage direct. Je n'ai pas ajouté de lumière qui suive Aren.

Les vestiaires (passage éclairé depuis la salle) et les braseros des gradins sud-ouest sont inchangés.

## 5. Scintillement

Même parcours en mouvement (`p6_video_64`), pixels clignotants par image :

| Tronçon | Premier pilote | Second pilote, galerie A | Second pilote, galerie B |
|---|---|---|---|
| Moyenne du parcours | 458 | **333** | 334 |
| Abords des gradins et de la galerie (images 300–400) | 849 | 767 | 818 |
| Arène (400–500) | 1 460 | **792** | 798 |
| Coursive (500–800) | 379 / 413 / 507 | 392 / 422 / 478 | 392 / 420 / 480 |

Les petites tuiles ne scintillent pas, grâce au filtrage de leur relief. Le dallage enrichi reste au niveau du premier
pilote.

## 6. Tests et mesures de rendu

| Vérification | Résultat |
|---|---|
| `tests/run_tests.gd` | 85 / 85 |
| `e2e_p6_ouverture --tuto-rapide`, `e2e_p6_saut_tutoriel`, `e2e_p4_retour` | réussis |
| Parcours `p4` et `p4_sondes` (20 sondes) | réussis |
| Sondes de collision `p6_sondes` (dont « réserve fermée ») | 10 / 10 |
| Reliefs visibles traversables | aucun (seules les étiquettes de debug, comme avant) |
| Circulation à une touche, azimut 0° | 4 tronçons, 3/3, 0 % de contact mural |
| Caméra, `p6_video_631` | 0 bond |
| F5 | se charge sans erreur |

**Coût de rendu** (`perf_pieces_p6`, rendu logiciel, appels de dessin et primitives) :

| Position | Premier pilote | Second pilote, A | Second pilote, B |
|---|---|---|---|
| Vestiaires | 924 / 86 k | 923 / 86 k | 923 / 86 k |
| Tunnel sud | 421 / 79 k | 434 / 70 k | 438 / 70 k |
| Arène (entrée) | 431 / 50 k | 431 / 47 k | 434 / 48 k |
| Arène (centre) | 351 / 48 k | 351 / 46 k | 354 / 46 k |
| Coursive | 291 / 35 k | 284 / 31 k | 287 / 31 k |
| Infirmerie | 404 / 36 k | 407 / 36 k | 402 / 36 k |

* Les appels de dessin sont stables. Les primitives baissent un peu, car la galerie est moins découpée.
* La mémoire vidéo passe de 295 à 304 Mo : les deux textures peintes sont maintenant chargées par les matières pilotes.
* Les deux échantillonnages supplémentaires par pixel (détails peints) et le coût des fragments **restent à vérifier
  sur GPU**. Les endroits à regarder : la coursive, et l'arène face à la galerie.

## 7. Ressources

| Ressource | Statut | Usage |
|---|---|---|
| `src/p6/maconnerie_p64.gdshader` | modifié | Calepinage irrégulier, fissures, pierres de réparation, désordre des tuiles, calques de détails peints |
| `art/p4/mat/sol_terre.png`, `art/p4/mat/sol_herbe.png` (Drive SOL-02 / SOL-01 v03, « à tester ») | existants, non modifiés | Détails peints (salissures, mousse) des matières P6.4.1 |
| `art/p4/mat/roche.png` | existant | Grain de luminance (inchangé) |
| Cadenas d'indication | généré par la scène (24 × 24) | Porte C |
| Modèles Quaternius des portes | existants | Coupe (inchangée) |

## Décision attendue

1. **Galerie** : A, B, ou une combinaison ? Par exemple B au sud, où la galerie est au premier plan, et A ailleurs.
2. **Porte** : la variante C convient-elle, ferrure et cadenas d'approche compris ?
3. **Matières** : le mur avec détails peints est-il au bon niveau de discrétion ? Le dallage enrichi suffit-il, ou
   faut-il essayer un pavage irrégulier ?
4. **Lumière** : garder la logique « accès et allée de circulation » pour la suite ?
