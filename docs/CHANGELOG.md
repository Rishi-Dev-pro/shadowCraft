# CHANGELOG

All notable changes to **ShadowCraft 2D** are documented in this file.

- Integrated Earthbreaker V2 into Guardian II with a telegraphed ground hit, directional knockback, guard reduction and a dedicated cooldown. The battle and preview share the same motion and effects.

- Refined the two-handed lift and extraction in the Earthbreaker study. Blade contact now triggers a low radial shockwave, dust, six stone fragments, a fading crack and a short camera impulse.

- Added the standalone Hunter Earthbreaker motion study with blade-edge ground contact, local hit-stop, dust and stone fragments.

- Transferred Hunter's approved white-rig walk and combat poses to twenty registered painted layers in Guardian II. Attack presentation follows existing active frames and the approach cycle advances with ground travel.

- Replaced Hunter’s rolling defeat with a stagger and one-knee drop. The campaign’s non-looping defeat clip holds the kneel before the K.O. overlay and retains that frame behind it.

- Added a standalone Hunter white-rig combat study with two axe attacks, guard, hit recoil, knockback and defeat. The study inherits the approved walk rig.

- Added an isolated white-silhouette Hunter walk study based on the axe-wielding idle artwork, with alternating foot support and a two-handed axe grip.

### Raezen reference-sheet pose review

- Integrated the approved traveling walk into Raezen's Training A/D controls. Walking uses the review rig, and returns to the action rig for idle, backsteps, running and combat.

- Added asymmetric step timing, load-driven shoulder and cloth motion, and a traveling review with sole roll against the fixed floor. The preceding free-arm walk is available as the baseline in the comparison scene.

- Coordinated the free shoulder, elbow and glove with the opposite step in the isolated walk. The sword-side elbow follows the stride with a smaller arc.

- Polished heel loading, high-knee passing and cloth follow-through in the isolated walk. The Void Blade now follows the grip at a fixed local angle.

- Refit all eight isolated walk drawings using hip, knee, ankle and neck landmarks. The review rig uses uninterrupted thigh plates, skirt panels and a profile boot sampled from original Raezen artwork. Right weight acceptance still needs a foreshortened rear-leg correction for a closer silhouette match.
- Re-authored the isolated walk keys against the newly supplied eight-frame sheet and aligned heel and toe contact to the original boot textures.

### Raezen in-place walk review

- Rebuilt the isolated preview around a time-driven skeletal cycle with fixed left and right floor anchors and zero root travel.

### Raezen grounded walk study

- Added distance-driven sole locking and heel-to-toe transfer to the isolated eight-pose study. Captured a matched-speed dojo comparison for visual review.

### Raezen isolated eight-pose study

- Added a fixed-root comparison between the current Training walk and a separately keyed walk using Raezen's original artwork. The study uses a forward knee bend on both legs, separated heel contacts and lifted passing boots.

### Raezen forward walk rebuild

- Replaced the forward walk with longer alternating steps, registered heel and toe pivots, a lower weight-acceptance pose and a higher passing leg. The standalone preview and Training share the new skeletal tracks.

### Raezen eight-pose walk reference

- Added a standalone preview of the forward walk used in Training. Each step shows contact, weight acceptance, passing and rise with the original rig artwork and socketed Void Blade.

### Raezen Training locomotion correction

- Replaced the translating stance with alternating skeletal steps driven by actual collision-body displacement. The supporting boot stays planted while the opposite leg swings.
- Added direction-facing walking and running with a separate combat backstep input. Braking settles the feet and sword attacks take over from the current gait pose.

### Raezen Hybrid and Training selection (Milestone 14)

- Added heavy recoil, front and rear impacts, a physical front kick, and a get-up through Sword Ready to the Raezen Hybrid Lab.
- Added a Kai/Raezen switcher to the existing Training Dojo. Both fighters share the same arena, collision slot and dummy.
- Preserved the two original Void Bursts and all 969 rendered baseline samples from the 18 previously approved profiles.

### Kai skeletal trial and combat experiment (2026-11-18)

- Added a separate Moonveil Courtyard trial for the cutout Kai, with the original frame-based fighter available in the standard Grind battle and campaign.
- Kai uses layered turnaround artwork, a 2D bone rig, grounded gait, crouching and landing, and skeletal versions of his jab, cross, heavy punch, and front kick.
- Added configurable two-way dashes, a hit-confirmed jab-to-cross follow-up, a missed-heavy recovery penalty, and adaptive responses to repeated heavies.

### Grind combat refinement (2026-11-18)

- Widened the duel-only body capsules to fit the fighters' painted silhouettes and added a braking margin before contact. Kai can still backstep or jump, and short attack steps stop at the body gap.
- The Agile Ninja now approaches with measured steps, positions, attacks, recovers, and makes bounded retreats before re-entering range.
- Active contact follows the Ninja's blade or Kai's painted striking hand. Impacts pause the duel briefly, and guard retains the existing damage reduction and recovers sooner from blockstun so there is time to counter.

### Grind animation repair (2026-11-18)

- The Agile Ninja now drives joint poses and two-bone foot placement from one physics-timed animation pass. Gait advances from actual travel and the hips lower when a planted step would exceed the leg's reach.
- Reworked guard, quick slash, spinning slash, recoil, knockback, and defeat from the supplied pose guide. Re-anchored the painted headband tails and masked sleeve pixels from the cloak. The strike resources still determine the hit windows and damage.
- Grind Kai uses his existing painted frames with grounded support offsets, distance-driven gait, separate reaction timing, and an existing low-stance clip for guard.


### Grind Milestone 02 — First Gauntlet bout (2026-11-18)

- The Gauntlet preparation panel starts one Kai versus Agile Ninja encounter in Moonveil Courtyard. The battle includes its own HUD, controls, rematch, and result screen. The material reward remains a preview.
- The Agile Ninja's cutout layers use manually traced masks from the left figure in the supplied concept. Skeleton2D, Bone2D, and AnimationPlayer drive the poses. Distance-driven two-bone foot placement supports locomotion and articulated scarf tails follow motion.
- Added isolated duel movement, input actions, timed light and heavy strikes, directional guard, knockback, and an opponent rhythm with pauses, retreat, and guarding. Grind Kai shares the existing artwork and health component.
- Godot 4.7.2 verified 17/17 focused headless checks and 30/30 rendered checks including 13 captures. World Map 76/76, player movement 63/63, and combat foundation 78/78 passed.

