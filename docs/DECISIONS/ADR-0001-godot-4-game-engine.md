# ADR-0001: Godot 4 as Game Engine

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
ShadowCraft 2D requires a modern, lightweight, highly performant 2D game engine capable of running on modest Windows hardware (integrated GPUs, low memory consumption) while providing strong 2D skeletal animation, frame-by-frame animation, 2D physics, and rapid iteration. The project is an original 2D weapon-based fighting game with strict requirements against 3D overhead.

## Decision
We select **Godot 4** (specifically v4.3+ / v4.7.2 stable) as the primary game engine for ShadowCraft 2D.

Key driving factors:
1. Native, first-class 2D engine with dedicated 2D pixel coordinates, 2D transform matrices, and specialized 2D physics (`CharacterBody2D`, `Area2D`).
2. Robust animation tooling out of the box (`AnimationPlayer`, `Skeleton2D`, `Bone2D`, `AnimatedSprite2D`).
3. Clean, zero-cost data-driven configuration using custom `Resource` scripts.
4. Open source (MIT license), completely avoiding proprietary royalty fees or telemetry runtime overhead.
5. Fast startup times (< 2 seconds) and headless test execution capability.

## Alternatives Considered
- **Unity:** Heavy runtime footprint, complex licensing changes, bloated 2D package ecosystem that sits on top of a 3D core engine.
- **Unreal Engine 5:** Completely unsuitable for lightweight 2D games; massive binary size, excessive GPU requirements.
- **Custom C++/Raylib/Monogame:** Significantly longer development timeline, lack of built-in animation editor, timeline tools, and scene graph serialization.

## Consequences
- **Positive:** Instant editor loading, lightweight repository size, native 2D pipeline, full access to engine source if needed, smooth headless testing in CI.
- **Negative:** GDScript is engine-specific (mitigated by strict static typing and clean design patterns); smaller commercial ecosystem compared to Unity (mitigated by self-contained architecture).
