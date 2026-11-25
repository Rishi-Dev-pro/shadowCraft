extends Node2D
## Presents the Hybrid lab clips on the dojo's one existing collision slot.

const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")
const Walk = preload("res://experimental/raezen_hybrid/walk_review/eight_pose_walk.gd")
const WalkRig = preload("res://experimental/raezen_hybrid/walk_review/side_walk_rig.gd")
const Motion = preload("res://experimental/raezen_hybrid/motion_player.gd")
const Gait = preload("res://experimental/raezen_hybrid/training/gait.gd")
const Target = preload("res://experimental/kai_hybrid/training/training_target.gd")
const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const FRAMES = preload("res://assets/characters/raezan_boss/raezan_sprite_frames.tres")
const SCALE: float = 0.72
const PADDING: float = 88.0
const FLOOR: float = 491.0
const MARGIN: float = 0.025
const ATTACK_KIND: Dictionary = {
	"diagonal": Attack.Kind.LIGHT, "heavy": Attack.Kind.HEAVY, "front_kick": Attack.Kind.KICK,
	"void_burst": Attack.Kind.HEAVY, "void_burst_main": Attack.Kind.HEAVY,
}

var fighter: CharacterController2D
var target: Target
var motion: Motion
var enabled: bool = false
var menu_open: bool = false
var facing: float = 1.0
var impacts: int = 0
var _profiles: Dictionary[String, int] = {}
var _stage: SubViewport
var _display: Sprite2D
var _floor_y: float
var _last_sample: Vector2
var _dash_travel: float = 0.0
var _contact: RectangleShape2D = RectangleShape2D.new()
var _report: Callable
var _gait: Gait = Gait.new()
var _grounded_motion: bool = false
var _walk_rig: WalkRig
var _action_rig: Rig
var _walk_landing: float = -1.0
var _walk_time: float
var _gait_entry: Dictionary
var _gait_blend: float
var _rest_from: Dictionary
var _rest_pose: Dictionary
var _rest_blend: float


func setup(body: CharacterController2D, practice_target: Target, floor_y: float, report: Callable) -> void:
	fighter = body
	target = practice_target
	_floor_y = floor_y
	_report = report
	_stage = SubViewport.new()
	_stage.size = Vector2i(512, 600)
	_stage.world_2d = World2D.new()
	_stage.transparent_bg = true
	add_child(_stage)
	_stage.canvas_transform = Transform2D(0.0, Vector2(0.0, PADDING))
	var rig: Rig = Rig.new()
	_action_rig = rig
	_stage.add_child(rig)
	_walk_rig = WalkRig.new()
	_stage.add_child(_walk_rig)
	_walk_rig.hide()
	var paint: Sprite2D = Sprite2D.new()
	paint.centered = false
	_stage.add_child(paint)
	motion = Motion.new()
	add_child(motion)
	motion.configure(rig, paint, FRAMES)
	motion.event_fired.connect(_on_event)
	for index: int in motion.profiles.size():
		_profiles[motion.profiles[index]["id"]] = index
	_display = Sprite2D.new()
	_display.centered = false
	_display.texture = _stage.get_texture()
	var composite: CanvasItemMaterial = CanvasItemMaterial.new()
	composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	_display.material = composite
	add_child(_display)


func set_active(active: bool) -> void:
	enabled = active
	visible = active
	set_physics_process(active)
	set_process_unhandled_key_input(active)
	_walk_landing = -1.0
	_stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	_use_rig(_action_rig)
	motion.inspect_pose(_profiles["neutral"], 0.0)
	_last_sample = Vector2.ZERO
	_dash_travel = 0.0
	_grounded_motion = false
	_rest_pose.clear()
	if active:
		_face_target()
		_project()


func reset_pose() -> void:
	impacts = 0
	set_active(enabled)


func _physics_process(delta: float) -> void:
	if menu_open:
		return
	if _grounded_motion:
		_move_on_floor(delta)
	else:
		_move_action(delta)
	target.synchronize_hold(false)
	_drive_input()
	_project()


