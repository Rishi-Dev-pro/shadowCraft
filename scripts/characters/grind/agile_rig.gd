extends Node2D
## The original concept faces left. Only visual transforms are mirrored.

const ART_SCALE: float = 0.327
const STANCE: float = 0.58
const MOVEMENT: Array[StringName] = [&"forward", &"backward", &"run"]
const ROTATED: Array[StringName] = [
	&"Pelvis", &"Torso", &"Head", &"Hair", &"Scarf", &"ScarfEnd", &"Cloth", &"ClothEnd",
	&"NearUpperArm", &"NearForearm", &"NearHand", &"RearUpperArm", &"RearForearm", &"Weapon",
	&"NearThigh", &"NearShin", &"NearFoot", &"RearThigh", &"RearShin", &"RearFoot",
]

@onready var _skeleton: Skeleton2D = $Skeleton2D
@onready var _player: AnimationPlayer = $AnimationPlayer
var _bones: Dictionary[StringName, Bone2D] = {}
var _ankle_rest: Dictionary[StringName, Vector2] = {}
var _library: AnimationLibrary = AnimationLibrary.new()
var _mode: StringName = &"idle"
var _phase: float = 0.0
var _stance_weight: float = 0.0
var _stride_sign: float = -1.0
var _cycle_distance: float = 146.0
var _step_height: float = 35.0
var _pelvis_y: float
var _defeat_correction: float


func _ready() -> void:
	process_priority = 1
	for bone: Node in _skeleton.find_children("*", "Bone2D", true, true):
		_bones[bone.name] = bone as Bone2D
	for foot: StringName in [&"RearFoot", &"NearFoot"]:
		_ankle_rest[foot] = _skeleton.to_local(_bones[foot].global_position)
	_pelvis_y = _bones[&"Pelvis"].position.y
	_build_clips()
	_player.add_animation_library(&"", _library)
	_player.play(&"idle")


func drive(mode: StringName, facing: float, travel: float, delta: float) -> void:
	_skeleton.transform = Transform2D(Vector2(-facing * ART_SCALE, 0), Vector2(0, ART_SCALE), Vector2.ZERO)
	if mode != _mode:
		_mode = mode
		_player.play(mode, 0.12 if mode in MOVEMENT or mode == &"idle" else 0.08)
	if mode in MOVEMENT:
		_stride_sign = 1.0 if mode == &"backward" else -1.0
		_cycle_distance = 188.0 if mode == &"run" else (118.0 if mode == &"backward" else 144.0)
		_step_height = 62.0 if mode == &"run" else (25.0 if mode == &"backward" else 42.0)
		_phase = fposmod(_phase + absf(travel) / _cycle_distance, 1.0)
	_stance_weight = move_toward(_stance_weight, float(mode in MOVEMENT), delta * 9.0)


func _process(_delta: float) -> void:
	if _mode == &"defeat":
		_keep_collapse_above_floor()
		return
	if _mode in [&"hit", &"knockback", &"air"]:
		return
	_place_leg(&"NearThigh", &"NearShin", &"NearFoot", _phase)
	_place_leg(&"RearThigh", &"RearShin", &"RearFoot", fposmod(_phase + 0.5, 1.0))


func _keep_collapse_above_floor() -> void:
	# Compensate for the lower limbs swinging toward the baseline as the body falls.
	var pelvis: Bone2D = _bones[&"Pelvis"]
	pelvis.position.y -= _defeat_correction
	var bottom: float = -INF
	for name: StringName in [&"NearFoot", &"RearFoot", &"Head", &"Waist", &"NearHand"]:
		if name == &"Waist":
			var waist: Sprite2D = pelvis.get_node("waist") as Sprite2D
			bottom = maxf(bottom, _sprite_bottom(waist))
			continue
		var bone: Bone2D = _bones[name]
		var sprite: Sprite2D = bone.get_child(0) as Sprite2D if name != &"Head" else bone.get_node("head") as Sprite2D
		if name == &"NearHand":
			sprite = bone.get_node("near_hand") as Sprite2D
		bottom = maxf(bottom, _sprite_bottom(sprite))
	var age: float = _player.current_animation_position if _player.is_playing() else 0.94
	_defeat_correction = -bottom * (1.0 if bottom > 0.0 else smoothstep(0.31, 0.91, age))
	pelvis.position.y += _defeat_correction
	# AnimationPlayer overwrites this track while the defeat clip plays.
	if _player.is_playing():
		_defeat_correction = 0.0


func _sprite_bottom(sprite: Sprite2D) -> float:
	var bottom: float = -INF
	var rect: Rect2 = sprite.get_rect().grow(-3.0)
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		bottom = maxf(bottom, _skeleton.to_local(sprite.to_global(corner)).y)
	return bottom


