# SHADOWCRAFT 2D — ASSET PRODUCTION & PIPELINE GUIDELINES

> **Status:** APPROVED PRODUCTION STANDARD  
> **Target Display:** 1280 × 720 (16:9 Baseline)  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md`

---

## Experimental Kai cutout

The Kai cutout rig in `scenes/characters/grind/kai_cutout_rig.tscn` references the existing ShadowCraft art at `assets/characters/kai_v2/source/kai_turnaround_grid.png`. The texture is read directly with UV-mapped geometry from the lower-right turnaround view. Polygon outlines follow the fabric and include overlapping shoulder, elbow, wrist, knee, and ankle regions. The boot layers use atlas regions. The existing source-art provenance and usage terms apply. No new full-frame sprites were generated.

## 1. SPRITE & TEXTURE REQUIREMENTS

### Format & Color Profile
- **File Format:** 32-bit PNG (with true 8-bit alpha transparency channel).
- **Color Space:** sRGB.
- **Palette & Shading:**
  - Dark silhouette tones (deep near-black shades: `#0c0a12`, `#14101c`, `#1c1828`) with soft anatomical gradients.
  - Saturated signature accent colors (Kai: Purple `#8a2be2` / `#a855f7`; Razen: Crimson `#dc2626` / `#ef4444`).
- **No JPEG or Lossy Formats:** Artifacts and lossy compression degrade silhouette edges.

### Godot Import Settings
- **Filter Mode:** `Linear Mipmap` (or `Nearest` if pixel-art mode is explicitly chosen; default for clean vector/high-res silhouette rendering is `Linear` with 2D pixel snap).
- **Compression Mode:** `Lossless` for character sprites and combat VFX to maintain edge sharpness; `VRAM Compressed` (ETC2/ASTC / S3TC) allowed only for large static arena background textures.
- **Repeat:** `Disabled` for character sprites; `Mirrored Repeat` or `Repeat` enabled only for seamless background parallax strips.

---

## 2. CHARACTER SCALE & RESOLUTION PRINCIPLES

- **Proportional Scaling Rule:** Rather than locking arbitrary, rigid pixel dimensions before visual character designs are complete, all humanoid fighters adhere to a **proportional screen height budget**:
  - In a 720p vertical viewport, a standing adult fighter occupies approximately **35% to 45% of the total screen height** (roughly 250px to 320px tall on screen).
  - This preserves martial presence and anatomical detail while leaving sufficient headroom for jumps, high kicks, and health HUD bars.
- **Consistent World Units:**
  - Standard unit: 1 pixel in sprite = 1 unit in Godot 2D space at 1.0x scale.
  - Scaling a character's root node should remain `Vector2(1.0, 1.0)` to preserve physics fidelity; avoid ad-hoc scale hacks on sub-nodes.

---

## 3. PIVOT & ORIGIN CONVENTIONS

Every character component and sprite must adhere to strict pivot origin placement:

| Part / Node | Pivot / Origin Placement | Purpose |
|---|---|---|
| **Character Root (`CharacterBody2D`)** | Bottom-center (ground contact point between feet) | Guarantees exact ground alignment and floor raycasts |
| **Torso / Hip** | Hip center | Primary rotational root for martial postures |
| **Head / Neck** | Base of neck | Natural rotation for nodding, looking, impact recoil |
| **Upper Arm** | Shoulder joint center | Smooth arm arcs |
| **Forearm** | Elbow joint center | Punch and guard bending |
| **Hand** | Wrist joint | Grip rotation |
| **Weapon Socket (`Marker2D`)** | Hand grip center (where palm grips the hilt) | Modular weapon attachment point |
| **Weapon Sprites** | Center of the weapon grip/handle | Aligns perfectly with `WeaponSocket2D` |
| **Thigh** | Hip joint connection | Leg swings and stance depth |
| **Shin** | Knee joint center | Kicks and crouch compression |
| **Foot** | Ankle / heel base | Ground flat contact |

---

## 4. 2D CHARACTER LAYER ORDERING (Z-INDEX)

To maintain realistic silhouette depth and anatomical consistency during both sides of facing, character parts are arranged in standard visual draw order (from back to front):

```text
(Back to Front)
1. Back Arm (Upper Arm, Forearm, Hand)
2. Back Leg (Thigh, Shin, Foot)
3. Torso / Pelvis / Lower Garments
4. Head / Mask / Headband Back Ribbon
5. Front Leg (Thigh, Shin, Foot)
6. Front Arm (Upper Arm, Forearm, Hand)
7. Weapon Socket & Weapon Sprite
8. Headband Front Ribbon / Scarf Physics
9. Emissive Overlays & Particle Sockets
```

When facing is inverted (`scale.x = -1.0`), Godot automatically flips the 2D local hierarchy without disrupting Z-index layering.

---

