# NEXT SESSION — SHADOWCRAFT 2D

## Grind combat refinement (2026-11-18)

- The supplied recording and a Godot reproduction showed the old body capsules allowed a 58-world-pixel gap under forward pressure. The refined grounded sprint test stops at 113 world pixels. Attack steps can close to the physical spacing limit.
- Architecture audit covered the Grind-only capsules, short committed steps, physics-timed active windows, separate decision and recovery states, and local impact pause. The fixed camera and courtyard scene stayed in place.
- Quality audit covered approach, neutral spacing, retreat, guard, close pressure, wall knockback, contact on both moves, victory, and return navigation. Kai's motion still uses authored frame art. Godot passed 38 rendered checks including captures. The input-driven run defeated the normal opponent AI with both attack types. Campaign movement and combat passed 63 and 78 checks.

## Grind animation repair (2026-11-18)

- Review in **World Map → Grind → The Gauntlet → Start Battle** or open the Grind lobby scene directly. The supplied pose guide drove the repair. The referenced gameplay recording was unavailable, so the pre-repair Godot run served as the baseline.
- Architecture audit covered the 2D rig, independent paint layers, a single pose writer, and duel-owned attack phase timing. The project reference checker returned zero errors and five pre-existing orphan UID warnings.
- Quality audit covered alternating foot lift and stance in all three gaits, guard mitigation, timed damage, knockback, collapse, victory, and return navigation in Godot. The campaign movement and combat suites passed 63 and 78 checks respectively.
- Kai still uses the painted frame set. His gait is adjusted at the support foot, so it retains the frame changes of the source drawings. No new campaign art or character rig was introduced.

## Grind Milestone 02 — First Gauntlet bout (2026-11-18)

- Open **World Map → Grind → The Gauntlet → Start Battle**. Moonveil Courtyard hosts one opponent and a local victory or defeat result. The full trial reward remains pending and the prototype leaves the inventory alone.
- On a fresh checkout of this branch, run `scenes/ui/grind_lobby.tscn` directly. The local World Map integration is a separate change. Grind Kai uses a dedicated SpriteFrames resource that references the shared Kai textures required for the bout.
- **Architecture audit:** The arena, fighters, cutout rig, duel controller, AI, attack resources, and HUD are separate from the campaign. The prototype references Kai's SpriteFrames and HealthComponent. The cutout manifest records the user-supplied source and pivots. Built-in ImageGen supplied the courtyard from a brief for an empty moonlit, timber-dojo courtyard with purple lanterns, distant mountains, and a flat open stone floor.
- **Quality audit:** Manually entered the fight through the World Map and inspected the live intro, arena, health bars, and Kai defeat. Rendered checks used controlled inputs and spacing to inspect gait states, both sides' strikes, guard, knockback, the Agile Ninja's grounded collapse, victory, and lobby return. Godot focused checks passed 17/17 headless and 30/30 rendered, including 13 captured frames. World Map 76/76, movement 63/63, and combat foundation 78/78 passed.
- Kai's Grind guard holds an existing anticipation pose. A sustained manual balance pass is still pending. Future opponents and trial rewards require separate authorization.

## Grind lobby animation and visual identity (2026-11-18)

- Open **Grind** from the World Map to replay the entrance. The Gauntlet, Dojo, and Forge keep their approved silhouettes. The Forge remains sealed pending Sensei's instruction.
- Architecture audit covered the existing inventory and World Map route, the shared custom button and dialogue, and two 2D petal batches. Ambient updates stop when the lobby is hidden or the game loses focus. The project reference checker reported zero errors and five existing orphan UID warnings.
- Quality audit included live controls and actual 1280×720 Compatibility renders of each entrance stage, changing petal positions, hover, a held press, the Forge requirement, and the Sensei reveal and dismissal. Regression suites passed for World Map 76/76, movement 63/63, combat 78/78, and character selection 53/53.
- Three 180-frame samples in the focused 1280×720 window measured 51.0 and 52.4 FPS with ambience active and 47.5 FPS with ambience frozen. The respective 95th-percentile frame times were 33.4, 33.5, and 34.8 ms.

## Grind mission-select redesign (2026-11-18)

