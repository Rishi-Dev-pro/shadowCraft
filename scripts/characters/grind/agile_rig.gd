extends Node2D
## Combat poses and distance-driven gait are composed once, on the duel's physics tick.

const ART_SCALE: float = 0.327
const STANCE: float = 0.60
const MOVEMENT: Array[StringName] = [&"forward", &"backward", &"run"]
const LEG_CHAINS: Array[Array] = [
	[&"NearThigh", &"NearShin", &"NearFoot"],
	[&"RearThigh", &"RearShin", &"RearFoot"],
]
const ROTATED: Array[StringName] = [
	&"Pelvis", &"Spine", &"Chest", &"Neck", &"Head", &"Hair",
	&"NearShoulder", &"RearShoulder", &"Headband", &"ScarfEnd", &"Cloth", &"ClothEnd",
	&"NearUpperArm", &"NearForearm", &"NearHand", &"RearUpperArm", &"RearForearm", &"Weapon",
	&"NearThigh", &"NearShin", &"NearFoot", &"RearThigh", &"RearShin", &"RearFoot",
]

@onready var _skeleton: Skeleton2D = $Skeleton2D
@onready var _player: AnimationPlayer = $AnimationPlayer
var _bones: Dictionary[StringName, Bone2D] = {}
var _library: AnimationLibrary = AnimationLibrary.new()
var _rest_feet: Array[Vector2] = []
var _feet: Array[Vector2] = []
var _swing_from: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _swing_goal: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _swinging: Array[bool] = [false, false]
var _from_angles: PackedFloat32Array
var _landmarks: Array[Sprite2D] = []
var _soles: Array[float] = []
var _mode: StringName
var _phase: float = STANCE
var _age: float
var _from_pelvis: Vector2
var _pelvis_rest: Vector2
var _facing: float = -1.0
var _moving: bool = false
var _direction: float = -1.0
var _stride: float = 112.0
var _lift: float = 40.0
var _scarf_drag: float
var _arc: float = -1.0
var _heavy_arc: bool = false
var _near_shoulder_rest: Vector2
var _rear_shoulder_rest: Vector2
var _blade: Sprite2D
var _chest_art: Sprite2D
var _shoulder_profile: float = 1.0
var _from_profile: float = 1.0
var _settling_foot: int = -1
var _settle_from: Vector2
var _settle_age: float


func _ready() -> void:
	for bone: Node in _skeleton.find_children("*", "Bone2D", true, true):
		_bones[bone.name] = bone as Bone2D
	for chain: Array in LEG_CHAINS:
		var foot: Bone2D = _bones[chain[2]]
		var sole: Sprite2D = foot.get_child(0) as Sprite2D
		_soles.append(sole.position.y + sole.get_rect().end.y - 2.0)
		var anchor: Vector2 = _skeleton.to_local(foot.global_position)
		_rest_feet.append(Vector2(anchor.x * 0.72, -_soles.back()))
		_landmarks.append(sole)
	_feet.assign(_rest_feet)
	_landmarks.append(_bones[&"Head"].get_node("head") as Sprite2D)
	_landmarks.append(_bones[&"Pelvis"].get_node("waist") as Sprite2D)
	_landmarks.append(_bones[&"NearHand"].get_node("near_hand") as Sprite2D)
	_pelvis_rest = _bones[&"Pelvis"].position
	_near_shoulder_rest = _bones[&"NearShoulder"].position
	_rear_shoulder_rest = _bones[&"RearShoulder"].position
	_chest_art = _bones[&"Chest"].get_node(^"torso") as Sprite2D
	_blade = _bones[&"Weapon"].get_node(^"blade") as Sprite2D
	_from_angles.resize(ROTATED.size())
	_build_clips()
	_player.add_animation_library(&"", _library)


