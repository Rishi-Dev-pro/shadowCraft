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

`motion_profiles.json` defines the representative moves. A profile selects a supported state, duration, preview sample, and optional interruption threshold. Continuous keys specify normalized time, root and pelvis offsets, per-foot offsets, named bone angles in degrees, blade angle, depth offset, offhand weight, and hidden-layer weight. Unspecified values return to authored rest. A painted segment takes exclusive visibility during its configured time range. It can use the complete clip or a selected list of keys. Matching silhouettes at larger painted handoff boundaries remains an authoring requirement.

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

## Targeted painted-frame repair

The original lab baseline is commit `44345e0`. Void Burst frames 04, 05, 08 and 09 reproduce the hard rear scarf edge in their approved runtime PNGs. The full painted frame owns the visible pose in this segment. Its rig and blade sockets are hidden. The original batch 05 sheet supplies the cut-off scarf and cloak contours. The lab overrides these four frames only and retains the original paint through the body, grip, blade and floor.

Knockback frames 01–12 omit painted boot soles, cloth or blade pixels at the normalized image's y=491 boundary. The lab already drew the floor guide 6 world pixels below that point and had no floor collision or mask. The registered batch 06 source supplies the missing lower contours. Each repaired key aligns its lowest substantial painted contact with y=491 while retaining its source scale and horizontal registration. Frame 08 needs transparent preview space to the right for the recovered boot tip. The existing canvas origin, 0.72 scale, floor, timing, events, and original prone ending continue to apply. There is no get-up segment in the original preview; Reset returns to neutral.

`art/paint_repairs/` holds the 16 isolated textures. The replacements use one-based filenames and are selected by `restored_frames` in the existing profile. Each moving sword and its hand remain part of the same authored painted frame. The live socket checks are separate and apply to the layered rig.

The before/after Godot Compatibility renders matched exactly for all 772 samples of the 15 unaffected profiles. Changes in the two repaired profiles were confined to the listed frame slots, and the native neutral comparison still reported zero differing pixels. The rendered runner passed 101 checks and the campaign boss suite passed 64. The knockback still has discrete painted pose changes, especially as the planted boot gives way to the fall.

## Void Burst catalogue audit

Both clips belong to the original Raezen SpriteFrames. The campaign uses one Void Burst AttackData. Its phase-one path plays the configured `void_burst` animation. The boss's phase-two override explicitly plays `phase2_void_burst` for that same attack and raises its selection weight when the attack qualifies.

| Property | Preparation / Charge | Main Signature Attack |
|---|---|---|
| Campaign SpriteFrames name | `void_burst` | `phase2_void_burst` |
| Original timing | 20 equal frames at 18 fps, 1.111 s, one shot | 20 equal frames at 18 fps, 1.111 s, one shot |
| Original sequence | Low stance, forward charge, smaller energy release, dissipation and lower guard | Loaded stance, overhead blade and energy coil, extended thrust with a large expanding wave, contraction and lowered blade |
| Campaign role | Phase-one presentation. The lab category describes its relative intensity. | Phase-two signature presentation, selected explicitly by the boss controller. |
| Lab profile | `void_burst`. Keeps the previous four repaired keys and includes the original release and recovery after the former nine-frame excerpt. | `void_burst_main`. Plays the complete signature sequence at the original rate. |

The current catalogue has 18 entries. Both bursts use the authored frame sequence from start to finish with exclusive painted surface ownership. The new local textures recover crop margins from the batch 05 sheet and the user-selected batch 08 phase-two sheet. The replacement pixels preserve the source's sword, hands and effects as a single painted surface. Added transparent canvas space keeps the source registration at the lab's original scale and floor. Run the rendered verifier with `-- burst_comparison` to capture every paired original and lab frame.

The Godot 4.7.2 review checked all 20 paired frames of each burst, with 143 rendered runner checks and 64 campaign checks passing. All 833 samples of the other 16 profiles, including the repaired knockback, matched the preceding lab render pixel for pixel.

## Milestone 11 temporal playback

The baseline already integrated delta and speed. The main visual discontinuities were immediate whole-frame swaps at painted key boundaries, a selector that replaced the outgoing pose before playback, and a rig blend that pulled accumulated travel back to the incoming clip's local origin. The reproduced advance-to-idle transition lost 24 source pixels of horizontal travel. Both 18 fps bursts replaced their entire image at the 50% boundary. The repaired PNGs were also first loaded on demand inside the render path.

