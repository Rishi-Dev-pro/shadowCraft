# NEXT SESSION — SHADOWCRAFT 2D

## Guardian II Earthbreaker

Guardian II uses the same Earthbreaker V2 motion as the preview. At blade contact (0.80 s), a short ground hitbox deals 23 damage, or 13.8 through Kai's existing guard. The special has a 12 s cooldown. Review its frequency in unscripted player fights before tuning.

## Hunter combat approval checkpoint

Guardian II now uses Hunter's painted bone layers for his forward walk, horizontal swing, overhead chop, guard, hit recoil and knockback. The approved kneeling defeat still plays through the existing one-shot battle animation. Review the axe and brim overlap in the overhead wind-up and the coat over the passing knee.

## Raezen reference-sheet pose review

- Training integration is verified. Select Raezen in the dojo and use A/D for the approved walk. The full-stride travel rate follows the approved lab cadence. The Training regression passed all 37 checks.

- The isolated comparison lab and walk_review/travel_review.tscn remain available. Each traveling cycle covers 250.56 display pixels at the existing scale.

- Review the free-arm comparison at normal speed beside the full figure. Glove excursion relative to its shoulder measures 39.7 display pixels, up from 13.3 in the approved baseline.

- Review the baseline and refined loops side by side. The revised early heel plant lasts through the first 100 ms of loading on each side. Later stance still uses the approved fixed-root stride.

- The latest fixed-root comparison puts the two ankles at the traced horizontal separation on each key. Key 6 remains the largest mismatch. Its rear knee sits forward of the estimated knee behind the armour. Review the rendered pairs and the loop before considering the Training path. A localized three-quarter rear knee and greave correction is the next art requirement.
- Review the paired eight-pose render and fixed-root loop. The new reference drives the existing experimental rig in the same pose order.
- Architecture review confirmed the matching work is scoped to the existing walk lab. Visual review checks the eight exact keys, both heel contacts, and the loop boundary. Retargeting the reviewed poses to world-space foot locks during gameplay travel is pending approval.

## Raezen in-place walk review

- Review the two-second 30 fps in-place playback before directional integration. The original Hybrid controller still owns gameplay movement.
- Architecture review confirmed the new pose sample consumes time only. Quality review checks root displacement, alternating stance, planted floor contact and the render at the loop boundary.

## Raezen grounded walk review

- Review the matched-speed 30 fps dojo replay before connecting the study to playable Training. The experiment uses the original rig, step poses and sword socket with distance-derived support anchors.
- Architecture review scoped the correction to the existing walk review and motion player. Quality review measured both support boots and the trailing toe in rendered playback and checked the eight exact poses.

## Raezen isolated walk review

- Review `experimental/raezen_hybrid/walk_review/walk_review.tscn` before connecting the new walk to Training. The scene shows the current gait and the eight-pose study at the same scale with both roots fixed.
- Architecture audit traced A/D to the existing ground gait and verified the new knee solver is scoped to the isolated scene. Visual review uses an exact-key sheet and normal-speed replays. Gameplay support anchoring for the new cycle remains pending visual approval.

## Raezen forward walk rebuild

- Run the Raezen walk preview or select Raezen in Training and walk with A/D. The normal-speed fixed-camera comparison pairs the previous walk with the new contact, load, pass, and rise phases.
- Architecture review traced the new walk only through the experimental gait solver and original rig. Quality review checked rendered weight transfer, toe clearance, the blade socket and the integrated sword attack handoff.

## Raezen forward walk review

- Run `experimental/raezen_hybrid/raezen_walk_preview.tscn` to view the walk in isolation, then select Raezen in the existing Training Dojo to try it. Both use the same skeletal gait and authored character layers.
- The architecture review traced the shared gait from physics displacement to the existing leg solver and sword socket. The quality review checked both supporting boots, knee flexion, delayed hair and scarf, and sword recovery in Godot 4.7.2.

## Raezen Training locomotion correction

- Select Raezen in the existing Training Dojo. A/D walk and turn, Ctrl + A/D runs, and S + A/D keeps the current facing for a backstep.
- Architecture review confirmed collision-body movement drives the foot anchors and the rig still hands off to the existing attack controller. Quality review included actual rendered start, stop, left/right turns, forward walk, backward walk, run and sword recovery. The Training regression measures the support ankle in world coordinates during forward steps.

## Raezen Hybrid and Training selection (Milestone 14)

- Open Training from the World Map with Kai selected and choose Raezen through **Switch Character**. Use the on-screen controls to review all five new reaction, kick and get-up profiles in the dojo.
- The original main Void Burst still changes silhouette at the 18 ms paint-to-rig handoff. A future revision needs a Raezen-specific painted bridge that matches the final stance, weapon reach and planted boot. See the experimental Raezen README for the measured limits.
- Architecture review covered the existing player physics slot, a single active controller, shared dummy state and separate campaign routes. Quality review covered the 207 lab checks, 27 roster checks, 21 Kai Training checks, 64 campaign checks, and 969 identical baseline samples.

