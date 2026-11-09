class_name CombatController
extends Node

signal combat_state_changed(previous: State, current: State)
signal attack_started(attack: AttackData)
signal attack_finished(attack: AttackData)
signal hit_landed(attack: AttackData, target: Hurtbox2D, damage: float)

enum State { NEUTRAL, STARTUP, ACTIVE, RECOVERY, HITSTUN }

@export var punch_attack: AttackData
@export var kick_attack: AttackData
@export var light_attack_action: StringName = &"light_attack"
@export var kick_attack_action: StringName = &"kick_attack"
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
var _hit_flash_frames: int = 0

func _ready() -> void:
	assert(movement_controller != null and animated_sprite != null and hitbox != null, "CombatController requires movement, sprite, and hitbox nodes")
	if punch_attack != null:
		assert(animated_sprite.sprite_frames.has_animation(punch_attack.animation_name), "Punch animation is missing from SpriteFrames")
	if kick_attack != null:
		assert(animated_sprite.sprite_frames.has_animation(kick_attack.animation_name), "Kick animation is missing from SpriteFrames")
	hitbox.target_hit.connect(_on_target_hit)
	if health_component != null:
		health_component.damage_received.connect(_on_damage_received)
		health_component.defeated.connect(_on_defeated)
	_update_movement_lock()

func _physics_process(_delta: float) -> void:
	if _hit_flash_frames > 0:
		_hit_flash_frames -= 1
		if _hit_flash_frames == 0 and animated_sprite != null:
			animated_sprite.modulate = Color.WHITE
	if current_state == State.NEUTRAL:
		if InputMap.has_action(light_attack_action) and Input.is_action_just_pressed(light_attack_action):
			start_attack(punch_attack)
		elif InputMap.has_action(kick_attack_action) and Input.is_action_just_pressed(kick_attack_action):
			start_attack(kick_attack)
		return
	if current_state == State.HITSTUN:
		hitstun_frames -= 1
		if hitstun_frames <= 0:
			_change_state(State.NEUTRAL)
		return
	phase_frame += 1
	if current_attack == null:
		_change_state(State.NEUTRAL)
		return
	match current_state:
		State.STARTUP:
			if phase_frame >= current_attack.startup_frames:
				phase_frame = 0
				hitbox.set_active(true)
				_change_state(State.ACTIVE)
		State.ACTIVE:
			if phase_frame >= current_attack.active_frames:
				hitbox.set_active(false)
				phase_frame = 0
				_change_state(State.RECOVERY)
		State.RECOVERY:
			if phase_frame >= current_attack.recovery_frames:
				var finished_attack: AttackData = current_attack
				current_attack = null
				_change_state(State.NEUTRAL)
				attack_finished.emit(finished_attack)

func start_attack(data: AttackData) -> bool:
	if current_state != State.NEUTRAL or data == null or animated_sprite == null or movement_controller == null:
		return false
	if not movement_controller.is_grounded or movement_controller.current_state == CharacterController2D.State.CROUCH:
		return false
	current_attack = data
	phase_frame = 0
	hitbox.configure(data, movement_controller.is_facing_right)
	hitbox.set_active(false)
	animated_sprite.play(data.animation_name)
	_change_state(State.STARTUP)
	attack_started.emit(data)
	return true

func is_animation_locked() -> bool:
	return current_state != State.NEUTRAL

func on_combat_hit(attacker: Node2D, attack: AttackData, _damage: float) -> void:
	if attack == null or movement_controller == null:
		return
	current_attack = null
	hitbox.set_active(false)
	var direction: float = signf(movement_controller.global_position.x - attacker.global_position.x)
	if is_zero_approx(direction):
		direction = -1.0 if movement_controller.is_facing_right else 1.0
	movement_controller.velocity.x = direction * attack.knockback.x
	movement_controller.velocity.y = -absf(attack.knockback.y)
	hitstun_frames = maxi(1, roundi(attack.hitstun_seconds * Engine.physics_ticks_per_second))
	phase_frame = 0
	_change_state(State.HITSTUN)
	animated_sprite.play(&"idle_signature")
	animated_sprite.modulate = Color(1.35, 0.8, 1.5, 1.0)
	_hit_flash_frames = 6

func _on_target_hit(target: Hurtbox2D, damage: float) -> void:
	if current_attack != null:
		hit_landed.emit(current_attack, target, damage)

func _on_damage_received(_amount: float, _source: Node2D) -> void:
	if current_attack != null:
		current_attack = null
		hitbox.set_active(false)
		phase_frame = 0
		hitstun_frames = 12
		_change_state(State.HITSTUN)
		animated_sprite.play(&"idle_signature")

func _on_defeated() -> void:
	hitbox.set_active(false)
	current_attack = null
	_change_state(State.NEUTRAL)
	animated_sprite.stop()

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
