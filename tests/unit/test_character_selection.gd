extends SceneTree

var _checks: int = 0
var _failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var selection_state: CharacterSelectionState = _ensure_selection_state()
	var selection_scene: PackedScene = load("res://scenes/ui/character_select.tscn") as PackedScene
	_check(selection_scene != null, "Character Selection scene loads")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/character_select.tscn", "F5 main scene is Character Selection")
	_check(InputMap.has_action("pause_menu"), "Escape pause action exists")
	_check(selection_state.get_character_ids().size() == 2, "Selection offers exactly the two approved fighters")
	var menu: Control = selection_scene.instantiate() as Control
	root.add_child(menu)
	await process_frame
	var kai_preview: AnimatedSprite2D = menu.get_node("PreviewLayer/KaiPreview") as AnimatedSprite2D
	var razen_preview: AnimatedSprite2D = menu.get_node("PreviewLayer/RazenPreview") as AnimatedSprite2D
	_check(kai_preview.animation == &"idle_signature" and kai_preview.is_playing(), "Kai selection preview plays the real idle animation")
	_check(razen_preview.animation == &"idle_signature" and razen_preview.is_playing(), "Razen selection preview plays the real idle animation")
	_check((menu.get_node("KAICard") as Button) != null and (menu.get_node("RAZENCard") as Button) != null, "Mouse-selectable cards exist for both fighters")
	(menu.get_node("RAZENCard") as Button).pressed.emit()
	_check(selection_state.selected_character_id == &"razen", "Razen card selection updates the playable character state")
	(menu.get_node("KAICard") as Button).pressed.emit()
	_check(selection_state.selected_character_id == &"kai", "Kai card selection updates the playable character state")
	menu.queue_free()
	await process_frame

	var passed_kai: int = 0
	var passed_razen: int = 0
	for selection_index: int in range(4):
		var character_id: StringName = &"kai" if selection_index % 2 == 0 else &"razen"
		selection_state.select_character(character_id)
		var arena_scene: PackedScene = load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene
		var arena: Node2D = arena_scene.instantiate() as Node2D
		root.add_child(arena)
		for _step: int in range(4):
			await physics_frame
		var fighters: Node2D = arena.get_node("Fighters") as Node2D
		var player: CharacterController2D = fighters.get_node("Kai") as CharacterController2D
		var combat: CombatController = player.get_node("CombatController") as CombatController
		var sprite: AnimatedSprite2D = player.get_node("Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D
		var dummy_container: Node2D = fighters.get_node("DummyTarget") as Node2D
		var dummy_health: HealthComponent = dummy_container.get_node("TrainingDummy/HealthComponent") as HealthComponent
		_check(player.character_data.character_id == character_id, "%s selection instantiates that playable character" % character_id)
		_check(player.target_opponent == dummy_container.get_node("TrainingDummy"), "%s faces the arena's real training dummy" % character_id)
		_check(combat != null and sprite.sprite_frames.has_animation(&"light_jab") and sprite.sprite_frames.has_animation(&"front_kick"), "%s has working shared attack mappings" % character_id)
		var player_count: int = 0
		for fighter: Node in fighters.get_children():
			if fighter is CharacterController2D:
				player_count += 1
		_check(player_count == 1, "character switching creates exactly one player instance")
		if character_id == &"kai":
			passed_kai += 1
		else:
			passed_razen += 1
		var jab: AttackData = load("res://resources/attacks/light_jab.tres") as AttackData
		var before_jab: float = dummy_health.current_health
		_check(combat.start_attack(jab), "%s can start the existing Light Jab" % character_id)
		_check(sprite.animation == &"light_jab", "%s displays its own jab animation" % character_id)
		await _advance_attack(arena, combat, jab)
		_check(dummy_health.current_health < before_jab, "%s Light Jab damages the shared training dummy" % character_id)
		var kick: AttackData = load("res://resources/attacks/front_kick.tres") as AttackData
		dummy_health.restore_full()
		dummy_container.position.x = 960.0
		player.position = Vector2(850.0, 560.0)
		player.velocity = Vector2.ZERO
		var before_kick: float = dummy_health.current_health
		_check(combat.start_attack(kick), "%s can start the existing Front Kick" % character_id)
		_check(sprite.animation == &"front_kick", "%s displays its own kick animation" % character_id)
		await _advance_attack(arena, combat, kick)
		_check(dummy_health.current_health < before_kick, "%s Front Kick damages the shared training dummy" % character_id)
		arena.queue_free()
		await process_frame
	_check(passed_kai == 2 and passed_razen == 2, "Repeated Kai/Razen scene switching completes without stale instances")
	selection_state.select_character(&"kai")
	var pause_test_arena: Node2D = (load("res://scenes/arenas/MovementTestArena.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(pause_test_arena)
	await physics_frame
	var pause_menu: CanvasLayer = pause_test_arena.get_node("PauseMenu") as CanvasLayer
	pause_menu.call("_toggle_pause")
	_check(paused and pause_menu.visible, "Escape pause menu freezes gameplay and displays its panel")
	pause_menu.call("_change_character")
	for _frame: int in range(3):
		await process_frame
	_check(not paused, "Change Character resumes the tree before returning to selection")
	_check(root.get_node_or_null("CharacterSelect") != null, "Change Character returns to the character selection scene")
	print("CHARACTER SELECTION: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _advance_attack(arena: Node2D, combat: CombatController, attack: AttackData) -> void:
	for _frame: int in range(attack.get_total_frames() + 12):
		await physics_frame
	var _arena_controller: MovementTestArenaController = arena as MovementTestArenaController
	if combat.current_state != CombatController.State.NEUTRAL:
		for _extra_frame: int in range(24):
			await physics_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)

func _ensure_selection_state() -> CharacterSelectionState:
	var state: CharacterSelectionState = root.get_node_or_null("CharacterSelection") as CharacterSelectionState
	if state == null:
		state = load("res://scripts/systems/character_selection_state.gd").new() as CharacterSelectionState
		state.name = "CharacterSelection"
		root.add_child(state)
	return state
