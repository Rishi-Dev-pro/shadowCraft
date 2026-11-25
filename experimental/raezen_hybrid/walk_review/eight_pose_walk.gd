extends RefCounted
## Performance track over the archived eight-drawing study.
const Base = preload("res://experimental/raezen_hybrid/walk_review/free_arm_baseline.gd")
const CYCLE_SECONDS: float = Base.CYCLE_SECONDS
const STRIDE: float = 348.0
# Drawing times in fortieths of a cycle. The weapon-side step accepts load
# sooner and spends longer passing over the bent support knee.
const BEATS: Array[float] = [0, 3.6, 10.4, 16.2, 20.8, 24.1, 31.1, 36.3, 40]
# Belt shift, compression, chest pitch. The belt moves ahead of the shoulders.
const LOAD: Array[Vector3] = [
	Vector3(-1, 0, -1), Vector3(4, 3, 1), Vector3(2, -1, 0), Vector3(-2, 1, -1),
	Vector3(-3, 0, -1), Vector3(5, 4, 2), Vector3(1, -1, 1), Vector3(-2, 0, -1)]
# Upper arm, elbow and hand have separate accents. The elbow gathers under
# load and opens during release while the glove trails the change of direction.
const ARM: Array[Vector3] = [
	Vector3(14, -8, 2), Vector3(13, -6, 4), Vector3(2, -11, 3), Vector3(-7, -16, 0),
	Vector3(-9, -17, -2), Vector3(-6, -18, -1), Vector3(5, -13, 1), Vector3(11, -8, 2)]


static func drawing(seconds: float) -> float:
	var beat: float = fposmod(seconds / CYCLE_SECONDS, 1.0) * 40.0
	for i: int in 8:
		if beat < BEATS[i + 1]:
			var span: float = BEATS[i + 1] - BEATS[i]
			var u: float = (beat - BEATS[i]) / span
			var earlier: float = BEATS[i] - BEATS[i - 1] if i > 0 else 40.0 - BEATS[7]
			var later: float = BEATS[i + 2] - BEATS[i + 1] if i < 7 else BEATS[1]
			return i + smoothstep(0, 1, u) + span * u * (1-u) * (
				(1-u) * 2.0 / (earlier + span) - u * 2.0 / (span + later))
	return 0.0


static func _track(keys: Array[Vector3], key: float) -> Vector3:
	var phase: float = fposmod(key, 8.0)
	return Base._curve(keys, floori(phase), fposmod(phase, 1.0))


static func travel(seconds: float) -> float:
	return (floorf(seconds / CYCLE_SECONDS) + drawing(seconds) / 8.0) * STRIDE


static func sample(seconds: float, traveling: bool = false) -> Dictionary:
	var key: float = drawing(seconds)
	var pose: Dictionary = Base.sample(key * CYCLE_SECONDS / 8.0)
	var load_shift: Vector3 = _track(LOAD, key)
	var chest: Vector3 = _track(LOAD, key - 0.32)
	var arm: Vector3 = _track(ARM, key)
	var angles: Dictionary = pose["angles"]
	pose["pelvis"][0] += load_shift.x
	pose["pelvis"][1] = 6.0 + 0.72 * (pose["pelvis"][1] - 6.0) + load_shift.y
	angles["Pelvis"] += 0.34 * load_shift.x
	angles["Chest"] += chest.z - 0.38 * load_shift.x
	angles["Neck"] -= 0.55 * chest.z
	angles["ArmFar"] = arm.x - 0.42 * _track(Base.BODY, key).z
	angles["ElbowFar"] = _track(ARM, key - 0.23).y
	angles["WristFar"] = _track(ARM, key - 0.45).z
	angles["HandFar"] = 0.5 * _track(ARM, key - 0.66).z
	angles["ElbowNear"] += 0.45 * (chest.x - load_shift.x)
	angles["HairTip"] += 0.24 * (chest.z - load_shift.z)
	angles["ScarfTip"] += 0.25 * (_track(LOAD, key - 0.72).x - load_shift.x)
	angles["Coat"] += 0.16 * (_track(LOAD, key - 0.48).x - load_shift.x)
	for near: bool in [true, false]:
		var keys: Array[Vector3] = Base.NEAR if near else Base.FAR
		var boot: Vector3 = Base._roll_contact(keys, key, near)
		boot.y *= 0.80 if near else 0.95
		if traveling:
			var phase: float = fposmod(key - (4.0 if near else 0.0), 8.0)
			var contact: Vector3 = keys[4 if near else 0]
			# World-space stride advances only on swing. During support the
			# ankle rolls around the contacting heel, then the forefoot.
			var progress: float = smoothstep(4.0, 8.0, phase)
			var toe_off: float = 29.0 if near else 32.0
			if phase <= 4.0:
				boot.z = lerpf(contact.z, 0, smoothstep(0, 1.0, phase)) + toe_off * smoothstep(2.1, 4, phase)
				boot.y = 0.0
			elif phase < 5.0:
				boot.z = lerpf(toe_off, boot.z, smoothstep(4, 5, phase))
			var roll: float = _roll_distance(near, contact.z, boot.z)
			boot.x = contact.x + STRIDE * (progress - phase / 8.0) + roll
		angles["FootNear" if near else "FootFar"] = boot.z
		pose["near" if near else "far"] = Base._ankle(boot, near)
	return pose


static func _roll_distance(near: bool, start: float, finish: float) -> float:
	# Integrate the painted sole's support height over its roll angle.
	var step: float = (finish - start) / 12.0
	var distance: float = 0
	for i: int in 12:
		var pitch: float = start + (i + 0.5) * step
		var rad: float = deg_to_rad(pitch)
		distance += Base.sole_contact(near, pitch).rotated(rad).y * deg_to_rad(step)
	return distance
