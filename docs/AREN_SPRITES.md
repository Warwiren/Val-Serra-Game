# Aren — production des sprites HD-2D (pixel art)

## 1. Analyse des références (Drive : 3 planches)

| Planche | Usage |
|---|---|
| Portrait illustré « Aren – Chasseur » | Référence du visage et des matériaux (portrait de dialogue, plus fin que le sprite) |
| Fiche de personnage (vue de face, pose 3/4, palette, sabre) | Proportions, palette, forme du long sabre |
| Référence de sprites (6 directions + 5 poses de combat) | **Source des sprites** : Repos, Avance, Attaque, Garde, Touché |

Constats :
- **Pas de vraie grille de pixels** : les poses sont un « pseudo pixel art » généré par IA (pixels de 3 à 5 px,
  irréguliers, flou de compression). Mesure par autocorrélation des contours : aucune période stable.
  -> Il faut **rééchantillonner** en vrai pixel art, pas « extraire » des pixels.
- Portrait et sprites diffèrent en finesse (normal) ; couleurs cohérentes : écharpe bleue, cheveux châtains,
  bleu nuit, cuir brun, acier, fiole cyan.
- **Direction en combat** : vers la **droite** (les Chasseurs sont à gauche de l'écran) — c'est déjà
  l'orientation des 5 poses de combat de la planche.
- **Incohérence réelle relevée : la longueur du sabre** varie d'une pose à l'autre (≈ 24 px au repos, 17 px
  visibles en garde, 23 px en « touché », 33,5 px en attaque, en pixels natifs). Corrigée (voir §2).
- Effets lumineux peints dans les poses (arc de taille, glyphe de garde, étincelles, poussière) : retirés du
  sprite et refaits en calques séparés.

## 2. Pipeline réalisé (`tools/art/aren_sprites.py`, `tools/art/aren_anims.py`)

1. Découpe des 5 poses dans la planche.
2. Détourage : fond, ombre portée (uniquement dans la bande du sol, le pantalon bleu nuit étant aussi sombre).
3. Retrait des effets : couleur cyan + **masques manuels par pose** (arc de l'attaque, glyphe de la garde,
   poussière du « touché »), en protégeant la lame.
4. **Échelle unique** pour toutes les poses (déduite de la pose debout : 208 px source -> **64 px natifs**,
   facteur 3,25) : les proportions restent identiques d'une pose à l'autre.
5. Réduction par cellule (couleur médiane, aucun flou) puis **palette commune de 30 couleurs** pour les 5 poses.
6. Nettoyage (pixels isolés), contour sombre continu.
7. **Cadre commun 140 × 84 px**, **ancrage stable** au talon du pied arrière (44, 80).
8. **Correction du sabre** : lame prolongée jusqu'à la longueur du long sabre (32–33 px) avec la coupe
   transversale de référence relevée sur la pose d'attaque.

## 3. Animations

| Animation | Images | Cadence | Construction |
|---|---|---|---|
| Repos | 4 | 4 img/s, boucle | Pose repos + respiration (haut du corps −1 px, appuis fixes) |
| Garde | 4 | 4 img/s, boucle | Pose garde + respiration ; glyphe d'Aether séparé |
| Attaque | armé → élan → frappe → maintien → retour | ≈ 0,8 s | Poses garde, avance, attaque ; déplacement vers la cible par le moteur ; arc de taille séparé (4 images) |
| Dégâts | 1 + flash + recul | 0,35 s | Pose touché |
| Effets | arc 4 images, glyphe 3 images | 16 et 10 img/s | Dessinés au pixel près, palette Aether, mode additif |

Affichage : **×3, filtrage « plus proche voisin »**, positions arrondies au pixel (aucun flou, aucun
scintillement) -> Aren mesure 192 px à l'écran en 1280 × 720.

## 4. Limites honnêtes

- Une seule image par pose dans la planche : l'attaque enchaîne 3 poses dessinées + déplacement, pas une
  animation dessinée image par image. Pour un mouvement plus fluide, il faudrait **2 à 4 images
  intermédiaires dessinées** par animation (armé, traînée, retour) — c'est le prochain asset à demander.
- La pose de garde est plus basse que les autres (accroupie) : cohérent, mais à valider visuellement.
- La base féminine n'a pas de planche de sprites : elle garde l'ancien visuel.
- Les deux compagnons n'ont pas de références : ils restent provisoires (style différent).
