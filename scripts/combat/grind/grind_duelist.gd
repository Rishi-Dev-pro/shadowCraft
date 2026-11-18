class_name GrindDuelist
extends CharacterBody2D

signal strike_landed(point: Vector2, guarded: bool, heavy: bool)

const GRAVITY: float = 1530.0
const GUARD_DAMAGE: float = 0.24
const HURT_LAYER: int = 1 << 16

@export var data: GrindDuelistData
@onready var health: HealthComponent = $Health
@onready var hurtbox: Area2D = $Hurtbox
@onready var _visual: Node2D = $Visual

var facing: float = 1.0
var guarding: bool = false
var _attack: GrindStrike
var _attack_time: float
var _spent: bool
var _cooldown: float
var _stun: float
var _push: float
var _reaction: StringName = &"hit"
var _strike_shape: RectangleShape2D = RectangleShape2D.new()
var _query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
var _shadow: Node2D
var _shadow_floor: float


func _ready() -> void:
	assert(data != null and data.light.is_valid() and data.heavy.is_valid())
	health.max_health = data.health
	health.restore_full()
	hurtbox.collision_layer = HURT_LAYER
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
	return _attack == null and _stun <= 0.0 and _cooldown <= 0.0 and is_on_floor() and not health.is_defeated


func step(
	delta: float, opponent: GrindDuelist, movement: float = 0.0, sprint: bool = false,
	guard: bool = false, jump: bool = false, strike: int = 0
) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_stun = maxf(0.0, _stun - delta)
	var grounded: bool = is_on_floor()
	var responsive: bool = not health.is_defeated and _attack == null and _stun <= 0.0
	if responsive and absf(opponent.position.x - position.x) > 1.0:
		facing = signf(opponent.position.x - position.x)
	guarding = responsive and guard and grounded
	if strike > 0 and not guarding and can_strike():
		_attack = data.heavy if strike == 2 else data.light
		_attack_time = 0.0
		_spent = false
		responsive = false
	if _attack != null:
		_attack_time += delta
		if _attack_time >= _attack.duration:
			_cooldown = _attack.cooldown
			_attack = null

	var walk_speed: float = data.walk if movement * facing >= 0.0 else data.walk * 0.76
	var run: bool = sprint and movement * facing > 0.0
	var desired: float = movement * (data.run if run else walk_speed) if responsive and not guarding else 0.0
	if jump and data.jump > 0.0 and responsive and not guarding and grounded:
		velocity.y = -data.jump
	elif not grounded:
		velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, desired, 2420.0 * delta)
	if absf(_push) > 0.1:
		velocity.x = _push
		_push = move_toward(_push, 0.0, 700.0 * delta)
	var before: float = position.x
	move_and_slide()
	_shadow.position.y = maxf(0.0, _shadow_floor - position.y)
	var traveled: float = position.x - before
	_visual.call(&"drive", _visual_mode(traveled, run), facing, traveled, delta)


func resolve_strike(opponent: GrindDuelist) -> void:
	if _attack == null or _spent or opponent.health.is_defeated:
		return
	if _attack_time < _attack.contact_start or _attack_time > _attack.contact_end:
		return
	_strike_shape.size = _attack.extent
	_query.transform = Transform2D(0.0, global_position + Vector2(_attack.center.x * facing, _attack.center.y))
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(_query, 2)
	for hit: Dictionary in hits:
		if hit.get("collider") != opponent.hurtbox:
			continue
		_spent = true
		var heavy: bool = _attack.heavy
		var contact: Vector2 = Vector2(lerpf(global_position.x, opponent.global_position.x, 0.79), opponent.global_position.y - 139.0)
		var blocked: bool = opponent.receive_strike(_attack, self)
		strike_landed.emit(contact, blocked, heavy)
		return


func receive_strike(strike: GrindStrike, source: GrindDuelist) -> bool:
	var from: float = signf(source.position.x - position.x)
	var blocked: bool = guarding and from == facing
	var taken: float = health.apply_damage(strike.damage * (GUARD_DAMAGE if blocked else 1.0), source)
	if taken <= 0.0:
		return blocked
	_push = -from * strike.push * (0.38 if blocked else 1.0)
	if not blocked or health.is_defeated:
		_attack = null
		guarding = false
		_stun = strike.stun
		_reaction = &"knockback" if strike.heavy else &"hit"
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
	if guarding:
		return &"guard"
	if not is_on_floor():
		return &"air"
	if absf(traveled) < 0.15:
		return &"idle"
	if traveled * facing < 0.0:
		return &"backward"
	return &"run" if sprint else &"forward"
