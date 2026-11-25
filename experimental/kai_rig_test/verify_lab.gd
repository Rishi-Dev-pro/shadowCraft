extends SceneTree
## Run with --script and set KAI_RIG_CAPTURE_DIR to save PNG review evidence.

const Lab = preload("res://experimental/kai_rig_test/kai_rig_lab.gd")
const LAB_SCENE: String = "res://experimental/kai_rig_test/kai_rig_lab.tscn"

var _lab: Lab
var _capture_dir: String
var _rendered: bool
var _checks: int
var _failures: int


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_rendered = DisplayServer.get_name() != "headless"
	_capture_dir = OS.get_environment("KAI_RIG_CAPTURE_DIR")
	if _rendered:
		await process_frame
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
	if change_scene_to_file(LAB_SCENE) != OK:
		quit(1)
		return
	await scene_changed
	_lab = current_scene as Lab
	if OS.get_cmdline_user_args().has("--repaired-art"):
		_lab.repair_toggle.button_pressed = true
		var seat: Sprite2D = _lab.rig.find_child("SeatUnderlay", true, false) as Sprite2D
		_check(seat != null and seat.visible and seat.texture != null, "Revised artwork loaded")
	var bones: Array[Node] = _lab.rig.get_node("Skeleton2D").find_children("*", "Bone2D")
	var near_boot: Bone2D = _lab.rig.find_child("RightFoot") as Bone2D
	var far_boot: Bone2D = _lab.rig.find_child("LeftFoot") as Bone2D
	var neutral_near: Vector2 = near_boot.global_position
	var neutral_far: Vector2 = far_boot.global_position
	var rest: Dictionary[StringName, Transform2D] = {}
	for bone: Bone2D in bones:
		rest[bone.name] = bone.transform
	_check(bones.size() == 23, "23 bones loaded")
	var original_layer_count: int = 0
	for sprite: Node in _lab.rig.find_children("*", "Sprite2D"):
		if sprite.has_meta(&"approved_png"):
			original_layer_count += 1
	_check(original_layer_count == 19, "19 registered original layers bound")
	_check(_lab.rig.find_children("*", "AnimationPlayer").is_empty(), "Static poses only")

	if _rendered:
		await _check_neutral_pixels()
		await _capture("pose_01_neutral")

	for index: int in Lab.JOINTS.size():
		var spec: Dictionary = Lab.JOINTS[index]
		var joint: StringName = spec["bone"]
		_lab.joint_menu.select(index + 1)
		_lab.joint_menu.item_selected.emit(index + 1)
		_check(not _lab.rig.joint_transform(joint).is_equal_approx(rest[joint]), "%s moves %s" % [spec["label"], joint])
		var isolated: bool = true
		for bone: Bone2D in bones:
			if bone.name != joint and not bone.transform.is_equal_approx(rest[bone.name]):
				isolated = false
		_check(isolated, "%s affects one local transform" % spec["label"])
		var limits: Vector2 = spec["range"]
		var values: Array[float] = [limits.x, -10.0, 10.0, float(spec["sample"]), limits.y]
		for value: float in values:
			_lab.primary.value = value
			if spec.get("pelvis", false):
				_lab.secondary.value = 0 if absf(value) == 10.0 else (10 if value >= 0 else -10)
			elif spec.get("slide", false):
				_lab.secondary.value = 0 if absf(value) == 10.0 else (6 if value >= 0 else -6)
			await _capture("joint_%02d_%+04d" % [index, value], true)
		if spec.get("slide", false) or spec.get("pelvis", false):
			_lab.primary.value = 0
			_lab.secondary.value = 0
			_lab.secondary.value = 8
			_check(not _lab.rig.joint_transform(joint).is_equal_approx(rest[joint]), "%s secondary slider works independently" % spec["label"])
			await _capture("joint_%02d_secondary" % index, true)

	for i: int in range(1, Lab.POSES.size()):
		_lab.pose_menu.select(i)
		_lab.pose_menu.item_selected.emit(i)
		var changed: bool = false
		var rigid: bool = true
		for bone: Bone2D in bones:
			changed = changed or not bone.transform.is_equal_approx(rest[bone.name])
			rigid = rigid and bone.scale.is_equal_approx(Vector2.ONE)
		_check(changed and rigid, "%s deforms without bone scaling" % Lab.POSES[i]["label"])
		if Lab.POSES[i].has("stance"):
			var spread: float = Lab.POSES[i]["stance"].y
			_check(near_boot.global_position.distance_to(neutral_near - Vector2(spread, 0)) < 0.2
				and far_boot.global_position.distance_to(neutral_far + Vector2(spread, 0)) < 0.2,
				"%s holds both boot pivots at the intended ground positions" % Lab.POSES[i]["label"])
		await _capture("pose_%02d_%s" % [i + 1, String(Lab.POSES[i]["label"]).to_snake_case()])

	if _rendered:
		await RenderingServer.frame_post_draw
		var deformed: PackedByteArray = _lab.stage.get_texture().get_image().get_data()
		_lab.get_node("%Reset").pressed.emit()
		await RenderingServer.frame_post_draw
		_check(deformed != _lab.stage.get_texture().get_image().get_data(), "Reset redraws the neutral artwork")
	else:
		_lab.get_node("%Reset").pressed.emit()
	var reset_ok: bool = true
	for bone: Bone2D in bones:
		reset_ok = reset_ok and bone.transform.is_equal_approx(rest[bone.name])
	_check(reset_ok, "Reset restores every local transform")
	if _rendered:
		await _check_neutral_pixels()
	print("KAI RIG LAB: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check_neutral_pixels() -> void:
	_lab.floor_line.hide()
	await RenderingServer.frame_post_draw
	var registered: PackedByteArray = _lab.stage.get_texture().get_image().get_data()
	_lab.reference_toggle.button_pressed = true
	await RenderingServer.frame_post_draw
	var approved: PackedByteArray = _lab.stage.get_texture().get_image().get_data()
	var differing_pixels: int = 0
	var maximum_delta: int = 0
	for first: int in range(0, registered.size(), 4):
		var pixel_delta: int = 0
		for channel: int in range(4):
			pixel_delta = maxi(pixel_delta, absi(int(registered[first + channel]) - int(approved[first + channel])))
		if pixel_delta > 0:
			differing_pixels += 1
			maximum_delta = maxi(maximum_delta, pixel_delta)
	_check(maximum_delta <= 1, "Neutral versus approved render: %d pixels differ, max channel delta %d/255" % [differing_pixels, maximum_delta])
	_lab.reference_toggle.button_pressed = false
	_lab.floor_line.show()


func _capture(file: String, stage_only: bool = false) -> void:
	if not _rendered or _capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var viewport: Viewport = _lab.stage if stage_only else root
	var result: Error = viewport.get_texture().get_image().save_png(_capture_dir.path_join(file + ".png"))
	if result != OK:
		_check(false, "Save " + file)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS " if condition else "FAIL ") + message)
