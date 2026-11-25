class_name GrindDuelist
extends CharacterBody2D

signal attack_committed(attack: GrindStrike)
signal strike_landed(point: Vector2, guarded: bool, heavy: bool)

const GRAVITY: float = 1530.0
const ACCELERATION: float = 2420.0
const FOOTWORK_MARGIN: float = 9.0
const GUARD_DAMAGE: float = 0.24
const GUARD_STUN: float = 0.52
const HURT_LAYER: int = 1 << 16

@export var data: GrindDuelistData
@onready var health: HealthComponent = $Health
@onready var hurtbox: Area2D = $Hurtbox
@onready var _visual: Node2D = $Visual
@onready var _body: CapsuleShape2D = $Body.shape as CapsuleShape2D
@onready var _hurt_shape: CollisionShape2D = $Hurtbox/Shape

var facing: float = 1.0
var guarding: bool = false
var _attack: GrindStrike
var _attack_time: float
var _attack_step: float
var _clean_contact: bool
var _combo_window: float
var _last_attack: StringName
var _dash_age: float
var _dash_direction: int
var _dash_facing: float
var _dash_cooldown: float
var _landing_time: float
var _turn_time: float
var _crouching: bool
var _hurt_capsule: CapsuleShape2D
var _hurt_standing_height: float
var _hurt_standing_center: float
var _spent: bool
var _cooldown: float
var _stun: float
var _push: float
var _reaction: StringName = &"hit"
var _strike_shape: CapsuleShape2D = CapsuleShape2D.new()
var _query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
var _shadow: Node2D
var _shadow_floor: float


func _ready() -> void:
	assert(data != null and data.light.is_valid() and data.heavy.is_valid())
	health.max_health = data.health
	health.restore_full()
	hurtbox.collision_layer = HURT_LAYER
	_hurt_capsule = _hurt_shape.shape.duplicate() as CapsuleShape2D
	_hurt_shape.shape = _hurt_capsule
	_hurt_standing_height = _hurt_capsule.height
	_hurt_standing_center = _hurt_shape.position.y
	_query.collide_with_areas = true
	_query.collide_with_bodies = false
	_query.collision_mask = HURT_LAYER
	_query.exclude = [hurtbox.get_rid()]
	_query.shape = _strike_shape
	_shadow_floor = position.y + 1.0
	_shadow = Node2D.new()
	_shadow.z_index = -13
	_shadow.draw.connect(_draw_ground_shadow)
	add_child(_shadow)


func _draw_ground_shadow() -> void:
	_shadow.draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.22))
	for radius: int in [61, 56, 47, 37]:
		_shadow.draw_circle(Vector2.ZERO, float(radius), Color(0.05, 0.026, 0.09, 0.15), true)
	_shadow.draw_set_transform(Vector2.ZERO)


func can_strike() -> bool:
	return (_attack == null and _stun <= 0.0 and _cooldown <= 0.0
		and _dash_direction == 0 and _landing_time <= 0.0 and is_on_floor() and not health.is_defeated)


func gap_to(opponent: GrindDuelist) -> float:
	return absf(opponent.global_position.x - global_position.x)


func minimum_spacing(opponent: GrindDuelist) -> float:
	return _body.radius + opponent._body.radius


func attack_distance(strike: GrindStrike, opponent: GrindDuelist) -> float:
	var hurt_radius: float = (opponent._hurt_shape.shape as CapsuleShape2D).radius
	return strike.reach + strike.contact_radius + hurt_radius + strike.step_distance


func is_attacking() -> bool:
	return _attack != null


func is_staggered() -> bool:
	return _stun > 0.0


func committed_heavy() -> bool:
	return _attack != null and _attack.heavy and _attack_time >= 0.12 and _attack_time < _attack.contact_start


func heavy_whiff_open() -> bool:
	return _attack != null and _attack.heavy and not _spent and _attack_time > _attack.contact_end


