extends Node2D

const OpponentAI = preload("res://scripts/combat/grind/grind_opponent_ai.gd")
const BattleHud = preload("res://scripts/ui/grind_battle_hud.gd")
const Petals = preload("res://scripts/ui/grind_petals.gd")
const GRIND_LOBBY: String = "res://scenes/ui/grind_lobby.tscn"
const CONTROLS: Dictionary[StringName, int] = {
	&"grind_left": KEY_A, &"grind_right": KEY_D, &"grind_run": KEY_SHIFT, &"grind_jump": KEY_W,
	&"grind_guard": KEY_SPACE, &"grind_light": KEY_Z, &"grind_heavy": KEY_C,
}

const PROTOTYPE_CONTROLS: Dictionary[StringName, int] = {
	&"grind_crouch": KEY_S, &"grind_kick": KEY_X, &"grind_dash_back": KEY_Q, &"grind_dash_forward": KEY_E,
}

@export var experimental_fighter: PackedScene
@onready var kai: GrindDuelist = $Kai
@onready var agile: GrindDuelist = $AgileNinja
@onready var _hud: BattleHud = $Overlay/Hud
@onready var _mist: ColorRect = $Overlay/Mist
@onready var _petals: Petals = $Overlay/Petals
@onready var _impacts: Node2D = $Impacts

var live: bool = false
var complete: bool = false
var _leaving: bool = false
var _brain: OpponentAI = OpponentAI.new()
var _buffered_strike: int
var _buffer_time: float
var _queued_jump: bool
var _queued_dash: int
var _hit_pause: float
var _clock: float
var _weather_step: float
var _spark: Vector2
var _spark_age: float = 1.0
var _spark_guarded: bool
var _spark_heavy: bool


func _ready() -> void:
	_register_controls(CONTROLS)
	if experimental_fighter != null:
		var spawn: Vector2 = kai.position
		remove_child(kai)
		kai.queue_free()
		kai = experimental_fighter.instantiate() as GrindDuelist
		kai.name = "Kai"
		kai.position = spawn
		add_child(kai)
		_register_controls(PROTOTYPE_CONTROLS)
		kai.attack_committed.connect(_brain.observe_player_attack)
		_hud.show_experimental_controls()
	kai.health.health_changed.connect(_hud.set_kai_health)
	agile.health.health_changed.connect(_hud.set_enemy_health)
	_hud.set_kai_health(kai.health.current_health, kai.health.max_health)
	_hud.set_enemy_health(agile.health.current_health, agile.health.max_health)
	kai.health.defeated.connect(_finish.bind(false))
	agile.health.defeated.connect(_finish.bind(true))
	kai.strike_landed.connect(_on_hit)
	agile.strike_landed.connect(_on_hit)
	_hud.lobby_requested.connect(_return_to_lobby)
	_hud.retry_requested.connect(_retry)
	_impacts.draw.connect(_draw_impact)
	get_window().focus_entered.connect(_sync_weather)
	get_window().focus_exited.connect(_sync_weather)
	_sync_weather()
	_intro()


func _register_controls(bindings: Dictionary[StringName, int]) -> void:
	for action: StringName in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = bindings[action] as Key
			InputMap.action_add_event(action, event)


func _intro() -> void:
	kai.modulate.a = 0.0
	agile.modulate.a = 0.0
	_hud.announce("MOONVEIL COURTYARD", 0.65)
	var reveal: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal.tween_property(kai, "modulate:a", 1.0, 0.58)
	reveal.tween_property(agile, "modulate:a", 1.0, 0.58).set_delay(0.14)
	await get_tree().create_timer(1.23).timeout
	if _leaving:
		return
	live = true
	_hud.announce("FIGHT", 0.24)