## Kai skeletal trial and combat experiment (2026-11-18)

- Run `scenes/arenas/grind/kai_skeletal_trial.tscn` directly in Godot. Standard Grind still opens `moonveil_courtyard.tscn` with the painted fighter. Use the two scenes under the same camera for comparison.
- The experimental controls add S for crouch, X for front kick, Q for back dash, and E for forward dash. Dash cooldown begins after the movement and recovery complete. Attacks and defensive locks must finish before dash input is accepted.
- The experimental AI tracks recently committed heavies. After a visible wind-up it can backstep, guard near a wall, or close during a missed swing to punish. The normal Grind and campaign encounter configurations stay separate.
- The skeletal trial shares the grounded two-bone solver with Agile Ninja. Kai has his own pose library and hand and boot contact points. Campaign integration requires a separate visual sign-off and adapter that maps campaign states to the prototype pose interface.

- Verification covered 25 checks in the rendered 1280 x 720 trial, including a full victory, a grounded Kai defeat, both dashes, a guarded heavy, and adaptive whiff punishment. The original Grind suite passed 25 checks. Campaign movement and combat passed 63 and 78 checks. The project reference check reported zero errors and five pre-existing warnings.

## Grind combat refinement (2026-11-18)

- The supplied recording and a Godot reproduction showed the old body capsules allowed a 58-world-pixel gap under forward pressure. The refined grounded sprint test stops at 113 world pixels. Attack steps can close to the physical spacing limit.
- Architecture audit covered the Grind-only capsules, short committed steps, physics-timed active windows, separate decision and recovery states, and local impact pause. The fixed camera and courtyard scene stayed in place.
- Quality audit covered approach, neutral spacing, retreat, guard, close pressure, wall knockback, contact on both moves, victory, and return navigation. Kai's motion still uses authored frame art. Godot passed 38 rendered checks including captures. The input-driven run defeated the normal opponent AI with both attack types. Campaign movement and combat passed 63 and 78 checks.

## Grind animation repair (2026-11-18)

- Review in **World Map → Grind → The Gauntlet → Start Battle** or open the Grind lobby scene directly. The supplied pose guide drove the repair. The referenced gameplay recording was unavailable, so the pre-repair Godot run served as the baseline.
- Architecture audit covered the 2D rig, independent paint layers, a single pose writer, and duel-owned attack phase timing. The project reference checker returned zero errors and five pre-existing orphan UID warnings.
- Quality audit covered alternating foot lift and stance in all three gaits, guard mitigation, timed damage, knockback, collapse, victory, and return navigation in Godot. The campaign movement and combat suites passed 63 and 78 checks respectively.
- Kai still uses the painted frame set. His gait is adjusted at the support foot, so it retains the frame changes of the source drawings. No new campaign art or character rig was introduced.

## Grind Milestone 02 — First Gauntlet bout (2026-11-18)

- Open **World Map → Grind → The Gauntlet → Start Battle**. Moonveil Courtyard hosts one opponent and a local victory or defeat result. The full trial reward remains pending and the prototype leaves the inventory alone.
- On a fresh checkout of this branch, run `scenes/ui/grind_lobby.tscn` directly. The local World Map integration is a separate change. Grind Kai uses a dedicated SpriteFrames resource that references the shared Kai textures required for the bout.
- **Architecture audit:** The arena, fighters, cutout rig, duel controller, AI, attack resources, and HUD are separate from the campaign. The prototype references Kai's SpriteFrames and HealthComponent. The cutout manifest records the user-supplied source and pivots. Built-in ImageGen supplied the courtyard from a brief for an empty moonlit, timber-dojo courtyard with purple lanterns, distant mountains, and a flat open stone floor.
- **Quality audit:** Manually entered the fight through the World Map and inspected the live intro, arena, health bars, and Kai defeat. Rendered checks used controlled inputs and spacing to inspect gait states, both sides' strikes, guard, knockback, the Agile Ninja's grounded collapse, victory, and lobby return. Godot focused checks passed 17/17 headless and 30/30 rendered, including 13 captured frames. World Map 76/76, movement 63/63, and combat foundation 78/78 passed.
- Kai's Grind guard holds an existing anticipation pose. A sustained manual balance pass is still pending. Future opponents and trial rewards require separate authorization.

## Grind lobby animation and visual identity (2026-11-18)

- Open **Grind** from the World Map to replay the entrance. The Gauntlet, Dojo, and Forge keep their approved silhouettes. The Forge remains sealed pending Sensei's instruction.
- Architecture audit covered the existing inventory and World Map route, the shared custom button and dialogue, and two 2D petal batches. Ambient updates stop when the lobby is hidden or the game loses focus. The project reference checker reported zero errors and five existing orphan UID warnings.
- Quality audit included live controls and actual 1280×720 Compatibility renders of each entrance stage, changing petal positions, hover, a held press, the Forge requirement, and the Sensei reveal and dismissal. Regression suites passed for World Map 76/76, movement 63/63, combat 78/78, and character selection 53/53.
- Three 180-frame samples in the focused 1280×720 window measured 51.0 and 52.4 FPS with ambience active and 47.5 FPS with ambience frozen. The respective 95th-percentile frame times were 33.4, 33.5, and 34.8 ms.

