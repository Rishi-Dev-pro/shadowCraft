extends SceneTree

const Adapter = preload("res://experimental/kai_hybrid/training/hybrid_training.gd")
const Actor = preload("res://experimental/raezen_hybrid/training/raezen_training.gd")
const Walk = preload("res://experimental/raezen_hybrid/walk_review/eight_pose_walk.gd")
const MAP: String = "res://scenes/ui/world_map.tscn"

var _dojo: Adapter
var _failures: int
var _destination: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_destination = OS.get_environment("RAEZEN_TRAINING_CAPTURE_DIR")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var selection: Node = root.get_node("CharacterSelection")
	selection.select_character(&"kai")
	change_scene_to_file(MAP)
	await scene_changed
	current_scene.get_node("LeftCommandPanel").emit_signal(&"training_dojo_selected")
	await scene_changed
	await _ticks(4)
	_dojo = current_scene.get_node_or_null("HybridTraining") as Adapter
	if _dojo == null:
		_check(false, "Hybrid Training loads from World Map")
		quit(1)
		return
	var arena: Node = current_scene
	var hero: CharacterBody2D = _dojo.fighter
	var hp: HealthComponent = hero.get_node("HealthComponent")
	var dummy: TrainingDummy = _dojo.target.dummy
	var switch_button: Button = arena.find_child("SwitchCharacter", true, false)
	_check(not _dojo.switcher.use_raezen and _dojo.display.visible and switch_button != null, "Kai and Switch Character are present on entry")
	await _place(802.0, 920.0)
	await _action(&"light_attack", 1)
	await _ticks(56)
	_check(_dojo.target.hits == 1, "Default Kai hits the training dummy")
	await _choose(switch_button, "SelectRaezen", true)
	var actor: Actor = _dojo.switcher.raezen
	if actor == null:
		_check(false, "Raezen activates")
		quit(1)
		return
	_check(current_scene == arena and actor.fighter == hero and actor.target.dummy == dummy
		and _dojo.target.hits == 1 and actor.visible and not _dojo.display.visible, "Switch uses the same actor slot and retains dummy drill state")
	await _capture("raezen_selected")
	await _place(660.0, 1120.0)
	await _action(&"move_right", 39)
	await _ticks(16)
	var right: float = hero.global_position.x
	await _action(&"move_left", 39)
	await _ticks(16)
	_check(right > 675.0 and hero.global_position.x < right - 10.0, "Raezen moves both directions")
	await _verify_ground_gait(actor)
	_key(KEY_F, true)
	await _ticks(17)
	_check(actor.motion.active["id"] == "guard", "Raezen guards")
	await _capture("raezen_guard")
	_key(KEY_F, false)
	await _ticks(35)
	await _action(&"jump", 1)
	await _ticks(16)
	var lifted: bool = hero.global_position.y < _dojo.training_floor_y() - 15.0
	await _capture("raezen_jump")
	await _ticks(95)
	_check(lifted and absf(hero.global_position.y - _dojo.training_floor_y()) < 0.25, "Raezen jumps and lands on the dojo floor")
	for dash: Key in [KEY_E, KEY_SHIFT]:
		await _place(580.0, 930.0)
		await _tap(dash)
		await _ticks(22)
		await _capture("raezen_dash" if dash == KEY_E else "raezen_void_step")
		await _ticks(55)
		_check(hero.global_position.x > 680.0, "Dash or Void Step covers visible distance")
		await _place(802.0, 920.0)
		await _tap(dash)
		await _ticks(72)
		_check(hero.global_position.x < dummy.global_position.x - 42.0, "Dash or Void Step respects the dummy body")
	var moves: Array[String] = ["diagonal", "heavy", "front_kick", "void_burst", "void_burst_main"]
	for index: int in moves.size():
		await _place(802.0, 920.0)
		var hits: int = _dojo.target.hits
		if index < 3:
			await _action([&"light_attack", &"heavy_attack", &"kick_attack"][index], 1)
		else:
			await _tap(KEY_U if index == 3 else KEY_I)
		await _ticks([26, 36, 29, 43, 48][index])
		await _capture("raezen_" + moves[index])
		await _ticks(115)
		_check(_dojo.target.hits == hits + 1, moves[index] + " contacts the dummy once")
	for index: int in 4:
		await _place(720.0, 1010.0)
		var before_hp: float = hp.current_health
		await _tap([KEY_1, KEY_2, KEY_3, KEY_4][index])
		await _ticks(10)
		var expected: String = ["hit", "heavy_hit", "directional_hit", "directional_hit_rear"][index]
		_check(actor.motion.active["id"] == expected and hp.current_health < before_hp, expected + " animates and updates shared health")
		await _capture("raezen_" + expected)
		await _ticks(75)
	await _place(720.0, 1010.0)
	await _tap(KEY_5)
	await _ticks(78)
	_check(actor.motion.active["id"] == "knockback" and not actor.motion.playing, "Knockback holds Raezen down")
	await _capture("raezen_knockdown")
	await _tap(KEY_G)
	await _ticks(17)
	_check(actor.motion.active["id"] == "get_up" and actor.motion.playing, "G starts get-up from knockdown")
	await _capture("raezen_get_up")
	await _ticks(57)
	_check(actor.motion.active["id"] == "ready", "Get-up flows into the sword-ready stance")
	await _ticks(43)
	await _place(810.0, 685.0)
	var left_hits: int = _dojo.target.hits
	await _action(&"light_attack", 1)
	await _ticks(62)
	_check(actor.facing < 0.0 and _dojo.target.hits == left_hits + 1, "Facing left mirrors the presentation and still hits in front")
	await _choose(switch_button, "SelectKai")
	_check(not actor.enabled and not actor.visible and _dojo.display.visible and _dojo.fighter == hero, "Switching back suspends Raezen and restores the Kai adapter")
	await _capture("kai_restored")
	await _place(802.0, 920.0)
	var kai_hits: int = _dojo.target.hits
	await _action(&"light_attack", 1)
	await _ticks(68)
	_check(_dojo.target.hits == kai_hits + 1, "Kai can still hit the dummy after switching back")
	for index: int in 2:
		await _choose(switch_button, "SelectRaezen")
		await _tap(KEY_I)
		await _ticks(4)
		var hits_at_swap: int = _dojo.target.hits
		await _choose(switch_button, "SelectKai")
		await _ticks(73)
		_check(_dojo.switcher.raezen == actor and _dojo.target.hits == hits_at_swap
			and not actor.enabled and dummy == _dojo.target.dummy and current_scene == arena, "Repeated switch cancels the inactive fighter's action and keeps one Raezen instance")
	print("Raezen switcher verification failures: ", _failures)
	quit(int(_failures != 0))


