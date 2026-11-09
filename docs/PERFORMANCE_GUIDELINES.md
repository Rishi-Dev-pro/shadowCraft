# SHADOWCRAFT 2D — PERFORMANCE & PROFILING GUIDELINES

> **Status:** APPROVED PERFORMANCE BASELINE  
> **Target:** Rock-solid 60 FPS on modest Windows laptops  
> **Source of Truth:** `docs/PROJECT_CONSTITUTION.md` and `docs/DECISIONS/ADR-0010-lightweight-performance-strategy.md`

---

## 1. PERFORMANCE BUDGETS

| Metric | Hard Ceiling | Target Nominal | Measurement Method |
|---|---|---|---|
| **Frame Rate** | Min 58 FPS | Stable 60 FPS | In-engine Monitor & Godot Profiler |
| **Frame Time** | Max 16.6 ms | 10.0 – 12.0 ms | `Performance.TIME_PROCESS` |
| **Physics Tick** | Max 3.0 ms | 1.0 – 1.5 ms | `Performance.TIME_PHYSICS_PROCESS` |
| **Render Tick** | Max 8.0 ms | 4.0 – 6.0 ms | Godot Visual Profiler |
| **Draw Calls** | Max 50 calls | 15 – 30 calls | `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| **System RAM** | Max 400 MB | 200 – 300 MB | Windows Task Manager / OS Monitor |
| **Video Memory (VRAM)** | Max 256 MB | 80 – 150 MB | `Performance.RENDER_VIDEO_MEM_USED` |
| **Startup Time** | Max 3.0 sec | < 1.5 sec | Time to interactive menu |

---

## 2. OPTIMIZATION STRATEGIES FOR 2D

### 1. 2D CanvasItem Batching
- Godot's Compatibility renderer automatically batches draw calls for 2D sprites sharing the same texture atlas, blend mode, and Z-index layer.
- **Rule:** Pack character body parts, weapon accessories, and common combat sparks into unified texture atlases where possible to keep arena draw calls under 30.

### 2. Snap to Pixel & Integer Transforms
- Enabled in `project.godot`:
  ```ini
  [rendering]
  2d/snap/snap_2d_transforms_to_pixel=true
  2d/snap/snap_2d_vertices_to_pixel=true
  ```
- Prevents sub-pixel jitter and eliminates the need for expensive multisample anti-aliasing (MSAA) passes on 2D silhouette geometry.

### 3. Particle Limits
- Cap simultaneous GPU particle systems (`GPUParticles2D`) or CPU particle fallbacks (`CPUParticles2D`) to under 200 active particles per combat arena.
- Sparks and blood/shadow dust bursts must have lifetimes under 0.4 seconds.

### 4. Zero Mid-Fight Disk I/O
- All weapon sprites, attack sounds, and character scenes must be preloaded during arena loading screens.
- Never call `load()` or `ResourceLoader.load()` synchronously inside `_process()` or during active attack frames.

---

## 3. PROFILING & MEASUREMENT METHODOLOGY

Agents and developers must adhere to **Rule 15 of AGENTS.md**: *Never claim performance without measurements.*

### How to Profile Performance in Godot 4:
1. Launch the game or test arena with profiling flags:
   ```powershell
   godot --path . --fixed-fps 60 --print-fps
   ```
2. Inspect Godot Editor's **Debugger -> Monitors**:
   - Track `Time / Process (ms)`
   - Track `Time / Physics (ms)`
   - Track `Raster / Draw Calls`
   - Track `Memory / Dynamic (MB)`
3. Log findings in phase completion reports with concrete numerical metrics.

