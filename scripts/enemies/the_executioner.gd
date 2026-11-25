class_name TheExecutioner
extends TrainingDummy

signal parry_succeeded(attacker: Node2D, contact_position: Vector2)

@export var light_slash_attack: AttackData
@export var heavy_slash_attack: AttackData
@export var horizontal_slash_attack: AttackData
@export var dash_attack: AttackData
@export var combo_attack: AttackData
@export var combo_step_attacks: Array[AttackData] = []
@export var counterattack: AttackData
@export var weapon_data: WeaponData

const PARRY_READ_CHANCE: float = 0.28
const PARRY_ANTICIPATION_SECONDS: float = 0.10
const PARRY_WINDOW_SECONDS: float = 0.15
const PARRY_COOLDOWN_SECONDS: float = 4.2
const VISUAL_SCALE: float = 0.72
const FRAME_GROUND_Y: float = 491.0
const FRAME_CENTER_Y: float = 256.0
const KAI_FOOTLINE_OFFSET: float = -6.0

var _last_attack_id: StringName = &""
var _parry_anticipation: float = 0.0
var _parry_window: float = 0.0
var _parry_cooldown: float = 1.2
var _parry_armed: bool = false
var _counter_pending: bool = false
var _counter_delay: float = 0.0
var _combo_steps: int = 0
var _combo_window_ticks: Array[Vector2i] = [Vector2i(14, 18), Vector2i(44, 48), Vector2i(74, 78)]
var _combo_window_index: int = -1
var _combo_window_open: bool = false

func _ready() -> void:
	punch_attack = light_slash_attack
	kick_attack = horizontal_slash_attack
	super._ready()
	minion_sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	minion_sprite.position.y = KAI_FOOTLINE_OFFSET - (FRAME_GROUND_Y - FRAME_CENTER_Y) * VISUAL_SCALE
	minion_sprite.play(&"idle")
	_attack_cooldown = 1.0
	_ai_timer = 0.65
	attack_range = 246.0
	approach_speed = 92.0
	guard_damage_reduction = 0.5

func _physics_process(delta: float) -> void:
	_parry_cooldown = maxf(0.0, _parry_cooldown - delta)
	if _parry_armed:
		_parry_anticipation = maxf(0.0, _parry_anticipation - delta)
		if _parry_anticipation <= 0.0:
			_parry_window = maxf(0.0, _parry_window - delta)
			if _parry_window <= 0.0:
				_parry_armed = false
	if _counter_pending:
		_counter_delay -= delta
		if _counter_delay <= 0.0:
			_counter_pending = false
			if not health_component.is_defeated and is_instance_valid(_hero) and _distance_to_hero() <= 270.0:
				_start_executioner_attack(counterattack)
	super._physics_process(delta)

func _update_ai(delta: float) -> void:
	if _parry_armed or _counter_pending:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
		if _parry_armed and _parry_anticipation <= 0.0:
			_play_animation(&"parry")
		elif _parry_armed:
			_play_animation(&"high_guard")
		return
	if _current_attack == combo_attack and _ai_state == AIState.ATTACK:
		_update_three_hit_combo()
		return
	if _current_attack == dash_attack and _ai_state == AIState.ATTACK:
		var direction: float = 1.0 if _facing_right else -1.0
		velocity.x = move_toward(velocity.x, direction * 142.0, 780.0 * delta)
		_update_attack()
		return
	super._update_ai(delta)

func _start_attack() -> void:
	if _hero == null or health_component.is_defeated:
		_enter_ai_state(AIState.IDLE, 0.35)
		return
	var distance: float = _distance_to_hero()
	var candidates: Array[AttackData] = []
	if distance > 215.0:
		_add_candidate(candidates, dash_attack, 4)
		_add_candidate(candidates, light_slash_attack, 2)
	else:
		_add_candidate(candidates, light_slash_attack, 3)
		_add_candidate(candidates, horizontal_slash_attack, 2)
		_add_candidate(candidates, heavy_slash_attack, 2)
		_add_candidate(candidates, combo_attack, 1)
	for index: int in range(candidates.size() - 1, -1, -1):
		if candidates.size() > 1 and candidates[index].attack_id == _last_attack_id:
			candidates.remove_at(index)
	if candidates.is_empty():
		_enter_ai_state(AIState.IDLE, 0.3)
		return
	var chosen: AttackData = candidates[_random.randi_range(0, candidates.size() - 1)]
	_start_executioner_attack(chosen)

