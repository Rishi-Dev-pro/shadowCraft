# CHANGELOG

All notable changes to **ShadowCraft 2D** are documented in this file.
### Grind combat refinement (2026-11-18)

- Widened the duel-only body capsules to fit the fighters' painted silhouettes and added a braking margin before contact. Kai can still backstep or jump, and short attack steps stop at the body gap.
- The Agile Ninja now approaches with measured steps, positions, attacks, recovers, and makes bounded retreats before re-entering range.
- Active contact follows the Ninja's blade or Kai's painted striking hand. Impacts pause the duel briefly, and guard retains the existing damage reduction and recovers sooner from blockstun so there is time to counter.

### Grind animation repair (2026-11-18)

- The Agile Ninja now drives joint poses and two-bone foot placement from one physics-timed animation pass. Gait advances from actual travel and the hips lower when a planted step would exceed the leg's reach.
- Reworked guard, quick slash, spinning slash, recoil, knockback, and defeat from the supplied pose guide. Re-anchored the painted headband tails and masked sleeve pixels from the cloak. The strike resources still determine the hit windows and damage.
- Grind Kai uses his existing painted frames with grounded support offsets, distance-driven gait, separate reaction timing, and an existing low-stance clip for guard.


### Grind Milestone 02 — First Gauntlet bout (2026-11-18)

- The Gauntlet preparation panel starts one Kai versus Agile Ninja encounter in Moonveil Courtyard. The battle includes its own HUD, controls, rematch, and result screen. The material reward remains a preview.
- The Agile Ninja's cutout layers use manually traced masks from the left figure in the supplied concept. Skeleton2D, Bone2D, and AnimationPlayer drive the poses. Distance-driven two-bone foot placement supports locomotion and articulated scarf tails follow motion.
- Added isolated duel movement, input actions, timed light and heavy strikes, directional guard, knockback, and an opponent rhythm with pauses, retreat, and guarding. Grind Kai shares the existing artwork and health component.
- Godot 4.7.2 verified 17/17 focused headless checks and 30/30 rendered checks including 13 captures. World Map 76/76, player movement 63/63, and combat foundation 78/78 passed.

### Grind lobby animation and visual identity (2026-11-18)

- Added a shared, clipped ShadowCraft button with blade and seal marks, a traveling border highlight, and a short inset response on press. Shippori Mincho and Barlow provide the lobby typography and include their OFL notices.
- The existing mission silhouettes use a single staggered AnimationPlayer sequence. The Gauntlet reveals diagonally, the Dojo vertically, and the Forge from its furnace. Two 2D petal batches, drifting mist, localized light changes, and a few embers animate while the lobby is visible and focused.
- Sensei's dialogue opens in a crest-marked side panel. The mission, inventory, and guidance dialogs share an ink reveal, keyboard focus handling, and animated dismissal.
- Inspected Godot Compatibility renders at 1280×720 and exercised the lobby controls in the running game. Regression checks passed for the World Map (76), movement (63), combat (78), and character selection (53).

### Grind mission-select redesign (2026-11-18)

- Rebuilt the composition around the angular Gauntlet, the tall Dojo gate, and the low, stepped Forge. Reframed the existing artwork inside custom silhouettes and used each silhouette for mouse hit testing.
- Moved the shared inventory counters into the header and Sensei's guidance to a crescent-marked control below the Dojo. Both still open the existing dialogs.
- Inspected the visible Compatibility-renderer game in fullscreen and windowed mode. Verified the mission and utility controls, keyboard activation, return to the map, and guardian dossier selection. Godot regressions passed for the World Map (72), movement (63), combat (78), and character selection (53).

### Grind Arena Milestone 01 (2026-11-18)

- Added the cinematic Grind lobby, with a shared material summary and inventory, three activity entries, the Wooden Sword recipe preview, and Sensei's initial guidance.
- Connected the existing World Map command menu to the lobby with a two-way fade. The menu highlights Grind while the lobby is open, and returning restores the same map and guardian selection.
- The lobby reads Wood, Stick, and Stone from `resources/grind/player_inventory.tres`. Combat Trials and Practice Grounds open preparation panels, and Weapon Forge explains the Sensei story requirement.
- Godot 4.7.2 Compatibility verification covered all lobby panels, the return button, and a Hunter rematch launch. The World Map suite passed 66 checks. Movement, combat foundation, character selection, Kai V2, and Combat Phase 2 Step 2 suites passed. All four guardian suites passed their assertions, with one resource still in use at shutdown in the Executioner suite.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Combat 1.1 attack polish

