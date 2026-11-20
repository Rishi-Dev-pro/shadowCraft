extends RefCounted
## Grounded reaction and foot-contact timing for the experimental lab.

enum Kind { STANDARD, HEAVY, KNOCKBACK, GUARD }
enum SourceSide { FRONT, BACK }
enum Phase { IMPACT, RECOIL, STAGGER, RECOVERY }

const NAMES: Array[String] = ["Standard Hit", "Heavy Hit", "Knockback", "Guard Impact"]
const PHASES: Array[String] = ["Impact", "Recoil", "Stagger Recovery", "Recovery"]
const CONTACT: Array[float] = [0.067, 0.100, 0.110, 0.066]
const TOTAL: Array[float] = [0.360, 0.740, 0.780, 0.330]
const STAGGER: Array[float] = [0.36, 0.265, 0.335, 0.33]
const RECOVERY: Array[float] = [0.168, 0.554, 0.560, 0.151]
const PUSH_TIME: float = 0.310
const PUSH_DISTANCE: float = 66.0

var kind: Kind
var side: SourceSide
var time: float = 0.0
var moved: float = 0.0
var blocked: bool = false
var planned_travel: float = 0.0
var starts_guarded: bool = false
var returns_to_guard: bool = false


func direction() -> float:
	return -1.0 if side == SourceSide.FRONT else 1.0


func phase() -> Phase:
	if time < CONTACT[kind]:
		return Phase.IMPACT
	if time >= RECOVERY[kind]:
		return Phase.RECOVERY
	return Phase.RECOIL if time < STAGGER[kind] else Phase.STAGGER


func force(delay: float = 0.0) -> float:
	var clock: float = time - delay
	var load: float = smoothstep(0.0, CONTACT[kind], clock)
	return load * (1.0 - smoothstep(CONTACT[kind], RECOVERY[kind], clock))


func catch_balance() -> float:
	var span: float = RECOVERY[kind] - STAGGER[kind]
	if span <= 0.0:
		return 0.0
	var progress: float = clampf((time - STAGGER[kind]) / span, 0.0, 1.0)
	return pow(sin(PI * progress), 2)


func settle() -> float:
	return 1.0 - smoothstep(RECOVERY[kind], TOTAL[kind], time)


func travel() -> float:
	if kind != Kind.KNOCKBACK:
		return 0.0
	var progress: float = clampf(time / PUSH_TIME, 0.0, 1.0)
	# Rapid pickup followed by braking. This cumulative curve ends exactly
	# at the configured displacement when the collision sweep is clear.
	return planned_travel * (1.0 - pow(1.0 - progress, 2.6))


func foot(rear: bool) -> Vector2:
	if kind != Kind.KNOCKBACK:
		return Vector2.ZERO
	var leads: bool = rear == (side == SourceSide.FRONT)
	var start: float = 0.022 if leads else 0.176
	var end: float = 0.176 if leads else PUSH_TIME
	var swing: float = smoothstep(start, end, time)
	var destination: float = moved if blocked else planned_travel
	var lift: float = (11.0 if leads else 7.0) * sin(PI * swing) * absf(destination) / PUSH_DISTANCE
	return Vector2(destination * swing - moved, -lift)