func _move_action(delta: float) -> void:
	if not _rest_pose.is_empty():
		_rest_blend = minf(1.0, _rest_blend + delta * 7.0)
		motion.present_ground_step(_rest_pose, _rest_from, _rest_blend)
		return
	motion.advance(delta)
	var sample: Vector2 = _sample_position()
	var movement: Vector2 = (sample - _last_sample) * Vector2(SCALE * facing, SCALE)
	_last_sample = sample
	var dash_id: String = motion.active["id"]
	if dash_id in ["dash", "void_step"]:
		var distance: float = 185.0 if dash_id == "dash" else 140.0
		var desired: float = distance * smoothstep(0.12, 0.78, motion.progress())
		movement.x += (desired - _dash_travel) * facing
		_dash_travel = desired
	if not is_zero_approx(movement.x):
		fighter.move_and_collide(Vector2(movement.x, 0.0), false, MARGIN)
	if not is_zero_approx(movement.y):
		fighter.move_and_collide(Vector2(0.0, minf(_floor_y - fighter.global_position.y, movement.y)), false, MARGIN)


func _move_on_floor(delta: float) -> void:
	if _walk_landing >= 0.0:
		_walk_landing = minf(1.0, _walk_landing + delta / 0.13)
		var settle: float = smoothstep(0.0, 1.0, _walk_landing)
		var landing: Dictionary = {"angles": {"Pelvis": 0.0}, "underlay": 1.0}
		for foot: String in ["near", "far"]:
			var offset: Vector2 = _gait_entry[foot] * (1.0 - settle)
			landing[foot] = [offset.x, offset.y]
		motion.present_ground_step(landing, _gait_entry, _walk_landing)
		if _walk_landing >= 1.0:
			_request("neutral")
		return
	var axis: float = Input.get_axis("move_left", "move_right")
	var running: bool = Input.is_physical_key_pressed(KEY_CTRL) and _gait.direction == facing
	var keeping_facing: bool = Input.is_action_pressed("crouch") or facing == _gait.direction
	var continuing: bool = axis * _gait.direction > 0.0 and keeping_facing
	var speed: float = Gait.BACK_SPEED if _gait.direction != facing else (Gait.RUN_SPEED if running else Gait.WALK_SPEED)
	var walk: bool = not running and _gait.direction == facing
	if walk != (motion.rig == _walk_rig):
		_gait_entry = motion._last_pose.duplicate(true)
		_gait_blend = 0.0
		if not walk:
			var carry: float = _gait.velocity
			var contacts: Array[Vector2] = [_gait_entry["near"], _gait_entry["far"]]
			_gait.begin(fighter.global_position.x, facing, _gait.direction, SCALE, contacts)
			_gait.velocity = carry
		_use_rig(_walk_rig if walk else _action_rig)
	var requested: float = axis * speed if continuing else 0.0
	_gait.velocity = move_toward(_gait.velocity, requested, (Gait.ACCELERATION if continuing else Gait.BRAKING) * delta)
	var start_x: float = fighter.global_position.x
	var dx: float = _gait.velocity * delta
	var advance: float = absf(_gait.velocity) / Gait.WALK_SPEED * delta
	if walk:
		dx = (Walk.travel(_walk_time + advance) - Walk.travel(_walk_time)) * SCALE * facing
	var collision: KinematicCollision2D = fighter.move_and_collide(Vector2(dx, 0.0), false, MARGIN)
	if collision != null:
		_gait.velocity = 0.0
		continuing = false
	var x: float = fighter.global_position.x
	var stopped: bool
	var key: Dictionary
	if walk:
		var fraction: float = clampf(absf((x - start_x) / dx), 0.0, 1.0) if not is_zero_approx(dx) else 0.0
		_walk_time = fposmod(_walk_time + advance * fraction, Walk.CYCLE_SECONDS)
		key = Walk.sample(_walk_time, true)
		stopped = not continuing and is_zero_approx(_gait.velocity)
	else:
		stopped = _gait.step(x, x - start_x, delta, continuing, running)
		key = _gait.pose(x)
	_gait_blend = minf(1.0, _gait_blend + delta * 8.0)
	if walk and _gait_blend < 1.0:
		var blend: float = smoothstep(0, 1, _gait_blend)
		for foot: String in ["near", "far"]:
			var offset: Vector2 = _gait_entry[foot].lerp(Rig.coordinates(key[foot]), blend)
			key[foot] = [offset.x, offset.y]
	motion.present_ground_step(key, _gait_entry, _gait_blend)
	_last_sample = _sample_position()
	if stopped:
		var from: Dictionary = motion._last_pose.duplicate(true)
		if walk:
			_gait_entry = from
			_walk_landing = 0.0
			return
		if _request("neutral"):
			_rest_from = from
			_rest_pose = {"near": [from["near"].x, 0.0], "far": [from["far"].x, 0.0],
				"pelvis": [0.0, 8.0], "underlay": 0.70}
			_rest_blend = 0.0
			motion.present_ground_step(_rest_pose, _rest_from, 0.0)


