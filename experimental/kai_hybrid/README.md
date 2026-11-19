# Kai hybrid pose lab

Open `kai_hybrid_lab.tscn` and press F6 in Godot 4.7.2. Select a pose to hold its endpoint. **Play Transition** or **Restart** runs from neutral through the selected pose and back to neutral. **Pause** and the speed slider support frame inspection. The original preview holds the painted reference for guard because the current Kai SpriteFrames resource has no authored guard clip.

## Attack animation previews

Use **Light Attack**, **Heavy Attack**, or **Front Kick** from neutral, idle, or held guard. **Heavy Punch** still opens the approved pose preview. The status shows the current attack phase and any queued punch. The last 120 ms of Light Attack accepts one Light Attack or Heavy Attack. The next attack starts after recovery. Press **Guard** before recovery to return to guard, or let the attack settle into idle. **Reset** clears the active attack and buffer.

| Preview | First impact | Recovery begins | Total at 1× |
|---|---:|---:|---:|
| Light Attack | 113 ms | 216 ms | 350 ms |
| Heavy Attack | 279 ms | 492 ms | 700 ms |
| Front Kick | 228 ms | 462 ms | 636 ms |

`attack_motion.gd` defines phase times and buffer eligibility. The rig handles entry and recovery. A single correction surface uses registered painted keys from the original jab, heavy punch and kick art during the strike. The kick uses the rear boot as its registration anchor. The heavy impact uses the approved Heavy Punch texture directly. Four fast pose changes use stepped painted keys where interpolating overlapping limbs tore the contour in the rendered preview. No gameplay hit logic is connected.

To capture the attack routes, set `KAI_ATTACK_CAPTURE_DIR` to a writable directory and run `godot --path . --script res://experimental/kai_hybrid/verify_attacks.gd` in a visible Godot instance. To rebake the attack-only textures, render the rig anchors with `capture_attack_anchors.gd` and `KAI_ATTACK_ANCHOR_DIR`, then run `python -B experimental/kai_hybrid/prepare_attack_art.py <anchor-directory>`.

## Dash and evasion

Use **Forward Dash**, **Backward Dash**, or **Evasive Dash** from neutral, idle, either walk, or guard. During the dash, **Idle**, **Guard**, either walk button, and **Stop** choose the recovery exit. With no change, Kai returns to the stance or walk he came from. The status line shows preparation, the directional burst, and recovery. **Reset** clears the lab travel and returns to the approved neutral.

| Motion | Native travel | Preparation | Burst | Recovery |
|---|---:|---:|---:|---:|
| Forward | +220 px | 52 ms | 270 ms | 190 ms |
| Backward | −180 px | 63 ms | 245 ms | 210 ms |
| Low evasion | −140 px | 72 ms | 290 ms | 235 ms |

`dash_distances.gd` is the single place to tune the three world distances. The lab displays actual travel against the configured distance. The camera follows Kai, so screen displacement differs from world displacement. `dash_motion.gd` retains the original acceleration curve and pose stride. The longer world travel may show some boot glide relative to the floor marks because the authored foot contacts are evaluated in pose space.

Dash requests are rejected during flight or an active dash, including recovery. Movement reaches its full distance before recovery unless a layer-1 physics body in the hybrid Stage blocks the lab dash collider. On contact, travel stops and the existing pose timing continues. Set `KAI_DASH_CAPTURE_DIR` to an existing writable directory and run `godot --path . --script res://experimental/kai_hybrid/verify_dash.gd` for rendered distance and support checks at 60 Hz and a thin-wall test in both directions.

## Jump and landing

**Jump** plays a vertical jump in the preview. While Kai is in the jump, use **Idle**, **Guard**, **Forward Walk**, or **Backward Walk** to choose the exit after landing recovery. Press **Jump** again to queue a second jump. A jump started from animated idle returns to idle by default. **Pause** and the speed slider work during every phase.

`jump_motion.gd` supplies six phases, a 120 ms preparation, 740 ms of ballistic travel, and 330 ms of landing and recovery. The center of the arc continues under gravity through the airborne pose. The lead knee gathers while the rear boot trails. The front leg extends on descent, and the torso and arms brace before contact. Both feet return to their neutral targets for the landing compression. The sash and headband follow through as Kai settles. The preview uses the existing artwork and joint scales.

