extends RefCounted
## Holds a preview clock locally. Durations are seconds at 1× playback.

enum Profile { LIGHT, HEAVY, GUARD }

const MAX_SECONDS: float = 0.100

var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			clear()
var remaining: float = 0.0
var _seconds: Array[float] = [0.032, 0.061, 0.041]


func duration(profile: Profile) -> float:
	return _seconds[profile]


func configure(profile: Profile, seconds: float) -> void:
	_seconds[profile] = clampf(seconds, 0.0, MAX_SECONDS)


func request(profile: Profile) -> bool:
	if not enabled or remaining > 0.0 or duration(profile) <= 0.0:
		return false
	remaining = duration(profile)
	return true


func consume(delta: float) -> float:
	var held: float = minf(delta, remaining)
	remaining -= held
	return delta - held


func clear() -> void:
	remaining = 0.0
