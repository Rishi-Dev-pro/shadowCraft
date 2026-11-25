class_name RaezanBoss
extends TheExecutioner

signal boss_phase_changed(phase: int)

@export var vertical_slash_attack: AttackData
@export var void_burst_attack: AttackData
@export var void_step_attack: AttackData
@export var five_hit_attack: AttackData
@export var five_hit_steps: Array[AttackData] = []
@export_range(0.25, 0.75, 0.05) var phase_two_health_ratio: float = 0.5
@export_range(180.0, 360.0, 5.0) var void_burst_max_range: float = 265.0
@export_range(0.0, 1.0, 0.05) var phase_one_guard_chance: float = 0.25
@export_range(0.0, 1.0, 0.05) var phase_two_guard_chance: float = 0.32

const PLAYER_FOOTLINE_OFFSET: float = -6.0
const COMBO_WINDOWS: Array[Vector2i] = [Vector2i(8, 10), Vector2i(20, 22), Vector2i(32, 34), Vector2i(44, 46), Vector2i(56, 58)]
const VOID_STEP_DURATION: float = 0.26
const VOID_STEP_COOLDOWN: float = 6.0
const VOID_BURST_COOLDOWN: float = 10.0
const HIT_REACTION_STUN_FRAMES: int = 30
const KNOCKBACK_STUN_FRAMES: int = 60
const GUARD_ENTRY_SECONDS: float = 0.18
const GUARD_CONTACT_SECONDS: float = 0.12
const GUARD_RELEASE_SECONDS: float = 0.15

var _phase: int = 1
var _void_step_active: bool = false
var _void_step_elapsed: float = 0.0
var _void_step_direction: float = 1.0
var _void_step_cooldown: float = 2.0
var _void_burst_cooldown: float = 5.0
var _combo_window_index_raezan: int = -1
var _combo_window_open_raezan: bool = false
var _attack_animation_override: StringName = &""
var _guard_animation_elapsed: float = 0.0
var _guard_contact_timer: float = 0.0
var _guard_release_timer: float = 0.0

func _ready() -> void:
	punch_attack = light_slash_attack
	kick_attack = horizontal_slash_attack
	super._ready()
	minion_sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	minion_sprite.position.y = PLAYER_FOOTLINE_OFFSET - (FRAME_GROUND_Y - FRAME_CENTER_Y) * VISUAL_SCALE
	minion_sprite.play(&"idle")
	# Give the player a clear opening at round start.  The Executioner's base
	# timings are intentionally tightened for Guardian III, so Raezan owns a
	# slightly longer, phase-aware cadence below.
	_attack_cooldown = 3.2
	_ai_timer = 1.5
	approach_speed = 105.0
	attack_range = 258.0
	guard_damage_reduction = 0.5
	if not health_component.health_changed.is_connected(_on_boss_health_changed):
		health_component.health_changed.connect(_on_boss_health_changed)

func _physics_process(delta: float) -> void:
	if _ai_state == AIState.DEFEND:
		_guard_animation_elapsed += delta
	_guard_contact_timer = maxf(0.0, _guard_contact_timer - delta)
	_guard_release_timer = maxf(0.0, _guard_release_timer - delta)
	_void_step_cooldown = maxf(0.0, _void_step_cooldown - delta)
	_void_burst_cooldown = maxf(0.0, _void_burst_cooldown - delta)
	if _void_step_active:
		_update_void_step(delta)
		return
	super._physics_process(delta)
	_sync_guard_presentation()

func _sync_guard_presentation() -> void:
	if _defensive_step_timer > 0.0 and _ai_state == AIState.DEFEND:
		return
	var animation_to_play: StringName = &""
	if _ai_state == AIState.DEFEND:
		if _guard_contact_timer > 0.0:
			animation_to_play = &"guard_impact"
		elif _guard_animation_elapsed < GUARD_ENTRY_SECONDS:
			animation_to_play = &"guard_entry"
		else:
			animation_to_play = &"guard_hold"
	elif _guard_release_timer > 0.0 and _ai_state in [AIState.IDLE, AIState.RECOVER]:
		animation_to_play = &"guard_release"
	if animation_to_play != &"" and minion_sprite.animation != animation_to_play:
		_play_animation(animation_to_play)

