extends SceneTree
## Runs the real World Map route, dojo physics and keyboard actions.

const Adapter = preload("res://experimental/kai_hybrid/training/hybrid_training.gd")
const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const Dash = preload("res://experimental/kai_hybrid/dash_motion.gd")
const MAP: String = "res://scenes/ui/world_map.tscn"

var _dojo: Adapter
var _errors: int = 0
var _destination: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_destination = OS.get_environment("KAI_TRAINING_CAPTURE_DIR")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.get_node("CharacterSelection").select_character(&"kai")
	if change_scene_to_file(MAP) != OK:
		push_error("The existing World Map could not load.")
		quit(1)
		return
	await scene_changed
	current_scene.get_node("LeftCommandPanel").emit_signal(&"training_dojo_selected")
	await scene_changed
	await _ticks(4)
	_dojo = current_scene.get_node_or_null("HybridTraining") as Adapter
	_check(1, _dojo != null and current_scene.scene_file_path == Adapter.BASE_ARENA, "World Map Training opens the existing dojo and activates Hybrid Kai")
	if _dojo == null:
		quit(1)
		return
	var hero: CharacterBody2D = _dojo.fighter
	var dummy: TrainingDummy = _dojo.target.dummy
	var motion = _dojo.motion
	var spawn: Vector2 = hero.global_position
	var target_spawn: Vector2 = dummy.global_position
	await _capture("entered")
	await _action(&"move_right", 38)
	await _ticks(52)
	var moved_right: bool = hero.global_position.x > spawn.x + 10.0
	var right_x: float = hero.global_position.x
	await _action(&"move_left", 33)
	await _ticks(55)
	_check(2, moved_right and hero.global_position.x < right_x - 10.0, "A/D plays both walks and moves the body")
	await _action(&"jump", 1)
	await _ticks(27)
	var lifted: bool = hero.global_position.y < spawn.y - 45.0
	await _capture("jump")
	await _ticks(70)
	_check(3, lifted and absf(hero.global_position.y - spawn.y) < 0.15 and not motion.jump_active, "Jump arcs and lands on the existing floor")
	_dojo.reset_training()
	var dx: float = hero.global_position.x
	_key(KEY_E, true)
	await _ticks(38)
	_key(KEY_E, false)
	var forward: bool = is_equal_approx(hero.global_position.x - dx, absf(Dash.DISTANCE[Dash.Kind.FORWARD]))
	dx = hero.global_position.x
	_key(KEY_Q, true)
	await _ticks(40)
	_key(KEY_Q, false)
	var backward: bool = is_equal_approx(dx - hero.global_position.x, absf(Dash.DISTANCE[Dash.Kind.BACKWARD]))
	dx = hero.global_position.x
	_key(KEY_SHIFT, true)
	await _ticks(42)
	_key(KEY_SHIFT, false)
	_check(4, forward and backward and is_equal_approx(dx - hero.global_position.x, absf(Dash.DISTANCE[Dash.Kind.EVASIVE])), "E/Q/Shift preserve all three open-floor travel distances")
	await _prepare_contact()
	_key(KEY_E, true)
	await _ticks(38)
	_key(KEY_E, false)
	_check(21, motion.dash_blocked and hero.global_position.x < dummy.global_position.x - 45.0, "Player dash stops at the existing dummy body")
	_dojo.reset_training()
	_key(KEY_F, true)
	await _ticks(23)
	_check(5, motion.guarding(), "F raises and holds the approved Guard")
	await _capture("guard")
	_key(KEY_F, false)
	await _ticks(19)
	var singles: bool = true
	var durations: Array[int] = [9, 20, 17]
	var actions: Array[StringName] = [&"light_attack", &"heavy_attack", &"kick_attack"]
	var push: Array[float] = []
	for kind: int in 3:
		await _prepare_contact()
		var before: float = dummy.global_position.x
		await _action(actions[kind], 1)
		await _ticks(durations[kind])
		_check(6 + kind, _dojo.target.hits == 1, Attack.NAMES[kind] + " connects through the existing hurtbox")
		await _capture(Attack.FAMILIES[kind] + "_impact")
		await _ticks(60)
		push.append(dummy.global_position.x - before)
		singles = singles and _dojo.target.hits == 1 and _dojo.target.recovered
	_dojo.reset_training()
	await _ticks(4)
	await _action(&"light_attack", 1)
	await _ticks(12)
	var miss_clock: bool = motion.hit_stop.remaining == 0.0
	await _ticks(33)
	_check(9, _dojo.target.hits == 0 and miss_clock, "Out-of-range strike misses and adds no contact hold")
	await _prepare_contact()
	await _action(&"light_attack", 1)
	dummy.global_position.x = hero.global_position.x - 114.0
	await _ticks(38)
	var behind_missed: bool = _dojo.target.hits == 0
	await _action(&"heavy_attack", 1)
	await _ticks(18)
	_check(10, behind_missed and _dojo.target.hits == 1, "Attack cannot hit behind its locked facing and can hit after turning")
	_check(11, singles, "Each attack registers once and returns the target to idle")
	await _prepare_contact()
	var initial_scale: float = Engine.time_scale
	await _action(&"heavy_attack", 1)
	var held: bool = false
	for frame: int in 30:
		await physics_frame
		if motion.hit_stop.remaining > 0.0:
			held = true
			break
	var reset: Button = current_scene.find_child("ResetDummy", true, false) as Button
	_check(12, held and Engine.time_scale == initial_scale and reset != null and reset.can_process(), "Contact hold keeps the existing arena UI responsive")
	_check(13, push[1] > push[2] and push[2] > push[0] and push[0] > 0.0, "Dummy uses distinct light, heavy and kick recoil distances")
	if reset != null:
		reset.pressed.emit()
	_check(15, dummy.global_position.distance_to(target_spawn) < 0.15 and dummy.velocity == Vector2.ZERO
		and dummy.hitstun_frames == 0 and _dojo.target.sprite.animation == &"idle"
		and _dojo.target.durability == _dojo.target.maximum and motion.hit_stop.remaining == 0.0,
		"UI reset clears an active hit, restores position and durability, and returns the dummy to idle")
	await _prepare_contact(1190.0)
	await _action(&"heavy_attack", 1)
	await _ticks(60)
	_check(14, _dojo.target.hits == 1 and dummy.global_position.x > 1190.0 and dummy.global_position.x < 1210.1, "Existing wall stops heavy knockback")
	await _capture("wall")
	await _prepare_contact()
	await _action(&"light_attack", 1)
	await _ticks(16)
	await _action(&"light_attack", 1)
	await _ticks(50)
	_check(16, _dojo.target.hits == 2 and not motion.attack_active, "Buffered repeated light attacks land once per swing")
	_key(KEY_F, true)
	await _ticks(25)
	var guarded: bool = motion.guarding()
	_key(KEY_F, false)
	var before_move: float = hero.global_position.x
	await _action(&"move_left", 35)
	await _ticks(50)
	_check(17, guarded and hero.global_position.x < before_move - 10.0 and not motion.guarding(), "Combat returns through Guard to movement")
	await _capture("resumed")
	await _verify_navigation()
	print("Training verification failures: ", _errors)
	quit(int(_errors != 0))