## Grind mission-select redesign (2026-11-18)

- Grind opens from the existing World Map menu. The Gauntlet, Dojo, and Forge now occupy a single asymmetrical mission-select composition. Their original art is framed by custom 2D silhouettes. Click any destination or use Tab and Enter to activate it.
- Architecture audit covered the original lobby signal, inventory Resource, dialogs, and map fade. Drawing and hit testing are local to `scripts/ui/grind_mission_panel.gd`. Project reference checker reported zero errors and five pre-existing orphan UID warnings.
- Quality audit covered fullscreen and windowed visuals, all lobby actions, keyboard focus, map return, and live Hunter dossier selection. Automated layout checks catch overlapping anchor ranges and verify silhouette hit areas. World Map 72/72, movement 63/63, combat 78/78, and character selection 53/53 passed.
- The next gameplay milestone requires separate authorization.

## Grind Arena Milestone 01 (2026-11-18)

- Open **Grind** from the existing World Map command menu. The dedicated `scenes/ui/grind_lobby.tscn` is instantiated once inside the map. The map's visual layers are hidden during the lobby visit and restored after the return fade.
- Inventory counts originate from `resources/grind/player_inventory.tres` and start at Wood 0, Stick 0, and Stone 0. The resource supplies presentation data for this milestone. Forge prerequisites and Sensei's initial dialogue are shown in their own panels.
- **Architecture audit:** The lobby uses 2D Controls, one shared navigation panel, a typed inventory Resource, and no frame-based lobby work. It uses the existing map and guardian routing. Reference checker reported zero errors and five existing orphan UID warnings.
- **Quality audit:** Clicked through the lobby, inventory, trial, practice, Forge, guidance, and return controls in the visible Godot game. Checked fullscreen and windowed layouts and launched The Hunter in Mistfall Crossing after leaving Grind. The World Map regression suite passed 66/66 checks. The Executioner suite passed 19/19 assertions and emitted a resource-in-use warning at shutdown.
- **Next:** Wait for authorization before implementing trial gameplay, opponents, a Sensei story unlock, or crafting.

## Battlefield floor alignment correction (2026-11-17)

- Replaced only the three non-dojo arena backgrounds with regenerated 1672×941 art aligned to the Moonlit Dojo's floor/horizon composition. Kai and all guardian assets/transforms/animations were left untouched.
- Removed only the legacy hidden `Environment/ElevatedPlatform` and its one-way collision. The real floor, walls, and jump physics remain.
- Movement test assertions now expect the elevated platform to be absent. Godot 4.7.2 reimport succeeded, Phase 02 movement checks passed 63/63, and actual Compatibility-renderer captures of all four arenas were compared. The fighters share the same ground baseline and the legacy elevated platform is absent.
- Two-pass review completed: arena variants continue to use the shared 2D gameplay floor/camera/character setup; no platform remnants remain; four-stage visual evidence is in `reports/screenshots/arena_floor_alignment_comparison.png`. No commit was made.

## Location-specific guardian battlefields (2026-11-17)

- Added separate Mistfall Crossing, Crimson Sanctum, and Raezen's Citadel backgrounds and inherited arena scenes. The Initiate continues to use the approved Moonlit Dojo.
- World Map routing maps the four guardian IDs to their location scene; all scenes reuse the existing combat template. World Map tests passed 58/58. The new arena renders are `reports/screenshots/arena_mistfall_crossing_runtime.png`, `arena_crimson_sanctum_runtime.png`, and `arena_raezen_citadel_runtime.png`, captured with Godot's Compatibility renderer and visually inspected with the guardian, HUD, and fighters. Manual mouse navigation from the map itself was not exercised.
- No combat, character artwork, progression rules, or dojo changes were made. Work remains uncommitted; preserve unrelated existing changes.

## Latest UI Fix — Raezen rematch (2026-11-17)

- The defeated Raezen dossier now enables `REMATCH` in the existing bottom action button. The button uses the existing battle callback and encounter flow; progression remains intact.
- World Map checks passed (40 checks, 0 failures). No commit was made; preserve unrelated working-tree changes.

## Latest Follow-up — Raezan selected sheets and walk playback (2026-11-17)

- Recovered the two user-selected Phase 2 sheets from the local generated-image archive and preserved them under `assets/characters/raezan_boss/source/batches/batch_08_selected/`. The 16-frame finisher and 20-frame Void Burst are extracted to 512×512 RGBA frames, included in `raezan_sprite_frames.tres`, and previewed at `assets/characters/raezan_boss/previews/phase2_finisher_contact.png` and `phase2_void_burst_contact.png`.
- Walking was integrated already: 8 forward and 8 backward frames are assigned in the SpriteFrames resource. It appeared frozen because inherited `walk` and Raezan's explicit `walk_forward` requests alternated every physics tick and restarted playback. `RaezanBoss._play_animation()` now canonicalizes the generic walk request by phase. The focused Godot check confirmed frame advancement in both phases and source texture paths for both selected sheets.
- Godot 4.7.2 reimported the PNGs; the focused Raezan runtime test passed with 0 failures. Contact sheets were visually inspected. No manual live-arena recording was captured in this pass, so check the gameplay presentation manually if desired.
- Keep the worktree changes uncommitted and preserve unrelated changes. Do not use EvoLink. No additional artwork generation was needed.