Use **Play** to review a motion independently and **Transition** to chain from the displayed motion to the selected destination. **Source steps** disables temporal paint registration and uses the original sampled rig curve. The arrow buttons select adjacent source slots. The progress bar shows transition progress, the status shows elapsed clip time and current source frame, and the menu can cap the live lab at 30, 60, or 120 FPS.

- Continuous sampling uses scaled seconds. The pre-roll has a separate elapsed time so charge, strike, and recovery markers remain at their authored positions in the destination clip. Pause preserves both times. Scrub inspects the destination and clears transition history. Repaired textures are loaded before playback.
- Smooth playback uses monotone Hermite interpolation for the root between existing keys and keeps the prior horizontal world-space boot trajectories. Limbs and weapon rotation take the short angular path. Depth switches discretely. The rig's existing foot solver and hand socket remain authoritative. The outgoing root offset is carried into the next preview so the local curve can start at its own origin.
- `transition_profiles.json` defines eligible state pairs, duration, easing, interruption, root, foot, weapon, and painted handoff policies. Compatible rig motions blend from the sampled outgoing pose. Hair, scarf, and coat use a separate non-oscillating damped curve across those blends. Guard exits can use the campaign's painted `guard_release` key as a short bridge. Rig-to-painted entries can settle through a short live pre-roll, while abrupt impacts and incompatible painted silhouettes use their authored cuts. Ready doubles as the recover-to-stance preview. The knockback clip ends prone and has no authored get-up, so it holds until reset or independent playback.
- Painted source keys stay mutually exclusive. Selected Void Burst boundaries compensate small lateral registration changes with a bounded horizontal translation between key centers. The artwork at each source key center uses its original registration. Preparation applies this around source pairs 06–07, 12–13, and 13–14. Signature applies it around 01–02, 03–04, 04–05, and 09–10. The boundary into the signature thrust retains its sharp original key change. No full-image crossfade, rotation, or scaling is used. Original energy, sword grip, and effect timing stay in the authored frames.

For rendered timeline and transition evidence, use the verifier with `-- motion transitions`. The verifier additionally samples each configured route, checks interrupted pre-roll and preserved movement distance, and compares the same clock instant at 30, 60, and 120 Hz. The painted sequences can still show the cadence of their source poses where adjacent silhouettes differ substantially.

Rendered comparison at 60 samples per second, using zero-based sample numbers. The 11 unlisted standalone profiles matched the previous lab pixel for pixel in the character view. The two bursts were compared with the same repaired textures in discrete source mode to isolate temporal changes.

| Motion | Samples that changed | Reason |
|---|---|---|
| Forward | 1–11, 13–23, 25–35, 37–47 | Continuous root curve and removal of the generic standalone startup blend. |
| Backward | 1–51 | Continuous root curve and removal of the generic standalone startup blend. |
| Jump | 1–46 | Continuous signed root curve through takeoff, apex, and descent. |
| Landing | 0–7 | Independent playback starts at the authored airborne key and descends into contact. |
| Hit | 1–7 | The reaction begins with its authored timing and no unrelated neutral blend. |
| Void Burst preparation | 39–41, 43–44 | Subpixel registration near two adjacent release pairs. |
| Void Burst signature | 9–11, 13–14, 29–31 | Subpixel registration during charge and the overhead hold. |

All 166 configured route pairs passed structural sampling. Fourteen named transitions were rendered for visual review. Both full painted Burst clips were rendered separately. The signature clip finished on key 20 at 1.1111 s of animation time at every combination of 30, 60, and 120 FPS caps and 0.25×, 0.5×, 1×, and 2× playback. At 1×, observed wall durations were 1.133, 1.117, and 1.116 s. Painted-to-painted guard release and hit-to-knockback still show a discrete silhouette change. Their source poses, strike timing, and recovery remain intact.

## Milestone 12 combat handoffs

Standalone playback retains the Milestone 11 keys, timing, scale and textures. The following adjustments apply when using **Transition**.

