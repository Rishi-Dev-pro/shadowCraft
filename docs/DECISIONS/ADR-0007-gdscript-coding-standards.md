# ADR-0007: GDScript Coding Standards

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
Dynamically typed scripting languages can lead to subtle runtime crashes, difficult debugging, lack of autocomplete, and slower execution speeds. Godot 4 features a vastly improved GDScript 2.0 with static typing, static analysis, and performance optimizations.

## Decision
We enforce **strict static typing and modular GDScript conventions** across all code:
1. All variables, constants, parameters, and function return values must specify explicit types:
   ```gdscript
   var current_health: float = 100.0
   func take_damage(amount: float, source: Node2D) -> bool:
   ```
2. Untyped declarations (`var x = ...` without explicit `: Type`) are prohibited.
3. Core components register explicit `class_name` identifiers (`CharacterController2D`, `CombatController`, `AttackData`).
4. Signals must define typed parameters:
   ```gdscript
   signal health_updated(new_health: float, max_health: float)
   ```
5. Warnings are treated as errors where practical; circular dependencies are prevented by decoupling through signals and custom resources.

## Alternatives Considered
- **C# (.NET):** Adds external runtime requirements (.NET SDK/Mono), larger build binaries, and slower export pipelines.
- **Untyped GDScript:** Fast to write initially, but catastrophic for medium-to-large projects with refactoring and type safety risks.

## Consequences
- **Positive:** Catch bugs at parse time before running, superior IDE auto-completion, approximately 20-30% faster execution in Godot 4's VM, clean self-documenting code.
- **Negative:** Slightly more verbose syntax upfront.