### Grind lobby animation and visual identity (2026-11-18)

- Added a shared, clipped ShadowCraft button with blade and seal marks, a traveling border highlight, and a short inset response on press. Shippori Mincho and Barlow provide the lobby typography and include their OFL notices.
- The existing mission silhouettes use a single staggered AnimationPlayer sequence. The Gauntlet reveals diagonally, the Dojo vertically, and the Forge from its furnace. Two 2D petal batches, drifting mist, localized light changes, and a few embers animate while the lobby is visible and focused.
- Sensei's dialogue opens in a crest-marked side panel. The mission, inventory, and guidance dialogs share an ink reveal, keyboard focus handling, and animated dismissal.
- Inspected Godot Compatibility renders at 1280×720 and exercised the lobby controls in the running game. Regression checks passed for the World Map (76), movement (63), combat (78), and character selection (53).

### Grind mission-select redesign (2026-11-18)

- Rebuilt the composition around the angular Gauntlet, the tall Dojo gate, and the low, stepped Forge. Reframed the existing artwork inside custom silhouettes and used each silhouette for mouse hit testing.
- Moved the shared inventory counters into the header and Sensei's guidance to a crescent-marked control below the Dojo. Both still open the existing dialogs.
- Inspected the visible Compatibility-renderer game in fullscreen and windowed mode. Verified the mission and utility controls, keyboard activation, return to the map, and guardian dossier selection. Godot regressions passed for the World Map (72), movement (63), combat (78), and character selection (53).

### Grind Arena Milestone 01 (2026-11-18)

- Added the cinematic Grind lobby, with a shared material summary and inventory, three activity entries, the Wooden Sword recipe preview, and Sensei's initial guidance.
- Connected the existing World Map command menu to the lobby with a two-way fade. The menu highlights Grind while the lobby is open, and returning restores the same map and guardian selection.
- The lobby reads Wood, Stick, and Stone from `resources/grind/player_inventory.tres`. Combat Trials and Practice Grounds open preparation panels, and Weapon Forge explains the Sensei story requirement.
- Godot 4.7.2 Compatibility verification covered all lobby panels, the return button, and a Hunter rematch launch. The World Map suite passed 66 checks. Movement, combat foundation, character selection, Kai V2, and Combat Phase 2 Step 2 suites passed. All four guardian suites passed their assertions, with one resource still in use at shutdown in the Executioner suite.

### Battlefield floor alignment correction (2026-11-17)
- Regenerated only the Mistfall Crossing, Crimson Sanctum, and Raezen's Citadel background images, using the approved Moonlit Dojo's higher horizon/open-floor boundary as the visual alignment reference. All four source backgrounds are 1672×941; no character assets, transforms, pivots, or animations changed.
- Removed the obsolete hidden one-way `ElevatedPlatform` and its collision shape from the shared arena. The actual `Environment/Floor` collision and arena boundaries remain unchanged.
- Updated movement tests to assert the legacy platform is absent while retaining checks for the real floor and walls. Godot 4.7.2 Compatibility-renderer captures of all four arenas were visually compared side by side; the fighters remain on the common ground line. Phase 02 movement checks passed 63/63.
- Two-pass review: (1) all three variants still inherit the same 2D floor, walls, camera, fighter setup, and HUD, with only their background textures varying; no elevated-platform node or collision remains. (2) imported scenes rendered successfully, the 63 movement assertions passed, and the four-stage comparison capture is saved at `reports/screenshots/arena_floor_alignment_comparison.png`.

### Location-specific guardian battlefields (2026-11-17)
- Added original 16:9 stage backgrounds for Mistfall Crossing, Crimson Sanctum, and Raezen's Citadel. The Initiate remains in the existing Moonlit Dojo.
- Added inherited arena scenes for the three new stages. They reuse the same 2D gameplay template, camera, floor and walls, fighter spawner, combat, health, and HUD; only the background texture varies.
- World Map battle requests now route each guardian to the matching stage. World Map tests passed **58/58**, covering all four mappings, scene resources, and the three variant textures. Actual Compatibility-renderer captures show each new guardian/background/HUD combination. No changes to guardian unlock rules or character/combat assets.
- Two-pass audit: architecture review confirmed all scenes remain 2D and inherit the existing combat/floor/camera/HUD setup; quality review confirmed the route and resource tests pass and the new renders preserve fighter visibility. The project reference checker reports 0 errors and 4 pre-existing orphan-UID warnings; manual World Map mouse navigation remains untested.

### Raezen dossier rematch button (2026-11-17)
- The defeated Raezen dossier now shows an enabled `REMATCH` button in the existing bottom action slot. It reuses the current battle request, unlock check and encounter transition; story completion and guardian progress are unchanged.
- World Map SceneTree checks passed: 40 checks, 0 failures, including the Raezen button label, enabled state, encounter start and battle-request signal. No files staged or committed.

### Raezan selected Phase 2 sheets and walk-cycle repair (2026-11-17)
- Located the two user-selected generated sheets in the local image archive and preserved copies under `assets/characters/raezan_boss/source/batches/batch_08_selected/`: the 16-pose Phase 2 finisher and 20-pose Phase 2 Void Burst. Extracted them as transparent 512×512 frames, generated contact sheets, and connected them to the existing `phase2_finisher` and `phase2_void_burst` SpriteFrames clips. Earlier source artwork remains intact.
- Fixed the frozen-looking walk: the inherited AI requested `walk` every physics tick while Raezan's override immediately changed it to `walk_forward` (or the Phase 2 gait), restarting the animation each tick. Raezan now resolves generic walk requests to a stable, phase-aware clip before playback.
- Reimported the changed textures in Godot 4.7.2. Focused Raezan runtime checks passed with zero failures, including Phase 1 and Phase 2 gait frame advancement and validation that both selected source clips are the textures assigned to the runtime SpriteFrames resource.
- Visually inspected the two extracted contact sheets. This pass did not capture a live gameplay recording; in-game appearance during a manually played fight remains for user review. No files were staged or committed.

