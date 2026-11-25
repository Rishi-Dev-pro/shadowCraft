class_name CombatController
extends Node

signal combat_state_changed(previous: State, current: State)
signal attack_started(attack: AttackData)
signal attack_finished(attack: AttackData)
signal attack_chained(previous: AttackData, next: AttackData)
signal hit_landed(attack: AttackData, target: Hurtbox2D, damage: float)
signal defeat_pose_reached

enum State { NEUTRAL, STARTUP, ACTIVE, RECOVERY, HITSTUN, KNOCKDOWN, DOWNED, GETTING_UP, DEFEATED }

@export var moveset: MovesetData
## Legacy single-attack slots, used only when no moveset resource is assigned.
@export var punch_attack: AttackData
@export var kick_attack: AttackData

@export_group("Input Actions")
@export var light_attack_action: StringName = &"light_attack"
@export var kick_attack_action: StringName = &"kick_attack"
@export var heavy_attack_action: StringName = &"heavy_attack"
@export var roundhouse_attack_action: StringName = &"roundhouse_attack"

@export_group("Passive Defense")
@export_range(0.0, 0.8, 0.05) var passive_back_guard_reduction: float = 0.0

@export_group("Node Paths")
@export var movement_controller_path: NodePath = NodePath("..")
@export var sprite_path: NodePath = NodePath("../Skeleton2D/AnimatedSprite2D")
@export var hitbox_path: NodePath = NodePath("../PlayerHitbox")
@export var health_path: NodePath = NodePath("../HealthComponent")

@onready var movement_controller: CharacterController2D = get_node_or_null(movement_controller_path) as CharacterController2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(sprite_path) as AnimatedSprite2D
@onready var hitbox: Hitbox2D = get_node_or_null(hitbox_path) as Hitbox2D
@onready var health_component: HealthComponent = get_node_or_null(health_path) as HealthComponent

var current_state: State = State.NEUTRAL
var current_attack: AttackData
var phase_frame: int = 0
var hitstun_frames: int = 0
var chain_index: int = 0

var _hit_flash_frames: int = 0
var _physics_tick: int = 0
var _active_action: StringName = &""
var _chain_root: AttackData
var _buffered_input: CombatInputBuffer = CombatInputBuffer.new()
var _defeated_latched: bool = false
var _fall_animation_finished: bool = false
var _downed_timer: float = 0.0
var _defeat_pose_started: bool = false
var _base_damage_reduction: float = 0.0
var _is_passive_guarding: bool = false

const FALLBACK_BUFFER_TICKS: int = 8
const FALLBACK_CHAIN_WINDOW_TICKS: int = 4

func _ready() -> void:
	assert(movement_controller != null and animated_sprite != null and hitbox != null, "CombatController requires movement, sprite, and hitbox nodes")
	_validate_attack_animations()
	hitbox.target_hit.connect(_on_target_hit)
	if health_component != null:
		_base_damage_reduction = health_component.damage_reduction
		health_component.defeated.connect(_on_defeated)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	_update_movement_lock()

func _physics_process(_delta: float) -> void:
	_physics_tick += 1
	_update_passive_guard()
	if _hit_flash_frames > 0:
		_hit_flash_frames -= 1
		if _hit_flash_frames == 0 and animated_sprite != null:
			animated_sprite.modulate = Color.WHITE
	match current_state:
		State.NEUTRAL:
			_poll_neutral_start()
		State.HITSTUN:
			_poll_attack_buffer()
			hitstun_frames -= 1
			if hitstun_frames <= 0:
				var buffered_action: StringName = _buffered_input.peek_action()
				var buffer_is_valid: bool = buffered_action != &"" and _buffered_input.consume(buffered_action, _physics_tick, _buffer_ticks())
				_enter_neutral()
				if buffer_is_valid:
					_start_buffered_neutral_attack(buffered_action)
		State.KNOCKDOWN:
			if movement_controller.is_grounded and _fall_animation_finished:
				_enter_downed_state()
		State.DOWNED:
			movement_controller.velocity.x = 0.0
			movement_controller.velocity.y = 0.0
			_downed_timer -= _delta
			if _downed_timer <= 0.0 and not _is_defeated():
				_begin_getup()
		State.GETTING_UP:
			movement_controller.velocity.x = 0.0
		State.DEFEATED:
			movement_controller.velocity.x = 0.0
			if movement_controller.is_grounded:
				movement_controller.velocity.y = 0.0
				if _fall_animation_finished and animated_sprite.animation != &"defeated":
					_play_defeated_pose()
		State.STARTUP:
			_poll_attack_buffer()
			_advance_attack()
		State.ACTIVE, State.RECOVERY:
			_poll_attack_buffer()
			_advance_attack()