| Route | Transition interval | Behavior |
|---|---|---|
| Guard → idle, ready, advance, retreat, sword attack, or Burst preparation | 0–150 ms | Keeps the displayed painted guard initially. A raised guard lowers through the registered middle key at 30 ms, then the original release key at 70.5 ms. A short smootherstep rig settle starts at 103.5 ms. The already-lowered guard skips the raised-only middle key. |
| Hit → knockback | 0–66.7 ms after impact | An ease-out live pre-roll retains the sampled torso recoil, planted boot, and attached weapon. The floor-registered knockback begins at source key 1 and keeps its authored fall and prone ending. |
| Advance, retreat, or ready → light, heavy, or sword attack | 0–83.3 ms, then 0–100 ms of authored attack startup | Smoothstep bends into anticipation with the outgoing planted boot held during the rig interval and horizontal root position preserved. A bounded registration of the starting paint decays before contact. |
| Sword attack or Burst → ready, movement, or guard | 0–100 ms after the last attack key | A valid late request queues until the source sequence finishes. The exact outgoing painting is held for the first 18 ms, followed by a smootherstep rig settle. The layer switch remains exclusive. Ready is the lab's recover-to-stance destination. |
| Ready → preparation or main Burst | 0–100 ms | The existing rig entry settles to the selected variant. The main entry widens and shifts its stance to approach the original first key. The main exit uses a separate wider recovery pose to reduce the visible change when switching from its painted final stance. |

The complete Burst charge, release and recovery sequences still play through their 20 authored keys. The patched recovery retains one painted surface until the rig is ready to take over and carries padded paint registration across the boundary. Hair, scarf and coat use the existing damped blend on the rig. Depth and full painted keys remain discrete as designed. Large original differences in armor silhouette and leg width still remain visible at some handoffs.

The original campaign routes a sufficiently strong hit to the same knockback clip and aliases its inherited kick slot to horizontal slash. The lab has one authored hit reaction, one knockback, and no dedicated front kick or get-up. Dedicated heavy and directional hit, kick recovery, and prone recovery are therefore excluded from the executable review. The existing prone hold stays supported.

The before/after review covers 21 supported handoffs plus the complete playback of each Burst. The character viewport matched at all 969 samples across the 18 standalone motions. The live stance probe checked both movement directions with hold error below 0.01 source pixels. Recovery tests verify that an attack finishes before a queued guard, that pausing does not bypass commitment, and that a hit clears the queue. The signature's wide painted stance still differs from the live rig at the ownership change. The entry and exit adjustments reduce that change while leaving the original frames intact.

## Milestone 13 completeness audit and recovery

The Milestone 12 baseline was the existing working tree at `44345e0`, including its unstaged lab edits. The six lab files were recorded before the audit. Godot 4.7.2 Compatibility passed **181 lab checks and 64 campaign checks** before any project edit. The selector showed 18 profiles. Both Void Bursts still used their separate 20-frame source sequences at 18 fps, or 1.1111 seconds per clip. The recovery review used the 1280 × 720 lab, 0.72 display scale, 1× playback, the original floor reference, and the existing 100 ms smootherstep handoff.

### Main Void Burst recovery decision

The initial 18 ms of recovery holds the end of `phase2_void_burst` exactly as displayed. The painted texture uses a 640 px canvas and a 64 px left registration. Samples at 17.99 and 18.01 ms showed exclusive ownership switching to the rig at the configured boundary. The preview's carried world offset remained fixed. On the first rig sample the local root was `(222, 491)`, pelvis `(221, 240)`, chest rotation 7°, and blade pivot rotation 7°. The rig's grip and tip were at approximately `(143, 263)` and `(406, 383)`. The painted ending has a lower hand, longer downstage blade reach, wider stance, and a differently swept hair and cloak silhouette. The rig's foot targets solved at the cut. The visible change comes from the differing illustrations and contact locations at this exclusive surface switch, rather than a world-root reset, texture-edge crop, or detached sword.

**Recovery tuning was deferred.** The wide-stance alignment trial moved the near boot closer in horizontal registration but missed its planted target by 4.82 source pixels and opened the knee contour. A smaller pelvis and shoulder trial retained the baseline boot targets but left the blade and silhouette step visible. Both trials were rendered from temporary, in-memory profile data. The runtime and source artwork retain the Milestone 12 recovery. Further improvement needs an approved transition-only painting that matches both the wide final stance and the rig's hand-to-tip reach on entry.

The rendered review sampled the final painted frame, the switch, the middle of recovery, and the settled idle or sword-ready pose. It also checked the intact preparation release, light-sword recovery, forward-to-heavy entry, and guard release. The original grip remained attached on both visual surfaces and the floor guide stayed fixed. The large main Burst silhouette change remains visible. No new frames, interleaves, or crossfades were introduced.

### Animation coverage

The audit cross-checked all 29 boss SpriteFrames definitions, their backing sequences, the batch 06 hit/knockback/KO sheet inventories, the eight unselected flinch drawings, the boss controller, and possible matches elsewhere in the project. The enemy boss uses `raezan_boss` in project paths. The playable `razen` is a different character.

