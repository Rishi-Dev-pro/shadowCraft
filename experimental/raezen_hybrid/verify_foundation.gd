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
	_check(player.profiles.size() == 23, "All 18 baseline and five new motion profiles are present")
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
		_verify_paint_repairs(index, profile, player)
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
	await _verify_temporal_profiles(identifiers)
	_verify_combat_handoffs(identifiers)
	await _verify_void_bursts(identifiers)
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


func _verify_paint_repairs(index: int, profile: Dictionary, player: Motion) -> void:
	var paint: Dictionary = profile.get("paint", {})
	var restored: Array = paint.get("restored_frames", [])
	if restored.is_empty():
		return
	var clip: StringName = StringName(paint["clip"])
	var keys: Array = paint.get("frames", [])
	var count: int = keys.size() if not keys.is_empty() else player.source.get_frame_count(clip)
	for number: int in restored:
		var slot: int = number - 1
		if not keys.is_empty():
			slot = -1
			for candidate: int in keys.size():
				if int(keys[candidate]) == number - 1:
					slot = candidate
					break
		var path: String = Motion.PAINT_REPAIRS + "%s_%02d.png" % [clip, number]
		var valid: bool = slot >= 0 and slot < count and FileAccess.file_exists(path)
		if valid:
			var sample: float = lerpf(paint["start"], paint["end"], (slot + 0.5) / count)
			player.inspect_pose(index, sample)
			_lab._update_status()
			var image: Image = player.correction.texture.get_image()
			valid = player.correction.visible and not player.rig.visible and image.get_height() == 512
			valid = valid and player.correction.texture != player.source.get_frame_texture(clip, number - 1)
			valid = valid and image.get_width() <= _lab.hybrid_stage.size.x
			if clip == &"knockback":
				for y: int in range(int(Lab.GROUND), image.get_height()):
					for x: int in image.get_width():
						valid = valid and image.get_pixel(x, y).a < 48.0 / 255.0
			elif image.get_width() == 512:
				var original: Image = player.source.get_frame_texture(clip, number - 1).get_image()
				var repaired_left: int = _solid_left_edge(image)
				valid = valid and repaired_left > 0 and repaired_left < _solid_left_edge(original)
			else:
				var bounds: Rect2i = image.get_used_rect()
				valid = valid and bounds.has_area() and bounds.position.x > 0 and bounds.end.x < image.get_width()
		_check(valid, "%s frame %02d uses bounded, registered repair artwork" % [clip, number])


func _solid_left_edge(image: Image) -> int:
	var bounds: Rect2i = image.get_used_rect()
	for x: int in range(bounds.position.x, bounds.end.x):
		for y: int in range(bounds.position.y, bounds.end.y):
			if image.get_pixel(x, y).a >= 48.0 / 255.0:
				return x
	return image.get_width()


func _verify_lab_controls(identifiers: Dictionary) -> void:
	var player: Motion = _lab.player
	player.source_mode = true
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
	player.source_mode = false
	player.speed = 1.0


func _verify_void_bursts(identifiers: Dictionary) -> void:
	var player: Motion = _lab.player
	player.source_mode = true
	var reference: Sprite2D = _lab.original_stage.get_child(0) as Sprite2D
	var capture: bool = not _directory.is_empty() and OS.get_cmdline_user_args().has("burst_comparison")
	var expected_clips: Dictionary[String, StringName] = {
		"void_burst": &"void_burst",
		"void_burst_main": &"phase2_void_burst",
	}
	var expected_titles: Dictionary[String, String] = {
		"void_burst": "Void Burst — Preparation / Charge",
		"void_burst_main": "Void Burst — Main Signature Attack",
	}
	for id: String in expected_clips:
		var index: int = identifiers[id]
		var clip: StringName = expected_clips[id]
		var count: int = player.source.get_frame_count(clip)
		var fps: float = player.source.get_animation_speed(clip)
		_lab.selected.select(index)
		_lab.selected.item_selected.emit(index)
		var paint: Dictionary = player.active.get("paint", {})
		if paint.is_empty():
			_check(false, "%s selection must display its painted sequence in source mode" % id)
			continue
		var duration: float = 0.0
		for frame: int in count:
			duration += player.source.get_frame_duration(clip, frame) / fps
		_check(StringName(paint["clip"]) == clip and not paint.has("frames")
			and _lab.selected.get_item_text(index) == expected_titles[id]
			and is_equal_approx(float(player.active["seconds"]), duration),
			"%s selects its full original clip at the authored duration" % id)
		_lab._speed(0.5)
		_lab._play()
		player.advance(0.2)
		_lab._pause()
		_check(is_equal_approx(player.clock, 0.1) and not player.playing, id + " supports speed and pause")
		var frames_match: bool = count == 20
		for frame: int in count:
			_lab.scrub.value = (frame + 0.5) / count
			var original: Texture2D = player.source.get_frame_texture(clip, frame)
			var expected: Texture2D = original
			if float(frame + 1) in paint.get("restored_frames", []):
				var path: String = Motion.PAINT_REPAIRS + "%s_%02d.png" % [clip, frame + 1]
				expected = player._repaired_paint.get(path)
			frames_match = frames_match and expected != null and expected == player.correction.texture
			frames_match = frames_match and player.correction.visible and not player.rig.visible
			if capture:
				reference.texture = original
				await RenderingServer.frame_post_draw
				var source_path: String = _directory.path_join("%s_source_%02d.png" % [id, frame + 1])
				var lab_path: String = _directory.path_join("%s_lab_%02d.png" % [id, frame + 1])
				var source_error: Error = _lab.original_stage.get_texture().get_image().save_png(source_path)
				var lab_error: Error = _lab.hybrid_stage.get_texture().get_image().save_png(lab_path)
				frames_match = frames_match and source_error == OK and lab_error == OK
		_check(frames_match, "%s scrubs all 20 distinct source slots without rig or texture substitution" % id)
	reference.texture = player.source.get_frame_texture(&"idle", 0)
	player.source_mode = false
	_lab._speed(1.0)
	_lab._reset()
	_check(_lab.hybrid_stage.size.x == 512 and _lab._hybrid_display.offset == Vector2.ZERO
		and player.rig.visible, "Void Burst reset restores the original neutral viewport")


