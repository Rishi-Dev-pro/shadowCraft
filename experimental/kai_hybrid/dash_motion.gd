extends RefCounted
## Lab movement clock and grounded foot targets, in native pixels.

enum Kind { FORWARD, BACKWARD, EVASIVE }
enum Phase { PREPARATION, BURST, RECOVERY }

const NAMES: Array[String] = ["Forward Dash", "Backward Dash", "Evasive Dash"]
const Distances = preload("res://experimental/kai_hybrid/dash_distances.gd")
const DISTANCE: Array[float] = [Distances.FORWARD, -Distances.BACKWARD, -Distances.LOW_EVASION]
const POSE_STRIDE: Array[float] = [74.0, -62.0, -54.0]
const PREP: Array[float] = [0.052, 0.063, 0.072]
const BURST: Array[float] = [0.27, 0.245, 0.29]
const RECOVERY: Array[float] = [0.19, 0.21, 0.235]
const ACCEL_FRACTION: Array[float] = [0.29, 0.24, 0.35]

var kind: Kind = Kind.FORWARD
var time: float = 0.0
var rear_entry: Vector2 = Vector2.ZERO
var front_entry: Vector2 = Vector2.ZERO


func total() -> float:
	return PREP[kind] + BURST[kind] + RECOVERY[kind]


func phase() -> Phase:
	if time < PREP[kind]:
		return Phase.PREPARATION
	if time < PREP[kind] + BURST[kind]:
		return Phase.BURST
	return Phase.RECOVERY


func progress() -> float:
	var u: float = clampf((time - PREP[kind]) / BURST[kind], 0.0, 1.0)
	var peak: float = ACCEL_FRACTION[kind]
	if u < peak:
		return u * u / peak
	return 1.0 - (1.0 - u) * (1.0 - u) / (1.0 - peak)


func travel() -> float:
	return DISTANCE[kind] * progress()


func pose_travel() -> float:
	return POSE_STRIDE[kind] * progress()


func momentum(delay: float = 0.0) -> float:
	var u: float = clampf((time - delay - PREP[kind]) / BURST[kind], 0.0, 1.0)
	var peak: float = ACCEL_FRACTION[kind]
	var speed: float = u / peak if u < peak else (1.0 - u) / (1.0 - peak)
	return signf(DISTANCE[kind]) * speed


func foot(rear: bool) -> Vector2:
	var entry: Vector2 = rear_entry if rear else front_entry
	if time < PREP[kind]:
		return Vector2(entry.x, lerpf(entry.y, 0.0, smoothstep(0.0, PREP[kind], time)))
	var leads: bool = rear == (kind != Kind.FORWARD)
	var u: float = progress()
	var swing: float = clampf(inverse_lerp(0.01 if leads else 0.45, 0.44 if leads else 0.94, u), 0.0, 1.0)
	var lift: float = (10.0 if leads else 7.0) if kind != Kind.EVASIVE else (7.0 if leads else 5.0)
	return Vector2(lerpf(entry.x, POSE_STRIDE[kind], smoothstep(0.0, 1.0, swing)), -lift * pow(sin(PI * swing), 2.0))