func _start_ground_motion(axis: float) -> void:
	var direction: float = signf(axis)
	if fighter.test_move(fighter.global_transform, Vector2(direction * 2.0, 0.0), null, MARGIN):
		return
	var source_pose: Dictionary = motion._last_pose.duplicate(true)
	if not Input.is_action_pressed("crouch") and direction != facing:
		_set_facing(direction)
		var near_x: float = source_pose["near"].x + Gait.NEAR_REST_X
		var far_x: float = source_pose["far"].x + Gait.FAR_REST_X
		source_pose["near"] = Vector2(-far_x - Gait.NEAR_REST_X, 0.0)
		source_pose["far"] = Vector2(-near_x - Gait.FAR_REST_X, 0.0)
	if not _request("forward" if direction == facing else "backward"):
		return
	var boot_offsets: Array[Vector2] = [source_pose["near"], source_pose["far"]]
	_gait.begin(fighter.global_position.x, facing, direction, SCALE, boot_offsets)
	_walk_time = 0.0
	_gait_entry = source_pose
	_gait_blend = 0.0
	_grounded_motion = true
	if direction != facing or Input.is_physical_key_pressed(KEY_CTRL):
		motion.present_ground_step(_gait.pose(fighter.global_position.x), _gait_entry, 0.0)


func _drive_input() -> void:
	var id: String = motion.active["id"]
	if id == "knockback":
		return
	if id == "get_up" and not motion.playing:
		_request("ready")
		return
	if id == "jump" and motion.progress() >= 0.80:
		_request("landing")
		return
	if Input.is_action_just_pressed("jump"):
		_request("jump")
	for index: int in 3:
		if Input.is_action_just_pressed([&"light_attack", &"heavy_attack", &"kick_attack"][index]):
			if not _grounded_motion and id in ["neutral", "ready"]:
				_face_target()
			_request(["diagonal", "heavy", "front_kick"][index])
	id = motion.active["id"]
	if motion.playing and id not in ["neutral", "ready", "forward", "backward", "guard"]:
		return
	if Input.is_physical_key_pressed(KEY_F):
		if id != "guard":
			if not _grounded_motion and id in ["neutral", "ready"]:
				_face_target()
			_request("guard")
		return
	if _grounded_motion:
		return
	if id == "guard":
		_request("neutral")
		return
	var axis: float = Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis) and motion.rig.visible:
		_start_ground_motion(axis)
	elif id != "neutral" and not motion.playing:
		_request("neutral")


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if not enabled or menu_open or key == null or key.echo or not key.pressed:
		return
	if motion.active["id"] == "knockback":
		if key.physical_keycode == KEY_G:
			_request("get_up")
		return
	if key.physical_keycode in [KEY_E, KEY_SHIFT, KEY_U, KEY_I] and motion.active["id"] in ["neutral", "ready"]:
		_face_target()
	match key.physical_keycode:
		KEY_E: _request("dash")
		KEY_SHIFT: _request("void_step")
		KEY_U: _request("void_burst")
		KEY_I: _request("void_burst_main")
		KEY_1: practice_hit("hit", 4.0)
		KEY_2: practice_hit("heavy_hit", 8.0)
		KEY_3: practice_hit("directional_hit", 5.0)
		KEY_4: practice_hit("directional_hit_rear", 5.0)
		KEY_5: practice_hit("knockback", 10.0)
		_: return
	get_viewport().set_input_as_handled()


