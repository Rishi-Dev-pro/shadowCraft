# Kai rig stress test

Open `res://experimental/kai_rig_test/kai_rig_lab.tscn` in Godot 4.7.2 and run the scene with F6. Select a static pose or an isolated joint. Joint changes start from neutral so adjacent stress tests cannot carry transforms into one another. Pelvis and wrist controls expose translation separately. Left denotes Kai's far side in the approved right-facing view.

## Acceptance

**Hold animation development.** The approved neutral pose is visually intact. The active rig uses the 19 approved PNGs in their registered draw order on 23 Bone2D nodes. The planted presets solve the two leg chains to the selected boot positions with no bone scaling. Deformation exposes missing paint in several important poses.

The neutral GPU comparison against the approved assembled PNG found a maximum difference of one channel step out of 255 across 2,863 pixels in Godot's Compatibility renderer. Reset returned the same result. Those small differences come from compositing the separate partially transparent layers in the renderer. The approved artwork and registration files retained their recorded SHA-256 hashes.

## Joint-by-joint visual results

Angles are local offsets from the approved painted pose. The quoted values are inspected samples. They are separate from the executable control ranges. A passing control only certifies the requested transform. The grades below reflect rendered artwork.

| Joint or layer | Grade | Rendered result | Artwork or rig work needed |
|---|---|---|---|
| Left shoulder and upper arm | PARTIAL | ±10° stays coherent. At −35°, an underarm flap is exposed. Higher rotation separates the far sleeve from the torso. | Paint the far armpit and rear sleeve cap in the approved view. |
| Right shoulder and upper arm | FAIL | Small offsets retain most of the silhouette. The −130° extension and overhead raise expose a broad underarm and chest cutout. | Paint the near shoulder cap, armpit and continuous chest underneath it. |
| Left elbow | PARTIAL | ±10° remains connected. At −70° the pieces overlap sharply. At +155° the inner bend loses its continuous contour. | Add an inner sleeve and cuff underlay for the flex and extension transitions. |
| Right elbow | FAIL | A dark cut is visible under the arm at −10°. The exposed hole in the painted torso is clear at +35° and grows in larger bends. | Paint the torso concealed by the neutral forearm and add a continuous inner elbow bridge. |
| Left wrist and hand | PARTIAL | ±10° rotation alone looks connected. +60° with a 6 px hand offset reveals a hard cuff boundary. | Extend the glove and cuff beneath one another for larger changes. |
| Right wrist and hand | PARTIAL | ±10° rotation alone remains readable. An 8 px outward hand shift reveals the mitten and bracer join. | Extend the glove cuff and bracer underlap around the wrist pivot. |
| Chest rotation | PARTIAL | ±10° is visually usable. At +25° the torso lifts away from the belt. | Paint the lower torso behind the belt. Evaluate a short weighted waist transition once the paint is available. |
| Spine lean | PARTIAL | Small offsets hold the costume together. Leaning to the ±25° end samples reveals the lower torso and belt boundary. | Share the lower torso underlay with the chest and anchor deformation around the waist. |
| Neck rotation | PARTIAL | ±10° looks attached. At +30° the rotated neck meets the collar at a sharp edge. | Add overlapping neck and inner-collar paint. |
| Head rotation | PASS | The mask silhouette and visible neck connection stay legible at the inspected ±30° end samples. | None for the tested nod range. |
| Pelvis and belt | PARTIAL | Isolated translation and small tilt remain cohesive. The planted 64 px crouch exposes breaks and stacked cut edges along the hip and sash. | Paint continuous waist and seat folds under the belt, front flap and sash. |
| Left hip and thigh | PARTIAL | ±10° preserves the join. At −38° the groin fold pulls out as a narrow painted tab. A raised knee exposes the top of the thigh. | Extend the far inner thigh and hip folds beneath the front flap. |
| Right hip and thigh | PARTIAL | ±10° is usable. At +55° and in the planted wide stance, the sash and upper-leg contours split into separate pieces. | Paint the trousers under the sash and add a near-hip overlap. |
| Left knee | PARTIAL | ±10° preserves the knee cuff. At +100° the shin folds across the thigh and the inside contour breaks. | Add compressed trouser folds and an inner cuff for deep flexion. |
| Right knee | PARTIAL | ±10° stays attached. At −100° the shin plate and folded cloth expose the straight joint seam. | Add a matching deep-flexion fold and underlap between the cloth and shin plate. |
| Left ankle and boot | PARTIAL | The joint is connected at ±10°. The ±40° end samples show an abrupt break at the boot rim under the shin plate. | Extend the boot collar under the shin armour. |
| Right ankle and boot | PARTIAL | The joint holds at ±10°. At the ±40° end samples the boot toe and cuff read as a separate cutout. | Extend the near boot collar and check the pivot against the folded ankle paint. |
| Waist sash | FAIL | At +35° the sash stays mounted to the belt but exposes a large missing patch of hip paint. | Paint a complete hip underlay matching the approved trousers and belt shading. |
| Headband tails | PASS | The knot remains attached in the tested ±65° samples. The tails can tuck behind the shoulder in the negative direction. | None for the tested swing. |

## Rendered poses

Neutral shows the approved silhouette. The forward and backward leans and defensive guard work as inspection poses, with a limited waist and upper-arm range. Both arms overhead and forward extension reveal the chest and sleeve voids. The raised knee exposes the far hip. Deep crouch, both knees bent and the wide stance reveal overlapping hip folds and trouser cuts even with both boots correctly positioned.

## Verification

- Godot 4.7.2 Compatibility ran the 1280 × 720 lab. The automated runner passed 60 checks, including both initial and reset renderer comparisons, 19 isolated joint selections, secondary controls, nine non-neutral presets and three planted stances.
- Visual review covered the rendered poses and the isolated tests at ±10°, their sample values and end ranges. The screenshots retain visible defects for review.
- Verified hashes for the 19 approved PNG layers, layer registration, assembled reference and original frame master. The project reference check reported zero errors and five pre-existing orphan UID warnings. The existing Grind battle suite passed 25 checks.
- The lab and its verification runner are isolated under `experimental/kai_rig_test/`.

To rerun the checks, use `godot --path . --script res://experimental/kai_rig_test/verify_lab.gd`. Set `KAI_RIG_CAPTURE_DIR` to an existing output directory to save the rendered PNGs.
