extends RefCounted
## Side-view study. One sample per top-row drawing, from left contact to left reach.
## All spatial keys are in the registered 512 px character canvas.
const CYCLE_SECONDS: float = 4.0 / 3.0
const FLOOR_Y: float = 485.0

# Absolute ankle X, bottom-of-boot clearance, sole pitch. Near is the sword-hand
# side (the right knee lifted in drawing 3). Far carries the first left contact.
const NEAR: Array[Vector3] = [
	Vector3(153.3, 0, 20), Vector3(162.5, 0, 12), Vector3(280.5, 96, 64), Vector3(349.5, 4.65, -25),
	Vector3(337.2, 0, -21), Vector3(268.3, 0, 1), Vector3(234.5, 0, 3), Vector3(167.1, 0, 26),
]
const FAR: Array[Vector3] = [
	Vector3(329.5, 0, -30), Vector3(331.1, 0, -14), Vector3(216.2, 0, 3), Vector3(168.7, 0, 32),
	Vector3(167.1, 0, 17), Vector3(217.7, 15.5, 70), Vector3(197.8, 26, 66), Vector3(344.9, 4.65, -30),
]
# Midpoint between the two projected sockets, and hip-to-neck forward inclination.
const BODY: Array[Vector3] = [
	Vector3(253.7, 257, 6.8), Vector3(257.1, 269, 4.7), Vector3(251.5, 257, 12.9), Vector3(261.3, 257, 10.1),
	Vector3(258.9, 258, 8.1), Vector3(257, 280, 9.1), Vector3(253.1, 264, 11.3), Vector3(258.8, 257, 8.1),
]
const ARM_SWING: Array[float] = [-3.0, -2.0, 3.0, 5.0, 4.0, 1.0, -1.0, -4.0]
# Lower hulls of each painted boot in its level, ankle-relative coordinates.
const NEAR_SOLE: Array[Vector2] = [
	Vector2(-19.6, 33.3), Vector2(-17.7, 34), Vector2(-9.5, 34.9), Vector2(22.1, 35.7),
	Vector2(31.9, 35), Vector2(37.7, 33.9), Vector2(51.7, 30.5), Vector2(54.6, 28.4),
]
const FAR_SOLE: Array[Vector2] = [
	Vector2(-19, 32), Vector2(-18, 33), Vector2(-9, 34), Vector2(13, 35),
	Vector2(45, 35), Vector2(49, 34), Vector2(50, 33),
]

static func sample(seconds: float) -> Dictionary:
	var key: float = fposmod(seconds, CYCLE_SECONDS) * 8.0 / CYCLE_SECONDS
	var i: int = floori(key) % 8
	var next: int = (i + 1) % 8
	var u: float = key - floorf(key)
	var near_boot: Vector3 = _roll_contact(NEAR, key, true)
	var far_boot: Vector3 = _roll_contact(FAR, key, false)
	var body: Vector3 = _curve(BODY, i, u)
	body.y = 0.6 * body.y + 0.2 * (_body_at(key - 0.32).y + _body_at(key + 0.32).y)
	var swing: float = lerpf(ARM_SWING[i], ARM_SWING[next], smoothstep(0, 1, u))
	var turn: float = swing * 0.28
	var lean: float = body.z
	# Inclination is measured from the hip line. The spine pivots partway up
	# that line, so it needs a larger turn to put the neck over the traced point.
	var spine_correction: float = 4.0 + 0.19 * lean
	var hair_lag: Vector3 = _body_at(key - 0.30) - body
	var scarf_lag: Vector3 = _body_at(key - 0.62) - body
	var shoulders: float = -0.55 * turn
	# The free (far) arm advances with the opposite, sword-side leg. Let
	# the upper arm lead the bracer, then the glove, through each reversal.
	var phase: float = key * TAU / 8.0
	var reach: float = -cos(phase + 0.10)
	var forearm: float = -cos(phase - 0.18)
	var wrist: float = -cos(phase - 0.35)
	return {
		"near": _ankle(near_boot, true), "far": _ankle(far_boot, false),
		"pelvis": [body.x - 251.0, body.y - 253.0],
		"angles": {
			"Pelvis": turn, "Spine": lean * 1.38 + spine_correction - turn, "Chest": -0.20 * lean,
			"ShoulderNear": shoulders, "ShoulderFar": -shoulders - 2.0 * reach,
			"Neck": -0.32 * lean - 0.65 * spine_correction, "Head": -0.48 * lean,
			"ArmNear": -0.74 * lean + swing - spine_correction, "ElbowNear": -2.0 + 1.4 * forearm,
			"ArmFar": 7.0 - 11.5 * reach - 0.5 * lean,
			"ElbowFar": -9.0 - 4.0 * forearm,
			"WristFar": 3.0 + 2.5 * wrist, "HandFar": 1.0 * wrist,
			"FootNear": near_boot.z, "FootFar": far_boot.z,
			"HairTip": 0.16 * hair_lag.y + 0.12 * hair_lag.z + 0.10 * hair_lag.x,
			"ScarfTip": 0.19 * scarf_lag.y + 0.16 * scarf_lag.z + 0.16 * scarf_lag.x,
			"Coat": 0.09 * scarf_lag.y,
		},
		"blade": 10.0,
		"underlay": 1.0,
	}

