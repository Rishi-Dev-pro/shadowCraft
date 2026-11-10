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
| Unified F5 runtime | `test_combat_foundation.gd` | Main scene contains Kai V2, existing TrainingDummy health/hurtbox, collision spacing, and health UI | PASS |
| Main-scene attack integration | Same runner and Compatibility runtime | Z/X animations play; whiff does no damage/no spark; jab/kick both damage dummy and confirmed hit spawns spark | PASS (78/78 suite) |
| Primary launcher | `run_shadowcraft.bat` | Godot 4.7.2 is found/verified, quoted project path launches configured main scene, debug flag and persistent log work | PASS; launched via batch, log `reports/logs/shadowcraft_latest.log` |
| Development launcher diagnosis | `run_combat.bat` | Trailing project-path separator is trimmed; explicit `--scene` loads the standalone test scene | PASS; exact invalid-path error reproduced before fix |
| Actual rendered unified runtime | `reports/videos/unified_gameplay_showcase.avi` | Main-scene recording shows forward/backward movement, crouch, no-effect miss, jab/kick contacts, sparks, dummy recoil and jump/landing | PASS; 1280×720, 60 FPS, 360 frames; visually inspected selected frames |

## Recorded Evidence

- `reports/videos/combat1_foundation_showcase.avi` — 1280×720, 60 fixed-FPS, 240 frames.
- `reports/screenshots/combat1_idle.png`, `combat1_run.png`, `combat1_jab.png`, `combat1_kick.png`, `combat1_recovery.png`.
- Unified main-game evidence: `reports/videos/unified_gameplay_showcase.avi`; rendered frames `reports/screenshots/unified_runtime_forward_backward.png`, `unified_runtime_whiff_no_effect.png`, `unified_runtime_jab_contact.png`, `unified_runtime_kick_contact.png`, `unified_runtime_jump.png`, and `unified_runtime_landing_ready.png`.

The fixed-rate movie is visual evidence, not an FPS or frame-time benchmark. No performance benchmark was run.

Combat 1.1 evidence is stored in `reports/videos/combat11_before.avi`, `combat11_after_showcase.avi`, and `combat11_slow_motion.avi`; selected rendered frames are under `reports/screenshots/combat11_after_*.png`.

Combat launch repair evidence is in `reports/videos/combat_launch_after.avi` and `reports/screenshots/combat_launch_*.png`.
