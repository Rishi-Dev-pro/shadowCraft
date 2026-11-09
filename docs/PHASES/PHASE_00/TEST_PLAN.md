# PHASE 00 TEST PLAN: VERIFICATION OF FOUNDATION INTEGRITY

> **Phase Identifier:** PHASE-00  
> **Status:** APPROVED & TESTED  
> **Source of Truth:** `docs/PHASES/PHASE_00/SPECIFICATION.md`

---

## 1. OBJECTIVE

The Phase 00 Test Plan validates the structural, configuration, governance, and architectural integrity of the newly established repository. Because no gameplay code is implemented during Phase 00, verification focuses on:
- File system and directory compliance.
- Engine configuration validity (`project.godot`).
- Documentation cross-referencing and markdown integrity.
- Preservation of the archived 3D prototype.
- Git repository health and clean commit staging.

---

## 2. TEST CASES & EXECUTION MATRIX

| Test ID | Test Category | Description / Command | Pass Criteria | Status |
|---|---|---|---|---|
| **TC-001** | Workspace Boundary | Check working directory location | Must be `d:\projects 2.0\games\shadowCraft` | PASS |
| **TC-002** | 3D Archive Preservation | Check `..\exp-1` status and git status | Zero modifications to `..\exp-1` files | PASS |
| **TC-003** | Engine Configuration | Parse `project.godot` via Godot 4 headless | Parses with zero syntax errors | PASS |
| **TC-004** | 2D Mandate Check | Grep workspace for prohibited 3D nodes | Zero occurrences of CharacterBody3D, MeshInstance3D | PASS |
| **TC-005** | Directory Structure | Verify all standard directories exist | `assets/`, `scenes/`, `scripts/`, `resources/`, `tests/`, `docs/` exist | PASS |
| **TC-006** | AGENTS.md Compliance | Verify presence of all 22 mandatory rules | All 22 rules numbered and present | PASS |
| **TC-007** | ADR Completeness | Check `docs/DECISIONS/` for ADR-0001 through ADR-0011 | Exactly 11 ADRs present with standard structure | PASS |
| **TC-008** | Documentation Suite | Verify all specified technical documents exist | All 16 docs exist with non-empty content | PASS |
| **TC-009** | CI Configuration | Validate `.github/workflows/ci.yml` syntax | Valid YAML format with headless test execution | PASS |
| **TC-010** | Git Status | Inspect `git status` before commit | All files tracked, no unwanted artifacts | PASS |

---

## 3. VERIFICATION PROCEDURES

### TC-003: Engine Configuration Parsing
Execute Godot in headless mode pointing to the project:
```powershell
cmd.exe /c "..\exp-1\tools\bin\godot\Godot_v4.7.2-stable_win64.exe --headless --path . --quit"
```
*Expected Result:* Godot loads the project settings without syntax or parse failures.

### TC-004: Prohibited 3D Nodes Search
Run a recursive search across the workspace for 3D node references:
```powershell
Get-ChildItem -Recurse -Include *.gd,*.tscn,*.tres | Select-String "CharacterBody3D", "MeshInstance3D"
```
*Expected Result:* Zero matches found.

