# SHADOWCRAFT 2D — PROJECT TASK BOARD

> **Sprint:** Phase 00 Completion & Foundation Gate  
> **Status View:** Active Tasks, Done Column, Backlog  
> **Rule:** No task outside the authorized phase may be moved to "In Progress" without user sign-off.

---

## 1. COMPLETED TASKS (PHASE 00)

- [x] **TASK-001**: Inspect workspace and confirm new project boundary (`d:\projects 2.0\games\shadowCraft`).
- [x] **TASK-002**: Confirm preservation of archived 3D prototype in `..\exp-1` without touching or importing legacy files.
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

---

## 2. IN PROGRESS (PHASE 00 CLOSEOUT)

- [ ] **TASK-017**: Present Phase 00 completion summary and audit findings to the user for formal sign-off.

---

## 3. BACKLOG (BLOCKED — PENDING PHASE 01 AUTHORIZATION)

### Phase 01: Kai 2D Character Art & Animation Pipeline
- [ ] **TASK-101**: Establish Kai visual reference sheet (purple theme, silhouette anatomy, headband).
- [ ] **TASK-102**: Generate/create 2D transparent PNG limb sprites for Kai (head, torso, limbs, clothing).
- [ ] **TASK-103**: Build `Kai.tscn` with `Skeleton2D` and `Bone2D` hierarchical rig.
- [ ] **TASK-104**: Attach `Marker2D` weapon socket to right hand bone.
- [ ] **TASK-105**: Animate neutral locomotion cycles (`idle`, `walk_fwd`, `walk_bwd`, `crouch`).
- [ ] **TASK-106**: Validate 60 FPS animation playback in Godot 2D editor.

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