## Latest Handoff — Separately Authorized Raezan Final Boss (2026-11-17)

- Raezan is assembled using the existing Executioner-style frame-based architecture: `scenes/enemies/raezan_boss.tscn` inherits the shared guardian scene, uses 25 SpriteFrames animations from 328 extracted PNG frames, and `scripts/enemies/raezan_boss.gd` adds sword attacks, five-hit combo windows, dash, Void Step, Void Burst, phase two and inherited parry/counter behavior.
- Four approved sheets are preserved as reference sources in `assets/characters/raezan_boss/source/prior_user_selected_sheets/`; they are opaque and their small, inconsistent cells (about 98–165px wide) are not suitable for direct production use without risking damaged alpha edges or blur from upscaling. Independent Void Blade image, data and scene remain under `assets/weapons/void_blade/`, `resources/weapons/void_blade.tres` and `scenes/weapons/void_blade.tscn`.
- Focused Raezan test passed with zero failures. All 13 regression suites also passed: hierarchy 44, movement 63, Kai V2 95, Razen V2 113, combat foundation 78, character selection 53, Combat Phase 2 Step 2 66, unarmed Combat Phase 2 124, window manager 4, world map 36, Initiate 60, Hunter 24, Executioner 19.
- Live arena verified visually: the boss scene/HUD load, spawn scale and floor line match Kai, and the Raezan sword-in-hand artwork and attack presentation render. Automated desktop input provided taps, not sustained holds; no successful player hit against Raezan was visually confirmed before defeat. Continue with a hands-on sustained-input fight to verify attacks, combo, guard/parry, Void Step, Void Burst, both phases and win/defeat flow.
- Preserve the current broad working-tree changes; nothing was staged or committed. Do not overwrite the approved four sheets. Current asset limitation: weapon-bearing source frames bake the Void Blade into each character frame; the reusable separate weapon resource is retained but not mounted over those frames.
- Refinement pass: Raezan approach now uses the forward gait in either facing direction; Burst hitbox width is 480px for its intended close range and the hitbox test confirms one damage event; the common hit flinch now uses eight authored frames and knockback gets enough ticks to complete. Guard reduction is 50% with intermittent phase-aware guard decisions. Four newly generated transparent guard poses map to entry/hold/impact/release clips; the fixed physics-tick animation sync is covered by the focused test. Focused Raezan, Executioner (19), combat foundation (78), movement (63) and Razen V2 (113) tests passed. Live arena loaded with correctly scaled Kai/Raezan, but player hit, Burst impact, guard damage reduction and Phase 2 were not confirmed visually; this interaction attempt ended at the defeat screen. Continue with controlled sustained-input acceptance checks.

## Latest Handoff — Guardian III: The Executioner (2026-11-14)

- Visual repair: Executioner idle had a white-matted source sheet; import now decontaminates partially transparent white-composited edge pixels. KO cells now discard disconnected adjacent-pose spill, which caused the second cropped body during defeat. The scene has one AnimatedSprite2D body layer.
- Executioner now uses a uniform 0.72 visual scale and a computed Y offset based on the 512px canvas ground anchor, bringing its rendered height in line with Kai while aligning the feet at Kai's arena footline. Godot GUI captures verified idle/approach, heavy slash, hit reaction and KO; the final KO overlay shows a single fallen body. Kai's defeated pose was also checked in the live arena.
- No gameplay/combat/progression data changed. Do not stage or commit; preserve the unrelated existing worktree changes.
- The Executioner package is integrated at `scenes/enemies/the_executioner.tscn`, with its sprite-frame resource, independent Iron Sword resource/scene, per-move attack data, story map flow, and timed parry-counter path using the existing arena architecture.
- The combo's three contact windows now select distinct `AttackData` resources (`executioner_combo_hit_one/two/three.tres`) so each authored slash has its own geometry and impact values. Focused test `test_the_executioner_guardian.tscn` passed **16/16** on Godot 4.7.2.
- Actual `run_shadowCraft.bat debug` launched; World Map → unlocked Executioner marker → Enter Battle displayed Kai and The Executioner in the real dojo arena. Idle pose, sword-in-frame grip, scale, initial spacing, AI approach and defeat presentation were visually observed. The Windows UI driver can send only key taps, so sustained player movement, deliberate attack hits, and successful parry-counter timing remain unverified.
- Temporary debug progression was restored to the observed previous state: Initiate defeated, Hunter and Executioner locked. No EvoLink was used; no files were staged or committed.
- A separate canonical sword resource exists, but current illustrated animation frames include the sword in the character sprite artwork; the live sprite is not yet driven by a separate animated weapon socket. Preserve this as a known limitation rather than claiming full weapon/pose separation.
- Focused scene/resource validation passed, `git diff --check` passed on the intended edits, and the animation manifest parsed as JSON. Broader `--script` regression invocation did not yield reliable process summaries in this session; rerun suites using the project’s supported runner before declaring the whole deliverable complete.

