# ADR-0010: Lightweight Performance Strategy

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
A critical pillar of ShadowCraft 2D is broad accessibility on modest Windows laptops (such as 8GB RAM machines with dual-core Intel Core i3/i5 processors and Intel HD/UHD integrated graphics). The game must deliver a seamless 60 FPS combat experience without stuttering, thermal throttling, or high battery drain.

## Decision
We enforce a lightweight performance strategy:
1. **Target Budget:**
   - Frame Rate: Consistent 60 FPS (16.6ms frame budget).
   - Baseline Resolution: 1280 × 720 (720p 16:9).
   - Draw Calls: < 50 draw calls per combat arena.
   - Total System RAM: < 350 MB working set.
   - VRAM: < 256 MB.
2. **Batching & Textures:**
   - Combine character cut-outs and combat effects into consolidated sprite atlases to enable Godot 2D automatic batching.
   - Utilize native 2D CanvasItems with integer pixel snapping (`snap_2d_transforms_to_pixel` and `snap_2d_vertices_to_pixel`) to avoid subpixel blur and unnecessary anti-aliasing passes.
3. **Lighting & Particles:**
   - Restrict simultaneous `PointLight2D` nodes to 4 per scene.
   - Limit active 2D particle counts (`GPUParticles2D` / `CPUParticles2D`) to under 200 particles at peak impact.
4. **Demand-Driven Scene Loading:**
   - Preload combat arenas and fighter resources during transitions; never load large disk resources synchronously during active combat frames.

## Alternatives Considered
- **1080p native internal rendering:** Increases fillrate demands by 225% on low-end integrated GPUs without tangible visual benefit for shadow silhouette art.
- **Uncapped frame rate:** Causes thermal throttling and battery drain on portable laptops with zero gameplay advantage over deterministic 60 FPS.

## Consequences
- **Positive:** Smooth, rock-solid 60 FPS on practically any Windows laptop; minimal fan noise; instant scene loading.
- **Negative:** Requires art assets and background designs to adhere strictly to texture atlas limits and resolution budgets.