# --- Attack lifecycle ---------------------------------------------------------

func _advance_attack() -> void:
	phase_frame += 1
	if current_attack == null:
		_enter_neutral()
		return
	match current_state:
		State.STARTUP:
			if phase_frame >= current_attack.startup_frames:
				phase_frame = 0
				hitbox.set_active(true)
				hitbox.set_active_frame(0, movement_controller.is_facing_right)
				_change_state(State.ACTIVE)
		State.ACTIVE:
			hitbox.set_active_frame(phase_frame - 1, movement_controller.is_facing_right)
			if phase_frame >= current_attack.active_frames:
				hitbox.set_active(false)
				phase_frame = 0
				_change_state(State.RECOVERY)
		State.RECOVERY:
			if is_chain_window_open() and _try_chain_link():
				return
			if phase_frame >= current_attack.recovery_frames:
				var finished_attack: AttackData = current_attack
				current_attack = null
				_enter_neutral()
				attack_finished.emit(finished_attack)

func start_attack(data: AttackData) -> bool:
	if current_state != State.NEUTRAL or data == null or animated_sprite == null or movement_controller == null:
		return false
	if not movement_controller.is_grounded:
		return false
	if not data.can_start_from(is_crouched()):
		return false
	_begin_attack(data, _action_for_attack(data), false)
	return true

func _begin_attack(data: AttackData, action: StringName, chained: bool) -> void:
	var previous_attack: AttackData = current_attack
	current_attack = data
	phase_frame = 0
	_active_action = action
	hitbox.set_active(false)
	hitbox.configure(data, movement_controller.is_facing_right)
	animated_sprite.play(data.animation_name)
	if chained:
		chain_index += 1
		_change_state(State.STARTUP)
		attack_chained.emit(previous_attack, data)
	else:
		chain_index = 0
		_chain_root = data
		_buffered_input.clear()
		_change_state(State.STARTUP)
		attack_started.emit(data)

func is_chain_window_open() -> bool:
	if current_state != State.RECOVERY or current_attack == null:
		return false
	var window_start: int = maxi(0, current_attack.recovery_frames - _chain_window_ticks())
	return phase_frame >= window_start

func _try_chain_link() -> bool:
	if current_attack == null or current_attack.chain_next == null:
		return false
	var chain_action: StringName = current_attack.get_chain_action(_active_action)
	if chain_action == &"":
		return false
	if not _buffered_input.consume(chain_action, _physics_tick, _buffer_ticks()):
		return false
	_begin_attack(current_attack.chain_next, chain_action, true)
	return true

# --- Input -------------------------------------------------------------------

func _poll_neutral_start() -> void:
	var crouched: bool = is_crouched()
	for action: StringName in _attack_actions():
		if not InputMap.has_action(action) or not Input.is_action_just_pressed(action):
			continue
		var data: AttackData = _resolve_neutral_attack(action, crouched)
		if data != null and start_attack(data):
			return

func _poll_attack_buffer() -> void:
	for action: StringName in _attack_actions():
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			_buffered_input.push(action, _physics_tick)

func _start_buffered_neutral_attack(action: StringName) -> void:
	var data: AttackData = _resolve_neutral_attack(action, is_crouched())
	if data != null:
		start_attack(data)

func buffer_attack_input(action: StringName) -> void:
	_buffered_input.push(action, _physics_tick)

func get_buffered_action() -> StringName:
	return _buffered_input.peek_action()

func _attack_actions() -> Array[StringName]:
	return [light_attack_action, kick_attack_action, heavy_attack_action, roundhouse_attack_action]

func _resolve_neutral_attack(action: StringName, crouched: bool) -> AttackData:
	if action == light_attack_action:
		return get_light_attack()
	if action == kick_attack_action:
		if crouched and get_sweep_attack() != null:
			return get_sweep_attack()
		return get_kick_attack()
	if action == heavy_attack_action:
		return get_heavy_attack()
	if action == roundhouse_attack_action:
		return get_roundhouse_attack()
	return null