## Latest Handoff — Story Guardian II: The Hunter (2026-11-14)

- World Map guardian dossiers now retain the DEFEATED badge and show an enabled REMATCH button for The Initiate and The Hunter; it routes through their existing playable encounter flow. Executioner and Raezen behavior was left unchanged.
- Latest visual correction: World Map dossier now points back to the original map-specific Hunter bust (`assets/ui/world_map/portraits/guardian_hunter_portrait.png`). The Hunter axe remains an independent scene/resource; `WeaponSocket`, the sprite grip pivot and separate idle/movement/guard/hit/attack pose values were adjusted to put the diagonal handle through the raised hands. No artwork changed. The current CUA preview only rendered its status label over a blank canvas, so do not claim the axe grip has passed visual verification; resolve the rendering preview and inspect in the running arena next.
- Guardian II is implemented as an isolated character package under `assets/enemies/the_hunter/`, with 60 transparent 512×512 frames across idle, forward/backward movement, axe attacks, guard, hit and death, plus an independent portrait and provenance manifest.
- The Stone Axe is a separate reusable `WeaponData` resource, scene and texture under `resources/weapons/stone_axe.tres`, `scenes/weapons/stone_axe.tscn` and `assets/weapons/stone_axe/stone_axe.png`; The Hunter mounts the same scene independently of his sprite frames for future Forge reuse.
- The Hunter uses the shared enemy/combat structure and dedicated light/heavy/sweep attack resources. Existing progression now allows Guardian II only after Guardian I; Hunter victory unlocks Guardian III without unlocking Raezen.
- Focused Hunter test passed **27/27**; Guardian I **60/60**, Phase 02 movement **63/63**, Kai V2 **95/95**, combat foundation **78/78**, World Map progression **30/30**, and Phase 01 hierarchy **44/44** passed in Godot 4.7.2. Headless editor scan exited 0 with no reported errors. Actual game was opened through intro → logo → map → Hunter battle and visually showed Kai, The Hunter, the axe, approach behavior and the defeat overlay. This visual pass did not manually exercise every attack input or every animation frame.
- `project.godot` was byte-restored after the temporary focused-test launch. No files were staged or committed; preserve the large existing unrelated dirty/untracked worktree. Stop here pending user review; do not proceed to Guardian III or Forge implementation without authorization.

## Latest Handoff — Story Guardian I: The Initiate (2026-11-14)

- Critical combat repair completed: Kai attack presses are buffered during startup and near hitstun recovery; normal attack reach is unchanged, so early attacks at spawn distance correctly whiff until the Initiate approaches. Kai's grounded backstep reduces damage by 40%. Initiate attack cooldowns are now 3.0 seconds for jab/kick and 3.6 seconds for heavy/roundhouse; attack damage remains unchanged.
- Focused live-scene regression: 60/60 Initiate checks passed; Phase 01 hierarchy 44/44, Phase 02 movement 63/63, Kai V2 95/95, combat foundation 78/78, Phase 2 Step 1 124/124, and Step 2 66/66. A Godot-rendered capture confirmed the Z→Z→C chain, direct C and X kick, health reductions, and return to idle. No changes staged or committed.
- Actual arena capture evidence: `reports/videos/critical_combat_repair_20261114_debug.avi`; contact sheet: `reports/screenshots/critical_combat_repair_final_contact.png`. The desktop window capture surface was unreliable, so this was verified through the real arena scene rendered by Godot with scripted InputMap events, not manual keyboard interaction.
- The shared Training Dojo target is back to its original unadorned robotic-minion SpriteFrames; its standalone ponytail and sakura overlays were removed from the shared scene/script.
- A separate original female Initiate package lives under `assets/enemies/the_initiate/`: generated source sheets, transparent 512×512 frames, fixed floor anchor, contact sheets, SpriteFrames and provenance manifest. `scenes/enemies/the_initiate.tscn` inherits the shared dummy collision/health/hurtbox structure.
- Story encounters replace only the arena's TrainingDummy slot with the dedicated Initiate scene. Kai remains the story fighter; training continues to use the original non-attacking minion.
- Initiate has independent 140 HP, data-defined jab/heavy punch/front kick/roundhouse, forward approach, occasional guarded retreat, hit reaction, and a one-shot fall that retains the established victory/progression flow. Attack poses are held through data-defined recovery timing.
- Godot 4.7.2 Compatibility arena capture and combat regressions are complete for this repair. GUI keyboard injection was unavailable, so controls were exercised through scripted InputMap events in the actual arena scene. No commit was made; preserve unrelated working-tree changes.