func _update_ai(delta: float) -> void:
	if _parry_armed or _counter_pending:
		super._update_ai(delta)
		return
	if _current_attack == five_hit_attack and _ai_state == AIState.ATTACK:
		_update_five_hit_combo()
		return
	if _current_attack == void_step_attack and _ai_state == AIState.ATTACK:
		velocity.x = 0.0
		_update_attack()
		return
	super._update_ai(delta)
	if _ai_state == AIState.APPROACH:
		# _facing_right describes which way the sprite faces, not travel intent.
		# Approach always advances in the facing direction; the retreat clip is
		# reserved for the deliberate defensive backstep.
		_play_animation(&"phase2_walk_forward" if _phase == 2 else &"walk_forward")
	elif _ai_state == AIState.DEFEND:
		if _defensive_step_timer > 0.0:
			_play_animation(&"phase2_walk_backward" if _phase == 2 else &"walk_backward")
		else:
			_play_animation(&"guard")
	elif _ai_state == AIState.IDLE or _ai_state == AIState.RECOVER:
		_play_animation(&"phase2_idle" if _phase == 2 else &"idle")

func _start_attack() -> void:
	if _hero == null or health_component.is_defeated:
		_enter_ai_state(AIState.IDLE, 0.35)
		return
	var distance: float = _distance_to_hero()
	if distance > 330.0 and _void_step_cooldown <= 0.0 and _random.randf() < (0.48 if _phase == 2 else 0.3):
		_start_void_step()
		return
	var candidates: Array[AttackData] = []
	if distance > 285.0:
		_add_candidate(candidates, dash_attack, 4)
		_add_candidate(candidates, light_slash_attack, 1)
	else:
		_add_candidate(candidates, light_slash_attack, 3)
		_add_candidate(candidates, heavy_slash_attack, 2)
		_add_candidate(candidates, horizontal_slash_attack, 2)
		_add_candidate(candidates, vertical_slash_attack, 2)
		_add_candidate(candidates, five_hit_attack, 1 if _phase == 1 else 2)
		if _void_burst_cooldown <= 0.0 and distance <= void_burst_max_range:
			_add_candidate(candidates, void_burst_attack, 1 if _phase == 1 else 2)
	for index: int in range(candidates.size() - 1, -1, -1):
		if candidates.size() > 1 and candidates[index].attack_id == _last_attack_id:
			candidates.remove_at(index)
	if candidates.is_empty():
		_enter_ai_state(AIState.IDLE, 0.4)
		return
	var chosen: AttackData = candidates[_random.randi_range(0, candidates.size() - 1)]
	var distance_limit: float = 410.0 if chosen == dash_attack else (void_burst_max_range if chosen == void_burst_attack else attack_range + 20.0)
	if distance > distance_limit:
		_enter_ai_state(AIState.APPROACH)
		return
	_start_raezan_attack(chosen)

func _play_animation(animation_name: StringName) -> void:
	# The shared TrainingDummy requests the generic "walk" clip on every AI
	# approach tick. Resolve that request to one stable Raezan clip here; if the
	# base request and this subclass's facing/phase clip disagree, AnimatedSprite2D
	# is restarted every physics frame and the walk cycle appears frozen.
	if animation_name == &"walk":
		animation_name = &"phase2_walk_forward" if _phase == 2 else &"walk_forward"
	elif animation_name == &"walk_backward" and _phase == 2:
		animation_name = &"phase2_walk_backward"
	if animation_name == &"guard" and _ai_state == AIState.DEFEND:
		if _guard_contact_timer > 0.0:
			super._play_animation(&"guard_impact")
		elif _guard_animation_elapsed < GUARD_ENTRY_SECONDS:
			super._play_animation(&"guard_entry")
		else:
			super._play_animation(&"guard_hold")
		return
	if _guard_release_timer > 0.0 and animation_name in [&"idle", &"phase2_idle"]:
		super._play_animation(&"guard_release")
		return
	super._play_animation(animation_name)

