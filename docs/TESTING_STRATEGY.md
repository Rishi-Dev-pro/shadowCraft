# SHADOWCRAFT 2D — TESTING & QUALITY ASSURANCE STRATEGY

> **Status:** APPROVED QA STRATEGY  
> **Framework:** GdUnit4 (Godot Unit Testing Framework)  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md` and `docs/DECISIONS/ADR-0008-testing-and-gdunit4.md`

---

## 1. TESTING PHILOSOPHY

In ShadowCraft 2D, testing is divided into automated mathematical/logical verification and tactile game feel verification:

1. **Automated Headless Tests (GdUnit4):**
   - Verify damage calculations, poise depletion formulas, state machine transition rules, resource bounds, input buffering, and save-file serialization.
   - Run in under 5 seconds via Godot's `--headless` CLI.
   - Serve as continuous integration (CI) gates preventing regression.
2. **Interactive Manual QA:**
   - Test game feel, input responsiveness, frame pacing, visual alignment of weapon hitboxes to animation sprites, screen shake, and audio sync.
   - **The Honesty Rule:** Passing headless tests proves code correctness, NOT visual satisfaction or tactile combat feel. Never claim visual verification without interactive inspection.

---

## 2. TEST SUITE HIERARCHY

```text
tests/
├── unit/
│   ├── test_damage_calculator.gd
│   ├── test_poise_system.gd
│   ├── test_character_state_machine.gd
│   ├── test_weapon_data_schema.gd
│   ├── test_attack_data_bounds.gd
│   └── test_save_game_validator.gd
│
└── integration/
    ├── test_combat_exchange_flow.gd
    ├── test_parry_window_timing.gd
    ├── test_hitbox_hurtbox_collision.gd
    └── test_save_load_roundtrip.gd
```

---

## 3. SAMPLE GDUNIT4 TEST IMPLEMENTATIONS

### Unit Test: Damage Calculation Formula
```gdscript
# tests/unit/test_damage_calculator.gd
extends GdUnitTestSuite

func test_clean_hit_damage() -> void:
    var base_weapon_damage: float = 10.0
    var attack_ratio: float = 1.5
    var material_multiplier: float = 1.8 # Iron
    var armor_reduction: float = 5.0
    
    var calculated: float = CombatMath.calculate_damage(
        base_weapon_damage, 
        attack_ratio, 
        material_multiplier, 
        armor_reduction, 
        false # not blocked
    )
    
    # Expected: (10 * 1.5 * 1.8) - 5 = 27 - 5 = 22.0
    assert_float(calculated).is_equal_approx(22.0, 0.01)

func test_blocked_damage_mitigation() -> void:
    var raw_damage: float = 20.0
    var mitigation_ratio: float = 0.75 # 75% blocked
    
    var blocked_damage: float = CombatMath.apply_block_mitigation(raw_damage, mitigation_ratio)
    
    # Expected: 20 * (1 - 0.75) = 5.0
    assert_float(blocked_damage).is_equal_approx(5.0, 0.01)
```

### Integration Test: Hitbox Collision & Health Reduction
```gdscript
# tests/integration/test_hitbox_hurtbox_collision.gd
extends GdUnitTestSuite

var attacker: CharacterBody2D
var defender: CharacterBody2D

func before_test() -> void:
    attacker = auto_free(CharacterBody2D.new())
    defender = auto_free(CharacterBody2D.new())

func test_hitbox_depletes_defender_health() -> void:
    var health_comp: HealthComponent = auto_free(HealthComponent.new())
    health_comp.max_health = 100.0
    health_comp.current_health = 100.0
    defender.add_child(health_comp)
    
    var hit_payload: Dictionary = {
        "damage": 15.0,
        "poise_damage": 20.0,
        "is_counter": false
    }
    
    health_comp.receive_damage(hit_payload["damage"])
    assert_float(health_comp.current_health).is_equal(85.0)
```

---

## 4. SECURITY & DATA INTEGRITY VALIDATION

All persistent data and dynamic resource configs must pass strict security validation:
1. **Save File Schema Validation:**
   - JSON keys must match expected types (`version: int`, `gold: int`, `unlocked_weapons: Array[String]`).
   - Numerical values must be clamped to reasonable gameplay bounds (e.g., gold $\ge 0$, health $\le \text{max_health}$).
2. **Resource Clamping:**
   - Attack frame data must be verified: `startup_frames >= 1`, `active_frames >= 1`, `recovery_frames >= 1`.
   - Prevent division by zero or infinite loop states.
3. **Save File Checksum / HMAC:**
   - Stored in `user://savegame.json` along with an SHA-256 HMAC digest to detect accidental corruption or tampering.

---

## 5. CONTINUOUS INTEGRATION (CI) EXECUTION

Automated testing is integrated via GitHub Actions in `.github/workflows/ci.yml`.

### CLI Execution Command
```powershell
# Headless run from repository root
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd run -a tests/
```

### CI Gate Rules
- 100% of tests must pass before merging code into `main`.
- Any crash, memory leak warning, or failed assertion fails the CI build.