| Motion | Original source found | Hybrid equivalent | Status | Recommended action |
|---|---|---|---|---|
| Heavy hit | The boss has an eight-frame `hit` flinch and sixteen-frame `knockback`. The unselected drawings belong to the same flinch sheet. The separately named `heavy_hit` art belongs to playable Razen. | Generic Torso Hit Reaction and Knockback. | Missing dedicated clip. | Keep the existing flinch and knockdown behavior. The boss already selects `knockback` for a knockdown reaction. Commission boss-specific artwork only if a separate heavy recoil is approved. |
| Directional hit | The boss shares `hit` and `knockback`. The inherited controller uses the attacker-side sign for displacement and flips the character drawing with facing. The available Raezen sheets supply no distinct directional sequence. | One generic hit and one knockback in the lab's authored facing. | Missing dedicated clip. | Keep the shared reactions and directional movement in the campaign. A distinct directional pose needs approved Raezen-specific artwork and a defined use case. |
| Front kick | The boss binds the inherited kick slot to `horizontal_slash_attack`. Front-kick sheets and attack resources found elsewhere belong to playable characters or other enemies. | Horizontal sword swing is supported in the attacker slot. | Missing. | Keep the existing slash behavior. A boss front kick requires separately approved artwork and move design. |
| Get-up | `knockback` and `death` end prone. The inherited hit state resumes the normal boss state when hitstun expires. The standalone `razen_getup.png` belongs to playable Razen. | Prone hold with no get-up route. | Missing. | Preserve the prone ending in the lab. A continuous return from prone requires a separately approved Raezen get-up sequence with floor contact. |

### Future clip checklist

1. Verify the character, art ownership, source clip name, frame order, frame count, and timing. Preserve the current 18 approved profiles and capture a comparison baseline.
2. Add a unique `id`, readable `title`, an existing supported `state`, the clip duration in `seconds`, and a normalized representative `sample` in `motion_profiles.json`. Add an `interrupt_after` threshold only when the new move warrants one. The lab selector reads the profile list directly.
3. For rig motion, author ordered normalized `keys` at 0 through 1 using frame-space `root`, `pelvis`, `near`, and `far` offsets. Key named joint angles in degrees and optional `underlay`, `blade`, `depth`, and `offhand` values. Check the two resulting world-space boot paths at gameplay scale. Existing `carry_x` routes preserve accumulated horizontal travel at a handoff.
4. For paint, use the existing `paint.clip` and normalized `start` and `end` span. The span samples source frames evenly. Set its duration from the authored rate for uniform holds. An explicit `frames` list uses zero-based slots. A separately approved lab correction uses one-based `restored_frames` and the existing `art/paint_repairs/<clip>_<frame>.png` binding. Check transparent bounds and any `restored_canvas_left` registration. Paint and rig must take exclusive visibility.
5. Use the existing near-palm grip and `BladePivot` for rig motion. Author `blade` as pivot rotation and `depth` for draw order. Use the existing offhand target only when the opposite hand can reach it. When the weapon is baked into a painted key, preserve the painted hand, blade, and effect together on that surface.
6. Add only the supported transitions to `transition_profiles.json`. The first matching state pair supplies the duration, easing, root, feet, weapon, secondary, interruption, and paint policy. Use the existing `entry_pose` or a source-ID-specific `source_poses` correction when the silhouettes need alignment. Supply ordered `events` from the controller's known event names, with normalized time and matched blade-window open/close markers where relevant. The lab emits presentation events independently of the campaign hitboxes.
7. Update the verifier's expected profile count only when the new motion is approved. Add checks for source selection and duration, events, state eligibility, transform and grip stability, painted bounds, planted feet, and interruption or recovery behavior as applicable. Render the full new motion and its handoffs in Compatibility mode, inspect at gameplay scale, compare the protected profile samples, and rerun the campaign suite.

### Regression and scope

The final run again passed **181 rendered lab checks and 64 campaign checks** without errors or warnings. All **969 rendered character-view samples** from the 18 standalone profiles matched Milestone 12 byte for byte. Neutral matched before and after reset, and both complete Burst sequences remained separately selectable and at their original timing. The only project file changed for Milestone 13 was this README. Campaign resources, approved artwork, rig, weapon attachment, lab scripts and transition configuration were untouched. Nothing was staged, committed or pushed.

