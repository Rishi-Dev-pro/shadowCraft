# PHASE 03 SPECIFICATION — CORE 2D COMBAT ENGINE

**Phase status:** In progress; Combat 1 foundation is the only completed milestone.
**Engine:** Godot 4.7.2, Compatibility renderer
**Authority:** User-approved Combat 1 milestone on 2026-11-10.

## Phase Objective

Build a reusable 2D combat foundation that connects data-defined attacks to spatial hit/hurt areas, damage, health, reaction, and animation while keeping locomotion and presentation responsibilities separate.

## Combat 1 Scope

- Typed `AttackData` resources, damage calculation, health component, hitbox/hurtbox collision filtering, combat phase state machine, knockback and hitstun.
- Integrate the foundation with Kai V2 while preserving existing movement and animation behavior outside attacks.
- Add original, distinct Light Jab and Front Kick animations, one training dummy, and a dedicated Combat Test Arena.
- Verify the arena in Godot and run Combat 1 plus Phase 01/02 regression tests.

## Acceptance Criteria

- Attacks use configured startup, active and recovery frames. Only active windows can register damage, and each target is hit at most once per window.
- Player and enemy hit/hurtbox layers only interact through their intended physics masks.
- Valid damage updates health, applies directional knockback and enters hitstun. Invalid attack states (airborne, crouched, or busy) reject initiation.
- Jab and kick have distinct original sprite clips, correct playback alignment, and different data values.
- The dedicated arena runs in the actual Godot 4.7.2 renderer. Phase 01/02 test suites continue to pass.
- Pass 1 and Pass 2 are documented. Any following Combat milestone waits for explicit user approval.

## Explicitly Deferred

Combo buffers/chains, blocking, dodging, backstep, parry, poise, knockdown/recovery, aerial/sweep attacks, additional basic attacks, shadow specials, finishers, enemy AI, weapons, and later roadmap phases.