func _place_leg(thigh_name: StringName, shin_name: StringName, foot_name: StringName, phase: float) -> void:
	var thigh: Bone2D = _bones[thigh_name]
	var shin: Bone2D = _bones[shin_name]
	var foot: Bone2D = _bones[foot_name]
	var target: Vector2 = _ankle_rest[foot_name]
	var stride: float = _cycle_distance * STANCE / ART_SCALE
	if phase < STANCE:
		# Local foot travel exactly cancels root travel during the planted segment.
		target.x += (0.5 - phase / STANCE) * stride * _stride_sign * _stance_weight
	else:
		var swing: float = (phase - STANCE) / (1.0 - STANCE)
		target.x += (smoothstep(0.0, 1.0, swing) - 0.5) * stride * _stride_sign * _stance_weight
		target.y -= sin(PI * swing) * _step_height * _stance_weight
	var local_goal: Vector2 = _bones[&"Pelvis"].to_local(_skeleton.to_global(target)) - thigh.position
	var a: float = shin.position.length()
	var b: float = foot.position.length()
	var reach: float = clampf(local_goal.length(), absf(a - b) + 0.5, a + b - 0.4)
	var bend: float = acos(clampf((reach * reach - a * a - b * b) / (2.0 * a * b), -1.0, 1.0))
	var hip: float = local_goal.angle() - atan2(b * sin(bend), a + b * cos(bend))
	if thigh_name == &"RearThigh":
		bend = -bend
		hip = local_goal.angle() - atan2(b * sin(bend), a + b * cos(bend))
	thigh.rotation = wrapf(hip - shin.position.angle(), -PI, PI)
	shin.rotation = wrapf(hip + bend - thigh.rotation - foot.position.angle(), -PI, PI)
	foot.rotation = -(_bones[&"Pelvis"].rotation + thigh.rotation + shin.rotation)