func can_dash() -> bool:
	return data.dash_speed > 0.0 and _dash_cooldown <= 0.0 and can_strike()


func _begin_strike(slot: int) -> bool:
	var strike: GrindStrike
	match slot:
		1: strike = data.cross if _combo_window > 0.0 and _last_attack == &"light" and data.cross != null else data.light
		2: strike = data.heavy
		3: strike = data.kick
	if strike == null:
		return false
	_attack = strike
	_attack_time = 0.0
	_attack_step = 0.0
	_spent = false
	_clean_contact = false
	_combo_window = 0.0
	attack_committed.emit(strike)
	return true


func _finish_strike() -> void:
	_cooldown = _attack.cooldown + (_attack.whiff_cooldown if not _spent else 0.0)
	_last_attack = _attack.animation
	_combo_window = data.combo_window if _clean_contact else 0.0
	_attack = null


func _update_crouch(active: bool) -> void:
	if _crouching == active:
		return
	_crouching = active
	var reduction: float = 50.0 if active else 0.0
	_hurt_capsule.height = _hurt_standing_height - reduction
	_hurt_shape.position.y = _hurt_standing_center + reduction * 0.5


func step(
	delta: float, opponent: GrindDuelist, movement: float = 0.0, sprint: bool = false,
	guard: bool = false, jump: bool = false, strike: int = 0,
	crouch: bool = false, dash: int = 0
) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_stun = maxf(0.0, _stun - delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_landing_time = maxf(0.0, _landing_time - delta)
	_turn_time = maxf(0.0, _turn_time - delta)
	var grounded: bool = is_on_floor()
	var toward: float = signf(opponent.global_position.x - global_position.x)
	var responsive: bool = (not health.is_defeated and _attack == null and _stun <= 0.0
		and _dash_direction == 0 and _landing_time <= 0.0)
	if responsive and gap_to(opponent) > 1.0:
		if data.crouch_enabled and facing != toward and grounded:
			_turn_time = 0.14
		facing = toward
	guarding = responsive and guard and grounded
	_update_crouch(data.crouch_enabled and responsive and grounded and crouch and not guarding)
	if dash != 0 and not guarding and not _crouching and can_dash():
		_dash_direction = signi(dash)
		_dash_facing = facing
		_dash_age = 0.0
		responsive = false
	if strike > 0 and responsive and not guarding and not _crouching and can_strike():
		responsive = not _begin_strike(strike)
	if _attack != null:
		_attack_time += delta
		if _attack_time >= _attack.duration:
			_finish_strike()

	var walk_speed: float = data.walk if movement * facing >= 0.0 else data.walk * 0.76
	var run: bool = sprint and movement * facing > 0.0
	var desired: float = movement * (data.run if run else walk_speed) if responsive and not guarding and not _crouching else 0.0
	if jump and data.jump > 0.0 and responsive and not guarding and not _crouching and grounded:
		velocity.y = -data.jump
	elif not grounded:
		velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, desired, ACCELERATION * delta)
	var clearance: float = gap_to(opponent) - minimum_spacing(opponent)
	if _attack != null:
		# Commit to the strike and spend a short step during anticipation.
		var slide: float = smoothstep(_attack.contact_start * 0.32, _attack.contact_start, _attack_time)
		var step_target: float = _attack.step_distance * slide
		var step_travel: float = maxf(step_target - _attack_step, 0.0)
		_attack_step = step_target
		velocity.x = facing * minf(step_travel, maxf(clearance - 2.0, 0.0)) / delta
	elif _dash_direction != 0:
		_dash_age += delta
		var burst: float = clampf(_dash_age / data.dash_duration, 0.0, 1.0)
		velocity.x = _dash_direction * _dash_facing * data.dash_speed * sin(PI * burst)
		if _dash_age >= data.dash_duration + data.dash_recovery:
			_dash_direction = 0
			_dash_cooldown = data.dash_cooldown
	if _attack == null and grounded and opponent.is_on_floor() and velocity.x * toward > 0.0:
		# Brake before the collision capsules meet. A retreat remains unrestricted.
		var room: float = maxf(clearance - FOOTWORK_MARGIN, 0.0)
		var speed_limit: float = minf(sqrt(2.0 * ACCELERATION * room), room / delta)
		velocity.x = toward * minf(absf(velocity.x), speed_limit)
	if absf(_push) > 0.1:
		velocity.x = _push
		_push = move_toward(_push, 0.0, 610.0 * delta)
	var before: float = position.x
	move_and_slide()
	if not grounded and is_on_floor():
		_landing_time = data.landing_recovery
	_shadow.position.y = maxf(0.0, _shadow_floor - position.y)
	var traveled: float = position.x - before
	_visual.call(&"drive", _visual_mode(traveled, run), facing, traveled, delta, _attack, _attack_time)


