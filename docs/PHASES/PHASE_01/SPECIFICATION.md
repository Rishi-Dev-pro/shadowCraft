# PHASE 01 SPECIFICATION: KAI 2D CHARACTER ART & ANIMATION PIPELINE

> **Phase Identifier:** PHASE-01  
> **Status:** IN PROGRESS (AUTHORIZED)  
> **Target Release:** v0.2.0  
> **Lead Architect:** Technical Director & Lead Game Architect

---

## 1. PURPOSE & OBJECTIVES

The objective of Phase 01 is to establish the production-quality 2D character pipeline for ShadowCraft 2D and implement the protagonist, **Kai — The Shadow Disciple**.

Kai represents the agile martial arts archetype of the game. His visual presentation must combine traditional ninja/shinobi aesthetics with readable shadow anatomy, dark fitted martial arts attire, and controlled purple emissive accents.

### Core Deliverables:
1. **Original 2D Character Artwork:**
   - Transparent 32-bit PNG sprites for every anatomical segment (head/mask/hair, torso/chest emblem, waist cloth/sash, upper/lower arms, hands, upper/lower legs, feet).
   - Natural human proportions avoiding any blocky, voxel, robotic, or disconnected forms.
2. **2D Skeletal Hierarchy (`Skeleton2D` + `Bone2D`):**
   - Humanoid bone hierarchy rooted at ground level `(0, 0)`.
   - Precise pivot placement at anatomical joints (hips, neck, shoulders, elbows, wrists, knees, ankles).
   - Seamless overlap between adjacent limbs to eliminate gaps during deformation.
   - Weapon attachment socket (`Marker2D` named `Socket_Weapon`) attached to the front hand bone.
3. **Locomotion Animation Suite (`AnimationPlayer`):**
   - `loco/idle`: Natural breathing cycle, weight shift, combat readiness.
   - `loco/walk_fwd`: Disciplined martial forward stride.
   - `loco/walk_bwd`: Defensive backward retreat.
   - `loco/crouch`: Low martial stance.
4. **Godot Scene & Data Integration:**
   - `scenes/characters/Kai.tscn`: Root `CharacterBody2D` with visual rig, `Skeleton2D`, `Bone2D` hierarchy, `AnimationPlayer`, and collision shape.
   - `resources/characters/kai.tres`: `CharacterData` definition holding base attributes and identity parameters.
   - `scenes/arenas/KaiPreview.tscn`: Clean preview scene allowing visual inspection of all 4 animation cycles under fixed camera framing.
5. **Visual Verification & Audit:**
   - Captured in-engine screenshots of all states.
   - Two-pass audit (Pass 1: Architecture & Consistency; Pass 2: Quality & Completeness).
   - Strict stop before Phase 02.

---

## 2. STRICT SCOPE LIMITS

### Permitted in Phase 01:
- 2D character sprites, textures, and sprite sheets.
- `Skeleton2D` rigging, `Bone2D` configuration, and `AnimationPlayer` tracks.
- Locomotion animations (`idle`, `walk_fwd`, `walk_bwd`, `crouch`).
- `CharacterData` resource and character packed scenes.
- 2D character preview scene for visual inspection and screenshot capture.
- Automated validation tests for rig hierarchy, bone names, and animation tracks.

### Strictly Prohibited in Phase 01:
- Developing antagonist Razen (reserved for Phase 08).
- Implementing weapon sprites or attack movesets (reserved for Phase 04).
- Implementing gameplay player movement controllers or input bindings (Phase 02).
- Implementing combat damage, hitboxes, hurtboxes, or health logic (Phase 03).
- Any 3D nodes, 3D meshes, or 3D rendering.
- Touching or modifying the archived 3D prototype in `..\exp-1`.