---

## Latest Handoff — Phase 6A World Map Hub (2026-11-11)

- **World Map Hub Implementation (`scenes/ui/world_map.tscn`):**
  - High-res clean Japanese fantasy background landscape (`assets/ui/world_map/world_map_background_extracted.png`, 995×941) displayed responsive and centered with a deep midnight purple backdrop and drifting sakura petals (`CPUParticles2D`).
  - Animated glowing dotted neon path rendered via custom `_draw()` on `RouteLayer` with pulsing waypoint beacons connecting all four landmarks.
  - Interactive `GuardianMarker` instances positioned via normalized coordinates:
    - **The Initiate (Guardian I):** Available by default.
    - **The Hunter (Guardian II):** Unlocks upon defeating The Initiate.
    - **The Executioner (Guardian III):** Unlocks upon defeating The Hunter.
    - **Raezen's Citadel (Final Boss):** Unlocks upon defeating all three guardians.
  - **Right Journey Panel (`scenes/ui/world_map/journey_panel.tscn`):**
    - Dynamic panel styling matching Image 4 reference with high-res Raezen portrait, lore, 0/3 progress bar, guardian status list with individual lock/unlock pills, and battle action button ("ENTER BATTLE" / "FIGHT RAEZEN").
    - Encounter modal dialogue explains Phase 6B arrival with one-click direct transition into the Training Dojo.
  - **Left Navigation Dock (`scenes/ui/world_map/left_nav_panel.tscn`):**
    - Floating vertical glass dock offering `STORY MODE` (active indicator), `TRAINING DOJO` (loads `MovementTestArena.tscn`), `WEAPON FORGE` ("Coming Soon in Phase 7" toast), and `CHANGE FIGHTER` (returns to `character_select.tscn`).
    - Lower card dynamically reflects the active fighter selected in `CharacterSelection` state.
  - **Story Progression Autoload (`scripts/systems/story_progression.gd`):**
    - Autoload singleton `StoryProgression` with persistent JSON storage (`user://story_progression.json`), unlock evaluation, and victory tracking.
  - **Startup Flow Integration:**
    - Intro Cinematic → Logo Screen → Character Selection → World Map Hub → Training Dojo / Story Encounters.
    - Added "WORLD MAP" button to in-arena pause menu (`scripts/ui/pause_menu.gd`).
  - **Automated Verification:**
    - `tests/unit/test_world_map.gd` (29 checks, 0 failures).
    - Full regression suites verified: Window Manager (4/4), Character Selection (53/53), Combat Foundation (78/78). Total: 164 checks, 0 failures.
  - **Visual Runtime Verification:**
    - Verified OpenGL compatibility captures: `reports/screenshots/world_map_hub_runtime.png` and `reports/screenshots/world_map_hub_razen_selected.png`.
  - **Strict Constraints Respected:**
    - Zero modifications to character art, animations, movement/combat physics, attack resources, or the dojo arena.
    - Working tree left uncommitted for human review.

---

## Historical Handoff — Phase 5 Moonlit Dojo and HUD

- Added `assets/arenas/moonlit_dojo/moonlit_dojo_background.png` and `assets/ui/portraits/kai_hud_portrait.png`; the playable `MovementTestArena` displays the dojo behind the existing live fighters and collision world.
- The HUD now has live player/minion health bars and numeric values, a Kai portrait (Razen uses a crop from existing Razen gameplay art), a minion portrait crop from its existing idle frame, centered logo/round labels, current controls, and lower-right branding. Telemetry remains available with `--combat-debug`.
- New assets were imported with Godot 4.7.2. Run one visual check at 1280×720 and adjust only layout/scale if needed. Do not change combat, movement, AI, damage, hitboxes, or gameplay animation for this pass. No commit was made.

## Current State — Combat Phase 2, Step 2 Integrated (2026-11-11)

- Approved Cross/Heavy art is mapped into each fighter's `SpriteFrames`, with independent `AttackData`, contact-timed active windows and per-active-frame hitbox positions.
- Each fighter's jab chains into Cross on Z, then Cross chains into Heavy on C. C also starts Heavy directly from neutral. Roundhouse and Sweep remain unassigned; Step 3 was not started.
- The shared movement/combat controllers, health, hitboxes, hit-stop and dummy presentation remain the existing implementation.
- Godot 4.7.2 was unavailable in this workspace session. Run the builders, focused and regression suites, then visually verify both fighters' full Z → Z → C sequences before considering Step 2 closed.

## Next Immediate Action

Complete Godot runtime verification of the Step 2 animations, hitbox contact and chain recovery. Do not start Step 3 or another combat milestone until the user approves that verification.

---

Historical handoff below reflects the state before the Step 2 art approval; its “blocked on artwork” section is superseded by the current state above.

# Latest Handoff — Round-end Screen and Defeat Flow (2026-11-11)