func drive(mode: StringName, facing: float, travel: float, delta: float, strike: GrindStrike = null, strike_age: float = 0.0) -> void:
	if facing != _facing:
		# Exchange support feet when the side-on artwork turns to face the opponent.
		var old_near: Vector2 = _feet[0]
		_feet[0] = Vector2(-_feet[1].x, _feet[1].y + _soles[1] - _soles[0])
		_feet[1] = Vector2(-old_near.x, old_near.y + _soles[0] - _soles[1])
		_swinging.fill(false)
		_facing = facing
	_skeleton.transform = Transform2D(Vector2(-facing * ART_SCALE, 0.0), Vector2(0.0, ART_SCALE), Vector2.ZERO)
	var travel_art: float = -facing * travel / ART_SCALE
	_update_steps(mode, travel_art, delta)
	if mode != _mode:
		for index: int in ROTATED.size():
			_from_angles[index] = _bones[ROTATED[index]].rotation
		_from_pelvis = _bones[&"Pelvis"].position
		_from_profile = _shoulder_profile
		_age = 0.0
		_mode = mode
	else:
		_age += delta

	var clip: Animation = _library.get_animation(mode)
	var cursor: float = _age
	if _moving:
		cursor = _phase * clip.length
	elif strike != null:
		cursor = strike_age * clip.length / strike.duration
	elif clip.loop_mode != Animation.LOOP_NONE:
		cursor = fposmod(_age, clip.length)
	cursor = minf(cursor, clip.length)
	var blend: float = smoothstep(0.0, 0.09 if mode in [&"light", &"heavy", &"hit", &"knockback", &"defeat"] else 0.15, _age)
	for index: int in ROTATED.size():
		var goal: float = float(clip.value_track_interpolate(index, cursor))
		_bones[ROTATED[index]].rotation = lerp_angle(_from_angles[index], goal, blend)
	var pelvis: Bone2D = _bones[&"Pelvis"]
	var shift: Vector2 = clip.value_track_interpolate(ROTATED.size(), cursor)
	pelvis.position = _from_pelvis.lerp(_pelvis_rest + shift, blend)
	_scarf_drag = lerpf(_scarf_drag, travel_art * 1.4, 1.0 - exp(-delta * 6.0))
	_bones[&"Headband"].rotation += deg_to_rad(_scarf_drag) * blend
	_bones[&"ScarfEnd"].rotation += deg_to_rad(_scarf_drag * 0.8) * blend
	_pose_spin(cursor if mode == &"heavy" else 0.0, blend)
	if mode == &"defeat":
		_ground_collapse(smoothstep(0.27, 0.88, cursor))
	elif mode != &"air":
		_support_pelvis()
		for index: int in LEG_CHAINS.size():
			_place_leg(index, blend if _mode == &"knockback" else 1.0)
	_update_slash(strike, strike_age)


func _pose_spin(age: float, blend: float) -> void:
	# Project the shoulder turn through the side profile as the support foot pivots.
	var turn: float = smoothstep(0.28, 0.57, age)
	_shoulder_profile = lerpf(_from_profile, cos(turn * TAU), blend)
	var across: float = _shoulder_profile
	_bones[&"NearShoulder"].position.x = _near_shoulder_rest.x * across
	_bones[&"RearShoulder"].position.x = _rear_shoulder_rest.x * across
	var width: float = lerpf(0.66, 1.0, absf(across))
	_chest_art.scale.x = width
	_chest_art.position.x = -71.0 * width
	_bones[&"NearUpperArm"].z_index = -8 if across < -0.16 else 0
	_bones[&"RearUpperArm"].z_index = 8 if across < -0.16 else 0


