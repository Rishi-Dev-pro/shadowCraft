extends RefCounted
## Lab-only attack timing and pose sampling. Times are seconds at 1× playback.

enum Kind { LIGHT, HEAVY, KICK }
enum Phase { PREPARATION, WIND_UP, ACCELERATION, IMPACT, FOLLOW_THROUGH, REPLANT, RECOVERY }

const NAMES: Array[String] = ["Light Attack", "Heavy Attack", "Front Kick"]
const PHASES: Array[String] = ["Preparation", "Wind-up", "Acceleration", "Impact", "Follow-through", "Replant", "Attack Recovery"]
const FAMILIES: Array[String] = ["jab", "heavy", "kick"]
const ENTRY: Array[float] = [0.042, 0.092, 0.068]
const ACCELERATION: Array[float] = [0.074, 0.219, 0.158]
const IMPACT: Array[float] = [0.113, 0.279, 0.228]
const FOLLOW_THROUGH: Array[float] = [0.148, 0.336, 0.283]
const REPLANT: float = 0.342
const RECOVERY: Array[float] = [0.216, 0.492, 0.462]
const TOTAL: Array[float] = [0.350, 0.700, 0.636]
const BUFFER_WINDOW: float = 0.120
# Authored key times, from the skeletal anchor back to that same anchor.
const KEYS: Array[Array] = [
	[0.042, 0.074, 0.096, 0.113, 0.133, 0.162, 0.188, 0.216],
	[0.092, 0.143, 0.199, 0.219, 0.279, 0.325, 0.370, 0.421, 0.462, 0.492],
	[0.068, 0.110, 0.158, 0.228, 0.271, 0.342, 0.402, 0.462],
]
# Easing strength within each painted interval. The times and key poses stay
# fixed, including the moment that ownership switches between painted keys.
const SEGMENT_EASE: Array[Array] = [
	[0.50, 0.0, 0.22, 0.0, 0.0, 0.42, 0.34],
	[0.42, 0.64, 0.48, 0.28, 0.40, 0.0, 0.48, 0.55, 0.44],
	[0.26, 0.48, 0.24, 0.0, 0.38, 0.36, 0.48],
]


static func segment_progress(kind: Kind, segment: int, progress: float) -> float:
	return lerpf(progress, smoothstep(0.0, 1.0, progress), SEGMENT_EASE[kind][segment])


static func phase(kind: Kind, time: float) -> Phase:
	if time >= RECOVERY[kind]:
		return Phase.RECOVERY
	if kind == Kind.KICK and time >= REPLANT:
		return Phase.REPLANT
	if time >= FOLLOW_THROUGH[kind]:
		return Phase.FOLLOW_THROUGH
	if time >= IMPACT[kind]:
		return Phase.IMPACT
	if time >= ACCELERATION[kind]:
		return Phase.ACCELERATION
	if kind != Kind.LIGHT and time >= ENTRY[kind]:
		return Phase.WIND_UP
	return Phase.PREPARATION


static func allows_buffer(kind: Kind, time: float, next: Kind) -> bool:
	return kind == Kind.LIGHT and next != Kind.KICK and time >= TOTAL[kind] - BUFFER_WINDOW
