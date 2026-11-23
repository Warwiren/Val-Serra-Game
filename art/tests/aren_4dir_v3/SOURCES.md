# Aren — marches / courses de face et de dos « en profondeur » (proposition V3) — BANC D'ESSAI (non validé)

**Statut : proposition, non validée. PROCÉDURALE.** Active au démarrage de la forêt F5 (touche G : V3 / 4dir / V2).

| Fichiers | Origine | Traitement (`tools/p49/aren_marche_profondeur.py`, rejouable) |
|---|---|---|
| `walk_face_0..7`, `walk_back_0..7`, `run_face_0..7`, `run_back_0..7` | `art/tests/aren_4dir/idle_face_0.png` / `idle_back_0.png` (étude « Aren IDLE V1 ») | pas en profondeur : pied avancé plus bas de face (plus haut de dos), ±5,6 px en marche, ±7,4 px en course ; pied en l'air levé de 3 / 6 px ; botte rigide, jambe étirée / tassée ; mains en opposition ±2 / ±3 px ; rebond 1 / 2 px ; bascule 1 px ; frange grise autour des bottes retirée |

Aucun pixel nouveau : seulement déplacés ou répétés. Ce ne sont PAS des poses dessinées. Mesures image par image
(position des pieds et des mains) et SHA-256 : `cadence_aren_4dir_v3.json`. Les attentes et le profil restent ceux de
`art/tests/aren_4dir/` et `art/tests/v09b5_aren/`.
