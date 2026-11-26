# P7.13 — Consolidation visuelle et bordures de la grande place

Branche **`p7-13-bordures-place`**, depuis `p7-12-2-coherence-terrasse`. Commits séparés : terrasse, château, bordures,
architecture, rendu (puis documentation). EN ATTENTE de votre examen en jeu ; rien n'est annoncé validé.

## 1. Belvédère

* **Fonction de la terrasse.** La façade ouest de la boutique n'est maçonnée que sur 1,25 m au-dessus de la terrasse
  (pan de bois dès 7,0 m) : une fenêtre de service n'y tient pas.
* J'ai donc ajouté une **buvette adossée** à ce mur, entre ses deux fenêtres d'étage (y 80,1 → 83,9). Elle comprend :
  * un comptoir de bois peint du vert de la boutique, à plateau de pierre, avec ses retours ;
  * une étagère avec pots et flacons, un tonnelet, une ardoise, une lanterne ;
  * un appentis de tuiles canal, même construction que l'appentis de la forge D.
* La buvette n'est jamais escamotée : elle est basse et adossée.
* **Tables.** Trois tables ; la table 3 est décalée vers l'ouest pour dégager l'accès au comptoir.
* **Emplacements de PNJ** (données seulement, aucun PNJ) : `cafe_assis_1`, `cafe_assis_2` et `cafe_serveur`, derrière le
  comptoir.
* **Examen.** Nouvel examen `ex_buvette`.
* **Collisions.** Bloc `decor_buvette` (x 74,8 → 76, y 82 → 83,8).
* **Contrôle** (parcours `p7_7122_terrasse`, caméras A et B) :
  * 11 points sur 11 ;
  * poussées contre le comptoir et les balustrades sud et ouest : arrêts corrects.
* Le garde-corps n'est pas modifié.

## 2. Cohérence architecturale

Vos captures annotées ne me sont pas parvenues. J'ai inspecté les abords des quatre volées et les portes civiques, et
corrigé les défauts constatés :

* **Ouverture injustifiée près de l'escalier.**
  * Le pignon est de la forge D longe la volée C et le palier 2.
  * Ses deux fenêtres plaquées (appui à 4,4 m) étaient enterrées par les marches (4,6 m) et le palier (5,75 m).
  * Elles sont retirées : le pignon devient aveugle, comme un mur d'échiffre.
* **Porte du bâtiment civique.**
  * Le soubassement de 0,55 m des façades civiques passait devant le pied des portes. La porte du corps de garde semblait
    donc surélevée et sans accès.
  * Le soubassement est désormais interrompu au droit des portes. Elles sont de plain-pied sur leur seuil : aucun
    emmarchement n'est nécessaire, le dallage est au niveau du seuil.
  * La correction vaut pour toutes les façades construites par `_batiment_civique`.
* **Éléments qui semblaient flotter.**
  * Les murs d'échiffre en gradins des volées A à D étaient dessinés contre la Guilde, l'auberge, la forge et le socle du
    palier.
  * Ils ne le sont plus de ces côtés (`CONTRE_MUR`). Les collisions sont inchangées des deux côtés.
* **Entrées.** Les entrées fonctionnelles sont inchangées.

## 3. Accès au château

* **Herse.** La herse du châtelet est **baissée** dans la feuillure de l'arc :
  * treillis de chêne ferré à mailles larges, environ 76 % de vide ;
  * pointes de fer au sol, coulisses de pierre.
* **Grille.** La grille métallique des données n'est plus dessinée. Sa collision et son texte « fermée » restent : c'est
  désormais la herse qui ferme. Gardes et guérites sont inchangés.
* **Perspective.**
  * La rampe montante et le château restent lisibles à travers les mailles. Depuis l'avenue, la trame se superpose au
    château, déjà petit en haut de l'arc.
  * La première version (68 % de vide) le brouillait trop ; j'ai donc élargi les mailles.
* **Comparaison.** `--herse=relevee` rétablit l'état P7.12.2 (herse relevée, grille).

## 4. Bordures de la grande place (`scenes/p7/bordures_p713.gd`, `--bordures=0` : blockout)

* **Draperie** (`bat_commerce_e2`, collision inchangée) :
  * rez-de-chaussée de pierre maçonné en épaisseur ;
  * porte cintrée sur l'entrée décorative des données ;
  * « ouvroirs » : baies de boutique à tablette prise dans l'épaisseur du mur (aucun relief traversable), volets relevés
    au-dessus de 2,3 m, étoffes ;
  * étage enduit rose sur cordon, croisées à volets bleu ardoise, corniche ;
  * toit de tuiles, pignon sur rue ;
  * enseigne aux ciseaux et au coupon, distincte du flacon de la boutique.
* **Visibilité de la boutique.** La draperie est **plus basse** que le blockout (faîtage à 12,1 m contre 12,9 m) et en
  retrait de l'encorbellement de la boutique : la boutique n'est pas davantage masquée.
* **Étals 0 à 3** (collisions des données) :
  * tréteaux, poteaux, toile à deux pans rayée de teintes sourdes ;
  * marchandises propres à chaque étal : épices, poteries, légumes, fleurs ;
  * caisse et tonneau (modèles déjà importés) ;
  * les quatre étals sont fusionnés ensemble.
  * L'étal 3 est raccourci à l'est (x 70 → 69,3) : le blason du soutènement et l'axe du château sont dégagés.
* **Halle sur quai** (`bat_echoppe_no_o`, quai de 0,45 m des données) :
  * parement et dallage ;
  * petite halle de charpente sur dés de pierre, toit de tuiles ;
  * sacs, caisses, tonneaux.
  * Son volume d'escamotage est relevé à la hauteur de la halle.
