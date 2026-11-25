extends Node

const ARENA_SCENE: PackedScene = preload("res://scenes/arenas/MovementTestArena.tscn")
const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const CharacterSelectionState = preload("res://scripts/systems/character_selection_state.gd")

var _checks: int = 0
var _failures: int = 0
var _progression: StoryProgressionState
var _selection: CharacterSelectionState
var _saved_exists: bool = false
var _saved_contents: String = ""
var _previous_character: StringName = &"kai"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_saved_exists = FileAccess.file_exists(StoryProgressionState.SAVE_PATH)
	if _saved_exists:
		var save_file: FileAccess = FileAccess.open(StoryProgressionState.SAVE_PATH, FileAccess.READ)
		if save_file != null:
			_saved_contents = save_file.get_as_text()
			save_file.close()
	_progression = get_tree().root.get_node_or_null("StoryProgression") as StoryProgressionState
	_selection = get_tree().root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if _progression == null:
		_progression = StoryProgressionState.new()
		_progression.name = "StoryProgression"
		get_tree().root.add_child(_progression)
	if _selection == null:
		_selection = CharacterSelectionState.new()
		_selection.name = "CharacterSelection"
		get_tree().root.add_child(_selection)
	_previous_character = _selection.get_selected_character()

	_progression.reset_progress()
	_assert(_progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_INITIATE), "Guardian I remains available at the start")
	_assert(not _progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_HUNTER), "Guardian II stays locked before Guardian I is defeated")
	_assert(not _progression.begin_guardian_encounter(StoryProgressionState.GUARDIAN_HUNTER), "Locked Hunter encounter cannot start")
	_progression.record_guardian_victory(StoryProgressionState.GUARDIAN_INITIATE)
	_assert(_progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_HUNTER), "Guardian I victory unlocks The Hunter")
	_assert(_progression.begin_guardian_encounter(StoryProgressionState.GUARDIAN_HUNTER), "Unlocked Hunter encounter can start")
	_selection.select_character(&"razen")

	var arena: MovementTestArenaController = ARENA_SCENE.instantiate() as MovementTestArenaController
	get_tree().root.add_child(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var hunter: TheHunter = arena.dummy_target as TheHunter
	_assert(hunter != null, "Guardian II replaces the training target with the dedicated Hunter scene")
	_assert(arena.player.character_data.display_name == "Kai", "Story battle selects Kai regardless of prior playable selection")
	_assert(hunter != null and hunter.ai_enabled, "The Hunter AI is enabled in the story encounter")
	if hunter != null:
		_assert(hunter.health_component.max_health == 180.0, "The Hunter uses its own Guardian II health value")
		_assert(hunter.weapon_data.weapon_id == &"stone_axe", "The Hunter scene references the canonical reusable Stone Axe data")
		var sprite_frames: SpriteFrames = hunter.minion_sprite.sprite_frames
		_assert(sprite_frames.resource_path.ends_with("the_hunter_axe_wielding_v2_sprite_frames.tres"), "The Hunter uses the axe-in-hand animation package")
		var expected_frames: Dictionary[StringName, int] = {
			&"idle": 8, &"walk": 8, &"walk_backward": 8,
			&"light_axe": 6, &"heavy_axe": 8, &"axe_sweep": 8,
			&"spin_axe": 10, &"guard": 4, &"hit": 6, &"death": 37,
		}
		var all_frames_are_transparent_512px: bool = true
		for animation_name: StringName in expected_frames:
			var animation_count: int = sprite_frames.get_frame_count(animation_name)
			if animation_count != expected_frames[animation_name]:
				all_frames_are_transparent_512px = false
				continue
			for frame_index: int in range(animation_count):
				var texture: Texture2D = sprite_frames.get_frame_texture(animation_name, frame_index)
				var frame_image: Image = texture.get_image() if texture != null else null
				if frame_image == null or frame_image.get_size() != Vector2i(512, 512) or frame_image.get_pixel(0, 0).a != 0.0:
					all_frames_are_transparent_512px = false
		_assert(all_frames_are_transparent_512px, "All Hunter frames have the requested counts, 512x512 cells and transparent corners")
		_assert(hunter.enemy_hitbox.attack_data == hunter.light_axe_attack, "Hunter hitbox is configured with his dedicated light axe data")
		var reusable_axe_scene: PackedScene = hunter.weapon_data.weapon_scene
		var reusable_axe: Node2D = reusable_axe_scene.instantiate() as Node2D if reusable_axe_scene != null else null
		var axe_sprite: Sprite2D = reusable_axe.get_node_or_null("Sprite2D") as Sprite2D if reusable_axe != null else null
		_assert(axe_sprite != null and axe_sprite.texture != null, "The canonical Stone Axe remains available as an independent reusable scene")
		var weapon_socket: Node2D = hunter.get_node_or_null("Silhouette/WeaponSocket") as Node2D
		_assert(weapon_socket != null and weapon_socket.get_child_count() == 0, "The illustrated grip poses do not receive a second overlaid axe sprite")
		var axe_image: Image = axe_sprite.texture.get_image() if axe_sprite != null and axe_sprite.texture != null else null
		_assert(axe_image != null and axe_image.get_format() == Image.FORMAT_RGBA8 and axe_image.get_pixel(0, 0).a == 0.0, "The shared axe texture keeps its transparent game background")
		if reusable_axe != null:
			reusable_axe.free()
		var hunter_x_before: float = hunter.global_position.x
		var received_axe_hits: Array[float] = []
		hunter.enemy_hitbox.target_hit.connect(func(_target: Hurtbox2D, damage: float) -> void: received_axe_hits.append(damage))
		await get_tree().create_timer(5.0).timeout
		_assert(hunter.global_position.x < hunter_x_before, "Hunter approaches Kai when the fight begins outside his attack range")
		_assert(hunter.minion_sprite.flip_h, "Hunter faces Kai while approaching from the right")
		var each_hit_is_one_authored_move: bool = true
		for damage: float in received_axe_hits:
			if not (is_equal_approx(damage, hunter.light_axe_attack.base_damage) or is_equal_approx(damage, hunter.heavy_axe_attack.base_damage) or is_equal_approx(damage, hunter.sweep_axe_attack.base_damage)):
				each_hit_is_one_authored_move = false
		_assert(each_hit_is_one_authored_move, "Hunter damage events use one configured axe attack per target contact")
		print("  Hunter live attack trace: %s; Kai HP %.1f/%.1f" % [received_axe_hits, arena.kai_health.current_health, arena.kai_health.max_health])
		hunter.ai_enabled = false
		hunter._deactivate_enemy_hitbox()
		hunter.velocity = Vector2.ZERO
		hunter.health_component.restore_full()
		for _frame: int in range(180):
			if arena.combat.current_state == CombatController.State.NEUTRAL and arena.player.is_grounded:
				break
			await get_tree().physics_frame
		arena.kai_health.restore_full()
		arena.player.global_position = Vector2(500.0, 560.0)
		arena.player.velocity = Vector2.ZERO
		arena.player.is_grounded = true
		arena.player.current_state = CharacterController2D.State.IDLE
		arena.player.target_opponent = hunter
		arena.player.set_facing(true)
		hunter.global_position = Vector2(632.0, 560.0)
		var combat: CombatController = arena.combat
		var light_attack: AttackData = combat.get_light_attack()
		var hunter_health_before: float = hunter.health_component.current_health
		var light_attack_started: bool = combat.start_attack(light_attack)
		_assert(light_attack_started, "Kai's light attack can start against The Hunter")
		if light_attack != null:
			for _frame: int in range(light_attack.get_total_frames() + 5):
				await get_tree().physics_frame
			_assert(is_equal_approx(hunter_health_before - hunter.health_component.current_health, light_attack.base_damage), "Kai's light attack damages The Hunter once through the existing hurtbox path")
		var completions: Array[int] = []
		hunter.defeat_animation_finished.connect(func() -> void: completions.append(hunter.minion_sprite.frame))
		hunter.health_component.apply_damage(hunter.health_component.max_health * 2.0)
		hunter.health_component.apply_damage(10.0)
		await get_tree().create_timer(2.1, true).timeout
		_assert(completions == [36], "Hunter finishes the kneeling defeat once on the held frame")
		_assert(hunter.minion_sprite.frame == 36 and not hunter.minion_sprite.is_playing(), "Hunter remains kneeling after the round ends")
		get_tree().paused = false
		_assert(_progression.is_guardian_defeated(StoryProgressionState.GUARDIAN_HUNTER), "Hunter victory can be saved through existing story progression")
		_assert(_progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_EXECUTIONER), "Hunter victory unlocks Guardian III without changing earlier gates")
		_assert(not _progression.is_guardian_unlocked(StoryProgressionState.BOSS_RAEZEN), "Guardian III remains required before Raezen unlocks")
		_progression.end_guardian_encounter()
	arena.queue_free()
	await get_tree().process_frame
	_selection.select_character(_previous_character)
	_restore_progress()
	print("THE HUNTER GUARDIAN: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(_failures)


func _restore_progress() -> void:
	if _saved_exists:
		var save_file: FileAccess = FileAccess.open(StoryProgressionState.SAVE_PATH, FileAccess.WRITE)
		if save_file != null:
			save_file.store_string(_saved_contents)
			save_file.close()
	else:
		var absolute_path: String = ProjectSettings.globalize_path(StoryProgressionState.SAVE_PATH)
		if FileAccess.file_exists(StoryProgressionState.SAVE_PATH):
			DirAccess.remove_absolute(absolute_path)
	if _progression != null:
		_progression.load_progress()
		_progression.end_guardian_encounter()


func _assert(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] " + description)
	else:
		_failures += 1
		printerr("[FAIL] " + description)
