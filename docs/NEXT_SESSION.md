# NEXT SESSION — SHADOWCRAFT 2D

## Current State — Combat Runtime Launch Repair (2026-11-10)

- Kai V2 is integrated and remains the playable character in `scenes/arenas/MovementTestArena.tscn`, the F5 main scene. The old Kai scene remains available as `scenes/characters/KaiLegacy.tscn`.
- Combat 1 and the authorized Combat 1.1 polish pass are implemented in the isolated `scenes/arenas/combat_test_arena.tscn`; movement, crouch, jump and physics remain owned by the existing controller. The F5 movement arena is unchanged.
- Controls in the Combat Test Arena: A/D move backward/forward, Space jump, S crouch, Z Light Jab, X Front Kick. The dummy is a damageable test target, not an AI opponent.
- Attack logic is data-driven through `resources/attacks/light_jab.tres` and `front_kick.tres`. Contact windows align with the dedicated six-frame animation clips, and each active physics frame has a matching hitbox offset. Confirmed contact triggers short hit-stop, a small impact spark and a tuned dummy recoil. Damage and collision architecture are preserved.
- F5 intentionally remains on `MovementTestArena.tscn`; use `run_combat.bat` to launch the damageable training dummy arena, or `run_combat.bat debug` for hitboxes. In the editor, open `scenes/arenas/combat_test_arena.tscn` and press F6.
- Evidence for the launch repair: normal-speed runtime capture `reports/videos/combat_launch_after.avi`, active hitbox view `reports/screenshots/combat_launch_kick_debug.png`, jab `reports/screenshots/combat_launch_jab.png`, and successful kick/contact `reports/screenshots/combat_launch_impact.png`.
- Automated results after the repair are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`. Godot 4.7.2, Compatibility renderer.
- Two-pass audits are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`. No performance benchmark was taken; the fixed-rate recordings are visual evidence, not FPS measurements.

## Next Immediate Action

Wait for the user's visual verification of the combat launch repair. Do not begin the Combo Engine, input buffering, defense, additional attacks, shadow specials, weapons, enemies, or later phases until explicitly authorized.

## Project Preservation Notes

- Preserve all existing user changes in the working tree; the checkout contains unrelated movement-playtest screenshots and scripts from earlier work. Stage only files listed for Combat 1.
- Do not modify the archived `D:\projects 2.0\games\exp-1` project.
- Combat 1 was committed as `c80e0e5`; Combat 1.1 is a separate scoped polish commit after review.

## Existing Movement Review Note

The earlier forward/backward gait review recorded significant planted-foot excursion and stiffness in `docs/CHANGELOG.md`. That movement-only concern remains separate from this Combat 1 task and is not modified here.