- Defeat presentation is delayed until Kai/Razen's fall and grounded defeated pose finish; the minion's K.O. presentation waits for its death animation. The result overlay is on CanvasLayer 20 so it renders above fighter sprites and remains legible, with the fallen fighter visible dimly behind it.
- The minion disables its current attack/hitbox and stops AI once the selected hero's health reaches zero. K.O. means player win; Defeat means minion win. Both pause play and offer Rematch or Character Select.
- Headless Godot 4.7.2 load of `MovementTestArena.tscn` completed without errors. Capture/inspect both terminal screens visually before further UI changes. No files were staged or committed.

## Current State — Combat Phase 2, Step 1 Complete (2026-11-10)

- The combat layer is now moveset-driven. `CombatController` reads an assigned `MovesetData` (chain roots, direct heavy/roundhouse/sweep slots, `buffer_ticks`, `chain_window_ticks`), buffers presses during active/recovery, and links into `AttackData.chain_next` inside the combo window while movement stays locked.
- Each fighter owns independent attack data: `resources/attacks/kai/` preserves the approved Kai numbers exactly, `resources/attacks/razen/` gives Razen 16-tick attacks (6/2/8) matching his approved 8-pose clips with heavier damage, knockback, hitstun and hit-stop. Both scenes assign `resources/movesets/*_moveset.tres` instead of shared attack slots.
- Incoming hits use one path (`Hurtbox2D` → `on_combat_hit`); the duplicate listener that reset hitstun to 12 frames is gone. Hit-stop and impact scale now come from `AttackData`.
- Verified: Step 1 suite 97/97 plus all six regressions (Combat 78/78, Kai V2 95/95, Razen V2 113/113, selection 53/53, Phase 01 44/44, Phase 02 63/63 from the committed file). Rendered captures are in `reports/screenshots/phase2_step1/`.
- Step 1 adds no art. Direct heavy/roundhouse/sweep slots and all chains are intentionally empty, and crouched attacks remain rejected until Step 3 adds sweep art and the crouch-lock handling.

## Follow-ups completed after Step 1 (2026-11-10)

- `tests/unit/test_player_movement.gd` is repaired and the working-tree Phase 02 suite runs 63/63.
- Crouch posture is now explicit: `CharacterController2D.combat_crouch_lock` is driven by the active attack's `AttackData.stance`, so a crouched attack keeps the crouch state and collision capsule for its whole animation without crouch input, and standing attacks never take the lock.
- Razen's Front Kick hitbox was realigned to his authored boot (offset y −216); his jab and all Kai geometry are unchanged. Phase 2 suite is 122/122.

## Historical Handoff — Step 2 Awaited Artwork

Step 2 (Cross Punch and Heavy Punch for both fighters) needs four original sprite sheets before it can be built honestly: Kai Cross 6 poses, Kai Heavy 10 poses, Razen Cross 8 poses, Razen Heavy 12 poses, at 512×512 cells with a transparent background, ground-anchored boots and a right-facing three-quarter view, matching the existing Kai V2 and Razen illustration style.

Timing, hitbox trajectories and chain linking must be authored from those poses, so no `AttackData`, moveset chain or animation slot for Cross/Heavy has been written yet. Once the sheets exist, the work is: atlas import (3×2 / 4×2 / 5×2 grids), per-character `AttackData` with startup/active/recovery derived from the contact pose, hitbox offsets measured from the limb, and `chain_next` wiring from the jabs (**Z** jab → cross → heavy) with the existing buffer and chain-window rules.

Do not start Step 3 (Roundhouse and Sweep) or another phase without written authorization. Nothing has been staged or committed.

## Previous State — Playable Character Selection Complete (2026-11-10)

- F5 and `run_shadowcraft.bat` start at `scenes/ui/character_select.tscn`. The selector shows animated Kai V2 and Razen idle previews, mouse cards, A/D or arrow selection, and PLAY.
- The selected fighter is instantiated into the existing `MovementTestArena` through one spawner. Both use the existing movement controller, arena, Combat 1 attack definitions, hitbox pipeline and damageable TrainingDummy. Razen has separate jab/kick animation clips in its own SpriteFrames asset.
- ESC pauses. Resume returns to play; Change Character unpauses and returns to the selector. The selection remains available for the next entry.
- Godot 4.7.2 Compatibility renderer captures: `reports/screenshots/character_selection_runtime.png`, `reports/videos/character_selection_runtime.avi`, `reports/videos/kai_selection_gameplay.avi`, and `reports/videos/razen_selection_gameplay.avi`. Capture logs are in `reports/logs/`.
- Regression results: Phase 01 44/44; Phase 02 63/63; Kai V2 95/95; Razen V2 113/113; Combat 1 78/78; selection 53/53. The capture showcase log confirms both shared attacks hit the dummy for each character.
- Both implementation audits and capture details are documented in `docs/CHARACTER_SELECTION.md`.

## Next Immediate Action

Wait for user review of the actual selection screen and both playable characters. Do not start combos, Combat 2, defense, additional combat, boss AI, or another project phase without explicit authorization.

## Prior Handoff — Razen Character Package (2026-11-10)