func _verify_temporal_profiles(ids: Dictionary) -> void:
	var player: Motion = _lab.player
	var representatives: Dictionary = {}
	for index: int in player.profiles.size():
		var state: String = player.profiles[index]["state"]
		if not representatives.has(state):
			representatives[state] = index
	representatives["recovery"] = ids["ready"]
	var valid_routes: int = 0
	var route_count: int = 0
	for rule: Dictionary in player.transitions:
		for origin: String in rule["from"]:
			for destination: String in rule["to"]:
				if origin == "recovery":
					continue
				route_count += 1
				player.inspect_pose(representatives[origin], 0.8 if origin == "jump" else 1.0)
				var source_x: float = player._last_pose["root"].x if player.rig.visible else 0.0
				var accepted: bool = player.play_profile(representatives[destination])
				var valid: bool = accepted and is_equal_approx(player.world_x, source_x)
				for sample: int in 12:
					player.advance(1.0 / 120.0)
					valid = valid and player.rig.visible != player.correction.visible
					if player.rig.visible:
						valid = valid and player.rig.weapon.position.distance_to(Vector2.ZERO) < 0.01
				valid_routes += int(valid)
	_check(valid_routes == route_count, "%d/%d configured preview routes preserve root and exclusive art" % [valid_routes, route_count])
	player.inspect_pose(ids["forward"], 1.0)
	var distance: float = player._last_pose["root"].x
	player.play_profile(ids["neutral"])
	player.advance(0.18)
	_check(is_equal_approx(player.world_x + player._last_pose["root"].x, distance),
		"Advance-to-idle preserves the full accumulated travel after blending")
	player.inspect_pose(ids["knockback"], 1.0)
	_check(not player.play_profile(ids["ready"]) and player.correction.visible, "Prone knockback holds its source ending")
	player.inspect_pose(ids["neutral"], 0.0)
	player.play_profile(ids["void_burst_main"])
	player.advance(0.04)
	_check(player.rig.visible and is_zero_approx(player.clock), "Signature pre-roll keeps time separate from the authored charge")
	_check(player.play_profile(ids["hit"]) and player.rig.visible and not player.blade_window_open,
		"An interrupted pre-roll releases its previous visual and event state")
	_check(absf(Motion._angle(179.0, -179.0, 0.5) - 180.0) < 0.001, "Rotations take the short path across 180°")
	var deterministic: bool = true
	for id: String in ["forward", "jump", "void_burst", "void_burst_main"]:
		var samples: Array[Vector4] = []
		for hz: int in [30, 60, 120]:
			player.play_profile(ids[id], true)
			for tick: int in hz / 2:
				player.advance(1.0 / hz)
			var position: Vector2 = player._last_pose["root"] if player.rig.visible else Vector2(player.source_frame, player.paint_shift_x)
			samples.append(Vector4(player.clock, position.x, position.y, float(player.blade_window_open)))
		deterministic = deterministic and samples[0].is_equal_approx(samples[1]) and samples[1].is_equal_approx(samples[2])
	_check(deterministic, "30, 60, and 120 Hz deltas agree on time, pose, and source key")
	var source_continuous: bool = true
	for id: String in ["void_burst", "void_burst_main"]:
		player.inspect_pose(ids[id], 0.0)
		player.step_source(ids[id], 1)
		source_continuous = source_continuous and player.source_frame == 1 and not player.playing
		player.step_source(ids[id], -1)
		source_continuous = source_continuous and player.source_frame == 0
	_check(source_continuous, "Source stepping visits adjacent original keys in both directions")
	if not _directory.is_empty() and OS.get_cmdline_user_args().has("transitions"):
		await _capture_transitions(ids)
	_lab._reset()


