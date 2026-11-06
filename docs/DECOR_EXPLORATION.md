# Décor définitif de la zone d'exploration HD-2D (branche `decor-final`)

**F5** affiche ce décor, sans réglage ni argument. Une seule version active : `art/explore_hd2d/illustre/`,
décrite par `illustre/decor.json` ; la géométrie de jeu (praticable, collisions, tri) reste `zone.json`.

## Contenu
| Élément | Fichier | Source et outil de régénération |
|---|---|---|
| Sol et chemin | `illustre/sol/sol.png` (1408×800, plaque + ombres des objets) | esquisse fournie recalée sur le tracé exact : `tools/explore/sol_recalage.py` puis `tools/explore/import_sol.py --sans-lumieres --exclure-ombres muret` |
| Maison | `illustre/maison.png` | référence officielle (`art/source/concepts_2026-11-07/`) sur la géométrie du gabarit : `tools/explore/maison_finale.py` |
| Grand arbre, arbre de droite | `arbre_tronc/feuillage`, `arbre_d_tronc/feuillage` | concept (planche C) : `tools/explore/concepts_vers_sprites.py` |
| 5 buissons | `buisson_0..4` | idem |
| Lanternes, banc, caisses, barriques, clôtures, cristaux | `lanterne`, `banc`, `caisses_pile`, `barriques_pile`, `cloture_d/g`, `cristal_*` | planches du 6 nov. : `extract_planche.py`, `compose_piles.py`, `compose_cloture.py` |
| Muret du premier plan | masqué (le sol peint son propre bord bas) | — |

## Toiture de la maison (correctif)
La version précédente reprojetait des **quadrilatères approximatifs** : la référence mappée sur la façade
contenait son propre avant-toit, d'où un second toit dessiné sur la façade, et le versant recouvrait le pignon droit.
Désormais chaque pixel prend sa matière dans la **carte des zones du gabarit** :
- **toit** : uniquement les pixels du versant du gabarit (ardoise, mousse, poutre faîtière), reprojetés depuis le
  versant de la référence ; la cheminée de la référence dans le bloc de la cheminée du gabarit ;
- **bande haute de façade et pignon droit** (sous le toit) : enduit de la référence, avec l'oculus au centre ;
- **avant-toit** : rive en bois sombre de 3 px et ombre portée douce sous l'égout (le toit n'est plus « posé ») ;
- façade, mur latéral, porte et 3 fenêtres : inchangés (rectangles exacts du gabarit) ; dimensions, emprise,
  collisions et ligne de tri inchangées.
Validation : `docs/media/decor_final/toiture_avant_apres_superposition.png` (gabarit, avant, après, et contours du
gabarit superposés), `toiture_avant_apres_en_jeu.jpg` (1280×720).

## Vérification visuelle finale (`docs/media/decor_final/zone_complete_F5_1280.png`, vidéo `demo_zone_definitive.mp4`)
- Arbres, buissons : pieds sur leur emprise ; on passe devant et derrière (feuillage transparent localement).
- Rochers et végétation : seulement ceux **peints dans le sol** (plus de doublons recollés) ; deux cristaux d'Aether
  indépendants, absents du sol peint.
- Ombres : celles du rendu de la scène (objets), lumière des lanternes peinte dans le sol.
- Chemin lissé sans couture ; bord bas raccordé ; muret masqué.

## Défauts encore présents
- Les **lanternes du bas et de droite** tombent sur le bord du chemin peint, plus large (≈ 3,6 m) que le tracé
  d'origine (2,6 m) ; leur position de jeu n'a pas été modifiée.
- **Ombres des arbres** : celles des anciens arbres (rondes), pas celles des nouveaux feuillages.
- Maison : texture d'enduit répétée dans la bande haute (motif de fissure visible) ; liseré sombre sur l'arête droite.
- Lueur chaude peinte sur le chemin à des endroits sans lanterne.
- Différence de finesse entre décor illustré et personnages en gros pixels (sprites à venir).
