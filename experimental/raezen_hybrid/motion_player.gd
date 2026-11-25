extends Node
## One clock owns pose, correction surface and preview events. No combat logic.

signal event_fired(event: String, at_seconds: float)
signal finished

const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")
const PROFILES: String = "res://experimental/raezen_hybrid/motion_profiles.json"
const TRANSITIONS: String = "res://experimental/raezen_hybrid/transition_profiles.json"
const PAINT_REPAIRS: String = "res://experimental/raezen_hybrid/art/paint_repairs/"
const STATES: Array[String] = [
	"idle", "ready", "advance", "retreat", "jump", "landing", "dash", "evade",
	"guard", "light_attack", "heavy_attack", "sword_attack", "hit", "knockback",
	"stagger", "recovery", "void_step", "void_burst", "get_up",
]
const ATTACKS: Array[String] = ["light_attack", "heavy_attack", "sword_attack", "void_burst"]
const EVENTS: Array[String] = ["plant_near", "plant_far", "guard_on", "guard_off",
	"blade_window_on", "blade_window_off", "contact", "recovery", "takeoff", "land",
	"drive", "charge", "release_ready", "grip_lock", "grip_release"]
const VECTORS: Array[String] = ["root", "pelvis", "near", "far"]
const SCALARS: Array[String] = ["offhand", "underlay"]
const CLOTH_JOINTS: Array[String] = ["Hair", "HairTip", "Scarf", "ScarfTip", "Coat"]
const REST_BOOT_CONTACT_X: Vector2 = Vector2(179.0, 330.0)

var rig: Rig
var correction: Sprite2D
var source: SpriteFrames
var profiles: Array = []
var active: Dictionary = {}
var clock: float = 0.0
var playing: bool = false
var speed: float = 1.0
var blade_window_open: bool = false
var last_event: String = ""
var source_mode: bool = false
var source_frame: int = -1
var source_slot: int = -1
var world_x: float = 0.0
var paint_shift_x: float = 0.0
var paint_origin_x: float = 0.0
var transitions: Array = []
var queued_profile: int = -1
var _last_pose: Dictionary = {}
var _blend_from: Dictionary = {}
var _transition: Dictionary = {}
var _transition_elapsed: float = 0.0
var _preview_ease: float = 0.0
var _leading: bool = false
var _in_playback: bool = false
var _outgoing_paint: Texture2D
var _outgoing_shift: float = 0.0
var _outgoing_origin: float = 0.0
var _outgoing_raised: bool = false
var _surface_from: Dictionary = {}
var _stance_foot: String = ""
var _entry_shift: float = 0.0
var _event_cursor: int = 0
var _repaired_paint: Dictionary[String, Texture2D] = {}


func configure(body_rig: Rig, painted: Sprite2D, original: SpriteFrames) -> void:
	rig = body_rig
	correction = painted
	source = original
	profiles = JSON.parse_string(FileAccess.get_file_as_string(PROFILES))
	transitions = JSON.parse_string(FileAccess.get_file_as_string(TRANSITIONS))
	for profile: Dictionary in profiles:
		var paint: Dictionary = profile.get("paint", {})
		for frame: int in paint.get("restored_frames", []):
			var path: String = PAINT_REPAIRS + "%s_%02d.png" % [paint["clip"], frame]
			if not _repaired_paint.has(path):
				_repaired_paint[path] = Rig.load_pixels(path)
	inspect_pose(0, 0.0)


func inspect_pose(index: int, progress: float) -> void:
	playing = false
	_in_playback = false
	active = profiles[index]
	clock = clampf(progress, 0.0, 1.0) * float(active["seconds"])
	_clear_transition()
	world_x = 0.0
	_event_cursor = 0
	blade_window_open = false
	last_event = ""
	_render()


