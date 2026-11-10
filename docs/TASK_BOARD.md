# SHADOWCRAFT 2D — PROJECT TASK BOARD

> **Sprint:** Phase 02 Completed — Gated for Phase 03 Authorization  
> **Status View:** Active Tasks, Done Column, Backlog  
> **Rule:** No task outside the authorized phase may be moved to "In Progress" without user sign-off.

---

## 1. COMPLETED TASKS (PHASE 00)

- [x] **TASK-001**: Inspect workspace and confirm new project boundary (`d:\projects 2.0\games\shadowCraft`).
- [x] **TASK-002**: Confirm preservation of archived 3D prototype in `..\exp-1` without touching legacy files.
- [x] **TASK-003**: Initialize Git repository on `main` branch with Git LFS filter support.
- [x] **TASK-004**: Create `.gitignore` tailored for Godot 4, GDScript, and GdUnit4.
- [x] **TASK-005**: Create `.gitattributes` to normalize line endings (`LF`) and identify binary media assets.
- [x] **TASK-006**: Configure `project.godot` for Godot 4.x with Compatibility renderer (`gl_compatibility`), 1280x720 baseline resolution, and 2D physics layers 1-7.
- [x] **TASK-007**: Create directory structure with `.gitkeep` for assets, scenes, scripts, resources, tests, and docs.
- [x] **TASK-008**: Author comprehensive root `AGENTS.md` containing the 22 mandatory operational rules.
- [x] **TASK-009**: Author `docs/PROJECT_CONSTITUTION.md` as the permanent source of truth.
- [x] **TASK-010**: Author `docs/ARCHITECTURE.md` with complete component diagrams and Mermaid workflows.
- [x] **TASK-011**: Author Architecture Decision Records (ADR-0001 through ADR-0011).
- [x] **TASK-012**: Author supporting technical guidelines: `TECH_STACK.md`, `ASSET_GUIDELINES.md`, `ANIMATION_GUIDELINES.md`, `COMBAT_DESIGN.md`, `WEAPON_SYSTEM.md`, `TESTING_STRATEGY.md`, `PERFORMANCE_GUIDELINES.md`, `SECURITY_GUIDELINES.md`, `GIT_WORKFLOW.md`.
- [x] **TASK-013**: Author Phase 00 phase records: `SPECIFICATION.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, `COMPLETION_REPORT.md`.
- [x] **TASK-014**: Setup GitHub Actions continuous integration workflow (`.github/workflows/ci.yml`).
- [x] **TASK-015**: Execute Two-Pass Audit (Pass 1: Architecture & Consistency; Pass 2: Quality & Completeness).
- [x] **TASK-016**: Create initial Git commit with Conventional Commit messaging.
- [x] **TASK-017**: Phase 00 completion report delivered and sign-off granted by user.

---

## 2. COMPLETED TASKS (PHASE 01: KAI CHARACTER PIPELINE)

- [x] **TASK-101**: Establish Kai visual reference sheet (`kai_concept_art.png`) with purple theme, silhouette anatomy, ninja mask, and chest emblem.
- [x] **TASK-102**: Generate/author transparent 32-bit PNG limb sprites for Kai with rounded joint sockets and transparent margins (Head, Torso, Arms, Hands, Legs, Feet, Emblem).
- [x] **TASK-103**: Create `CharacterData.gd` resource script and `resources/characters/kai.tres` with identity attributes.
- [x] **TASK-104**: Build `scenes/characters/Kai.tscn` with `Skeleton2D` and `Bone2D` hierarchical rig and `Socket_Weapon` Marker2D.
- [x] **TASK-105**: Author 4 required locomotion cycles in `AnimationPlayer` (`loco/idle`, `loco/walk_fwd`, `loco/walk_bwd`, `loco/crouch`).
- [x] **TASK-106**: Build `scenes/arenas/KaiPreview.tscn` and capture genuine Godot screenshots for Visual Quality Gate.
- [x] **TASK-107**: Execute automated structural validation tests (`tests/unit/test_kai_hierarchy.gd`) with 100% pass rate (44/44 assertions).
- [x] **TASK-108**: Execute Pass 1 and Pass 2 audits, update documentation, and produce Phase 01 Completion Report.

---

## 3. COMPLETED TASKS (PHASE 02: PLAYER MOVEMENT & CONTROLS)

- [x] **TASK-201**: Configure standard fighting game Input Map in `project.godot` (`move_forward`, `move_backward`, `move_left`, `move_right`, `jump`, `crouch`).
- [x] **TASK-202**: Author `scripts/characters/CharacterController2D.gd` with 6-state kinematics FSM, velocity integration, gravity, friction, and landing logic.
- [x] **TASK-203**: Implement dynamic collision height adjustment in `Kai.tscn` (standing 320px vs crouch 200px) with ground base anchor at Y=0.
- [x] **TASK-204**: Implement jump lockout rules while crouching.
- [x] **TASK-205**: Implement opponent-facing orientation logic via visual `Skeleton2D.scale.x` flipping while preserving unscaled root `CharacterBody2D`.
- [x] **TASK-206**: Connect animation playback cleanly to locomotion cycles (`loco/idle`, `walk_fwd`, `walk_bwd`, `crouch`) with airborne freeze safety.
- [x] **TASK-207**: Build `scenes/arenas/MovementTestArena.tscn` and `scripts/arenas/MovementTestArenaController.gd` with live telemetry HUD and boundary walls.
- [x] **TASK-208**: Author automated unit test suite `tests/unit/test_player_movement.gd` and achieve 100% pass rate (55/55 assertions passed).
- [x] **TASK-209**: Execute Phase 01 regression suite `tests/unit/test_kai_hierarchy.gd` (44/44 assertions passed).
- [x] **TASK-210**: Capture and verify in-engine screenshots for Visual Quality Gate.
- [x] **TASK-211**: Execute Pass 1 and Pass 2 audits, update project documentation, and author Phase 02 Completion Report.

### Authorized Phase 02 Integration Follow-up (2026-11-10)

- [x] **TASK-212**: Build independent Kai V2 playable scene from the verified 60-frame import set and preserve Kai V1 as `KaiLegacy.tscn`.
- [x] **TASK-213**: Connect eight frame animations to the existing movement controller, add opt-in run/crouch-walk behavior and Shift run input, and make Kai V2 the Movement Test Arena character.
- [x] **TASK-214**: Validate 95 Kai V2 assertions plus Phase 01/02 regression suites (44/44 and 63/63); capture and inspect the actual Godot 4.7.2 Compatibility-renderer game.
- [x] **TASK-215**: Perform architecture/integration and quality/regression audits; update Roadmap, Changelog, Task Board, and NEXT_SESSION. Phase 03 remains gated.

---

## 4. COMPLETED TASKS (PHASE 03: COMBAT 1 FOUNDATION — 2026-11-10)

- [x] **TASK-301**: Implement data-bound `Hitbox2D` with frame-window activation, collision filtering and once-per-target hit handling.
- [x] **TASK-302**: Implement player and dummy `Hurtbox2D` receiver paths on the existing physics layers 4-7.
- [x] **TASK-303**: Add `HealthComponent` and bounded damage calculation; apply knockback, timed hitstun and a short hit flash.
- [x] **TASK-304**: Add a typed combat state machine and `AttackData` resources for Light Jab and Front Kick with separate startup, active and recovery frames.
- [x] **TASK-305**: Add the original six-frame jab/kick animation atlases and integrate them into Kai V2's existing `SpriteFrames` resource.
- [x] **TASK-306**: Build the isolated `CombatTestArena` with playable Kai V2, a training dummy, health bars, state telemetry and opt-in hitbox drawing.
- [x] **TASK-307**: Verify 35/35 Combat 1 assertions, Kai V2 (95/95), Phase 02 movement (63/63), Phase 01 hierarchy (44/44), and inspect the actual Godot Movie Maker recording and screenshots.
- [x] **TASK-308**: Complete Combat 1 architecture and quality audits; document the remaining Phase 03 scope and handoff.
- [x] **TASK-309**: Align jab and kick active phases with their contact poses; add per-active-frame limb-matched hitbox offsets and regression coverage.
- [x] **TASK-310**: Add confirmed-hit-only hit-stop, restrained punch/kick sparks, and a short eased dummy recoil.
- [x] **TASK-311**: Capture actual normal, slow-motion, and active-hitbox footage; run all 52 Combat and 202 movement/hierarchy regression assertions; complete both audits.
- [x] **TASK-312**: Trace the F5 scene and verify Kai V2's jab/kick clips remain wired in the movement scene while its opponent marker has no hurtbox or hit-feedback owner.
- [x] **TASK-313**: Preserve the F5 movement arena, add an explicit combat-arena launcher, verify the combat scene's hit feedback, and capture normal-speed gameplay from that scene.
- [x] **TASK-314**: Remove the launcher wait-on-error, broaden Godot discovery, and verify its scene target and non-blocking missing-engine behavior.
- [x] **TASK-315**: Integrate the existing Combat 1 dummy and feedback into the main playable arena and make `run_shadowcraft.bat` the verified, logged unified launcher.

---

## 5. IN PROGRESS / NEXT GATE

### Authorized Razen Character Production — Complete (2026-11-10)

- [x] Produce original animation sheets and 56 aligned frames for idle, forward/backward walk, run, crouch, crouch walk, jump, landing and attack presentation; preserve the approved signature artwork.
- [x] Add Razen CharacterData, independent playable scene, shared-controller animation adapter, SpriteFrames builder, provenance, rendered preview and focused regression coverage.
- [x] Validate Godot resource loads and inspect Compatibility-rendered clips. This is not Phase 08 boss work; wait for user visual approval before extending Razen.

The Combat 1.1 runtime launch repair is complete and awaits visual verification. `MovementTestArena.tscn` remains the F5 main scene; run `run_combat.bat` to play the damageable dummy arena. Do not begin the Combo Engine or another Combat milestone until explicitly authorized.

### Remaining Phase 03 work (not authorized yet)
- [ ] Combo input buffer and chain windows.
- [ ] Blocking, dodge and backstep.
- [ ] Additional attacks, air/sweep moves, shadow specials and finishers.
- [ ] Complete remaining defense, combo and special-move tests.

### Later phases remain gated
- Phase 04 weapon framework, Phase 05 complete defense/combos, and subsequent roadmap phases remain planned and untouched.
