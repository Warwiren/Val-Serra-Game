# P7.12.1 — Consolidation du quartier civique et corrections de caméra

Branche **`p7-12-1-civique-consolidation`**, depuis `p7-12-quartier-civique`. Trois commits séparés : caméra, occultation,
art. EN ATTENTE de votre examen ; rien n'est annoncé validé.

## 1. Caméra : saut pendant les interactions (P0)

* **Cause mesurée.** À l'ouverture d'un examen ou d'un dialogue, `cam.ui_lock` ramenait le décentrage vertical de la
  caméra (`aim_frac` = 0,1) à 0 en 0,33 s, puis le rétablissait à la fermeture. Il s'agit du centrage « dialogue » de P3.
  Résultat : un recentrage de **72 px (1,2 m)** vers le bas à chaque interaction, puis le retour.
* **Correction.**
  * `Cam25.visee_fixe` conserve la visée pendant les interactions.
  * Elle est activée **seulement** pour la caméra de la ville et la caméra « V » du Colisée. Les autres caméras et le
    combat sont inchangés.
  * `--visee_dialogue=1` : comportement P3.
* **Mesure.** `tools/p7/stabilite_interactions_p7121.gd`, avec le parcours `p7_7121_interactions` : 7 examens
  (Guilde, auberge, forge, boutique, fontaine, garde du château, hôtel de ville) sur les **trois niveaux** urbains.
  Écart maximal du centre de caméra : **71,95 px → 0 px**, avec les caméras A et B.

## 2. Occultation trop brusque (P0)

* **Constat.** Après la première montée (volées A et B), la caméra, 22 m derrière Aren, passe au-dessus de la Guilde et
  de l'auberge : ces bâtiments disparaissaient en entier.
  * Hors de la marge de 2,6 m, la Guilde masquait toute la vue depuis le bord sud de la place. Seul le cercle
    d'occlusion montrait Aren, ce que l'outil de P7.6 signalait déjà sur 360 points.
* **Correction : escamotage des parties hautes** (option 2 de votre ordre de priorité ; aucune transparence, aucune trame).
  * Au chargement, chaque volume de plus de 5 m est coupé à h0 + 3,5 m : les boîtes sont coupées en deux, les maillages
    fusionnés répartis par triangle, et les toits suivent leur partie.
  * Si la ligne de vue caméra → pieds d'Aren passe au-dessus de la coupe au droit du volume, **seuls les étages et le
    toit** sont escamotés. Le rez-de-chaussée reste, coupé net. Sinon, le volume entier est escamoté, comme avant.
  * Un volume qui **coupe la ligne de vue** vers Aren est aussi escamoté : Aren et ses chemins restent visibles.
  * Hystérésis conservée. Mode net. Le fondu reste expérimental (`--escamotage=fondu`, Forward+ seulement).
  * `--escamotage_partiel=0` : comportement P7.6.
* **Trajets automatiques.** Guilde, auberge, remparts et tours du sud ne perdent plus que leur partie haute, sauf une
  tour au passage de la porte sud, qui est escamotée entière.

## 3. Perspective du château (P1)

Trois plans distincts :

1. terrasse civique et avenue ;
2. **porte fortifiée** : herse relevée dans la voûte, passage ouvert, la grille basse des données, les gardes et les
   guérites ferment toujours l'accès ;
3. par l'arc, une **rampe montante** (8 → 12 m, environ 145 m, décor seul) bordée de maisons basses mène au **château**.
   * Le château est indépendant et non jouable, à environ 150 m derrière la porte.
   * Rocher, enceinte crénelée, porte à blason entre deux tours rondes coiffées d'ardoise, tours d'angle, logis, donjon.

L'ardoise est désormais **réservée au château**. Les tours de la porte et les tours carrées perdent leurs toits coniques,
les guérites reçoivent un chapeau de pierre. Le château ne se confond plus avec l'entrée.

* **Cadrage.**
  * La caméra de la ville ne montre qu'environ 4° au-dessus de l'horizon : le château ne peut entrer dans le cadre qu'à
    travers l'arc.
  * L'arc est relevé (clef à 16 m) et le château dimensionné pour cette fenêtre. Depuis la place, sa porte et ses tours
    s'aperçoivent dans l'arc.
  * **Adaptation locale de la caméra**, nécessaire et limitée : sur la terrasse et l'avenue (niveau haut, y < 71), la
    plongée passe progressivement de 11° à 6,5°. Même lissage critique et même recalage que dans le Colisée : aucun zoom,
    aucune rupture de suivi.
  * Depuis la terrasse et l'avenue, le château se lit en entier.
  * `--plongee_civique=0` désactive cette adaptation.

