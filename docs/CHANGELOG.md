# CHANGELOG

All notable changes to **ShadowCraft 2D** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
