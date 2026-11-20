extends Node2D
## The master canvas stays unscaled. Apply display scale after compositing.

const Weapon = preload("res://experimental/raezen_hybrid/weapon_attachment.gd")
const TIP = preload("res://experimental/raezen_hybrid/cloth_tip.gdshader")
const ART: String = "res://experimental/raezen_hybrid/art/"

var skeleton: Skeleton2D
var weapon: Weapon
var bones: Dictionary[String, Bone2D] = {}
var layers: Dictionary[String, Sprite2D] = {}
var _rest: Dictionary[String, Transform2D] = {}
var _underlays: Array[Sprite2D] = []
var _sword_layers: Array[Sprite2D] = []
var _points: Dictionary[String, Vector2] = {}
var _cloth_shaders: Dictionary[String, ShaderMaterial] = {}
var offhand_reach_error: float = 0.0


func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART + "registration.json"))
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	for joint: String in data["joints"]:
		var entry: Array = data["joints"][joint]
		var parent_name: String = entry[0]
		var location: Vector2 = coordinates(entry[1])
		var bone: Bone2D = Bone2D.new()
		bone.name = joint
		bone.set_autocalculate_length_and_angle(false)
		bone.position = location if parent_name.is_empty() else location - _points[parent_name]
		bone.rest = bone.transform
		var parent_node: Node2D = skeleton if parent_name.is_empty() else bones[parent_name]
		parent_node.add_child(bone)
		bones[joint] = bone
		_rest[joint] = bone.transform
		_points[joint] = location
	var grip: Vector2 = coordinates(data["primary_grip"])
	weapon = Weapon.new()
	weapon.name = "PrimaryGrip"
	weapon.position = grip - _points["HandNear"]
	bones["HandNear"].add_child(weapon)
	weapon.configure(coordinates(data["offhand_grip"]) - grip, coordinates(data["blade_tip"]) - grip)
	for layer: Dictionary in data["layers"]:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = layer["name"]
		sprite.centered = false
		sprite.texture = load_pixels(ART + layer["name"] + ".png")
		sprite.z_as_relative = false
		sprite.z_index = layer["depth"]
		var mount: String = layer["joint"]
		sprite.position = coordinates(layer["origin"]) - (grip if mount == "BladePivot" else _points[mount])
		var parent_node: Node2D = weapon.pivot if mount == "BladePivot" else bones[mount]
		parent_node.add_child(sprite)
		layers[layer["name"]] = sprite
		if mount == "BladePivot":
			_sword_layers.append(sprite)
		if layer["underlay"]:
			_underlays.append(sprite)
	for id: String in ["hair", "scarf"]:
		var shader: ShaderMaterial = ShaderMaterial.new()
		shader.shader = TIP
		_cloth_shaders[id] = shader
	reset_pose()


static func coordinates(point: Array) -> Vector2:
	return Vector2(float(point[0]), float(point[1]))


static func load_pixels(path: String) -> ImageTexture:
	var pixels: Image = Image.load_from_file(path)
	assert(pixels != null and not pixels.is_empty(), "Missing Raezen art: " + path)
	return ImageTexture.create_from_image(pixels)


func reset_pose() -> void:
	for joint: String in bones:
		bones[joint].transform = _rest[joint]
	for sprite: Sprite2D in _underlays:
		sprite.modulate.a = 0.0
	weapon.set_pose(0.0)
	_set_weapon_depth(0)
	for id: String in _cloth_shaders:
		layers[id].material = null
	offhand_reach_error = 0.0


func apply_pose(pose: Dictionary) -> void:
	reset_pose()
	bones["Root"].position += pose["root"]
	bones["Pelvis"].position += pose["pelvis"]
	var angles: Dictionary = pose["angles"]
	for joint: String in angles:
		bones[joint].rotation = deg_to_rad(float(angles[joint]))
	_soft_tip("hair", float(angles.get("HairTip", 0.0)))
	_soft_tip("scarf", float(angles.get("ScarfTip", 0.0)))
	var amount: float = pose["underlay"]
	for sprite: Sprite2D in _underlays:
		sprite.modulate.a = amount
	weapon.set_pose(pose["blade"])
	_set_weapon_depth(roundi(pose["depth"]))
	if pose["solve_feet"]:
		_plant("Near", pose["near"])
		_plant("Far", pose["far"])
	if pose["offhand"] > 0.0:
		var goal: Vector2 = bones["HandFar"].global_position.lerp(weapon.offhand.global_position, pose["offhand"])
		var align: float = weapon.pivot.global_rotation
		var hand_offset: Vector2 = _rest["HandFar"].origin.rotated(align)
		_solve("ArmFar", "ElbowFar", "WristFar", goal - hand_offset, _rest["WristFar"].origin)
		bones["WristFar"].global_rotation = align
		offhand_reach_error = bones["HandFar"].global_position.distance_to(goal)


func _set_weapon_depth(offset: int) -> void:
	for layer: Sprite2D in _sword_layers:
		layer.z_index = (30 if layer.name == &"grip_wrap" else 31) + offset


func _soft_tip(id: String, pixels: float) -> void:
	if is_zero_approx(pixels):
		return
	var sprite: Sprite2D = layers[id]
	var shader: ShaderMaterial = _cloth_shaders[id]
	shader.set_shader_parameter(&"tip_shift_uv", pixels / float(sprite.texture.get_height()))
	sprite.material = shader


func _plant(side: String, offset: Vector2) -> void:
	var foot: String = "Foot" + side
	var goal: Vector2 = to_global(_points[foot] + offset + bones["Root"].position - _rest["Root"].origin)
	_solve("Hip" + side, "Knee" + side, foot, goal, _rest[foot].origin)
	bones[foot].global_rotation = 0.0


func _solve(first_name: String, second_name: String, end_name: String, goal: Vector2, lower: Vector2) -> float:
	var first: Bone2D = bones[first_name]
	var second: Bone2D = bones[second_name]
	var parent_node: Node2D = first.get_parent()
	var target: Vector2 = parent_node.to_local(goal) - first.position
	var upper: Vector2 = _rest[second_name].origin
	var a: float = upper.length()
	var b: float = lower.length()
	var length: float = clampf(target.length(), absf(a - b) + 0.001, a + b - 0.001)
	var bend_side: float = -1.0 if upper.cross(lower) < 0.0 else 1.0
	var bend: float = bend_side * acos(clampf((length * length - a * a - b * b) / (2.0 * a * b), -1.0, 1.0))
	var pitch: float = target.angle() - atan2(b * sin(bend), a + b * cos(bend))
	first.rotation = pitch - upper.angle()
	second.rotation = pitch + bend - first.rotation - lower.angle()
	return bones[end_name].global_position.distance_to(goal)


func foot_error(side: String, expected: Vector2) -> float:
	var foot: String = "Foot" + side
	return to_local(bones[foot].global_position).distance_to(_points[foot] + expected)
