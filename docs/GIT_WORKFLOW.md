# SHADOWCRAFT 2D — GIT WORKFLOW & VERSION CONTROL POLICY

> **Status:** APPROVED VERSION CONTROL STANDARD  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md` and `docs/DECISIONS/ADR-0009-git-and-asset-versioning-strategy.md`

---

## 1. REPOSITORY STRUCTURE & BRANCHING MODEL

- **Primary Branch:** `main` (trunk-based development for disciplined phases).
- **Phase Tags:** Every completed phase is tagged on `main` upon approval:
  - `v0.0.0` (Initial Phase 00 Foundation)
  - `v0.1.0` (Phase 01 Completion)
  - `v0.2.0` (Phase 02 Completion)
  - ... through `v1.0.0` (Release)

---

## 2. COMMIT CONVENTIONS (CONVENTIONAL COMMITS)

Every commit message must follow the Conventional Commits 1.0.0 format:

```text
<type>(<scope>): <short description>

[optional body explaining rationale and consequences]

[optional footer referencing tasks or breaking changes]
```

### Approved Types
- `feat`: A new gameplay feature, component, screen, or weapon.
- `fix`: A bug fix, mathematical balance adjustment, or collision correction.
- `docs`: Documentation updates, ADRs, phase specifications, or roadmap syncs.
- `test`: Adding or refactoring automated tests.
- `refactor`: Code restructuring without behavioral change.
- `perf`: Optimizations that reduce draw calls, frame time, or memory.
- `chore`: Engine config, `.gitignore`, build scripts, or repo governance updates.

### Examples
- `feat(combat): implement 4-frame parry deflection window`
- `fix(damage): prevent negative damage values against high armor`
- `docs(phase-00): complete foundation specification and ADR records`
- `chore(engine): configure GL compatibility renderer and 720p viewport`

---

## 3. ASSET VERSIONING & GIT LFS

- Binary media files (large PNG sprite sheets, WAV audio, OGG tracks) are tracked via Git LFS filters defined in `.gitattributes`.
- Never commit raw uncompressed video files, PSD working layers, or temporary Godot editor imports (`.godot/` is strictly ignored).

---

## 4. PRE-COMMIT CHECKLIST (PHASE GATING)

Before creating a commit closing any phase:
1. All automated tests in `tests/` pass with zero failures.
2. The working tree is clean: no untracked `.tmp`, `.log`, or scratch scripts.
3. Pass 1 Audit (Architecture & Consistency) is executed and documented.
4. Pass 2 Audit (Quality & Completeness) is executed and documented.
5. `docs/CHANGELOG.md` and `docs/NEXT_SESSION.md` are updated.
6. The legacy 3D project in `..\exp-1` is verified untouched.
