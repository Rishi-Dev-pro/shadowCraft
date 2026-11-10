# Character Selection and Playable Roster

The project main scene is `res://scenes/ui/character_select.tscn`. The selector previews the real looping idle `SpriteFrames` from Kai V2 and Razen, supports mouse cards, A/D or left/right selection, and Enter/Space or PLAY to continue.

`CharacterSelectionState` is the single autoload storing the selected character ID and scene path. `MovementTestArena` owns one `ArenaCharacterSpawner`; it instances the selected `CharacterController2D` scene into the established `Fighters/Kai` slot to preserve paths used by arena UI and combat components. Both characters keep their own `CharacterData`, `SpriteFrames`, and animation controller while using the existing movement controller, attack resources, hitbox, health and training dummy. Razen's scene carries the shared Light Jab and Front Kick combat components and character-specific animation clips.

ESC opens an always-processing pause overlay. Resume restores play; Change Character unpauses and returns to the selector. The selector retains the current choice until the player changes it.

## Controls

- A / Left: select Kai; D / Right: select Razen. In play: A moves backward and D moves forward.
- Enter / Space or click PLAY: start with the selected fighter.
- Space: jump; S / Down: crouch; Shift + forward: run.
- Z: Light Jab; X: Front Kick.
- ESC: pause; Change Character returns to the selector.

## Verification artifacts

- Selector capture: `reports/screenshots/character_selection_runtime.png`; 90-frame 30 FPS capture: `reports/videos/character_selection_runtime.avi`.
- Actual arena showcases: `reports/videos/kai_selection_gameplay.avi` and `reports/videos/razen_selection_gameplay.avi`, recorded at 1280×720, 30 FPS with Godot 4.7.2 Compatibility renderer. Runtime logs are in `reports/logs/`.
- Integration runner: `tests/integration/character_selection_capture.gd`; pass `--capture-razen` after `--` to render Razen, and `--integration-showcase` to drive movement, whiff/confirmed attacks and jump for capture.
- Regression suites: Phase 01 hierarchy, Phase 02 movement, Kai V2, Razen V2, Combat 1 foundation and character selection. The selection suite covers both real character scenes, shared combat/dummy damage, repeated instantiation, and pause/return flow.

## Two-pass audit

1. **Architecture and consistency:** F5 points at the selector; one autoload owns choice; one spawner fills the established player slot; the arena keeps one shared movement/combat/dummy implementation; both chosen scenes expose the required components and matching animation clips. Only 2D scene nodes are added. Kai's legacy rollback scene and the archived `exp-1` project are untouched.
2. **Quality and completeness:** Reviewed all new UI/spawner/state scripts and changed scene/resource mappings; Godot loaded and rendered the selector and both playable fighters through the actual Compatibility renderer; all six regression suites passed at the totals listed above; `git diff --check` was run. Unrelated pre-existing working-tree changes were excluded from the scoped commit.

This is a character-select and runtime-integration deliverable. It does not authorize additional combat milestones, boss behavior or a project phase transition.
