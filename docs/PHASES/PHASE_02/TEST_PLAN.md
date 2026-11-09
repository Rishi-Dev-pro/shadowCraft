# PHASE 02 TEST PLAN: PLAYER MOVEMENT & CONTROLS

> **Phase Identifier:** PHASE-02  
> **Status:** VERIFIED & PASSED  
> **Source of Truth:** `docs/PHASES/PHASE_02/SPECIFICATION.md`

---

## 1. OBJECTIVE

Validate that the 2D movement and control system for Kai is completely functional, deterministic, physically grounded, adheres strictly to 2D-only constraints, and cleanly connects to Phase 01 animations without glitches or forbidden behaviors.

---

## 2. TEST CASES MATRIX

| Test ID | Category | Description | Verification Method | Pass Criteria | Status |
|---|---|---|---|---|---|
| **TC-201** | Forward Walk | Move forward input accelerates character to maximum walk speed | Automated unit test (`test_player_movement.gd`) | `velocity.x` reaches `walk_speed` (within 1%); `loco/walk_fwd` requested | **PASS** |
| **TC-202** | Backward Walk | Move backward input sets velocity in opposite direction | Automated unit test | `velocity.x` reaches negative speed; `loco/walk_bwd` requested | **PASS** |
| **TC-203** | Friction / Stop | Releasing movement decelerates character to 0 px/s | Automated unit test | Character comes to complete stop; transitions to `loco/idle` | **PASS** |
| **TC-204** | Jump Initiation | Pressing jump when grounded applies upward vertical impulse | Automated unit test | `velocity.y == jump_velocity` (-420 px/s); `is_on_floor() == false` | **PASS** |
| **TC-205** | Jump Lockout | Pressing jump while crouching is strictly prevented | Automated unit test | `velocity.y` remains 0; character remains grounded and crouched | **PASS** |
| **TC-206** | Landing Reset | Falling onto floor resets vertical velocity and restores grounded status | Automated unit test | `velocity.y` resets to 0; state returns to grounded `idle`/`walk` | **PASS** |
| **TC-207** | Crouch Collision | Entering crouch reduces collision shape height | Automated unit test | Collision capsule height drops from 320px to 200px; plays `loco/crouch` | **PASS** |
| **TC-208** | Wall Collision | Walking into solid arena wall stops character horizontally | Automated unit test | Character cannot penetrate beyond wall boundary (`is_on_wall() == true`) | **PASS** |
| **TC-209** | Facing Logic | Changing target side flips `Skeleton2D.scale.x` without inverting root | Automated unit test | `skeleton.scale.x` flips sign; root `scale.x == 1.0` | **PASS** |
| **TC-210** | Regression | Run Phase 01 hierarchy validation suite | Automated unit test (`test_kai_hierarchy.gd`) | 100% pass rate (all 44 assertions pass) | **PASS** |
| **TC-211** | In-Engine Visual Gate | Inspect interactive movement test scene under active physics simulation | In-engine Movie Maker capture & direct image audit | Smooth locomotion, clean grounded stance, no collision hovering, 60 FPS | **PASS** |

---

## 3. EXECUTION SUMMARY

- **Phase 02 Unit Test Suite (`tests/unit/test_player_movement.gd`):** 55 / 55 Passed (100%)
- **Phase 01 Regression Test Suite (`tests/unit/test_kai_hierarchy.gd`):** 44 / 44 Passed (100%)
- **Total Assertions Executed:** 99 / 99 Passed (100%)
- **Visual Verifications:** 4 in-engine captures visually audited via `read_file`:
  1. `reports/screenshots/movement_arena_composite.png` (Idle state, telemetry display, arena boundaries)
  2. `reports/screenshots/movement_walk_fwd.png` (Forward locomotion, max speed 220 px/s)
  3. `reports/screenshots/movement_jump.png` (Airborne jump, Y-impulse -420 px/s, no ground cycle glitching)
  4. `reports/screenshots/movement_crouch.png` (Grounded crouch, collision capsule dynamically reduced from 320px to 200px)

