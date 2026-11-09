# SHADOWCRAFT 2D — TECHNICAL STACK & TOOLCHAIN

> **Status:** APPROVED BASELINE  
> **Architecture Reference:** `docs/ARCHITECTURE.md`

---

## 1. CORE ENGINE & RUNTIME

| Component | Selection | Specification / Notes |
|---|---|---|
| **Engine** | Godot Engine 4 | v4.3 or higher (verified with Godot 4.7.2 stable official) |
| **Rendering Backend** | GL Compatibility | OpenGL 3.3 / GLES3 driver profile |
| **Programming Language** | GDScript 2.0 | Mandatory static typing, class_name registration |
| **Target Operating System** | Windows 10/11 | 64-bit desktop executable |
| **Physics Subsystem** | Godot 2D Physics | Deterministic 2D collision layers & kinematic sliding |
| **Animation Subsystem** | Native Godot 2D | `AnimationPlayer`, `Skeleton2D`, `Bone2D`, `AnimatedSprite2D` |
| **Audio Subsystem** | Godot AudioServer | Multi-bus audio mixing (Master, Music, SFX, Ambience) |

---

## 2. HARDWARE BASELINE TARGETS

ShadowCraft 2D is engineered to run at a consistent 60 FPS on modest Windows laptops.

### Minimum Supported Hardware
- **Processor:** Intel Core i3-6100U / AMD Ryzen 3 2200U (Dual-Core @ 2.3 GHz or better)
- **Memory (RAM):** 4 GB DDR3/DDR4
- **Graphics (GPU):** Intel HD Graphics 520 / Intel UHD 620 / AMD Radeon Vega 3
- **OpenGL Support:** OpenGL 3.3 compatible drivers
- **Storage:** 500 MB free hard drive or SSD space
- **Display Resolution:** 1366 × 768 or 1920 × 1080 panel (game renders at 1280 × 720 baseline)

### Recommended Hardware
- **Processor:** Intel Core i5-8250U / AMD Ryzen 5 3500U or better
- **Memory (RAM):** 8 GB DDR4
- **Graphics (GPU):** Intel Iris Xe / AMD Radeon Vega 8 / NVIDIA GeForce MX150 or dedicated GPU
- **Display:** 1920 × 1080 @ 60 Hz

---

## 3. DEVELOPMENT TOOLS & LIBRARIES

- **Editor & IDE:** Godot 4 Editor / VS Code with `godot-tools` GDScript extension.
- **Testing Framework:** **GdUnit4** (automated unit and integration testing runner).
- **Version Control:** Git 2.40+ with Git LFS (Large File Storage) enabled for media assets.
- **Continuous Integration:** GitHub Actions running automated headless tests on pull requests and main pushes.
- **Asset Creation (Production Pipeline):**
  - Sprites & Cutouts: Aseprite / Photoshop / Krita (exported to 32-bit transparent PNGs).
  - Audio: Audacity / Reaper (exported to WAV for low-latency SFX, OGG Vorbis for background music).
  - Fonts: Open-source TTF/OTF fonts with permissive SIL Open Font License.

---

## 4. ENGINE CONFIGURATION HIGHLIGHTS

Extracted from `project.godot`:
```ini
[application]
config/name="ShadowCraft 2D"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/vsync/vsync_mode=1

[rendering]
renderer/rendering_method="gl_compatibility"
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```