func _verify_ground_gait(actor: Actor) -> void:
	await _place(540.0, 1120.0)
	var hero: CharacterBody2D = actor.fighter
	var start: float = hero.global_position.x
	Input.action_press(&"move_right")
	await _ticks(13)
	var maximum_slip: float = 0.0
	var maximum_floor_error: float = 0.0
	var heel_contact: bool = false
	var toe_contact: bool = false
	var support_count: int = 0
	var steps: int = 0
	var boots_lifted: Array[bool] = [false, false]
	var loaded_with_both_down: bool = false
	var blade_tracking: bool = true
	var support_side: int = -1
	var old_boot: Transform2D
	var floor_contact: float = actor._display.to_global(Vector2(256, Walk.Base.FLOOR_Y)).y
	for tick: int in 95:
		await physics_frame
		var near: bool = Walk.drawing(actor._walk_time) >= 4.0
		var side: int = int(near)
		var ankle: Bone2D = actor.motion.rig.bones["FootNear" if near else "FootFar"]
		var other: Bone2D = actor.motion.rig.bones["FootFar" if near else "FootNear"]
		var current: Transform2D = actor._display.global_transform * ankle.global_transform
		var pitch: float = ankle.global_rotation_degrees
		var pivot: Vector2 = Walk.Base.sole_contact(near, pitch)
		var floor_error: float = absf((current * pivot).y - floor_contact)
		maximum_floor_error = maxf(maximum_floor_error, floor_error)
		var other_sole: Vector2 = Walk.Base.sole_contact(not near, other.global_rotation_degrees)
		var lift: float = floor_contact - actor._display.to_global(other.to_global(other_sole)).y
		boots_lifted[side] = boots_lifted[side] or lift > 15.0
		loaded_with_both_down = loaded_with_both_down or absf(lift) < 0.05
		heel_contact = heel_contact or pitch < -5.0
		toe_contact = toe_contact or pitch > 8.0
		blade_tracking = blade_tracking and actor.motion.rig == actor._walk_rig and actor._walk_rig.weapon.get_parent() == actor._walk_rig.bones["HandNear"]
		if side == support_side:
			maximum_slip = maxf(maximum_slip, absf((old_boot * pivot).x - (current * pivot).x))
			support_count += 1
		elif support_side >= 0:
			steps += 1
		old_boot = current
		support_side = side
	Input.action_release(&"move_right")
	_check(actor.facing > 0.0 and hero.global_position.x > start + 95.0 and steps >= 2,
		"Forward walking faces right and alternates the support boot")
	_check(support_count > 48 and maximum_slip < 0.5 and maximum_floor_error < 0.5,
		"Support anchor drifts %.3f px and sole height varies %.3f px" % [maximum_slip, maximum_floor_error])
	_check(heel_contact and toe_contact, "The support boot rolls from heel contact to toe push-off")
	_check(boots_lifted[0] and boots_lifted[1] and loaded_with_both_down and blade_tracking,
		"Both boots pass in turn, load shares both contacts, and the blade follows the hand")
	await _ticks(24)
	start = hero.global_position.x
	await _ticks(10)
	_check(absf(start - hero.global_position.x) < 0.1 and not actor._grounded_motion,
		"Release settles the feet and stops the collision body")
	Input.action_press(&"crouch")
	await _action(&"move_left", 38)
	_check(hero.global_position.x < start - 38.0 and actor.facing > 0.0
		and actor.motion.active["id"] == "backward", "Holding S changes A/D into a combat-facing backstep")
	Input.action_release(&"crouch")
	await _action(&"move_left", 42)
	_check(actor.facing < 0.0 and actor.motion.active["id"] == "forward",
		"Releasing S turns the whole rig into a left-facing forward stride")
	_key(KEY_CTRL, true)
	start = hero.global_position.x
	await _action(&"move_right", 71)
	_check(actor.facing > 0.0 and hero.global_position.x > start + 145.0,
		"Reversing into Ctrl+A/D turns right and reaches running speed")
	_key(KEY_CTRL, false)
	await _ticks(28)
	await _place(735.0, 920.0)
	var hits: int = actor.target.hits
	Input.action_press(&"move_right")
	await _ticks(25)
	await _action(&"light_attack", 1)
	Input.action_release(&"move_right")
	_check(actor.motion.active["id"] == "diagonal" and not actor._grounded_motion,
		"Moving sword attack takes control from the gait immediately")
	await _ticks(75)
	_check(actor.motion.active["id"] == "neutral" and actor.target.hits == hits + 1,
		"Walking entry lands one sword hit and recovers to idle")