The lift is vertical in this lab. Walking starts after recovery. The upper-body guard and airborne tuck keep rotations within the cutout rig's useful range. A faint trouser-to-shin seam is visible in some tuck frames.

Set `KAI_JUMP_CAPTURE_DIR` to a writable directory and run `godot --path . --script res://experimental/kai_hybrid/verify_jump.gd` for 60 Hz rendered samples of the six phases, repeat jumps, and every queued exit. The runner also checks ground contact, unit scale, and return to the approved neutral.

## Idle and secondary motion

**Idle** starts the breathing loop. **Reset** shows the exact still neutral reference. From animated idle, either walk can start and settle back to idle with **Stop**. Selecting Guard, Heavy Punch, or Deep Crouch from animated idle plays the approved round trip and resumes idle. To hold a pose for inspection, select it from Reset. **Pause** freezes idle at its current phase, **Play Transition** resumes it, and **Restart** begins the loop again.

`idle_motion.gd` schedules a 22.8-second sequence of still holds, three different breaths, two brief looks, and one deliberate weight adjustment. Breathing is local to the chest and shoulders, with the neck compensating so the helmet does not rise with each breath. The pelvis moves less than two native pixels during the single weight shift. The existing leg solver keeps both boots planted. The sash and headband respond to changes of the hip and head respectively, and return to rest as their attachments settle. The idle exit uses the same 0.18-second blend to approved neutral before the next motion.

The Godot Compatibility capture samples the full cycle and its wrap at gameplay scale. The capture runner verifies six fully still intervals, the active look at equivalent phases one loop apart, planted feet, and transition exits during breath, gaze, and weight adjustment. The existing rear trouser-cuff crease in some walk samples and the crouch handoff ripple remain visible in their approved routes.

Set `KAI_IDLE_CAPTURE_DIR` to an existing writable directory and run `godot --path . --script res://experimental/kai_hybrid/verify_idle.gd` to reproduce the 30 Hz capture and contact checks.

## Locomotion review

**Forward Walk** and **Backward Walk** play continuously. Click the other direction to reverse. **Idle** or **Stop** completes the current stance and settles into neutral. **Guard** finishes the active step and raises the approved guard. Either walk can start from guard. Pause and the speed setting apply to the walk preview.

`walk_cycle.gd` generates contact and swing targets for `hybrid_body.gd`. Forward starts with the front boot and uses a longer stride. Backward starts with the rear boot, has a longer trail step, and keeps the arms closer to guard. Both preserve the painted fighting orientation. The rig solves the leg lengths without scaling, and applies restrained hip, spine, arm, sash, and headband motion. The test viewport follows the root so the character stays aligned beside the approved reference. The floor marks represent the moving world under the contact foot.

| Movement or transition | Review |
|---|---|
| Forward walk | PASS. The front boot leads, followed by the rear boot. The gait is compact to retain the wide combat silhouette. |
| Backward walk | PASS. The rear boot leads and the head stays oriented toward the opponent. |
| Idle to forward and forward to idle | PASS. Entry and settlement preserve the planted foot and character scale. |
| Idle to backward and backward to idle | PASS. The retreat starts with the rear foot and settles into the same facing stance. |
| Forward to backward and backward to forward | PARTIAL. The stance carries through without a visible pose snap. Reversal can wait for the rest of the current two-step cycle, up to 0.84 seconds at 1×. |
| Forward to guard and backward to guard | PASS. The arms begin closing during the last step and reach the authored guard after both feet settle. |
| Guard to forward and guard to backward | PASS. The arm blend starts from the approved guard and lowers into the selected walk. |

The original cutout still shows a brief light crease at the rear trouser-to-shin join on some swing frames. Intended planted targets were met within 0.0001 native pixels across the captured transitions. Neutral, guard, heavy punch, and deep crouch matched the previous artwork and floor renders pixel-for-pixel across 116 comparison images. The controls were also exercised in the visible Godot lab.

Set `KAI_WALK_CAPTURE_DIR` to an existing writable directory and run `godot --path . --script res://experimental/kai_hybrid/verify_walk.gd` to capture all ten transitions at 30 samples per second and verify the foot targets.

## Architecture

