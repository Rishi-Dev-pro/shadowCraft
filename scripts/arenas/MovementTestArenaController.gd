class_name MovementTestArenaController
extends Node2D

const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/combat/hit_spark_2d.tscn")
const HIT_STOP_SCALE: float = 0.08
const JAB_HIT_STOP_SECONDS: float = 0.04
const KICK_HIT_STOP_SECONDS: float = 0.055

# ==============================================================================
# SHADOWCRAFT 2D — Movement Test Arena Controller
# ==============================================================================
# Provides live telemetry diagnostics for Player Movement & Controls.
# Displays velocity, state machine transitions, grounded state, and animations.
# Supports an optional automated showcase sequence for Movie Maker verification.
# ==============================================================================

@export var is_showcase_mode: bool = false

@onready var player: CharacterController2D = $Fighters/Kai
@onready var state_label: Label = $UI/TelemetryPanel/Margin/VBox/StateValue
@onready var velocity_label: Label = $UI/TelemetryPanel/Margin/VBox/VelocityValue
@onready var grounded_label: Label = $UI/TelemetryPanel/Margin/VBox/GroundedValue
@onready var facing_label: Label = $UI/TelemetryPanel/Margin/VBox/FacingValue
@onready var anim_label: Label = $UI/TelemetryPanel/Margin/VBox/AnimValue
@onready var dummy_target: TrainingDummy = $Fighters/DummyTarget/TrainingDummy
@onready var animation_sprite: AnimatedSprite2D = $Fighters/Kai/Skeleton2D/AnimatedSprite2D
@onready var combat: CombatController = $Fighters/Kai/CombatController
@onready var kai_health: HealthComponent = $Fighters/Kai/HealthComponent
@onready var dummy_health: HealthComponent = $Fighters/DummyTarget/TrainingDummy/HealthComponent
@onready var hitbox: Hitbox2D = $Fighters/Kai/PlayerHitbox
@onready var kai_bar: ProgressBar = $UI/KaiHealth
@onready var dummy_bar: ProgressBar = $UI/DummyHealth
@onready var combat_event_label: Label = $UI/CombatEvent

var _timer: float = 0.0
var _jump_triggered: bool = false
var _last_combat_event_time: float = 0.0
var _hit_stop_active: bool = false
var _previous_hit_stop_scale: float = 1.0
var _combat_showcase: bool = false
var _showcase_whiff_done: bool = false
var _showcase_jab_done: bool = false
var _showcase_kick_done: bool = false
var _showcase_summary_logged: bool = false

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--showcase"):
		is_showcase_mode = true
	if player != null and dummy_target != null:
		player.target_opponent = dummy_target
		player.collision_mask |= 1 << 2
	if kai_health != null:
		kai_health.health_changed.connect(_update_kai_health)
		_update_kai_health(kai_health.current_health, kai_health.max_health)
	if dummy_health != null:
		dummy_health.health_changed.connect(_update_dummy_health)
		_update_dummy_health(dummy_health.current_health, dummy_health.max_health)
	combat.combat_state_changed.connect(_on_combat_state_changed)
	combat.hit_landed.connect(_on_hit_landed)
	dummy_target.hit_taken.connect(_on_dummy_hit)
	hitbox.debug_draw = OS.get_cmdline_user_args().has("--combat-debug")
	if hitbox.debug_draw:
		hitbox.queue_redraw()
	_combat_showcase = OS.get_cmdline_user_args().has("--integration-showcase")
	if _combat_showcase:
		player.use_simulated_input = true

func _physics_process(delta: float) -> void:
	if (is_showcase_mode or _combat_showcase) and player != null:
		_process_showcase(delta)

func _process(_delta: float) -> void:
	if player == null:
		return
	
	if state_label != null:
		state_label.text = "STATE: %s" % _state_to_string(player.current_state)
	
	if velocity_label != null:
		velocity_label.text = "X: %.1f | Y: %.1f px/s" % [player.velocity.x, player.velocity.y]
	
	if grounded_label != null:
		grounded_label.text = "Grounded: %s" % ["YES (on floor)" if player.is_on_floor() else "NO (airborne)"]
	
	if facing_label != null:
		facing_label.text = "Facing: %s" % ["RIGHT" if player.is_facing_right else "LEFT"]
	
	if anim_label != null:
		if animation_sprite != null:
			anim_label.text = "Animation: %s" % animation_sprite.animation
		elif player.anim_player != null:
			anim_label.text = "Animation: %s" % player.anim_player.current_animation
	if combat != null and state_label != null and combat.current_state != CombatController.State.NEUTRAL:
		state_label.text = "STATE: COMBAT %s" % _combat_state_name(combat.current_state)
	if _last_combat_event_time > 0.0 and Time.get_ticks_msec() / 1000.0 - _last_combat_event_time > 2.2 and combat_event_label != null:
		combat_event_label.text = "Z  Light Jab     X  Front Kick"