## 4. Corps de garde ouest (P1)

Même emplacement, même collision. Calcaire **plus clair et plus chaud**, façades **maçonnées en épaisseur** (baies en
retrait de 0,45 m).

* **Entrée principale** : arc appareillé, blason sous fronton, lanternes, balconnet de l'étage noble.
* **Ouvertures variées** : croisées de pierre, baies cintrées, fenêtres d'attique, archères sur l'avenue ; deux fenêtres
  éclairées.
* **Identité** : bannières de la ville, échauguette à l'angle sud-est, couronnement de corbeaux et de créneaux clairs.
* Les barreaux du rez-de-chaussée sont supprimés.

## 5. Raccords

* **Hôtel de ville** (non habillé) : un **pavillon de calcaire** symétrique du corps de garde occupe la partie ouest du
  bloc (x 74 → 79,5) et forme le flanc est de la porte. Le reste du bloc garde le blockout, retinté en pierre : il n'y a
  plus de volume bleu-vert. Collision et entrée fonctionnelle inchangées.
* **Profondeur des fenêtres** : les façades de l'administration sont reconstruites **en épaisseur**, comme le corps de
  garde et le pavillon.
  * Croisées de pierre, appuis, claveaux ou plates-bandes à clef.
  * Sa porte sud des données devient une vraie baie.
* Le sol du quartier haut derrière la porte est assombri : le dessus clair du massif brillait à travers l'arc.

## Fichiers

* `src/explore25/cam25.gd` (`visee_fixe`) ; `scenes/p6/colisee.gd` (activation, `_profil_ville`).
* `scenes/p7/ville_v07b.gd` : découpe bas / haut, ligne de vue, escamotage partiel.
* `scenes/p7/civique_p712.gd` : châtelet, château, rampe, corps de garde, pavillon, façades civiques.
* `tools/p7/stabilite_interactions_p7121.gd` (nouveau).
* `src/explore25/routes25.gd` : parcours `p7_7121_interactions` et `p7_7121_escamotage`.

## Appels de dessin

Zone du fond nord, de la porte et de la ville haute (x 26 → 118, y 8 → 89) : **638** surfaces avec le quartier civique,
contre **584** sans (`--civique=0`), soit +54 (P7.12 : +34). Les découpes bas / haut ajoutent quelques maillages, sans
nouvelle matière.

## Tests

Série complète après chaque commit (caméra, occultation, art), mêmes résultats :

| Test | Résultat |
|---|---|
| Tests unitaires | 76 sur 76 |
| Tutoriel : ouverture (`--tuto-rapide`) et saut | réussis |
| `p6_sondes` (chargement du Colisée, collisions) | 10 sur 10 |
| F5 (forêt), V11 | sans erreur, 0 échec |
| Sondes de collision de la ville, caméras A et B | 40 sur 40 |
| Trajets sur les trois niveaux, A et B | 29 points sur 29 |
| Transitions ville ↔ Colisée, A et B | 4 passages, 12 points sur 12 |
| Chargement de toutes les scènes F6 de `scenes/p7` | sans erreur, aucune ressource manquante |
| Stabilité des examens (7 interactions, trois niveaux), A et B | 0 px |
| Recouvrements de volumes, axe du château | 0, dégagé |

## Problèmes restants

* Rendu vérifié en mode Compatibilité seulement. Sur votre GPU, à juger :
  * la plongée adoucie de la terrasse, à éprouver en mouvement ;
  * la lisibilité du château à travers l'arc depuis la place, où il reste petit ;
  * les teintes du calcaire.
* Le rez-de-chaussée coupé des volumes escamotés montre un dessus plat : c'est le dessus du blockout, ou le plancher du
  premier étage pour les bâtiments habillés.
* L'hôtel de ville reste en blockout, retinté en pierre, au-delà du pavillon : il relève de son propre lot.
* `tools/p7/camera_volumes_p76.py` ne modélise ni l'escamotage partiel ni la plongée locale. Ses comptes « Aren masqué »
  surestiment désormais les cas réels.
