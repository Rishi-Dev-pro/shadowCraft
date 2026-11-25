extends Node

const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const CharacterSelectionState = preload("res://scripts/systems/character_selection_state.gd")
const ARENA_SCENE: PackedScene = preload("res://scenes/arenas/MovementTestArena.tscn")

var _checks: int = 0
var _failures: int = 0
var _progression: StoryProgressionState
var _selection: CharacterSelectionState
var _saved_story_file_exists: bool = false
var _saved_story_file_contents: String = ""
var _previous_character_id: StringName = &"kai"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_tests")


func _run_tests() -> void:
	_backup_player_state()
	_progression = get_tree().root.get_node_or_null("StoryProgression") as StoryProgressionState
	if _progression == null:
		_progression = StoryProgressionState.new()
		_progression.name = "StoryProgression"
		get_tree().root.add_child(_progression)
	_selection = get_tree().root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if _selection == null:
		_selection = CharacterSelectionState.new()
		_selection.name = "CharacterSelection"
		get_tree().root.add_child(_selection)

	_progression.reset_progress()
	_assert(_progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_INITIATE), "Initiate is the first unlocked story guardian")
	_assert(not _progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_HUNTER), "Hunter stays locked before the Initiate is defeated")
	_assert(_progression.begin_guardian_encounter(StoryProgressionState.GUARDIAN_INITIATE), "Initiate encounter can start")
	_assert(not _progression.begin_guardian_encounter(StoryProgressionState.GUARDIAN_HUNTER), "Later guardian encounter is rejected")
	_assert(_progression.active_guardian_encounter == StoryProgressionState.GUARDIAN_INITIATE, "Active encounter remains the Initiate")

	_selection.select_character(&"razen")
	var story_arena: MovementTestArenaController = ARENA_SCENE.instantiate() as MovementTestArenaController
	get_tree().root.add_child(story_arena)
	await get_tree().process_frame
	_assert(story_arena.player.character_data.display_name == "Kai", "Story encounter spawns Kai regardless of previous selection")
	_assert(_selection.get_selected_character() == &"kai", "Kai remains selected as the story default")
	_assert(story_arena.dummy_target.ai_enabled, "Initiate encounter enables opponent AI")
	var initiate: TheInitiate = story_arena.dummy_target as TheInitiate
	_assert(initiate != null, "Story encounter swaps in the dedicated female Initiate scene")
	_assert(story_arena.dummy_target.punch_attack.attack_id == &"the_initiate_jab", "Initiate uses its dedicated jab data")
	_assert(story_arena.dummy_target.kick_attack.attack_id == &"the_initiate_kick", "Initiate uses its dedicated kick data")
	_assert(initiate.heavy_punch_attack.attack_id == &"the_initiate_heavy_punch", "Initiate has a distinct heavy punch definition")
	_assert(initiate.roundhouse_attack.attack_id == &"the_initiate_roundhouse", "Initiate has a distinct roundhouse definition")
	_assert(story_arena.dummy_target.health_component.max_health == 140.0, "Guardian has separate story-battle health")
	var initiate_frames: SpriteFrames = story_arena.dummy_target.minion_sprite.sprite_frames
	_assert(initiate_frames.has_animation(&"walk_backward"), "Guardian can retreat using a backward gait")
	_assert(initiate_frames.get_frame_count(&"punch") == 4 and initiate_frames.get_frame_count(&"heavy_punch") == 4, "Both punch clips have four distinct authored poses")
	_assert(initiate_frames.get_frame_count(&"kick") == 4 and initiate_frames.get_frame_count(&"roundhouse") == 4, "Both kick clips have four distinct authored poses")
	_assert(initiate_frames.get_frame_count(&"death") == 4, "Guardian defeat uses its own fall-to-ground clip")
	_assert(not story_arena.dummy_target.enemy_hitbox.monitoring, "Opponent hitbox starts inactive")
	var received_hits: Array[int] = [0]
	var received_ai_damage: Array[float] = [0.0]
	var ai_damage_events: Array[int] = [0]
	story_arena.dummy_target.enemy_hitbox.target_hit.connect(func(_target: Hurtbox2D, _damage: float) -> void: received_hits[0] += 1)
	story_arena.kai_health.damage_received.connect(func(amount: float, _source: Node2D) -> void:
		received_ai_damage[0] += amount
		ai_damage_events[0] += 1)
	var player_health_before: float = story_arena.kai_health.current_health
	var guardian_x_before: float = story_arena.dummy_target.global_position.x
	await get_tree().create_timer(0.5).timeout
	_assert(story_arena.dummy_target.global_position.x < guardian_x_before, "Initiate approaches Kai while outside attack distance")
	_assert(story_arena.dummy_target.minion_sprite.flip_h, "Initiate turns to face Kai when he begins on her left")
	story_arena.dummy_target.global_position.x = story_arena.player.global_position.x + 130.0
	await get_tree().create_timer(1.5).timeout
	_assert(story_arena.kai_health.current_health < player_health_before, "Initiate active attack frames damage Kai")
	_assert(received_hits[0] > 0, "Initiate damage is registered through its active hitbox exactly once per contact")
	_assert(ai_damage_events[0] <= 1 and received_ai_damage[0] <= 9.5, "Guardian I deals at most one configured attack's damage during the 1.5-second observation window")
	_assert(initiate._attack_cooldown > 0.0, "Guardian I remains in its configured post-attack cooldown after a hit")
	await _test_kai_attack_pipeline(story_arena, initiate)
	story_arena.dummy_health.apply_damage(999.0, story_arena.player)
	await story_arena.dummy_target.defeat_animation_finished
	_assert(story_arena.dummy_target.minion_sprite.animation == &"death" and not story_arena.dummy_target.minion_sprite.is_playing(), "Initiate defeat holds the fallen pose before victory UI")
	_assert(_progression.is_guardian_defeated(StoryProgressionState.GUARDIAN_INITIATE), "Battle victory persists the Initiate defeat")
	_assert(_progression.is_guardian_unlocked(StoryProgressionState.GUARDIAN_HUNTER), "Battle victory unlocks the Hunter")
	_assert(is_zero_approx(story_arena.dummy_health.apply_damage(20.0, story_arena.player)), "Defeated Initiate cannot take repeated damage")
	story_arena.queue_free()
	get_tree().paused = false
	await get_tree().process_frame

	_progression.end_guardian_encounter()
	var training_arena: MovementTestArenaController = ARENA_SCENE.instantiate() as MovementTestArenaController
	get_tree().root.add_child(training_arena)
	await get_tree().process_frame
	_assert(not training_arena.dummy_target.ai_enabled, "Training Dojo keeps the minion non-attacking")
	_assert(training_arena.dummy_target.get_node("Silhouette").get_node_or_null("Ponytail") == null, "Training dummy remains free of Initiate-only accessories")
	_assert(training_arena.dummy_target.get_node("Silhouette").get_node_or_null("SakuraEmblem") == null, "Training dummy retains its original clean silhouette")
	training_arena.queue_free()
	await get_tree().process_frame

	_assert(_progression.get_guardians_defeated_count() == 1, "Only the first guardian counts as defeated")
	_restore_player_state()
	print("INITIATE GUARDIAN: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(_failures)


func _test_kai_attack_pipeline(arena: MovementTestArenaController, initiate: TheInitiate) -> void:
	var combat: CombatController = arena.combat
	var player: CharacterController2D = arena.player
	var player_health: HealthComponent = arena.kai_health
	var guardian_health: HealthComponent = initiate.health_component
	var guardian_hurtbox: Hurtbox2D = initiate.get_node("Hurtbox") as Hurtbox2D
	var player_hurtbox: Hurtbox2D = player.get_node("PlayerHurtbox") as Hurtbox2D
	var player_hitbox: Hitbox2D = player.get_node("PlayerHitbox") as Hitbox2D
	var sprite: AnimatedSprite2D = player.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var feedback_callback: Callable = Callable(arena, "_on_hit_landed")
	if combat.hit_landed.is_connected(feedback_callback):
		combat.hit_landed.disconnect(feedback_callback)
	initiate.ai_enabled = false
	initiate._deactivate_enemy_hitbox()
	initiate.hitstun_frames = 0
	await _wait_for_combat_neutral(arena.combat, 90)
	player_health.restore_full()
	_assert(guardian_hurtbox.collision_layer == 64 and guardian_hurtbox.collision_mask == 8, "Initiate hurtbox receives the player's configured hitbox layer")
	_assert(player_hitbox.collision_layer == 8 and player_hitbox.collision_mask == 64, "Kai hitbox targets enemy hurtboxes")
	_assert(is_equal_approx(combat.passive_back_guard_reduction, 0.4), "Kai's existing backward step carries the passive high guard")
	await _run_kai_attack_case(arena, initiate, &"light_attack", combat.get_light_attack())
	await _run_kai_attack_case(arena, initiate, &"heavy_attack", combat.get_heavy_attack())
	await _run_kai_attack_case(arena, initiate, &"kick_attack", combat.get_kick_attack())
	await _run_kai_combo_case(arena, initiate)
	player_health.restore_full()
	player.global_position = Vector2(500.0, 560.0)
	player.velocity = Vector2.ZERO
	player.is_grounded = true
	player.simulate_horizontal_input(-1.0)
	initiate.global_position = Vector2(632.0, 560.0)
	initiate.velocity = Vector2.ZERO
	for _frame: int in range(8):
		if player.current_state == CharacterController2D.State.MOVE_BACKWARD:
			break
		await get_tree().physics_frame
	await get_tree().physics_frame
	var health_before_guard: float = player_health.current_health
	_assert(is_equal_approx(player_health.damage_reduction, 0.4), "Kai's retreat raises the configured guard before a hit lands")
	player_hurtbox.receive_hit(initiate, initiate.punch_attack)
	var guard_damage: float = health_before_guard - player_health.current_health
	_assert(is_equal_approx(guard_damage, initiate.punch_attack.base_damage * 0.6), "Backward guard mitigates an incoming Initiate strike by 40 percent (received %.2f, expected %.2f)" % [guard_damage, initiate.punch_attack.base_damage * 0.6])
	_assert(combat.current_state == CombatController.State.NEUTRAL and sprite.animation != &"heavy_hit", "Backward guard keeps Kai out of hitstun and in control")
	player.reset_simulated_input()
	player.current_state = CharacterController2D.State.IDLE
	player_health.damage_reduction = 0.0
	player_health.restore_full()
	await get_tree().physics_frame
	player_hurtbox.receive_hit(initiate, initiate.punch_attack)
	_assert(combat.current_state == CombatController.State.HITSTUN, "An unguarded Initiate hit starts Kai's hitstun")
	for _frame: int in range(maxi(1, combat.hitstun_frames - 2)):
		await get_tree().physics_frame
	Input.action_release(&"heavy_attack")
	Input.action_press(&"heavy_attack")
	await get_tree().physics_frame
	Input.action_release(&"heavy_attack")
	var buffered_heavy_started: bool = await _wait_for_attack(combat, combat.get_heavy_attack(), 6)
	_assert(buffered_heavy_started, "A heavy-punch input near hitstun recovery is buffered into neutral")
	if buffered_heavy_started:
		for _frame: int in range(combat.get_heavy_attack().get_total_frames() + 5):
			await get_tree().physics_frame
	initiate.ai_enabled = true
	initiate._attack_cooldown = 3.0
	initiate._ai_timer = 0.8


func _run_kai_attack_case(arena: MovementTestArenaController, initiate: TheInitiate, action: StringName, attack: AttackData) -> void:
	var player: CharacterController2D = arena.player
	var combat: CombatController = arena.combat
	var sprite: AnimatedSprite2D = player.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
	var health: HealthComponent = initiate.health_component
	await _wait_for_combat_neutral(combat, 90)
	if attack == null:
		_assert(false, "%s has a configured Kai attack resource" % action)
		return
	player.global_position = Vector2(500.0, 560.0)
	player.velocity = Vector2.ZERO
	player.is_grounded = true
	player.current_state = CharacterController2D.State.IDLE
	player.set_facing(true)
	player.target_opponent = initiate
	initiate.global_position = Vector2(632.0, 560.0)
	initiate.velocity = Vector2.ZERO
	initiate.hitstun_frames = 0
	var health_before: float = health.current_health
	Input.action_release(action)
	Input.action_press(action)
	var attack_started: bool = await _wait_for_attack(combat, attack, 5)
	Input.action_release(action)
	_assert(attack_started, "%s input starts the intended move" % action)
	_assert(not attack_started or sprite.animation == attack.animation_name, "%s selects its authored attack animation" % action)
	_assert(not player_hitbox_is_misconfigured(player), "%s keeps a valid hitbox mask during startup" % action)
	for _frame: int in range(attack.get_total_frames() + 5):
		await get_tree().physics_frame
	_assert(is_equal_approx(health_before - health.current_health, attack.base_damage), "%s reaches the Initiate once during its active frames" % action)
	_assert(combat.current_state == CombatController.State.NEUTRAL, "%s recovers to neutral without a stuck state" % action)


func _run_kai_combo_case(arena: MovementTestArenaController, initiate: TheInitiate) -> void:
	var combat: CombatController = arena.combat
	var player: CharacterController2D = arena.player
	var health: HealthComponent = initiate.health_component
	player.global_position = Vector2(500.0, 560.0)
	player.velocity = Vector2.ZERO
	player.is_grounded = true
	player.current_state = CharacterController2D.State.IDLE
	player.set_facing(true)
	initiate.global_position = Vector2(632.0, 560.0)
	initiate.velocity = Vector2.ZERO
	initiate.hitstun_frames = 0
	health.restore_full()
	var jab: AttackData = combat.get_light_attack()
	var cross: AttackData = jab.chain_next
	var heavy: AttackData = cross.chain_next if cross != null else null
	if cross == null or heavy == null:
		_assert(false, "Kai's existing Z to Z to C chain links load")
		return
	var health_before: float = health.current_health
	Input.action_release(&"light_attack")
	Input.action_press(&"light_attack")
	await get_tree().physics_frame
	Input.action_release(&"light_attack")
	for _frame: int in range(maxi(1, jab.startup_frames - 2)):
		await get_tree().physics_frame
	Input.action_press(&"light_attack")
	await get_tree().physics_frame
	Input.action_release(&"light_attack")
	var cross_started: bool = await _wait_for_attack(combat, cross, 12)
	_assert(cross_started, "Quick second Z is buffered through startup and starts Cross Punch")
	if not cross_started:
		return
	Input.action_press(&"heavy_attack")
	await get_tree().physics_frame
	Input.action_release(&"heavy_attack")
	var heavy_started: bool = await _wait_for_attack(combat, heavy, 12)
	_assert(heavy_started, "C input during Cross startup chains into Heavy Punch")
	if not heavy_started:
		return
	for _frame: int in range(heavy.get_total_frames() + 5):
		await get_tree().physics_frame
	_assert(is_equal_approx(health_before - health.current_health, jab.base_damage + cross.base_damage + heavy.base_damage), "Z to Z to C applies one intended hit per chain link")
	_assert(combat.current_state == CombatController.State.NEUTRAL, "Z to Z to C returns cleanly to neutral")


func _wait_for_attack(combat: CombatController, expected: AttackData, max_frames: int) -> bool:
	for _frame: int in range(max_frames):
		if combat.current_attack == expected:
			return true
		await get_tree().physics_frame
	return combat.current_attack == expected


func _wait_for_combat_neutral(combat: CombatController, max_frames: int) -> void:
	for _frame: int in range(max_frames):
		if combat.current_state == CombatController.State.NEUTRAL:
			return
		await get_tree().physics_frame


func player_hitbox_is_misconfigured(player: CharacterController2D) -> bool:
	var hitbox: Hitbox2D = player.get_node("PlayerHitbox") as Hitbox2D
	return hitbox.collision_layer != 8 or hitbox.collision_mask != 64


func _assert(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] " + message)
	else:
		_failures += 1
		printerr("  [FAIL] " + message)


func _backup_player_state() -> void:
	_saved_story_file_exists = FileAccess.file_exists(StoryProgressionState.SAVE_PATH)
	if _saved_story_file_exists:
		var file: FileAccess = FileAccess.open(StoryProgressionState.SAVE_PATH, FileAccess.READ)
		if file != null:
			_saved_story_file_contents = file.get_as_text()
			file.close()
	var selected: CharacterSelectionState = get_tree().root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if selected != null:
		_previous_character_id = selected.get_selected_character()


func _restore_player_state() -> void:
	if _selection != null:
		_selection.select_character(_previous_character_id)
	if _saved_story_file_exists:
		var file: FileAccess = FileAccess.open(StoryProgressionState.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_saved_story_file_contents)
			file.close()
	else:
		var save_absolute_path: String = ProjectSettings.globalize_path(StoryProgressionState.SAVE_PATH)
		if FileAccess.file_exists(StoryProgressionState.SAVE_PATH):
			DirAccess.remove_absolute(save_absolute_path)
	if _progression != null:
		_progression.load_progress()