- Grind opens from the existing World Map menu. The Gauntlet, Dojo, and Forge now occupy a single asymmetrical mission-select composition. Their original art is framed by custom 2D silhouettes. Click any destination or use Tab and Enter to activate it.
- Architecture audit covered the original lobby signal, inventory Resource, dialogs, and map fade. Drawing and hit testing are local to `scripts/ui/grind_mission_panel.gd`. Project reference checker reported zero errors and five pre-existing orphan UID warnings.
- Quality audit covered fullscreen and windowed visuals, all lobby actions, keyboard focus, map return, and live Hunter dossier selection. Automated layout checks catch overlapping anchor ranges and verify silhouette hit areas. World Map 72/72, movement 63/63, combat 78/78, and character selection 53/53 passed.
- The next gameplay milestone requires separate authorization.

## Grind Arena Milestone 01 (2026-11-18)

- Open **Grind** from the existing World Map command menu. The dedicated `scenes/ui/grind_lobby.tscn` is instantiated once inside the map. The map's visual layers are hidden during the lobby visit and restored after the return fade.
- Inventory counts originate from `resources/grind/player_inventory.tres` and start at Wood 0, Stick 0, and Stone 0. The resource supplies presentation data for this milestone. Forge prerequisites and Sensei's initial dialogue are shown in their own panels.
- **Architecture audit:** The lobby uses 2D Controls, one shared navigation panel, a typed inventory Resource, and no frame-based lobby work. It uses the existing map and guardian routing. Reference checker reported zero errors and five existing orphan UID warnings.
- **Quality audit:** Clicked through the lobby, inventory, trial, practice, Forge, guidance, and return controls in the visible Godot game. Checked fullscreen and windowed layouts and launched The Hunter in Mistfall Crossing after leaving Grind. The World Map regression suite passed 66/66 checks. The Executioner suite passed 19/19 assertions and emitted a resource-in-use warning at shutdown.
- **Next:** Wait for authorization before implementing trial gameplay, opponents, a Sensei story unlock, or crafting.

## Current State — Playable Character Selection Complete (2026-11-10)

- F5 and `run_shadowcraft.bat` start at `scenes/ui/character_select.tscn`. The selector shows animated Kai V2 and Razen idle previews, mouse cards, A/D or arrow selection, and PLAY.
- The selected fighter is instantiated into the existing `MovementTestArena` through one spawner. Both use the existing movement controller, arena, Combat 1 attack definitions, hitbox pipeline and damageable TrainingDummy. Razen has separate jab/kick animation clips in its own SpriteFrames asset.
- ESC pauses. Resume returns to play; Change Character unpauses and returns to the selector. The selection remains available for the next entry.
- Godot 4.7.2 Compatibility renderer captures: `reports/screenshots/character_selection_runtime.png`, `reports/videos/character_selection_runtime.avi`, `reports/videos/kai_selection_gameplay.avi`, and `reports/videos/razen_selection_gameplay.avi`. Capture logs are in `reports/logs/`.
- Regression results: Phase 01 44/44; Phase 02 63/63; Kai V2 95/95; Razen V2 113/113; Combat 1 78/78; selection 53/53. The capture showcase log confirms both shared attacks hit the dummy for each character.
- Both implementation audits and capture details are documented in `docs/CHARACTER_SELECTION.md`.

## Next Immediate Action

Wait for user review of the actual selection screen and both playable characters. Do not start combos, Combat 2, defense, additional combat, boss AI, or another project phase without explicit authorization.

## Prior Handoff — Razen Character Package (2026-11-10)

- Completed the authorized Razen production steps 3–6 in an isolated package. Razen has 56 original animation frames plus the approved signature pose, a CharacterData resource, standalone `Razen.tscn`, and a presentation-only animation controller reusing `CharacterController2D`.
- Godot resource build and focused test completed: Razen 93/93. Actual Compatibility-renderer captures are in `assets/characters/razen/previews/rendered/`; review recording: `assets/characters/razen/previews/razen_v2_review.avi`.
- Await visual approval of Razen before further character work. Do not begin Phase 08 boss AI/encounters. The attack-presentation clip is not a combat mechanic.
- F5 still launches Kai V2 in `MovementTestArena.tscn`; Kai and existing combat were not modified by this Razen task.

## Prior Handoff — Unified Movement and Combat Runtime (2026-11-10)

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
