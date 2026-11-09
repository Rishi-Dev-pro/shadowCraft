# ADR-0006: Combat Architecture

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
A responsive, high-precision fighting game requires deterministic, frame-discrete hit registration, directional blocking, precise parry windows, and clear feedback loops without bogging down physics simulation.

## Decision
We implement a discrete component combat pipeline:
1. **Collision Triggers:** Native `Area2D` nodes segregated into dedicated physics collision layers:
   - Layer 4: Player Hitbox
   - Layer 5: Enemy Hitbox
   - Layer 6: Player Hurtbox
   - Layer 7: Enemy Hurtbox
2. **Phase Separation:**
   - Startup, Active, Recovery states enforced by `CharacterStateMachine` and `CombatController`.
   - Hitboxes are enabled strictly on active frame milestones and disabled during recovery.
3. **Defensive Mechanics:**
   - Walking away from opponent automatically engages high guard.
   - Crouching guard protects lower hurtbox.
   - 4-frame parry window deflects incoming strikes and inflicts attacker recoil.
4. **Decoupled Combat Signals:**
   - Signals communicate combat outcomes: `hit_landed`, `parry_triggered`, `block_mitigated`, `health_changed`.
   - Audio and particle effects listen to signals, keeping core combat mathematics clean and testable.

## Alternatives Considered
- **Raycast-based Combat:** Fast for bullets, but fails to model wide weapon arcs, swinging axes, or sweeping spears.
- **Physics Velocity / Impulse Collision:** Unpredictable bouncing and non-deterministic behavior unsuitable for precise fighting game frame data.

## Consequences
- **Positive:** Deterministic, easily tunable via frame data in `AttackData`, fully testable via unit and integration tests without visual scenes running.
- **Negative:** Requires disciplined synchronization between visual animation keyframes and active collision shape toggles.