### Separately Authorized Final Boss — Raezan (2026-11-17)
- Assembled the existing Raezan art library into a `SpriteFrames` resource using the same frame-based AnimatedSprite2D architecture as The Executioner; added an inherited Raezan boss scene, attack profiles, reusable Void Blade resource/scene, and story-arena routing for Raezen Citadel.
- Added five distinct combo hit profiles, four sword strikes, dash, Void Step, Void Burst, inherited guard/parry/counter behavior, and a 50% health phase transition using existing health, hurtbox, hitbox and progression systems. Tuned the boss's attack cadence and recovery for readable openings.
- Preserved the four user-approved sheets under `assets/characters/raezan_boss/source/prior_user_selected_sheets/` as visual references; they were not imported as production frames because they have opaque dark-gray backgrounds and small, inconsistent cells (about 98–165px wide), making background removal/upscaling likely to damage edges and detail. The production library remains individually extracted under `assets/characters/raezan_boss/frames/`.
- Automated suites passed: Phase 01 hierarchy 44/44; Phase 02 movement 63/63; Kai V2 95/95; Razen V2 113/113; combat foundation 78/78; character selection 53/53; Phase 2 Step 2 66/66; unarmed combat 124/124; window manager 4/4; world map 36/36; Initiate 60/60; Hunter 24/24; Executioner 19/19; Raezan 0 failures.
- In the live arena, the Raezan boss scene and HUD loaded; Kai and Raezan had aligned gameplay scale/floor positioning, and Raezan's sword pose and movement/attack presentation were inspected. Desktop key-tap automation could not sustain movement/attack holds, and the sampled live fight ended in defeat before a player hit was visually confirmed; runtime attack acceptance remains unverified.
- Limitation: source character frames depict the Void Blade in-hand. The separate reusable Void Blade asset/resource is preserved, but it is not overlaid on the sprite to avoid duplicate swords; independently animating/detaching it requires weapon-free character layers or artwork.
- Two-pass audit: architecture review confirmed the 2D-only scene inherits the established Executioner/TrainingDummy combat and SpriteFrames path, and keeps the story boss gate/callbacks in the shared arena; quality review re-read the Raezan controller, inherited scene, attack/resource mappings, frame builder, manifest and focused tests. No files were staged or committed. Live visual verification is limited to rendering, scale/ground alignment, sword pose and observed boss hit/defeat animation; player-hit registration, a full victory, parry/counter timing and phase-two gameplay were not visually confirmed.

### Raezan combat refinement (2026-11-17)
- Corrected the approach animation selection so Raezan uses the forward gait while advancing, independent of which direction he faces; both phase-one and phase-two routes are covered. The separate authored forward and backward cycles remain intact.
- Fixed Void Burst reach for its intended close-combat spacing by updating its hitbox width to 480px while preserving its authored startup, active timing and damage. One activation still registers only one hit.
- Reduced the common hit reaction to eight existing authored flinch/recovery poses and allowed the knockback animation time to finish. Guard mitigation is now 50%; Raezan receives intermittent, phase-aware guard opportunities with cooldowns, preserving inherited parry/counter behavior.
- Validation: focused Raezan test passed with 0 failures, including gait-state selection, one Burst hit, damage application and 50% guard mitigation. Executioner 19/19, combat foundation 78/78, Phase 02 movement 63/63 and Razen V2 113/113 passed. Live arena inspection showed Raezan advancing with a stepping pose, aligned with Kai, and the blade held in-frame; the short interactive run did not visually confirm a player hit, a Void Burst hit or phase two. No files staged or committed.
- Guard visual follow-up: added four transparent 512×512, floor-aligned guard poses from the approved in-project Raezan art reference (anticipation, blade protecting upper body, braced contact, release). Mapped them to entry/hold/impact/release SpriteFrames clips and fixed the state-to-animation sync so the generic AI cannot restart the entry pose every physics tick. Focused Raezan test now confirms the pose sequence and 50% blocked damage. The actual arena was launched, but the rapid boss defeat overlay prevented a live visual check of the guard pose or its runtime damage reduction.

### Executioner visual integration repair (2026-11-14)
- Fixed the Executioner's white fringe at import time: the idle sheet was white-matted with partial alpha, so its edge RGB is now decontaminated from the white composite while opaque silver hair, armor and sword pixels remain intact.
- Removed disconnected neighboring-pose fragments from KO cells before cropping. The duplicate upper-body image in later fall frames came from those sheet spill fragments; the inherited Executioner scene already has one animated body node.
- Matched the Executioner's uniform in-game visual height to Kai and recalculated the sprite's vertical offset to keep both characters' feet on the same arena baseline. Collision, combat, progression, Kai and the other characters were left unchanged.
- Focused Executioner checks cover a single animated body layer, the shared foot line/scale, and clean late KO frames. Fresh Godot 4.7.2 arena captures showed idle/approach, heavy slash, hit reaction and the final KO overlay; the KO view contains exactly one fallen Executioner. Kai's own KO was also inspected in the live arena.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Combat Phase 2 Step 2 integration

### Separately Authorized Guardian III — The Executioner (2026-11-14)
- Added distinct `AttackData` profiles for each hit of The Executioner's three-hit sword combo. Its three active windows now switch hitbox size, per-frame offsets, damage, knockback, hitstun and impact timing to match the authored opening, second and finishing slash, rather than reusing one generic hit profile.
- Retained the independent reusable Iron Sword `WeaponData` and scene, the 238 transparent 512×512 animation frames, and the existing shared health/hitbox/hurtbox/progression architecture. No EvoLink requests were made.
- Focused Guardian III scene test passed **16/16**, including per-slash profile mapping, frame resource checks, sword-resource separation, parry timing and progression gating. The live launcher reached the actual Executioner arena; its idle stance, sword grip, scene scale, opposing placement and defeat overlay were visually inspected. UI automation on Windows only sent key taps, so sustained movement and successful player-triggered hit/parry sequences remain unverified by this session.
- No files were staged or committed. Two-pass review: architecture pass confirmed the new per-hit data stays within `AttackData`/`Hitbox2D` and leaves other fighters and story gates untouched; quality pass re-read the changed script, scene, resources and focused test, and recorded the live-input limitation rather than claiming complete gameplay acceptance.

