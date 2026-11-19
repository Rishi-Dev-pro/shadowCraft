extends SceneTree
## Render the complete loop and idle round trips at game scale.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Preview = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const Body = preload("res://experimental/kai_hybrid/hybrid_body.gd")
const IdleMotion = preload("res://experimental/kai_hybrid/idle_motion.gd")
const STEP: float = 1.0 / 30.0

var _lab: Lab
var _destination: String
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_destination = OS.get_environment("KAI_IDLE_CAPTURE_DIR")
	if _destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	_lab = LAB.instantiate() as Lab
	root.add_child(_lab)
	await process_frame
	var body: Body = _lab.get_node("%HybridBody")
	var skeleton: Skeleton2D = body.find_child("Skeleton2D") as Skeleton2D
	var near_boot: Bone2D = skeleton.find_child("RightFoot") as Bone2D
	var far_boot: Bone2D = skeleton.find_child("LeftFoot") as Bone2D
	var near_rest: Vector2 = near_boot.global_position
	var far_rest: Vector2 = far_boot.global_position
	var buttons: HBoxContainer = _lab.get_node("%PoseButtons")
	await _capture("neutral")
	buttons.get_child(0).pressed.emit()
	_lab.controller.stop_playback()
	var worst_contact: float = 0.0
	var rigid: bool = true
	for frame: int in ceili((IdleMotion.LOOP_SECONDS + 0.8) / STEP):
		_lab.controller.advance_preview(STEP)
		worst_contact = maxf(worst_contact, near_boot.global_position.distance_to(near_rest))
		worst_contact = maxf(worst_contact, far_boot.global_position.distance_to(far_rest))
		rigid = rigid and body.scale.is_equal_approx(Vector2.ONE)
		for index: int in skeleton.get_bone_count():
			rigid = rigid and skeleton.get_bone(index).scale.is_equal_approx(Vector2.ONE)
		await _capture("idle_%03d" % frame, true)
	_check(worst_contact < 0.1, "Both idle feet held their neutral targets. Maximum error: %.5f px" % worst_contact)
	_check(rigid, "Idle preserves unit scale on every bone and the body")
	body.apply_idle(0.0, 0.0)
	await RenderingServer.frame_post_draw
	var neutral: PackedByteArray = root.get_texture().get_image().get_data()
	for time: float in [0.65, 4.70, 7.70, 10.95, 15.78, 22.0]:
		body.apply_idle(time, 1.0)
		await RenderingServer.frame_post_draw
		_check(neutral == root.get_texture().get_image().get_data(), "No residual body or cloth motion in rest at %.2f s" % time)
	body.apply_idle(5.75, 1.0)
	await RenderingServer.frame_post_draw
	var first: PackedByteArray = root.get_texture().get_image().get_data()
	_check(first != neutral, "Observation pose visibly differs from the settled stance")
	body.apply_idle(5.75 + IdleMotion.LOOP_SECONDS, 1.0)
	await RenderingServer.frame_post_draw
	_check(first == root.get_texture().get_image().get_data(), "Rendered pose is pixel-identical across the loop boundary")
	for index: int in [4, 5, 1, 2, 3]:
		_lab.get_node("%Reset").pressed.emit()
		buttons.get_child(0).pressed.emit()
		_lab.controller.stop_playback()
		var warmup_frames: int = 68 if index == 4 else (377 if index == 5 else 156)
		for warmup: int in warmup_frames:
			_lab.controller.advance_preview(STEP)
		var left_idle: bool = false
		for frame: int in 100:
			if frame == 7:
				buttons.get_child(index).pressed.emit()
				_lab.controller.stop_playback()
			if index >= 4 and frame == 48:
				buttons.get_child(6).pressed.emit()
				_lab.controller.stop_playback()
			_lab.controller.advance_preview(STEP)
			# A handoff may start the normal frame clock again. Keep capture on
			# the single explicit clock so every sample stays 1/30 second apart.
			_lab.controller.stop_playback()
			left_idle = left_idle or not _lab.controller.idle_active
			await _capture("round_%d_%03d" % [index, frame], true)
		_check(left_idle and _lab.controller.idle_active, "Round trip returned to animated idle, button %d" % index)
	print("Idle visual capture checks failed: ", _failures)
	quit(int(_failures != 0))


func _capture(name: String, crop: bool = false) -> void:
	await RenderingServer.frame_post_draw
	var pixels: Image = root.get_texture().get_image()
	if crop:
		pixels = pixels.get_region(Rect2i(805, 332, 275, 342))
	if pixels.save_png(_destination.path_join(name + ".png")) != OK:
		_check(false, "Could not save " + name)


func _check(valid: bool, message: String) -> void:
	if valid:
		print("PASS ", message)
	else:
		_failures += 1
		push_error(message)
