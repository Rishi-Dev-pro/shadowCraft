# Kai hidden artwork stress review

The neutral visual gate passed. The articulation gate remains open for the overhead reach, deep crouch, and large hip, elbow, and cuff rotations. Keep this revision in the static rig lab.

## Artwork revision

`res://assets/characters/kai_hidden_artwork_repair/` contains the repaired layers, an assembled PNG, and `repair_registration.json`. The manifest lists 19 registered layers, their original pivots, and the donor frames and retained pixels for each reconstruction. Eighteen revised PNGs and one approved-source PNG make up the revision.

| Region | Reconstructed paint |
|---|---|
| Right shoulder and chest | Near-side underarm and the chest concealed by the forearm, registered to the torso so the paint stays with the chest when the arm moves. |
| Elbows and inner sleeves | Inner returns on both sleeves and an overlap at the far wrist. The near wrist retains its original cuff construction. |
| Lower torso, waist, and pelvis | Overlap behind the belt, near hip behind the sash, and far hip behind the front flap. |
| Thighs and knees | Inner-thigh coverage and short compression folds where the trouser hems meet the shin guards. |
| Boots and ankles | Hidden boot-collar returns under both shin guards. |
| Neck and collar | Inner collar overlap behind the neutral neck. |

The donors are the original painted landing, idle, and walking frames. The source art includes usable fabric and armour at moderate bends. It lacks a continuous matching overhead shoulder cap and armpit, a high-flex inner elbow and cuff, and a complete compressed hip, seat, and knee silhouette. Those ranges retain their defects.

## Joint-by-joint visual results

Angles are local offsets from the approved pose. Values describe rendered samples. PASS means clean through the reviewed range, PARTIAL means usable at lower offsets with a visible limit, and FAIL means a priority movement still exposes a major contour defect. Left is Kai's far side in the approved pose.

| Joint or layer | Before | Repaired | Rendered result and limit |
|---|---|---|---|
| Left shoulder | PARTIAL | PARTIAL | Small offsets around ±10° hold. The far sleeve edge separates in the large raise. A continuous far armpit and rear sleeve cap are still missing. |
| Right shoulder | FAIL | FAIL | −35° has a continuous body silhouette. At −130° the chest is filled in, but the raised arm exposes a flat underarm edge and a mismatch at the shoulder cap. The overhead pose still fails. |
| Left elbow | PARTIAL | PARTIAL | The +35° sample retains the inner sleeve. At +155° the cuff and inner sleeve no longer describe a continuous bend. |
| Right elbow | FAIL | PARTIAL | The chest opening at +35° is filled. A change in shading is visible at the inner elbow. Very large bends still need a painted flex or extension shape across the elbow and bracer. |
| Left wrist and hand | PARTIAL | PARTIAL | Small rotations stay attached. The +60° sample with translation still exposes the cuff boundary. |
| Right wrist and hand | PARTIAL | PARTIAL | Small rotations stay attached. Outward translation still exposes the glove and bracer boundary. A dedicated near-side cuff return is still missing. |
| Chest rotation | PARTIAL | PARTIAL | The lower torso overlaps the belt at +25°, with a small hard edge at the exposed side. Large rotations need a continuous waist transition. |
| Spine lean | PARTIAL | PARTIAL | Moderate static lean holds together. The ±25° samples still show a waist and belt transition. |
| Neck rotation | PARTIAL | PARTIAL | Small rotation stays connected. At +30° the head and neck still meet the folded collar at a sharp angle. |
| Head rotation | PASS | PASS | The mask and head silhouette remain coherent at the ±30° samples. |
| Pelvis and belt | PARTIAL | PARTIAL | Small movement and the isolated translation remain readable. The planted deep crouch exposes stacked hip folds and cloth intersections. |
| Left hip and thigh | PARTIAL | PARTIAL | Added paint covers part of the exposed hip at −38°. The hard inner-thigh fold and front flap remain apparent in the raised-knee pose. |
| Right hip and thigh | PARTIAL | PARTIAL | Small rotation keeps the join. The outer contour and independent sash still stack at +55° and in the wide stance. |
| Left knee | PARTIAL | PARTIAL | The +35° sample retains the trouser cuff. At +100° the shin crosses the thigh with a hard fold edge. |
| Right knee | PARTIAL | PARTIAL | The −35° sample stays connected, with a small edge visible behind the shin plate. At −100° the lower leg still reads as a separate shape. |
| Left ankle and boot | PARTIAL | PARTIAL | +20° stays attached. Near +40° the join at the boot rim still reads sharply. |
| Right ankle and boot | PARTIAL | PARTIAL | +20° stays attached. Near +40° the rigid cuff and boot silhouette still break visually. |
| Waist sash | FAIL | PARTIAL | At +35° the removed sash reveals fabric instead of the original large cutout. A dark edge remains at the outer thigh, and the ±65° samples cross the costume silhouette. |
| Headband tails | PASS | PASS | The tie remains attached through the ±65° samples. |

The defensive guard reads cleanly at full-character scale. The forward extension fills most of the original chest opening and still exposes a hard underarm edge. Both arms overhead, deep crouch, raised knee, and wide stance remain useful stress poses with visible edge or overlap defects.

## Verification

- Independently recomposited all 19 registered PNGs from disk. The neutral pose has zero differing visible RGBA pixels and identical alpha coverage against the approved assembly. All 22 recorded source and reference hashes match.
- Ran the static lab in Godot 4.7.2 Compatibility and visually reviewed the rendered neutral, joint close-ups, and pose comparisons. The repaired run passed 61 automated checks. The player-facing neutral result and reset were within one channel step out of 255, across 8,878 pixels with any difference. Automated checks validate switching, transforms, and pixel tolerance. The grades above reflect visual inspection.
- Project reference scan returned zero errors and five pre-existing orphan UID warnings. The existing Grind integration test passed 25 checks.
- Architecture audit found only the experimental art and the existing 2D lab involved. The quality audit verified import paths, preserved source hashes, reset, and no staged files.

Open `res://experimental/kai_rig_test/kai_rig_lab.tscn` and run it with F6. Switch **Use repaired layers** on or off while holding a pose to compare the same joint angles. To repeat the rendered checks, run `godot --path . --script res://experimental/kai_rig_test/verify_lab.gd -- --repaired-art`. Set `KAI_RIG_CAPTURE_DIR` to an existing directory to save the PNGs.