### Playable character selection (2026-11-10)
- Made the character-select screen the F5/main launch scene with animated idle previews from the real Kai V2 and Razen sprite-frame resources. Mouse selection, A/D or arrows and PLAY are wired to a single selection-state autoload.
- Added a runtime spawner in the existing movement/combat arena. The selected character keeps its own character data, artwork and animation controller while both reuse the same movement, Combat 1 attacks, hitboxes, health and TrainingDummy.
- Added Razen-specific jab/kick animation frames, plus ESC pause with Resume and Change Character actions.
- Added selection/switching regression coverage and a Godot Movie Maker capture runner. The selector and both characters were inspected in Compatibility-rendered gameplay recordings.
- Verification: Phase 01 44/44; Phase 02 63/63; Kai V2 95/95; Razen V2 113/113; Combat 1 78/78; character selection 53/53. Captures/logs are listed in `docs/CHARACTER_SELECTION.md`.

### Razen standalone character package (2026-11-10)
- Completed the user-approved Razen visual production follow-up in an isolated package. Generated original sheets for 8 idle, 8 forward walk, 8 backward walk, 8 run, 4 crouch, 8 crouch-walk, 4 jump, 4 landing and 4 attack-presentation frames. Normalized 56 frames plus the approved signature pose as a one-frame combat-ready presentation.
- Added animation provenance/frame manifests, transparent aligned frame PNGs, contact sheets, a Godot `SpriteFrames` builder, Razen `CharacterData`, a dedicated animation controller, `Razen.tscn`, a separate rendered-review arena and a 93-check scene/resource regression test.
- Reused `CharacterController2D` with independent presentation-only frame animation. Did not alter the F5 scene, Kai V2, combat architecture, or Phase 08 boss gate. `attack_presentation` is not connected to combat.
- Visual review caught and corrected the initial sprite pivot offset: centered 512px frames need a local Y offset of -232px at 0.7 scale to align the y=488 sole anchor to the physics floor.
- Godot 4.7.2 built the SpriteFrames resource; the final Razen checks cover all state mappings and pass **93/93**. Regressions pass: Kai V2 **95/95**, Phase 02 **63/63**, Phase 01 **44/44**, Combat **78/78** at fixed 60 FPS. A real-time headless Combat run exposes one existing timing-sensitive animation-frame assertion, documented with its deterministic pass in `docs/RAZEN_CHARACTER_PRODUCTION.md`.
- The configured F5 scene was also rendered with the existing integration showcase; the Godot log confirmed the jab miss, confirmed jab and kick hits, and dummy health change. Actual Compatibility-renderer Razen screenshots for every clip and a 4.7-second review AVI are in `assets/characters/razen/previews/`. Both audits are documented in `docs/RAZEN_CHARACTER_PRODUCTION.md`.

### Unified playable movement and Combat 1 arena (2026-11-10)
- Composed the existing TrainingDummy scene into `MovementTestArena.tscn` and wired its existing damage, hurtbox, hit reactions, health UI, hit-stop, hit spark, hitbox debug display, and combat telemetry through the arena controller. Kai keeps the original movement/crouch/jump controller and now collides with the dummy body.
- `run_shadowcraft.bat` is now the one-click game launcher. It searches standard locations and PATH, accepts `GODOT4_EXE`, validates Godot 4.7.2, runs the configured main scene from the quoted project directory, and writes `reports/logs/shadowcraft_latest.log`; failure prompts are conditional. Removed the launcher's archived-project engine fallback.
- Added an in-engine integration showcase option and main-arena combat regression assertions. The dedicated combat arena remains a development test scene; Combat 2 is not started.
- Reproduced the old development launch failure exactly: its `%~dp0` path retained a trailing backslash inside a quoted `--path` argument, causing Godot to merge the following scene path into an invalid project path. Trimmed the directory and switched that optional test launcher to explicit `--scene`; ordinary play uses only the main launcher.