### Story Mode — Guardian II: The Hunter (2026-11-14)
- World Map dossiers now keep the DEFEATED status visible while exposing an enabled REMATCH action for the already-playable Initiate and Hunter encounters. Rematches reuse the existing guardian encounter flow and do not reset story progression.
- Visual correction: restored the pre-Hunter map dossier portrait (`guardian_hunter_portrait.png`) and adjusted only the Hunter's separate Stone Axe socket/grip pivot and per-animation pose data. The axe artwork and Hunter sprite frames remain unchanged. Current desktop capture showed the preview label but not the character, so this correction still needs a successful in-game visual check.
- Added an original Guardian II art package with transparent 512×512 frames and an independent portrait, normalized from generated source sheets; the supplied reference remains provenance only and was not cropped into gameplay sprites.
- Added a canonical reusable Stone Axe texture/scene and `WeaponData` resource. The Hunter instances that same weapon as a separate visual layer, with frame-matched grip/rotation poses during attacks, guard and movement.
- Added a dedicated Hunter scene inheriting the shared enemy health, hitbox, hurtbox and AI architecture, with data-driven light/heavy/sweep axe attacks and distance-aware move selection.
- Connected Guardian II to the existing story unlock and arena flow. Story encounters force Kai, replace only the arena's training-target slot, and on Hunter victory unlock Guardian III while Raezen remains gated.
- Focused Godot 4.7.2 regression passed **27/27**; Guardian I **60/60**, Phase 02 movement **63/63**, Kai V2 **95/95**, combat foundation **78/78**, World Map progression **30/30**, and Phase 01 hierarchy **44/44** also passed. The actual startup/map/battle flow was visually inspected in the running game; Hunter was visible approaching Kai with the axe equipped, and the round-end defeat presentation appeared. The final headless editor scan exited 0 without reported script/resource errors. No files were staged or committed.

### Story Mode — Guardian I: The Initiate (in progress, 2026-11-13)
- Fixed lost player attack inputs during startup and hitstun recovery, and corrected tests to respect authored attack reach; added a 40% grounded backstep guard for Kai and lengthened The Initiate's attack recovery cadence. Actual rendered arena capture and focused combat regressions confirm jab, heavy punch, kick and the supported jab chain damage the guardian once per hit.
- Connected the available Initiate map marker to the existing Movement Test Arena, forces Kai as the story fighter, and uses dedicated jab/kick attack resources while retaining the shared health, hitbox, hurtbox, KO and defeat flows.
- Enabled the existing minion AI only for the Initiate encounter, added a brief defensive retreat, guardian HUD labels, confirmed-hit spark/hit-stop feedback, and persistent Initiate victory recording after the death animation completes.
- Added a focused guardian regression test scene for AI damage, training-dojo isolation, Kai selection, death timing and Hunter unlock. Focused Initiate test passed **19/19**; existing World Map, selection, combat foundation, Phase 02 movement, Phase 01 hierarchy and Kai V2 suites passed **30/30, 53/53, 78/78, 63/63, 44/44 and 95/95** respectively (382 assertions combined).
- Replaced the old loose accessory overlay on the shared dummy with a separate original female Initiate design and transparent frame package. The normal training dummy scene is restored to its unadorned approved minion sprite and remains the Training Dojo target.
- Added a dedicated Initiate scene/subclass inheriting the established health, hurtbox, hitbox and AI architecture; added data-defined heavy punch and roundhouse attacks, frame-synced attack recovery, rearward defensive movement, and animation selection by AttackData. The story arena swaps only its encounter target to The Initiate; Kai and the default training arena remain unchanged.
- Original art source sheets, 512×512 frame exports, shared ground anchor, contact sheets and asset provenance are stored under `assets/enemies/the_initiate/`. Automated/regression checks were updated; the 2026-11-14 arena capture verifies the live fight and attack health changes.

### Phase 5 — Moonlit Dojo and fight HUD (2026-11-11)
- Added an original, full-bleed moonlit dojo background and Kai V2 HUD portrait. The arena renders the environment as a background texture while fighters, collisions, health UI, and controls remain separate live Godot nodes.
- Replaced the training HUD layout with opposing hero/minion portraits, live health bars and values, centered ShadowCraft/round labels, accurate controls, and lower-right branding. Razen uses a crop from his existing approved gameplay idle art; the minion uses its existing idle frame.
- Kept the movement/collision layout and gameplay art unchanged. Godot import completed and the arena loaded headlessly without reported resource/script errors. In-engine visual inspection could not be completed because the desktop capture surface returned the Codex window instead of the running Godot window.

### Round-end presentation and defeated-player AI stop (2026-11-11)
- The arena now waits for the defeated fighter/minion to finish its fall and reach the grounded pose before showing the result. The K.O./Defeat overlay uses a high CanvasLayer so the downed character remains behind a readable panel.
- When Kai or Razen reaches zero health, the minion cancels any active attack, disables its hitbox, and stops making AI decisions. The arena pauses after the fall and offers Rematch or Character Select.
- Godot 4.7.2 headless launch of `MovementTestArena.tscn` completed without load errors; visual presentation still needs an in-game check.

### Combat Phase 2 — Step 2: Cross and Heavy Punch Integration (2026-11-11)
- Imported the user-approved original Kai V2 Cross Punch (6 frames), Kai Heavy Punch (10), Razen Cross Punch (8) and Razen Heavy Punch (12) into their isolated character animation packages and SpriteFrames resources. All clips are 512×512 transparent frames, 30 FPS, one-shot, aligned to Kai's y=496 and Razen's y=488 ground baselines.
- Added independent per-character `AttackData` for both new punches, tuned startup to the authored contact pose, supplied two active-frame hitbox offsets per move, and connected Light Jab → Cross Punch on Z → Heavy Punch on C using the existing buffer and chain-window engine. Direct C heavy remains available; roundhouse/sweep remain empty for Step 3.
- Extended the existing Kai SpriteFrames builder and Razen animation manifest/builder path. Added focused Step 2 checks for frame resources, move data and both playable chain sequences; updated the Step 1 suite's expected moveset inventory.
- Engine verification is pending because Godot 4.7.2 is not present on PATH or in the launcher's standard install paths in this session; no runtime pass or gameplay capture is claimed.