func _prepare_contact(target_x: float = 920.0) -> void:
	_dojo.reset_training()
	_dojo.target.dummy.global_position.x = target_x
	_dojo.fighter.global_position.x = target_x - 118.0
	await _ticks(3)


func _verify_navigation() -> void:
	var pause: CanvasLayer = current_scene.get_node("PauseMenu")
	var return_button: Button = pause.get("_world_map_button")
	return_button.pressed.emit()
	await scene_changed
	_check(18, current_scene.scene_file_path == MAP, "Existing pause menu returns to World Map")
	var selection: Node = root.get_node("CharacterSelection")
	selection.select_character(&"razen")
	current_scene.get_node("LeftCommandPanel").emit_signal(&"training_dojo_selected")
	await scene_changed
	await _ticks(3)
	_check(19, current_scene.get_node_or_null("HybridTraining") == null
		and current_scene.get_node("Fighters/Kai").visible, "Razen retains the original training player")
	selection.select_character(&"kai")
	var progression: Node = root.get_node("StoryProgression")
	var started: bool = progression.begin_guardian_encounter(&"the_initiate")
	if started:
		change_scene_to_file(Adapter.BASE_ARENA)
		await scene_changed
		await _ticks(5)
	_check(20, started and current_scene.get_node_or_null("HybridTraining") == null
		and current_scene.get_node("Fighters/Kai").visible, "Guardian encounter keeps the frame-based player")
	progression.end_guardian_encounter()


func _ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame


func _action(action: StringName, hold: int) -> void:
	Input.action_press(action)
	await _ticks(hold + 1)
	Input.action_release(action)


func _key(code: Key, held: bool) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = code
	key.pressed = held
	Input.parse_input_event(key)


func _capture(title: String) -> void:
	if _destination.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(_destination.path_join(title + ".png")) != OK:
		_errors += 1


func _check(id: int, passes: bool, description: String) -> void:
	if passes:
		print("PASS #%02d " % id + description)
	else:
		_errors += 1
		push_error("FAIL #%02d " % id + description)
