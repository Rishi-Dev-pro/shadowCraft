# Raezen source and deformation audit

Raezen is the final boss in `scenes/enemies/raezan_boss.tscn`. The playable Razen has a separate scene, art library, and moveset. The boss uses `assets/characters/raezan_boss/raezan_sprite_frames.tres` on the inherited Executioner `Silhouette/MinionSprite`. The authored canvas is 512 × 512, the registered floor is y=491, and the boss uses 0.72 scale and a −6 world-pixel visual footline offset. The source drawn facing is right. The campaign mirrors that drawing when facing left.

The brief's 25 clips and 328 frames describe an earlier production inventory. The current resource has **29 definitions, 345 frame slots and 324 distinct PNGs**. The frame directory contains **332 PNGs**, including eight excluded flinch drawings. There are **34 PNG source files**, including original sheets, later replacements, prior user selections and rejected candidates. Audit contact sheets covered every slot in the live resource, including aliases. The unselected flinch prints remain source references. `production_manifest.json` and the seven batch manifests describe provenance, while the scene's assigned SpriteFrames determines what plays.

## Campaign wiring

- World Map unlocks the final encounter through StoryProgression and enters `scenes/arenas/RaezenCitadel.tscn`. The shared arena spawner replaces the training target with `raezan_boss.tscn`. The arena HUD uses the campaign portrait at `assets/ui/world_map/portraits/raezen_battle_portrait.png`.
- `scripts/enemies/raezan_boss.gd` specializes `TheExecutioner` and its inherited `TrainingDummy` physics and floor handling. Its approach and retreat use different clips in each phase. The inherited enemy hitbox, ExecutionerHurtbox, parry/counter route, and HealthComponent remain authoritative.
- The boss has 360 health and changes phase at 50%. Its scene binds the distinct light, heavy, horizontal, vertical, and dash slashes, the parry counter, both Void actions, and the five-hit sequence with individual attack profiles under `resources/attacks/enemy/raezan_*.tres`. The inherited three-step list and the boss's five-step list coexist. The five windows run on physics ticks 8–10, 20–22, 32–34, 44–46 and 56–58, then recover at tick 68. Recovery and cooldowns depend on the attack and phase.
- Void Step uses 0.26 s drive then 0.12 s braking. Its 6 s cooldown is separate from Void Burst's 10 s cooldown, shortened in phase two. Void Burst selects its own Phase 2 art and uses a 480 × 244 collision volume. Guard entry, hold, impact and release are separate presentations. Flinch and knockback have separate stun floors.
- `resources/weapons/void_blade.tres` points at `scenes/weapons/void_blade.tscn`. The independent candidate at `assets/weapons/void_blade/void_blade.png` has a different unregistered grip and silhouette from the weapon in the normalized boss frames. The boss's visible sword is baked into each original drawing, including its tassel, grip occlusion and sometimes its effects. The candidate body has a different arm position and is marked unapproved in its manifest. Neither candidate is the neutral visual master.

## Animation requirements matrix

Counts are runtime slots. Body motion entries include the most important silhouette and overlap risks. The start and end describe the registered artwork, while gameplay recovery is owned by the campaign controller.

