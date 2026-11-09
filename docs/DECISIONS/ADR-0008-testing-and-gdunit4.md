# ADR-0008: Testing and GdUnit4

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
A fighting game relies heavily on exact mathematics: damage calculations, frame timings, input buffering, poise reduction, knockback vectors, and state transitions. Manual playtesting alone cannot catch edge cases or regression bugs introduced during weapon additions. Automated testing is essential.

## Decision
We adopt **GdUnit4** as the standard testing framework for ShadowCraft 2D:
1. **Unit Tests (`tests/unit/`):**
   - Damage calculation formulas.
   - Resource integrity checks (verifying `WeaponData` and `AttackData` ranges).
   - Input buffering logic and state machine transition rules.
   - Save file serialization, schema validation, and checksum checks.
2. **Integration Tests (`tests/integration/`):**
   - Simulated combat exchanges (spawning attacker and defender headlessly, dispatching an attack, asserting health reduction and state updates).
3. **Headless CLI Execution:**
   - Tests execute via Godot's `--headless` CLI runner, making them fully compatible with GitHub Actions CI.
4. **Honesty Rule:** Headless unit tests verify math and logic; visual appeal, animation smoothness, and tactile control feel require explicit on-screen testing and cannot be declared verified by headless runs alone.

## Alternatives Considered
- **GUT (Godot Unit Test):** Popular alternative, but GdUnit4 provides superior Godot 4 fluent assertions, CI CLI integration, and asynchronous runner support.
- **Manual QA Only:** Unacceptable for a multi-phase technical architecture.

## Consequences
- **Positive:** Automated regression protection, confidence during refactoring, quick test cycles (< 5 seconds for full suite).
- **Negative:** Requires disciplined test authoring for each new component created.
