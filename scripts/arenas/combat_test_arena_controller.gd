class_name CombatTestArenaController
extends Node2D

const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/combat/hit_spark_2d.tscn")
const HIT_STOP_SCALE: float = 0.08
const JAB_HIT_STOP_SECONDS: float = 0.04
const KICK_HIT_STOP_SECONDS: float = 0.055

@onready var kai: CharacterController2D = $Fighters/Kai
@onready var dummy: TrainingDummy = $Fighters/TrainingDummy
@onready var kai_health: HealthComponent = $Fighters/Kai/HealthComponent
@onready var dummy_health: HealthComponent = $Fighters/TrainingDummy/HealthComponent
@onready var kai_bar: ProgressBar = $UI/KaiHealth
@onready var dummy_bar: ProgressBar = $UI/DummyHealth
@onready var state_label: Label = $UI/Telemetry
@onready var event_label: Label = $UI/CombatEvent
@onready var hitbox: Hitbox2D = $Fighters/Kai/PlayerHitbox

var _last_event_time: float = 0.0
var _showcase_time: float = 0.0
var _showcase_jab_started: bool = false
var _showcase_kick_started: bool = false
var _hit_stop_active: bool = false
var _previous_hit_stop_scale: float = 1.0
var _combat_polish_showcase: bool = false
var _combat_slowmo_showcase: bool = false
var _polish_showcase_attacks: Dictionary[StringName, bool] = {}

func _ready() -> void:
	kai.target_opponent = dummy
	# Combat-only spacing: keep the existing movement scene's environment-only
	# mask unchanged while preventing Kai and the training dummy from passing
	# through one another in this dedicated arena.
	kai.collision_mask |= 1 << 2
	kai_health.health_changed.connect(_update_kai_health)
	dummy_health.health_changed.connect(_update_dummy_health)
	$Fighters/Kai/CombatController.combat_state_changed.connect(_on_combat_state_changed)
	$Fighters/Kai/CombatController.hit_landed.connect(_on_hit_landed)
	dummy.hit_taken.connect(_on_dummy_hit)
	_update_kai_health(kai_health.current_health, kai_health.max_health)
	_update_dummy_health(dummy_health.current_health, dummy_health.max_health)
	hitbox.debug_draw = OS.get_cmdline_user_args().has("--combat-debug")
	if hitbox.debug_draw:
		hitbox.queue_redraw()
	if OS.get_cmdline_user_args().has("--combat-showcase"):
		kai.use_simulated_input = true
	if OS.get_cmdline_user_args().has("--combat-polish-showcase"):
		_combat_polish_showcase = true
		_combat_slowmo_showcase = OS.get_cmdline_user_args().has("--combat-slowmo")
		kai.use_simulated_input = true
		if _combat_slowmo_showcase:
			Engine.time_scale = 0.35

func _process(_delta: float) -> void:
	if _combat_polish_showcase:
		_process_polish_showcase(_delta)
	elif kai.use_simulated_input and OS.get_cmdline_user_args().has("--combat-showcase"):
		_process_showcase(_delta)
	var controller: CombatController = $Fighters/Kai/CombatController
	var movement: String = "RIGHT" if kai.is_facing_right else "LEFT"
	state_label.text = "STATE: %s  |  FACING: %s  |  MOVE: %.0f px/s" % [_state_name(controller.current_state), movement, kai.velocity.x]
	if Time.get_ticks_msec() / 1000.0 - _last_event_time > 2.2:
		event_label.text = "Z  Light Jab     X  Front Kick"

func _process_showcase(delta: float) -> void:
	_showcase_time += delta
	if _showcase_time < 0.72:
		kai.simulate_horizontal_input(1.0)
		kai.simulate_run(true)
	elif _showcase_time < 0.9:
		kai.simulate_horizontal_input(0.0)
		kai.simulate_run(false)