func _action_for_attack(data: AttackData) -> StringName:
	if data == null:
		return &""
	if data == get_heavy_attack():
		return heavy_attack_action
	if data == get_roundhouse_attack():
		return roundhouse_attack_action
	if data == get_sweep_attack():
		return kick_attack_action
	if data == get_light_attack():
		return light_attack_action
	if data == get_kick_attack():
		return kick_attack_action
	if data == get_light_chain_start() or _is_in_chain(get_light_chain_start(), data):
		return light_attack_action
	if data == get_kick_chain_start() or _is_in_chain(get_kick_chain_start(), data):
		return kick_attack_action
	return &""

func _is_in_chain(root: AttackData, data: AttackData) -> bool:
	var node: AttackData = root
	while node != null:
		if node == data:
			return true
		node = node.chain_next
	return false

# --- Attack table accessors --------------------------------------------------

func get_light_chain_start() -> AttackData:
	if moveset != null and moveset.light_chain_start != null:
		return moveset.light_chain_start
	return punch_attack

func get_kick_chain_start() -> AttackData:
	if moveset != null and moveset.kick_chain_start != null:
		return moveset.kick_chain_start
	return kick_attack

func get_light_attack() -> AttackData:
	return get_light_chain_start()

func get_kick_attack() -> AttackData:
	return get_kick_chain_start()

func get_heavy_attack() -> AttackData:
	return moveset.heavy_attack if moveset != null else null

func get_roundhouse_attack() -> AttackData:
	return moveset.roundhouse_attack if moveset != null else null

func get_sweep_attack() -> AttackData:
	return moveset.sweep_attack if moveset != null else null

func get_chain_root() -> AttackData:
	return _chain_root

func _buffer_ticks() -> int:
	return moveset.buffer_ticks if moveset != null else FALLBACK_BUFFER_TICKS

func _chain_window_ticks() -> int:
	return moveset.chain_window_ticks if moveset != null else FALLBACK_CHAIN_WINDOW_TICKS

func is_crouched() -> bool:
	return movement_controller != null and movement_controller.current_state == CharacterController2D.State.CROUCH

func is_animation_locked() -> bool:
	return current_state != State.NEUTRAL

# --- Incoming damage ---------------------------------------------------------

func on_combat_hit(attacker: Node2D, attack: AttackData, _damage: float) -> void:
	if attack == null or movement_controller == null or _is_defeated():
		return
	if _is_passive_guarding:
		movement_controller.velocity.x = move_toward(movement_controller.velocity.x, 0.0, movement_controller.ground_friction / Engine.physics_ticks_per_second)
		movement_controller.velocity.y = 0.0
		return
	_interrupt_current_action()
	var direction: float = signf(movement_controller.global_position.x - attacker.global_position.x)
	if is_zero_approx(direction):
		direction = -1.0 if movement_controller.is_facing_right else 1.0
	movement_controller.velocity.x = direction * attack.knockback.x
	movement_controller.velocity.y = -absf(attack.knockback.y)
	if attack.hit_reaction == AttackData.HitReaction.KNOCKDOWN:
		_begin_knockdown()
		return
	hitstun_frames = maxi(1, roundi(attack.hitstun_seconds * Engine.physics_ticks_per_second))
	_change_state(State.HITSTUN)
	animated_sprite.play(&"heavy_hit" if attack.hit_reaction == AttackData.HitReaction.HEAVY else &"idle_signature")
	animated_sprite.modulate = Color(1.35, 0.8, 1.5, 1.0)
	_hit_flash_frames = 6

func interrupt_for_parry(stun_ticks: int) -> void:
	if current_state not in [State.STARTUP, State.ACTIVE] or _is_defeated():
		return
	_interrupt_current_action()
	hitstun_frames = maxi(1, stun_ticks)
	_change_state(State.HITSTUN)
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"heavy_hit"):
		animated_sprite.play(&"heavy_hit")

