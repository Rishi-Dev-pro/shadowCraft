# PHASE 03 COMPLETION REPORT — COMBAT 1 FOUNDATION

**Milestone:** Combat 1 — Foundation
**Status:** Complete; Phase 03 remains in progress. Waiting for user visual approval.
**Engine:** Godot 4.7.2, GL Compatibility renderer.

## Delivered

- `AttackData` resources for Light Jab and Front Kick, with separate animation names, timings, hitbox dimensions/offset, damage, knockback, and hitstun.
- `CombatMath`, `HealthComponent`, `Hitbox2D`, and `Hurtbox2D` scripts. Combat physics uses existing layers 4–7. Attack hits are filtered to one per target per active window.
- A `CombatController` state machine (`NEUTRAL`, `STARTUP`, `ACTIVE`, `RECOVERY`, `HITSTUN`) that owns attack timing and animation selection. Kai's existing presentation controller pauses its state sync during combat, then resumes locomotion. Attacks lock movement; the existing CharacterController physics remains the owner of gravity and floor collision.
- Original six-pose Light Jab and Front Kick atlas clips embedded into the existing Kai V2 SpriteFrames resource. Distinct Z and X InputMap actions.
- A dedicated `combat_test_arena.tscn` with Kai V2, a 120-health training dummy, health bars, state/event labels and `--combat-debug` hitbox outlines. Its enemy body collision mask is local to this arena. The F5 scene remains `MovementTestArena.tscn`.

## Verification Results

- Combat foundation: **35/35** assertions.
- Kai V2 regression: **95/95**.
- Phase 02 movement regression: **63/63**.
- Phase 01 hierarchy regression: **44/44**.
- Godot 4.7.2 editor import/scene scan completed without parse or resource errors.
- Actual game verification: recorded and visually inspected `reports/videos/combat1_foundation_showcase.avi` (1280×720, 60 fixed-FPS, 240 frames) and `reports/videos/combat1_hitbox_debug.avi`. The inspected frames show the idle guard, approach, distinct jab contact, distinct front-kick extension and return to guard. Hitbox height was adjusted after comparing the active debug outline to the strike poses. Damage feedback and dummy health change are visible. This was a rendered game capture, not a headless visual claim.

## Two-Pass Audit

### Pass 1 — Architecture and Integration

- Confirmed the new arena and dummy use only 2D nodes and existing physics layers; no new external dependencies or 3D nodes.
- Confirmed `MovementTestArena.tscn` remains the configured main scene and KaiLegacy remains available. Combat-only spacing is scoped to `combat_test_arena.tscn`.
- Confirmed attack data, hitboxes, health, animation ownership and input actions connect through valid resource and node paths. Crouch/jump/physics behavior remains under the existing movement controller; the new attacks reject crouched and airborne initiation.
- Confirmed remaining roadmap milestones are listed as unstarted and gated.

### Pass 2 — Quality and Completeness

- Re-read new scripts, resources, scenes and documentation; refreshed Godot's global class cache after snake_case renames, then reran Combat 1 and Phase 01/02 regression suites.
- Confirmed one damage event per active window, no double attack initiation while busy, recovery returns to neutral, hitstun and knockback are applied, and defeat health clamps at zero.
- Inspected actual rendered frames from the movie; visual results show both attack poses and clean recovery. The training dummy is intentionally a simple prototype target.
- No FPS/frame-time benchmark was measured; the fixed-rate movie output is not reported as a performance measurement.

## Remaining Limitations

- Only Light Jab and Front Kick are implemented. There is no combo buffer/chain, guard, dodge, parry, poise, knockdown, aerial/sweep attack, shadow special, finisher, weapon, or opponent AI.
- The dummy supplies health and reactions but does not attack or block.
- Hit reactions are represented by knockback, hitstun and a brief violet flash; no dedicated authored hit-reaction animation is included yet.
- Manual input play is supported in `scenes/arenas/combat_test_arena.tscn`; the project F5 scene intentionally remains the movement test arena.

## Combat 1.1 — Basic Attack Polish (2026-11-10)

