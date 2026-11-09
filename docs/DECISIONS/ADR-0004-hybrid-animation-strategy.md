# ADR-0004: Hybrid Animation Strategy

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
In 2D fighting games, animation defines both visual quality and gameplay responsiveness.
- Pure skeletal cutout animation can look "paper doll" or rubbery during fast martial arts strikes, lacking the smear frames, foreshortening, and impact distortion required for authentic martial combat.
- Pure frame-by-frame sprite animation requires massive texture memory for every single walk cycle, breathing loop, and guard transition, creating high production overhead and memory consumption.

## Decision
We adopt a **Hybrid Animation Strategy**:

1. **Skeletal 2D Animation (`Skeleton2D` + `Bone2D`):**
   - Applied to neutral locomotion: `idle`, `walk_fwd`, `walk_bwd`, `crouch_enter`, `crouch_loop`, `guard_up`.
   - Enables continuous, buttery smooth procedural transitions, breathing cycles, and seamless attachment of weapons to hand bone sockets.
2. **Frame-by-Frame Sprite Animation (`AnimationPlayer` with texture track keying):**
   - Applied to high-impact combat actions: weapon swings, heavy stabs, parry deflections, knockdowns, and hit reactions.
   - Provides exaggerated martial smears, punchy frame-holds, and zero-interpolation snap on impact.

## Alternatives Considered
- **Pure Skeletal (Cutout only):** Resulted in lack of martial weight and unnatural limb stretching during rapid sword arcs.
- **Pure Frame-by-Frame Sprites:** Excessive VRAM usage and enormous sprite-drawing burden for minor transitional states.

## Consequences
- **Positive:** Combines the visual punch and martial weight of classic 2D fighters with the smooth locomotion and low asset overhead of skeletal rigs.
- **Negative:** Requires careful coordination between bone transforms and sprite visibility tracks within `AnimationPlayer`.

