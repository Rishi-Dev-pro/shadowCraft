# SHADOWCRAFT 2D

[![Engine](https://img.shields.io/badge/Godot-4.x-blue.svg)](https://godotengine.org/)
[![Renderer](https://img.shields.io/badge/Renderer-Compatibility%20(GL3)-green.svg)](https://docs.godotengine.org/en/stable/tutorials/rendering/rendering_methods.html)
[![Platform](https://img.shields.io/badge/Platform-Windows%20(64--bit)-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT%20Custom-orange.svg)](LICENSE)

**ShadowCraft 2D** is an original 2D weapon-based shadow fighting game built from the ground up in **Godot 4**. It combines the tactical spacing, martial arts precision, and dojo progression of *Shadow Fight 2* with the iconic weapon categories and material progression inspired by *Minecraft*.

---

## 1. Game Vision

Two shadow warriors clash in a fixed 2D side-view fighting arena. Combat is tactical, deliberate, and spacing-driven. Weapons dictate the warrior's entire moveset, frame timings, reach, and combat rhythm—they are not mere stat multipliers.

### Original Characters

- **Kai — The Shadow Disciple**: Protagonist. Characterized by agile martial arts, disciplined swordplay, and an ethereal **purple** energy signature.
- **Razen — The Crimson Warlord**: Antagonist and rival. Characterized by brutal power, heavy momentum-driven strikes, and an intimidating **crimson** energy signature.

### Weapon System

ShadowCraft strictly separates **Weapon Category** from **Material Tier**:

- **Weapon Categories (Moveset & Combat Style):**
  - **Sword**: Balanced speed, mid-range slicing, versatile combo chains.
  - **Axe**: Heavy vertical cleaves, armor-breaking chops, slower recovery.
  - **Spear**: Superior thrusting reach, precision zoning, vulnerable at point-blank range.
  - **Mace**: Crushing blunt trauma, high poise damage, devastating knockdowns.

- **Material Tiers (Durability, Weight & Damage Scaling):**
  - **Wood** → **Stone** → **Iron** → **Diamond** → **Netherite**

---

## 2. Technical Pillars

- **Pure 2D Architecture:** Built exclusively with Godot 4 native 2D nodes (`CharacterBody2D`, `Area2D`, `Skeleton2D`, `Bone2D`, `AnimationPlayer`, `AnimatedSprite2D`). All 3D nodes and 3D physics are strictly forbidden.
- **Compatibility Renderer:** Powered by Godot's `gl_compatibility` (OpenGL 3.3 / GLES3) renderer for maximum performance, minimal GPU overhead, and instant load times on modest laptops.
- **Hybrid Animation Pipeline:** Smooth skeletal deformation for neutral locomotion (idle, walking, running, breathing) combined with hand-crafted frame-by-frame animation for high-impact combat strikes, knockdowns, and parry reactions.
- **Data-Driven Combat Engine:** Attacks and weapons are defined as modular Godot `Resource` files (`AttackData`, `WeaponData`), keeping gameplay logic decoupled from visual presentation.
- **Static GDScript:** Pure GDScript 2.0 with strict static typing for optimal runtime performance and compile-time safety.

---

## 3. Directory Layout

```text
ShadowCraft-2D/
├── project.godot           # Godot 4 engine configuration (GL Compatibility, 1280x720)
├── .gitignore              # Engine and environment ignore rules
├── .gitattributes         # Line-ending and binary asset filters
├── AGENTS.md               # Mandatory AI agent operational rules
├── README.md               # Project documentation overview
├── LICENSE                 # Software license and asset copyright notice
│
├── assets/                 # Production-ready 2D game assets
│   ├── characters/         # Character sprite sheets and skeletal parts (kai, razen)
│   ├── weapons/            # Weapon sprites and icons
│   ├── arenas/             # 2D parallax backgrounds and dojo environments
│   ├── effects/            # 2D particles and combat visual FX
│   ├── ui/                 # UI themes, fonts, icons, HUD frames
│   └── audio/              # SFX, impact sounds, and atmospheric music
│
├── scenes/                 # Packed Godot scenes (.tscn)
│   ├── characters/         # Character prefabs (Player, Dummy, Opponents)
│   ├── combat/             # Hitbox, Hurtbox, Combat Arena scenes
│   ├── weapons/            # Weapon visual instances and sockets
│   ├── arenas/             # Arena stage layouts
│   └── ui/                 # HUD, health bars, menus, dialogue overlays
│
├── scripts/                # GDScript source code (.gd)
│   ├── characters/         # Character controller, state machines, animation
│   ├── combat/             # Combat controller, damage calc, hit registration
│   ├── weapons/            # Weapon controllers and socket handlers
│   ├── enemies/            # Enemy controllers and AI decision systems
│   ├── progression/        # Dojo progression, save/load, inventory
│   └── systems/            # Event bus, audio manager, settings
│
├── resources/              # Data-driven configuration (.tres)
│   ├── characters/         # Character base stats and definitions
│   ├── attacks/            # Frame data, hitboxes, and attack parameters
│   └── weapons/            # Weapon definitions and moveset mappings
│
├── tests/                  # Automated test suites (GdUnit4)
│   ├── unit/               # Logic, math, and data validation tests
│   └── integration/        # Combat flow and state machine tests
│
└── docs/                   # Architectural blueprints and project governance
    ├── PROJECT_CONSTITUTION.md   # Non-negotiable project constitution
    ├── ARCHITECTURE.md           # Full technical architecture and system diagrams
    ├── ROADMAP.md                # 13-phase development roadmap
    ├── TASK_BOARD.md             # Active sprint tasks and backlog
    ├── CHANGELOG.md              # Historical record of changes
    ├── DECISIONS/                # Architecture Decision Records (ADR-0001 - ADR-0011)
    └── PHASES/                   # Phase specifications, plans, and reports
```

---

## 4. Development & Running

### Requirements
- **Engine:** Godot 4 (v4.3 or higher, tested with Godot 4.7.2 stable)
- **OS:** Windows 10/11 (64-bit)
- **Renderer:** OpenGL 3.3 / Compatibility mode

### Opening the Project
1. Launch the Godot 4 Project Manager.
2. Select **Import** and choose `d:\projects 2.0\games\shadowCraft\project.godot`.
3. Open and edit with the Godot editor.

### Testing
Automated testing is configured using **GdUnit4**. Tests can be executed headlessly via CLI:
```powershell
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd run -a tests/
```

---

## 5. Copyright & Originality

*Shadow Fight 2* (Nekki) and *Minecraft* (Mojang/Microsoft) serve solely as conceptual inspiration for game mechanics and progression models. 
ShadowCraft 2D does not use, copy, reverse-engineer, or adapt any proprietary sprites, textures, animations, code, audio, branding, or character assets from those franchises. All visual art, audio, code, and character designs are original creations owned by the ShadowCraft Team.