- Reproduced the original attacks and found their active windows ended at or just before the atlas's full contact pose. The static hitboxes also sat behind the visible jab knuckles and kick toe. This made the punch read as an abrupt arm extension and made contact difficult to read.
- Aligned both six-frame animation clips to the existing 12-tick total action duration: six startup ticks, two active ticks, four recovery ticks. This places the active window over the contact pose while leaving damage and total action duration unchanged.
- Added two per-active-frame hitbox offsets for each attack. The jab box is narrower and shifted to the fist; the kick box tracks the contact toe and slight retraction. Debug outlines were checked against actual rendered frames.
- Confirmed hits now trigger a real-time 40ms jab / 55ms kick hit-stop with time-scale restoration, a small code-drawn spark (different size for punch and kick), and eased dummy recoil. No camera shake, particle system, damage rebalance, or gameplay phase was added.
- Updated the combat regression runner to **52/52** assertions, including whiffs, active timing/offsets, hitbox deactivation, repeat attacks, and time-scale restoration. Re-ran Kai V2 **95/95**, Phase 02 **63/63**, and Phase 01 **44/44**.
- Actual Compatibility-renderer recordings: `reports/videos/combat11_before.avi`, `reports/videos/combat11_after_showcase.avi` (normal speed, hitbox debug), and `reports/videos/combat11_slow_motion.avi` (0.35× showcase). Selected whiff, contact, impact, and recovery frames are under `reports/screenshots/combat11_after_*.png`.
- Pass 1 verified 2D-only nodes, valid scene/resource references, existing physics/layers/input, and no movement-scene changes. Pass 2 reread modified code/resources/docs, ran all four suites, and inspected normal and slow-motion rendered footage. No performance benchmark was run. Pre-existing unrelated movement files remain untouched.

Combat 1.1 is complete and waits for visual approval. Combo Engine work remains gated.

## Runtime Launch Repair (2026-11-10)

- **Root cause:** F5 launches `res://scenes/arenas/MovementTestArena.tscn`. It instances Kai V2 with the CombatController and its attack SpriteFrames, but its `DummyTarget` is only a visual `Node2D` marker. It has no health/hurtbox, and the movement arena does not install `CombatTestArenaController`, the scene-level owner that displays combat telemetry, hit-stop, and impact sparks. As a result, hit confirmation effects are impossible in the F5 movement test scene even though the jab and kick clips are connected. The dedicated combat arena already has the correct dummy and feedback owner.
- **Fix:** Preserved the F5 main scene. Added `run_combat.bat` to launch the existing `combat_test_arena.tscn` explicitly; its `debug` argument enables hitbox outlines. README and NEXT_SESSION now explain the difference, and the Combat 1 runner checks the main-scene choice, missing marker hurtbox, attack clips on F5 Kai, and combat-scene feedback owner.
- **Verification:** Combat suite **62/62**, Kai V2 **95/95**, Phase 02 **63/63**, Phase 01 **44/44**. Godot 4.7.2 editor scan and project reference scan completed. Actual Compatibility-renderer capture from `combat_test_arena.tscn`: `reports/videos/combat_launch_after.avi` (1280×720, 60 FPS, 480 frames; normal speed, debug hitboxes). Inspected contact/impact frames under `reports/screenshots/combat_launch_*.png`; the jab and front kick select their attack clips, hitboxes overlap the dummy at contact, the impact spark is visible, and dummy recoil/health response appear. No performance benchmark was taken.
- **Pass 1 — Architecture & Integration:** Confirmed F5 configuration is unchanged, `run_combat.bat` targets only the existing combat arena, attack resource/sprite references resolve, the movement marker remains decorative, and the combat arena contains the damageable training dummy and feedback owner. Only 2D nodes are used; no archived project or future milestone was touched.
- **Pass 2 — Quality & Completeness:** Re-read the launcher, test additions, and docs; ran all four suites and Godot scans; checked the normal-speed rendered footage and selected frames. The combat launcher uses the local Godot installation or PATH fallback and keeps the existing F5 workflow intact.

The runtime launch repair is complete and awaits user verification. Combat 2 remains unstarted.

### Launcher pause follow-up

- Reproduced the prompt wait in `run_combat.bat`: when Godot could not be resolved by the launching shell, the error branch ran a literal `pause`. Removed it and added searches for the 4.7.2 executable under standard local/program folders, both Godot executable names on PATH, and a `GODOT4_EXE` override. The game launches as a foreground process so launcher errors remain visible; the F5 scene and combat systems are unchanged.
- Added launcher regression assertions. Final Combat suite: **65/65**; Kai V2 **95/95**, Phase 02 **63/63**, Phase 01 **44/44** remain passing. The prior actual runtime recording still verifies visual combat; this follow-up changes only Windows executable lookup/launcher waiting.

## Git

- Branch: `codex/kai-rebuild-checkpoint-20261110`.
- Commit: recorded in the final handoff after validation.
- Pre-existing unrelated working-tree changes are excluded from the commit.