func play_profile(index: int, force: bool = false) -> bool:
	var next: Dictionary = profiles[index]
	var rule: Dictionary = {}
	if force:
		world_x = 0.0
	else:
		if not can_transition(next["state"]):
			return false
		rule = transition_for(active["state"], next["state"])
		if bool(rule.get("finish_source", false)) and _in_playback and progress() < 1.0:
			queued_profile = index
			return true
	var outgoing: Dictionary = _last_pose.duplicate(true) if rig.visible else {}
	var surface: Texture2D = correction.texture if correction.visible else null
	var surface_shift: float = paint_shift_x
	var surface_origin: float = paint_origin_x
	var was_raised: bool = source_frame > 0
	var previous_id: String = active["id"]
	_clear_transition()
	if force:
		_preview_ease = float(next.get("preview_ease", 0.0))
	if not rule.is_empty():
		_transition = rule
		var mode: String = rule["paint"]
		_leading = (mode in ["guard_release", "paint_exit"] and surface != null) or (mode == "rig_entry" and not outgoing.is_empty())
		if surface != null:
			_outgoing_paint = surface
			_outgoing_shift = surface_shift
			_outgoing_origin = surface_origin
			_outgoing_raised = was_raised
			var source_poses: Dictionary = rule.get("source_poses", {})
			_surface_from = source_poses.get(previous_id, rule.get("settle_pose", {}))
		if not outgoing.is_empty():
			var origin: Vector2 = outgoing["root"]
			if rule["root"] == "carry_x":
				world_x += origin.x
				outgoing["root"] = Vector2(0.0, origin.y)
			if mode in ["none", "rig_entry"]:
				_blend_from = outgoing
				_set_stance_foot(outgoing, next, rule)
	active = next
	clock = 0.0
	blade_window_open = false
	last_event = ""
	_event_cursor = 0
	playing = true
	_in_playback = true
	if _leading:
		_render_lead()
	else:
		_emit_events()
		_render()
	return true


func can_transition(destination: String) -> bool:
	var rule: Dictionary = transition_for(active["state"], destination)
	if rule.is_empty():
		return false
	if _in_playback and rule.has("after_event"):
		for event: Array in active.get("events", []):
			if event[1] == rule["after_event"] and progress() < float(event[0]):
				return false
	if destination in ["hit", "knockback"]:
		return true
	if _leading:
		return bool(_transition["interruptible"])
	if not _in_playback:
		return true
	var current: String = active["state"]
	if current == "jump":
		return destination == "landing" and progress() >= float(active.get("interrupt_after", 0.75))
	if current == "get_up":
		return false
	if current in ATTACKS or current in ["dash", "evade", "void_step", "knockback", "stagger"]:
		return not blade_window_open and progress() >= float(active.get("interrupt_after", 0.78))
	return true


func transition_for(from: String, to: String) -> Dictionary:
	for rule: Dictionary in transitions:
		if from in rule["from"] and to in rule["to"]:
			return rule
	return {}


func transition_fraction() -> float:
	if _transition.is_empty() or is_zero_approx(float(_transition["seconds"])):
		return 1.0
	return clampf(_transition_elapsed / float(_transition["seconds"]), 0.0, 1.0)


func step_source(index: int, direction: int) -> void:
	var profile: Dictionary = profiles[index]
	var paint: Dictionary = profile.get("paint", {})
	var count: int = ceili(float(profile["seconds"]) * 60.0)
	if not paint.is_empty():
		var order: Array = paint.get("frames", [])
		count = source.get_frame_count(StringName(paint["clip"])) if order.is_empty() else order.size()
	var start: float = float(paint.get("start", 0.0))
	var end: float = float(paint.get("end", 1.0))
	var slot: int = floori(inverse_lerp(start, end, progress()) * count) if active == profile else -1
	slot = clampi(slot + direction, 0, count - 1)
	inspect_pose(index, lerpf(start, end, (slot + 0.5) / count))


func _clear_transition() -> void:
	_blend_from.clear()
	_transition = {}
	_transition_elapsed = 0.0
	_preview_ease = 0.0
	_leading = false
	_outgoing_paint = null
	_outgoing_raised = false
	_surface_from = {}
	_stance_foot = ""
	_entry_shift = 0.0
	queued_profile = -1


