extends SceneTree
## Run in visible Godot to capture the three bursts and their handoffs at 60 Hz.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Preview = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const Dash = preload("res://experimental/kai_hybrid/dash_motion.gd")
const STEP: float = 1.0 / 60.0
const CASES: Dictionary[String, Vector3i] = {
	"forward_idle": Vector3i(0, 0, -1), "forward_walk": Vector3i(0, 4, -1), "forward_guard": Vector3i(0, 1, -1),
	"backward_idle": Vector3i(1, 0, -1), "backward_walk": Vector3i(1, 5, -1), "backward_guard": Vector3i(1, 1, -1),
	"evade_idle": Vector3i(2, 0, -1), "evade_guard": Vector3i(2, 1, -1),
	"forward_to_backward_walk": Vector3i(0, 0, 5), "retreat_to_forward_walk": Vector3i(1, 0, 4),
	"evade_to_guard": Vector3i(2, 0, 1), "repeat": Vector3i(0, -1, -1),
}

var _errors: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var destination: String = OS.get_environment("KAI_DASH_CAPTURE_DIR")
	if destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var lab: Lab = LAB.instantiate() as Lab
	root.add_child(lab)
	await process_frame
	var buttons: HBoxContainer = lab.get_node("%PoseButtons")
	var controller: Preview = lab.controller
	var body: Node2D = lab.get_node("%HybridBody")
	var skeleton: Skeleton2D = body.find_child("Skeleton2D") as Skeleton2D
	var rear: Bone2D = skeleton.find_child("RightFoot") as Bone2D
	var front: Bone2D = skeleton.find_child("LeftFoot") as Bone2D
	var rest: Vector2 = Vector2(rear.global_position.x, front.global_position.x)
	var floor: Vector2 = Vector2(rear.global_position.y, front.global_position.y)
	var single: bool = OS.get_cmdline_user_args().has("quick")
	for name: String in CASES:
		if single and not name.ends_with("_idle"):
			continue
		var info: Vector3i = CASES[name]
		lab.get_node("%Reset").pressed.emit()
		if info.y >= 0:
			buttons.get_child(info.y).pressed.emit()
			if info.y != 1:
				for frame: int in (147 if info.y == 0 else 18):
					controller.advance_preview(STEP)
		controller.stop_playback()
		buttons.get_child(8 + info.x).pressed.emit()
		_check(controller.dash_active, name + " starts dash")
		var sequence: Array[int] = []
		var error: float = 0.0
		var penetration: float = 0.0
		var facing: bool = true
		var has_support: bool = true
		var collider: CharacterBody2D = lab.get_node("%DashCollider")
		var initial_x: float = collider.global_position.x
		var previous_travel: float = 0.0
		var largest_step: float = 0.0
		for frame: int in (85 if name == "repeat" else 60):
			if frame == 9:
				_check(not controller.request_dash(Dash.Kind.BACKWARD), name + " rejects overlapping dash")
				if info.z >= 0:
					buttons.get_child(info.z).pressed.emit()
			if name == "repeat" and frame == 38:
				_check(controller.request_dash(Dash.Kind.FORWARD), "A second dash is accepted after recovery")
			if controller.dash_active or controller.walk_active or controller.idle_active:
				controller.advance_preview(STEP)
				controller.stop_playback()
			largest_step = maxf(largest_step, absf(controller.dash_world_x - previous_travel))
			previous_travel = controller.dash_world_x
			if controller.dash_active:
				var phase: int = controller.dash.phase()
				if sequence.is_empty() or phase != sequence.back():
					sequence.append(phase)
				var travel: Vector2 = Vector2(controller.dash.pose_travel(), 0.0)
				var rear_path: Vector2 = controller.dash.foot(true)
				var front_path: Vector2 = controller.dash.foot(false)
				has_support = has_support and (rear_path.y >= -0.001 or front_path.y >= -0.001)
				var rear_target: Vector2 = Vector2(rest.x, floor.x) + rear_path - travel
				var front_target: Vector2 = Vector2(rest.y, floor.y) + front_path - travel
				error = maxf(error, maxf(rear.global_position.distance_to(rear_target), front.global_position.distance_to(front_target)))
				penetration = maxf(penetration, maxf(rear.global_position.y - floor.x, front.global_position.y - floor.y))
				facing = facing and body.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(body.position.y)
				for bone: int in skeleton.get_bone_count():
					facing = facing and skeleton.get_bone(bone).scale.is_equal_approx(Vector2.ONE)
			await RenderingServer.frame_post_draw
			var pixels: Image = root.get_texture().get_image()
			if pixels.save_png(destination.path_join("%s_%03d.png" % [name, frame])) != OK:
				_check(false, "Capture failed: " + name)
		var expected: Array[int] = [0, 1, 2]
		if name == "repeat":
			expected.append_array([0, 1, 2])
		_check(sequence == expected and not controller.dash_active, name + " visits all phases and exits recovery")
		_check(error < 0.12 and penetration < 0.12 and facing, "%s foot error %.5f px, penetration %.5f px, facing and scale: %s" % [name, error, penetration, facing])
		_check(has_support, name + " keeps one boot planted throughout the dash")
		var expected_distance: float = Dash.DISTANCE[info.x] * (2.0 if name == "repeat" else 1.0)
		var measured: float = collider.global_position.x - initial_x
		var peak_step: float = 2.0 * absf(Dash.DISTANCE[info.x]) * STEP / Dash.BURST[info.x]
		_check(is_equal_approx(measured, expected_distance) and largest_step <= peak_step + 0.001,
			"%s configured %.2f px, measured %.2f px, max frame travel %.2f px" % [name, expected_distance, measured, largest_step])
		var exit_button: int = info.z if info.z >= 0 else info.y
		match exit_button:
			0:
				_check(controller.idle_active, name + " returns to idle")
			1:
				_check(not controller.walk_active and controller.duration() < 1.0, name + " settles into guard")
			4, 5:
				_check(controller.walk_cycle.direction == (1 if exit_button == 4 else -1), name + " enters the selected walk")
	lab.get_node("%Reset").pressed.emit()
	buttons.get_child(7).pressed.emit()
	_check(controller.jump_active and not controller.request_dash(Dash.Kind.EVASIVE), "Dash is rejected safely during jump")
	lab.get_node("%Reset").pressed.emit()
	_check(not controller.dash_active and is_zero_approx(controller.dash_world_x), "Reset clears the dash and lab travel")
	await _verify_walls(lab)
	print("Dash verification failures: ", _errors)
	quit(int(_errors != 0))


