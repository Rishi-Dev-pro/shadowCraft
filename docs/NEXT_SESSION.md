# NEXT SESSION — SHADOWCRAFT 2D

## Current State — Combat 1 Foundation (2026-11-10)

- Kai V2 is integrated and remains the playable character in `scenes/arenas/MovementTestArena.tscn`, the F5 main scene. The old Kai scene remains available as `scenes/characters/KaiLegacy.tscn`.
- The user authorized Combat 1 only. It is implemented in the isolated `scenes/arenas/combat_test_arena.tscn`; movement, crouch and jump still use the existing controller. The original Phase 01/02 arena is unchanged by combat integration.
- Controls in the Combat Test Arena: A/D move backward/forward, Space jump, S crouch, Z Light Jab, X Front Kick. The dummy is a damageable test target, not an AI opponent.
- Attack logic is data-driven through `resources/attacks/light_jab.tres` and `front_kick.tres`. Each uses a distinct six-frame animation atlas, startup/active/recovery timing, hitbox dimensions, damage and knockback. The full Phase 03 system is not complete.
- Run the test arena directly from Godot with `res://scenes/arenas/combat_test_arena.tscn`. Pass `--combat-debug` to show active hitbox outlines; pass `--combat-showcase` to capture the automatic jab/kick demo.
- Evidence: `reports/videos/combat1_foundation_showcase.avi`; inspected frames: `reports/screenshots/combat1_{idle,run,jab,kick,recovery}.png`.
- Automated results: Combat 1 `35/35`, Kai V2 `95/95`, Phase 02 movement `63/63`, Phase 01 hierarchy `44/44`. Godot 4.7.2, Compatibility renderer.
- Two-pass architecture and quality audits are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`. No performance benchmark was taken; the fixed-rate movie export is visual evidence, not an FPS measurement.

## Next Immediate Action

Wait for the user's visual approval of the Combat Test Arena. Do not begin the combo engine, defense, additional attacks, shadow specials, weapons, enemies, or later phases until explicitly authorized.

## Project Preservation Notes

- Preserve all existing user changes in the working tree; the checkout contains unrelated movement-playtest screenshots and scripts from earlier work. Stage only files listed for Combat 1.
- Do not modify the archived `D:\projects 2.0\games\exp-1` project.
- Combat 1 was committed after the documented validation; see the final handoff for the commit hash.

## Existing Movement Review Note

The earlier forward/backward gait review recorded significant planted-foot excursion and stiffness in `docs/CHANGELOG.md`. That movement-only concern remains separate from this Combat 1 task and is not modified here.
