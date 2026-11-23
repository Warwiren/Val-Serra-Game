# art/p6 — ressources P6 (Colisée de Val'Serra)

| Fichier | Provenance | Statut |
|---|---|---|
| `combat/arene_colisee.png` | Rendu du blockout 3D du Colisée (`scenes/p6/colisee.tscn -- --decor_combat`), caméra de combat posée sur le sable, sans personnages ni interface, 1280 × 720 | **PROVISOIRE** (décor de blockout, matières P4 réutilisées) — à remplacer lors de la passe graphique |

Aucune nouvelle texture : le Colisée réutilise les matières P4 (`art/p4/mat/`, `art/p4/batiment/`, `art/p4/pont/`)
teintées, et le sprite du garde (`art/p45/chars/garde/`) pour tous les PNJ provisoires.
Régénérer le décor de combat après une modification du blockout :
`godot --path . --rendering-method forward_plus --resolution 1280x720 res://scenes/p6/colisee.tscn -- --decor_combat --etat=tutorial_available`
