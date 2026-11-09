# SHADOWCRAFT 2D — MASTER DEVELOPMENT ROADMAP

> **Status:** APPROVED PROVISIONAL ROADMAP  
> **Governance:** Strict phase-by-phase execution. No phase may commence without explicit user authorization.  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md`

---

## 1. PHASE PROGRESS OVERVIEW

| Phase | Title | Focus Area | Status | Gated Approval |
|---|---|---|---|---|
| **Phase 00** | Project Foundation & Architecture | Engine setup, documentation, ADRs, repo governance | **COMPLETED** | Approved |
| **Phase 01** | Kai 2D Character Art & Animation Pipeline | 2D silhouette sprites, Skeleton2D rig, idle/locomotion | **COMPLETED** | Approved |
| **Phase 02** | Player Movement & Controls | Kinematic 2D movement, jump, crouch, dash, facing logic | *PLANNED* | Pending Authorization |
| **Phase 03** | Core 2D Combat Engine | Hitbox/Hurtbox layers, damage math, health component | *PLANNED* | Blocked by Phase 02 |
| **Phase 04** | Wooden Sword & First Moveset | AttackData resources, combo chain, active frames | *PLANNED* | Blocked by Phase 03 |
| **Phase 05** | Blocking, Parrying, Dodging & Combos | High/low guard, 4-frame parry window, counter-hit stun | *PLANNED* | Blocked by Phase 04 |
| **Phase 06** | Weapon Framework & Additional Categories | Axe, Spear, Mace movesets & Material tier scaling | *PLANNED* | Blocked by Phase 05 |
| **Phase 07** | Enemy Combat AI | Sense-evaluate-act loop, spacing AI, reaction tables | *PLANNED* | Blocked by Phase 06 |
| **Phase 08** | Boss Encounters | Razen boss archetype, custom phases, phase transitions | *PLANNED* | Blocked by Phase 07 |
| **Phase 09** | Dojos & Arenas | Parallax 2D backgrounds, dynamic lighting, boundary walls | *PLANNED* | Blocked by Phase 08 |
| **Phase 10** | Campaign Map & Progression | Dojo selection, bodyguard ladder, save/load system | *PLANNED* | Blocked by Phase 09 |
| **Phase 11** | Equipment & Upgrades | Blacksmith upgrade loop, material requirements, economy | *PLANNED* | Blocked by Phase 10 |
| **Phase 12** | UI, Audio, Optimization & Release | Full HUD, SFX/Music bus, 60 FPS profiling, packaging | *PLANNED* | Blocked by Phase 11 |

---

## 2. DETAILED PHASE SPECIFICATIONS

### Phase 00: Project Foundation & Architecture
- **Objective:** Establish the clean, pure 2D project structure, engine configuration, coding standards, architecture blueprints, ADRs, and quality assurance framework.
- **Key Deliverables:** `project.godot` (GL Compatibility, 1280x720), `AGENTS.md`, `docs/PROJECT_CONSTITUTION.md`, `docs/ARCHITECTURE.md`, 11 ADRs, full documentation suite, GdUnit4 test layout, clean Git initialization.
- **Exit Criteria:** Pass 1 and Pass 2 audits completed with 0 errors; working tree clean; initial commit pushed.

### Phase 01: Kai 2D Character Art & Animation Pipeline
- **Objective:** Produce high-resolution 2D silhouette sprite assets for protagonist Kai; build the `Skeleton2D` and `Bone2D` hierarchical rig; configure `AnimationPlayer` for neutral loops.
- **Key Deliverables:** Transparent PNG sprites (Head, Torso, Arms, Legs, Purple Accents), rigged Kai scene (`scenes/characters/Kai.tscn`), locomotion animations (`idle`, `walk_fwd`, `walk_bwd`, `crouch`).
- **Exit Criteria:** Smooth 60 FPS skeletal interpolation in Godot 2D editor; zero 3D nodes; sprite scale standardized.

### Phase 02: Player Movement & Controls
- **Objective:** Implement `CharacterBody2D` physics movement, input handling, state machine, and automatic opponent facing.
- **Key Deliverables:** `CharacterController2D.gd`, `CharacterStateMachine.gd`, movement states (`IdleState`, `MoveState`, `JumpState`, `CrouchState`), opponent distance tracking.
- **Exit Criteria:** Responsive 60 FPS controls; smooth transitions; deterministic floor and wall collisions.

### Phase 03: Core 2D Combat Engine
- **Objective:** Build the spatial collision pipeline for combat: hitboxes, hurtboxes, health components, and damage formulas.
- **Key Deliverables:** `Hitbox2D.gd`, `Hurtbox2D.gd`, `HealthComponent.gd`, `CombatController.gd`, physics layers 4-7 configured, unit tests for damage/poise math.
- **Exit Criteria:** Automated test verifying that active Hitbox overlapping Hurtbox emits hit signal, applies calculated damage, and updates health.

### Phase 04: Wooden Sword & First Moveset
- **Objective:** Create the initial playable weapon and moveset: Wooden Sword.
- **Key Deliverables:** `WeaponData` resource schema, `AttackData` resources for neutral light, forward light, heavy chop, and combo buffering.
- **Exit Criteria:** Kai can execute a full 3-hit light combo and heavy attack with precise active frames and recovery locks.

### Phase 05: Blocking, Parrying, Dodging & Combos
- **Objective:** Implement complete defensive systems and advanced combo interactions.
- **Key Deliverables:** High guard, low crouching guard, 4-frame parry window, hitstop (freeze frames), stagger and knockdown states.
- **Exit Criteria:** Successful parry negates damage and inflicts attacker recoil; whiffed attacks are punishable.

### Phase 06: Weapon Framework & Additional Categories
- **Objective:** Expand the weapon framework to include Axe, Spear, and Mace movesets, plus material tier scaling (Wood, Stone, Iron, Diamond, Netherite).
- **Key Deliverables:** Distinct moveset definitions, weight penalties, poise damage multipliers, weapon sprite variations.
- **Exit Criteria:** Each weapon category has a demonstrably unique rhythm, range, and fighting style.

### Phase 07: Enemy Combat AI
- **Objective:** Implement single-player AI opponent that evaluates spacing, blocks attacks, and punishes whiffs.
- **Key Deliverables:** `EnemyController.gd`, sensory evaluation module, fuzzy aggression decision tree, difficulty parameters.
- **Exit Criteria:** AI provides a challenging, engaging duel without input-reading cheats.

### Phase 08: Boss Encounters
- **Objective:** Develop Razen (The Crimson Warlord) as the premier antagonist and boss fight.
- **Key Deliverables:** Razen 2D visual assets, crimson effects, multi-phase boss state machine, special moves, intro/outro cinematics.
- **Exit Criteria:** Razen delivers an intense, multi-phase boss fight testing player spacing and parry mastery.

### Phase 09: Dojos & Arenas
- **Objective:** Build atmospheric 2D battlegrounds featuring multi-layer parallax scrolling, ambient lighting, and boundary walls.
- **Key Deliverables:** Training Dojo, Bamboo Courtyard, Crimson Citadel arena scenes; 2D canvas lighting.
- **Exit Criteria:** Visual atmosphere matches the shadow fighting pillar; zero framerate drops below 60 FPS.

### Phase 10: Campaign Map & Progression
- **Objective:** Implement the dojo campaign ladder, bodyguard progression, and persistent game save/load system.
- **Key Deliverables:** Campaign map UI, ladder progression state, encrypted JSON save file with schema validation and HMAC hash.
- **Exit Criteria:** Player progression persists reliably across restarts; tampered saves are safely handled.

### Phase 11: Equipment & Upgrades
- **Objective:** Implement the blacksmith upgrade loop, material requirements, currency economy, and gear stats.
- **Key Deliverables:** Inventory resource, upgrade UI, shop interface, stat scaling calculators.
- **Exit Criteria:** Weapons can be upgraded from Wood through Netherite using acquired materials.

### Phase 12: UI, Audio, Optimization & Release Preparation
- **Objective:** Complete full audio mixing, polished HUD, options menu, performance profiling, and Windows export packaging.
- **Key Deliverables:** Audio tracks, dynamic SFX, settings menu (remapping, volume, resolution), 60 FPS profile report, final standalone build.
- **Exit Criteria:** Clean executable launch; passes all regression tests; verified stable on modest hardware.