## 5. SPRITE SHEET & FILE NAMING CONVENTIONS

- **Base Directory:** `assets/characters/<character_name>/` or `assets/weapons/<category>/`
- **Limb Parts (Skeletal Cutouts):**
  - `<char>_head.png`
  - `<char>_torso.png`
  - `<char>_arm_upper_fwd.png`, `<char>_arm_lower_fwd.png`, `<char>_hand_fwd.png`
  - `<char>_arm_upper_bwd.png`, `<char>_arm_lower_bwd.png`, `<char>_hand_bwd.png`
  - `<char>_leg_upper_fwd.png`, `<char>_leg_lower_fwd.png`, `<char>_foot_fwd.png`
  - `<char>_leg_upper_bwd.png`, `<char>_leg_lower_bwd.png`, `<char>_foot_bwd.png`
- **Frame-by-Frame Sprite Sheets:**
  - `<char>_<category>_<action>_sheet.png` (e.g., `kai_sword_atk_light_1_sheet.png`)
  - Must include frame dimensions in documentation or use uniform grid spacing (e.g., 384x384 per frame).
- **Weapon Sprites:**
  - `assets/weapons/<category>/<category>_<tier>.png`  
    *(Example: `assets/weapons/sword/sword_wood.png`, `assets/weapons/axe/axe_iron.png`)*
  - Weapon icons for UI: `assets/ui/icons/weapons/icon_<category>_<tier>.png`

---

## 6. SOURCE ASSET RETENTION & PROVENANCE LOG

- **Source Asset Storage:** Raw layered files (`.psd`, `.kra`, `.aseprite`) are retained in an external or Git-LFS tracked `assets_source/` workspace, never mixed directly into the active runtime scenes.
- **Export Standard:** All exported assets must be trimmed of redundant transparent padding while maintaining the unified pivot point.
- **Asset Provenance Ledger:** Every asset introduced into the repository must have an entry in the table below:

| Asset Path | Origin / Tool | Author / Source | License | Date Added | Verified Clean |
|---|---|---|---|---|---|
| `assets/characters/kai/kai_concept_art.png` | Bespoke Original 2D Concept Art | Subagent `509b8a93` (Image Generator) | Proprietary (Original) | 2026-11-09 | Yes (Zero legacy/external art) |
| `assets/characters/kai/head.png` | 2D Anatomical Cutout (170x190) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/torso.png` | 2D Anatomical Cutout (185x295) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/arm_upper_fwd.png` | 2D Anatomical Cutout (122x197) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/arm_lower_fwd.png` | 2D Anatomical Cutout (108x180) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/hand_fwd.png` | 2D Anatomical Cutout (96x120) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/leg_upper_fwd.png` | 2D Anatomical Cutout (173x230) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/leg_lower_fwd.png` | 2D Anatomical Cutout (153x185) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/foot_fwd.png` | 2D Anatomical Cutout (165x118) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/arm_upper_bwd.png` | 2D Depth Layer (Darkened 72%) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/arm_lower_bwd.png` | 2D Depth Layer (Darkened 72%) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/hand_bwd.png` | 2D Depth Layer (Darkened 72%) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/leg_upper_bwd.png` | 2D Depth Layer (Darkened 72%) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/leg_lower_bwd.png` | 2D Depth Layer (Darkened 72%) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/foot_bwd.png` | 2D Depth Layer (Darkened 72%) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/kai/emblem_purple.png` | 2D Signature Star Emblem (49x44) | ShadowCraft Art Pipeline | Proprietary (Original) | 2026-11-09 | Yes |
| `assets/characters/razen/` | Bespoke Original Art | ShadowCraft Art Team | Proprietary (Original) | Pending Phase 08 | Yes |
| `assets/weapons/` | Bespoke 2D Sprites | ShadowCraft Art Team | Proprietary (Original) | Pending Phase 04 | Yes |
| `assets/arenas/` | Bespoke Parallax Art | ShadowCraft Art Team | Proprietary (Original) | Pending Phase 09 | Yes |
| `assets/enemies/the_initiate/source/guardian_ready_reference.png` | Original image generation; user-provided Initiate reference and approved robotic minion used as design references | OpenAI ImageGen built-in | Proprietary (Original ShadowCraft asset) | 2026-11-14 | Yes |
| `assets/enemies/the_initiate/source/*_sheet.png` | Original pose-sheet generation; reference used for identity/pose guidance only, no reference pixels reused | OpenAI ImageGen built-in | Proprietary (Original ShadowCraft assets) | 2026-11-14 | Yes |
| `assets/enemies/the_initiate/frames/*/*.png` | 512×512 transparent normalized pose frames imported by `scripts/enemies/import_the_initiate_art.py` | ShadowCraft frame pipeline | Proprietary (Original ShadowCraft assets) | 2026-11-14 | Yes |

