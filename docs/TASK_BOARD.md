# SHADOWCRAFT 2D — PROJECT TASK BOARD

> **Sprint:** Phase 01 Completed — Gated for Phase 02 Authorization  
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

## 3. IN PROGRESS

*None. Strictly stopped at Phase 01 completion gate awaiting user sign-off.*

---

## 4. BACKLOG (BLOCKED — PENDING PHASE 02 AUTHORIZATION)

### Phase 02: Player Movement & Controls
- [ ] **TASK-201**: Implement `CharacterController2D` script with velocity integration and gravity.
- [ ] **TASK-202**: Implement `CharacterStateMachine` and basic locomotion states.
- [ ] **TASK-203**: Implement automatic opponent-facing logic.
- [ ] **TASK-204**: Implement input buffer for responsive martial commands.

### Phase 03: Core 2D Combat Engine
- [ ] **TASK-301**: Implement `Hitbox2D` (Area2D) with attack data binding.
- [ ] **TASK-302**: Implement `Hurtbox2D` (Area2D) with body part vulnerability zones.
- [ ] **TASK-303**: Implement `HealthComponent` and poise depletion logic.
- [ ] **TASK-304**: Build unit tests for damage and poise calculation.