func _start_raezan_attack(attack: AttackData) -> void:
	if attack == null:
		_enter_ai_state(AIState.RECOVER, 0.4)
		return
	_attack_animation_override = _phase_two_animation_for(attack)
	if attack == void_burst_attack:
		_void_burst_cooldown = VOID_BURST_COOLDOWN * (0.85 if _phase == 2 else 1.0)
	if attack == five_hit_attack:
		_combo_window_index_raezan = -1
		_combo_window_open_raezan = false
		_last_attack_id = attack.attack_id
		_current_attack = attack
		_attack_frame = 0
		_attack_hitbox_active = false
		_attack_cooldown = 6.6 if _phase == 1 else 5.2
		enemy_hitbox.configure(attack, _facing_right)
		_enter_ai_state(AIState.ATTACK)
		_play_animation(_attack_animation_override if _attack_animation_override != &"" else &"five_hit_combo")
		return
	_start_executioner_attack(attack)
	if _attack_animation_override != &"":
		_play_animation(_attack_animation_override)

func _phase_two_animation_for(attack: AttackData) -> StringName:
	if _phase != 2:
		return &""
	if attack == void_burst_attack:
		return &"phase2_void_burst"
	if attack == five_hit_attack or attack == heavy_slash_attack:
		return &"phase2_finisher"
	return &""

func _update_five_hit_combo() -> void:
	_attack_frame += 1
	var active_index: int = -1
	for index: int in range(COMBO_WINDOWS.size()):
		var window: Vector2i = COMBO_WINDOWS[index]
		if _attack_frame >= window.x and _attack_frame <= window.y:
			active_index = index
			break
	if active_index >= 0:
		if not _combo_window_open_raezan or _combo_window_index_raezan != active_index:
			enemy_hitbox.set_active(false)
			var step: AttackData = five_hit_attack
			if active_index < five_hit_steps.size() and five_hit_steps[active_index] != null:
				step = five_hit_steps[active_index]
			enemy_hitbox.configure(step, _facing_right)
			enemy_hitbox.set_active(true)
			_combo_window_open_raezan = true
			_combo_window_index_raezan = active_index
		enemy_hitbox.set_active_frame(_attack_frame - COMBO_WINDOWS[active_index].x, _facing_right)
	elif _combo_window_open_raezan:
		enemy_hitbox.set_active(false)
		_combo_window_open_raezan = false
	if _attack_frame >= 68:
		_finish_raezan_attack(0.78 if _phase == 1 else 0.6)

func _start_void_step() -> void:
	_void_step_active = true
	_void_step_elapsed = 0.0
	_void_step_direction = 1.0 if _facing_right else -1.0
	_void_step_cooldown = VOID_STEP_COOLDOWN
	_attack_cooldown = 4.4 if _phase == 1 else 3.7
	_current_attack = null
	_deactivate_enemy_hitbox()
	_enter_ai_state(AIState.ATTACK)
	_play_animation(&"void_step")

