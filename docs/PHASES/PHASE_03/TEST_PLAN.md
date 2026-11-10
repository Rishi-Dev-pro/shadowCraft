# PHASE 03 TEST PLAN — COMBAT 1 FOUNDATION

## Test Matrix

| Test area | Verification | Pass criteria | Result |
|---|---|---|---|
| Attack resources and timing | `tests/unit/test_combat_foundation.gd` | Jab and kick load, differ by kind, and have bounded 12-frame total phases | PASS |
| Input and animation resources | Same runner | Z/X actions exist; each attack has six 512×512 atlas frames | PASS |
| State gates | Same runner | Busy, airborne, and crouched states reject attacks; neutral accepts; combat lock releases after recovery | PASS |
| Spatial filtering and single-hit | Same runner and live physics | Player layer 4 reaches dummy layer 7 only during active frames; one hit per active window | PASS |
| Damage and health | Same runner | Mitigation math is bounded; health updates; lethal damage clamps at zero and emits defeat | PASS |
| Reactions and facing | Same runner | Knockback, hitstun, brief hit flash, and front-side mirroring work without changing physics-root orientation | PASS |
| Kai V2 regression | `tests/unit/test_kai_v2.gd` | V2 scene and animation assertions remain green | PASS |
| Phase 02 regression | `tests/unit/test_player_movement.gd` | Existing movement assertions remain green | PASS |
| Phase 01 regression | `tests/unit/test_kai_hierarchy.gd` | Existing hierarchy assertions remain green | PASS |
| Rendered visual check | Godot Movie Maker recording | Inspect idle, run-in, jab, kick and recovery frames in Compatibility renderer | PASS |

## Combat 1.1 Polish Regression

| Test area | Verification | Pass criteria | Result |
|---|---|---|---|
| Contact timing and hitbox trajectory | `tests/unit/test_combat_foundation.gd` | Both contact poses enter their active window; each active frame uses its own limb-aligned offset; the hitbox deactivates for recovery | PASS (52/52 suite) |
| Whiff and contact behavior | Same runner | Whiffs outside reach cause no damage; grounded contact damages once per active window | PASS |
| Feedback and repeat use | Same runner and rendered game | Hit-stop restores simulation time; sparks occur only on confirmed hits; repeated jab/kick attacks recover and land once | PASS |
| Actual game visual inspection | `reports/videos/combat11_after_showcase.avi`, `combat11_slow_motion.avi` | Inspect whiffs, contact frames, feedback, hitbox outlines, repeated attacks, and return to guard in Compatibility renderer | PASS |

## Combat Runtime Launch Repair

| Test area | Verification | Pass criteria | Result |
|---|---|---|---|
| F5 scene identification | `test_combat_foundation.gd` | Main scene stays `MovementTestArena.tscn`; its opponent marker has no hurtbox | PASS |
| Attack visual wiring on F5 Kai | Same runner | Kai V2's controller starts the jab/kick clips and retains the jab through active contact | PASS |
| Combat launch path | `run_combat.bat`; `test_combat_foundation.gd` | Explicit launcher targets combat arena with its own hit-feedback controller and damageable dummy; Combat suite 65/65 | PASS |
| Launcher missing-engine path | Same runner and `run_combat.bat` | Common Godot paths / PATH / `GODOT4_EXE` are checked; failure exits without a `pause` prompt | PASS |
| Actual rendered runtime | `reports/videos/combat_launch_after.avi` | Normal-speed scene capture shows contact poses, debug hitboxes, confirmed spark, dummy recoil and recovery | PASS |

## Recorded Evidence

- `reports/videos/combat1_foundation_showcase.avi` — 1280×720, 60 fixed-FPS, 240 frames.
- `reports/screenshots/combat1_idle.png`, `combat1_run.png`, `combat1_jab.png`, `combat1_kick.png`, `combat1_recovery.png`.

The fixed-rate movie is visual evidence, not an FPS or frame-time benchmark. No performance benchmark was run.

Combat 1.1 evidence is stored in `reports/videos/combat11_before.avi`, `combat11_after_showcase.avi`, and `combat11_slow_motion.avi`; selected rendered frames are under `reports/screenshots/combat11_after_*.png`.

Combat launch repair evidence is in `reports/videos/combat_launch_after.avi` and `reports/screenshots/combat_launch_*.png`.