### Combat launch integration repair (2026-11-10)
- Diagnosed the missing hit response when launching with F5: the configured main scene is `MovementTestArena.tscn`. It contains Kai V2, but its `DummyTarget` is only a visual facing marker and the scene has no dummy hurtbox or CombatTestArenaController to spawn hit-stop and impact sparks. The combat-enabled arena remained separate.
- Preserved the F5 movement scene and added `run_combat.bat` as an explicit launch path for `combat_test_arena.tscn`; the `debug` argument enables active hitbox outlines. README and the phase handoff explain the distinction.
- Added regression assertions for main-scene identity, Z/X attack events selecting and advancing the attack clips on F5 Kai, the non-damageable movement marker, and the combat arena's presentation owner. Combat suite is now 62/62; no attack, movement, or damage rules changed.
- Re-recorded the explicitly launched combat arena at normal speed and inspected jab/kick contacts, hit sparks, dummy recoil, recovery and hitbox debug. All existing suites passed; no performance benchmark was measured.
- Follow-up: reproduced the launcher's prompt wait when its Godot lookup failed. Added standard install-folder and PATH resolution plus a `GODOT4_EXE` override, and removed the blocking `pause`; the failure path now prints an error and exits. Added regression checks for the target scene, executable lookup, and non-blocking failure path.

### Combat 1.1 basic attack polish (2026-11-10)
- Aligned Light Jab and Front Kick contact phases to the authored frame-4 pose within their unchanged 12-physics-frame total duration. Attack data now stores a hitbox offset for each active frame; the hitbox follows the fist recoil and toe retraction, and tighter shapes place the active region over the visible striking limbs.
- Added confirmed-hit-only 40ms jab / 55ms kick hit-stop, small code-drawn impact sparks with distinct punch/kick scale, and eased dummy recoil. Damage values, collision layers, single-hit-per-window handling, and movement/physics ownership remain unchanged.
- Expanded Combat foundation regression coverage to 52 assertions, including whiff/contact, active-frame alignment, hitbox trajectory and deactivation, repeat attacks, and hit-stop restoration. Kai V2 95/95, Phase 02 63/63, and Phase 01 44/44 also passed.
- Captured the normal-speed and reduced-time-scale rendered sequences with active hitbox outlines, plus actual jab/kick whiff, contact, impact, and recovery frames under `reports/videos/combat11_*.avi` and `reports/screenshots/combat11_after_*.png`.
- Completed both architecture/integration and quality/completeness audits. No performance benchmark was measured. Combo chaining and all later Combat milestones remain gated pending visual approval.

## [Earlier] — Combat 1 foundation

### Combat 1 foundation (2026-11-10)
- Added typed `AttackData`, `CombatMath`, `HealthComponent`, `Hitbox2D`, `Hurtbox2D`, and Kai V2's combat state/timing controller. The controller owns startup, active, recovery and hitstun; the existing animation controller yields visual ownership during combat. Attacks are ground-only and once-per-target during each active window.
- Added original six-pose Light Jab and Front Kick atlases; integrated each as a separate 30 FPS clip in the existing Kai V2 `SpriteFrames`. `AttackData` configures frame timing, hitbox position/size, damage, knockback and hitstun.
- Added a damageable 2D training dummy and a separate `CombatTestArena` with health bars, state feedback and opt-in hitbox outlines. Combat-arena enemy body collision is local to this scene; the F5 Movement Test Arena remains the main scene.
- Added Z and X input actions. Adjusted jab/kick hitbox height after inspecting the rendered debug outline against Kai's fist and kick contact. Headless tests passed: Combat 1 35/35, Kai V2 95/95, Phase 02 movement 63/63, Phase 01 hierarchy 44/44.
- Captured and visually inspected the actual Godot 4.7.2 Compatibility-renderer recording `reports/videos/combat1_foundation_showcase.avi` and the idle/run/jab/kick/recovery frames under `reports/screenshots/combat1_*.png`.
- Pass 1 verified 2D-only scenes, valid resource links, isolated arena collision, and preserved Phase 01/02 entry scenes. Pass 2 reviewed all new code/resources, ran the four test suites, and inspected the recorded animation and impact frames. No frame-time benchmark was recorded.
- Phase 03 remains in progress. Combo chaining, defense, advanced moves and specials are not implemented; wait for explicit authorization before starting another Combat milestone.