## Milestone 14 — Reactions, front kick, get-up and Training selection

| Lab motion | Artwork and animation |
| --- | --- |
| Heavy Hit | Raezen's registered rig layers, with a stronger chest and head recoil than the generic hit, planted feet and a recovery to his resting grip. |
| Directional Hit / Rear Directional Hit | Two different recoil poses, with opposite signed travel relative to the current facing. Neither reaction flips the character. |
| Front Kick | Raezen's existing articulated leg layers. The far leg rises, extends, and retracts while the near foot supports his weight. The sword stays mounted throughout. The dummy strike uses one contact marker. |
| Get Up | Starts on the exact final painted frame of Raezen's knockback. Selected registered frames from the same boss sequence resolve the initial lift; the rig takes over to straighten and blend into Sword Ready. The painted section still has visible key changes. |

Get-up is only available from knockback after its source motion completes. The exit uses a 120 ms transition with carried travel and world foot placement. The existing light-attack transition rules handle the kick, and the existing hit rules handle the three new reactions. The new clips use the experiment's own source layers and the original boss's registered knockback art.

### Main Void Burst recovery

The Compatibility render reproduced the discontinuity at the 18 ms surface handoff. Root carry remains stable across the cut. The last painted pose has a wider boot spread, a longer downstage blade reach and different hair and coat silhouettes from the first rig pose. The prior conservative correction still showed this jump, while the wider corrective pose pulled the support foot approximately 4.82 source pixels away from its target. Both the 20 source frames at 18 fps and the recovery configuration were retained. A painted bridge registered to the wide support stance, hand and sword would be required to resolve the discontinuity without abandoning that contact. Existing knee and armor overlap, and stepped guard changes were also retained where changing them would affect the approved reference renders.

### Training Dojo

Enter **World Map → Training** with Kai selected, then use **Switch Character** above the arena. Kai is the default. Selecting Raezen swaps presentation and input on the same physics slot. The dummy, durability, hit count and shared player health carry over. The switch closes the departing presenter before activating the new one, cancels its pending action, and reuses the same Raezen instance on repeat visits. The campaign's character selection stays independent.

With Raezen selected, **A/D** walk in the direction of travel, **Ctrl + A/D** run, and holding **S + A/D** keeps his current facing for a combat backstep. **Space** jumps, **F** guards, **E** dashes, **Shift** performs Void Step, **Z/C/X** perform light sword, heavy sword and front kick, and **U/I** perform the preparation and main Burst variants. **1–4** drill normal, heavy, front and rear reactions. **5** knocks Raezen down and **G** gets him up. These opt-in reactions use nonlethal practice damage on the shared health display. **R** resets the drill. The dummy stays passive.

### Training locomotion repair

The original adapter advanced the lab's small stance shifts as ground travel, despite boot lifts of only about six source pixels. The independent boot offsets did not cancel the body travel during contact. Direction changes also inherited the dummy-facing side and could enter the backward clip even when the player meant to turn.

Training now moves the existing collision body with acceleration and braking. `training/gait.gd` takes actual displacement after collision, leaves the support boot at a world-space anchor, and moves only the swing boot through lift, travel and landing. The pelvis lowers as needed to keep both contacts within reach. The head, arms and coat respond to the stride, and the rig, sword and cloth mirror as a single presentation. Releasing movement settles both feet before the frame holds or turns, and a sword attack starts from the current rig pose. Walk, run and backstep use distinct stride lengths and posture. The lab's original standalone profile playback remains available for comparison.

### Reference-guided forward walk

Run `raezen_walk_preview.tscn` directly for the isolated cycle at the Training display scale. The preview and dojo share the same distance-driven step solver. Each boot repeats contact, a brief two-boot load, passing and rise. The swing boot rolls through release and reach. Small pelvis and shoulder counter-rotation keeps the head stable, and the hair and scarf lag the motion by different amounts. The original painted layers and palm socket supply Raezen and his blade throughout the cycle. The standing angles of the source boot and armor artwork remain visible in the side projection.

### Rebuilt forward walk

Training A/D enters the existing advance state and now takes its pose from `training/walk_cycle.gd`. The supplied eight-pose sheet informed separate support, swing and torso tracks. The support foot rolls about its registered heel and toe as it accepts and releases weight. The other leg bends through a higher, longer swing and reaches for the next heel contact. The pelvis compresses after contact and rises through the step, opposing arm motion and staggered hair and scarf follow-through remain on the original rig, and the Void Blade stays on the hand socket.