func _choose(button: Button, name_to_select: String, capture: bool = false) -> void:
	_click(button)
	await _ticks(3)
	if capture:
		await _capture("character_switcher")
	var choice: Button = current_scene.find_child(name_to_select, true, false)
	_click(choice)
	await _ticks(4)


func _click(button: Button) -> void:
	var cursor: Vector2 = button.get_global_rect().get_center()
	var pointer: InputEventMouseMotion = InputEventMouseMotion.new()
	pointer.position = cursor
	root.push_input(pointer, true)
	for pressed: bool in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.position = cursor
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		root.push_input(click, true)


func _place(player_x: float, dummy_x: float) -> void:
	_dojo.fighter.global_position = Vector2(player_x, _dojo.training_floor_y())
	_dojo.target.dummy.global_position.x = dummy_x
	await _ticks(4)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame


func _action(action: StringName, hold: int) -> void:
	Input.action_press(action)
	await _ticks(hold + 1)
	Input.action_release(action)


func _tap(code: Key) -> void:
	_key(code, true)
	await _ticks(2)
	_key(code, false)


func _key(code: Key, held: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = held
	Input.parse_input_event(event)


func _capture(name_to_save: String) -> void:
	if _destination.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_destination.path_join(name_to_save + ".png")) == OK, "Captured " + name_to_save)


func _check(passed: bool, description: String) -> void:
	if passed:
		print("PASS ", description)
	else:
		_failures += 1
		push_error("FAIL " + description)