func _update_steps(mode: StringName, travel: float, delta: float) -> void:
	var walking: bool = mode in MOVEMENT
	var direction: float = 1.0 if mode == &"backward" else -1.0
	if walking and (not _moving or _direction != direction):
		# Begin with the trailing foot so a reversal can keep the other boot down.
		var trailing: int = 0 if (_feet[0].x - _feet[1].x) * direction <= 0.0 else 1
		var near_lift: float = _rest_feet[0].y - _feet[0].y
		var rear_lift: float = _rest_feet[1].y - _feet[1].y
		if maxf(near_lift, rear_lift) > 0.1:
			trailing = 0 if near_lift > rear_lift else 1
		_phase = fposmod(STANCE - trailing * 0.5, 1.0)
		_swinging.fill(false)
		_direction = direction
	var previous_phase: float = _phase
	if walking:
		var target_stride: float = 155.0 if mode == &"run" else (93.0 if mode == &"backward" else 111.0)
		var target_lift: float = 61.0 if mode == &"run" else (31.0 if mode == &"backward" else 46.0)
		_stride = lerpf(_stride, target_stride, 1.0 - exp(-delta * 9.0))
		_lift = lerpf(_lift, target_lift, 1.0 - exp(-delta * 9.0))
		_phase = fposmod(_phase + absf(travel) * ART_SCALE / _stride, 1.0)
	_moving = walking
	if mode != &"idle":
		_settling_foot = -1
	for index: int in LEG_CHAINS.size():
		var phase: float = fposmod(_phase + index * 0.5, 1.0)
		var previous: float = fposmod(previous_phase + index * 0.5, 1.0)
		_feet[index].x -= travel
		if walking and phase >= STANCE:
			if not _swinging[index] or phase < previous:
				_swing_from[index] = _feet[index] + Vector2(travel, 0.0)
				_swing_goal[index] = _rest_feet[index] + Vector2(direction * _stride * STANCE / (2.0 * ART_SCALE), 0.0)
			_swinging[index] = true
			_swing_from[index].x -= travel
			var swing: float = (phase - STANCE) / (1.0 - STANCE)
			_feet[index] = _swing_from[index].lerp(_swing_goal[index], smoothstep(0.0, 1.0, swing))
			_feet[index].y -= sin(PI * swing) * _lift
		elif walking and _swinging[index]:
			var landing_fraction: float = phase / maxf(phase + 1.0 - previous, 0.01)
			_feet[index] = _swing_goal[index] - Vector2(travel * landing_fraction, 0.0)
			_swinging[index] = false
		elif not walking:
			_feet[index].y = move_toward(_feet[index].y, _rest_feet[index].y, delta * 420.0)
			_swinging[index] = false
			# A stagger is a reactive catch step. Keep the support leg pinned until it
			# needs to move, and move the free foot further back to catch the weight.
			var offset: float = _feet[index].x - _rest_feet[index].x
			var limit: float = (79.0 if index == 0 else 114.0) if mode == &"knockback" else 117.0
			if absf(offset) > limit:
				_feet[index].x = move_toward(_feet[index].x, _rest_feet[index].x + signf(offset) * limit, delta * 980.0)
				if mode == &"knockback" and index == 0:
					_feet[index].y = _rest_feet[index].y - 26.0 * sin(PI * clampf(_age / 0.23, 0.0, 1.0))


	if mode == &"idle":
		_settle_stance(travel, delta)


func _settle_stance(travel: float, delta: float) -> void:
	# After a push or stop, walk one misplaced boot back into stance while the
	# other is still supporting the body.
	if _settling_foot < 0:
		if _feet[0].y < _rest_feet[0].y or _feet[1].y < _rest_feet[1].y:
			return
		var near_error: float = _feet[0].distance_to(_rest_feet[0])
		var rear_error: float = _feet[1].distance_to(_rest_feet[1])
		if maxf(near_error, rear_error) < 35.0:
			return
		_settling_foot = 0 if near_error > rear_error else 1
		_settle_from = _feet[_settling_foot]
		_settle_age = 0.0
	else:
		_settle_from.x -= travel
	_settle_age += delta
	var weight: float = clampf(_settle_age / 0.19, 0.0, 1.0)
	var foot: int = _settling_foot
	_feet[foot] = _settle_from.lerp(_rest_feet[foot], smoothstep(0.0, 1.0, weight))
	_feet[foot].y -= 19.0 * sin(PI * weight)
	if weight >= 1.0:
		_settling_foot = -1