- `hybrid_body.tscn` instances the existing 23-bone rig. Neutral uses the 19 approved cutouts. Planted leg targets support the moderate crouch, weight transfer, and small forward and backward steps. No bones are scaled. The guard and early crouch use the experimental hidden overlap revision where its motion is moderate.
- `hybrid_controller.gd` owns entry, hold, and recovery on one clock. It animates the headband, waist sash, and subtle breathing on the skeletal surface. Secondary motion eases out at a painted handoff. The painted sash and headband are part of the source pose during corrections.
- `correction_renderer.gd` caches the registered art and displacement textures. The heavy punch uses existing painted references 02, 04, and 05. The crouch uses references 01 and 03. At wide joint angles the whole character surface takes over because both actions change the pelvis, clothing, and limb overlaps together. The native skeletal handoff render is the first correction key. The correction shader aligns adjacent painted poses and lets a single sample own the outer contour.
- Both comparison panes use native 512 × 512 transparent renders, identical facing and floor registration, then the same 0.7 display scale at 1280 × 720. The anchor frames are rendered in Godot. A constant, uniform registration per pose family aligns painted references without applying runtime proportion changes.

## Visual acceptance

| Pose | Result | Rendered finding |
|---|---|---|
| Neutral | PASS | The original and hybrid preserve the same silhouette and painted features. The two native Godot surfaces differ by at most 1/255 per channel at launch and after reset. Downsampling to the displayed game scale yields a maximum of 2/255. |
| Defensive guard | PASS | The tested guard raises both forearms cleanly, with connected shoulders and elbow contours through entry and return. The reference pane uses the approved combat-ready idle for this comparison. |
| Heavy punch | FAIL | The painted extension itself reads cleanly. Around 0.40 seconds, the advancing fist and forearm distort during the change in overlap. The reverse traversal exposes the same defect during recovery. A dedicated matched arm-and-torso transition key is needed before accepting it. |
| Deep crouch | PARTIAL | The held painting is approved. The corrected entry and return retain more upper-body mass as the hips lower. A slight inner-fold and sash ripple remains at the handoff. The painted helmet profile and narrower rear-foot stance differ slightly from neutral. |

The experiment proves the neutral, guard, and painted endpoints at this scale. The punch and crouch transition observations above predate the locomotion pass. The approved poses and their animation paths were preserved for the current experiment.

### Crouch proportion correction

The body, correction sprite, and bones retain unit scale. The earlier optical-flow handoff changed local shape while matching the painted keys, which made the upper body appear to shrink. The correction lowers the pelvis by up to 23 source pixels during the skeletal approach, with a small hip and spine tilt and separate planted targets for the boots. Regional translations for the helmet, upper torso, and soles constrain the paint handoff. Local image warping still resolves the knees, cloth folds, and regions between those anchors.

The two painted keys are byte-identical to their approved versions. Their whole-image placements move up four and seven source pixels to register the rear sole to the skeletal floor. The held drawing has a slightly shorter helmet profile and the rear boot is drawn about 41 source pixels inward relative to neutral. The rear boot makes a gradual grounded readjustment to reach that footprint. At the 0.7 display scale, the rear sole stayed within a one-pixel vertical range and the front sole within three pixels across the 30 Hz samples. Boot-pivot height is constant during the skeletal portion.

The Godot captures reproduce neutral, guard and heavy punch pixel-for-pixel against the previous lab, including all 65 guard and punch transition samples. The new crouch playback, scale and floor-height checks passed. The Grind regression passed 25 checks.

## Verification and reproduction

The scene was opened in Godot 4.7.2 Compatibility and the pose and play controls were exercised in the window. The rendered verification runner sampled all three round trips at 30 samples per second and exercised live play, pause, restart, and reset. It reported zero failures. Automated checks measure compositing and route ownership. The verdicts above are based on the rendered images. The existing Grind test passed 25 checks.

To rebuild the baked art, set `KAI_HYBRID_HANDOFF_DIR` to a writable directory and run `godot --path . --script res://experimental/kai_hybrid/capture_handoffs.gd`. Run `python experimental/kai_hybrid/prepare_corrections.py <handoff-directory>` with Pillow, NumPy and OpenCV installed. The Godot lab has no Python runtime dependency.

Use `--crouch-only` to rebuild the crouch handoff and displacement maps while retaining both painted keys and the punch files.

To reproduce the captures, set `KAI_HYBRID_CAPTURE_DIR` to an existing writable directory and run `godot --path . --script res://experimental/kai_hybrid/verify_lab.gd`.
