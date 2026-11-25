extends RefCounted
## One step of the authored walk. The next step exchanges the support and swing legs.
## The reference supplies the motion poses, while the rig supplies the artwork.

const STEP_DISTANCE: float = 62.0
const TOUCHDOWN_AHEAD: float = 1.48
const TOE_RELEASE: float = 0.12

# Phase, pelvis drop, pelvis lead, and upper-body counter-swing.
const BODY: Array[Vector4] = [
	Vector4(0.00, 8.0, 2.5, 1.0),
	Vector4(0.17, 20.0, -1.5, 0.65),
	Vector4(0.47, 9.0, 0.0, 0.12),
	Vector4(0.76, 2.0, 5.0, -0.67),
	Vector4(1.00, 8.0, 2.5, -1.0),
]
const SUPPORT: Array[Vector3] = [
	Vector3(0.00, -13.0, 0.0),
	Vector3(0.20, 0.0, 0.0),
	Vector3(0.72, 0.0, 0.0),
	Vector3(1.00, 19.0, 0.0),
]
const SWING: Array[Vector3] = [
	Vector3(0.00, 19.0, 0.0),
	Vector3(0.12, 30.0, 0.0),
	Vector3(0.28, 24.0, 20.0),
	Vector3(0.48, 9.0, 43.0),
	Vector3(0.69, -9.0, 36.0),
	Vector3(0.86, -15.0, 15.0),
	Vector3(1.00, -13.0, 0.0),
]

var _hair: float
var _scarf: float


func reset() -> void:
	_hair = 0.0
	_scarf = 0.0


func follow_stride(phase: float, effort: float, delta: float) -> void:
	var wake: float = effort * sin(TAU * (phase - 0.13))
	_hair = lerpf(_hair, 1.7 * wake - effort * 1.6, 1.0 - exp(-12.0 * delta))
	_scarf = lerpf(_scarf, 4.4 * wake - effort * 3.3, 1.0 - exp(-7.0 * delta))


static func swing_progress(phase: float) -> float:
	return smoothstep(TOE_RELEASE, 1.0, phase)


func pose(phase: float, swing: int, near: Vector2, far: Vector2, effort: float, roll: float) -> Dictionary:
	var body: Vector4 = _body_at(phase)
	var swing_boot: Vector3 = _boot_at(SWING, phase)
	var support_boot: Vector3 = _boot_at(SUPPORT, phase)
	var near_boot: Vector3 = swing_boot if swing == 0 else support_boot
	var far_boot: Vector3 = swing_boot if swing == 1 else support_boot
	near_boot.y *= roll
	far_boot.y *= roll
	var counter: float = body.w * (-1.0 if swing == 0 else 1.0) * effort
	var hip_turn: float = 4.0 * counter
	return {
		"near": _ankle_target(near, near_boot, true),
		"far": _ankle_target(far, far_boot, false),
		"pelvis": [body.z + 3.5 * counter, body.y],
		"angles": {
			"Pelvis": hip_turn,
			"Spine": 5.5 - 1.1 * hip_turn, "Chest": -4.5 * counter,
			"Neck": 3.6 * counter, "Head": -3.9,
			"ArmNear": -13.0 * counter, "ElbowNear": 5.0 * counter,
			"ArmFar": 19.0 * counter, "ElbowFar": -8.0 * counter,
			"FootNear": near_boot.y, "FootFar": far_boot.y,
			"HairTip": _hair, "ScarfTip": _scarf, "Coat": 0.35 * _scarf,
		},
		"blade": 3.7 * counter - 2.0,
		"underlay": 1.0,
	}


static func sole_pivot(near: bool, pitch: float) -> Vector2:
	# The boot textures have different ankle-to-sole registrations.
	if near:
		return Vector2(-11.0 if pitch < 0.0 else 13.0, 36.0)
	return Vector2(-12.0 if pitch < 0.0 else 36.0, 34.0)


static func _ankle_target(flat: Vector2, boot: Vector3, near: bool) -> Array[float]:
	var pivot: Vector2 = sole_pivot(near, boot.y)
	var ankle: Vector2 = flat + pivot - pivot.rotated(deg_to_rad(boot.y))
	return [ankle.x, ankle.y - boot.z]


static func _body_at(phase: float) -> Vector4:
	for i: int in range(1, BODY.size()):
		var next: Vector4 = BODY[i]
		if phase <= next.x:
			var previous: Vector4 = BODY[i - 1]
			return previous.lerp(next, smoothstep(previous.x, next.x, phase))
	return BODY[-1]


static func _boot_at(keys: Array[Vector3], phase: float) -> Vector3:
	for i: int in range(1, keys.size()):
		var next: Vector3 = keys[i]
		if phase <= next.x:
			var previous: Vector3 = keys[i - 1]
			return previous.lerp(next, smoothstep(previous.x, next.x, phase))
	return keys[-1]