### Kai V2 playable integration (2026-11-10)
- Added `scenes/characters/KaiV2.tscn` as an independent `CharacterBody2D` playable character using imported transparent 512×512 frames through a reusable `SpriteFrames` resource and a presentation-only animation controller. Preserved the former scene as `KaiLegacy.tscn` for rollback, removing only its duplicated scene UID so both files remain independently addressable.
- Integrated idle, forward/backward walk, run, crouch, crouch walk, jump, and landing animations with the existing movement controller. V2-only run and crouch-walk behavior is opt-in; original controller defaults preserve Kai V1 behavior. Added Shift+forward run input.
- Made Kai V2 the arena character in the existing `run/main_scene`; retained acceleration, gravity, jump impulse, collision, arena boundaries, and player controls. Updated arena instructions for run.
- Added 95 focused Kai V2 scene/resource/runtime assertions. Godot 4.7.2: Kai V2 95/95, Phase 02 movement 63/63, Phase 01 hierarchy 44/44. Captured a genuine Compatibility-renderer Movie Maker recording and verified idle, walk, run, retreat, crouch, crouch-walk, jump, platform landing, and recovery frames.
- Pass 1 audit: new scene is 2D-only; all referenced resources resolve; `KaiLegacy.tscn` is retained without a duplicated UID; `exp-1` is untouched; Phase 03 remains gated. Pass 2 audit: changed files re-read, all 202 focused/regression assertions passed, rendered movie inspected, working tree contains unrelated pre-existing files which are excluded from this commit.
- Evidence: `reports/videos/kai_v2_integration.avi` and actual-game frames `reports/screenshots/kai_v2_{idle,forward,run,backward,crouch,crouch_walk,jump,landing,idle_after}.png`.

### Signature stance and reference gait pass (2026-11-10)
- Re-authored Kai's idle guard and forward/backward walk clips with eight explicit gait poses, pelvis transfer, knee/foot articulation, and a distinct retreat profile while retaining the existing Skeleton2D and artwork.
- Captured the idle stance and every authored forward/backward pose in the running Godot scene under `reports/screenshots/kai_reference_after_*.png`; the walking runner reports 13/13 checks passing, including a sampled support foot in all eight poses per direction.
- Visual review remains open: measured planted-foot excursion is still large (up to 147.54px forward and 164.59px backward), and some gait poses read stiff. The eight-pose contact checks do not establish convincing foot locking. Treat this pass as provisional pending rig/foot-placement work and human review.
- No movement controller, physics, collision, crouch, jump, landing, or new art assets were changed in this pass. Phase 03 remains gated.

### Fixed
- Refined only Kai's forward and backward walk clips with modest hip bob, hip/torso counter-rotation, a purposeful backward torso lean, and stronger opposite arm swing. Leg and foot curves were retained after tuning iterations increased measured foot slide. Crouch, jump, landing, collision, and movement physics remain untouched.
- Added a live walking sequence runner with idle/start/continuous/stop captures, forward/backward reversals, ground-foot sampling, and genuine Godot before/after movies.
- Validation note: state transitions passed 7/7. Current sampled grounded-foot horizontal excursion is higher than the baseline, so foot locking remains a known visual limitation for a future walk-only iteration.
- Repaired Kai's crouch pose: corrected the back knee bend, kept both soles grounded by removing the 29px foot-sprite offsets, and adjusted pelvis height for crouch contact.
- Added ankle compensation to both walk cycles and restored complete leg and arm chains on idle/walk/jump/landing clips so no stale bone rotations remain when a state changes; transitions now blend through the existing AnimationPlayer.
- Replaced the overlapping procedural airborne bone writer with authored `jump_air` and `jump_land` clips in Kai's existing animation library.
- Updated the movement regression assertion to verify the shared AnimationPlayer owns airborne and landing clips.
- Added a live 17-check transition runner and genuine before/after Godot screenshots and movies under `reports/`.
- Kept locomotion state and cycle active through ground deceleration; animation playback rate now follows horizontal velocity to reduce foot sliding.
- Froze the active ground pose through both jump and fall, and added a separate skeletal tuck and eased landing settle without changing Kai's artwork or ground cycles.
- Preserved the pre-collision downward speed for landing feedback, reset vertical speed after contact, and guarded standing capsule expansion against overhead obstruction.
- Lowered the movement test platform to an 80px rise, reachable within the existing approximately 90px jump arc. Jump impulse and gravity remain unchanged.
- Added regression assertions for repeated airborne jump input, measured jump height, platform reachability, velocity-matched walking animation, and the airborne presentation component.