| Clip | Frames @ FPS | Start → end | Articulation and planted contact | Weapon, secondary motion and silhouette risks |
|---|---:|---|---|---|
| idle | 8 @ 8 | Low blade stance → loop seam | Tiny chest, elbow and head movement, both boots | Near glove covers grip, blade crosses both legs, hair and coat lag |
| walk | 8 @ 12 | Forward gait alias | Same alternating support and hip travel as forward | Same sword pitch/scarf and ankle occlusion as forward |
| walk_forward | 8 @ 12 | Long stride → cycle seam | Alternate boots, bent swing knee, steady torso | Low one-handed blade, ankle and overlapping thigh plates exchange depth |
| walk_backward | 8 @ 12 | Retreat stride → cycle seam | Low head, alternate support, separate cadence | Low blade, trailing coat changes direction and crosses boots |
| turn | 8 @ 12 | Right stance → left stance | Foot transfer through frontal silhouette | Grip and pauldron swap depth, visible back of hair requires painted keys |
| light_slash | 16 @ 20 | Low ready → low ready | Small shoulder rotation, forward set | Near arm quick extension and recovery, grip passes in front of plates |
| heavy_slash | 16 @ 18 | Low ready → low ready | Deep load, elevated shoulder, wider planted end | Overhead blade, long torso twist, scarf reverses and sparks may share pixels |
| horizontal_slash | 16 @ 20 | Low ready → low ready | Low hip pivot and long forward extension | Sword foreshortening/cross-body occlusion and lateral cloth sweep |
| vertical_slash | 16 @ 18 | Low ready → low ready | Crouched load to rising arc and back | Hand crosses upper-body silhouette, over-shoulder plane and hair overlap |
| five_hit_combo | 20 @ 20 | Ready → ready | Five successive step/reload silhouettes | Repeated sword depth changes, trails on separate future effects track |
| dash_attack | 16 @ 20 | Ready → low drive → ready | Root travel, gathered knees and brake | Blade trails forward lean, hair and sash stretch back in silhouette |
| void_step | 16 @ 18 | Ready → compression/drive → ready | Root motion during low stride, stable floor on exit | Sword held low, near-black/magenta effects overlay boot and cloth |
| guard | 12 @ 12 | Low → lifted cover → low seam | Modest knee/shoulder changes | Blade crosses chest, offhand support and gauntlet overlap |
| high_guard | 12 @ 12 | Guard alias | Identical contact profile to guard | Shares guard frames and occlusion risks |
| guard_entry | 2 @ 12 | Braced low → committed cover | Deepened hip load, feet split | Both forearms close and blade rises across neckline |
| guard_hold | 1 @ 10 | Cover → hold | Fixed low stance on planted boots | Blade passes in front of face and near arm |
| guard_impact | 1 @ 12 | Loaded block contact → held key | Compressed forearms and knees | Sword plane and gauntlets share impact occlusion |
| guard_release | 1 @ 12 | Braced low release → held key | Weight returning to wide combat stance | Hands lower in front of waist plates |
| parry | 16 @ 20 | Low → short high redirect → low | Braced boots and short arm load | Grip rotates rapidly and violet contact intersects blade |
| counterattack | 20 @ 20 | High parry → low ready | Low shoulder drop, weight transfer, rising recovery | Cross-body slash with glow and hand visibility changes |
| void_burst | 20 @ 18 | Ready → charge → release → ready | Plant and compress through broad upper-body arc | Blade, halo and painted burst intersect torso, preserve separate future effects ownership |
| hit | 8 @ 16 | Ready → chest recoil → ready | Mostly planted, shoulder and head lead recovery | Released offhand, blade lag, rear cape opens around thigh |
| knockback | 16 @ 16 | Ready → recoil → grounded fall | Hip displacement then multi-point floor contact | Sword nears floor and disappears behind crossed body layers |
| death | 20 @ 12 | Ready → collapse → prone hold | Knee/hip descent, shoulder and torso floor contact | Sword settles alongside body, soft cloth compresses underneath |
| phase2_idle | 8 @ 10 | Angled ready → seam | Steady boot support and armor weight shift | Lower blade and stronger scarf movement |
| phase2_walk_forward | 8 @ 14 | Drive → seam | Alternate heel and toe with aggressive torso | Plates exchange occlusion near high knee, blade stays ahead |
| phase2_walk_backward | 8 @ 14 | Retreat → seam | Shorter reversed transfer, head holds aim | Sword stays presented, trailing sash changes timing |
| phase2_finisher | 16 @ 20 | Ready → charged lunge → ready | Low body with rising recovery, planted endpoint | Magenta motion effect obscures blade and cloak in selected keys |
| phase2_void_burst | 20 @ 18 | Wide ready → cross-body charge → release | Wide braced base through high arc and recovery | Selected sheet contains effects and changing hand silhouette |

Jump and landing have no dedicated boss clip. They require separate contact markers, hip compression, ankle articulation and a blade clearance test through takeoff and descent. Future dodges, stagger, sword-ready, early cancels and two-hand attacks require a shared grip coordinate and optional offhand target plus explicit depth and correction cues. Large turns, fall/KO and painted effect-heavy slash or Void keys require replacement poses with exclusive surface ownership. Continuous local articulation belongs on the layered rig where the original painting permits it.
