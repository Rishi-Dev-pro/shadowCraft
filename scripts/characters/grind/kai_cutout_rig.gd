extends "res://scripts/characters/grind/agile_rig.gd"
## Kai's pose library uses the same grounded solver as the Agile Ninja.

var _previous_upper_mode: StringName
var _shoulder_from: float

func _ready() -> void:
	super._ready()
	_landmarks.append(_bones[&"RearHand"].get_node(^"rear_hand") as Node2D)


func _pose_spin(age: float, blend: float) -> void:
	# Protract the punching shoulder across the chest without scaling body volume.
	if _previous_upper_mode != _mode:
		_shoulder_from = _bones[&"NearShoulder"].position.x
		_previous_upper_mode = _mode
	var forward: float = 0.0
	if _mode == &"heavy":
		forward = 30.0 * smoothstep(0.28, 0.40, age) * (1.0 - smoothstep(0.49, 0.71, age))
	elif _mode == &"cross":
		forward = 20.0 * smoothstep(0.09, 0.16, age) * (1.0 - smoothstep(0.22, 0.38, age))
	_bones[&"NearShoulder"].position.x = lerpf(_shoulder_from, _near_shoulder_rest.x - forward, blend)


func _update_slash(_strike: GrindStrike, _age_seconds: float) -> void:
	pass


func _plant_weight(index: int, cursor: float, blend: float) -> float:
	if _mode == &"kick" and index == 0:
		return 1.0 - smoothstep(0.0, 0.11, cursor) * (1.0 - smoothstep(0.48, 0.70, cursor))
	return super._plant_weight(index, cursor, blend)


func strike_segment(strike: GrindStrike) -> PackedVector2Array:
	var limb: Bone2D = _bones[&"NearFoot"] if strike.animation == &"kick" else _bones[&"NearHand"]
	if strike.animation == &"light":
		limb = _bones[&"RearHand"]
	var tip: Vector2 = Vector2(-17, 18) if strike.animation == &"kick" else Vector2(-3, 23)
	return PackedVector2Array([limb.global_position, limb.to_global(tip)])