The isolated preview was rendered alongside the previous walk with identical camera, scale and playback rate before the new gait was enabled in Training. The dojo uses the same rig and walk track, advancing against the collision body's measured displacement. The existing running and retreat poses take over as before. The support check now looks at the sole's active pivot and floor height during rollover.

### Isolated eight-pose review

The rebuilt Training walk above was rejected in visual review. A trace from the live dojo confirmed that A/D activated the `forward` state and used the procedural gait. The near knee used the rearward bend inherited from the painted stance, even as the far knee bent forward. In the fixed-root render, both boots remained close together during passing, with much of the change hidden behind the tassets and the blade.

Run `walk_review/walk_review.tscn` to compare that exact gait with the new study. Both roots stay fixed and both rigs use the existing 0.72 display scale. The study keys eight leg and torso configurations directly, rotates the original boots around their sole pivots, and uses a forward knee pole for both legs. It uses the registered artwork, underlays and sword attachment from the existing rig. This is the isolated visual review build. Training still uses the rejected cycle while the replacement is under review.

### Grounded walk review

The fixed-root study used local ankle positions. Those could show the intended pose but could not keep either boot at the same point on the dojo floor as the body traveled. The earlier traveling comparison moved both rigs across a marked floor at the same speed and derived the study's stance anchors from distance.

Godot 4.7.2 rendered the eight poses individually and the complete moving cycle at 30 fps. Across consecutive left, right and left support phases, the measured drift and floor-height errors were each below 0.001 display pixels. The dojo comparison injected the study into a temporary runtime capture so it used the existing camera, collision body, floor, artwork and scale. The playable dojo still uses its existing controller and animation.

### In-place walk review

The preceding in-place proof fixed both sole anchors as well as the character root. It demonstrated independent articulation and contact before the character received the new pose reference.

### Raezen Walk Cycle Reference Sheet

The isolated lab now takes its eight keys in order from the top row of the new `Raezen Walk Cycle Reference Sheet.png`. The original form, proportions and textures still come from the registered Raezen rig. Measured boot positions and lift, pelvis height and small arm angles drive each key, including the tall right passing pose and the deeper right weight acceptance. Heel and forefoot pivots use the painted boot contours. The blade uses its original palm socket.

The preview fixes the character root and camera to make pose differences visible. The source sheet's stance-foot positions vary between keys, so a boot can move horizontally relative to the static preview floor. World-space foot anchoring over gameplay travel remains an integration step after visual approval.

The pose-by-pose revision fits the screen-space midpoint of the hips, the knee and ankle of each leg, and the inclination from hips to neck. The sword-hand leg is the one lifted in drawing 3. The contact drawings use the full reach of the registered leg segments. Original walk_forward_01 supplies a profile boot. Original heavy_slash_07, with the blade overhead, supplies intact skirt and thigh plates. The review rig samples those regions directly on the existing bones.

The newly rendered eight-pair review uses a single scale and ground registration throughout. At that display size the mean distance to the hand-marked knee and ankle landmarks fell from 17.9 to 10.4 px. Drawing 6 still exceeds the useful range of the planar rear leg. With the ankle aligned horizontally, the knee sits about 41 px from its estimated position beneath the armour. A separately registered foreshortened rear calf and knee would allow a closer weight-acceptance pose.

### Regression and rendered review

The Godot 4.7.2 Compatibility suite passed 207 lab checks, with both complete Burst sequences checked separately at 18 fps. All 969 rendered character-area samples across the 18 previous standalone profiles matched the Milestone 13 baseline byte for byte. All 24 native captures of the main Burst exit also matched. The existing Kai Training suite passed 21 checks and the campaign Raezen suite passed 64. The rendered Training switcher verifier passed 27 behavior checks and saved 18 screenshots. It exercised the existing World Map entry, viewport mouse clicks on the menu buttons, Raezen moves and completed get-up, left-facing contact and repeated swaps back to Kai. The rendered menu, HUD and new motion sequences were reviewed at the existing Training and lab scales.

### Files changed

- Raezen motion and rig: `motion_profiles.json`, `transition_profiles.json`, `motion_player.gd`, `raezen_rig.gd`, `verify_foundation.gd`.
- Training: `training/character_switcher.gd`, `training/raezen_training.gd`, `training/verify_switcher.gd` and the existing Kai `training/hybrid_training.gd` adapter.
- Documentation: this README, the Kai Hybrid README, the project changelog and the next-session notes.
