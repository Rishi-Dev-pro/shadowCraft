extends RefCounted
## Authored beats with shared timing for the body and its delayed cloth response.

const LOOP_SECONDS: float = 22.8


static func breath(time: float) -> float:
	var t: float = fposmod(time, LOOP_SECONDS)
	return (
		_beat(t, Vector4(1.45, 2.65, 2.77, 4.22))
		+ 0.72 * _beat(t, Vector4(8.10, 9.02, 9.17, 10.24))
		+ 0.85 * _beat(t, Vector4(16.62, 17.96, 18.06, 19.39))
	)


static func weight_shift(time: float) -> float:
	return _beat(fposmod(time, LOOP_SECONDS), Vector4(11.65, 12.69, 13.46, 14.73))


static func gaze(time: float) -> float:
	var t: float = fposmod(time, LOOP_SECONDS)
	return (
		1.63 * _beat(t, Vector4(5.09, 5.52, 6.25, 7.18))
		- 1.12 * _beat(t, Vector4(19.74, 20.04, 20.38, 21.07))
	)


static func _beat(time: float, keys: Vector4) -> float:
	# Settle completely between gestures, with zero velocity at either end.
	return smoothstep(keys.x, keys.y, time) * (1.0 - smoothstep(keys.z, keys.w, time))
