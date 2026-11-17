# SHADOWCRAFT 2D — AGENT GOVERNANCE & OPERATIONAL DIRECTIVES

> **Target Engine:** Godot 4 (Compatibility Renderer)  
> **Architecture:** 2D-only Modular Component & Data-Driven Resource System  
> **Current Version:** Phase 00 (Project Foundation)  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md` and `docs/ARCHITECTURE.md`

This document defines the mandatory operating protocols, coding standards, and governance rules for every AI coding agent and automated developer working on **ShadowCraft 2D**. Compliance with this document is non-negotiable.

---

## 1. THE 22 CORE AGENT RULES

Every agent interacting with this repository MUST strictly abide by these 22 rules:

1. **Read `AGENTS.md` before modifying any file.** Understand your role, operational limits, and current phase context before editing code or documentation.
2. **Read relevant architecture and phase documents before implementation.** Always review `docs/ARCHITECTURE.md`, `docs/PROJECT_CONSTITUTION.md`, and the active phase specification before touching scripts or scenes.
3. **Respect the approved project scope.** Never implement features or systems not explicitly defined in the active phase specification.
4. **Never start a future phase without explicit user authorization.** Complete the active phase, deliver the completion report, and wait for human sign-off.
5. **Never silently redesign approved game mechanics or visual identity.** Any change to established mechanics, combat math, or visual styles requires explicit user approval.
6. **Inspect existing code before creating or replacing systems.** Check the existing scripts, scenes, and resources to prevent redundant implementations.
7. **Avoid duplicate systems and unnecessary dependencies.** Favor Godot 4 native 2D features and standard library patterns over external plugins or custom wrappers.
8. **Use typed, modular, maintainable GDScript.** All scripts must use GDScript 2.0 static typing (`var x: int = 0`, `func foo() -> void:`). No untyped dynamic variables without explicit justification.
9. **Keep game logic separate from presentation.** Decouple combat calculations and state logic from visual animations, particle effects, and audio triggers. Use signals for cross-boundary communication.
10. **Use reusable Resources for configurable weapons, attacks and character data.** Define data structures via custom `Resource` scripts (`AttackData`, `WeaponData`, `CharacterData`) rather than hardcoding stats in nodes.
11. **Validate user input, resource data and save data.** Clamp ranges, verify bounds, check schema integrity, and never trust raw unvalidated external state.
12. **Never hardcode secrets or credentials.** Keep development keys, tokens, or private configuration strictly out of the repository.
13. **Never claim tests passed without executing them.** Automated tests must be executed and their output verified before reporting success.
14. **Never claim visual verification based only on headless tests.** Headless runs confirm logic, not rendering, aesthetics, animation sync, or screen alignment. Distinguish between headless verification and visual testing.
15. **Never claim performance without measurements.** Provide actual frame time, FPS, draw calls, or memory metrics when asserting performance benchmarks.
16. **Record meaningful changes in project documentation.** Update `docs/CHANGELOG.md` and relevant phase logs upon completing significant components or bug fixes.
17. **Update `docs/NEXT_SESSION.md` after every completed milestone.** Clearly document the current state, active blockers, and the next immediate tasks.
18. **Perform two complete codebase audits after each implementation phase.** Execute Pass 1 (Architecture & Consistency) and Pass 2 (Quality & Completeness) before requesting phase closure.
19. **Run regression tests after meaningful changes.** Verify that new modifications do not break previously established combat, movement, or data pipelines.
20. **Commit and push each completed change.** Stage only the files in scope and use a descriptive Conventional Commit (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`). Push to the current branch's upstream after verification, unless the user gives different instructions for that change.
21. **Keep the working tree clean after a completed phase.** Remove temporary debug files, orphaned scratch scripts, and unneeded assets before committing.
22. **Stop and report blockers instead of inventing solutions.** If an architectural conflict, missing asset, or engine incompatibility arises, halt execution and report it clearly to the user.

---

## 2. GOVERNANCE & AUTHORITY MODEL

- **The User is the Supreme Authority:** The user has sole authority over design sign-offs, phase transitions, scope adjustments, and art direction.
- **Phase Gating Protocol:** Work proceeds strictly phase-by-phase according to `docs/ROADMAP.md`. Under no circumstances may an agent jump ahead to subsequent phases (e.g., jumping from Phase 00 to Phase 01 character art, or Phase 02 movement to Phase 03 combat).
- **Strict 2D Enforcement:** Any introduction of 3D nodes (`CharacterBody3D`, `MeshInstance3D`, `Camera3D`), 3D physics, or 2.5D rendering is an immediate rule violation. ShadowCraft 2D is native 2D throughout.
- **Old Project Isolation:** The legacy project in `d:\projects 2.0\games\exp-1` is archived and permanently frozen. It must never be edited, moved, renamed, imported, or deleted.

---

## 3. FILE SYSTEM & CODE ORGANIZATION

All agents must adhere to the standardized directory layout:

- `assets/`: Raw and imported media (audio, textures, sprites, UI elements, fonts).
- `scenes/`: Packed scenes (`.tscn`), divided strictly by domain (`characters/`, `combat/`, `weapons/`, `arenas/`, `ui/`).
- `scripts/`: GDScript source code (`.gd`), mirroring domain divisions (`characters/`, `combat/`, `weapons/`, `enemies/`, `progression/`, `systems/`).
- `resources/`: Custom Resource files (`.tres`), defining data-driven stats (`characters/`, `attacks/`, `weapons/`).
- `tests/`: Automated test suites (`unit/`, `integration/`) executed via GdUnit4.
- `docs/`: Technical specifications, architecture records, guidelines, and phase logs.

Never create empty placeholder scripts without implementation. Use `.gitkeep` for required directories.

---

## 4. CODING STANDARDS SUMMARY

- **GDScript 2.0 Static Typing:** Explicit return types and parameter types for all functions.
- **Naming Conventions:**
  - Files & Directories: `snake_case` (e.g., `character_controller_2d.gd`, `wooden_sword.tres`).
  - Class Names & Types: `PascalCase` (e.g., `CharacterController2D`, `AttackData`).
  - Functions & Variables: `snake_case` (e.g., `calculate_damage()`, `current_health`).
  - Constants & Enums: `SCREAMING_SNAKE_CASE` (e.g., `MAX_HEALTH`, `WeaponCategory.SWORD`).
  - Private Members: Prefixed with `_` (e.g., `_velocity`, `_update_state()`).
  - Signals: Past-tense or state-transition verbs in `snake_case` (e.g., `health_changed`, `attack_landed`, `state_entered`).
- **Node Referencing:** Favor `@onready` with unique scene names or typed node paths. Validate node existence with assertions in `_ready()` if critical.

---

## 5. AUDITING AND VERIFICATION PROTOCOL

At the conclusion of each development phase, the agent must perform and document a two-pass audit:

### Pass 1: Architecture & Consistency
- Verify adherence to 2D-only technical constraints.
- Verify compatibility of all scene structures, script interfaces, and data resources.
- Validate that the Roadmap, Task Board, and Phase Implementation Plans are strictly aligned.
- Confirm zero presence of 3D nodes or legacy migration artifacts.

### Pass 2: Quality & Completeness
- Re-read all newly modified and created code and documentation.
- Execute the test suite and verify 100% pass rate.
- Check security, bounds validation, and input sanitization.
- Verify Git working tree cleanliness and write the Phase Completion Report.

---

*Every agent must review this document at the start of any conversation turn that modifies project code or architecture.*

