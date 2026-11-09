# SHADOWCRAFT 2D — SECURITY & RELIABILITY GUIDELINES

> **Status:** APPROVED SECURITY POLICY  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md`

---

## 1. SAVE FILE INTEGRITY & VALIDATION

### File Storage & Sandboxing
- Save files are restricted to Godot's sandboxed virtual path: `user://savegame.json`.
- Never write to absolute Windows filesystem paths (`C:\...`, `D:\...`).
- Path traversal sequences (`../`, `..\`) must be explicitly blocked if parsing external file names.

### Schema Validation & Clamping
- When deserializing save files:
  1. Confirm `schema_version` matches the current supported engine version.
  2. Verify all expected fields exist and match expected types (e.g., `gold` is an `int`, not a string or nested object).
  3. Clamp all values within realistic gameplay bounds:
     ```gdscript
     gold = clampi(data.get("gold", 0), 0, 9999999)
     current_dojo = clampi(data.get("current_dojo", 1), 1, 10)
     ```
  4. Reject corrupted or malformed files gracefully by loading default fallback profiles rather than crashing.

### Tampering Prevention
- Calculate an SHA-256 HMAC digest of the save contents combined with an internal salt.
- Store the digest in a header file `user://savegame.chk`. If the computed hash fails to match, alert the user and offer to reset or load a backup.

---

## 2. RESOURCE & CONFIGURATION HARDENING

### Dynamic Resource Loading
- Never use unsanitized user strings in `load()` or `ResourceLoader.load()`.
- Whitelist allowable resource paths:
  ```gdscript
  func load_weapon_resource(weapon_id: String) -> WeaponData:
      var allowed_weapons: Dictionary = {
          "wood_sword": "res://resources/weapons/sword/sword_wood.tres",
          "iron_sword": "res://resources/weapons/sword/sword_iron.tres"
      }
      if not allowed_weapons.has(weapon_id):
          push_error("Unauthorized weapon resource request: %s" % weapon_id)
          return null
      return load(allowed_weapons[weapon_id]) as WeaponData
  ```

### Frame Data Sanitization
- Frame counters in `AttackData` must be strictly positive:
  - `startup_frames >= 1`
  - `active_frames >= 1`
  - `recovery_frames >= 1`
- Negative or zero values can lead to infinite loops or divide-by-zero errors in animation logic.

---

## 3. SECRETS & CREDENTIALS PROTECTION

- **Rule 12 of AGENTS.md:** *Never hardcode secrets or credentials.*
- Zero API keys, passwords, private tokens, or user machine identifiers may be committed to Git.
- The `.gitignore` must strictly exclude all private local files (`.env`, `*.secret`, credentials).

---

## 4. FUTURE ARCHITECTURE: SERVER-AUTHORITATIVE PRINCIPLES

If local or online multiplayer is ever introduced in a future expansion:
- The game architecture must remain strictly **server-authoritative**.
- Clients submit input intents (`move_left`, `press_light_attack`), never combat outcomes (`dealt_50_damage`, `set_health_to_0`).
- The host or server alone calculates hit collisions, damage formulas, and state changes.