### Combat Phase 2 follow-ups: suite repair, crouch lock, Razen reach (2026-11-10)
- Repaired the malformed ending of `tests/unit/test_player_movement.gd` (a literal `\n` where `kai.free()` belonged). The file is byte-identical to its committed version again and the working-tree Phase 02 suite runs **63/63**.
- Added an explicit combat-owned crouch posture: `CharacterController2D.combat_crouch_lock` is set by `CombatController` while a crouched-stance attack owns the character, so the crouched state and collision capsule survive the suppression of crouch input. The lock clears on neutral, hitstun or knockdown, standing attacks never set it, and normal crouch input outside combat is unchanged. Sixteen new assertions cover the crouched start, posture and capsule through startup/active/recovery, a crouched→crouched chain link, lock release on recovery, and absence of the lock on standing attacks.
- Reviewed Razen's reach against his authored silhouettes by measuring the striking limb of each contact frame and mapping it through the sprite transform. His Front Kick hitbox was sitting ~21 local px too high, over the thigh rather than the boot, and now tracks the boot (`front_kick` offset y −236 → −216, active offsets updated). His Light Jab was left as authored: the existing box already encloses his fist, and nudging it upward moved it off the training dummy's hurtbox. Kai's hitbox geometry and trajectories are untouched and asserted equal to the approved legacy resources.
- Verification: Phase 2 suite **122/122**, Combat **78/78**, Phase 02 movement **63/63**, Kai hierarchy **44/44**, Kai V2 **95/95**, Razen V2 **113/113**, selection **53/53**. Rendered capture with `--combat-debug` confirms the active kick rectangle now covers the extended boot and still lands 18 damage on the dummy.

### Combat Phase 2 — Step 1: Combat Data & Chain Engine (2026-11-10)
- Extended `AttackData` additively with `stance`, `hit_reaction`, `hit_stop_seconds`, `impact_scale`, `lunge_velocity`, `chain_next` and `chain_input`, plus `can_start_from()`, `get_hit_stop_seconds()` and `get_chain_action()`. Existing fields and the approved `light_jab.tres` / `front_kick.tres` numbers are unchanged.
- Added `MovesetData` (`resources/attacks/moveset_data.gd`) as the per-fighter attack table (chain roots, direct heavy/roundhouse/sweep slots, buffer and chain-window timing) and `CombatInputBuffer`, a dependency-free tick-stamped single-slot buffer.
- Refactored `CombatController` to resolve attacks from the moveset, buffer presses during active/recovery windows, consume the buffer only inside the chain window, chain into `chain_next` while keeping movement locked, and gate crouch-only attacks by stance. Z/X behaviour and all Combat 1 timings are preserved.
- Added per-character attack resources: Kai (`resources/attacks/kai/`) keeps his approved numbers exactly; Razen (`resources/attacks/razen/`) gains independent data retimed to his approved 8-pose clips (16 ticks, 6/2/8) with heavier damage, knockback, hitstun, recovery and hit-stop. Both character scenes now assign a moveset instead of two shared attack slots.
- Consolidated incoming-hit handling to the single `Hurtbox2D` → `on_combat_hit` path; the redundant `damage_received` listener that overwrote hitstun with a fixed 12 frames was removed. Hit-stop duration and spark scale now come from attack data instead of per-arena constants, and attack table accessors replace the old `punch_attack`/`kick_attack` reads in both arena controllers.
- Added `heavy_attack` (C) and `roundhouse_attack` (V) input actions. The direct heavy, roundhouse and sweep slots remain unassigned until their approved art lands; crouched attacks keep their existing rejection until Step 3.
- Verification: new Step 1 suite **97/97** (fixed-rate and wall-clock). Regressions: Combat foundation **78/78**, Kai V2 **95/95**, Razen V2 **113/113**, Character selection **53/53**, Phase 01 **44/44**, Phase 02 **63/63** (run from the committed file; the working-tree copy has a pre-existing literal `\n` parse corruption). Rendered Godot 4.7.2 Compatibility captures confirm Kai still deals 8/15 and Razen now deals 11/18 with his full clips playing through recovery. Step 2 remains gated on explicit approval; nothing was staged or committed.

### Playable character selection (2026-11-10)
- Made the character-select screen the F5/main launch scene with animated idle previews from the real Kai V2 and Razen sprite-frame resources. Mouse selection, A/D or arrows and PLAY are wired to a single selection-state autoload.
- Added a runtime spawner in the existing movement/combat arena. The selected character keeps its own character data, artwork and animation controller while both reuse the same movement, Combat 1 attacks, hitboxes, health and TrainingDummy.
- Added Razen-specific jab/kick animation frames, plus ESC pause with Resume and Change Character actions.
- Added selection/switching regression coverage and a Godot Movie Maker capture runner. The selector and both characters were inspected in Compatibility-rendered gameplay recordings.
- Verification: Phase 01 44/44; Phase 02 63/63; Kai V2 95/95; Razen V2 113/113; Combat 1 78/78; character selection 53/53. Captures/logs are listed in `docs/CHARACTER_SELECTION.md`.

### Razen standalone character package (2026-11-10)
- Completed the user-approved Razen visual production follow-up in an isolated package. Generated original sheets for 8 idle, 8 forward walk, 8 backward walk, 8 run, 4 crouch, 8 crouch-walk, 4 jump, 4 landing and 4 attack-presentation frames. Normalized 56 frames plus the approved signature pose as a one-frame combat-ready presentation.
- Added animation provenance/frame manifests, transparent aligned frame PNGs, contact sheets, a Godot `SpriteFrames` builder, Razen `CharacterData`, a dedicated animation controller, `Razen.tscn`, a separate rendered-review arena and a 93-check scene/resource regression test.
- Reused `CharacterController2D` with independent presentation-only frame animation. Did not alter the F5 scene, Kai V2, combat architecture, or Phase 08 boss gate. `attack_presentation` is not connected to combat.
- Visual review caught and corrected the initial sprite pivot offset: centered 512px frames need a local Y offset of -232px at 0.7 scale to align the y=488 sole anchor to the physics floor.
- Godot 4.7.2 built the SpriteFrames resource; the final Razen checks cover all state mappings and pass **93/93**. Regressions pass: Kai V2 **95/95**, Phase 02 **63/63**, Phase 01 **44/44**, Combat **78/78** at fixed 60 FPS. A real-time headless Combat run exposes one existing timing-sensitive animation-frame assertion, documented with its deterministic pass in `docs/RAZEN_CHARACTER_PRODUCTION.md`.
- The configured F5 scene was also rendered with the existing integration showcase; the Godot log confirmed the jab miss, confirmed jab and kick hits, and dummy health change. Actual Compatibility-renderer Razen screenshots for every clip and a 4.7-second review AVI are in `assets/characters/razen/previews/`. Both audits are documented in `docs/RAZEN_CHARACTER_PRODUCTION.md`.

