extends Node
## One clock owns pose, correction surface and preview events. No combat logic.

signal event_fired(event: String, at_seconds: float)
signal finished

const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")
const PROFILES: String = "res://experimental/raezen_hybrid/motion_profiles.json"
const STATES: Array[String] = [
	"idle", "ready", "advance", "retreat", "jump", "landing", "dash", "evade",
	"guard", "light_attack", "heavy_attack", "sword_attack", "hit", "knockback",
	"stagger", "recovery", "void_step", "void_burst",
]
const ATTACKS: Array[String] = ["light_attack", "heavy_attack", "sword_attack", "void_burst"]
const EVENTS: Array[String] = ["plant_near", "plant_far", "guard_on", "guard_off",
	"blade_window_on", "blade_window_off", "contact", "recovery", "takeoff", "land",
	"drive", "charge", "release_ready", "grip_lock", "grip_release"]
const BLEND_SECONDS: float = 0.12
const VECTORS: Array[String] = ["root", "pelvis", "near", "far"]
const SCALARS: Array[String] = ["blade", "depth", "offhand", "underlay"]

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
var _last_pose: Dictionary = {}
var _blend_from: Dictionary = {}
var _event_cursor: int = 0


func configure(body_rig: Rig, painted: Sprite2D, original: SpriteFrames) -> void:
	rig = body_rig
	correction = painted
	source = original
	profiles = JSON.parse_string(FileAccess.get_file_as_string(PROFILES))
	inspect_pose(0, 0.0)


func inspect_pose(index: int, progress: float) -> void:
	playing = false
	active = profiles[index]
	clock = clampf(progress, 0.0, 1.0) * float(active["seconds"])
	_blend_from.clear()
	_event_cursor = 0
	blade_window_open = false
	last_event = ""
	_render()


func play_profile(index: int, force: bool = false) -> bool:
	var next: Dictionary = profiles[index]
	if playing and not force and not can_transition(next["state"]):
		return false
	_blend_from = _last_pose.duplicate(true) if rig.visible and not next.has("paint") else {}
	active = next
	clock = 0.0
	blade_window_open = false
	last_event = ""
	_event_cursor = 0
	playing = true
	_emit_events()
	_render()
	return true


func can_transition(destination: String) -> bool:
	if destination not in STATES:
		return false
	if not playing or destination in ["hit", "knockback"]:
		return true
	var current: String = active["state"]
	if current == "jump":
		return destination == "landing" and progress() >= float(active.get("interrupt_after", 0.75))
	if current in ATTACKS or current in ["dash", "evade", "void_step", "knockback", "stagger"]:
		return not blade_window_open and progress() >= float(active.get("interrupt_after", 0.78))
	return true


func advance(delta: float) -> void:
	if not playing:
		return
	var total: float = float(active["seconds"])
	clock = minf(total, clock + maxf(delta, 0.0) * speed)
	_emit_events()
	_render()
	if clock >= total:
		blade_window_open = false
		playing = false
		finished.emit()


func progress() -> float:
	return clock / float(active["seconds"])


func _emit_events() -> void:
	var events: Array = active.get("events", [])
	while _event_cursor < events.size() and float(events[_event_cursor][0]) <= progress():
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
	var paint: Dictionary = active.get("paint", {})
	if not paint.is_empty() and u >= float(paint["start"]) and u <= float(paint["end"]):
		var clip: StringName = StringName(paint["clip"])
		var normalized: float = inverse_lerp(float(paint["start"]), float(paint["end"]), u)
		var visual_keys: Array = paint.get("frames", [])
		var count: int = source.get_frame_count(clip) if visual_keys.is_empty() else visual_keys.size()
		var key: int = mini(floori(normalized * count), count - 1)
		correction.texture = source.get_frame_texture(clip, key if visual_keys.is_empty() else int(visual_keys[key]))
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
	var cloth: float = float(active.get("cloth", 0.0)) * sin(PI * u)
	pose["angles"]["Hair"] = cloth * sin(TAU * u)
	pose["angles"]["HairTip"] = 1.4 * cloth * sin(TAU * u - 0.55)
	pose["angles"]["Scarf"] = cloth * sin(TAU * u - 0.75)
	pose["angles"]["ScarfTip"] = 1.5 * cloth * sin(TAU * u - 1.20)
	pose["angles"]["Coat"] = cloth * sin(TAU * u - 1.10) * 0.6
	if not _blend_from.is_empty():
		pose = _mix(_blend_from, pose, smoothstep(0.0, BLEND_SECONDS, clock))
	pose["solve_feet"] = pose["pelvis"] != Vector2.ZERO or pose["near"] != Vector2.ZERO or pose["far"] != Vector2.ZERO
	_last_pose = pose
	rig.apply_pose(pose)
	rig.show()
	correction.hide()


static func _expand(key: Dictionary) -> Dictionary:
	var result: Dictionary = {"angles": key.get("angles", {})}
	for property: String in VECTORS:
		result[property] = Rig.coordinates(key.get(property, [0, 0]))
	for property: String in SCALARS:
		result[property] = float(key.get(property, 0.0))
	return result


static func _mix(a: Dictionary, b: Dictionary, weight: float) -> Dictionary:
	var result: Dictionary = {"angles": {}}
	for property: String in VECTORS:
		var value: Vector2 = a[property]
		result[property] = value.lerp(b[property], weight)
	for property: String in SCALARS:
		result[property] = lerpf(a[property], b[property], weight)
	var names: Array = a["angles"].keys()
	for joint: String in b["angles"]:
		if joint not in names:
			names.append(joint)
	for joint: String in names:
		result["angles"][joint] = lerpf(a["angles"].get(joint, 0.0), b["angles"].get(joint, 0.0), weight)
	return result