func _physics_process(delta: float) -> void:
	if live:
		if Input.is_action_just_pressed(&"grind_heavy") or Input.is_action_just_pressed(&"grind_light"):
			_buffered_strike = 2 if Input.is_action_just_pressed(&"grind_heavy") else 1
			_buffer_time = 0.15
		if experimental_fighter != null:
			if Input.is_action_just_pressed(&"grind_kick"):
				_buffered_strike = 3
				_buffer_time = 0.15
			if Input.is_action_just_pressed(&"grind_dash_back"):
				_queued_dash = -1
			elif Input.is_action_just_pressed(&"grind_dash_forward"):
				_queued_dash = 1
		_queued_jump = _queued_jump or Input.is_action_just_pressed(&"grind_jump")
	if _hit_pause > 0.0:
		_hit_pause -= delta
		return
	if not live:
		kai.step(delta, agile)
		agile.step(delta, kai)
		return

	var strike: int = 0
	_buffer_time = maxf(0.0, _buffer_time - delta)
	var guard: bool = Input.is_action_pressed(&"grind_guard")
	var crouch: bool = experimental_fighter != null and Input.is_action_pressed(&"grind_crouch")
	if _buffer_time > 0.0 and kai.can_strike() and not guard and not crouch and not (_queued_dash != 0 and kai.can_dash()):
		strike = _buffered_strike
		_buffer_time = 0.0
	kai.step(delta, agile, Input.get_axis(&"grind_left", &"grind_right"), Input.is_action_pressed(&"grind_run"),
		guard, _queued_jump, strike, crouch, _queued_dash)
	_queued_jump = false
	_queued_dash = 0
	_brain.update(delta, agile, kai)
	agile.step(delta, kai, _brain.move, _brain.sprint, _brain.guard, false, _brain.strike)
	kai.resolve_strike(agile)
	if live:
		agile.resolve_strike(kai)


func _process(delta: float) -> void:
	_clock += delta
	_weather_step += delta
	if _weather_step >= 0.05:
		_weather_step = 0.0
		var material: ShaderMaterial = _mist.material as ShaderMaterial
		material.set_shader_parameter("atmosphere", _clock)
	if _spark_age < 0.21:
		_spark_age += delta
		_impacts.queue_redraw()


func _sync_weather() -> void:
	var focused: bool = get_window().has_focus()
	set_process(focused)
	_petals.set_running(focused)


func _on_hit(point: Vector2, guarded: bool, heavy: bool) -> void:
	_hit_pause = maxf(_hit_pause, 0.025 if guarded else (0.065 if heavy else 0.040))
	_spark = point
	_spark_age = 0.0
	_spark_guarded = guarded
	_spark_heavy = heavy
	_impacts.queue_redraw()


func _draw_impact() -> void:
	var progress: float = _spark_age / 0.21
	if progress >= 1.0:
		return
	var tone: Color = Color("#d9d5ff") if _spark_guarded else Color("#ffc3d6")
	tone.a = (1.0 - progress) * 0.84
	var power: float = 1.55 if _spark_heavy else 1.0
	for index: int in range(5):
		var ray: Vector2 = Vector2.from_angle(index * TAU / 5.0 + 0.38)
		_impacts.draw_line(_spark + ray * (6.0 + progress * 21.0), _spark + ray * (6.0 + progress * 21.0 + 21.0 * power), tone, 2.0, true)
	if _spark_guarded:
		_impacts.draw_arc(_spark, 14.0 + 32.0 * progress, -1.8, 1.8, 15, tone, 2.0, true)


func _finish(victory: bool) -> void:
	if complete:
		return
	complete = true
	live = false
	if victory:
		_brain.update(0.0, agile, kai)
	_hud.announce("K.O.", 0.48)
	await get_tree().create_timer(1.24).timeout
	if not _leaving:
		_hud.show_result(victory)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_lobby()
		get_viewport().set_input_as_handled()


func _return_to_lobby() -> void:
	if _leaving:
		return
	_leaving = true
	var error: Error = get_tree().change_scene_to_file(GRIND_LOBBY)
	if error != OK:
		_leaving = false
		push_error("Unable to return to Grind: %s" % error_string(error))


func _retry() -> void:
	var error: Error = get_tree().reload_current_scene()
	if error != OK:
		push_error("Unable to restart the first Grind encounter: %s" % error_string(error))