### Unified playable movement and Combat 1 arena (2026-11-10)
- Composed the existing TrainingDummy scene into `MovementTestArena.tscn` and wired its existing damage, hurtbox, hit reactions, health UI, hit-stop, hit spark, hitbox debug display, and combat telemetry through the arena controller. Kai keeps the original movement/crouch/jump controller and now collides with the dummy body.
- `run_shadowcraft.bat` is now the one-click game launcher. It searches standard locations and PATH, accepts `GODOT4_EXE`, validates Godot 4.7.2, runs the configured main scene from the quoted project directory, and writes `reports/logs/shadowcraft_latest.log`; failure prompts are conditional. Removed the launcher's archived-project engine fallback.
- Added an in-engine integration showcase option and main-arena combat regression assertions. The dedicated combat arena remains a development test scene; Combat 2 is not started.
- Reproduced the old development launch failure exactly: its `%~dp0` path retained a trailing backslash inside a quoted `--path` argument, causing Godot to merge the following scene path into an invalid project path. Trimmed the directory and switched that optional test launcher to explicit `--scene`; ordinary play uses only the main launcher.

### Combat launch integration repair (2026-11-10)
- Diagnosed the missing hit response when launching with F5: the configured main scene is `MovementTestArena.tscn`. It contains Kai V2, but its `DummyTarget` is only a visual facing marker and the scene has no dummy hurtbox or CombatTestArenaController to spawn hit-stop and impact sparks. The combat-enabled arena remained separate.
- Preserved the F5 movement scene and added `run_combat.bat` as an explicit launch path for `combat_test_arena.tscn`; the `debug` argument enables active hitbox outlines. README and the phase handoff explain the distinction.
- Added regression assertions for main-scene identity, Z/X attack events selecting and advancing the attack clips on F5 Kai, the non-damageable movement marker, and the combat arena's presentation owner. Combat suite is now 62/62; no attack, movement, or damage rules changed.
- Re-recorded the explicitly launched combat arena at normal speed and inspected jab/kick contacts, hit sparks, dummy recoil, recovery and hitbox debug. All existing suites passed; no performance benchmark was measured.
- Follow-up: reproduced the launcher's prompt wait when its Godot lookup failed. Added standard install-folder and PATH resolution plus a `GODOT4_EXE` override, and removed the blocking `pause`; the failure path now prints an error and exits. Added regression checks for the target scene, executable lookup, and non-blocking failure path.

### Combat 1.1 basic attack polish (2026-11-10)
- Aligned Light Jab and Front Kick contact phases to the authored frame-4 pose within their unchanged 12-physics-frame total duration. Attack data now stores a hitbox offset for each active frame; the hitbox follows the fist recoil and toe retraction, and tighter shapes place the active region over the visible striking limbs.
- Added confirmed-hit-only 40ms jab / 55ms kick hit-stop, small code-drawn impact sparks with distinct punch/kick scale, and eased dummy recoil. Damage values, collision layers, single-hit-per-window handling, and movement/physics ownership remain unchanged.
- Expanded Combat foundation regression coverage to 52 assertions, including whiff/contact, active-frame alignment, hitbox trajectory and deactivation, repeat attacks, and hit-stop restoration. Kai V2 95/95, Phase 02 63/63, and Phase 01 44/44 also passed.
- Captured the normal-speed and reduced-time-scale rendered sequences with active hitbox outlines, plus actual jab/kick whiff, contact, impact, and recovery frames under `reports/videos/combat11_*.avi` and `reports/screenshots/combat11_after_*.png`.
- Completed both architecture/integration and quality/completeness audits. No performance benchmark was measured. Combo chaining and all later Combat milestones remain gated pending visual approval.

## [Earlier] — Combat 1 foundation

### Combat 1 foundation (2026-11-10)
- Added typed `AttackData`, `CombatMath`, `HealthComponent`, `Hitbox2D`, `Hurtbox2D`, and Kai V2's combat state/timing controller. The controller owns startup, active, recovery and hitstun; the existing animation controller yields visual ownership during combat. Attacks are ground-only and once-per-target during each active window.
- Added original six-pose Light Jab and Front Kick atlases; integrated each as a separate 30 FPS clip in the existing Kai V2 `SpriteFrames`. `AttackData` configures frame timing, hitbox position/size, damage, knockback and hitstun.
- Added a damageable 2D training dummy and a separate `CombatTestArena` with health bars, state feedback and opt-in hitbox outlines. Combat-arena enemy body collision is local to this scene; the F5 Movement Test Arena remains the main scene.
- Added Z and X input actions. Adjusted jab/kick hitbox height after inspecting the rendered debug outline against Kai's fist and kick contact. Headless tests passed: Combat 1 35/35, Kai V2 95/95, Phase 02 movement 63/63, Phase 01 hierarchy 44/44.
- Captured and visually inspected the actual Godot 4.7.2 Compatibility-renderer recording `reports/videos/combat1_foundation_showcase.avi` and the idle/run/jab/kick/recovery frames under `reports/screenshots/combat1_*.png`.
- Pass 1 verified 2D-only scenes, valid resource links, isolated arena collision, and preserved Phase 01/02 entry scenes. Pass 2 reviewed all new code/resources, ran the four test suites, and inspected the recorded animation and impact frames. No frame-time benchmark was recorded.
- Phase 03 remains in progress. Combo chaining, defense, advanced moves and specials are not implemented; wait for explicit authorization before starting another Combat milestone.