func advance(delta: float) -> void:
	if not playing:
		return
	var dt: float = maxf(delta, 0.0) * speed
	if _leading:
		var remaining: float = maxf(0.0, float(_transition["seconds"]) - _transition_elapsed)
		var consumed: float = minf(dt, remaining)
		_transition_elapsed += consumed
		if dt < remaining:
			_render_lead()
			return
		dt -= consumed
		_leading = false
		_blend_from.clear()
	if not _transition.is_empty():
		_transition_elapsed = minf(float(_transition["seconds"]), _transition_elapsed + dt)
	var total: float = float(active["seconds"])
	var overflow: float = maxf(0.0, dt - (total - clock))
	clock = minf(total, clock + dt)
	if is_equal_approx(clock, total):
		clock = total
	_emit_events()
	_render()
	if clock >= total:
		blade_window_open = false
		playing = false
		_in_playback = false
		finished.emit()
		if queued_profile >= 0:
			var next: int = queued_profile
			queued_profile = -1
			if play_profile(next) and overflow > 0.0:
				advance(overflow / speed)


func progress() -> float:
	return clock / float(active["seconds"])


func _render_lead() -> void:
	source_frame = -1
	source_slot = -1
	paint_shift_x = 0.0
	paint_origin_x = 0.0
	if _transition["paint"] in ["guard_release", "paint_exit"]:
		_render_painted_lead()
	elif not _blend_from.is_empty():
		var entry: Dictionary = _expand(_transition.get("entry_pose", active.get("entry_pose", {})))
		var pose: Dictionary = _blend_pose(_blend_from, entry)
		_apply_rig(pose)


func _render_painted_lead() -> void:
	var phase: float = transition_fraction()
	var settle_at: float = float(_transition.get("settle_at", 1.0))
	if phase >= settle_at and not _surface_from.is_empty():
		var entry: Dictionary = _expand(active.get("entry_pose", active.get("keys", [{}])[0]))
		var fraction: float = inverse_lerp(settle_at, 1.0, phase)
		_apply_rig(_blend_pose(_expand(_surface_from), entry, fraction))
		return
	correction.texture = _outgoing_paint
	paint_shift_x = _outgoing_shift
	paint_origin_x = _outgoing_origin
	for key: Dictionary in _transition.get("keys", []):
		if phase >= float(key["at"]) and (not key.get("raised", false) or _outgoing_raised):
			correction.texture = source.get_frame_texture(StringName(key["clip"]), int(key["frame"]))
			paint_shift_x = float(key.get("x", 0.0))
			paint_origin_x = 0.0
	correction.show()
	rig.hide()


func _set_stance_foot(pose: Dictionary, next: Dictionary, rule: Dictionary) -> void:
	if rule["feet"] != "stance":
		return
	var near: Vector2 = pose["near"]
	var far: Vector2 = pose["far"]
	var root: Vector2 = pose["root"]
	_stance_foot = "near" if absf(near.y + root.y) <= absf(far.y + root.y) else "far"
	var boots: Array = rule.get("first_boots", {}).get(next["id"], [])
	if not boots.is_empty():
		var desired_x: float = (REST_BOOT_CONTACT_X.x + near.x) if _stance_foot == "near" else (REST_BOOT_CONTACT_X.y + far.x)
		var painted_x: float = float(boots[0 if _stance_foot == "near" else 1])
		_entry_shift = clampf(desired_x - painted_x, -15.0, 15.0)


func _emit_events() -> void:
	var events: Array = active.get("events", [])
	while _event_cursor < events.size() and float(events[_event_cursor][0]) <= progress() + 0.000000001:
		var event: Array = events[_event_cursor]
		last_event = event[1]
		if last_event == "blade_window_on":
			blade_window_open = true
		elif last_event == "blade_window_off":
			blade_window_open = false
		_event_cursor += 1
		event_fired.emit(last_event, float(event[0]) * float(active["seconds"]))


