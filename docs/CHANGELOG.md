# CHANGELOG

All notable changes to **ShadowCraft 2D** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Kai Phase 02 movement polish

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
- Established strict save-data verification protocols and input clamping standards.