func _verify_combat_handoffs(ids: Dictionary) -> void:
	var player: Motion = _lab.player
	player.inspect_pose(ids["guard"], 0.8)
	var guard: Texture2D = player.correction.texture
	var accepted: bool = player.play_profile(ids["forward"])
	_check(accepted and player.correction.texture == guard and is_zero_approx(player.clock),
		"Guard release starts from the exact displayed guard")
	player.advance(0.04)
	_check(player.correction.texture == player.source.get_frame_texture(&"guard", 6)
		and not player.rig.visible, "Guard release lowers through the authored middle pose")
	player.advance(0.04)
	_check(player.correction.texture == player.source.get_frame_texture(&"guard_release", 0)
		and not player.rig.visible, "Guard release plays the authored final painted key")
	_check(player.play_profile(ids["hit"]) and player.rig.visible and not player.correction.visible,
		"Impact can interrupt the guard bridge with one visual owner")
	player.play_profile(ids["hit"], true)
	_check(not player.play_profile(ids["knockback"]), "Knockback cannot cancel the initial hit contact")
	player.advance(0.10)
	_check(player.play_profile(ids["knockback"]) and player.rig.visible and is_zero_approx(player.clock),
		"Hit enters the knockback pre-roll without replacing the displayed rig")
	player.advance(0.07)
	_check(player.correction.visible and player.source_frame == 0,
		"Knockback starts at its first floor-corrected source key")
	for move: String in ["forward", "backward"]:
		player.inspect_pose(ids[move], 0.32)
		var travel: float = player._last_pose["root"].x
		accepted = player.play_profile(ids["heavy"])
		var side: String = "Near" if player._stance_foot == "near" else "Far"
		var boot: Bone2D = player.rig.bones["Foot" + side]
		var contact: Vector2 = boot.global_position
		player.advance(0.05)
		_check(accepted and is_equal_approx(player.world_x, travel)
			and boot.global_position.distance_to(contact) < 0.01 and player.rig.visible,
			move + " holds the planted boot into the attack")
		player.advance(0.05)
		_check(player.source_frame == 0 and player.correction.visible, move + " keeps the attack anticipation")
	for attack: String in ["diagonal", "heavy", "void_burst", "void_burst_main"]:
		player.play_profile(ids[attack], true)
		var length: float = float(player.active["seconds"])
		player.advance(length * 0.45)
		_check(not player.play_profile(ids["guard"]), attack + " maintains the committed attack")
		player.advance(length * 0.38)
		accepted = player.play_profile(ids["guard"])
		_check(accepted and player.active["id"] == attack and player.queued_profile == ids["guard"],
			attack + " buffers guard without shortening authored recovery")
		player.advance(length * 0.17)
		_check(player.active["id"] == "guard" and player.queued_profile == -1
			and player.correction.visible and is_zero_approx(player.clock),
			attack + " holds its final painted surface at recovery handoff")
		player.advance(0.12)
		_check(player.active["id"] == "guard" and player.source_frame == 0,
			attack + " enters guard on its original first key")
	player.play_profile(ids["heavy"], true)
	player.advance(0.4)
	player.playing = false
	_check(not player.play_profile(ids["guard"]), "Pausing cannot bypass attack commitment")
	player.playing = true
	player.advance(0.35)
	player.play_profile(ids["guard"])
	_check(player.queued_profile == ids["guard"] and player.play_profile(ids["hit"])
		and player.queued_profile == -1, "An interrupting hit clears a buffered guard")
	player.inspect_pose(ids["forward"], 0.65)
	var origin: float = player._last_pose["root"].x
	player.play_profile(ids["diagonal"])
	player.advance(0.95)
	player.play_profile(ids["ready"])
	player.advance(0.8)
	player.play_profile(ids["backward"])
	player.advance(0.9)
	var next_origin: float = player.world_x + player._last_pose["root"].x
	_check(is_equal_approx(next_origin, origin - 22.0), "Repeated movement, attack and recovery preserve net travel")
	_lab._reset()


func _capture_transitions(ids: Dictionary) -> void:
	var cases: Array = [
		["neutral","ready"], ["neutral","forward"], ["forward","neutral"], ["forward","guard"],
		["guard","horizontal"], ["horizontal","ready"], ["ready","guard"], ["jump","landing"],
		["dash","ready"], ["hit","knockback"], ["void_step","forward"], ["void_step","diagonal"],
		["neutral","void_burst"], ["neutral","void_burst_main"],
	]
	for pair: Array in cases:
		var phase: float = 1.0
		if pair[0] == "jump":
			phase = 0.8
		elif pair[0] == "hit":
			phase = 0.35
		_lab.player.inspect_pose(ids[pair[0]], phase)
		_lab.selected.select(ids[pair[1]])
		_lab._update_status()
		await _capture("%s_to_%s_outgoing" % [pair[0], pair[1]])
		_lab.player.play_profile(ids[pair[1]])
		for index: int in 19:
			_lab._update_status()
			await _capture("%s_to_%s_%02d" % [pair[0], pair[1], index])
			_lab.player.playing = true
			_lab.player.advance(1.0 / 60.0)


func _record_event(event: String, _at: float) -> void:
	_events.append(event)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_errors += 1
		push_error(message)