### Kai V2 playable integration (2026-11-10)
- Added `scenes/characters/KaiV2.tscn` as an independent `CharacterBody2D` playable character using imported transparent 512×512 frames through a reusable `SpriteFrames` resource and a presentation-only animation controller. Preserved the former scene as `KaiLegacy.tscn` for rollback, removing only its duplicated scene UID so both files remain independently addressable.
- Integrated idle, forward/backward walk, run, crouch, crouch walk, jump, and landing animations with the existing movement controller. V2-only run and crouch-walk behavior is opt-in; original controller defaults preserve Kai V1 behavior. Added Shift+forward run input.
- Made Kai V2 the arena character in the existing `run/main_scene`; retained acceleration, gravity, jump impulse, collision, arena boundaries, and player controls. Updated arena instructions for run.
- Added 95 focused Kai V2 scene/resource/runtime assertions. Godot 4.7.2: Kai V2 95/95, Phase 02 movement 63/63, Phase 01 hierarchy 44/44. Captured a genuine Compatibility-renderer Movie Maker recording and verified idle, walk, run, retreat, crouch, crouch-walk, jump, platform landing, and recovery frames.
- Pass 1 audit: new scene is 2D-only; all referenced resources resolve; `KaiLegacy.tscn` is retained without a duplicated UID; `exp-1` is untouched; Phase 03 remains gated. Pass 2 audit: changed files re-read, all 202 focused/regression assertions passed, rendered movie inspected, working tree contains unrelated pre-existing files which are excluded from this commit.
- Evidence: `reports/videos/kai_v2_integration.avi` and actual-game frames `reports/screenshots/kai_v2_{idle,forward,run,backward,crouch,crouch_walk,jump,landing,idle_after}.png`.

### Signature stance and reference gait pass (2026-11-10)
- Re-authored Kai's idle guard and forward/backward walk clips with eight explicit gait poses, pelvis transfer, knee/foot articulation, and a distinct retreat profile while retaining the existing Skeleton2D and artwork.
- Captured the idle stance and every authored forward/backward pose in the running Godot scene under `reports/screenshots/kai_reference_after_*.png`; the walking runner reports 13/13 checks passing, including a sampled support foot in all eight poses per direction.
- Visual review remains open: measured planted-foot excursion is still large (up to 147.54px forward and 164.59px backward), and some gait poses read stiff. The eight-pose contact checks do not establish convincing foot locking. Treat this pass as provisional pending rig/foot-placement work and human review.
- No movement controller, physics, collision, crouch, jump, landing, or new art assets were changed in this pass. Phase 03 remains gated.

### Fixed
- Refined only Kai's forward and backward walk clips with modest hip bob, hip/torso counter-rotation, a purposeful backward torso lean, and stronger opposite arm swing. Leg and foot curves were retained after tuning iterations increased measured foot slide. Crouch, jump, landing, collision, and movement physics remain untouched.
- Added a live walking sequence runner with idle/start/continuous/stop captures, forward/backward reversals, ground-foot sampling, and genuine Godot before/after movies.
- Validation note: state transitions passed 7/7. Current sampled grounded-foot horizontal excursion is higher than the baseline, so foot locking remains a known visual limitation for a future walk-only iteration.
- Repaired Kai's crouch pose: corrected the back knee bend, kept both soles grounded by removing the 29px foot-sprite offsets, and adjusted pelvis height for crouch contact.
- Added ankle compensation to both walk cycles and restored complete leg and arm chains on idle/walk/jump/landing clips so no stale bone rotations remain when a state changes; transitions now blend through the existing AnimationPlayer.
- Replaced the overlapping procedural airborne bone writer with authored `jump_air` and `jump_land` clips in Kai's existing animation library.
- Updated the movement regression assertion to verify the shared AnimationPlayer owns airborne and landing clips.
- Added a live 17-check transition runner and genuine before/after Godot screenshots and movies under `reports/`.
- Kept locomotion state and cycle active through ground deceleration; animation playback rate now follows horizontal velocity to reduce foot sliding.
- Froze the active ground pose through both jump and fall, and added a separate skeletal tuck and eased landing settle without changing Kai's artwork or ground cycles.
- Preserved the pre-collision downward speed for landing feedback, reset vertical speed after contact, and guarded standing capsule expansion against overhead obstruction.
- Lowered the movement test platform to an 80px rise, reachable within the existing approximately 90px jump arc. Jump impulse and gravity remain unchanged.
- Added regression assertions for repeated airborne jump input, measured jump height, platform reachability, velocity-matched walking animation, and the airborne presentation component.

---

## [0.3.0] — 2026-11-09
### Phase 02: Player Movement & Controls

#### Added
- **Fighting Game Input Map:**
  - Configured input actions in `project.godot`: `move_forward` (D / Right), `move_backward` (A / Left), `move_left` (A / Left), `move_right` (D / Right), `jump` (Space / W / Up), and `crouch` (S / Down).
- **Player Kinematics & State Machine:**
  - Authored `scripts/characters/CharacterController2D.gd` utilizing a statically typed 6-state kinematics machine (`IDLE`, `MOVE_FORWARD`, `MOVE_BACKWARD`, `CROUCH`, `JUMP`, `FALL`).
  - Implemented decoupled `update_kinematics(delta, move_input, jump, crouch, on_floor)` function allowing deterministic headless simulation and in-engine execution.
  - Implemented smooth acceleration (1800 px/s²), ground friction (2200 px/s²), walk speed (220 px/s), and retreat speed (180 px/s).
  - Implemented vertical gravity (980 px/s²), vertical jump impulse (-420 px/s), and terminal fall velocity (1200 px/s).
- **Collision & Physical Bounds:**
  - Added dynamic capsule collision resizing in `scenes/characters/Kai.tscn`: standing height (320px, Y=-160px) and crouched height (200px, Y=-100px), maintaining grounded foot base at Y=0.
  - Implemented strict crouch jump lockout preventing jump initiation while crouching.
  - Enabled floor landing reset and solid wall collision adherence.
- **Facing & Animation Integration:**
  - Implemented automatic and manual opponent tracking by flipping visual `Skeleton2D.scale.x = ±0.48` while preserving normalized root `CharacterBody2D.scale = Vector2(1, 1)` to eliminate inverted collision normal bugs.
  - Connected states to Phase 01 locomotion cycles (`loco/idle`, `loco/walk_fwd`, `loco/walk_bwd`, `loco/crouch`) with airborne freeze safety.
