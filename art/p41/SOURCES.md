# art/p41 — ressources P4.1 (netteté des personnages, raccords du décor)

Régénérables :
`python3 tools/p41/build_chars_p41.py <planches Drive>` (personnages) et `python3 tools/p41/decor_p41.py` (décor).
**Rien n'est déclaré final.** Les originaux (`art/proto/`, `art/explore_hd2d/`, `art/p4/`) ne sont pas modifiés.

| Dossier | Contenu | Source | Statut |
|---|---|---|---|
| `chars/aren/` | 24 images : repos 4 vues (+ respiration), marche 4 directions × 4 | Drive `Art/Aren/Aren_sprites_exploration.png` (1448 × 1086), réextrait à **57 px** de haut (P4 : 28 px) | net ; palette 96 couleurs ; à valider en mouvement |
| `chars/ilya/` | 24 images, mêmes noms | Drive `Art/Ilya/Ilya-1.png` (1121 × 744) : planche petite et rééchantillonnée, **38 px** au mieux | **provisoire** — design canonique respecté, mais détail limité (yeux à peine lisibles) ; à refaire |
| `chars/pnj/` | garde, 2 images (profil) | `art/proto/pnj.png` (pack 2026-11-07) à sa taille d'origine (P4 : réduit à 25 px) | provisoire — un seul profil |
| `chars/vorgane/` | 8 images de repos | **mêmes images que le combat** (`art/proto/vorgane_nuit_p1`, calques composés), retournées | même design qu'en combat ; voir rapport |
| `combat/aren/` | 50 images (repos, avance, préparation, attaque, impact, retour, garde, touché, Résonance) | Drive `Aren_sprites_combat.png`, **60 px** affichés ×2 (P4 : 40 px affichés ×3) | net ; même taille à l'écran |
| `combat/ilya/` | 9 poses (attente, respiration, préparation, tir, fin ; garde, touché et Aether = copies) | Drive `Art/Ilya/Ilya-2.png` | **provisoire** — 4 poses réelles seulement |
| `portraits/ilya/` | 6 expressions | Drive `Ilya-1.png` | planche canonique ; 128 px de large |
| `decor/` | 16 arbres / accessoires sans « plaque de sol » peinte ; 4 touffes d'herbe | `art/p4/` (packs P4_ENV_MODULES_v01, P4_PILOTES_TECH_v01) nettoyés ; touffes générées aux couleurs de SOL-01 | à tester |
