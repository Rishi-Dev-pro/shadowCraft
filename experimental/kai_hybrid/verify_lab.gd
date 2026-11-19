extends SceneTree
## Visible Godot run. Capture fixed-time samples as well as exercise live playback.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Preview = preload("res://experimental/kai_hybrid/hybrid_controller.gd")

var _failures: int = 0
var _directory: String
var _lab: Lab


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_directory = OS.get_environment("KAI_HYBRID_CAPTURE_DIR")
	if _directory.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	_lab = LAB.instantiate() as Lab
	root.add_child(_lab)
	await process_frame
	var body: Node2D = _lab.get_node("%HybridBody")
	var correction: Sprite2D = _lab.get_node("%Correction")
	var skeleton: Skeleton2D = body.find_child("Skeleton2D") as Skeleton2D
	_check(skeleton != null, "Skeleton2D loaded")
	if skeleton == null:
		quit(1)
		return
	var rear_boot: Bone2D = skeleton.find_child("RightFoot") as Bone2D
	var front_boot: Bone2D = skeleton.find_child("LeftFoot") as Bone2D
	var rear_floor: float = rear_boot.global_position.y
	var front_floor: float = front_boot.global_position.y
	await _capture("neutral")
	await _compare_neutral()
	for mode: int in [1, 2, 3]:
		var pose_button: Button = _lab.get_node("%PoseButtons").get_child(mode)
		pose_button.pressed.emit()
		_check(body.visible != correction.visible, "Only one artwork surface at pose %d" % mode)
		await _capture("pose_%d" % mode)
		var play: Button = _lab.get_node("%Play")
		play.pressed.emit()
		await create_timer(0.18).timeout
		_check(_lab.controller.is_processing(), "Live playback for pose %d" % mode)
		var pause: Button = _lab.get_node("%Pause")
		pause.pressed.emit()
		_check(not _lab.controller.is_processing(), "Pause holds pose %d" % mode)
		_lab.get_node("%Restart").pressed.emit()
		_check(_lab.controller.is_processing(), "Restart resumes from neutral")
		_lab.controller.stop_playback()
		var length: float = _lab.controller.duration()
		var crouch_scale_ok: bool = true
		var crouch_contact_ok: bool = true
		for frame: int in range(ceili(length * 30.0) + 1):
			_lab.controller.sample_transition(float(frame) / 30.0)
			if body.visible == correction.visible:
				_check(false, "Artwork ownership at pose %d frame %d" % [mode, frame])
			if mode == Preview.Pose.CROUCH:
				crouch_scale_ok = crouch_scale_ok and body.scale.is_equal_approx(Vector2.ONE) and correction.scale.is_equal_approx(Vector2.ONE)
				for index: int in skeleton.get_bone_count():
					crouch_scale_ok = crouch_scale_ok and skeleton.get_bone(index).scale.is_equal_approx(Vector2.ONE)
				if body.visible:
					crouch_contact_ok = crouch_contact_ok and absf(rear_boot.global_position.y - rear_floor) < 0.1
					crouch_contact_ok = crouch_contact_ok and absf(front_boot.global_position.y - front_floor) < 0.1
			await _capture("transition_%d_%03d" % [mode, frame])
		if mode == Preview.Pose.CROUCH:
			_check(crouch_scale_ok, "Crouch uses unit bone, body and correction scale")
			_check(crouch_contact_ok, "Skeletal crouch keeps both boot pivots at their floor heights")
		_check(body.visible and not correction.visible, "Recovery returns to skeletal neutral")
	_lab.get_node("%Reset").pressed.emit()
	_check(body.visible and not correction.visible, "Reset restores skeletal neutral")
	await _compare_neutral()
	print("Hybrid lab failures: %d" % _failures)
	quit(int(_failures > 0))


func _capture(file: String) -> void:
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_directory.path_join(file + ".png")) == OK, "Capture " + file, false)


func _compare_neutral() -> void:
	await RenderingServer.frame_post_draw
	var source: SubViewport = _lab.get_node("OriginalView/Stage")
	var hybrid: SubViewport = _lab.get_node("HybridView/Stage")
	var a: PackedByteArray = source.get_texture().get_image().get_data()
	var b: PackedByteArray = hybrid.get_texture().get_image().get_data()
	var maximum: int = 0
	for index: int in a.size():
		maximum = maxi(maximum, absi(int(a[index]) - int(b[index])))
	_check(maximum <= 1, "Native neutral comparison max delta %d/255" % maximum)


func _check(ok: bool, description: String, log_pass: bool = true) -> void:
	if not ok:
		_failures += 1
		push_error(description)
	elif log_pass:
		print("PASS " + description)
