# Lot A — Simulation de combat : compte rendu

## Statut : exécuté et vérifié (Godot 4.5.1)

- **28 tests sur 28 réussis**, sans erreur de script (`godot --headless --script res://tests/run_tests.gd`).
- **Simulation complète** (`tools/simulate_battle.gd`) : victoire en 22 tours de Chasseurs, t=826,
  3 parties brisées, récompenses correctes (60 pièces, cuir + 3 composants de parties).
- **Écran de débogage** lancé et capturé : voir `docs/captures/lotA_combat_debug.png` (le monstre
  annonce son Souffle ; l'aperçu indique qu'une Technique VIF sur la Glande arrive avant).
- Lot validé techniquement. **Reste votre validation de ressenti** (voir « Points à juger »).

Premier constat d'équilibrage : la politique automatique gagne assez confortablement (Héros intact).
Le monstre est peut-être un peu faible ; à confirmer en jouant à la main avant d'ajuster.

## Ce qui est implémenté

| Exigence (doc 08 §4, GDD §31–35) | Implémentation | Test |
|---|---|---|
| Horloge entière commune, C = ⌈10000/V⌉, V bornée 70–135 | `Formulas.cycle_length`, `Battle._build_events` | `test_cycle_values_from_gdd`, `test_derived_speeds_of_profiles` |
| 3 Chasseurs (rapide / équilibré / lourd) + 1 monstre, même planificateur | `BattleFactory`, `EnemyAI` | `test_same_scheduler_for_monster_and_hunters` |
| VIF/MESURÉ/CHARGÉ changent la date d'effet et la puissance, pas le tour suivant | `Battle._commit` | `test_modes_change_effect_time_not_next_decision`, `test_modes_scale_damage_and_break` |
| Égalités de temps : départage stable et explicite | `Battle._event_less` | `test_tie_break_is_stable_and_explicit`, `test_resolution_before_decision_at_same_time` |
| Changement de Vitesse en cours de préparation : progression conservée | `Battle.set_speed_mod` | `test_speed_change_keeps_progress`, `test_never_ready_before_own_preparation` |
| Interruption avant résolution (rupture) ; tour suivant inchangé | `Battle.interrupt`, `_apply_break` | `test_break_interrupts_announced_attack` |
| Attaque vive avant le télégraphe, chargée trop tard | — | `test_quick_strike_beats_telegraph_but_charged_does_not` |
| Acteur vaincu avec action en attente | `Battle._on_defeated` | `test_defeated_actor_loses_pending_action` |
| Monstre impossible à retarder indéfiniment (±20 %/fenêtre, résistance croissante) | `Battle.shift_readiness` | `test_boss_delay_is_capped_and_decays`, `test_monster_cannot_be_stalled_forever`, `test_advance_is_capped_too` |
| Résonance par action, jamais par cible ; plafond 100 | `Battle._gain_resonance` | `test_resonance_is_per_action_and_capped` |
| Garde −40 % sur la prochaine attaque, +10 Résonance si utile | `Battle._apply_damage` | `test_guard_reduces_next_hit_by_40_percent` |
| 3 parties à intégrité séparée, effet réel, rupture et butin uniques | `MonsterPart`, `_apply_break` | `test_break_happens_once…`, `test_carapace_break_exposes_body` |
| Capacité de sérum (coût, VOL, recul d'initiative) | `_resolve_serum` | `test_serum_costs_resonance_and_delays_target` |
| Objet de soin | `_resolve_item` | `test_potion_heals_and_is_consumed` |
| Dégâts jamais négatifs | `Formulas` | `test_damage_is_never_negative` |
| Aperçu fidèle à la simulation | `preview_timeline`, `estimate` (même code que la simulation) | `test_preview_matches_simulation` |
| IA sans boucle infinie, victoire/défaite, récompenses | `EnemyAI`, `_check_end`, garde-fou | `test_full_battle_ends…`, `test_victory_rewards…`, `test_defeat_is_reachable` |
| Déterminisme | aucun hasard | `test_simulation_is_deterministic` |
| Journal horodaté | `Battle.journal` | visible dans l'écran debug et `tools/simulate_battle.gd` |

## Comment tester (voir README)

1. Ouvrir le projet dans Godot 4.5+, ouvrir `tests/test_runner.tscn`, appuyer sur **F6** : tout doit être vert.
2. Appuyer sur **F5** : jouer un combat dans l'écran de débogage.
3. Points à juger à la main :
   - La chronologie se lit-elle ? Comprend-on qui joue ensuite et quand tombent les effets ?
   - Choisir VIF ou CHARGÉ change-t-il vraiment la meilleure décision (surtout quand le Souffle est annoncé) ?
   - Le marteau (Compagnon B, lent) reste-t-il utile face aux dagues (Compagnon A, rapide) ?
   - La garde vaut-elle parfois mieux qu'une attaque ?

## Reste à faire / limites connues

- Sauvegarde/restauration d'un combat en cours : non faite (prévue avec la sauvegarde, Lot E, si utile).
- États (brûlure, ralentissement…) et esquive : non faits, hors minimum du brief.
- Un seul sérum de test, partagé par les trois Chasseurs.
- Équilibrage non réglé : les nombres sont ceux du GDD ou des estimations à ajuster en jouant.
