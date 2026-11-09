# SHADOWCRAFT 2D — WEAPON TAXONOMY & ARCHITECTURAL SYSTEM

> **Status:** APPROVED SYSTEM SPECIFICATION  
> **Design Inspiration:** Minecraft Category/Material Matrix & Shadow Fight 2 Martial Movesets  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md`

---

## 1. THE DUAL-VECTOR WEAPON MATRIX

In ShadowCraft 2D, a weapon's combat identity is determined by the intersection of two independent axes:

```text
               ┌─────────────────────────────────────────────────────────────┐
               │                     MATERIAL TIERS                          │
               │   WOOD  ───►  STONE  ───►  IRON  ───►  DIAMOND  ───►  NETHERITE│
┌──────────────┼─────────────────────────────────────────────────────────────┤
│ WEAPON       │                                                             │
│ CATEGORIES   │                                                             │
│              │                                                             │
│  SWORD       │ [Wood Sword]  [Stone Sword] [Iron Sword]  [Dia Sword]  [Neth Sword] │
│  AXE         │ [Wood Axe]    [Stone Axe]   [Iron Axe]    [Dia Axe]    [Neth Axe]   │
│  SPEAR       │ [Wood Spear]  [Stone Spear] [Iron Spear]  [Dia Spear]  [Neth Spear] │
│  MACE        │ [Wood Mace]   [Stone Mace]  [Iron Mace]   [Dia Mace]   [Neth Mace]  │
└──────────────┴─────────────────────────────────────────────────────────────┘
```

- **Weapon Category** governs:
  - Martial discipline and posture.
  - Animation set and combo sequence.
  - Threat reach and spatial hitbox arcs.
  - Base startup and recovery windows.
- **Material Tier** governs:
  - Damage scaling multiplier.
  - Weight penalty / momentum modifier (modifies recovery frames slightly).
  - Poise depletion rate and armor penetration.
  - Particle trails, hit sound timbres, and visual blade sheen.

---

## 2. WEAPON CATEGORIES (FIGHTING DISCIPLINES)

### 1. The Sword (Fluidity & Versatility)
- **Combat Style:** Classical Kenjutsu / Dao swordplay. Rapid horizontal slashes, diagonal cuts, and lunging stabs.
- **Reach:** Moderate (120px active radius).
- **Speed:** Fast (Startup: 6–8 frames).
- **Core Moveset:**
  - `Neutral Light 1-2-3`: Rapid triple slash string.
  - `Forward Light`: Lunging mid-thrust with quick recovery.
  - `Heavy Overhead`: Two-handed vertical cleave (punishes low duckers).
  - `Special / Back Light`: Retreating feint slash with backward micro-step.

### 2. The Axe (Momentum & Crushing Cleaves)
- **Combat Style:** Brutal executioner sweeps, heavy momentum-driven swings, armor splitting.
- **Reach:** Moderate-Long (140px active radius).
- **Speed:** Slower (Startup: 12–16 frames).
- **Core Moveset:**
  - `Neutral Light 1-2`: Heavy horizontal chop into downward backhand.
  - `Forward Heavy`: Leaping executioner chop (ground bounce on hit).
  - `Special Overhead`: Overhead cleave that shatters blocking poise (+50% poise damage).

### 3. The Spear (Range Control & Zoning)
- **Combat Style:** Sojutsu spear martial arts. Precision thrusts, sweep sweeps, keep-away zoning.
- **Reach:** Longest (210px forward threat reach).
- **Speed:** Moderate thrusts (Startup: 9–11 frames).
- **Core Moveset:**
  - `Neutral Light 1-2`: Rapid double thrust at torso level.
  - `Forward Piercing Thrust`: Max-range reach attack that interrupts incoming dashes.
  - `Low Sweep`: Sweeping ground arc that trips standing opponents (knocks down high blockers).
  - *Weakness:* Point-blank dead zone; opponents inside the spearhead take minimal damage.

### 4. The Mace (Blunt Force & Poise Destruction)
- **Combat Style:** Crushing kinetic trauma, sweeping warhammer strikes, guard crushers.
- **Reach:** Compact (100px active radius).
- **Speed:** Heavy (Startup: 14–18 frames).
- **Core Moveset:**
  - `Neutral Light`: Short-range horizontal bludgeon.
  - `Heavy Overhead Smash`: Ground-pounding hammer strike causing knockdown.
  - `Spinning Sweep`: Full 360-degree sweep knocking back nearby opponents.
  - *Perk:* Guaranteed guard break if opponent blocks two consecutive heavy strikes.

---

## 3. MATERIAL TIERS & STAT MATRIX

| Material Tier | Damage Multiplier | Weight / Recovery Mod | Poise Damage Mod | Visual / Audio Theme |
|---|---|---|---|---|
| **Wood** | 1.0× (Baseline) | -2 frames (Fastest) | 0.8× | Natural timber texture, hollow wooden clacks |
| **Stone** | 1.35× | 0 frames (Standard) | 1.0× | Chiseled slate texture, blunt stone thuds |
| **Iron** | 1.80× | +1 frame recovery | 1.25× | Polished steel, sharp metallic clangs & sparks |
| **Diamond** | 2.40× | -1 frame recovery | 1.50× | Cyan crystalline sheen, ringing resonance, cyan trails |
| **Netherite** | 3.20× | +2 frames recovery | 2.00× | Dark obsidian/bronze alloy, deep bass impact, purple/ember trails |

---

## 4. GODOT RESOURCE DATA SCHEMAS

Weapons and attacks are stored strictly as custom Godot `Resource` files (`.tres`):

### `AttackData.gd`
```gdscript
class_name AttackData
extends Resource

@export var attack_name: String
@export var animation_name: String

@export_group("Frame Data")
@export_range(1, 60) var startup_frames: int = 6
@export_range(1, 60) var active_frames: int = 3
@export_range(1, 60) var recovery_frames: int = 12
@export_range(0, 10) var hitstop_frames: int = 4

@export_group("Damage & Impact")
@export var damage_ratio: float = 1.0
@export var poise_damage: float = 25.0
@export var knockback_impulse: Vector2 = Vector2(150.0, 0.0)
@export var hit_reaction_type: String = "light_stagger" # light_stagger, heavy_stagger, knockdown
@export var can_be_blocked_low: bool = false
@export var can_be_blocked_high: bool = true
```

### `WeaponData.gd`
```gdscript
class_name WeaponData
extends Resource

enum Category { SWORD, AXE, SPEAR, MACE }
enum MaterialTier { WOOD, STONE, IRON, DIAMOND, NETHERITE }

@export var weapon_id: String
@export var display_name: String
@export var category: Category
@export var material_tier: MaterialTier

@export var base_damage: float = 12.0
@export var weight_penalty: float = 1.0
@export var sprite_texture: Texture2D
@export var trail_color: Color = Color.WHITE

@export_group("Moveset")
@export var attack_light_1: AttackData
@export var attack_light_2: AttackData
@export var attack_light_3: AttackData
@export var attack_heavy: AttackData
@export var attack_forward: AttackData
@export var attack_special: AttackData
```
