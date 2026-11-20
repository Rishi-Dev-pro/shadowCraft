extends SceneTree
## Headless structural checks plus optional Compatibility-rendered captures.

const LAB = preload("res://experimental/raezen_hybrid/raezen_hybrid_lab.tscn")
const Lab = preload("res://experimental/raezen_hybrid/raezen_hybrid_lab.gd")
const Motion = preload("res://experimental/raezen_hybrid/motion_player.gd")
const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")

var _errors: int = 0
var _directory: String
var _lab: Lab
var _events: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_directory = OS.get_environment("RAEZEN_CAPTURE_DIR")
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
	else:
		_directory = ""
	_lab = LAB.instantiate() as Lab
	root.add_child(_lab)
	await process_frame
	var player: Motion = _lab.player
	var rig: Rig = player.rig
	_check(player.profiles.size() == 17, "All 17 requested motion profiles are present")
	_check(rig.bones.size() == 29 and rig.skeleton.get_bone_count() == 29, "All 29 articulated bones are registered")
	_check(rig.weapon.get_parent() == rig.bones["HandNear"] and rig.weapon.pivot.get_parent() == rig.weapon,
		"Blade pivot is a child of the mounted palm socket")
	var blade_length: float = rig.weapon.tip.position.length()
	_check(blade_length > 0.0 and rig.weapon.tip.get_parent() == rig.weapon.pivot
		and rig.weapon.offhand.get_parent() == rig.weapon.pivot, "Blade tip and offhand follow the same pivot")
	var art_valid: bool = true
	for name: String in rig.layers:
		var layer: Sprite2D = rig.layers[name]
		var texture: Image = layer.texture.get_image()
		art_valid = art_valid and texture.get_used_rect().has_area()
		art_valid = art_valid and texture.get_width() <= 512 and texture.get_height() <= 512
	_check(art_valid, "All registered layers contain bounded artwork")
	if not _directory.is_empty():
		await RenderingServer.frame_post_draw
		_verify_rendered_neutral()
	player.event_fired.connect(_record_event)
	var identifiers: Dictionary = {}
	for index: int in player.profiles.size():
		var profile: Dictionary = player.profiles[index]
		_check(not identifiers.has(profile["id"]), "Unique profile " + profile["id"])
		identifiers[profile["id"]] = index
		_validate_profile(profile, player)
		if not _directory.is_empty():
			player.inspect_pose(index, profile["sample"])
			_lab.selected.select(index)
			_lab._update_status()
			await _capture(profile["id"] + "_peak")
		player.inspect_pose(0, 0.0)
		_events.clear()
		player.play_profile(index, true)
		var frames: int = ceili(float(profile["seconds"]) * 60.0) + 1
		var maximum_foot_error: float = 0.0
		var rig_valid: bool = true
		var saw_paint: bool = false
		var saw_rig: bool = false
		for frame: int in frames:
			saw_paint = saw_paint or player.correction.visible
			saw_rig = saw_rig or rig.visible
			rig_valid = rig_valid and (rig.visible != player.correction.visible)
			if rig.visible:
				for key: String in rig.bones:
					var bone: Bone2D = rig.bones[key]
					rig_valid = rig_valid and bone.transform.is_finite() and bone.scale.is_equal_approx(Vector2.ONE)
				rig_valid = rig_valid and rig.weapon.pivot.global_position.distance_to(rig.bones["HandNear"].global_position) < 0.001
				rig_valid = rig_valid and absf(rig.weapon.tip.global_position.distance_to(rig.weapon.global_position) - blade_length) < 0.001
				var pose: Dictionary = player.get("_last_pose")
				maximum_foot_error = maxf(maximum_foot_error, rig.foot_error("Near", pose["root"] + pose["near"]))
				maximum_foot_error = maxf(maximum_foot_error, rig.foot_error("Far", pose["root"] + pose["far"]))
			if not _directory.is_empty() and OS.get_cmdline_user_args().has("motion"):
				_lab._update_status()
				await _capture("%s_%03d" % [profile["id"], frame])
			# In visible capture the lab has been paused by _capture().
			player.playing = player.clock < float(profile["seconds"])
			player.advance(1.0 / 60.0)
		var expected: Array[String] = []
		for event: Array in profile.get("events", []):
			expected.append(event[1])
		_check(_events == expected and not player.blade_window_open and not player.playing,
			"Ordered events and closed window for " + profile["id"])
		_check(rig_valid and (saw_paint if profile.has("paint") else saw_rig) and maximum_foot_error < 0.3,
			"%s | exclusive surface, stable grip and scale, max foot error %.4f px" % [profile["id"], maximum_foot_error])
	_verify_transitions(player, identifiers)
	player.inspect_pose(0, 0.0)
	var grip_pose: Dictionary = player.get("_last_pose").duplicate(true)
	grip_pose["angles"] = {"ArmNear": -55.0}
	grip_pose["offhand"] = 1.0
	grip_pose["depth"] = -8.0
	rig.apply_pose(grip_pose)
	_check(rig.offhand_reach_error < 0.05 and rig.layers["blade"].z_index == 23,
		"Reachable offhand locks to the grip and explicit weapon depth takes effect")
	_verify_lab_controls(identifiers)
	if not _directory.is_empty():
		await RenderingServer.frame_post_draw
		_verify_rendered_neutral()
	print("Raezen foundation structural failures: ", _errors)
	quit(int(_errors != 0))