- **Movement Test Arena & Telemetry:**
  - Created `scenes/arenas/MovementTestArena.tscn` with solid floor (Layer 1), left/right perimeter boundaries, elevated test platform (Y=420), dummy opponent target (X=960), and real-time telemetry diagnostics HUD.
  - Created `scripts/arenas/MovementTestArenaController.gd` providing real-time telemetry display and automated showcase playback capability.
- **Automated Testing & Visual Verification:**
  - Authored comprehensive test suite `tests/unit/test_player_movement.gd` covering 55 assertions across 11 test suites (100% pass rate).
  - Verified Phase 01 regression suite `tests/unit/test_kai_hierarchy.gd` (44/44 assertions passed, combined 99/99).
  - Captured in-engine visual proof in `reports/screenshots/` (`movement_arena_composite.png`, `movement_walk_fwd.png`, `movement_jump.png`, `movement_crouch.png`).

---

## [0.2.0] — 2026-11-09
### Phase 01: Kai: 2D Character Art & Animation Pipeline

#### Added
- **Visual Concept & Sprites:**
  - Created original high-resolution 2D character concept sheet and side-profile reference for Kai (`assets/characters/kai/kai_concept_art.png`).
  - Sculpted 16 transparent 32-bit PNG anatomical limb components with convex rounded joint caps and transparent borders (`head.png`, `torso.png` with purple star emblem, `arm_upper_fwd.png`, `arm_lower_fwd.png`, `hand_fwd.png`, `leg_upper_fwd.png`, `leg_lower_fwd.png`, `foot_fwd.png`, plus darkened back limb layers for depth).
- **Data Architecture:**
  - Created `CharacterData.gd` resource definition (`scripts/characters/CharacterData.gd`) for character metadata, identity, and combat attributes.
  - Created `resources/characters/kai.tres` defining Kai's baseline stats (100 HP, 100 poise, 220 walk speed, agile weight class).
- **Character Rig & Locomotion Scene:**
  - Built `scenes/characters/Kai.tscn` featuring `Skeleton2D` with an 18-bone humanoid hierarchy, precise joint offsets, and dedicated `Marker2D` weapon socket (`Socket_Weapon`).
  - Implemented 4 core locomotion cycles under library `"loco"` in `AnimationPlayer`:
    - `loco/idle`: 1.6s looping martial breathing and weight sway.
    - `loco/walk_fwd`: 1.0s fluid forward martial stride with opposing limb swing.
    - `loco/walk_bwd`: 1.0s defensive backward retreat stride.
    - `loco/crouch`: 0.5s grounded low-center-of-gravity martial guard with raised fists protecting chin and chest.
- **Verification & Visual Gate:**
  - Built interactive preview arena `scenes/arenas/KaiPreview.tscn` displaying all 4 states alongside the concept model sheet.
  - Added automated unit test suite `tests/unit/test_kai_hierarchy.gd` covering 44 assertions across scene nodes, bone structure, animation tracks, and resource integrity.
  - Captured in-engine Godot screenshots in `reports/screenshots/` verifying visual fidelity, seam quality, and ground alignment.

---

## [0.1.0] — 2026-11-09
### Phase 00: Project Constitution, Architecture & Development Environment

#### Added
- **Repository Setup:**
  - Initialized Git repository on `main` branch with Git LFS filter support.
  - Added `.gitignore` configured specifically for Godot 4, GDScript, and GdUnit4 artifacts.
  - Added `.gitattributes` to normalize line endings (`LF`) across all scripts, scenes, and configs.
  - Added MIT License with explicit proprietary reservation for original character lore, artwork, and designs.
- **Engine Configuration:**
  - Configured `project.godot` for Godot 4 (GL Compatibility renderer, 1280x720 baseline resolution, 60 FPS V-Sync, integer pixel snapping).
  - Defined 2D Physics Layers: Layer 1 (`environment`), Layer 2 (`player_body`), Layer 3 (`enemy_body`), Layer 4 (`player_hitbox`), Layer 5 (`enemy_hitbox`), Layer 6 (`player_hurtbox`), Layer 7 (`enemy_hurtbox`).
- **Standardized Directory Structure:**
  - Created standardized folders for `assets/`, `scenes/`, `scripts/`, `resources/`, `tests/`, and `docs/` with `.gitkeep` markers.
- **Governance & Directives:**
  - Created root-level `AGENTS.md` specifying the 22 mandatory operational rules, strict 2D enforcement, and two-pass audit protocols.
  - Created `docs/PROJECT_CONSTITUTION.md` as the permanent source of truth for design, combat philosophy, performance, and originality.
- **Technical Architecture:**
  - Created `docs/ARCHITECTURE.md` with complete Mermaid diagrams for system architecture, character components, combat sequence flow, weapon attack lifecycles, and enemy AI loops.
  - Created 11 Architecture Decision Records (`docs/DECISIONS/ADR-0001` through `ADR-0011`) covering engine selection, 2D mandate, Compatibility renderer, hybrid animation, weapon data decoupling, combat pipeline, GDScript typing, GdUnit4 testing, Git workflow, performance targets, and copyright protection.
- **Guidelines & Strategy:**
  - Created `docs/TECH_STACK.md`, `docs/ASSET_GUIDELINES.md`, `docs/ANIMATION_GUIDELINES.md`, `docs/COMBAT_DESIGN.md`, `docs/WEAPON_SYSTEM.md`, `docs/TESTING_STRATEGY.md`, `docs/PERFORMANCE_GUIDELINES.md`, `docs/SECURITY_GUIDELINES.md`, and `docs/GIT_WORKFLOW.md`.
- **Phase Documentation:**
  - Created `docs/PHASES/PHASE_00/SPECIFICATION.md`, `IMPLEMENTATION_PLAN.md`, `TEST_PLAN.md`, and `COMPLETION_REPORT.md`.
- **CI & Quality Automation:**
  - Created GitHub Actions workflow `.github/workflows/ci.yml` for automated headless validation and testing.

#### Security & Integrity
- Verified complete isolation and preservation of archived 3D prototype in `..\exp-1` without importing or altering any legacy files.
- Established strict save-data verification protocols and input clamping standards.\n