func resolve_strike(opponent: GrindDuelist) -> void:
	if _attack == null or _spent or opponent.health.is_defeated:
		return
	if _attack_time < _attack.contact_start or _attack_time > _attack.contact_end:
		return
	if (opponent.global_position.x - global_position.x) * facing <= 0.0:
		return
	var segment: PackedVector2Array = _visual.call(&"strike_segment", _attack)
	var arc: Vector2 = segment[1] - segment[0]
	_strike_shape.radius = _attack.contact_radius
	_strike_shape.height = arc.length() + 2.0 * _attack.contact_radius
	_query.transform = Transform2D(arc.angle() - PI * 0.5, segment[0].lerp(segment[1], 0.5))
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(_query, 2)
	for hit: Dictionary in hits:
		if hit.get("collider") != opponent.hurtbox:
			continue
		_spent = true
		var heavy: bool = _attack.heavy
		var contact: Vector2 = Geometry2D.get_closest_point_to_segment(
			opponent._hurt_shape.global_position, segment[0], segment[1])
		var blocked: bool = opponent.receive_strike(_attack, self)
		_clean_contact = not blocked
		strike_landed.emit(contact, blocked, heavy)
		return


func receive_strike(strike: GrindStrike, source: GrindDuelist) -> bool:
	var from: float = signf(source.global_position.x - global_position.x)
	var blocked: bool = guarding and from == facing
	var taken: float = health.apply_damage(strike.damage * (GUARD_DAMAGE if blocked else 1.0), source)
	if taken <= 0.0:
		return blocked
	_push = -from * strike.push * (0.38 if blocked else 1.0)
	if not blocked or health.is_defeated:
		if _attack != null:
			_cooldown = maxf(_cooldown, _attack.cooldown)
		_attack = null
		_combo_window = 0.0
		if _dash_direction != 0:
			_dash_direction = 0
			_dash_cooldown = data.dash_cooldown
		guarding = false
		_stun = strike.stun * (GUARD_STUN if blocked else 1.0)
		_reaction = &"guard" if blocked else (&"knockback" if strike.heavy else &"hit")
	if health.is_defeated:
		_visual.call(&"drive", &"defeat", facing, 0.0, 0.0)
	return blocked


func _visual_mode(traveled: float, sprint: bool) -> StringName:
	if health.is_defeated:
		return &"defeat"
	if _stun > 0.0:
		return _reaction
	if _attack != null:
		return _attack.animation
	if _dash_direction != 0:
		return &"dash_forward" if _dash_direction > 0 else &"dash_backward"
	if guarding:
		return &"guard"
	if _crouching:
		return &"crouch"
	if _landing_time > 0.0:
		return &"landing"
	if not is_on_floor():
		return &"air"
	if absf(traveled) < 0.15:
		return &"turn" if _turn_time > 0.0 else &"idle"
	if traveled * facing < 0.0:
		return &"backward"
	return &"run" if sprint else &"forward"
