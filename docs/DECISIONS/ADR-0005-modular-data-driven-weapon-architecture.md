# ADR-0005: Modular Data-Driven Weapon Architecture

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
In many action games, weapons are simply stat modifications (e.g., Weapon A does 10 damage, Weapon B does 20 damage). In ShadowCraft 2D, weapon selection must fundamentally alter combat identity: attack speed, reach, active frame windows, recovery times, and combo strings. Furthermore, Minecraft-inspired material tiers (Wood, Stone, Iron, Diamond, Netherite) must apply across categories without hardcoding every combination into standalone scripts.

## Decision
We decouple **Weapon Category** from **Material Tier** using custom Godot `Resource` definitions:

1. **`AttackData` (`Resource`):**
   Defines an individual attack: startup frames, active frames, recovery frames, damage ratio, poise damage, knockback vector, hitstop duration, and assigned animation name.
2. **`WeaponData` (`Resource`):**
   Defines the complete weapon instance: category (`SWORD`, `AXE`, `SPEAR`, `MACE`), tier (`WOOD`, `STONE`, `IRON`, `DIAMOND`, `NETHERITE`), base damage, weight penalty, visual texture, and slot mappings for light, heavy, forward, and special `AttackData`.

This allows designers to create new weapons entirely inside the Godot inspector as `.tres` files without touching or subclassing GDScript logic.

## Alternatives Considered
- **Script Inheritance (e.g., `WoodenSword extends Sword extends Weapon`):** Led to rigid class hierarchies, duplicated logic, and poor designer iteration speed.
- **Monolithic JSON Tables:** Lack compile-time type safety in GDScript and do not integrate seamlessly with Godot's resource inspector.

## Consequences
- **Positive:** Adding a new weapon or balancing frame data is purely a resource edit; 100% data-driven; zero code changes needed to tweak numbers or swap movesets.
- **Negative:** Requires rigorous resource schema validation at boot/load time to ensure no missing attack references.