func _support_pelvis() -> void:
	# Lower the hips when a long step would otherwise pull a planted ankle off the floor.
	var pelvis: Bone2D = _bones[&"Pelvis"]
	var height: float = pelvis.position.y
	for index: int in LEG_CHAINS.size():
		if _feet[index].y < _rest_feet[index].y - 0.1:
			continue
		var chain: Array = LEG_CHAINS[index]
		var hip: Vector2 = _bones[chain[0]].position.rotated(pelvis.rotation)
		var reach: float = _bones[chain[1]].position.length() + _bones[chain[2]].position.length() - 4.0
		var horizontal: float = _feet[index].x - (pelvis.position.x + hip.x)
		var vertical: float = sqrt(maxf(1.0, reach * reach - horizontal * horizontal))
		height = maxf(height, _feet[index].y - vertical - hip.y)
	pelvis.position.y = minf(height, pelvis.position.y + 55.0)


func _place_leg(index: int, weight: float) -> void:
	var chain: Array = LEG_CHAINS[index]
	var thigh: Bone2D = _bones[chain[0]]
	var shin: Bone2D = _bones[chain[1]]
	var foot: Bone2D = _bones[chain[2]]
	var pelvis: Bone2D = _bones[&"Pelvis"]
	var target: Vector2 = _feet[index]
	var local_goal: Vector2 = (target - pelvis.position).rotated(-pelvis.rotation) - thigh.position
	var a: float = shin.position.length()
	var b: float = foot.position.length()
	var reach: float = clampf(local_goal.length(), absf(a - b) + 0.5, a + b - 0.4)
	# Both knees bend toward the direction of the chest in the original left-facing art.
	var knee: float = -acos(clampf((reach * reach - a * a - b * b) / (2.0 * a * b), -1.0, 1.0))
	var hip: float = local_goal.angle() - atan2(b * sin(knee), a + b * cos(knee))
	thigh.rotation = lerp_angle(thigh.rotation, hip - shin.position.angle(), weight)
	shin.rotation = lerp_angle(shin.rotation, hip + knee - thigh.rotation - foot.position.angle(), weight)
	var lift: float = _rest_feet[index].y - target.y
	foot.rotation = lerp_angle(foot.rotation, -pelvis.rotation - thigh.rotation - shin.rotation + lift * 0.003, weight)


func _ground_collapse(settle: float) -> void:
	var lowest: float = -INF
	for sprite: Sprite2D in _landmarks:
		var bounds: Rect2 = sprite.get_rect().grow(-5.0)
		var to_rig: Transform2D = _skeleton.global_transform.affine_inverse() * sprite.global_transform
		for corner: Vector2 in [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]:
			lowest = maxf(lowest, (to_rig * corner).y)
	_bones[&"Pelvis"].position.y -= lowest * (1.0 if lowest > 0.0 else settle)


func strike_segment(_strike: GrindStrike) -> PackedVector2Array:
	# Painted blade centerline from the guard to the tip.
	return PackedVector2Array([
		_blade.to_global(Vector2(25, 44)),
		_blade.to_global(Vector2(25, 246)),
	])


func _update_slash(strike: GrindStrike, age: float) -> void:
	if strike != null and age >= strike.contact_start and age <= strike.contact_end:
		_arc = inverse_lerp(strike.contact_start, strike.contact_end, age)
		_heavy_arc = strike.heavy
		queue_redraw()
	elif _arc >= 0.0:
		_arc = -1.0
		queue_redraw()


func _draw() -> void:
	if _arc < 0.0:
		return
	var center: Vector2 = Vector2(_facing * (18.0 if _heavy_arc else 12.0), -145.0)
	var radius: Vector2 = Vector2(121.0, 35.0) if _heavy_arc else Vector2(91.0, 57.0)
	var sweep: float = 4.4 if _heavy_arc else 1.85
	var tone: Color = Color(0.75, 0.36, 0.87, sin(PI * _arc) * 0.74)
	for index: int in range(1, 29):
		var start: float = -1.25 + _arc * 1.7 + sweep * (index - 1) / 28.0
		var end: float = start + sweep / 28.0
		var a: Vector2 = Vector2.from_angle(start) * radius
		var b: Vector2 = Vector2.from_angle(end) * radius
		a.x *= _facing
		b.x *= _facing
		var taper: float = sin(PI * index / 29.0)
		draw_line(center + a, center + b, Color(tone, tone.a * taper), 1.0 + 4.0 * taper, true)