---

## [0.3.0] — 2026-11-09
### Phase 02: Player Movement & Controls

#### Added
- **Fighting Game Input Map:**
  - Configured input actions in `project.godot`: `move_forward` (D / Right), `move_backward` (A / Left), `move_left` (A / Left), `move_right` (D / Right), `jump` (Space / W / Up), and `crouch` (S / Down).
- **Player Kinematics & State Machine:**
  - Authored `scripts/characters/CharacterController2D.gd` utilizing a statically typed 6-state kinematics machine (`IDLE`, `MOVE_FORWARD`, `MOVE_BACKWARD`, `CROUCH`, `JUMP`, `FALL`).
  - Implemented decoupled `update_kinematics(delta, move_input, jump, crouch, on_floor)` function allowing deterministic headless simulation and in-engine execution.
  - Implemented smooth acceleration (1800 px/s²), ground friction (2200 px/s²), walk speed (220 px/s), and retreat speed (180 px/s).
  - Implemented vertical gravity (980 px/s²), vertical jump impulse (-420 px/s), and terminal fall velocity (1200 px/s).
- **Collision & Physical Bounds:**
  - Added dynamic capsule collision resizing in `scenes/characters/Kai.tscn`: standing height (320px, Y=-160px) and crouched height (200px, Y=-100px), maintaining grounded foot base at Y=0.
  - Implemented strict crouch jump lockout preventing jump initiation while crouching.
  - Enabled floor landing reset and solid wall collision adherence.
- **Facing & Animation Integration:**
  - Implemented automatic and manual opponent tracking by flipping visual `Skeleton2D.scale.x = ±0.48` while preserving normalized root `CharacterBody2D.scale = Vector2(1, 1)` to eliminate inverted collision normal bugs.
  - Connected states to Phase 01 locomotion cycles (`loco/idle`, `loco/walk_fwd`, `loco/walk_bwd`, `loco/crouch`) with airborne freeze safety.
- **Movement Test Arena & Telemetry:**
  - Created `scenes/arenas/MovementTestArena.tscn` with solid floor (Layer 1), left/right perimeter boundaries, elevated test platform (Y=420), dummy opponent target (X=960), and real-time telemetry diagnostics HUD.
  - Created `scripts/arenas/MovementTestArenaController.gd` providing real-time telemetry display and automated showcase playback capability.
- **Automated Testing & Visual Verification:**
  - Authored comprehensive test suite `tests/unit/test_player_movement.gd` covering 55 assertions across 11 test suites (100% pass rate).
  - Verified Phase 01 regression suite `tests/unit/test_kai_hierarchy.gd` (44/44 assertions passed, combined 99/99).
  - Captured in-engine visual proof in `reports/screenshots/` (`movement_arena_composite.png`, `movement_walk_fwd.png`, `movement_jump.png`, `movement_crouch.png`).

---

## [0.2.0] — 2026-11-09
### Phase 01: Kai: 2D Character Art & Animation Pipeline

#### Added
- **Visual Concept & Sprites:**
  - Created original high-resolution 2D character concept sheet and side-profile reference for Kai (`assets/characters/kai/kai_concept_art.png`).
  - Sculpted 16 transparent 32-bit PNG anatomical limb components with convex rounded joint caps and transparent borders (`head.png`, `torso.png` with purple star emblem, `arm_upper_fwd.png`, `arm_lower_fwd.png`, `hand_fwd.png`, `leg_upper_fwd.png`, `leg_lower_fwd.png`, `foot_fwd.png`, plus darkened back limb layers for depth).
- **Data Architecture:**
  - Created `CharacterData.gd` resource definition (`scripts/characters/CharacterData.gd`) for character metadata, identity, and combat attributes.
  - Created `resources/characters/kai.tres` defining Kai's baseline stats (100 HP, 100 poise, 220 walk speed, agile weight class).
