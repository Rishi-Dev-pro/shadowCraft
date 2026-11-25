extends RefCounted
## Places each swing foot in world space while the opposite boot supports the body.

const Walk = preload("res://experimental/raezen_hybrid/training/walk_cycle.gd")

const WALK_SPEED: float = 115.0
const BACK_SPEED: float = 87.0
const RUN_SPEED: float = 210.0
const ACCELERATION: float = 1050.0
const BRAKING: float = 1250.0
const NEAR_REST_X: float = -75.0
const FAR_REST_X: float = 56.0
# Contact, load, pass, rise, then the opposite boot makes contact.
# Columns are distance phase, swing lift, ankle pitch and pelvis drop.
const WALK_KEYS: Array[Vector4] = [
	Vector4(0.00, 0.0, 0.0, 9.0),
	Vector4(0.13, 0.0, 0.0, 15.0),
	Vector4(0.32, 17.0, 15.0, 14.0),
	Vector4(0.53, 28.0, 4.0, 10.0),
	Vector4(0.78, 18.0, -10.0, 6.5),
	Vector4(1.00, 0.0, 0.0, 9.0),
]

var velocity: float = 0.0
var facing: float = 1.0
var direction: float = 1.0
var swing_index: int:
	get:
		return _swing

var _feet: Array[float] = [0.0, 0.0]
var _swing: int
var _from: float
var _to: float
var _progress: float = 1.0
var _length: float = 42.0
var _lift: float = 0.0
var _weight: float = 0.0
var _run: float = 0.0
var _cloth: float = 0.0
var _scale: float = 1.0
var _walk_mix: float = 0.0
var _walk_sample: Vector4
var _hair_follow: float
var _scarf_follow: float
var _walk: Walk = Walk.new()
var _authored_mix: float
var _rolling: float


func begin(body_x: float, visual_facing: float, travel_direction: float, scale: float, boot_offsets: Array[Vector2]) -> void:
	facing = visual_facing
	direction = travel_direction
	_scale = scale
	_feet[0] = body_x + (NEAR_REST_X + boot_offsets[0].x) * facing * scale
	_feet[1] = body_x + (FAR_REST_X + boot_offsets[1].x) * facing * scale
	_swing = 0 if (_feet[0] - _feet[1]) * direction < 0.0 else 1
	_swing = 1 - _swing
	_progress = 1.0
	velocity = 0.0
	_weight = 0.0
	_run = 0.0
	_cloth = 0.0
	_lift = 0.0
	_walk_mix = 0.0
	_walk_sample = WALK_KEYS[-1]
	_hair_follow = 0.0
	_scarf_follow = 0.0
	_walk.reset()
	_authored_mix = 0.0
	_rolling = 1.0


func step(body_x: float, travel: float, delta: float, continuing: bool, running: bool) -> bool:
	var advance: float = absf(travel)
	var reverse: bool = facing != direction
	_run = move_toward(_run, float(running and not reverse), delta * 4.0)
	_weight = move_toward(_weight, float(continuing or absf(velocity) > 4.0), delta * 8.0)
	_cloth = move_toward(_cloth, velocity * facing / RUN_SPEED, delta * 2.8)
	var stride_pulse: float = _weight * _walk_mix * sin(TAU * _progress)
	_hair_follow = lerpf(_hair_follow, 1.6 * stride_pulse - 2.4 * _cloth, 1.0 - exp(-11.0 * delta))
	_scarf_follow = lerpf(_scarf_follow, 3.5 * stride_pulse - 5.3 * _cloth, 1.0 - exp(-7.0 * delta))
	_authored_mix = move_toward(_authored_mix, 0.0 if reverse else 1.0 - _run, 9.0 * delta)
	_walk.follow_stride(_progress, _weight, delta)
	if _progress >= 1.0:
		if not continuing or advance < 0.01:
			_lift = 0.0
			_rolling = 0.0
			return absf(velocity) < 0.01
		_swing = 1 - _swing
		_length = 38.0 if reverse else lerpf(53.0, 76.0, _run)
		_length = lerpf(_length, Walk.STEP_DISTANCE, _authored_mix)
		_from = _feet[_swing]
		_to = body_x - travel + direction * _length * lerpf(1.39, Walk.TOUCHDOWN_AHEAD, _authored_mix)
		_progress = 0.0
	var settling: bool = not continuing and advance < 0.01
	_progress = minf(1.0, _progress + (delta * 7.0 if settling else advance / _length))
	_rolling = 1.0 if continuing else 1.0 - smoothstep(0.65, 1.0, _progress)
	_walk_mix = move_toward(_walk_mix, 0.0 if reverse else 1.0 - _run, 7.0 * delta)
	_walk_sample = _sample_walk(_progress)
	var swing: float = lerpf(smoothstep(0.0, 1.0, _progress),
		smoothstep(0.13, 1.0, _progress), _walk_mix)
	swing = lerpf(swing, Walk.swing_progress(_progress), _authored_mix)
	_feet[_swing] = lerpf(_from, _to, swing)
	var basic_lift: float = sin(PI * _progress) * (18.0 if reverse else lerpf(25.0, 40.0, _run))
	_lift = lerpf(basic_lift, _walk_sample.y, _walk_mix)
	return not continuing and absf(velocity) < 0.01 and _progress >= 1.0


