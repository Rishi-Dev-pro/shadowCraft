# PHASE 01 IMPLEMENTATION PLAN: KAI CHARACTER PIPELINE

> **Phase Identifier:** PHASE-01  
> **Status:** ACTIVE  
> **Source of Truth:** `docs/PHASES/PHASE_01/SPECIFICATION.md`

---

## 1. SEQUENCED EXECUTION STEPS

### Stage 1: Visual Design & Concept Art Creation
- [ ] Step 1.1: Generate original high-resolution 2D concept art for Kai emphasizing athletic human proportions, ninja mask, dark martial attire, and purple accents.
- [ ] Step 1.2: Establish anatomical proportions: 300px total character height for 720p viewport.

### Stage 2: Original 2D Sprite Asset Extraction & Preparation
- [ ] Step 2.1: Author transparent 32-bit PNG limb cutouts with proper joint overlap and anatomical contours:
  - `head.png` (dark hair, ninja mask, subtle purple eyes)
  - `torso.png` (fitted tunic, purple chest star emblem, dark waist belt)
  - `waist_cloth.png` (sash drapery)
  - `arm_upper_fwd.png`, `arm_lower_fwd.png`, `hand_fwd.png`
  - `arm_upper_bwd.png`, `arm_lower_bwd.png`, `hand_bwd.png`
  - `leg_upper_fwd.png`, `leg_lower_fwd.png`, `foot_fwd.png`
  - `leg_upper_bwd.png`, `leg_lower_bwd.png`, `foot_bwd.png`
- [ ] Step 2.2: Place sprites in `assets/characters/kai/` and catalog in `docs/ASSET_GUIDELINES.md`.

### Stage 3: Skeletal Rigging in Godot 4
- [ ] Step 3.1: Define `CharacterData.gd` resource script in `scripts/characters/`.
- [ ] Step 3.2: Create `resources/characters/kai.tres` instance.
- [ ] Step 3.3: Construct `scenes/characters/Kai.tscn`:
  - Root `CharacterBody2D` with ground-contact origin `(0, 0)`.
  - `CollisionShape2D` (capsule roughly 40px width, 260px height).
  - `Visuals` (Node2D) container.
  - `Skeleton2D` with hierarchical `Bone2D` structure:
    `Bone_Root` -> `Bone_Pelvis` -> `Bone_Torso` -> `Bone_Neck` -> `Bone_Head`, plus Arms and Legs.
  - Sockets: `Marker2D` (`Socket_Weapon`) attached to `Bone_Hand_Front`.
  - Sprites attached or deformed with proper Z-index ordering.

### Stage 4: Animation Suite Authoring
- [ ] Step 4.1: Author `loco/idle` (60 FPS, 1.6s loop, subtle breathing rise/fall, natural weight shift).
- [ ] Step 4.2: Author `loco/walk_fwd` (60 FPS, 0.9s loop, synchronized foot-lift, torso dip, counter-arm swing).
- [ ] Step 4.3: Author `loco/walk_bwd` (60 FPS, 0.9s loop, defensive retreat steps, higher guard posture).
- [ ] Step 4.4: Author `loco/crouch` (60 FPS, 0.4s enter into low stance loop, compressed knee angles).

### Stage 5: Preview Scene & Visual Quality Gate
- [ ] Step 5.1: Create `scenes/arenas/KaiPreview.tscn` featuring fixed 2D camera, clean arena backdrop, and interactive/cycle display.
- [ ] Step 5.2: Launch Godot preview to capture genuine in-engine screenshots of:
  1. Full-body idle
  2. Full-body forward walk
  3. Full-body backward walk
  4. Full-body crouch
  5. Character artwork and rig hierarchy
- [ ] Step 5.3: Inspect screenshots; eliminate any mechanical stiffness, clipping, or distortion.

### Stage 6: Testing, Codebase Audits & Phase Closure
- [ ] Step 6.1: Execute automated validation script for bone hierarchy, animation tracks, and sprite paths.
- [ ] Step 6.2: Execute Pass 1 (Architecture & Consistency) and Pass 2 (Quality & Completeness) audits.
- [ ] Step 6.3: Author `docs/PHASES/PHASE_01/COMPLETION_REPORT.md`.
- [ ] Step 6.4: Update roadmap, task board, changelog, and next session docs.
- [ ] Step 6.5: Stage and commit with descriptive Git message.
- [ ] Step 6.6: Enforce strict stop condition.
