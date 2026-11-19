extends RefCounted
## Two-step combat gait. Feet are stored in world coordinates relative to the
## neutral stance. Reversal and stops take effect at double support.

const FORWARD_TIME: float = 0.74
const BACKWARD_TIME: float = 0.84
const FORWARD_STRIDE: float = 35.0
const BACKWARD_STRIDE: float = 27.0

var direction: int = 0
var requested_direction: int = 0
var phase: float = 0.0
var origin: float = 0.0


func advance(delta: float) -> void:
	if direction == 0:
		direction = requested_direction
		if direction == 0:
			return
	phase += delta / _duration()
	while phase >= 1.0:
		var remainder: float = (phase - 1.0) * _duration()
		origin += _stride()
		direction = requested_direction
		phase = 0.0
		if direction == 0:
			return
		phase = remainder / _duration()


func travel() -> float:
	var eased: float = smoothstep(0.0, 1.0, phase)
	return origin + _stride() * lerpf(phase, eased, 0.50)


func foot(rear: bool) -> Vector2:
	if direction == 0:
		return Vector2(origin, 0.0)
	var forward: bool = direction > 0
	var leads: bool = rear != forward
	var takeoff: float = (0.05 if leads else 0.55) if forward else (0.03 if leads else 0.49)
	var landing: float = (0.46 if leads else 0.96) if forward else (0.38 if leads else 0.94)
	var swing: float = clampf(inverse_lerp(takeoff, landing, phase), 0.0, 1.0)
	var lift: float = (18.0 if leads else 14.0) if forward else (13.0 if leads else 11.0)
	return Vector2(origin + _stride() * smoothstep(0.0, 1.0, swing), -lift * pow(sin(PI * swing), 2.0))


func _stride() -> float:
	return FORWARD_STRIDE if direction > 0 else (-BACKWARD_STRIDE if direction < 0 else 0.0)


func _duration() -> float:
	return FORWARD_TIME if direction > 0 else BACKWARD_TIME
