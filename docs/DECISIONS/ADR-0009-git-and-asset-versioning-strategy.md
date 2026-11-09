# ADR-0009: Git and Asset Versioning Strategy

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
Game repositories frequently bloat into unmanageable gigabytes due to uncompressed binary textures, audio files, and PSD/project source assets. ShadowCraft 2D must maintain a fast, clean, reproducible Git repository.

## Decision
We establish a standardized Git and asset versioning strategy:
1. **Branching Model:** Trunk-based development centered on `main`. Each feature or phase is validated before merging/committing.
2. **Conventional Commits:** Commit messages must strictly follow the Conventional Commits specification:
   - `feat:` new game mechanics, components, or screens.
   - `fix:` bug fixes and balancing corrections.
   - `docs:` documentation, ADRs, phase reports.
   - `test:` test suites and verification scripts.
   - `refactor:` code restructuring without behavioral change.
   - `chore:` build, CI, project configuration changes.
3. **Asset Handling:**
   - Production assets committed to Git must be optimized PNGs and compressed audio (OGG/WAV).
   - `.gitattributes` enforces standard line endings (`LF`) across all text, `.gd`, `.tscn`, and `.tres` files.
   - Git LFS (Large File Storage) is configured for large binaries if needed.
4. **Old Project Isolation:**
   - The archived project in `exp-1` is frozen. No files or Git history from `exp-1` shall be ported into the new repository.

## Alternatives Considered
- **Direct binary commits without normalization:** Causes Git repository bloat and merge conflicts across platforms due to CRLF vs LF.
- **Git submodules for old project:** Unnecessary coupling with a dead prototype.

## Consequences
- **Positive:** Clean history, small repo clone size, reproducible CI checkouts, clear attribution of work per phase.
- **Negative:** Requires contributors to follow commit formatting rules.
