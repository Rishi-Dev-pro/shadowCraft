extends Node2D
## The trial reuses Kai's authored 512px art with local foot contacts and combat cues.

const MOTION: Dictionary[StringName, StringName] = {
	&"forward": &"walk_forward", &"backward": &"walk_backward", &"run": &"run",
}
const DISTANCE: Dictionary[StringName, float] = {&"forward": 125.0, &"backward": 109.0, &"run": 151.0}
const SOLE: Dictionary[StringName, Array] = {
	&"idle_signature": [503, 509, 503, 508, 504, 504, 504, 504],
	&"walk_forward": [507, 501, 503, 503, 500, 507, 500, 500],
	&"walk_backward": [502, 501, 501, 499, 492, 499, 498, 501],
	&"run": [502, 496, 495, 486, 500, 501, 501, 486],
	&"trial_guard": [507, 510, 509, 510],
	&"light_jab": [496, 497, 496, 496, 496, 496],
	&"heavy_punch": [495, 495, 495, 495, 495, 495, 495, 496, 496, 496],
	&"heavy_hit": [512, 512, 512, 512],
	&"defeated": [512, 512],
}
# Worldward root corrections calibrated against the support boot in each painted pose.
const CONTACT_SHIFT: Dictionary[StringName, Array] = {
	&"idle_signature": [0, -12, -13, -19, -3, -4, -5, -2],
	&"walk_forward": [-12, -22, 0, 5, 28, -18, -9, -12],
	&"walk_backward": [10, -5, 12, 21, 23, -20, -24, -13],
	&"run": [-16, 12, 24, -12, -21, 18, 22, -19],
	&"trial_guard": [-5, 2, -4, 3],
	&"heavy_hit": [0, -3, -11, 5],
}

@onready var _sprite: AnimatedSprite2D = $Fighter
var _outgoing: Sprite2D
var _pose: StringName
var _age: float = 0.0
var _phase: float = 0.0
var _origin: Vector2
var _crossfade: float = 0.08
var _facing: float = 1.0


func _ready() -> void:
	_sprite.stop()
	_outgoing = Sprite2D.new()
	_outgoing.z_index = -1
	add_child(_outgoing)
	_outgoing.hide()


func drive(pose: StringName, facing: float, travel: float, delta: float, strike: GrindStrike = null, strike_age: float = 0.0) -> void:
	if pose != _pose:
		_crossfade = 0.065 if pose in [&"light", &"heavy", &"hit", &"knockback"] else 0.09
		if not _pose.is_empty() and facing == _facing and pose not in [&"hit", &"knockback", &"defeat"]:
			_outgoing.texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
			_outgoing.position = _sprite.position
			_outgoing.flip_h = _sprite.flip_h
			_outgoing.show()
		else:
			_outgoing.hide()
		_origin = _sprite.position
		_pose = pose
		_age = 0.0
	else:
		_age += delta
	_facing = facing
	_sprite.flip_h = facing < 0.0

	var clip: StringName = &"idle_signature"
	var frame: int = int(_age * 6.0) % 8
	if MOTION.has(pose):
		_phase = fposmod(_phase + absf(travel) / DISTANCE[pose], 1.0)
		clip = MOTION[pose]
		frame = mini(int(_phase * 8.0), 7)
	elif strike != null:
		clip = &"heavy_punch" if strike.heavy else &"light_jab"
		frame = _strike_frame(strike, strike_age)
	else:
		match pose:
			&"guard":
				clip = &"trial_guard"
				frame = 0 if _age < 0.07 else (1 if _age < 0.14 else 2 + int(_age * 2.4) % 2)
			&"air":
				clip = &"jump"
				frame = mini(int(_age * 7.0), 3)
			&"hit":
				clip = &"heavy_hit"
				frame = 1 if _age < 0.09 else (3 if _age < 0.22 else 0)
			&"knockback":
				clip = &"heavy_hit"
				frame = 1 if _age < 0.06 else (2 if _age < 0.22 else (3 if _age < 0.37 else 0))
			&"defeat":
				clip = &"defeated"
				frame = 0 if _age < 0.20 else 1

	if _sprite.animation != clip:
		_sprite.animation = clip
	_sprite.frame = frame
	var foot_y: float = SOLE[clip][frame] if SOLE.has(clip) else 503.0
	var support_x: float = CONTACT_SHIFT[clip][frame] if CONTACT_SHIFT.has(clip) else 0.0
	var target: Vector2 = Vector2(support_x * facing, 256.0 - foot_y)
	if clip == &"run" and frame in [3, 7]:
		target.y -= 9.0 # Flight drawings keep their authored clearance.
	var factor: float = smoothstep(0.0, _crossfade, _age)
	_sprite.position = Vector2(lerpf(_origin.x, target.x, factor), target.y)
	if _outgoing.visible:
		_outgoing.modulate.a = 1.0 - factor
		_sprite.modulate.a = lerpf(0.62, 1.0, factor)
		if factor >= 1.0:
			_outgoing.hide()
	else:
		_sprite.modulate.a = 1.0


func strike_segment(strike: GrindStrike) -> PackedVector2Array:
	# Forearm and knuckle positions measured on Kai's painted active frames.
	var wrist: Vector2 = Vector2(109.0, -117.0)
	var knuckles: Vector2 = Vector2(146.0, -119.0)
	if strike.heavy:
		match _sprite.frame:
			4:
				wrist = Vector2(136.0, -110.0)
				knuckles = Vector2(180.0, -113.0)
			5:
				wrist = Vector2(147.0, -124.0)
				knuckles = Vector2(190.0, -128.0)
			_:
				wrist = Vector2(142.0, -121.0)
				knuckles = Vector2(185.0, -124.0)
	wrist.x *= _facing
	knuckles.x *= _facing
	return PackedVector2Array([_sprite.to_global(wrist), _sprite.to_global(knuckles)])


func _strike_frame(strike: GrindStrike, age: float) -> int:
	if age < strike.contact_start:
		var startup: float = age / strike.contact_start
		return mini(floori(startup * (4.0 if strike.heavy else 3.0)), 3 if strike.heavy else 2)
	if age <= strike.contact_end:
		var active: float = inverse_lerp(strike.contact_start, strike.contact_end, age)
		return 4 + mini(floori(active * 3.0), 2) if strike.heavy else 3
	var recovery: float = inverse_lerp(strike.contact_end, strike.duration, age)
	return 7 + mini(floori(recovery * 3.0), 2) if strike.heavy else 4 + mini(floori(recovery * 2.0), 1)
