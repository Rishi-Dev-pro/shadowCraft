# PHASE 03 IMPLEMENTATION PLAN — COMBAT 1 FOUNDATION

**Status:** Combat 1 complete and verified; stop for user review.
**Scope authority:** User-approved first combat milestone, 2026-11-10.

## Completed Implementation Steps

1. Reuse the configured combat physics layers; keep MovementTestArena as the main scene.
2. Add typed AttackData and CombatMath; add HealthComponent for damage, health changes and defeat.
3. Add Hitbox2D/Hurtbox2D and connect them with per-target active-window filtering.
4. Add CombatController state/timing ownership and optional movement lock; let KaiV2AnimationController resume normal locomotion when combat exits.
5. Add original six-pose jab and front-kick atlas clips, distinct move data, Z/X controls, and a training dummy.
6. Create a separate `combat_test_arena.tscn` with HUD, live state telemetry and optional hitbox outlines.
7. Run unit/scene integration tests, Phase 01/02 regressions, and inspect a genuine Godot Movie Maker capture.
8. Complete architecture/integration and quality/completeness audits; update docs and commit only intended files.

## Gated Follow-Up

Do not begin combo engine, defense, advanced attacks, or shadow specials until the user reviews Combat 1 and explicitly authorizes the next milestone.
