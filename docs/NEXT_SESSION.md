# NEXT SESSION — SHADOWCRAFT 2D

## Current State — Razen Character Package Awaiting Visual Approval (2026-11-10)

- Completed the authorized Razen production steps 3–6 in an isolated package. Razen has 56 original animation frames plus the approved signature pose, a CharacterData resource, standalone `Razen.tscn`, and a presentation-only animation controller reusing `CharacterController2D`.
- Godot resource build and focused test completed: Razen 93/93. Actual Compatibility-renderer captures are in `assets/characters/razen/previews/rendered/`; review recording: `assets/characters/razen/previews/razen_v2_review.avi`.
- Await visual approval of Razen before further character work. Do not begin Phase 08 boss AI/encounters. The attack-presentation clip is not a combat mechanic.
- F5 still launches Kai V2 in `MovementTestArena.tscn`; Kai and existing combat were not modified by this Razen task.

## Current State — Unified Movement and Combat Runtime (2026-11-10)

- Kai V2 is integrated and remains the playable character in `scenes/arenas/MovementTestArena.tscn`, the F5 main scene. The old Kai scene remains available as `scenes/characters/KaiLegacy.tscn`.
- The main/F5 `MovementTestArena.tscn` now composes the existing Combat 1 damageable TrainingDummy and its health/hurtbox without duplicating Kai's controller, combat state machine or health system. Movement, crouch, jump and physics remain owned by the existing controller.
- Controls in the Combat Test Arena: A/D move backward/forward, Space jump, S crouch, Z Light Jab, X Front Kick. The dummy is a damageable test target, not an AI opponent.
- Attack logic is data-driven through `resources/attacks/light_jab.tres` and `front_kick.tres`. Contact windows align with the dedicated six-frame animation clips, and each active physics frame has a matching hitbox offset. Confirmed contact triggers short hit-stop, a small impact spark and a tuned dummy recoil. Damage and collision architecture are preserved.
- Double-click `run_shadowcraft.bat` (or press F5 in the editor) for movement and combat in the same arena; `run_shadowcraft.bat debug` shows the attack hitbox. Launcher discovery covers supported Godot 4.7.2 locations, PATH and `GODOT4_EXE`, validates the engine, and persists output to `reports/logs/shadowcraft_latest.log`. `run_combat.bat` remains a separate development test scene, not a gameplay requirement.
- Evidence for the launch repair: normal-speed runtime capture `reports/videos/combat_launch_after.avi`, active hitbox view `reports/screenshots/combat_launch_kick_debug.png`, jab `reports/screenshots/combat_launch_jab.png`, and successful kick/contact `reports/screenshots/combat_launch_impact.png`.
- Final integration regression results are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`: Combat **78/78**, Kai V2 **95/95**, Phase 02 **63/63**, Phase 01 **44/44**. Godot 4.7.2, Compatibility renderer.
- Two-pass audits are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`. No performance benchmark was taken; the fixed-rate recordings are visual evidence, not FPS measurements.

## Next Immediate Action

Wait for the user's visual verification of the unified playable launcher. Do not begin the Combo Engine, input buffering, defense, additional attacks, shadow specials, weapons, enemies, or later phases until explicitly authorized.

## Project Preservation Notes

- Preserve all existing user changes in the working tree; the checkout contains unrelated movement-playtest screenshots and scripts from earlier work. Stage only files listed for Combat 1.
- Do not modify the archived `D:\projects 2.0\games\exp-1` project.
- Combat 1 was committed as `c80e0e5`; Combat 1.1 is a separate scoped polish commit after review.

## Existing Movement Review Note

The earlier forward/backward gait review recorded significant planted-foot excursion and stiffness in `docs/CHANGELOG.md`. That movement-only concern remains separate from this Combat 1 task and is not modified here.
