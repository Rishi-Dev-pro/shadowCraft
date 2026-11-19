extends RefCounted
## A lab-only ballistic jump. The rig supplies pose, while this clock supplies height and phase.

enum State { JUMP_START, RISING, AIRBORNE, FALLING, LANDING, LANDING_RECOVERY }

const LABELS: Array[String] = ["Jump Start", "Rising", "Airborne", "Falling", "Landing", "Landing Recovery"]
const START: float = 0.12
const APEX: float = 0.37
const FLIGHT: float = APEX * 2.0
const IMPACT: float = 0.085
const RECOVERY: float = 0.245
const TOTAL: float = START + FLIGHT + IMPACT + RECOVERY
const GRAVITY: float = 1560.0


static func state_at(time: float) -> State:
	if time < START:
		return State.JUMP_START
	var flight_time: float = time - START
	if flight_time < APEX - 0.065:
		return State.RISING
	if flight_time < APEX + 0.065:
		return State.AIRBORNE
	if flight_time < FLIGHT:
		return State.FALLING
	if flight_time < FLIGHT + IMPACT:
		return State.LANDING
	return State.LANDING_RECOVERY


static func height_at(time: float) -> float:
	var air: float = clampf(time - START, 0.0, FLIGHT)
	return 0.5 * GRAVITY * air * (FLIGHT - air)


static func compression_at(time: float) -> float:
	if time < START:
		return smoothstep(0.0, 0.075, time) * (1.0 - smoothstep(0.075, START, time))
	var contact: float = time - START - FLIGHT
	return smoothstep(0.0, IMPACT, contact) * (1.0 - smoothstep(IMPACT, IMPACT + RECOVERY, contact))
