extends SceneTree
## Capture the visible jump and its existing locomotion exits at 60 Hz.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Preview = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const JumpMotion = preload("res://experimental/kai_hybrid/jump_motion.gd")
const STEP: float = 1.0 / 60.0

var _lab: Lab
var _destination: String
var _errors: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_destination = OS.get_environment("KAI_JUMP_CAPTURE_DIR")
	if _destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	_lab = LAB.instantiate() as Lab
	root.add_child(_lab)
	await process_frame
	var body: Node2D = _lab.get_node("%HybridBody")
	var reference: SubViewport = _lab.get_node("OriginalView/Stage")
	var stage: SubViewport = _lab.get_node("HybridView/Stage")
	var buttons: HBoxContainer = _lab.get_node("%PoseButtons")
	var skeleton: Skeleton2D = body.find_child("Skeleton2D") as Skeleton2D
	var rear: Bone2D = skeleton.find_child("RightFoot") as Bone2D
	var front: Bone2D = skeleton.find_child("LeftFoot") as Bone2D
	var rest_rear: Vector2 = rear.global_position
	var rest_front: Vector2 = front.global_position
	var cases: Dictionary[String, int] = {"neutral": -1, "idle": 0, "guard": 1, "forward": 4, "backward": 5, "repeat": 7}
	if OS.get_cmdline_user_args().has("neutral-only"):
		cases = {"neutral": -1}
	await RenderingServer.frame_post_draw
	var neutral: PackedByteArray = stage.get_texture().get_image().get_data()
	_check(neutral.size() == reference.get_texture().get_image().get_data().size(), "Reference and hybrid share framing")
	for name: String in cases:
		_lab.get_node("%Reset").pressed.emit()
		if name == "idle":
			buttons.get_child(0).pressed.emit()
			_lab.controller.stop_playback()
			_lab.controller.advance_preview(5.65)
		buttons.get_child(7).pressed.emit()
		_lab.controller.stop_playback()
		var phases: Array[int] = []
		var worst_contact: float = 0.0
		var penetration: float = 0.0
		var unit_scale: bool = true
		var count: int = 167 if name == "repeat" else 134
		for frame: int in count:
			if frame == 24 and cases[name] >= 0 and name != "idle":
				buttons.get_child(cases[name]).pressed.emit()
			if _lab.controller.jump_active or _lab.controller.walk_active or _lab.controller.idle_active:
				_lab.controller.advance_preview(STEP)
				_lab.controller.stop_playback()
			if _lab.controller.jump_active:
				var phase: int = _lab.controller.jump_state
				if phases.is_empty() or phase != phases.back():
					phases.append(phase)
				var grounded: bool = phase == JumpMotion.State.JUMP_START or phase >= JumpMotion.State.LANDING
				if grounded:
					worst_contact = maxf(worst_contact, rear.global_position.distance_to(rest_rear))
					worst_contact = maxf(worst_contact, front.global_position.distance_to(rest_front))
				penetration = maxf(penetration, rear.global_position.y - rest_rear.y)
				penetration = maxf(penetration, front.global_position.y - rest_front.y)
				for bone: int in skeleton.get_bone_count():
					unit_scale = unit_scale and skeleton.get_bone(bone).scale.is_equal_approx(Vector2.ONE)
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image().get_region(Rect2i(780, 250, 335, 425))
			if image.save_png(_destination.path_join("%s_%03d.png" % [name, frame])) != OK:
				_check(false, "Could not save jump capture")
		var expected: Array[int] = [0, 1, 2, 3, 4, 5]
		if name == "repeat":
			expected.append_array([0, 1, 2, 3, 4, 5])
		_check(phases == expected, "%s visited each jump phase in order" % name)
		_check(unit_scale and body.scale.is_equal_approx(Vector2.ONE), "%s retained unit scale" % name)
		_check(worst_contact < 0.1 and penetration < 0.1, "%s contact drift %.5f px, pivot penetration %.5f px" % [name, worst_contact, penetration])
		_check(not _lab.controller.jump_active, "%s completed landing recovery" % name)
		match name:
			"forward", "backward":
				_check(_lab.controller.walk_cycle.direction == (1 if name == "forward" else -1), "Reached " + name + " walk")
			"guard":
				_check(_lab.controller.duration() < 1.0 and not _lab.controller.walk_active, "Settled into guard")
			"idle":
				_check(_lab.controller.idle_active, "Resumed accepted idle")
			_:
				_check(stage.get_texture().get_image().get_data() == neutral, "Returned to pixel-identical neutral")
	print("Jump capture failures: ", _errors)
	quit(int(_errors > 0))


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_errors += 1
		push_error(message)