func _capture(name: String) -> void:
	_lab.player.playing = false
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(_directory.path_join(name + ".png"))
	if result != OK:
		_check(false, "Capture failed: " + name)


func _verify_rendered_neutral() -> void:
	var reference: Image = _lab.original_stage.get_texture().get_image()
	var reconstructed: Image = _lab.hybrid_stage.get_texture().get_image()
	if OS.get_cmdline_user_args().has("diagnostics"):
		reference.save_png(_directory.path_join("imported_render.png"))
		reconstructed.save_png(_directory.path_join("rig_render.png"))
		_lab.source.get_frame_texture(&"idle", 0).get_image().save_png(_directory.path_join("imported_texture.png"))
	var max_delta: float = 0.0
	var different: int = 0
	for y: int in reference.get_height():
		for x: int in reference.get_width():
			var a: Color = reference.get_pixel(x, y)
			var b: Color = reconstructed.get_pixel(x, y)
			if a != b:
				different += 1
				max_delta = maxf(max_delta, maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), maxf(absf(a.b - b.b), absf(a.a - b.a))))
	_check(max_delta <= 1.01 / 255.0, "Native neutral comparison: %d differing pixels, max channel %.2f/255" % [different, max_delta * 255.0])


func _validate_profile(profile: Dictionary, player: Motion) -> void:
	var valid: bool = profile["state"] in Motion.STATES and float(profile["seconds"]) > 0.0
	valid = valid and float(profile["sample"]) >= 0.0 and float(profile["sample"]) <= 1.0
	var previous: float = -1.0
	var window: bool = false
	for event: Array in profile.get("events", []):
		var time: float = float(event[0])
		valid = valid and time >= previous and time >= 0.0 and time <= 1.0 and event[1] in Motion.EVENTS
		previous = time
		if event[1] == "blade_window_on":
			valid = valid and not window
			window = true
		elif event[1] == "blade_window_off":
			valid = valid and window
			window = false
	valid = valid and not window
	var paint: Dictionary = profile.get("paint", {})
	if not paint.is_empty():
		var clip: StringName = StringName(paint["clip"])
		var start: float = float(paint["start"])
		var end: float = float(paint["end"])
		valid = valid and player.source.has_animation(clip) and 0.0 <= start and start < end and end <= 1.0
		for frame: float in paint.get("frames", []):
			valid = valid and int(frame) >= 0 and int(frame) < player.source.get_frame_count(clip)
	var keys: Array = profile.get("keys", [])
	if not keys.is_empty():
		valid = valid and keys[0]["t"] == 0.0 and keys.back()["t"] == 1.0
	previous = -1.0
	for key: Dictionary in keys:
		var time: float = float(key["t"])
		valid = valid and time > previous
		previous = time
		for joint: String in key.get("angles", {}):
			valid = valid and player.rig.bones.has(joint)
	_check(valid, "Valid state, references, tracks and markers for " + profile["id"])


func _verify_transitions(player: Motion, identifiers: Dictionary) -> void:
	player.play_profile(identifiers["horizontal"], true)
	player.advance(0.4)
	_check(player.blade_window_open and not player.play_profile(identifiers["ready"]), "Active sword window rejects ordinary interruption")
	_check(player.play_profile(identifiers["hit"]) and not player.blade_window_open, "Hit interrupts safely and closes the sword window")
	player.play_profile(identifiers["jump"], true)
	player.advance(0.15)
	_check(not player.play_profile(identifiers["landing"]), "Early landing cannot interrupt takeoff")
	player.advance(0.5)
	_check(player.play_profile(identifiers["landing"]), "Landing transition is available late in flight")


func _verify_lab_controls(identifiers: Dictionary) -> void:
	var player: Motion = _lab.player
	var guard_index: int = identifiers["guard"]
	_lab.selected.select(guard_index)
	_lab.selected.item_selected.emit(guard_index)
	_check(player.correction.visible and not player.playing, "Pose selector opens the painted guard for inspection")
	_lab.scrub.value = 0.25
	_check(is_equal_approx(player.progress(), 0.25), "Scrubber selects a stable normalized pose")
	_lab._speed(0.5)
	_lab._play()
	player.advance(0.2)
	_check(is_equal_approx(player.clock, 0.1), "Play uses the selected rate")
	_lab._pause()
	player.advance(0.2)
	_check(not player.playing and is_equal_approx(player.clock, 0.1), "Pause preserves the inspected playback time")
	_lab._reset()
	_check(_lab.selected.selected == 0 and player.rig.visible and not player.correction.visible
		and is_zero_approx(player.progress()) and not player.blade_window_open, "Reset restores exclusive neutral art")


func _record_event(event: String, _at: float) -> void:
	_events.append(event)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_errors += 1
		push_error(message)
