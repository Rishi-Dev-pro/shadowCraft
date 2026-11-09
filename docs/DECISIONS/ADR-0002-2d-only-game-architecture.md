# ADR-0002: 2D-Only Game Architecture

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
Previous experimental iterations (including archived 3D prototypes in `exp-1`) explored 3D character meshes and 3D physics. While 3D offers automatic perspective and skeletal retargeting, it introduced massive performance overhead on modest hardware, visual uncanny valley issues for shadow silhouettes, complex collision math, and excessive asset creation pipelines. The core game vision demands crisp, cinematic 2D side-view martial combat.

## Decision
We mandate a **strict 2D-only game architecture**.
All gameplay entities, physics, collision detection, and visual presentation nodes must use Godot's native 2D systems:
- Physics bodies: `CharacterBody2D`, `StaticBody2D`.
- Combat triggers: `Area2D` (`Hitbox2D`, `Hurtbox2D`).
- Animation: `Skeleton2D`, `Bone2D`, `AnimatedSprite2D`, `AnimationPlayer`.
- Lighting: `PointLight2D`, `DirectionalLight2D`.

All 3D nodes (`CharacterBody3D`, `MeshInstance3D`, `Camera3D`, 3D physics) are strictly prohibited.

## Alternatives Considered
- **2.5D (3D Models with Fixed Side-View Camera):** Rejected due to high GPU fillrate requirements, complex lighting calculations, and loss of the handcrafted shadow silhouette aesthetic.
- **Hybrid 3D Arenas with 2D Sprites:** Rejected due to visual inconsistency and unnecessary 3D pipeline overhead.

## Consequences
- **Positive:** Crystal-clear collision detection, trivial pixel-perfect alignment, predictable hitboxes/hurtboxes, superior performance on low-end laptops, and faithful realization of the shadow fighting visual pillar.
- **Negative:** Requires creating 2D directional sprite sheets and 2D skeletal rigs instead of rotating 3D meshes (addressed via our hybrid animation strategy).