- **Character Rig & Locomotion Scene:**
  - Built `scenes/characters/Kai.tscn` featuring `Skeleton2D` with an 18-bone humanoid hierarchy, precise joint offsets, and dedicated `Marker2D` weapon socket (`Socket_Weapon`).
  - Implemented 4 core locomotion cycles under library `"loco"` in `AnimationPlayer`:
    - `loco/idle`: 1.6s looping martial breathing and weight sway.
    - `loco/walk_fwd`: 1.0s fluid forward martial stride with opposing limb swing.
    - `loco/walk_bwd`: 1.0s defensive backward retreat stride.
    - `loco/crouch`: 0.5s grounded low-center-of-gravity martial guard with raised fists protecting chin and chest.
- **Verification & Visual Gate:**
  - Built interactive preview arena `scenes/arenas/KaiPreview.tscn` displaying all 4 states alongside the concept model sheet.
  - Added automated unit test suite `tests/unit/test_kai_hierarchy.gd` covering 44 assertions across scene nodes, bone structure, animation tracks, and resource integrity.
  - Captured in-engine Godot screenshots in `reports/screenshots/` verifying visual fidelity, seam quality, and ground alignment.

---

## [0.1.0] — 2026-11-09
### Phase 00: Project Constitution, Architecture & Development Environment

#### Added
- **Repository Setup:**
  - Initialized Git repository on `main` branch with Git LFS filter support.
  - Added `.gitignore` configured specifically for Godot 4, GDScript, and GdUnit4 artifacts.
  - Added `.gitattributes` to normalize line endings (`LF`) across all scripts, scenes, and configs.
  - Added MIT License with explicit proprietary reservation for original character lore, artwork, and designs.
- **Engine Configuration:**
  - Configured `project.godot` for Godot 4 (GL Compatibility renderer, 1280x720 baseline resolution, 60 FPS V-Sync, integer pixel snapping).
  - Defined 2D Physics Layers: Layer 1 (`environment`), Layer 2 (`player_body`), Layer 3 (`enemy_body`), Layer 4 (`player_hitbox`), Layer 5 (`enemy_hitbox`), Layer 6 (`player_hurtbox`), Layer 7 (`enemy_hurtbox`).
- **Standardized Directory Structure:**
  - Created standardized folders for `assets/`, `scenes/`, `scripts/`, `resources/`, `tests/`, and `docs/` with `.gitkeep` markers.
- **Governance & Directives:**
  - Created root-level `AGENTS.md` specifying the 22 mandatory operational rules, strict 2D enforcement, and two-pass audit protocols.
  - Created `docs/PROJECT_CONSTITUTION.md` as the permanent source of truth for design, combat philosophy, performance, and originality.
- **Technical Architecture:**
  - Created `docs/ARCHITECTURE.md` with complete Mermaid diagrams for system architecture, character components, combat sequence flow, weapon attack lifecycles, and enemy AI loops.
  - Created 11 Architecture Decision Records (`docs/DECISIONS/ADR-0001` through `ADR-0011`) covering engine selection, 2D mandate, Compatibility renderer, hybrid animation, weapon data decoupling, combat pipeline, GDScript typing, GdUnit4 testing, Git workflow, performance targets, and copyright protection.
- **Guidelines & Strategy:**
  - Created `docs/TECH_STACK.md`, `docs/ASSET_GUIDELINES.md`, `docs/ANIMATION_GUIDELINES.md`, `docs/COMBAT_DESIGN.md`, `docs/WEAPON_SYSTEM.md`, `docs/TESTING_STRATEGY.md`, `docs/PERFORMANCE_GUIDELINES.md`, `docs/SECURITY_GUIDELINES.md`, and `docs/GIT_WORKFLOW.md`.
- **Phase Documentation:**
  - Created `docs/PHASES/PHASE_00/SPECIFICATION.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, and `COMPLETION_REPORT.md`.
- **CI & Quality Automation:**
  - Created GitHub Actions workflow `.github/workflows/ci.yml` for automated headless validation and testing.

#### Security & Integrity
- Verified complete isolation and preservation of archived 3D prototype in `..\exp-1` without importing or altering any legacy files.
- Established strict save-data verification protocols and input clamping standards.\n