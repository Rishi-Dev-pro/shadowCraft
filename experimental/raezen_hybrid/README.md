# Raezen Hybrid Lab

Open and run `raezen_hybrid_lab.tscn` in Godot 4.7.2. The left preview shows the campaign's approved neutral frame. The right preview uses the layered rig or the approved painted sequence named in the status line. Select a motion to inspect its representative pose. Play, pause, change playback speed, scrub, or reset to neutral. Both previews use a 512 × 512 source canvas, 0.72 gameplay scale, and the campaign's six-world-pixel visual offset above the shared floor.

## Artwork and rig

[AUDIT.md](AUDIT.md) records the live SpriteFrames, campaign wiring, and deformation requirements. The lab uses `idle/idle_01.png` as its neutral master. Its 38 registered PNGs comprise 25 neutral surfaces and 13 concealed overlaps. The original artwork supplies the visible pixels. The guard, walk, and idle drawings supply overlap at the shoulder, elbow, belt, both hips, knees, and ankles. The blade is registered separately with painted coverage behind it and a grip wrap beneath the near glove. The master and the campaign asset are untouched.

`art/registration.json` contains exact frame-space pivots, cropped texture origins, and absolute draw depths. The 29 bones are organized as follows. Near and far each have their own set of limb bones.

```text
Skeleton2D
└─ Root
   └─ Pelvis
      ├─ Spine → Chest
      │  ├─ Neck → Head → Hair → HairTip
      │  │  └─ Scarf → ScarfTip
      │  └─ Shoulder → Arm → Elbow → Wrist → Hand (near and far)
      │                                      └─ PrimaryGrip (near only)
      │                                         └─ BladePivot → OffhandGrip, BladeTip
      ├─ Hip → Knee → Foot (near and far)
      ├─ Coat → CoatTip
      └─ Belt
```

The arms use parent-relative rotation. Each three-joint leg can solve against its independently positioned boot, while pelvic compression and root travel stay separate. Hair and scarf tip displacement tapers to zero near their attachments. The primary palm owns the blade position and its local angle. Depth offsets place the blade in or behind other artwork, and an optional second-arm solve aims the far hand at the offhand marker. Sword tips and grips share one pivot. The high-angle source poses on the painted surface carry their own gloves, sword, and effects.

## Motion data

`motion_profiles.json` defines the representative moves. A profile selects a supported state, duration, preview sample, and optional interruption threshold. Continuous keys specify normalized time, root and pelvis offsets, per-foot offsets, named bone angles in degrees, blade angle, depth offset, offhand weight, and hidden-layer weight. Unspecified values return to authored rest. The controller eases between keys, blends between two rig profiles over 0.12 seconds, and applies cloth motion independently. A painted segment may take exclusive visibility during its configured time range. It can use a frame range from the original clip or a selected list of keys. There is no dual exposure during the handoff. Matching silhouettes at painted handoff boundaries remains an authoring requirement.

The state policy blocks ordinary interrupts during committed attack and movement phases, allows a hit or knockback to interrupt them, and allows the jump-to-landing transition late in flight. One clock dispatches named markers in order at their authored time, including planted boots, guard on/off, blade window on/off, contact, recovery, charge and release. Interruption clears the active blade window. Markers are available through `event_fired(event, at_seconds)`. The lab does not instantiate gameplay hitboxes, change collision, or consume campaign input.

## Verification

Run the structural checks with an installed Godot Console binary, shown here as `godot`.

```powershell
godot --headless --path . --script res://experimental/raezen_hybrid/verify_foundation.gd
```

For the rendered pixel comparison and representative pose captures, create an output folder, set `RAEZEN_CAPTURE_DIR`, and run the same script without `--headless`. Add `-- motion` after the script path for every 60 Hz frame. The capture runner checks render ownership, bone transforms and scale, profile timing and events, blade length and grip attachment, a reachable offhand probe, foot target error, and the lab's selection, scrub, speed, pause and reset paths. Rendering checks compare the two native aligned viewports, excluding the review UI. Geometry checks cannot certify painted continuity or detect all clipping.