func practice_hit(id: String, amount: float) -> bool:
	if not enabled or motion.active["id"] in ["knockback", "get_up", "jump", "landing"]:
		return false
	if not _request(id):
		return false
	var guarded: bool = Input.is_physical_key_pressed(KEY_F)
	var hp: HealthComponent = fighter.get_node_or_null("HealthComponent") as HealthComponent
	if hp != null:
		# Repeated reaction drills keep the practice fighter alive.
		hp.apply_damage(clampf(amount * (0.5 if guarded else 1.0), 0.0, maxf(hp.current_health - 1.0, 0.0)), target.dummy)
	impacts += 1
	_report.call("RAEZEN  ·  " + String(motion.active["title"]).to_upper())
	return true


func _use_rig(rig: Rig) -> void:
	if motion.rig != rig:
		motion.rig.hide()
		motion.rig = rig
		rig.show()


func _request(id: String) -> bool:
	var start_id: String = motion.active["id"]
	if not motion.play_profile(_profiles[id]):
		return false
	if String(motion.active["id"]) != start_id or id == start_id:
		if motion.rig == _walk_rig:
			_use_rig(_action_rig)
			motion.advance(0.0)
		_walk_landing = -1.0
		motion.speed = 1.0
		_grounded_motion = false
		_rest_pose.clear()
		_last_sample = _sample_position()
		_dash_travel = 0.0
	return true


func _sample_position() -> Vector2:
	var local: Vector2 = motion._last_pose["root"] if motion.rig.visible else Vector2.ZERO
	return local + Vector2(motion.world_x, 0.0)


func _face_target() -> void:
	var dx: float = target.dummy.global_position.x - fighter.global_position.x
	if absf(dx) > 0.01:
		_set_facing(signf(dx))


func _set_facing(direction: float) -> void:
	facing = direction
	target.sprite.flip_h = facing > 0.0


func _project() -> void:
	var local: Vector2 = motion._last_pose["root"] if motion.rig.visible else Vector2.ZERO
	var width: int = maxi(512, motion.correction.texture.get_width()) if motion.correction.visible else 512
	if width != _stage.size.x:
		_stage.size.x = width
	_display.scale = Vector2(SCALE * facing, SCALE)
	_display.offset.x = motion.paint_shift_x - motion.paint_origin_x
	_display.global_position = fighter.global_position - Vector2((256.0 + local.x) * SCALE * facing, (FLOOR + PADDING + local.y) * SCALE)


func _on_event(event: String, _seconds: float) -> void:
	var id: String = motion.active["id"]
	if event != "contact" or not ATTACK_KIND.has(id):
		return
	var separation: float = (target.dummy.global_position.x - fighter.global_position.x) * facing
	if separation <= 0.0:
		return
	var burst: bool = id in ["void_burst", "void_burst_main"]
	var kick: bool = id == "front_kick"
	var reach: float = 236.0 if burst else (116.0 if kick else 169.0)
	_contact.size = Vector2(reach, 100) if not kick else Vector2(reach, 60)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _contact
	query.transform = Transform2D(0.0, fighter.global_position + Vector2(reach * 0.5 * facing, -125.0 if kick else -135.0))
	var hurtbox: Area2D = target.dummy.get_node("Hurtbox")
	query.collision_mask = hurtbox.collision_layer
	query.collide_with_bodies = false
	query.collide_with_areas = true
	for overlap: Dictionary in fighter.get_world_2d().direct_space_state.intersect_shape(query):
		if overlap["collider"] == hurtbox:
			target.strike(ATTACK_KIND[id], fighter)
			_report.call(String(motion.active["title"]).to_upper() + "  ·  ")
			return




