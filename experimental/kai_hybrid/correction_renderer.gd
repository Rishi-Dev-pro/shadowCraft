extends Sprite2D

const KaiRig = preload("res://experimental/kai_rig_test/kai_rig.gd")
const SURFACE = preload("res://experimental/kai_hybrid/pose_correction.gdshader")
const DIRECTORY: String = "res://experimental/kai_hybrid/corrections/"
const FAMILIES: Dictionary[int, String] = {2: "punch", 3: "crouch"}
const KNOTS: Dictionary[int, Array] = {2: [0.0, 0.34, 0.68, 1.0], 3: [0.0, 0.70, 1.0]}
# Helmet, upper torso, rear boot and front boot in the 512px registered canvas.
const CROUCH_ANCHORS: Array[Array] = [
	[Vector4(272, 107, 286, 151), Vector4(247, 200, 266, 230), Vector4(138, 480, 171, 480), Vector4(344, 479, 344, 481)],
	[Vector4(286, 151, 291, 190), Vector4(266, 230, 270, 266), Vector4(171, 480, 170, 480), Vector4(344, 481, 344, 481)],
]
# The two painted keys put the rear sole four and seven pixels below the rig sole.
const CROUCH_FLOOR_OFFSETS: Array[Vector2] = [Vector2(0, 4), Vector2(4, 7)]

var _art: Dictionary[int, Array] = {}
var _motion: Dictionary[int, Array] = {}
var _surface: ShaderMaterial = ShaderMaterial.new()
var _last_family: int = -1
var _last_segment: int = -1


func _ready() -> void:
	centered = false
	_surface.shader = SURFACE
	material = _surface
	for family: int in FAMILIES:
		var path: String = DIRECTORY + FAMILIES[family]
		_art[family] = []
		for index: int in range(KNOTS[family].size()):
			_art[family].append(KaiRig.load_approved_texture("%s_%d.png" % [path, index]))
		_motion[family] = []
		for index: int in range(KNOTS[family].size() - 1):
			_motion[family].append(KaiRig.load_approved_texture("%s_flow_%d.png" % [path, index]))
	texture = original_frame(2, 0)
	hide()


func display(family: int, progress: float) -> void:
	var keys: Array = KNOTS[family]
	var segment: int = 0
	while segment < keys.size() - 2 and progress >= float(keys[segment + 1]):
		segment += 1
	var local: float = inverse_lerp(float(keys[segment]), float(keys[segment + 1]), progress)
	if _last_family != family or _last_segment != segment:
		_surface.set_shader_parameter(&"source_pose", _art[family][segment])
		_surface.set_shader_parameter(&"destination_pose", _art[family][segment + 1])
		_surface.set_shader_parameter(&"motion", _motion[family][segment])
		_surface.set_shader_parameter(&"crouch_registration", family == 3)
		if family == 3:
			_surface.set_shader_parameter(&"crouch_anchors", PackedVector4Array(CROUCH_ANCHORS[segment]))
			_surface.set_shader_parameter(&"floor_offsets", CROUCH_FLOOR_OFFSETS[segment])
		_last_family = family
		_last_segment = segment
	_surface.set_shader_parameter(&"progress", clampf(local, 0.0, 1.0))
	show()


func original_frame(family: int, index: int) -> Texture2D:
	return _art[family][index]


func original_reference(family: int, progress: float) -> Texture2D:
	var keys: Array = KNOTS[family]
	var index: int = 1
	while index < keys.size() - 1 and progress >= (float(keys[index]) + float(keys[index + 1])) * 0.5:
		index += 1
	return original_frame(family, index)
