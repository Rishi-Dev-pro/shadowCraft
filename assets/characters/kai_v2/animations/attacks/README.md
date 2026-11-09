# Kai V2 Combat 1 Art

The two six-pose sprite strips in this folder are original combat poses generated for the Kai V2 character using the approved character direction and the combat brief. The supplied combat reference was used only for pose intent; none of its pixels or composite layout are used as game sprites.

`light_jab_source.png` and `front_kick_source.png` are 1536×1024 RGBA sheets. Each uses a 3×2 row-major grid of 512×512 cells. The individual frames are stored as `AtlasTexture` regions in Kai's existing `SpriteFrames` resource, which avoids duplicating the atlas data. The frame order and animation playback rate are recorded in `combat_attack_manifest.json`.

The animation frames keep a consistent 512×512 pivot cell. The existing Kai V2 `Skeleton2D` scale and sprite origin remain the only display scaling. The runtime attack hitboxes are authored separately in the corresponding `AttackData` resources and are not inferred from the artwork.
