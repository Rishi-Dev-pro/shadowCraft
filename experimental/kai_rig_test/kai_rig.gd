extends Node2D
## Experimental static rig. Artwork is registered in the approved 512px canvas.

var _bones: Dictionary[StringName, Bone2D] = {}
var _rest: Dictionary[StringName, Transform2D] = {}
var _art: Dictionary[String, Sprite2D] = {}
var _approved_textures: Dictionary[String, Texture2D] = {}
var _approved_offsets: Dictionary[String, Vector2] = {}
var _repaired_textures: Dictionary[String, Texture2D] = {}
var _underpainting: Array[Sprite2D] = []

const REPAIR_REGISTRATION: String = "res://assets/characters/kai_hidden_artwork_v2/repair_registration.json"


static func load_approved_texture(path: String) -> ImageTexture:
	var art: Image = Image.load_from_file(path)
	assert(art != null and not art.is_empty(), "Cannot load approved Kai artwork: " + path)
	return ImageTexture.create_from_image(art)


func _ready() -> void:
	# Read the original PNGs directly for the art audit. This scene needs no
	# imported variants or new import settings beside the approved source art.
	for child: Node in find_children("*", "Sprite2D", true, true):
		var piece: Sprite2D = child as Sprite2D
		var path: String = piece.get_meta(&"approved_png")
		var id: String = path.get_file().get_basename()
		piece.texture = load_approved_texture(path)
		_art[id] = piece
		_approved_textures[id] = piece.texture
		_approved_offsets[id] = piece.position
	for child: Node in $Skeleton2D.find_children("*", "Bone2D", true, true):
		var bone: Bone2D = child as Bone2D
		_bones[bone.name] = bone
		_rest[bone.name] = bone.transform


func set_repaired_artwork(enabled: bool) -> void:
	var revisions: Dictionary = {}
	if enabled:
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(REPAIR_REGISTRATION))
		assert(manifest is Dictionary, "Invalid Kai repair registration.")
		revisions = manifest["layers"]
		if _underpainting.is_empty():
			for entry: Dictionary in manifest["underpainting"]:
				var bone: Bone2D = _bones[StringName(entry["bone"])]
				var origin: Array = entry["origin_px"]
				var pivot: Array = entry["pivot_px"]
				var layer: Sprite2D = Sprite2D.new()
				layer.name = entry["file"].get_file().get_basename().to_pascal_case()
				layer.centered = false
				layer.texture = load_approved_texture(entry["file"])
				layer.position = Vector2(float(origin[0]) - float(pivot[0]), float(origin[1]) - float(pivot[1]))
				layer.z_index = int(entry["z_index"])
				bone.add_child(layer)
				_underpainting.append(layer)
	for layer: Sprite2D in _underpainting:
		layer.visible = enabled
	for id: String in _art:
		var piece: Sprite2D = _art[id]
		piece.position = _approved_offsets[id]
		piece.texture = _approved_textures[id]
		if enabled and revisions.has(id):
			var entry: Dictionary = revisions[id]
			var delta: Array = entry["origin_delta"]
			if not _repaired_textures.has(id):
				var path: String = entry["file"]
				_repaired_textures[id] = _approved_textures[id] if path == piece.get_meta(&"approved_png") else load_approved_texture(path)
			piece.position += Vector2(float(delta[0]), float(delta[1]))
			piece.texture = _repaired_textures[id]


func reset_pose() -> void:
	for joint: StringName in _bones:
		_bones[joint].transform = _rest[joint]


func joint_transform(joint: StringName) -> Transform2D:
	return _bones[joint].transform


func set_angle(joint: StringName, degrees: float) -> void:
	_bones[joint].rotation = _rest[joint].get_rotation() + deg_to_rad(degrees)


func set_pelvis(drop: float, degrees: float) -> void:
	_bones[&"Pelvis"].position = _rest[&"Pelvis"].origin + Vector2(0, drop)
	set_angle(&"Pelvis", degrees)


func set_wrist(joint: StringName, degrees: float, offset: float) -> void:
	var axis: Vector2 = _rest[joint].origin.normalized()
	_bones[joint].position = _rest[joint].origin + axis * offset
	set_angle(joint, degrees)


func set_planted_stance(drop: float, spread: float) -> void:
	var near_heel: Vector2 = _bones[&"RightFoot"].global_position - Vector2(spread, 0)
	var far_heel: Vector2 = _bones[&"LeftFoot"].global_position + Vector2(spread, 0)
	set_pelvis(drop, 0)
	_plant_leg(&"RightThigh", &"RightShin", &"RightFoot", near_heel)
	_plant_leg(&"LeftThigh", &"LeftShin", &"LeftFoot", far_heel)


func _plant_leg(thigh_id: StringName, shin_id: StringName, foot_id: StringName, heel: Vector2) -> void:
	var thigh: Bone2D = _bones[thigh_id]
	var shin: Bone2D = _bones[shin_id]
	var foot: Bone2D = _bones[foot_id]
	var hip_space: Node2D = thigh.get_parent() as Node2D
	var target: Vector2 = hip_space.to_local(heel) - thigh.position
	var upper_segment: Vector2 = _rest[shin_id].origin
	var lower_segment: Vector2 = _rest[foot_id].origin
	var upper: float = upper_segment.length()
	var lower: float = lower_segment.length()
	var reach: float = clampf(target.length(), absf(upper - lower) + 0.1, upper + lower - 0.1)
	var bend_direction: float = signf(wrapf(lower_segment.angle() - upper_segment.angle(), -PI, PI))
	var bend: float = bend_direction * acos(clampf((reach * reach - upper * upper - lower * lower) / (2 * upper * lower), -1.0, 1.0))
	var upper_angle: float = target.angle() - atan2(lower * sin(bend), upper + lower * cos(bend))
	thigh.rotation = wrapf(upper_angle - upper_segment.angle(), -PI, PI)
	shin.rotation = wrapf(upper_angle + bend - thigh.rotation - lower_segment.angle(), -PI, PI)
	foot.global_rotation = 0.0
