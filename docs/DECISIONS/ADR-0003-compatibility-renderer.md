# ADR-0003: Compatibility Renderer

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
Godot 4 provides three rendering backends:
1. **Forward+ (Vulkan):** High-end desktop renderer supporting clustered lighting and heavy 3D features.
2. **Mobile (Vulkan):** Scaled-down Vulkan backend.
3. **Compatibility (OpenGL 3.3 / GLES3):** Universal desktop and mobile fallback using standard OpenGL.

Target hardware includes modest Windows laptops equipped with integrated graphics (e.g., Intel UHD 620, older Iris Xe, AMD Vega integrated graphics). Vulkan drivers on these older laptops frequently suffer from driver crashes, high shader compilation stutter, and significant memory overhead.

## Decision
We configure the project to use the **Compatibility (`gl_compatibility`) renderer** across all platforms.

Configuration in `project.godot`:
```ini
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

## Alternatives Considered
- **Forward+:** Far too heavy for a pure 2D game; causes long shader pipeline cache stalls on startup and poor framerates on integrated graphics.
- **Mobile (Vulkan):** Still introduces Vulkan driver dependency and driver bugs on older Windows 10 machines with legacy Intel drivers.

## Consequences
- **Positive:** Maximum hardware compatibility across almost all Windows laptops manufactured in the last 10 years, rapid startup, zero Vulkan initialization latency, lower GPU memory utilization.
- **Negative:** Advanced 3D rendering features are unavailable, which aligns with our 2D-only architecture.

