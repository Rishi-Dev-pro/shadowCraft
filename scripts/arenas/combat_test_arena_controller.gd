class_name CombatTestArenaController
extends Node2D

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

func _process(_delta: float) -> void:
	if kai.use_simulated_input and OS.get_cmdline_user_args().has("--combat-showcase"):
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