func _build_clips() -> void:
	_clip(&"idle", [0.0, 0.48, 1.05, 1.64, 2.35], {
		&"Pelvis": [2, 1, 0, 3, 2], &"Spine": [-5, -8, -6, -4, -5],
		&"Chest": [1, 3, 2, -1, 1], &"Neck": [0, 1, 2, -2, 0], &"Head": [2, 3, -2, 3, 2],
		&"NearShoulder": [0, 2, 1, -1, 0], &"NearUpperArm": [9, 10, 13, 8, 9],
		&"NearForearm": [16, 19, 17, 14, 16], &"RearUpperArm": [11, 8, 10, 13, 11],
		&"RearForearm": [29, 34, 31, 27, 29], &"Weapon": [4, 6, 8, 4, 4],
		&"Headband": [2, -3, 4, 1, 2], &"ScarfEnd": [-6, 0, 9, -4, -6],
		&"Cloth": [2, -2, -1, 4, 2], &"ClothEnd": [0, -3, 2, 7, 0],
	}, [Vector2(5, 35), Vector2(10, 29), Vector2(0, 37), Vector2(-6, 38), Vector2(5, 35)], true)
	_clip(&"forward", [0.0, 0.25, 0.5, 0.75, 1.0], {
		&"Pelvis": [4, 0, -4, 0, 4], &"Spine": [-11, -9, -8, -10, -11],
		&"Chest": [-4, 0, 5, 0, -4], &"Neck": [4, 4, 4, 4, 4], &"Head": [5, 5, 1, 4, 5],
		&"NearUpperArm": [-12, 5, 22, 9, -12], &"RearUpperArm": [25, 9, -10, 9, 25],
		&"NearForearm": [23, 27, 33, 29, 23], &"RearForearm": [37, 30, 24, 31, 37],
		&"Headband": [-6, -9, -6, -8, -6], &"ScarfEnd": [-3, 8, 3, -6, -3],
		&"Cloth": [-3, -8, -5, -7, -3], &"ClothEnd": [3, 8, 4, -4, 3],
	}, [Vector2(-12, 44), Vector2(-16, 33), Vector2(-10, 44), Vector2(-15, 33), Vector2(-12, 44)], true)
	_clip(&"backward", [0.0, 0.25, 0.5, 0.75, 1.0], {
		&"Pelvis": [2, 3, -2, -3, 2], &"Spine": [4, 6, 4, 5, 4],
		&"Chest": [3, 0, -2, 0, 3], &"Neck": [-3, -4, -3, -4, -3], &"Head": [-2, -3, -2, -3, -2],
		&"NearUpperArm": [31, 34, 39, 34, 31], &"NearForearm": [53, 51, 47, 50, 53],
		&"RearUpperArm": [26, 19, 17, 22, 26], &"RearForearm": [62, 62, 66, 65, 62],
		&"Weapon": [-28, -27, -29, -28, -28], &"ScarfEnd": [1, -6, 1, 7, 1],
	}, [Vector2(14, 55), Vector2(16, 45), Vector2(10, 53), Vector2(12, 45), Vector2(14, 55)], true)
	_clip(&"run", [0.0, 0.25, 0.5, 0.75, 1.0], {
		&"Pelvis": [6, 0, -5, 0, 6], &"Spine": [-16, -15, -15, -16, -16],
		&"Chest": [-8, -3, 3, -3, -8], &"Neck": [8, 8, 8, 8, 8], &"Head": [7, 6, 4, 6, 7],
		&"NearUpperArm": [-26, 9, 37, 9, -26], &"NearForearm": [29, 44, 55, 43, 29],
		&"RearUpperArm": [33, 10, -37, 8, 33], &"RearForearm": [56, 42, 32, 41, 56],
		&"Headband": [-12, -8, -13, -8, -12], &"ScarfEnd": [-5, 12, 4, -11, -5],
		&"Cloth": [-7, -12, -8, -10, -7], &"ClothEnd": [5, 17, 5, -10, 5],
	}, [Vector2(-19, 67), Vector2(-29, 46), Vector2(-18, 63), Vector2(-29, 46), Vector2(-19, 67)], true)
	_clip(&"guard", [0.0, 0.46, 1.14], {
		&"Pelvis": [4, 5, 4], &"Spine": [-8, -7, -8], &"Chest": [5, 6, 5],
		&"Neck": [4, 3, 4], &"Head": [1, 1, 1], &"NearShoulder": [5, 6, 5],
		&"NearUpperArm": [43, 44, 43], &"NearForearm": [99, 96, 99],
		&"RearUpperArm": [35, 33, 35], &"RearForearm": [94, 96, 94],
		&"NearHand": [-9, -7, -9], &"Weapon": [-46, -48, -46], &"ScarfEnd": [3, 7, 3],
	}, [Vector2(13, 61), Vector2(15, 57), Vector2(13, 61)], true)
	# Pose changes bracket the authored contact window at 0.19–0.29 seconds.
	_clip(&"light", [0.0, 0.075, 0.16, 0.22, 0.28, 0.37, 0.56], {
		&"Pelvis": [2, 3, 7, -6, -9, -5, 2], &"Spine": [-5, -5, 4, -11, -18, -10, -5],
		&"Chest": [1, 4, 10, -6, -9, -5, 1], &"Neck": [0, 1, -4, 6, 8, 4, 0],
		&"Head": [2, 1, -6, 7, 9, 5, 2], &"NearShoulder": [0, -9, -13, 13, 17, 4, 0],
		&"NearUpperArm": [9, -13, -43, 71, 66, 39, 9],
		&"NearForearm": [16, 31, 44, 19, 19, 28, 16], &"NearHand": [0, -9, -16, 3, 17, 10, 0],
		&"Weapon": [4, 18, 29, -27, -20, -3, 4], &"RearUpperArm": [11, 17, 29, 33, 12, 19, 11],
		&"RearForearm": [29, 52, 60, 61, 48, 41, 29],
		&"Headband": [2, -2, -7, 6, 14, 8, 2], &"ScarfEnd": [-6, -4, 13, 17, -12, -17, -6],
		&"ClothEnd": [0, 3, 15, 19, -16, -12, 0],
	}, [Vector2(5, 35), Vector2(15, 42), Vector2(34, 54), Vector2(-26, 51),
		Vector2(-41, 59), Vector2(-24, 49), Vector2(5, 35)])
	# The heavy coils away, pivots through a flatter profile, and catches its weight.
	_clip(&"heavy", [0.0, 0.13, 0.29, 0.40, 0.49, 0.55, 0.68, 0.91], {
		&"Pelvis": [2, 9, 16, 9, -13, -17, -7, 2],
		&"Spine": [-5, -2, 4, -2, -17, -18, -9, -5], &"Chest": [1, 11, 17, 6, -9, -13, -5, 1],
		&"Neck": [0, -6, -8, -5, 8, 10, 5, 0], &"Head": [2, -6, -12, 2, 9, 10, 6, 2],
		&"NearShoulder": [0, -8, -20, -15, 18, 19, 8, 0],
		&"RearShoulder": [0, 14, 23, 25, -23, -20, -6, 0],
		&"NearUpperArm": [9, -26, -73, -93, 72, 73, 34, 9],
		&"NearForearm": [16, 26, 43, 73, 24, 38, 64, 16],
		&"NearHand": [0, 7, 31, 19, -10, 15, 21, 0],
		&"Weapon": [4, 8, 18, 39, -38, -37, -54, 4],
		&"RearUpperArm": [11, 28, 49, 52, 9, -21, 24, 11],
		&"RearForearm": [29, 59, 72, 79, 63, 32, 41, 29],
		&"Headband": [2, 4, 12, 17, 17, -22, -9, 2], &"ScarfEnd": [-6, 7, 19, 30, 26, -31, -14, -6],
		&"Cloth": [2, 10, 14, 9, 14, -17, -8, 2], &"ClothEnd": [0, 7, 14, 33, 25, -26, -16, 0],
	}, [Vector2(5, 35), Vector2(16, 43), Vector2(38, 64), Vector2(23, 77), Vector2(-23, 65),
		Vector2(-40, 61), Vector2(-23, 48), Vector2(5, 35)])
	_clip(&"hit", [0.0, 0.073, 0.15, 0.27], {
		&"Pelvis": [2, 6, 4, 2], &"Spine": [-5, 12, 8, -5], &"Chest": [1, 11, 5, 1],
		&"Neck": [0, -3, 8, 0], &"Head": [2, 6, -5, 2], &"Hair": [0, -5, 3, 0],
		&"NearUpperArm": [9, -17, -4, 9], &"NearForearm": [16, 34, 22, 16],
		&"RearForearm": [29, 55, 46, 29], &"ScarfEnd": [-6, -5, 17, -6],
	}, [Vector2(5, 35), Vector2(35, 45), Vector2(23, 46), Vector2(5, 35)])
	_clip(&"knockback", [0.0, 0.09, 0.22, 0.33, 0.42], {
		&"Pelvis": [2, 13, 8, 3, 2], &"Spine": [-5, 16, 12, 0, -5],
		&"Chest": [1, 14, 6, -3, 1], &"Neck": [0, 8, 0, 1, 0],
		&"Head": [2, 5, -10, 1, 2], &"NearUpperArm": [9, -35, -19, 17, 9],
		&"NearForearm": [16, 5, 43, 28, 16], &"RearForearm": [29, 37, 56, 42, 29],
		&"ScarfEnd": [-6, -18, 26, 15, -6], &"ClothEnd": [0, -11, 21, 3, 0],
	}, [Vector2(5, 35), Vector2(23, 33), Vector2(27, 63), Vector2(9, 54), Vector2(5, 35)])
	_clip(&"air", [0.0, 0.28, 0.6], {
		&"Spine": [-8, -3, -8], &"NearThigh": [30, 38, 19], &"NearShin": [-53, -65, -26],
		&"RearThigh": [19, 11, 18], &"RearShin": [-41, -58, -37],
		&"NearUpperArm": [22, 28, 22], &"NearForearm": [47, 53, 47], &"ScarfEnd": [8, -11, 8],
	}, [Vector2(0, 20), Vector2(0, 25), Vector2(0, 19)])
	_clip(&"defeat", [0.0, 0.13, 0.33, 0.63, 0.94], {
		&"Pelvis": [2, 12, 33, 71, 86], &"Spine": [-5, 11, 16, 9, 2],
		&"Chest": [1, 7, 13, 5, 1], &"Neck": [0, 6, -12, 4, -5], &"Head": [2, 1, -24, -9, 0],
		&"NearUpperArm": [9, -21, 15, 42, 27], &"NearForearm": [16, 38, 17, -22, -8],
		&"RearThigh": [7, 10, 17, -5, -7], &"RearShin": [-16, -14, -38, -17, -5],
		&"NearThigh": [13, 17, 28, 19, 14], &"NearShin": [-22, -30, -41, -19, -13],
		&"Headband": [2, -2, -16, -47, -91], &"ScarfEnd": [-6, 3, -18, -29, -11],
		&"Cloth": [0, -5, -19, -75, -140],
	}, [Vector2(5, 35), Vector2(22, 49), Vector2(40, 107), Vector2(67, 259), Vector2(106, 381)])


func _clip(clip_name: StringName, times: Array[float], angles: Dictionary, roots: Array[Vector2], loop: bool = false) -> void:
	var animation: Animation = Animation.new()
	animation.length = times.back()
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for bone_name: StringName in ROTATED:
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(String(get_path_to(_bones[bone_name])) + ":rotation"))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC_ANGLE)
		if angles.has(bone_name):
			var values: Array = angles[bone_name]
			for index: int in times.size():
				animation.track_insert_key(track, times[index], deg_to_rad(float(values[index])))
		else:
			animation.track_insert_key(track, 0.0, 0.0)
	var pelvis_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(pelvis_track, NodePath(String(get_path_to(_bones[&"Pelvis"])) + ":position"))
	animation.track_set_interpolation_type(pelvis_track, Animation.INTERPOLATION_CUBIC)
	for index: int in times.size():
		animation.track_insert_key(pelvis_track, times[index], roots[index])
	_library.add_animation(clip_name, animation)
