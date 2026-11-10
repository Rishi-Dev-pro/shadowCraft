# Razen — Isolated Character Package

Razen is an independent playable character presentation package built after approval of the signature ready pose. The supplied reference sheet guided identity, armor and motion; it was not cropped or shipped as sprite pixels.

## Assets

- `poses/signature_ready.png`: approved transparent 512×512 pose. It remains unchanged and is used verbatim as idle frame 1, landing frame 4, presentation endpoints and the one-frame `combat_ready` presentation.
- `source/animation_sheets/`: nine original generated sheets for idle, forward/backward walk, run, crouch, crouch walk, jump, landing and attack presentation.
- `animations/<name>/<name>_NN.png`: normalized transparent 512×512 frames with shared frame center and floor anchor. Run and jump use per-frame vertical anchors for airborne silhouettes.
- `previews/<name>_contact.png`: source-frame contact sheets. `previews/rendered/` contains actual Godot-rendered clips for every animation family; `previews/razen_v2_review.avi` is the Compatibility-renderer review recording.
- `animation_manifest.json`: frame paths, counts, timing, sheet provenance and anchoring metadata.
- `razen_manifest.json`, `generation_prompt.txt`: visual provenance and generation direction.

## Runtime

`scenes/characters/Razen.tscn` uses shared `CharacterController2D`, `resources/characters/razen.tres` and `razen_animation_controller.gd`. It contains no AI, hitbox, health component or combat logic. `attack_presentation` is a view-only authored sequence for future presentation, not an attack mechanic.

Build SpriteFrames with Godot 4.7.2:

```powershell
godot --headless --path . --script res://scripts/characters/razen_sprite_frames_builder.gd
```

Use `scenes/arenas/RazenAnimationPreview.tscn` for the independent review. The project's F5 main scene remains unchanged.