* **Circulations.** Circulations et axe du château préservés ; recouvrements de volumes : 0.

## 5. Défauts d'affichage

**Méthode** (`tools/p7/scintillement_p713.gd`, rendu Compatibilité) :

* Chaque vue de jeu est rendue avec un plan proche de 0,5 m, puis de 0,6 m, puis de nouveau 0,5 m.
* La projection ne change pas, seule la précision de profondeur varie. Les pixels qui basculent sont ceux qui scintillent
  quand la profondeur varie.
* Les animations (eau, fumée, personnage) sont écartées par la troisième image.

`tools/p7/coplanaires_p713.gd` + `.py` recherche en plus les faces coplanaires de même sens au niveau des triangles (les
maillages sont fusionnés). Beaucoup de ces paires sont enfouies dans d'autres volumes ; seules celles que le rendu
confirme ont été corrigées.

**Causes confirmées et corrigées** (décalages de quelques millimètres, invisibles) :

* **Dessus d'appui dans le plan du dessus du mur sous la baie.**
  * C'était la cause principale : une ligne scintillante à chaque appui vu d'en haut.
  * Les deux fonctions de mur percé (forge D, reprise par les façades civiques et la draperie ; boutique) arrêtent ce pan
    6 mm plus bas.
* **Pierres posées à fleur du parement.** Poteaux corniers du pan de bois sud, piédroits et linteau de la porte de la
  boutique, corniche de la devanture.
* **Bandes des toiles.** Étal de la boutique et étals de la place : leur recouvrement était dans un même plan ; les bandes
  sont désormais décalées.

**Résultat, sans ombres, sur 11 vues de jeu** (place, terrasses, avenue, volées A et B, ruelle) :

| Mesure | Avant | Après |
|---|---|---|
| Moyenne | 0,215 ‰ | **0,090 ‰** |
| Avenue | 182 px | 2 px |
| Terrasse civique | 315 px | 48 px |
| Terrasse du belvédère (façade ouest de la boutique) | 903 px | 473 px |

**Ombres et escaliers lointains (non confirmé ici) :**

* Le soleil de la ville utilise une ombre orthogonale unique, limitée à 120 m, qui s'efface progressivement à partir
  d'environ 96 m.
* Avec ombres, le détecteur trouve davantage de pixels qui basculent, en particulier des bords d'ombre sur les nez de
  marches de la volée C. Mais ce test change le plan proche, donc le cadrage de l'ombre : il exagère la part des ombres.
* En marche, plan proche et champ restent fixes et Godot cale l'ombre sur sa grille.
* Une comparaison directe depuis la porte sud (ombre à 120 m contre 4 tranches jusqu'à 220 m) ne montre qu'un écart
  minime.
* **Je n'ai donc rien changé par défaut.** `--ombres_ville=200` active l'essai en 4 tranches pour la ville : à juger en
  Forward+ sur votre GPU, avec le biais d'ombre si de l'acné apparaît sur les marches.
* Aucune modification globale de l'éclairage.

## 6. Occultations et caméra

* L'escamotage P7.12.2, avec son délai de réapparition, est conservé sans changement.
* **Mesure** (`tools/p7/escamotage_p7122.gd`, aller-retour en marchant et en courant) : 0 image où Aren est masqué, avec
  les caméras A et B.
* **Stabilité des examens** (7 interactions, trois niveaux) : **0 px** avec les caméras A et B.

## Fichiers

| Fichier | Contenu |
|---|---|
| `scenes/p7/bordures_p713.gd` (nouveau) | draperie, étals, halle |
| `scenes/p7/civique_p712.gd` | buvette, herse baissée, soubassement interrompu aux portes |
| `scenes/p7/ville_v07b.gd` | branchements, `grille_dessinee`, `CONTRE_MUR`, `--ombres_ville` |
| `scenes/p7/tranche_p76.gd` | échiffres, option `contre_mur` |
| `scenes/p7/forge_p7101.gd` | pignon est, `_mur_perce` |
| `scenes/p7/boutique_p711.gd` | `_mur_perce`, poteaux, porte, toile |
| `scenes/p6/colisee.gd` | une condition : grille non dessinée si la ville le demande ; le Colisée est inchangé |
| `tools/p7/build_ville_v07b.py`, `data/p7/ville_v07b.json` | buvette, table 3, emplacements de PNJ, étal 3 |
| `src/explore25/routes25.gd` | parcours de la terrasse |
| `tools/p7/scintillement_p713.gd`, `coplanaires_p713.gd` / `.py` (nouveaux) | outils de mesure du rendu |

## Appels de dessin

* **Zone de la place** (x 28 → 100, y 76 → 116) : 316 surfaces, contre 260 avec `--bordures=0` (+56). S'y ajoute le maillage
  commun des quatre étals, que le comptage écarte car il couvre 44 m.
* **Zone du fond nord** : 686 surfaces, comme en P7.12.2.

## Défauts restant à examiner

* Rendu vérifié en mode Compatibilité seulement. Sur votre GPU (Forward+), à juger :
  * le scintillement résiduel ;
  * les ombres des escaliers lointains (essai `--ombres_ville`) ;
  * les teintes de la draperie et des toiles.
* Il reste environ 470 pixels qui basculent sur la façade ouest de la boutique vue de la terrasse : traits épars au bord
  des volets et des fenêtres d'étage. Non résolus ici.
* Les points corrigés sans vos captures annotées (fenêtre, porte) sont à confirmer.
* Hors périmètre, toujours en blockout : l'hôtel de ville (au-delà du pavillon), les terrasses grises des volées A et B,
  la Guilde.
