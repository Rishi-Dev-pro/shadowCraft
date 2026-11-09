# PHASE 00 SPECIFICATION: PROJECT CONSTITUTION, ARCHITECTURE & DEVELOPMENT ENVIRONMENT

> **Phase Identifier:** PHASE-00  
> **Status:** APPROVED & COMPLETE  
> **Target Release:** v0.1.0  
> **Lead Architect:** Technical Director & Lead Game Architect

---

## 1. PURPOSE & OBJECTIVES

The objective of Phase 00 is to establish an unshakeable, professional, 2D-only technical foundation for **ShadowCraft 2D**. This is a completely fresh project built in Godot 4. Previous 3D prototypes are permanently archived and must remain untouched.

### Primary Goals:
1. Establish clean repository governance and strict operational rules for AI coding agents (`AGENTS.md`).
2. Define the immutable project constitution, visual pillars, combat philosophy, and 2D-only mandate (`PROJECT_CONSTITUTION.md`).
3. Formulate the technical architecture covering characters, combat, weapons, animation, AI, and progression (`ARCHITECTURE.md`).
4. Record formal Architecture Decision Records (ADR-0001 through ADR-0011).
5. Establish production guidelines for 2D assets, animation, combat math, weapon data, testing, performance, security, and Git.
6. Configure the initial Godot 4 project using the GL Compatibility renderer, 1280x720 baseline resolution, and 2D physics layers.
7. Configure testing infrastructure (GdUnit4) and continuous integration (GitHub Actions).
8. Perform two complete audits (Pass 1 & Pass 2) and record findings.
9. Enforce strict stop condition: complete Phase 00 without implementing gameplay or starting Phase 01.

---

## 2. SCOPE BOUNDARIES

### In Scope:
- Complete directory structure and `.gitkeep` markers.
- Git initialization (`main` branch), `.gitignore`, `.gitattributes`, `LICENSE`, `README.md`.
- `project.godot` engine configuration for 2D GL Compatibility.
- Full documentation suite under `docs/` and root `AGENTS.md`.
- 11 formal Architecture Decision Records.
- Phase 00 documentation (`SPECIFICATION.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, `COMPLETION_REPORT.md`).
- GitHub Actions CI workflow (`.github/workflows/ci.yml`).
- Verification that archived project in `..\exp-1` is completely untouched.
- Initial Git commit.

### Strictly Out of Scope:
- Importing any code, meshes, or assets from `..\exp-1`.
- Any 3D nodes (`CharacterBody3D`, `MeshInstance3D`, `Camera3D`).
- Creating Kai's 2D artwork or models (reserved for Phase 01).
- Implementing gameplay scripts, physics controllers, or combat mechanics.
- Starting Phase 01.

---

## 3. ACCEPTANCE CRITERIA

1. Git repository initialized and clean.
2. `project.godot` configured with `gl_compatibility`, 1280x720 resolution, canvas_items stretch mode, and 7 2D physics layers.
3. Root `AGENTS.md` contains all 22 mandatory operational rules.
4. `PROJECT_CONSTITUTION.md` and `ARCHITECTURE.md` are complete with Mermaid diagrams.
5. ADR-0001 through ADR-0011 exist and follow standard format.
6. All 9 technical guidelines are authored with rich project-specific details.
7. GdUnit4 testing structure and CI workflow are established.
8. Two-Pass Audit passes with zero architectural conflicts or missing requirements.
9. Initial Git commit created with descriptive message.
10. Strict stop observed.