func _start_executioner_attack(attack: AttackData) -> void:
	if attack == null or _hero == null or health_component.is_defeated:
		_enter_ai_state(AIState.IDLE, 0.3)
		return
	_current_attack = attack
	_last_attack_id = attack.attack_id
	_attack_frame = 0
	_attack_hitbox_active = false
	_combo_window_index = -1
	_combo_window_open = false
	if attack == combo_attack:
		_attack_cooldown = 4.3
	elif attack == heavy_slash_attack or attack == dash_attack:
		_attack_cooldown = 3.5
	else:
		_attack_cooldown = 2.5
	enemy_hitbox.configure(attack, _facing_right)
	_enter_ai_state(AIState.ATTACK)
	_play_animation(attack.animation_name)

func _update_three_hit_combo() -> void:
	if _current_attack == null:
		_finish_executioner_attack()
		return
	_attack_frame += 1
	var active_index: int = -1
	for index: int in range(_combo_window_ticks.size()):
		var window: Vector2i = _combo_window_ticks[index]
		if _attack_frame >= window.x and _attack_frame <= window.y:
			active_index = index
			break
	if active_index >= 0:
		if not _combo_window_open or _combo_window_index != active_index:
			enemy_hitbox.set_active(false)
			var step_attack: AttackData = combo_attack
			if active_index < combo_step_attacks.size() and combo_step_attacks[active_index] != null:
				step_attack = combo_step_attacks[active_index]
			enemy_hitbox.configure(step_attack, _facing_right)
			enemy_hitbox.set_active(true)
			_combo_window_open = true
			_combo_window_index = active_index
		enemy_hitbox.set_active_frame(_attack_frame - _combo_window_ticks[active_index].x, _facing_right)
	elif _combo_window_open:
		enemy_hitbox.set_active(false)
		_combo_window_open = false
	if _attack_frame >= 88:
		_finish_executioner_attack()

func _finish_executioner_attack() -> void:
	_deactivate_enemy_hitbox()
	_current_attack = null
	_combo_window_open = false
	_enter_ai_state(AIState.RECOVER, 0.55)

func _add_candidate(candidates: Array[AttackData], attack: AttackData, weight: int) -> void:
	if attack == null:
		return
	for _index: int in range(weight):
		candidates.append(attack)

func _on_hero_combat_state_changed(_previous: CombatController.State, current: CombatController.State) -> void:
	if not ai_enabled or health_component.is_defeated or _parry_cooldown > 0.0 or _parry_armed or _counter_pending:
		return
	if current != CombatController.State.STARTUP or not (_ai_state in [AIState.IDLE, AIState.APPROACH]):
		return
	if _hero == null or _distance_to_hero() > 270.0 or _random.randf() > PARRY_READ_CHANCE:
		return
	_parry_cooldown = PARRY_COOLDOWN_SECONDS
	_parry_armed = true
	_parry_anticipation = PARRY_ANTICIPATION_SECONDS
	_parry_window = PARRY_WINDOW_SECONDS
	_deactivate_enemy_hitbox()
	_enter_ai_state(AIState.DEFEND, PARRY_ANTICIPATION_SECONDS + PARRY_WINDOW_SECONDS)
	_play_animation(&"high_guard")

func try_parry(attacker: Node2D, attack: AttackData, contact_position: Vector2) -> bool:
	if not _parry_armed or _parry_anticipation > 0.0 or _parry_window <= 0.0 or attack == null:
		return false
	_parry_armed = false
	_parry_window = 0.0
	_parry_cooldown = PARRY_COOLDOWN_SECONDS
	_deactivate_enemy_hitbox()
	_counter_pending = true
	_counter_delay = 0.18
	if attacker != null:
		var combat: CombatController = attacker.get_node_or_null("CombatController") as CombatController
		if combat != null:
			combat.interrupt_for_parry(10)
		parry_succeeded.emit(attacker, contact_position)
	_enter_ai_state(AIState.RECOVER, 0.2)
	_play_animation(&"parry")
	return true

func on_combat_hit(attacker: Node2D, attack: AttackData, damage: float) -> void:
	_parry_armed = false
	_counter_pending = false
	super.on_combat_hit(attacker, attack, damage)
	if not health_component.is_defeated and _ai_state == AIState.HIT:
		hitstun_frames = maxi(hitstun_frames, 42)

func _on_hero_defeated() -> void:
	_parry_armed = false
	_counter_pending = false
	super._on_hero_defeated()

func _enter_ai_state(next_state: AIState, duration: float = 0.0) -> void:
	super._enter_ai_state(next_state, duration)
	if next_state == AIState.DEFEATED:
		_parry_armed = false
		_counter_pending = false
	elif next_state == AIState.APPROACH:
		_play_animation(&"walk_forward")
	elif next_state == AIState.IDLE or next_state == AIState.RECOVER:
		if not _parry_armed and not _counter_pending:
			_play_animation(&"idle")