func _process_polish_showcase(delta: float) -> void:
	_showcase_time += delta
	if _showcase_time < 0.25:
		event_label.text = "JAB WHIFF CHECK"
	elif _showcase_time < 0.5:
		_try_showcase_attack(&"jab_whiff", $Fighters/Kai/CombatController.punch_attack, false)
	elif _showcase_time < 0.72:
		event_label.text = "KICK WHIFF CHECK"
	elif _showcase_time < 0.95:
		_try_showcase_attack(&"kick_whiff", $Fighters/Kai/CombatController.kick_attack, false)
	elif _showcase_time < 1.2:
		kai.simulate_horizontal_input(0.0)
	elif _showcase_time < 1.82:
		kai.simulate_horizontal_input(1.0)
		kai.simulate_run(true)
	elif _showcase_time < 2.0:
		kai.simulate_horizontal_input(0.0)
		kai.simulate_run(false)
	elif _showcase_time < 2.3:
		_try_showcase_attack(&"jab_contact", $Fighters/Kai/CombatController.punch_attack, false)
	elif _showcase_time < 2.56:
		pass
	elif _showcase_time < 2.86:
		_try_showcase_attack(&"kick_contact", $Fighters/Kai/CombatController.kick_attack, false)
	elif _showcase_time < 3.12:
		pass
	elif _showcase_time < 3.4:
		_try_showcase_attack(&"jab_repeat_1", $Fighters/Kai/CombatController.punch_attack, true)
	elif _showcase_time < 3.68:
		_try_showcase_attack(&"kick_repeat_1", $Fighters/Kai/CombatController.kick_attack, true)
	elif _showcase_time < 3.96:
		_try_showcase_attack(&"jab_repeat_2", $Fighters/Kai/CombatController.punch_attack, true)
	elif _showcase_time < 4.24:
		_try_showcase_attack(&"kick_repeat_2", $Fighters/Kai/CombatController.kick_attack, true)
	else:
		kai.simulate_horizontal_input(0.0)
		kai.simulate_run(false)
		if _combat_slowmo_showcase:
			Engine.time_scale = 1.0

func _try_showcase_attack(key: StringName, attack: AttackData, reset_dummy: bool) -> void:
	if _polish_showcase_attacks.get(key, false):
		return
	if reset_dummy:
		dummy.global_position = Vector2(760.0, 640.0)
		dummy.velocity = Vector2.ZERO
	var combat: CombatController = $Fighters/Kai/CombatController
	if combat.start_attack(attack):
		_polish_showcase_attacks[key] = true
	elif _showcase_time < 1.22 and not _showcase_jab_started:
		_showcase_jab_started = $Fighters/Kai/CombatController.start_attack($Fighters/Kai/CombatController.punch_attack)
	elif _showcase_time < 1.55:
		kai.simulate_horizontal_input(0.0)
	elif _showcase_time < 1.9 and not _showcase_kick_started:
		_showcase_kick_started = $Fighters/Kai/CombatController.start_attack($Fighters/Kai/CombatController.kick_attack)
	else:
		kai.simulate_horizontal_input(0.0)
		kai.simulate_run(false)

func _update_kai_health(current: float, maximum: float) -> void:
	kai_bar.max_value = maximum
	kai_bar.value = current

func _update_dummy_health(current: float, maximum: float) -> void:
	dummy_bar.max_value = maximum
	dummy_bar.value = current

func _on_combat_state_changed(_previous: CombatController.State, current: CombatController.State) -> void:
	state_label.text = "COMBAT: %s" % _state_name(current)

func _on_hit_landed(attack: AttackData, _target: Hurtbox2D, damage: float) -> void:
	event_label.text = "%s  ·  %.0f damage" % [attack.display_name, damage]
	_last_event_time = Time.get_ticks_msec() / 1000.0
	_play_confirmed_hit_feedback(attack)

func _play_confirmed_hit_feedback(attack: AttackData) -> void:
	await _apply_hit_stop(attack)
	_spawn_hit_spark(attack)

func _spawn_hit_spark(attack: AttackData) -> void:
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
	var stop_duration: float = KICK_HIT_STOP_SECONDS if attack.kind == AttackData.AttackKind.KICK else JAB_HIT_STOP_SECONDS
	await get_tree().create_timer(stop_duration, true, false, true).timeout
	Engine.time_scale = _previous_hit_stop_scale
	_hit_stop_active = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _hit_stop_active:
		Engine.time_scale = _previous_hit_stop_scale
		_hit_stop_active = false

func _on_dummy_hit(attack_name: String, damage: float) -> void:
	event_label.text = "%s  ·  %.0f damage" % [attack_name, damage]
	_last_event_time = Time.get_ticks_msec() / 1000.0

func _state_name(state: CombatController.State) -> String:
	match state:
		CombatController.State.NEUTRAL: return "NEUTRAL"
		CombatController.State.STARTUP: return "STARTUP"
		CombatController.State.ACTIVE: return "ACTIVE"
		CombatController.State.RECOVERY: return "RECOVERY"
		CombatController.State.HITSTUN: return "HITSTUN"
	return "UNKNOWN"