To regenerate the layers, set `RAEZEN_RUNTIME_MASTER` to a writable PNG path, run `godot --headless --path . --script res://experimental/raezen_hybrid/export_runtime_master.gd`, then run `python experimental/raezen_hybrid/prepare_art.py $env:RAEZEN_RUNTIME_MASTER`. The generator requires Pillow and NumPy. It verifies that the live texture and approved source agree in alpha and painted interior, then reconstructs and compares all 79,949 visible neutral pixels before writing. The rig loads these source PNGs directly so a second import cannot recolour their very-low-alpha boundaries. A future packaged lab would need an explicit lossless texture packaging route for these generated layers.

## Visual review at gameplay scale

The 17 cases were rendered in the Godot 4.7.2 Compatibility viewport. The two native neutral views matched before and after reset with zero differing RGBA pixels. The checks reported a maximum sampled boot target error of 0.0001 source pixels. This measurement describes the position of the boot joints, while the knee painting and floor composition were judged from rendered frames.

| Motion | Visual result | Evidence and limit |
|---|---|---|
| Neutral sword stance | PASS | Identical registered render, including hand, weapon and floor placement. |
| Sword-ready stance | PASS | Modest shoulder and hip movement retains the low grip and silhouette. |
| Forward movement with sword | PARTIAL | Alternating support is visible. Near thigh and knee plates still break their contour during flexion. |
| Backward movement with sword | PARTIAL | Distinct retreat with retained sword direction. The layered armor still shows at the bent knee. |
| Sword guard | PARTIAL | Painted high guard preserves the upper-body silhouette. It supplies two entry keys and a hold, with a visibly stepped raise. |
| Horizontal sword swing | PARTIAL | The original painted sequence preserves the extended hand and blade. Independent depth and grip are unproven through the swing. |
| Vertical sword swing | PARTIAL | The painted raised blade clears the head. The rig has not validated that overhead handoff. |
| Diagonal sword swing | PARTIAL | The painted diagonal slash preserves the original wrist shape. The blade and hand cannot be independently driven in that sequence. |
| Heavy sword attack | PARTIAL | The overhead preparation and broad planted stance read in the source art. That rotation still relies on the full painted correction. |
| Torso hit reaction | PARTIAL | Upper-body recoil stays attached, but the armor overlap still shifts visibly on compression. |
| Knockback | PARTIAL | The painted fall preserves grip and silhouette. A continuous live-rig fall or recovery was not validated. |
| Jump with sword | PARTIAL | Ground clearance and attached low sword are visible. Knee and tasset edges still separate at the airborne bend. |
| Landing and absorption | PARTIAL | Ground contact is visible. Deepest compression still exposes a hard knee contour. |
| Dash with sword | PARTIAL | The painted driving stance reads. It is a motion reference, with no gameplay travel or independently driven recovery. |
| Void Step | PARTIAL | The original stance and painted effect preserve blade readability. The preview retains its baked effects and uses no independent root or blade motion. |
| Void Burst preparation | PARTIAL | The source charge and early release preserve the sword and posture. The painted energy and blade are still one surface. |
| Hair and scarf | PASS | Restrained tip motion stays joined to the original head and collar. |

The architecture and neutral gates pass. Artwork and motion approval remain open. Some leg poses need more complete pose-specific plating and joint underpainting. High-angle sword moves need separable hand, guard and blade corrections aligned at entry and exit. Current painted samples establish the pose and test the correction channel, while the two-hand live rig probe establishes reach and depth structurally only. Keep the experiment isolated until those motions pass visual review.

## Regression

The campaign Raezen suite completed 64 checks with zero failures, including guarding, hitboxes, phase two and defeat. The inherited Executioner suite completed 19 checks with zero failures and emitted its ObjectDB/resource cleanup diagnostics at exit. Campaign content and existing experimental character work were outside the milestone diff.