func _update_passive_guard() -> void:
	if health_component == null or movement_controller == null:
		_is_passive_guarding = false
		return
	if passive_back_guard_reduction <= 0.0:
		_is_passive_guarding = false
		health_component.damage_reduction = _base_damage_reduction
		return
	_is_passive_guarding = (current_state == State.NEUTRAL
			and movement_controller.is_grounded
			and movement_controller.current_state == CharacterController2D.State.MOVE_BACKWARD)
	health_component.damage_reduction = maxf(_base_damage_reduction, passive_back_guard_reduction) if _is_passive_guarding else _base_damage_reduction

## Single reaction path: Hurtbox2D routes every combat hit through
## on_combat_hit, so this only clears the timed action without re-applying
## hitstun (that double reset was the pre-Step-1 behaviour).
func _interrupt_current_action() -> void:
	current_attack = null
	hitbox.set_active(false)
	phase_frame = 0
	_buffered_input.clear()
	_active_action = &""
	_chain_root = null
	chain_index = 0

func _on_target_hit(target: Hurtbox2D, damage: float) -> void:
	if current_attack != null:
		hit_landed.emit(current_attack, target, damage)

func _on_defeated() -> void:
	if _defeated_latched:
		return
	_defeated_latched = true
	hitbox.set_active(false)
	_interrupt_current_action()
	_downed_timer = 0.0
	_fall_animation_finished = false
	movement_controller.velocity.x = 0.0
	if movement_controller.is_grounded:
		movement_controller.velocity.y = 0.0
	_change_state(State.DEFEATED)
	animated_sprite.play(&"knockdown")

func _begin_knockdown() -> void:
	if _is_defeated():
		return
	_fall_animation_finished = false
	_downed_timer = 0.0
	_change_state(State.KNOCKDOWN)
	animated_sprite.play(&"knockdown")

func _begin_getup() -> void:
	if _is_defeated():
		return
	_change_state(State.GETTING_UP)
	animated_sprite.play(&"getup")

func _play_defeated_pose() -> void:
	animated_sprite.play(&"defeated")

func _on_animation_finished() -> void:
	match animated_sprite.animation:
		&"knockdown":
			_fall_animation_finished = true
		&"defeated":
			if current_state == State.DOWNED or current_state == State.DEFEATED:
				animated_sprite.pause()
				animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"defeated") - 1
				if current_state == State.DEFEATED and not _defeat_pose_started:
					_defeat_pose_started = true
					defeat_pose_reached.emit()
		&"getup":
			if current_state == State.GETTING_UP and not _is_defeated():
				_enter_neutral()

func _is_defeated() -> bool:
	return _defeated_latched or (health_component != null and health_component.is_defeated)

func _enter_downed_state() -> void:
	if _is_defeated():
		return
	_change_state(State.DOWNED)
	_downed_timer = 0.9
	animated_sprite.play(&"defeated")

# --- State -------------------------------------------------------------------

func _enter_neutral() -> void:
	_interrupt_current_action()
	_change_state(State.NEUTRAL)

func _change_state(next_state: State) -> void:
	if current_state == next_state:
		return
	var previous: State = current_state
	current_state = next_state
	_update_movement_lock()
	combat_state_changed.emit(previous, next_state)

func _update_movement_lock() -> void:
	if movement_controller != null:
		movement_controller.combat_motion_locked = current_state != State.NEUTRAL
		# Crouched attacks keep the crouch posture; standing attacks must not
		# acquire a crouch lock, and hitstun/knockdown always release it.
		movement_controller.combat_crouch_lock = (current_state != State.NEUTRAL
				and current_attack != null
				and current_attack.stance == AttackData.Stance.CROUCHED)

func _validate_attack_animations() -> void:
	var sprite_frames: SpriteFrames = animated_sprite.sprite_frames
	if sprite_frames == null:
		return
	for reaction_animation: StringName in [&"heavy_hit", &"knockdown", &"defeated", &"getup"]:
		assert(sprite_frames.has_animation(reaction_animation), "Combat reaction animation is missing from SpriteFrames: %s" % reaction_animation)
	var attacks: Array[AttackData] = []
	if moveset != null:
		attacks = moveset.get_all_attacks()
	else:
		for legacy: AttackData in [punch_attack, kick_attack]:
			if legacy != null:
				attacks.append(legacy)
	for attack: AttackData in attacks:
		if attack == null or attack.animation_name == &"":
			continue
		assert(sprite_frames.has_animation(attack.animation_name), "Configured attack animation is missing from SpriteFrames: %s" % attack.animation_name)
