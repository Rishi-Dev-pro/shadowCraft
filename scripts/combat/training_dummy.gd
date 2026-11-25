class_name TrainingDummy
extends CharacterBody2D

signal hit_taken(attack_name: String, damage: float)
signal defeat_animation_finished

enum AIState { IDLE, APPROACH, ATTACK, DEFEND, HIT, RECOVER, DEFEATED }

@export var gravity: float = 980.0
@export var horizontal_friction: float = 900.0
@export var ai_enabled: bool = false
@export var punch_attack: AttackData
@export var kick_attack: AttackData
@export_range(40.0, 220.0, 1.0) var approach_speed: float = 118.0
@export_range(100.0, 240.0, 1.0) var attack_range: float = 172.0
@export_range(0.0, 0.8, 0.05) var guard_damage_reduction: float = 0.6
@onready var health_component: HealthComponent = $HealthComponent
@onready var silhouette: Node2D = $Silhouette
@onready var minion_sprite: AnimatedSprite2D = $Silhouette/MinionSprite
@onready var enemy_hitbox: Hitbox2D = $EnemyHitbox

var hitstun_frames: int = 0
var _hit_flash_frames: int = 0
var _normal_modulate: Color = Color.WHITE
var _ai_state: AIState = AIState.IDLE
var _ai_timer: float = 0.45
var _attack_cooldown: float = 0.8
var _guard_cooldown: float = 0.0
var _attack_frame: int = 0
var _attack_hitbox_active: bool = false
var _defensive_step_timer: float = 0.0
var _current_attack: AttackData
var _death_started: bool = false
var _death_animation_finished: bool = false
var _facing_right: bool = false
var _hero: CharacterController2D
var _hero_combat: CombatController
var _hero_health: HealthComponent
var _random: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 1
	health_component.defeated.connect(_on_defeated)
	_normal_modulate = silhouette.modulate
	_random.randomize()
	minion_sprite.flip_h = true
	minion_sprite.animation_finished.connect(_on_minion_animation_finished)
	minion_sprite.play(&"idle")
	if punch_attack != null and enemy_hitbox != null:
		enemy_hitbox.configure(punch_attack, _facing_right)
		enemy_hitbox.collision_mask = 1 << 6
		enemy_hitbox.set_active(false)
	if ai_enabled:
		_ai_state = AIState.IDLE

func configure_attacks(punch: AttackData, kick: AttackData) -> void:
	punch_attack = punch
	kick_attack = kick
	if enemy_hitbox != null and punch_attack != null:
		enemy_hitbox.configure(punch_attack, _facing_right)
		enemy_hitbox.set_active(false)