static func _body_at(key: float) -> Vector3:
	var wrapped: float = fposmod(key, 8.0)
	return _curve(BODY, floori(wrapped), fposmod(wrapped, 1.0))


static func _roll_contact(keys: Array[Vector3], key: float, near: bool) -> Vector3:
	var leg_key: float = _high_pass_time(key) if near else key
	var boot: Vector3 = _curve(keys, floori(leg_key) % 8, fposmod(leg_key, 1.0))
	var contact: int = 4 if near else 0
	var phase: float = fposmod(key - contact, 8.0)
	# Set the heel before touchdown, hold its world X as the sole rolls down,
	# then hand back to the existing in-place path as the body passes over it.
	var weight: float = smoothstep(7.55, 8.0, phase) if phase > 7.0 else 1.0 - smoothstep(0.65, 1.85, phase)
	var heel: Vector2 = sole_contact(near, keys[contact].z)
	var planted_x: float = keys[contact].x + heel.rotated(deg_to_rad(keys[contact].z)).x
	boot.x = lerpf(boot.x, planted_x - heel.rotated(deg_to_rad(boot.z)).x, weight)
	return boot

# Give the high passing knee more time to fold and extend between the same
# two heel strikes. Hermite slopes join the surrounding stance at unit speed.
static func _high_pass_time(key: float) -> float:
	const TIMES: Array[float] = [0.0, 0.7, 2.0, 3.45, 4.0]
	const SLOPES: Array[float] = [1.0, 1.0, 0.73, 1.0, 1.0]
	for i: int in 4:
		if key < TIMES[i + 1]:
			var span: float = TIMES[i + 1] - TIMES[i]
			var u: float = (key - TIMES[i]) / span
			return i + smoothstep(0, 1, u) + span * u * (1.0 - u) * (
				(1.0 - u) * SLOPES[i] - u * SLOPES[i + 1])
	return key

# A periodic monotone Hermite spline moves through intermediate drawings without
# stopping at each key or undershooting a ground-contact clearance.
static func _curve(keys: Array[Vector3], i: int, u: float) -> Vector3:
	var a: Vector3 = keys[i]
	var b: Vector3 = keys[(i + 1) % 8]
	var before: Vector3 = a - keys[(i + 7) % 8]
	var step: Vector3 = b - a
	var after: Vector3 = keys[(i + 2) % 8] - b
	var point: Vector3 = a.lerp(b, smoothstep(0, 1, u))
	for axis: int in 3:
		point[axis] += u * (1.0 - u) * ((1.0 - u) * _tangent(before[axis], step[axis]) - u * _tangent(step[axis], after[axis]))
	return point

static func _tangent(a: float, b: float) -> float:
	return 2.0 * a * b / (a + b) if a * b > 0.0 else 0.0

static func _ankle(boot: Vector3, near: bool) -> Array[float]:
	var rest: Vector2 = Vector2(181, 449) if near else Vector2(312, 451)
	var sole: Vector2 = sole_contact(near, boot.z).rotated(deg_to_rad(boot.z))
	return [boot.x - rest.x, FLOOR_Y - boot.y - sole.y - rest.y]

static func sole_contact(near: bool, pitch: float) -> Vector2:
	var sole: Array[Vector2] = NEAR_SOLE if near else FAR_SOLE
	var angle: float = deg_to_rad(pitch)
	var contact: Vector2 = sole[0]
	for point: Vector2 in sole:
		if point.rotated(angle).y > contact.rotated(angle).y:
			contact = point
	return contact