func _verify_walls(lab: Lab) -> void:
	var collider: CharacterBody2D = lab.get_node("%DashCollider")
	var hull: RectangleShape2D = (collider.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	var controller: Preview = lab.controller
	var wall: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(2.0, 176.0)
	shape.shape = rectangle
	wall.add_child(shape)
	collider.get_parent().add_child(wall)
	for kind: Dash.Kind in [Dash.Kind.FORWARD, Dash.Kind.BACKWARD, Dash.Kind.EVASIVE]:
		lab.get_node("%Reset").pressed.emit()
		var direction: float = signf(Dash.DISTANCE[kind])
		var origin: float = collider.global_position.x
		wall.global_position = Vector2(origin + direction * (60.0 + hull.size.x * 0.5 + rectangle.size.x * 0.5), collider.global_position.y - 88.0)
		await physics_frame
		await process_frame
		_check(controller.request_dash(kind), "Wall case starts " + Dash.NAMES[kind])
		# Submit the entire burst in one step to exercise tunnelling protection.
		controller.advance_preview(Dash.PREP[kind] + Dash.BURST[kind])
		controller.stop_playback()
		var measured: float = (collider.global_position.x - origin) * direction
		_check(controller.dash_blocked and measured <= 60.001 and measured > 59.0,
			"%s stops at the thin wall after %.2f px" % [Dash.NAMES[kind], measured])
		controller.advance_preview(Dash.RECOVERY[kind])
		_check(not controller.dash_active and is_equal_approx((collider.global_position.x - origin) * direction, measured),
			"Blocked dash keeps position through recovery")
	wall.queue_free()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_errors += 1
		push_error(description)
	else:
		print("PASS ", description)
