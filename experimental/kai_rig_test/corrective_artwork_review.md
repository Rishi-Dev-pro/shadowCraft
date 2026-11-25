# Kai corrective artwork review

**The neutral baseline passes. The articulation milestone remains open.** The new art closes gaps in the chest and reduces the stray cloth at the far hip. The exposed contours still fail at the requested −130° shoulder, −38° thigh, overhead, deep crouch and raised-knee samples.

## Artwork

The revision lives in `res://assets/characters/kai_hidden_artwork_v2/`. The `underpainting` directory holds the transparent source patches. The `layers` directory holds the registered texture replacements for the lab. `repair_registration.json` records donor frames, anchor coordinates, masks, coverage and part ownership.

- **Chest and underarm.** Registered the painted landing chest and armhole in the exposed near-side torso area. Extended the fabric beneath the belt.
- **Inner sleeves.** Restored both inner sleeve returns from landing artwork. The new torso paint stays attached to the chest when the forearm swings away.
- **Waist, hips and seat.** Used the low landing and tucked-jump fabric to paint behind the sash and inner thigh. Added a pelvis-mounted underpaint behind the two legs. Returned 999 pixels of a misassigned inner front-flap fragment to the existing pelvis layer. The sash knot and visible approved flap remain the neutral reference.
- **Knees and ankles.** Added compressed cloth returns at both trouser cuffs and extensions to the armour above both boot collars.

The authored masks and alpha recomposition apply inside covered neutral overlaps. The CPU assembly retains all approved visible RGBA values and identical alpha coverage. The lab uses the same pivots, angles, test presets, camera and registered scale for both revisions.

## Rendered visual verdicts

The values below are sampled local offsets. A smaller usable sample is evidence for that pose only. The lab retains its original ranges.

| Joint or pose | Verdict | What the rendered image shows |
|---|---|---|
| Right shoulder −35° | PASS | The shoulder silhouette holds and the underarm stays covered. |
| Right shoulder −130° | FAIL | The chest opening is closed. The exposed armhole ends in a sharply traced contour and the paint meets the original lapel at a visible tonal break. |
| Both arms overhead | FAIL | The shoulders and inner sleeves still show cut edges. The right chest continuity is improved. |
| Forward extension | FAIL | The main opening is covered. The underarm has a flat side boundary and the shoulder rim still reads separately. |
| Defensive guard | PASS | Both arms and the upper torso read as one at the tested guard position. |
| Right elbow +35° and raised forearm −70° | PARTIAL | The chest is continuous at both samples. The shoulder-side shading and inner elbow edge are visible at −70°. Use the moderate +35° sample for review. |
| Left elbow | PARTIAL | +35° is visually coherent. The large bend still exposes the inner cuff edge. |
| Left shoulder | PARTIAL | Small offsets around ±10° remain viable. The far sleeve edge separates when raised overhead. |
| Wrists | PARTIAL | Small offsets around ±10° stay attached. Larger bends with hand translation still show the existing cuff seam. |
| Chest and spine | PARTIAL | Moderate lean remains readable. At +25° of chest rotation a hard crease appears where the waist meets the belt. |
| Neck | PARTIAL | Small offsets around ±10° remain viable. The large turn still exposes the existing collar join. |
| Head and headband | PASS | The head and knot stay attached at the reviewed endpoints, ±30° and ±65° respectively. |
| Pelvis, +24 px and +10° | PASS | The isolated pelvis sample preserves the waist silhouette. The planted crouch is evaluated separately. |
| Waist sash +35° | PARTIAL | The exposed fabric has trouser volume. The upper fold under the sash keeps a dark, hard edge. |
| Left thigh −38° | FAIL | The long swinging cloth tab is gone. A triangular transition and a hard seam remain at the groin. Small offsets around ±10° remain usable. |
| Right thigh | PARTIAL | Small offsets around ±10° remain usable. The outer hip under the sash separates at greater planted flexion. |
| Raised knee | FAIL | The long tab is gone. The exposed inner-thigh folds end abruptly and a seam remains near the shin. |
| Deep crouch | FAIL | The near hip and knee still have a hard folded edge. The cloth beneath the sash separates from the trouser silhouette. |
| Both knees bent and wide stance | FAIL | Less loose material hangs between the legs. The front flap and supporting inner-thigh folds still stack visibly at the groin. |
| Left knee +35° and right knee −35° | PARTIAL | Moderate bends remain connected. The cloth-to-armour contour breaks under deep compression. |
| Left and right ankles +20° | PASS | The boot collar remains attached at the moderate samples. The wider ±40° limits still expose the existing rigid cuff edge. |

## Paint needed for the remaining poses

- **Extreme shoulder and elbow:** A matching three-quarter view of Kai with his right arm horizontal and above his head. It must expose the sleeve cap, complete armpit and side chest. The same material is needed on the inner elbow and cuff with the arm in deep flexion. Existing landing and stagger frames provide cloth and rim lighting, with the crucial armhole surfaces still partly occluded or seen at a different angle.
- **Pelvis and thighs:** A continuous painted seat and groin under an independently layered front flap and sash. The raised-knee and planted crouch versions need inner-thigh compression folds and intact outside hip contours. The approved crouch and jump references remain composited and occlude those folds.
- **Deep knee and ankle:** A compressed trouser cuff fitted to the original shin guard and a boot collar exposed in deeper rotation. Moderate overlaps can reuse the existing paint.

## Verification

Godot 4.7.2 Compatibility produced the original framing at every sampled pose. The comparison set contains 21 native-resolution close-ups with differences against the previous attempt, and all 63 uncut source captures. The engine kept the neutral and reset comparisons within 1/255 per channel. The rig runner passed 61 checks and the headless Grind regression passed 25. The reference scan found zero errors and five pre-existing orphan UID warnings. The 22 original artwork and registration hashes matched. The work stays in the static test lab and its new art directory.

Run `res://experimental/kai_rig_test/kai_rig_lab.tscn` with F6 and toggle **Use repaired layers** to inspect the revision at the same pose.