func _render() -> void:
	var u: float = progress()
	source_frame = -1
	source_slot = -1
	paint_shift_x = 0.0
	paint_origin_x = 0.0
	var paint: Dictionary = active.get("paint", {})
	if not paint.is_empty() and u >= float(paint["start"]) and u <= float(paint["end"]):
		var clip: StringName = StringName(paint["clip"])
		var normalized: float = inverse_lerp(float(paint["start"]), float(paint["end"]), u)
		var visual_keys: Array = paint.get("frames", [])
		var count: int = source.get_frame_count(clip) if visual_keys.is_empty() else visual_keys.size()
		var boundary_tolerance: float = 0.000000001 if paint.has("match_x") else 0.0
		var key: int = mini(floori(normalized * count + boundary_tolerance), count - 1)
		var frame: int = key if visual_keys.is_empty() else int(visual_keys[key])
		source_frame = frame
		source_slot = key
		if not source_mode:
			paint_shift_x = _paint_registration(paint, key, normalized * count - key)
		if float(frame + 1) in paint.get("restored_frames", []):
			var path: String = PAINT_REPAIRS + "%s_%02d.png" % [clip, frame + 1]
			correction.texture = _repaired_paint[path]
		else:
			correction.texture = source.get_frame_texture(clip, frame)
		if correction.texture.get_width() > 512:
			paint_origin_x = float(paint.get("restored_canvas_left", 0.0))
		var register_time: float = float(_transition.get("register_seconds", 0.0))
		if register_time > 0.0:
			paint_shift_x += _entry_shift * (1.0 - smoothstep(0.0, register_time, clock))
		correction.show()
		rig.hide()
		return
	var keys: Array = active.get("keys", [{"t": 0.0}, {"t": 1.0}])
	var segment: int = 0
	while segment < keys.size() - 2 and u > float(keys[segment + 1]["t"]):
		segment += 1
	var first: Dictionary = keys[segment]
	var second: Dictionary = keys[segment + 1]
	var weight: float = smoothstep(float(first["t"]), float(second["t"]), u)
	var pose: Dictionary = _mix(_expand(first), _expand(second), weight)
	if not source_mode and keys.size() > 2:
		var previous_x: float = pose["root"].x
		var x: float = _root_axis(keys, segment, u, 0)
		pose["root"] = Vector2(x, _root_axis(keys, segment, u, 1))
		# Preserve the existing authored world-space boot trajectories.
		pose["near"].x += previous_x - x
		pose["far"].x += previous_x - x
	var cloth: float = float(active.get("cloth", 0.0)) * sin(PI * u)
	pose["angles"]["Hair"] = cloth * sin(TAU * u)
	pose["angles"]["HairTip"] = 1.4 * cloth * sin(TAU * u - 0.55)
	pose["angles"]["Scarf"] = cloth * sin(TAU * u - 0.75)
	pose["angles"]["ScarfTip"] = 1.5 * cloth * sin(TAU * u - 1.20)
	pose["angles"]["Coat"] = cloth * sin(TAU * u - 1.10) * 0.6
	if not _blend_from.is_empty() and transition_fraction() < 1.0:
		pose = _blend_pose(_blend_from, pose)
	elif _preview_ease > 0.0 and clock < _preview_ease:
		pose = _mix(_expand({}), pose, smoothstep(0.0, _preview_ease, clock))
	_apply_rig(pose)


func _apply_rig(pose: Dictionary) -> void:
	pose["solve_feet"] = pose["pelvis"] != Vector2.ZERO or pose["near"] != Vector2.ZERO or pose["far"] != Vector2.ZERO
	_last_pose = pose
	rig.apply_pose(pose)
	rig.show()
	correction.hide()


func present_ground_step(key: Dictionary, from: Dictionary, settle: float) -> void:
	var pose: Dictionary = _expand(key)
	if settle < 1.0:
		var near_contact: Vector2 = pose["near"]
		var far_contact: Vector2 = pose["far"]
		pose = _mix(from, pose, smoothstep(0.0, 1.0, settle))
		pose["near"] = near_contact
		pose["far"] = far_contact
	rig.fit_ground_contacts(pose)
	_apply_rig(pose)