func _build_clips() -> void:
	_clip(&"idle", [0.0, 0.56, 1.12, 1.68], {
		&"Torso": [0, -2, 1, 0], &"Head": [0, 2, -1, 0], &"Hair": [0, -2, 1, 0],
		&"NearForearm": [8, 13, 9, 8], &"Weapon": [9, 12, 7, 9], &"Scarf": [0, 5, -4, 0],
		&"ScarfEnd": [-4, 8, -7, -4], &"Cloth": [0, 4, -2, 0], &"ClothEnd": [0, 7, -3, 0],
	}, [9, 5, 9, 9], true)
	_clip(&"forward", [0.0, 0.18, 0.36, 0.54, 0.72], {
		&"Torso": [-6, -9, -5, -8, -6], &"Head": [4, 7, 3, 6, 4],
		&"NearUpperArm": [9, 24, 7, -12, 9], &"RearUpperArm": [2, -18, 4, 22, 2],
		&"NearForearm": [19, 25, 14, 13, 19], &"ScarfEnd": [5, 13, 2, -7, 5],
		&"Cloth": [-5, -11, -7, -3, -5], &"ClothEnd": [3, 14, 1, -8, 3],
	}, [17, 9, 17, 9, 17], true)
	_clip(&"backward", [0.0, 0.15, 0.3, 0.45, 0.6], {
		&"Torso": [7, 10, 7, 9, 7], &"Head": [-6, -8, -6, -7, -6],
		&"NearUpperArm": [25, 18, 27, 34, 25], &"NearForearm": [37, 36, 37, 40, 37],
		&"RearUpperArm": [21, 28, 20, 12, 21], &"RearForearm": [46, 38, 46, 51, 46],
		&"Weapon": [-32, -28, -33, -32, -32], &"ScarfEnd": [-9, 3, 10, 1, -9],
	}, [20, 14, 20, 14, 20], true)
	_clip(&"run", [0.0, 0.12, 0.24, 0.36, 0.48], {
		&"Torso": [-16, -20, -16, -19, -16], &"Head": [12, 13, 11, 14, 12],
		&"NearUpperArm": [-15, 27, -12, -38, -15], &"NearForearm": [40, 55, 32, 23, 40],
		&"RearUpperArm": [9, -34, 3, 37, 9], &"RearForearm": [34, 20, 42, 45, 34],
		&"Scarf": [-19, -11, -20, -16, -19], &"ScarfEnd": [-12, 16, 0, -11, -12],
		&"Cloth": [-17, -29, -23, -15, -17], &"ClothEnd": [4, 23, 7, -11, 4],
	}, [28, 14, 28, 14, 28], true)
	_clip(&"guard", [0.0, 0.42, 0.84], {
		&"Torso": [9, 11, 9], &"Head": [-7, -9, -7],
		&"NearUpperArm": [38, 41, 38], &"NearForearm": [89, 86, 89],
		&"RearUpperArm": [22, 23, 22], &"RearForearm": [100, 102, 100],
		&"Weapon": [-88, -84, -88], &"ScarfEnd": [3, 8, 3],
	}, [41, 37, 41], true)
	_clip(&"light", [0.0, 0.13, 0.22, 0.31, 0.56], {
		&"Torso": [3, -15, 22, 14, 0], &"Head": [-2, 12, -15, -9, 0],
		&"NearUpperArm": [8, -47, 80, 61, 0], &"NearForearm": [18, -47, 20, 42, 8],
		&"Weapon": [8, -25, -25, 20, 8], &"RearUpperArm": [10, 30, -25, -5, 0],
		&"ScarfEnd": [2, 19, -27, -16, 2], &"ClothEnd": [0, 18, -20, 8, 0],
	}, [12, 27, 20, 24, 9])
	_clip(&"heavy", [0.0, 0.18, 0.37, 0.48, 0.6, 0.91], {
		&"Torso": [3, -21, -24, 34, 26, 0], &"Head": [0, 12, 15, -24, -15, 0],
		&"NearUpperArm": [9, -117, -163, 71, 52, 0], &"NearForearm": [16, -34, -51, 27, 39, 8],
		&"Weapon": [8, 33, 67, -42, 5, 8], &"RearForearm": [12, 60, 74, -24, 8, 0],
		&"ScarfEnd": [1, 16, 24, -39, -16, 1], &"ClothEnd": [0, 6, 17, -34, 15, 0],
	}, [13, 29, 37, 22, 33, 9])
	_clip(&"hit", [0.0, 0.085, 0.16, 0.29], {
		&"Torso": [0, -24, -13, 0], &"Head": [0, -15, -7, 0], &"Hair": [0, 16, 9, 0],
		&"NearUpperArm": [8, -32, -13, 0], &"NearForearm": [13, -27, -6, 8],
		&"ScarfEnd": [0, 24, -16, 0],
	}, [10, 16, 13, 9])
	_clip(&"knockback", [0.0, 0.09, 0.24, 0.43], {
		&"Pelvis": [0, -11, -6, 0], &"Torso": [0, -28, -16, 0],
		&"Head": [0, -18, 5, 0], &"NearUpperArm": [0, -37, -19, 0],
		&"NearThigh": [0, 6, 4, 0], &"RearShin": [0, -13, -6, 0],
		&"ClothEnd": [1, 25, -11, 0],
	}, [10, 16, 18, 10])
	_clip(&"air", [0.0, 0.28, 0.56], {
		&"Torso": [9, 3, 9], &"NearThigh": [27, 37, 27], &"NearShin": [-49, -63, -49],
		&"RearThigh": [18, 8, 18], &"RearShin": [-53, -66, -53],
		&"NearUpperArm": [22, 28, 22], &"NearForearm": [47, 53, 47], &"ScarfEnd": [8, -11, 8],
	}, [0, 5, 0], true)
	_clip(&"defeat", [0.0, 0.13, 0.35, 0.65, 0.94], {
		&"Pelvis": [0, 8, 32, 76, 89], &"Torso": [0, -11, -17, -3, -2],
		&"Head": [0, -12, -28, -13, -2], &"NearUpperArm": [0, 16, 41, 33, 26],
		&"NearForearm": [10, -19, -11, -19, -7], &"RearThigh": [0, 7, 8, -11, -12],
		&"RearShin": [0, -12, -26, -18, -2], &"NearThigh": [0, 14, 22, 21, 18],
		&"NearShin": [0, -13, -26, -9, 0], &"ScarfEnd": [0, -11, -28, -54, -86],
		&"Cloth": [0, -5, -19, -75, -128], &"ClothEnd": [0, 12, 8, -4, -10],
	}, [8, 15, 104, 246, 361])


func _clip(clip_name: StringName, times: Array[float], angles: Dictionary, height: Array, loop: bool = false) -> void:
	var animation: Animation = Animation.new()
	animation.length = times.back()
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for bone_name: StringName in ROTATED:
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(String(get_path_to(_bones[bone_name])) + ":rotation"))
		if angles.has(bone_name):
			var values: Array = angles[bone_name]
			for idx: int in range(times.size()):
				animation.track_insert_key(track, times[idx], deg_to_rad(float(values[idx])))
		else:
			animation.track_insert_key(track, 0.0, 0.0)
	var pelvis_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(pelvis_track, NodePath(String(get_path_to(_bones[&"Pelvis"])) + ":position:y"))
	for idx: int in range(times.size()):
		animation.track_insert_key(pelvis_track, times[idx], _pelvis_y + float(height[idx]))
	_library.add_animation(clip_name, animation)