static func _sample_walk(phase: float) -> Vector4:
	for index: int in range(1, WALK_KEYS.size()):
		var end: Vector4 = WALK_KEYS[index]
		if phase <= end.x:
			var start: Vector4 = WALK_KEYS[index - 1]
			return start.lerp(end, smoothstep(start.x, end.x, phase))
	return WALK_KEYS[-1]


func pose(body_x: float) -> Dictionary:
	var reverse: bool = direction != facing
	var arm: float = (-1.0 if _swing == 0 else 1.0) * cos(PI * _progress) * _weight
	var lean: float = (-2.0 if reverse else lerpf(5.0, 11.0, _run)) * _weight
	var raised: float = sin(PI * _progress) * _weight
	var drop: float = lerpf(9.0 + 7.0 * raised + 7.0 * _run, _walk_sample.w, _walk_mix)
	var hip_turn: float = arm * 1.9 * _walk_mix
	var foot_pitch: float = _walk_sample.z
	var pose_data: Dictionary = {
		"near": [(_feet[0] - body_x) / (facing * _scale) - NEAR_REST_X, -_lift if _swing == 0 else 0.0],
		"far": [(_feet[1] - body_x) / (facing * _scale) - FAR_REST_X, -_lift if _swing == 1 else 0.0],
		"pelvis": [2.0 * arm + hip_turn, drop],
		"angles": {
			"Pelvis": hip_turn,
			"Spine": lean - 2.0 * arm - hip_turn, "Chest": 2.2 * arm - hip_turn * 0.5,
			"Head": 2.0 * arm - lean * 0.65 + hip_turn * 0.5,
			"ArmNear": arm * (3.0 if reverse else 7.0), "ElbowNear": -3.0 * arm,
			"ArmFar": arm * (-4.0 if reverse else -12.0), "ElbowFar": 4.0 * arm,
			"FootNear": lerpf(-9.0 * raised, foot_pitch, _walk_mix) if _swing == 0 else 0.0,
			"FootFar": lerpf(-13.0 * raised, foot_pitch, _walk_mix) if _swing == 1 else 0.0,
			"HairTip": lerpf(-2.4 * _cloth, _hair_follow, _walk_mix),
			"ScarfTip": lerpf(-4.8 * _cloth - 0.6 * arm, _scarf_follow, _walk_mix),
			"Coat": _scarf_follow * 0.22 * _walk_mix,
		},
		"blade": 1.5 * arm - 2.0 * _run,
		"underlay": 0.85,
	}
	if _authored_mix <= 0.0:
		return pose_data
	var near: Vector2 = Vector2(pose_data["near"][0], 0.0)
	var far: Vector2 = Vector2(pose_data["far"][0], 0.0)
	var authored: Dictionary = _walk.pose(_progress, _swing, near, far, _weight, _rolling)
	if _authored_mix >= 1.0:
		return authored
	for field: String in ["near", "far", "pelvis"]:
		for axis: int in 2:
			pose_data[field][axis] = lerpf(pose_data[field][axis], authored[field][axis], _authored_mix)
	for joint: String in authored["angles"]:
		pose_data["angles"][joint] = lerpf(float(pose_data["angles"].get(joint, 0.0)),
			authored["angles"][joint], _authored_mix)
	for field: String in ["blade", "underlay"]:
		pose_data[field] = lerpf(pose_data[field], authored[field], _authored_mix)
	return pose_data