func _blend_pose(from: Dictionary, to: Dictionary, fraction: float = -1.0) -> Dictionary:
	if fraction < 0.0:
		fraction = transition_fraction()
	var weight: float = fraction
	match _transition["curve"]:
		"smooth":
			weight = smoothstep(0.0, 1.0, fraction)
		"smoother":
			weight = fraction * fraction * fraction * (fraction * (6.0 * fraction - 15.0) + 10.0)
		"ease_out":
			weight = 1.0 - (1.0 - fraction) * (1.0 - fraction)
	var pose: Dictionary = _mix(from, to, weight)
	var foot_policy: String = _transition["feet"]
	if foot_policy in ["world", "air_to_floor", "stance"]:
		for foot: String in ["near", "far"]:
			var source_contact: Vector2 = from["root"] + from[foot]
			var target_contact: Vector2 = to["root"] + to[foot]
			var contact: Vector2 = source_contact if foot == _stance_foot else source_contact.lerp(target_contact, weight)
			pose[foot] = contact - pose["root"]
	var cloth_weight: float = _damped_fraction(fraction) if _transition.get("secondary", "damped") == "damped" else weight
	for joint: String in CLOTH_JOINTS:
		pose["angles"][joint] = _angle(from["angles"].get(joint, 0.0), to["angles"].get(joint, 0.0), cloth_weight)
	return pose


static func _damped_fraction(fraction: float) -> float:
	return (1.0 - (1.0 + 5.0 * fraction) * exp(-5.0 * fraction)) / (1.0 - 6.0 * exp(-5.0))


static func _root_axis(keys: Array, segment: int, u: float, axis: int) -> float:
	var a: float = float(keys[segment].get("root", [0, 0])[axis])
	var b: float = float(keys[segment + 1].get("root", [0, 0])[axis])
	var start: float = float(keys[segment]["t"])
	var span: float = float(keys[segment + 1]["t"]) - start
	var x: float = (u - start) / span
	var s: float = (b - a) / span
	var va: float = 0.0
	var vb: float = 0.0
	if segment > 0:
		var before: Dictionary = keys[segment - 1]
		va = _continuous_slope(s, (a - float(before.get("root", [0, 0])[axis])) / (start - float(before["t"])))
	if segment + 2 < keys.size():
		var after: Dictionary = keys[segment + 2]
		vb = _continuous_slope(s, (float(after.get("root", [0, 0])[axis]) - b) / (float(after["t"]) - start - span))
	return lerpf(a, b, x * x * (3.0 - 2.0 * x)) + span * x * (1.0 - x) * ((1.0 - x) * va - x * vb)


static func _continuous_slope(a: float, b: float) -> float:
	return 2.0 * a * b / (a + b) if a * b > 0.0 else 0.0


static func _paint_registration(paint: Dictionary, slot: int, fraction: float) -> float:
	var weights: Dictionary = paint.get("match_x", {})
	var edge: int = slot - 1 if fraction < 0.5 else slot
	var direction: float = -1.0 if fraction < 0.5 else 1.0
	var overlap: float = smoothstep(0.0, 0.5, absf(fraction - 0.5))
	return direction * overlap * float(weights.get(str(edge + 1), 0.0)) * 0.5


static func _expand(key: Dictionary) -> Dictionary:
	var result: Dictionary = {"angles": key.get("angles", {})}
	for property: String in VECTORS:
		result[property] = Rig.coordinates(key.get(property, [0, 0]))
	for property: String in SCALARS:
		result[property] = float(key.get(property, 0.0))
	result["blade"] = float(key.get("blade", 0.0))
	result["depth"] = float(key.get("depth", 0.0))
	return result


static func _mix(a: Dictionary, b: Dictionary, weight: float) -> Dictionary:
	var result: Dictionary = {"angles": {}}
	for property: String in VECTORS:
		var value: Vector2 = a[property]
		result[property] = value.lerp(b[property], weight)
	for property: String in SCALARS:
		result[property] = lerpf(a[property], b[property], weight)
	result["blade"] = _angle(a["blade"], b["blade"], weight)
	result["depth"] = a["depth"] if weight < 0.5 else b["depth"]
	var names: Array = a["angles"].keys()
	for joint: String in b["angles"]:
		if joint not in names:
			names.append(joint)
	for joint: String in names:
		result["angles"][joint] = _angle(a["angles"].get(joint, 0.0), b["angles"].get(joint, 0.0), weight)
	return result


static func _angle(from: float, to: float, weight: float) -> float:
	return from + wrapf(to - from, -180.0, 180.0) * weight if absf(to - from) > 180.0 else lerpf(from, to, weight)
