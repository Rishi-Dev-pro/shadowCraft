class_name MovementTestArenaController
extends Node2D

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
@onready var dummy_target: Node2D = $Fighters/DummyTarget

var _timer: float = 0.0
var _jump_triggered: bool = false

func _ready() -> void:
	if player != null and dummy_target != null:
		player.target_opponent = dummy_target

func _physics_process(delta: float) -> void:
	if is_showcase_mode and player != null:
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
	
	if anim_label != null and player.anim_player != null:
		anim_label.text = "Animation: %s" % player.anim_player.current_animation

func _process_showcase(delta: float) -> void:
	_timer += delta
	if _timer < 0.35:
		# Walk forward on floor
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(false)
	elif _timer < 0.45:
		# Jump once while moving
		if not _jump_triggered:
			player.simulate_jump()
			_jump_triggered = true
		player.simulate_horizontal_input(1.0)
	elif _timer < 1.1:
		# In mid-air arc / descending
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.8:
		# Landed and crouching
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(true)
	else:
		player.reset_simulated_input()

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
