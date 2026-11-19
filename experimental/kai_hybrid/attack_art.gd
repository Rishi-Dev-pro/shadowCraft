extends RefCounted
## Drives the attack-only painted surface and its registered displacement maps.

const Motion = preload("res://experimental/kai_hybrid/attack_motion.gd")
const Rig = preload("res://experimental/kai_rig_test/kai_rig.gd")
const SURFACE = preload("res://experimental/kai_hybrid/attack_correction.gdshader")
const DIRECTORY: String = "res://experimental/kai_hybrid/attack_corrections/"
# These contacts change which limb occludes the body. Use the authored keys
# at the fastest part of the motion rather than warping overlapping contours.
const STEPPED: Array[Array] = [[1, 4], [5], [3]]

var _frames: Dictionary[int, Array] = {}
var _flows: Dictionary[int, Array] = {}
var _kind: int = -1
var _segment: int = -1
var _material: ShaderMaterial = ShaderMaterial.new()


func prepare(approved_heavy: Texture2D) -> void:
	_material.shader = SURFACE
	for kind: int in Motion.FAMILIES.size():
		_load(kind, Motion.KEYS[kind].size(), approved_heavy)


func display(sprite: Sprite2D, kind: Motion.Kind, time: float) -> Texture2D:
	var keys: Array = Motion.KEYS[kind]
	var frames: Array = _frames[kind]
	if _kind != kind:
		_kind = kind
		_segment = -1
	var next: int = 1
	while next < keys.size() - 1 and time >= keys[next]:
		next += 1
	var from: int = next - 1
	var stepped: bool = from in STEPPED[kind]
	if _segment != from:
		_segment = from
		_material.set_shader_parameter(&"source_pose", frames[from])
		_material.set_shader_parameter(&"destination_pose", frames[next])
		_material.set_shader_parameter(&"motion", _flows[kind][from])
		var guided: bool = kind == Motion.Kind.KICK and from >= 1 and from <= 5 and not stepped
		_material.set_shader_parameter(&"displacement_range", 224.0 if guided else 152.0)
	var local: float = clampf(inverse_lerp(keys[from], keys[next], time), 0.0, 1.0)
	if stepped:
		local = 0.0 if local < 0.5 else 1.0
	_material.set_shader_parameter(&"progress", local)
	sprite.texture = frames[0]
	sprite.material = _material
	return frames[next if local >= 0.5 else from]


func _load(kind: int, count: int, approved_heavy: Texture2D) -> void:
	var prefix: String = DIRECTORY + Motion.FAMILIES[kind]
	var anchor: Texture2D = Rig.load_approved_texture(prefix + "_0.png")
	var frames: Array[Texture2D] = [anchor]
	for index: int in range(1, count - 1):
		if kind == Motion.Kind.HEAVY and index == 4:
			frames.append(approved_heavy)
		elif kind == Motion.Kind.LIGHT and index == 4:
			frames.append(frames[3])
		elif kind == Motion.Kind.KICK and index == 5:
			frames.append(frames[1])
		else:
			frames.append(Rig.load_approved_texture("%s_%d.png" % [prefix, index]))
	frames.append(anchor)
	_frames[kind] = frames
	var flows: Array[Texture2D] = []
	for index: int in range(count - 1):
		flows.append(null if index in STEPPED[kind] else Rig.load_approved_texture("%s_flow_%d.png" % [prefix, index]))
	_flows[kind] = flows