- Completed the authorized Razen production steps 3–6 in an isolated package. Razen has 56 original animation frames plus the approved signature pose, a CharacterData resource, standalone `Razen.tscn`, and a presentation-only animation controller reusing `CharacterController2D`.
- Godot resource build and focused test completed: Razen 93/93. Actual Compatibility-renderer captures are in `assets/characters/razen/previews/rendered/`; review recording: `assets/characters/razen/previews/razen_v2_review.avi`.
- Await visual approval of Razen before further character work. Do not begin Phase 08 boss AI/encounters. The attack-presentation clip is not a combat mechanic.
- F5 still launches Kai V2 in `MovementTestArena.tscn`; Kai and existing combat were not modified by this Razen task.

## Prior Handoff — Unified Movement and Combat Runtime (2026-11-10)

- Kai V2 is integrated and remains the playable character in `scenes/arenas/MovementTestArena.tscn`, the F5 main scene. The old Kai scene remains available as `scenes/characters/KaiLegacy.tscn`.
- The main/F5 `MovementTestArena.tscn` now composes the existing Combat 1 damageable TrainingDummy and its health/hurtbox without duplicating Kai's controller, combat state machine or health system. Movement, crouch, jump and physics remain owned by the existing controller.
- Controls in the Combat Test Arena: A/D move backward/forward, Space jump, S crouch, Z Light Jab, X Front Kick. The dummy is a damageable test target, not an AI opponent.
- Attack logic is data-driven through `resources/attacks/light_jab.tres` and `front_kick.tres`. Contact windows align with the dedicated six-frame animation clips, and each active physics frame has a matching hitbox offset. Confirmed contact triggers short hit-stop, a small impact spark and a tuned dummy recoil. Damage and collision architecture are preserved.
- Double-click `run_shadowcraft.bat` (or press F5 in the editor) for movement and combat in the same arena; `run_shadowcraft.bat debug` shows the attack hitbox. Launcher discovery covers supported Godot 4.7.2 locations, PATH and `GODOT4_EXE`, validates the engine, and persists output to `reports/logs/shadowcraft_latest.log`. `run_combat.bat` remains a separate development test scene, not a gameplay requirement.
- Evidence for the launch repair: normal-speed runtime capture `reports/videos/combat_launch_after.avi`, active hitbox view `reports/screenshots/combat_launch_kick_debug.png`, jab `reports/screenshots/combat_launch_jab.png`, and successful kick/contact `reports/screenshots/combat_launch_impact.png`.
- Final integration regression results are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`: Combat **78/78**, Kai V2 **95/95**, Phase 02 **63/63**, Phase 01 **44/44**. Godot 4.7.2, Compatibility renderer.
- Two-pass audits are recorded in `docs/PHASES/PHASE_03/COMPLETION_REPORT.md`. No performance benchmark was taken; the fixed-rate recordings are visual evidence, not FPS measurements.

## Next Immediate Action

Wait for the user's visual verification of the unified playable launcher. Do not begin the Combo Engine, input buffering, defense, additional attacks, shadow specials, weapons, enemies, or later phases until explicitly authorized.

## Project Preservation Notes

- Preserve all existing user changes in the working tree; the checkout contains unrelated movement-playtest screenshots and scripts from earlier work. Stage only files listed for Combat 1.
- Do not modify the archived `D:\projects 2.0\games\exp-1` project.
- Combat 1 was committed as `c80e0e5`; Combat 1.1 is a separate scoped polish commit after review.

## Existing Movement Review Note

The earlier forward/backward gait review recorded significant planted-foot excursion and stiffness in `docs/CHANGELOG.md`. That movement-only concern remains separate from this Combat 1 task and is not modified here.

## Active Work — The Initiate Story Battle (2026-11-13)

- The Initiate is wired to the existing arena with Kai forced as the player, dedicated jab/kick data, existing minion AI/health/hitboxes, defensive retreat, confirmed-hit feedback, KO/defeat flow, and persistent unlock recording after the fall animation.
- The user most recently asked to generate a transparent ponytail and sakura shoulder emblem. Do not use the API key previously pasted into chat; advise revocation. The process environment now provides `OPENAI_API_KEY` without exposing it; the OpenAI Python package is prepared in a temporary environment. A ponytail image edit was rejected by the API with HTTP 429 (no credits remaining); generate neither accessory until credits are available. The user approved the `gpt-image-1.5` CLI path.
- Godot 4.7.2 is installed at `C:\Users\USER\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64.exe`. The normal launcher visibly opened the World Map and the Initiate encounter reached the K.O. screen. Automated results: Initiate **19/19**; World Map **30/30**; character selection **53/53**; combat foundation **78/78**; Phase 02 movement **63/63**; Phase 01 hierarchy **44/44**; Kai V2 **95/95**. The `Start-Process` invocation must quote the project path because it contains spaces. Complete remaining visual review without modifying Kai/Razen or later guardians.
- No commit was made. Preserve all unrelated pre-existing working-tree changes.
