# PHASE 02 IMPLEMENTATION PLAN: PLAYER MOVEMENT & CONTROLS

> **Phase Identifier:** PHASE-02  
> **Status:** ACTIVE  
> **Source of Truth:** `docs/PHASES/PHASE_02/SPECIFICATION.md`

---

## 1. IMPLEMENTATION WORKFLOW & STAGES

### Stage 1: Input & Data Preparation
- [x] Configure Godot input actions in `project.godot`: `move_forward`, `move_backward`, `move_left`, `move_right`, `jump`, `crouch`.
- [ ] Implement `scripts/characters/CharacterMovementData.gd` or exported parameters on controller for modular tuning.

### Stage 2: Character Controller & State Machine
- [ ] Author `scripts/characters/CharacterStateMachine.gd`:
  - Typed state definitions (`State` enum or discrete state nodes).
  - Clean transition guards preventing illegal state jumps (e.g. jumping while crouched).
- [ ] Author `scripts/characters/CharacterController2D.gd`:
  - Ground movement, acceleration, deceleration, friction.
  - Jump impulse, airborne gravity accumulation, terminal velocity clamp.
  - Dynamic collision capsule height adjustment on crouch enter/exit.
  - Facing management: update visual scale (`Skeleton2D.scale.x`) based on target or input direction without inverting physics root.
  - Seamless animation playback calls mapped to FSM states.

### Stage 3: Character Scene Integration
- [ ] Add `CollisionShape2D` to `scenes/characters/Kai.tscn` (CapsuleShape2D, standing height 320px, radius 28px, center at (0, -160)).
- [ ] Attach `CharacterController2D` script to `scenes/characters/Kai.tscn` root.
- [ ] Ensure `Skeleton2D` has `scale = Vector2(0.48, 0.48)` while root `CharacterBody2D` remains unscaled `Vector2(1.0, 1.0)`.

### Stage 4: Test Environment Construction
- [ ] Build `scenes/arenas/MovementTestArena.tscn`:
  - 1280×720 viewport with dark aesthetic.
  - Floor platform at Y=560 (Physics Layer 1: environment).
  - Left wall at X=60 and Right wall at X=1220 to test boundary collisions.
  - Elevated platform at X=640, Y=430 to test jumping up and landing.
  - Kai instance ready for interactive keyboard control and automated testing.
  - On-screen diagnostic HUD displaying current velocity, state, grounded status, and animation name.

### Stage 5: Automated Testing & Visual Verification
- [ ] Author automated headless test suite `tests/unit/test_player_movement.gd`:
  - TC-201: Ground walk forward acceleration & velocity ceiling.
  - TC-202: Ground walk backward velocity.
  - TC-203: Deceleration to dead stop on input release (friction).
  - TC-204: Jump impulse initiation and airborne gravity accumulation.
  - TC-205: Jump restriction while crouching (jump ignored).
  - TC-206: Landing on ground resets vertical velocity and restores grounded state.
  - TC-207: Crouch height collision adjustment.
  - TC-208: Left and right wall boundary collisions without clipping.
  - TC-209: Animation state synchronization (`idle`, `walk_fwd`, `walk_bwd`, `crouch`).
- [ ] Run regression suite: `tests/unit/test_kai_hierarchy.gd`.
- [ ] Run in-engine visual capture via Godot Movie Maker mode to inspect movement responsiveness and collision behavior.

### Stage 6: Audit & Handover
- [ ] Perform Pass 1 (Architecture & Consistency) and Pass 2 (Quality & Completeness) audits.
- [ ] Author `docs/PHASES/PHASE_02/COMPLETION_REPORT.md`.
- [ ] Update `ROADMAP.md`, `TASK_BOARD.md`, `CHANGELOG.md`, `NEXT_SESSION.md`.
- [ ] Commit with Conventional Commit message and strictly stop.