func _process_showcase(delta: float) -> void:
	if _combat_showcase:
		_process_combat_showcase(delta)
		return
	_timer += delta
	if _timer < 1.0:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 2.0:
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 3.0:
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(false)
		player.simulate_run(true)
	elif _timer < 4.0:
		player.simulate_horizontal_input(-1.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 5.0:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(true)
		player.simulate_run(false)
	elif _timer < 6.0:
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(true)
		player.simulate_run(false)
	elif _timer < 6.1:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 6.2:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
		if not _jump_triggered:
			player.simulate_jump()
			_jump_triggered = true
	elif _timer < 7.1:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	else:
		player.reset_simulated_input()

func _process_combat_showcase(delta: float) -> void:
	_timer += delta
	if _timer < 0.65:
		player.simulate_horizontal_input(1.0)
		player.simulate_run(true)
	elif _timer < 0.95:
		player.simulate_horizontal_input(-1.0)
		player.simulate_run(false)
	elif _timer < 1.05:
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.12:
		dummy_target.global_position.x = 1200.0
		player.simulate_horizontal_input(0.0)
		if not _showcase_whiff_done and combat.start_attack(combat.punch_attack):
			_showcase_whiff_done = true
			print("[IntegrationShowcase] Jab whiff at Kai %s, target %s" % [player.global_position, dummy_target.global_position])
	elif _timer < 1.45:
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.50:
		dummy_target.global_position.x = 960.0
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.62:
		player.simulate_crouch(true)
	elif _timer < 1.82:
		player.simulate_crouch(false)
	elif _timer < 2.20:
		player.simulate_horizontal_input(0.0)
	elif _timer < 2.36:
		player.simulate_horizontal_input(0.0)
		if not _showcase_jab_done and combat.start_attack(combat.punch_attack):
			_showcase_jab_done = true
			print("[IntegrationShowcase] Jab at Kai %s, target %s, floor=%s" % [player.global_position, dummy_target.global_position, player.is_on_floor()])
	elif _timer < 2.63:
		pass
	elif _timer < 2.78:
		if not _showcase_kick_done and combat.start_attack(combat.kick_attack):
			_showcase_kick_done = true
			print("[IntegrationShowcase] Kick at Kai %s, target %s, floor=%s" % [player.global_position, dummy_target.global_position, player.is_on_floor()])
	elif _timer < 2.98:
		pass
	elif _timer < 3.06:
		player.simulate_horizontal_input(0.0)
		if not _jump_triggered:
			player.simulate_jump()
			_jump_triggered = true
	elif _timer < 3.2:
		player.simulate_horizontal_input(0.0)
	else:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
		if _timer > 3.2:
			player.reset_simulated_input()
		if not _showcase_summary_logged:
			_showcase_summary_logged = true
			print("[IntegrationShowcase] End. Dummy health %.1f / %.1f; Kai pos=%s" % [dummy_health.current_health, dummy_health.max_health, player.global_position])

func _state_to_string(state: CharacterController2D.State) -> String:
	match state:
		CharacterController2D.State.IDLE:
			return "IDLE"
		CharacterController2D.State.MOVE_FORWARD:
			return "MOVE_FORWARD"
		CharacterController2D.State.MOVE_BACKWARD:
			return "MOVE_BACKWARD"
		CharacterController2D.State.CROUCH:
			return "CROUCH"
		CharacterController2D.State.JUMP:
			return "JUMP"
		CharacterController2D.State.FALL:
			return "FALL"
		_:
			return "UNKNOWN"

func _update_kai_health(current: float, maximum: float) -> void:
	kai_bar.max_value = maximum
	kai_bar.value = current

func _update_dummy_health(current: float, maximum: float) -> void:
	dummy_bar.max_value = maximum
	dummy_bar.value = current

func _on_combat_state_changed(_previous: CombatController.State, current: CombatController.State) -> void:
	if current != CombatController.State.NEUTRAL:
		state_label.text = "COMBAT: %s" % _combat_state_name(current)

func _on_hit_landed(attack: AttackData, _target: Hurtbox2D, damage: float) -> void:
	if _combat_showcase:
		print("[IntegrationShowcase] Confirmed %s hit for %.1f damage" % [attack.display_name, damage])
	combat_event_label.text = "%s  ·  %.0f damage" % [attack.display_name, damage]
	_last_combat_event_time = Time.get_ticks_msec() / 1000.0
	_play_confirmed_hit_feedback(attack)

func _on_dummy_hit(attack_name: String, damage: float) -> void:
	combat_event_label.text = "%s  ·  %.0f damage" % [attack_name, damage]
	_last_combat_event_time = Time.get_ticks_msec() / 1000.0

func _play_confirmed_hit_feedback(attack: AttackData) -> void:
	await _apply_hit_stop(attack)
	var spark: HitSpark2D = HIT_SPARK_SCENE.instantiate() as HitSpark2D
	if spark == null:
		return
	add_child(spark)
	spark.global_position = hitbox.global_position
	spark.play(attack.kind)

func _apply_hit_stop(attack: AttackData) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	_previous_hit_stop_scale = Engine.time_scale
	Engine.time_scale = minf(_previous_hit_stop_scale, HIT_STOP_SCALE)
	var duration: float = KICK_HIT_STOP_SECONDS if attack.kind == AttackData.AttackKind.KICK else JAB_HIT_STOP_SECONDS
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = _previous_hit_stop_scale
	_hit_stop_active = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _hit_stop_active:
		Engine.time_scale = _previous_hit_stop_scale
		_hit_stop_active = false

func _combat_state_name(state: CombatController.State) -> String:
	match state:
		CombatController.State.NEUTRAL: return "NEUTRAL"
		CombatController.State.STARTUP: return "STARTUP"
		CombatController.State.ACTIVE: return "ACTIVE"
		CombatController.State.RECOVERY: return "RECOVERY"
		CombatController.State.HITSTUN: return "HITSTUN"
	return "UNKNOWN"
