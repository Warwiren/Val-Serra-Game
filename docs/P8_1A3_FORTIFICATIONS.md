# P8.1-A3 — Escamotages locaux, bannières et fortifications sud

Branche **`p8-1a3-fortifications`**, depuis `p8-1a2-coherence`. Godot 4.7.2. **EN ATTENTE de revue sur GPU.**

## Cadre conservé

* Caméra de ville à 11° et plongée civique à 6,5°.
* Lumière B (second dosage).
* Forge D et boutique P7.11.
* Architecture du Colisée.
* Trois niveaux urbains et tracé des rues.
* Collisions : 151 formes, identiques.
* Interactions E sans saut de caméra.
* Portails.
* Escamotage existant, gardé comme base technique : aucune transparence, aucun fondu, aucune trame.

Il n'y a aucun PNJ, aucune modification de gameplay et aucun achat.

## Options de comparaison

| Option | État rétabli |
|---|---|
| `--escamotage_a3=0` | Escamotage de P8.1-A2 (une seule coupe, sommets estimés) |
| `--annexes_a2=1` | Appentis de P8.1-A2 sur le parvis |
| `--fortifs=0` | Muret de 1,2 m de P8.1-A2 |
| `--escamotage_delai_niveau=<s>` | Délai avant de rendre un étage (2 s par défaut) |

## 1. Escamotages locaux (commit A)

### Diagnostic

Outil : `tools/p8/escamotage_p81a3.gd`, sur le nouveau parcours `p81a3_aller_retour`. Ce parcours relie la place, la forge, l'allée, la porte du Colisée, le parvis et la rue du Colisée, à l'aller et au retour, en marchant puis en courant, avec arrêts et demi-tours. Il a été complété par la visite complète et la montée de la place.

L'outil relève, pour chaque volume, les bascules, leur cause, les disparitions entières, l'intervalle minimal entre deux bascules et la part de hauteur retirée.

| Volume | Situation | Cause | Avant (P8.1-A2) |
|---|---|---|---|
| `bat_guilde` | Au sud de la grande place ; la caméra passe au-dessus quand Aren longe la place | Caméra dans l'emprise | Tout ce qui dépassait 3,1 m disparaissait |
| `paysage_9` | Toits de premier plan au sud du parvis du Colisée | Caméra dans l'emprise | Tout au-dessus de 6,5 m |
| `paysage_3` | Fond sud-ouest, ouest de la Guilde | Caméra dans l'emprise | Tout au-dessus de 3,5 m |
| `paysage_4` | Fond bas près de l'allée | Ligne de vue | Sommet estimé à 8,5 m, réel 2,5 m : masquage injustifié |
| `bat_b_parvis_o2` | Annexes du parvis (passage des faubourgs) | — | Faux « Aren masqué » (119 images) : sommet estimé trop haut |

Les sommets des volumes étaient estimés jusqu'à 6 m au-dessus des murs. Cela déclenchait des escamotages pour des toits imaginaires.

### Corrections

Code : `ville_v07b.coupes_camera`, `_decouper_niveaux`, `_sommet_mesure`.

