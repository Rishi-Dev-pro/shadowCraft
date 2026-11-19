extends SceneTree
## Capture each contact-aware transition from the visible comparison lab.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Preview = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const FPS: float = 30.0

var _lab: Lab
var _destination: String
var _errors: int = 0
var _worst_contact: float = 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_destination = OS.get_environment("KAI_WALK_CAPTURE_DIR")
	if _destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	_lab = LAB.instantiate() as Lab
	root.add_child(_lab)
	await process_frame
	var body: Node2D = _lab.get_node("%HybridBody")
	var rear: Bone2D = body.find_child("RightFoot") as Bone2D
	var front: Bone2D = body.find_child("LeftFoot") as Bone2D
	var rear_rest: Vector2 = rear.global_position
	var front_rest: Vector2 = front.global_position
	var cases: Dictionary[String, Vector2i] = {
		"idle_forward": Vector2i(0, 1), "forward_idle": Vector2i(1, 0),
		"idle_backward": Vector2i(0, -1), "backward_idle": Vector2i(-1, 0),
		"forward_backward": Vector2i(1, -1), "backward_forward": Vector2i(-1, 1),
		"forward_guard": Vector2i(1, 2), "backward_guard": Vector2i(-1, 2),
		"guard_forward": Vector2i(2, 1), "guard_backward": Vector2i(2, -1),
	}
	for name: String in cases:
		var pair: Vector2i = cases[name]
		_lab.controller.select_pose(Preview.Pose.GUARD if pair.x == 2 else Preview.Pose.NEUTRAL)
		if absi(pair.x) == 1:
			_lab.controller.request_walk(pair.x)
			_lab.controller.stop_playback()
			for index: int in 37:
				_lab.controller.advance_walk(1.0 / FPS)
		var switch_frame: int = 12
		var count: int = 88 if name.begins_with("idle_") else 55
		for frame: int in count:
			if frame == switch_frame:
				_lab.controller.request_walk(pair.y if pair.y != 2 else 0, pair.y == 2)
				_lab.controller.stop_playback()
			if _lab.controller.walk_active:
				_lab.controller.advance_walk(1.0 / FPS)
			if _lab.controller.walk_active and _lab.controller.walk_cycle.direction != 0:
				var travel: Vector2 = Vector2(_lab.controller.walk_cycle.travel(), 0.0)
				var rear_step: Vector2 = _lab.controller.walk_cycle.foot(true)
				var front_step: Vector2 = _lab.controller.walk_cycle.foot(false)
				if rear_step.y > -0.001:
					_worst_contact = maxf(_worst_contact, (rear.global_position + travel).distance_to(rear_rest + rear_step))
				if front_step.y > -0.001:
					_worst_contact = maxf(_worst_contact, (front.global_position + travel).distance_to(front_rest + front_step))
				_check(rear_step.y > -0.001 or front_step.y > -0.001, "At least one boot in contact")
			await RenderingServer.frame_post_draw
			var filename: String = "%s_%03d.png" % [name, frame]
			_check(root.get_texture().get_image().save_png(_destination.path_join(filename)) == OK, filename)
		if absi(pair.y) == 1:
			_check(_lab.controller.walk_active and _lab.controller.walk_cycle.direction == pair.y, "Reached direction for " + name)
		else:
			_check(not _lab.controller.walk_active, "Settled in " + name)
		print("Captured ", name)
	_check(_worst_contact < 0.1, "Planted boot target error under 0.1 px")
	print("Maximum world-space contact error: ", _worst_contact, " px. Failures: ", _errors)
	quit(int(_errors > 0))


func _check(condition: bool, description: String) -> void:
	if not condition:
		_errors += 1
		push_error(description)