func _build_clips() -> void:
	_clip(&"idle", [0.0, 0.44, 0.93, 1.53, 2.1], {
		&"Pelvis": [1, 0, -1, 1, 1], &"Spine": [-5, -7, -5, -4, -5],
		&"Chest": [3, 2, 2, 4, 3], &"Head": [1, 4, 1, -1, 1],
		&"NearUpperArm": [41, 43, 41, 37, 41], &"NearForearm": [96, 93, 91, 94, 96],
		&"RearUpperArm": [11, 13, 12, 9, 11], &"RearForearm": [108, 105, 103, 106, 108],
		&"Headband": [-3, 2, -3, -5, -3], &"ScarfEnd": [4, -4, 6, 9, 4],
		&"ClothEnd": [2, 5, 1, -4, 2],
	}, [Vector2(1, 18), Vector2(1, 15), Vector2(-3, 18), Vector2(3, 20), Vector2(1, 18)], true)
	_clip(&"forward", [0.0, 0.25, 0.5, 0.75, 1.0], {
		&"Pelvis": [4, 0, -3, 0, 4], &"Spine": [-8, -7, -8, -7, -8],
		&"Chest": [-4, 0, 4, 0, -4], &"Head": [7, 6, 5, 6, 7],
		&"NearUpperArm": [3, 16, 33, 16, 3], &"NearForearm": [37, 41, 55, 41, 37],
		&"RearUpperArm": [26, 17, -7, 16, 26], &"RearForearm": [46, 44, 31, 44, 46],
		&"ScarfEnd": [1, 7, 2, -6, 1], &"ClothEnd": [-8, 4, 7, -3, -8],
	}, [Vector2(-5, 29), Vector2(-7, 21), Vector2(-5, 29), Vector2(-7, 21), Vector2(-5, 29)], true)
	_clip(&"backward", [0.0, 0.25, 0.5, 0.75, 1.0], {
		&"Pelvis": [2, 3, -2, 0, 2], &"Spine": [2, 3, 4, 3, 2], &"Head": [-4, -3, -4, -3, -4],
		&"NearUpperArm": [35, 36, 29, 34, 35], &"NearForearm": [69, 64, 74, 74, 69],
		&"RearUpperArm": [24, 17, 23, 26, 24], &"RearForearm": [72, 77, 75, 73, 72],
		&"ScarfEnd": [12, 6, -7, 1, 12], &"ClothEnd": [4, 3, -9, -2, 4],
	}, [Vector2(5, 32), Vector2(6, 26), Vector2(4, 32), Vector2(7, 25), Vector2(5, 32)], true)
	_clip(&"run", [0.0, 0.25, 0.5, 0.75, 1.0], {
		&"Pelvis": [6, 1, -5, 1, 6], &"Spine": [-21, -20, -21, -20, -21],
		&"Chest": [-6, -3, 5, -3, -6], &"Head": [15, 14, 12, 14, 15],
		&"NearUpperArm": [-25, 12, 51, 13, -25], &"NearForearm": [34, 54, 71, 54, 34],
		&"RearUpperArm": [44, 17, -30, 17, 44], &"RearForearm": [72, 55, 32, 55, 72],
		&"Headband": [-11, -8, -9, -7, -11], &"ScarfEnd": [6, -8, 3, 9, 6], &"ClothEnd": [-17, -6, -21, -9, -17],
	}, [Vector2(-13, 43), Vector2(-16, 30), Vector2(-13, 43), Vector2(-16, 30), Vector2(-13, 43)], true)
	_clip(&"turn", [0.0, 0.067, 0.15], {
		&"Pelvis": [1, 5, 1], &"Spine": [-5, -10, -5], &"Chest": [3, 8, 3],
		&"Head": [1, 8, 1], &"NearUpperArm": [41, 40, 41], &"NearForearm": [96, 100, 96],
		&"RearUpperArm": [11, 16, 11], &"RearForearm": [108, 105, 108],
		&"ScarfEnd": [4, -12, 4],
	}, [Vector2(1, 18), Vector2(2, 25), Vector2(1, 18)])
	_clip(&"crouch", [0.0, 0.43, 0.9], {
		&"Pelvis": [-8, -7, -8], &"Spine": [-17, -15, -17], &"Chest": [-9, -8, -9], &"Head": [22, 21, 22],
		&"NearUpperArm": [35, 37, 35], &"NearForearm": [74, 75, 74],
		&"RearUpperArm": [23, 25, 23], &"RearForearm": [68, 69, 68], &"ClothEnd": [8, 10, 8],
	}, [Vector2(16, 100), Vector2(17, 97), Vector2(16, 100)], true)
	_clip(&"guard", [0.0, 0.45, 0.90], {
		&"Spine": [-8, -8, -8], &"Chest": [5, 6, 5], &"Head": [8, 7, 8],
		&"NearUpperArm": [60, 58, 60], &"NearForearm": [87, 89, 87],
		&"RearUpperArm": [52, 50, 52], &"RearForearm": [74, 78, 74],
		&"ScarfEnd": [-2, 5, -2],
	}, [Vector2(6, 36), Vector2(7, 33), Vector2(6, 36)], true)
	_clip(&"air", [0.0, 0.19, 0.36, 0.70], {
		&"Spine": [-9, -16, -10, -7], &"Head": [6, 11, 5, 5],
		&"NearThigh": [13, 62, 41, 11], &"NearShin": [-29, -88, -56, -21],
		&"RearThigh": [19, 43, 37, 12], &"RearShin": [-38, -78, -51, -24],
		&"NearUpperArm": [30, 29, 41, 45], &"NearForearm": [75, 78, 70, 66],
		&"RearUpperArm": [25, 31, 25, 22], &"RearForearm": [60, 67, 65, 77],
		&"ScarfEnd": [4, -11, 11, -2], &"ClothEnd": [-5, -25, -15, 5],
	}, [Vector2(1, 18), Vector2(-4, 6), Vector2(0, 10), Vector2(-1, 15)])
	_clip(&"landing", [0.0, 0.07, 0.16], {
		&"Spine": [-10, -20, -5], &"Head": [10, 16, 3],
		&"NearUpperArm": [37, 46, 41], &"NearForearm": [71, 78, 72],
		&"RearUpperArm": [24, 31, 21], &"RearForearm": [75, 76, 80],
		&"ScarfEnd": [-2, 20, 5],
	}, [Vector2(0, 21), Vector2(-4, 53), Vector2(1, 18)])

	_clip(&"light", [0.0, 0.07, 0.13, 0.19, 0.24, 0.39], {
		&"Pelvis": [1, 5, -6, -6, -2, 1], &"Spine": [-5, -2, -16, -14, -9, -5],
		&"Chest": [3, 5, -6, -6, 1, 3], &"Head": [4, 1, 14, 13, 7, 1],
		&"RearUpperArm": [21, 14, 83, 93, 48, 21], &"RearForearm": [80, 88, 12, 9, 67, 80],
		&"NearUpperArm": [41, 43, 47, 47, 43, 41], &"NearForearm": [73, 79, 70, 75, 74, 72],
		&"ScarfEnd": [1, -4, 11, 13, -7, 4],
	}, [Vector2(1, 18), Vector2(8, 22), Vector2(-13, 25), Vector2(-16, 24), Vector2(-7, 20), Vector2(1, 18)])
	_clip(&"cross", [0.0, 0.09, 0.15, 0.22, 0.30, 0.45], {
		&"Pelvis": [1, 9, -6, -8, -5, 1], &"Spine": [-5, 5, -13, -16, -11, -5],
		&"Chest": [3, 9, -11, -10, -5, 3], &"Head": [2, -5, 15, 13, 8, 1],
		&"NearShoulder": [0, -7, 10, 10, 2, 0],
		&"NearUpperArm": [41, 12, 121, 124, 48, 41], &"NearForearm": [72, 86, 11, 8, 67, 72],
		&"RearUpperArm": [21, 28, 27, 28, 24, 21], &"RearForearm": [80, 77, 65, 68, 73, 80],
		&"ScarfEnd": [4, 0, 15, 13, -5, 4],
	}, [Vector2(1, 18), Vector2(16, 25), Vector2(-14, 26), Vector2(-21, 25), Vector2(-5, 21), Vector2(1, 18)])
	_clip(&"heavy", [0.0, 0.12, 0.27, 0.36, 0.44, 0.51, 0.68, 0.89], {
		&"Pelvis": [1, 8, 11, -7, -12, -11, -4, 1],
		&"Spine": [-5, 3, 8, -16, -19, -17, -11, -5],
		&"Chest": [3, 10, 15, -12, -16, -10, -4, 3], &"Head": [1, -6, -11, 15, 20, 20, 11, 1],
		&"NearShoulder": [0, -2, -9, 9, 14, 11, 6, 0],
		&"NearUpperArm": [41, 3, -22, 126, 138, 130, 46, 41],
		&"NearForearm": [72, 83, 91, 17, 7, 12, 66, 72],
		&"RearUpperArm": [21, 32, 36, 29, 19, 15, 21, 21],
		&"RearForearm": [80, 73, 74, 82, 73, 72, 74, 80], &"ClothEnd": [2, -3, -9, 8, 21, 16, -12, 2],
		&"ScarfEnd": [4, 0, -9, 3, 19, 15, -9, 4],
	}, [Vector2(1, 18), Vector2(18, 24), Vector2(31, 40), Vector2(-16, 29), Vector2(-25, 29),
		Vector2(-33, 35), Vector2(-17, 25), Vector2(1, 18)])
	_clip(&"kick", [0.0, 0.12, 0.20, 0.27, 0.34, 0.48, 0.69], {
		&"Pelvis": [1, -3, 2, 5, 5, -1, 1], &"Spine": [-5, 1, 10, 18, 11, 6, -5],
		&"Chest": [3, 2, 1, 4, -3, 0, 3], &"Head": [1, -4, -8, -12, -8, -3, 1],
		&"NearThigh": [11, 48, 102, 94, 91, 42, 12], &"NearShin": [-13, -72, -98, -6, -13, -62, -17],
		&"NearFoot": [0, -5, 7, 17, 13, 5, 0],
		&"NearUpperArm": [41, 46, 42, 33, 31, 35, 41], &"NearForearm": [72, 71, 68, 64, 71, 71, 72],
		&"RearUpperArm": [21, 26, 29, 12, 11, 22, 21], &"RearForearm": [80, 72, 66, 54, 59, 70, 80],
		&"ScarfEnd": [4, 3, -7, -12, 10, 8, 4],
	}, [Vector2(1, 18), Vector2(5, 23), Vector2(4, 22), Vector2(-9, 24), Vector2(-10, 26), Vector2(4, 26), Vector2(1, 18)])

	_clip(&"dash_forward", [0.0, 0.09, 0.2, 0.33], {
		&"Spine": [-5, -29, -23, -5], &"Chest": [3, -10, -6, 3], &"Head": [1, 23, 17, 1],
		&"NearUpperArm": [41, 8, 39, 41], &"NearForearm": [72, 39, 63, 72],
		&"RearUpperArm": [21, 31, 13, 21], &"RearForearm": [80, 63, 55, 80],
		&"Headband": [-3, -16, -11, -3], &"ScarfEnd": [4, 21, 12, 4], &"ClothEnd": [2, -35, -21, 2],
	}, [Vector2(1, 18), Vector2(-16, 32), Vector2(-11, 32), Vector2(1, 18)])
	_clip(&"dash_backward", [0.0, 0.1, 0.22, 0.34], {
		&"Spine": [-5, 14, 8, -5], &"Chest": [3, 7, 6, 3], &"Head": [1, -13, -7, 1],
		&"NearUpperArm": [41, 48, 44, 41], &"NearForearm": [72, 87, 84, 72],
		&"RearUpperArm": [21, 33, 35, 21], &"RearForearm": [80, 92, 86, 80],
		&"ScarfEnd": [4, -12, -17, 4], &"ClothEnd": [2, 18, 5, 2],
	}, [Vector2(1, 18), Vector2(12, 32), Vector2(10, 27), Vector2(1, 18)])
	_clip(&"hit", [0.0, 0.075, 0.17, 0.29], {
		&"Spine": [-5, 12, 6, -5], &"Chest": [3, 10, 4, 3], &"Head": [1, 12, -6, 1],
		&"NearUpperArm": [41, 32, 28, 41], &"NearForearm": [72, 83, 88, 72],
		&"RearUpperArm": [21, 12, 18, 21], &"RearForearm": [80, 61, 71, 80],
		&"ScarfEnd": [4, -7, 15, 4],
	}, [Vector2(1, 18), Vector2(17, 28), Vector2(11, 27), Vector2(1, 18)])
	_clip(&"knockback", [0.0, 0.08, 0.20, 0.32, 0.47], {
		&"Pelvis": [1, 12, 8, 1, 1], &"Spine": [-5, 20, 17, -1, -5],
		&"Chest": [3, 9, -4, 3, 3], &"Head": [1, 14, -17, -4, 1],
		&"NearUpperArm": [41, -8, 14, 38, 41], &"NearForearm": [72, 44, 51, 62, 72],
		&"RearUpperArm": [21, -8, -1, 29, 21], &"RearForearm": [80, 50, 60, 69, 80],
		&"ScarfEnd": [4, -14, 17, 9, 4],
	}, [Vector2(1, 18), Vector2(17, 32), Vector2(20, 43), Vector2(8, 40), Vector2(1, 18)])
	_clip(&"defeat", [0.0, 0.14, 0.35, 0.59, 0.90], {
		&"Pelvis": [1, 14, 32, 71, 87], &"Spine": [-5, 9, 18, 6, 0],
		&"Chest": [3, 6, 10, 1, 0], &"Head": [1, 8, -13, -7, 0],
		&"NearUpperArm": [41, 21, 11, 21, 17], &"NearForearm": [72, 63, 36, 18, 15],
		&"RearUpperArm": [21, 17, 37, 2, -14], &"RearForearm": [80, 58, 41, 2, -12],
		&"NearThigh": [11, 13, 24, 17, 13], &"NearShin": [-16, -25, -35, -16, -11],
		&"RearThigh": [9, 12, 24, 12, 8], &"RearShin": [-18, -25, -39, -11, -7],
		&"Headband": [-3, 3, -15, -50, -82], &"Cloth": [0, -9, -29, -57, -86],
	}, [Vector2(1, 18), Vector2(9, 24), Vector2(29, 75), Vector2(37, 165), Vector2(49, 211)])