* **Sommet réel** de chaque volume, mesuré sur sa géométrie.
* **Coupes par niveaux d'étage.**
  * Au-dessus de la coupe d'étage de P7.12.1, une coupe tous les 3 m jusqu'à l'égout, puis une coupe à l'égout (toit seul).
  * Chaque coupe est finie par son chapeau (plancher bordé d'une arase).
  * On retire seulement ce qui dépasse la ligne de vue vers Aren ; si la caméra est dans l'emprise, la coupe passe aussi sous elle.
  * La Guilde perd désormais en général ce qui dépasse 6,1 m (au lieu de 3,1 m), et `paysage_9` ce qui dépasse 7,0 ou 8,5 m.
* **Stabilité.**
  * Rendre un étage alors que le volume reste masqué attend 2 s.
  * Aucun rétablissement n'a lieu moins d'1 s après une bascule.
  * À l'entrée en masquage, la coupe est choisie avec 0,6 m d'avance, sauf pour la coupe la plus basse. Il y a ainsi une seule bascule au lieu de deux rapprochées.
* **Premiers plans du secteur du Colisée** (corrections architecturales) :
  * **Grand volume clair arrondi = bâche de la caravane** (cylindre de 3,8 m de diamètre, toile presque blanche). Elle devient un chariot bâché à l'échelle : caisse de 2,2 m, bâche en demi-cylindre de 1,05 m sur cinq arceaux, toile écrue patinée, chargement posé à côté. La collision est inchangée.
  * **Toitures de premier plan = appentis presque plats de P8.1-A2** (`bat_b_parvis_s`, `_o2`), lus d'en haut comme des plateformes rouges. Ils deviennent des **jardins en terrasse** : potagers surélevés, parapet de pierre, planches bordées de pierre de taille, plantations basses seulement (aucun arbuste). La collision est inchangée.

### Mesures

| Parcours | Part de hauteur retirée (A2 → A3) | Bascules (A2 → A3) | Aren masqué | Clignotements (< 1 s) |
|---|---|---|---|---|
| Forge-Colisée (aller-retour) | 0,73 → **0,47** | 33 → **30** | 0 → 0 | 0 → 0 |
| Visite complète | 0,79 → **0,60** | 37 → 41 (*) | 119 → **0** | 0 → 0 |
| Montée de la place (aller-retour) | 0,81 → **0,66** | 11 → 21 (*) | 0 → 0 | 0 → 0 |

(*) Les bascules en plus viennent des **nouvelles fortifications** (§ 3). Jusqu'en A2, les tours et courtines étaient coupées en permanence à 1,2 m et n'étaient jamais escamotées.

Sur le parcours forge-Colisée, aucun volume ne disparaît entièrement. Les bascules qui restent sont des changements d'étage de `paysage_9` et de la Guilde, espacés d'au moins 4,6 s.

## 2. Bannières (commit B)

Outil : `tools/p8/bannieres_p81a3.gd`. Il confronte chaque bannière notée par la ville aux baies du registre des façades (baie, volets et encadrement compris) : Colisée, entrées à enseigne « bannière », corps de garde, château.

| Bannière | Avant | Après |
|---|---|---|
| Guilde, gauche (bleue) | Devant la fenêtre de x 48,8 : la capture signalée | Une seule bannière, dans l'axe, au-dessus de la porte |
| Guilde, droite | Libre | Retirée (doublon) |
| Hôtel de ville, droite (rouge) | Devant la fenêtre cintrée de x 85,8 | Déplacée sur le trumeau voisin (x 87,1) |
| Hôtel de ville, gauche ; Colisée (8) ; corps de garde (2) ; château (2) | Libres | Inchangées |

**Total : 2 bannières devant une baie → 0. Aucun chevauchement.**

Les corrections sont faites dans les générateurs partagés :
* **Enseigne « bannière » des entrées** (`_entree_fonctionnelle`). La bannière va sur un trumeau libre et dégagé, décalée vers l'extérieur jusqu'à 3 m si nécessaire.
  * « Dégagé » : la bannière ne doit pas se retrouver derrière un volume accolé. C'est le cas de la Guilde côté ouest, cachée par l'immeuble de la placette.
  * Si un côté n'a pas de place, une seule bannière est posée dans l'axe, au-dessus de la porte.
  * À défaut, des étendards sur hampe de biais (règle de secours, non utilisée aujourd'hui).
* **`archi_p77`** : aucune baie d'étage dans l'encadrement d'une entrée des données. La fenêtre cintrée de la Guilde, posée sur la corniche de la porte, est omise. Le trumeau dégagé reçoit la bannière.
  * Cette règle dépend de `--f_coherence`, pas de `--escamotage_a3`.

Les couleurs héraldiques sont inchangées : Guilde bleue à carré d'or, hôtel de ville rouge.

Vérification visuelle (rendu, non livré) des façades hors registre : corps de garde (bannières sur les trumeaux de l'étage noble) et vestibule du Colisée (bannières sur les piles de l'arche). Aucune ne recouvre une baie.

## 3. Fortifications sud (commit C)

Code : `scenes/p8/fortifications_p81a3.gd`. Il s'agit de la proposition de P8.1-A2 (§ 6), dont le principe a été validé et qui est mise en œuvre ici.

### Description

* **Courtines-terrasses** (x −12 → 53 et 67 → 138 ; les données vont de 10 à 120, le reste est en affichage seul) :
  * côté ville, un mur de 1,2 m porte le **chemin de ronde** dallé ;
  * **parapet** de 0,6 m d'épaisseur jusqu'à 2,2 m, avec tablette de pierre de taille ;
  * **créneaux rectangulaires** : merlons de 1,0 m, créneaux de 0,6 m, sommet à 3,0 m ;
  * côté extérieur, **escarpe** maçonnée de 5 m à double talus et cordon-larmier. La façade extérieure mesure environ 8 m.
* **Fossé sec** (y 155 → 164, fond à −5 m) : fond herbeux, contrescarpe maçonnée avec tablette, murs d'extrémité. Le sol de décor est découpé autour du fossé, en affichage seul ; sa collision est inchangée.
* **Deux tours carrées de flanquement** sur les emprises des données (4 × 7 m), saillantes de 2 m sur le fossé :
  * talus dans le fossé, cordons à 1,2 et 6,2 m ;
  * archères sur la face sud et les flancs extérieurs ;
  * plate-forme dallée à 6,2 m, parapet et merlons (sommet à 7,8 m, soit environ 12,8 m au-dessus du fond du fossé) ;
  * porte de tour vers la placette (décor, sans interaction) ;
  * glissière de herse côté passage ;
  * pas d'échauguette.
* **Porte voûtée** entre les tours :
  * plein cintre de 6 m, clé à 5,15 m, claveaux ;
  * herse relevée visible sous la clé ;
  * vantaux de bois ferré de 4,2 m ouverts contre le passage ;
  * chemin de ronde crénelé à 5,4 m reliant les tours.
* **Pont dormant** dans l'axe x 60 : arche en plein cintre, culées, tablier dallé jusqu'à la contrescarpe, parapets bas.
  * La route praticable des données (y 156 → 162), sa barrière et l'examen « Porte sud » sont **inchangés** : l'accès extérieur et les transitions futures sont préservés.
* **Raccords** :
  * **lices** : la bande de 2 m entre les maisons et la courtine est fermée côté placette par un muret de 0,55 m (plus de bande apparemment praticable menant à un mur invisible) ;
  * **escaliers** d'accès au chemin de ronde contre la courtine, de part et d'autre de la porte ;
  * courtines prolongées jusqu'aux fonds et arrêtées sur le fossé, sans cul-de-sac ;
  * les maisons de la rue du chantier restent **adossées** au rempart.
* **Matières** : maçonnerie de soutènement de la ville (contrefort sali) et pierre de taille des couronnements, comme les murs de la place. Les ombres sont portées en lumière B, sans réglage particulier.

### Visibilité depuis l'intérieur (caméra 11°)

La caméra est environ 21 m derrière Aren et 6,4 m au-dessus de lui. Un élément situé d entre Aren et la caméra ne masque pas ses pieds s'il reste sous environ 0,3 × d.

La composition s'appuie sur cette règle : la hauteur défensive est donnée par le **fossé**. Côté ville, l'enceinte ne s'élève qu'à 1,2 m au chemin de ronde et à 3,0 m aux merlons.

Le reste passe par un **masquage local** :
* le **pied** de l'enceinte est permanent : escarpe, mur et chemin de ronde à 1,2 m, souche des tours à 0,9 m ;
* sont escamotables, avec des niveaux explicites et des coupes finies :
  * **merlons et parapets**, par 8 segments (étroits près de la porte, larges au loin) ;
  * **tours**, coupées à 3,4 m (au-dessus des archères basses), à 5,4 m (sous la plate-forme), ou entières au-dessus de la souche ;
  * **porte**, coupée à 3,65 m (mi-arc, sur une limite de gradin), à 5,46 m (chemin de ronde), ou entière.

**Il n'y a plus de coupe permanente à 1,2 m.**

| Parcours | Aren masqué | Clignotements | Bascules | Disparitions entières |
|---|---|---|---|---|
| Trajets de la ville (départ porte sud) | 0 | 0 | 24 | 4 (tours et porte au ras d'Aren) |
| Visite complète | 0 | 0 | 41 | 7 |
| Montée de la place (aller-retour) | 0 | 0 | 21 | 1 |
| Cadrage (6 parcours) | 0 % | 0 | — | — |

## 4. Cohérence et level design

* **Porte sud reconnaissable** : au départ et sur le pont, la caméra voit de face les deux tours, la porte voûtée, la herse, le crénelage et le pont. Depuis la placette, les tours encadrent le passage.
* **Pas de cul-de-sac** : les lices sont fermées par un muret, les courtines vont jusqu'aux fonds et s'arrêtent sur le fossé.
* **Bâtiments adossés** : les fonds de la rue du chantier sont accolés au rempart ; l'immeuble de la placette et la Guilde sont séparés de la courtine par les lices.
* **Sorties futures** : la route sud et son pont sont inchangés ; aucune nouvelle porte jouable.
* **Parcours** : rien de l'enceinte ne masque Aren durablement (mesures ci-dessus) ; collisions inchangées.

## 5. Contrôles (commit D)

`bash tools/p8/non_regression_p80c.sh` : les 24 contrôles plus 4 contrôles P8.1-A3.

| Contrôle | Résultat |
|---|---|
| 24 contrôles techniques (F5, tests unitaires, tutoriel, Colisée, ville A et B, portails, examens E à 0 px, lumière, escamotage, cadrage, tests « smoke ») | **24 / 24 OK** |
| Continuité forge-Colisée : Aren jamais masqué, aucun clignotement, aucune disparition entière, au plus 36 bascules, part retirée ≤ 0,55 | **OK** : 30 bascules, 0 disparition entière, part retirée 0,47, Aren masqué 0 |
| Continuité porte sud (trajets) : Aren jamais masqué, aucun clignotement | **OK** : 24 bascules, 4 disparitions entières, Aren masqué 0, aucun clignotement |
| Bannières : aucune devant une baie | **OK** : 0 sur 15 |
| Cohérence des façades : 0 superposition, 0 porte hors sol, 0 soubassement traversant, 0 obstacle | **OK** : 0 / 0 / 0 / 0 (19 portes, 94 faces) |
| Collisions (empreinte, lignes « C », comparées à P8.1-A) | **Identiques** : 151 formes |

### Coût d'affichage

Mesure en Forward+ avec Vulkan logiciel, 640 × 360, outil `tools/p7/profil_gpu_p77.gd`. Seuls les appels de dessin et les primitives sont significatifs.

| Profil | Appels A2 | Appels A3 | Primitives A2 | Primitives A3 |
|---|---|---|---|---|
| A | 1 664 | 1 892 | 531 917 | 542 101 |
| B | 2 531 | 2 885 | 883 230 | 902 481 |

**Coût en hausse : +14 % d'appels de dessin en A comme en B (+228 et +354), primitives +2 %.**

* L'essentiel vient du **découpage par niveaux**. Chaque coupe sépare les maillages d'un volume en un morceau par niveau, et ces morceaux restent des nœuds distincts même quand rien n'est escamoté.
* L'enceinte elle-même ajoute environ 30 appels : segments, tours, porte, fossé, pont.

Une optimisation est possible : ne découper que les volumes effectivement escamotés sur les parcours, ou refusionner les niveaux tant qu'un volume reste entier. Elle n'est pas faite ici. Le jugement des performances est à faire sur votre GPU, et `--escamotage_a3=0` donne le coût de A2 pour comparer.

## 6. Compromis visuels à juger sur GPU

* **Tours au premier plan.** Quand Aren longe la placette près d'une tour, sans être derrière elle, la tour entière reste visible et occupe un bord de l'écran. Quand Aren passe derrière, elle est coupée par niveaux, au plus bas jusqu'à sa souche de 0,9 m.
* **Porte voûtée vue de la placette.** Dans l'axe et à moins d'environ 18 m de la porte, la voûte est presque toujours escamotée, à mi-arc ou entière. On la voit entière depuis le haut de la placette et de la volée A, et de face au départ.
* **Caméra à hauteur de la voûte.** Au centre de la placette, la caméra est à la hauteur de la clé : l'arc se lit comme un bandeau mince au-dessus du passage.
* **Fossé peu visible.** À 11°, la caméra voit l'escarpe et la tablette de la contrescarpe, mais presque pas le fond du fossé.
* **Disparitions entières** des tours et de la porte quand Aren passe au ras de l'enceinte (4 à 7 par parcours). La souche des tours et le pied de la courtine restent en place.
* **Jardins du parvis** : potagers surélevés au premier plan, avec des plantations basses du module végétal.
* **Guilde** : une seule bannière dans l'axe, et la fenêtre de l'étage au-dessus de la porte est supprimée.

## 7. Fichiers

| Fichier | Rôle |
|---|---|
| `scenes/p8/fortifications_p81a3.gd` | Enceinte sud (nouveau) |
| `scenes/p7/ville_v07b.gd` | Escamotage par niveaux et niveaux explicites (spec), sommets mesurés, stabilité ; caravane ; bannières des entrées ; branchement de l'enceinte |
| `scenes/p7/ville_v07a.gd` | Registre des bannières ; vantaux A2 retirés quand l'enceinte est active |
| `scenes/p7/archi_p77.gd` | Aucune baie dans l'encadrement d'une entrée |
| `scenes/p7/civique_p712.gd` | Bannières notées (contrôle) |
| `scenes/p8/finition_p81.gd` | Jardins en terrasse ; sol de décor découpé autour du fossé |
| `scenes/p8/vegetation_p81.gd` | Plantations basses (`garnir(..., bas)`) |
| `src/explore25/routes25.gd` | Parcours `p81a3_aller_retour` |
| `tools/p8/escamotage_p81a3.gd` | Diagnostic et continuité de l'escamotage (nouveau) |
| `tools/p8/bannieres_p81a3.gd` | Contrôle des bannières (nouveau) |
| `tools/p7/escamotage_p7122.gd`, `tools/p8/cadrage_p80a.gd` | Adaptés aux coupes à plusieurs niveaux |
| `tools/p8/non_regression_p80c.sh` | 4 contrôles P8.1-A3 ajoutés |