func _physics_process(delta: float) -> void:
	if _hit_flash_frames > 0:
		_hit_flash_frames -= 1
		silhouette.modulate = Color(1.5, 1.2, 1.7, 1.0) if _hit_flash_frames > 0 else _normal_modulate
	if ai_enabled and _ai_state != AIState.DEFEATED:
		_update_target()
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
		_guard_cooldown = maxf(0.0, _guard_cooldown - delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	if hitstun_frames > 0:
		hitstun_frames -= 1
		velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
		if ai_enabled and _ai_state == AIState.HIT and hitstun_frames == 0:
			_enter_ai_state(AIState.RECOVER, 0.7)
	elif ai_enabled:
		_update_ai(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
	move_and_slide()

func on_combat_hit(attacker: Node2D, attack: AttackData, damage: float) -> void:
	if health_component.is_defeated:
		return
	var direction: float = signf(global_position.x - attacker.global_position.x)
	if is_zero_approx(direction):
		direction = 1.0
	var blocked: bool = ai_enabled and _ai_state == AIState.DEFEND
	velocity.x = direction * attack.knockback.x * (0.22 if blocked else 1.0)
	velocity.y = 0.0 if blocked else -absf(attack.knockback.y)
	hitstun_frames = 4 if blocked else maxi(1, roundi(attack.hitstun_seconds * Engine.physics_ticks_per_second))
	_hit_flash_frames = 6
	silhouette.modulate = Color(1.5, 1.2, 1.7, 1.0)
	hit_taken.emit(attack.display_name, damage)
	if ai_enabled and not blocked and not health_component.is_defeated:
		_deactivate_enemy_hitbox()
		_enter_ai_state(AIState.HIT)

func _update_target() -> void:
	if not is_instance_valid(_hero) or not _hero.is_inside_tree():
		_hero = null
		_hero_combat = null
		var fighters: Node = get_parent().get_parent() if get_parent() != null and get_parent().get_parent() != null else null
		if fighters != null:
			_hero = fighters.get_node_or_null("Kai") as CharacterController2D
		if _hero != null:
			_hero_combat = _hero.get_node_or_null("CombatController") as CombatController
			_hero_health = _hero.get_node_or_null("HealthComponent") as HealthComponent
			if _hero_combat != null and not _hero_combat.combat_state_changed.is_connected(_on_hero_combat_state_changed):
				_hero_combat.combat_state_changed.connect(_on_hero_combat_state_changed)
			if _hero_health != null:
				if not _hero_health.defeated.is_connected(_on_hero_defeated):
					_hero_health.defeated.connect(_on_hero_defeated)
				if _hero_health.is_defeated:
					_on_hero_defeated()
	if _hero == null:
		return
	_facing_right = _hero.global_position.x >= global_position.x
	minion_sprite.flip_h = not _facing_right

func _update_ai(delta: float) -> void:
	if _hero == null or _hero_combat == null or not is_instance_valid(_hero):
		velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
		return
	match _ai_state:
		AIState.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
			_ai_timer -= delta
			if _distance_to_hero() > attack_range:
				_enter_ai_state(AIState.APPROACH)
			elif _ai_timer <= 0.0 and _attack_cooldown <= 0.0:
				_start_attack()
		AIState.APPROACH:
			_play_animation(&"walk")
			if _distance_to_hero() <= attack_range:
				velocity.x = 0.0
				_enter_ai_state(AIState.IDLE, 0.3)
			else:
				velocity.x = (-1.0 if not _facing_right else 1.0) * approach_speed
		AIState.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
			_update_attack()
		AIState.DEFEND:
			if _defensive_step_timer > 0.0 and _hero != null:
				_defensive_step_timer = maxf(0.0, _defensive_step_timer - delta)
				velocity.x = (-1.0 if _facing_right else 1.0) * 42.0
				_play_animation(&"walk_backward")
			else:
				velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
				_play_animation(&"guard")
			_ai_timer -= delta
			if _ai_timer <= 0.0:
				_enter_ai_state(AIState.RECOVER, 0.45)
		AIState.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
			_ai_timer -= delta
			if _ai_timer <= 0.0:
				_enter_ai_state(AIState.IDLE, 0.2)

func _start_attack() -> void:
	if punch_attack == null or _hero == null:
		_enter_ai_state(AIState.IDLE, 0.3)
		return
	_current_attack = kick_attack if kick_attack != null and _random.randf() < 0.5 else punch_attack
	_attack_frame = 0
	_attack_hitbox_active = false
	_attack_cooldown = 1.35
	enemy_hitbox.configure(_current_attack, _facing_right)
	_enter_ai_state(AIState.ATTACK)
	_play_animation(_attack_animation_name(_current_attack))

func _attack_animation_name(attack: AttackData) -> StringName:
	if attack.animation_name != &"":
		return attack.animation_name
	return &"kick" if attack.kind == AttackData.AttackKind.KICK else &"punch"

func _update_attack() -> void:
	if _current_attack == null:
		_enter_ai_state(AIState.RECOVER, 0.35)
		return
	_attack_frame += 1
	if _attack_frame <= _current_attack.startup_frames:
		return
	var active_frame: int = _attack_frame - _current_attack.startup_frames - 1
	if active_frame < _current_attack.active_frames:
		if not _attack_hitbox_active:
			_attack_hitbox_active = true
			enemy_hitbox.set_active(true)
		enemy_hitbox.set_active_frame(active_frame, _facing_right)
		return
	_deactivate_enemy_hitbox()
	if _attack_frame >= _current_attack.get_total_frames():
		_enter_ai_state(AIState.RECOVER, 0.28)

func _on_hero_combat_state_changed(_previous: CombatController.State, current: CombatController.State) -> void:
	if not ai_enabled or health_component.is_defeated or _guard_cooldown > 0.0:
		return
	if current == CombatController.State.NEUTRAL or not (_ai_state in [AIState.IDLE, AIState.APPROACH]):
		return
	_guard_cooldown = 2.6
	if current in [CombatController.State.STARTUP, CombatController.State.ACTIVE] and _random.randf() <= 0.35:
		_defensive_step_timer = 0.12
		_enter_ai_state(AIState.DEFEND, 0.48)

func _on_hero_defeated() -> void:
	if not ai_enabled:
		return
	ai_enabled = false
	_deactivate_enemy_hitbox()
	_current_attack = null
	_attack_frame = 0
	hitstun_frames = 0
	velocity.x = 0.0
	_enter_ai_state(AIState.IDLE)

func _enter_ai_state(next_state: AIState, duration: float = 0.0) -> void:
	if _ai_state == next_state:
		_ai_timer = duration if duration > 0.0 else _ai_timer
		return
	if _ai_state == AIState.DEFEND and health_component != null:
		health_component.damage_reduction = 0.0
	_ai_state = next_state
	_ai_timer = duration
	if next_state != AIState.DEFEND and health_component != null:
		health_component.damage_reduction = 0.0
	if next_state == AIState.DEFEND:
		health_component.damage_reduction = guard_damage_reduction
		_play_animation(&"guard")
		minion_sprite.modulate = Color(0.9, 0.78, 1.0, 1.0)
	elif next_state == AIState.HIT:
		_deactivate_enemy_hitbox()
		minion_sprite.modulate = Color.WHITE
		_play_animation(&"hit")
	elif next_state == AIState.APPROACH:
		_play_animation(&"walk")
		minion_sprite.modulate = Color.WHITE
	elif next_state in [AIState.IDLE, AIState.RECOVER]:
		_play_animation(&"idle")
		minion_sprite.modulate = Color.WHITE
	elif next_state == AIState.ATTACK:
		minion_sprite.modulate = Color.WHITE
	elif next_state == AIState.DEFEATED:
		health_component.damage_reduction = 0.0
		_deactivate_enemy_hitbox()
		minion_sprite.modulate = Color.WHITE
		_play_animation(&"death")

func _deactivate_enemy_hitbox() -> void:
	if enemy_hitbox != null:
		enemy_hitbox.set_active(false)
	_attack_hitbox_active = false

func _play_animation(animation_name: StringName) -> void:
	if minion_sprite.sprite_frames == null or not minion_sprite.sprite_frames.has_animation(animation_name):
		return
	if minion_sprite.animation != animation_name or not minion_sprite.is_playing():
		minion_sprite.play(animation_name)

func _on_minion_animation_finished() -> void:
	if _ai_state == AIState.DEFEATED and minion_sprite.animation == &"death" and not _death_animation_finished:
		var death_frames: int = minion_sprite.sprite_frames.get_frame_count(&"death")
		minion_sprite.pause()
		minion_sprite.frame = maxi(0, death_frames - 1)
		_death_animation_finished = true
		defeat_animation_finished.emit()

func _distance_to_hero() -> float:
	return absf(_hero.global_position.x - global_position.x) if _hero != null else INF

func _on_defeated() -> void:
	if _death_started:
		return
	_death_started = true
	ai_enabled = false
	hitstun_frames = 0
	_attack_cooldown = INF
	velocity = Vector2.ZERO
	_enter_ai_state(AIState.DEFEATED)