func _update_void_step(delta: float) -> void:
	if health_component.is_defeated or _ai_state == AIState.DEFEATED:
		_void_step_active = false
		super._physics_process(delta)
		return
	_void_step_elapsed += delta
	if _void_step_elapsed < VOID_STEP_DURATION:
		velocity.x = _void_step_direction * (238.0 if _phase == 1 else 278.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if _void_step_elapsed >= VOID_STEP_DURATION + 0.12:
		_void_step_active = false
		velocity.x = 0.0
		_enter_ai_state(AIState.RECOVER, 0.5)

func _finish_raezan_attack(recovery: float) -> void:
	_deactivate_enemy_hitbox()
	_current_attack = null
	_attack_animation_override = &""
	_combo_window_open_raezan = false
	_enter_ai_state(AIState.RECOVER, recovery)

func _start_executioner_attack(attack: AttackData) -> void:
	super._start_executioner_attack(attack)
	if attack == null or _current_attack != attack:
		return
	var cooldown: float = 3.6 if attack == light_slash_attack else 4.3
	if attack == heavy_slash_attack or attack == vertical_slash_attack:
		cooldown = 4.6
	elif attack == horizontal_slash_attack or attack == dash_attack:
		cooldown = 4.3
	elif attack == void_burst_attack:
		cooldown = 7.4 if _phase == 1 else 6.0
	if _phase == 2:
		cooldown = maxf(3.0, cooldown - 0.7)
	_attack_cooldown = maxf(_attack_cooldown, cooldown)

func _on_hero_combat_state_changed(previous: CombatController.State, current: CombatController.State) -> void:
	if (
		current in [CombatController.State.STARTUP, CombatController.State.ACTIVE]
		and ai_enabled
		and not health_component.is_defeated
		and _guard_cooldown <= 0.0
		and _ai_state in [AIState.IDLE, AIState.APPROACH]
		and _hero != null
		and _distance_to_hero() <= 300.0
		and _random.randf() <= (phase_two_guard_chance if _phase == 2 else phase_one_guard_chance)
	):
		_guard_cooldown = 3.1 if _phase == 1 else 2.7
		_defensive_step_timer = 0.10
		_deactivate_enemy_hitbox()
		_enter_ai_state(AIState.DEFEND, 0.58 if _phase == 1 else 0.52)
		_play_animation(&"guard")
		return
	super._on_hero_combat_state_changed(previous, current)

func _on_boss_health_changed(current: float, maximum: float) -> void:
	if _phase == 1 and maximum > 0.0 and current / maximum <= phase_two_health_ratio and not health_component.is_defeated:
		_enter_phase_two()

func _enter_phase_two() -> void:
	_phase = 2
	_attack_cooldown = maxf(_attack_cooldown, 1.1)
	_ai_timer = 0.85
	minion_sprite.modulate = Color(1.08, 0.9, 1.18, 1.0)
	boss_phase_changed.emit(_phase)
	if _ai_state in [AIState.IDLE, AIState.RECOVER, AIState.APPROACH]:
		_play_animation(&"phase2_idle")

func _enter_ai_state(next_state: AIState, duration: float = 0.0) -> void:
	var previous_state: AIState = _ai_state
	if next_state == AIState.DEFEND and previous_state != AIState.DEFEND:
		_guard_animation_elapsed = 0.0
		_guard_contact_timer = 0.0
		_guard_release_timer = 0.0
	if next_state == AIState.RECOVER and _ai_state == AIState.ATTACK:
		duration = maxf(duration, 0.62 if _phase == 1 else 0.48)
	super._enter_ai_state(next_state, duration)
	if previous_state == AIState.DEFEND and next_state != AIState.DEFEND:
		_guard_release_timer = GUARD_RELEASE_SECONDS
		_play_animation(&"guard_release")
	if _phase == 2 and next_state in [AIState.IDLE, AIState.RECOVER]:
		_play_animation(&"phase2_idle")
	elif _phase == 2 and next_state == AIState.APPROACH:
		_play_animation(&"phase2_walk_forward")
	elif next_state == AIState.HIT:
		_play_animation(&"knockback" if hitstun_frames >= 36 else &"hit")
	if next_state == AIState.DEFEATED:
		_void_step_active = false
		_attack_animation_override = &""

func on_combat_hit(attacker: Node2D, attack: AttackData, damage: float) -> void:
	var was_guarding: bool = _ai_state == AIState.DEFEND
	super.on_combat_hit(attacker, attack, damage)
	if was_guarding and not health_component.is_defeated and _ai_state == AIState.DEFEND:
		_guard_contact_timer = GUARD_CONTACT_SECONDS
		_play_animation(&"guard")
		return
	if health_component.is_defeated or _ai_state != AIState.HIT:
		return
	if attack.hit_reaction == AttackData.HitReaction.KNOCKDOWN:
		# Let the authored falling sequence finish instead of cutting it off at
		# The Executioner's generic 42-tick reaction timeout.
		hitstun_frames = KNOCKBACK_STUN_FRAMES
		_play_animation(&"knockback")
	else:
		# The controlled eight-frame flinch lasts 30 ticks at its authored 16 fps.
		hitstun_frames = maxi(HIT_REACTION_STUN_FRAMES, roundi(attack.hitstun_seconds * Engine.physics_ticks_per_second))
		_play_animation(&"hit")

func _on_defeated() -> void:
	_void_step_active = false
	super._on_defeated()
