class_name CharacterController2D
extends CharacterBody2D

# ==============================================================================
# SHADOWCRAFT 2D — Player Movement & Control System
# ==============================================================================
# Pure 2D Kinematic movement for humanoid fighting game characters.
# Features:
# - Acceleration, deceleration, friction, gravity, terminal velocity clamp.
# - Clean FSM (IDLE, MOVE_FORWARD, MOVE_BACKWARD, CROUCH, JUMP, FALL).
# - Crouching with dynamic collision capsule resizing (jump locked).
# - Automatic or manual facing with visual-only flipping (scale.x).
# - Deterministic floor and wall collision handling via move_and_slide().
# - Input Map driven with optional simulated input mode for automated testing.
# - Separated kinematics calculation for pure headless unit testing.
# ==============================================================================

signal state_changed(old_state: State, new_state: State)
signal landed(impact_velocity_y: float)
signal facing_changed(is_facing_right: bool)

enum State {
	IDLE,
	MOVE_FORWARD,
	MOVE_BACKWARD,
	CROUCH,
	JUMP,
	FALL
}

# --- Configuration Properties ---
@export_group("Identity & Data")
@export var character_data: CharacterData

@export_group("Locomotion")
@export var walk_speed: float = 220.0
@export var walk_backward_speed: float = 180.0
@export var ground_acceleration: float = 1800.0
@export var ground_friction: float = 2200.0
@export var air_acceleration: float = 800.0
@export var air_friction: float = 300.0
@export var walk_cycle_speed: float = 80.0
@export var run_speed: float = 300.0
@export var crouch_walk_speed: float = 90.0
@export var crouch_backward_speed: float = 75.0
@export var external_animation_control: bool = false
@export var enable_run_and_crouch_walk: bool = false
@export var visual_scale: float = 0.48

@export_group("Jumping & Gravity")
@export var jump_velocity: float = -420.0
@export var gravity: float = 980.0
@export var max_fall_speed: float = 1200.0

@export_group("Collision Heights")
@export var standing_height: float = 320.0
@export var crouch_height: float = 200.0
@export var collision_radius: float = 28.0

@export_group("Input Action Bindings")
@export var action_forward: String = "move_forward"
@export var action_backward: String = "move_backward"
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_jump: String = "jump"
@export var action_crouch: String = "crouch"
@export var action_run: String = "run"

# --- State Variables ---
var current_state: State = State.IDLE
var is_facing_right: bool = true
var is_grounded: bool = true
var is_running: bool = false
var target_opponent: Node2D = null
var combat_motion_locked: bool = false
## Set by CombatController while a crouched-stance attack owns the character.
## Combat suppresses normal crouch input, so without this flag the posture would
## be dropped on the first attack frame and the character would stand up mid-move.
var combat_crouch_lock: bool = false

# --- Simulated Input (for automated unit tests) ---
var use_simulated_input: bool = false
var sim_horizontal_axis: float = 0.0
var sim_jump_pressed: bool = false
var sim_jump_just_pressed: bool = false
var sim_crouch_pressed: bool = false
var sim_run_requested: bool = false
var override_floor_detection: bool = false
var sim_is_on_floor: bool = true

# --- Node References ---
@onready var skeleton: Skeleton2D = get_node_or_null("Skeleton2D") as Skeleton2D
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
@onready var collision_shape: CollisionShape2D = get_node_or_null("MovementCollision")

# --- Private Internal Variables ---
var _capsule_shape: CapsuleShape2D
var _was_on_floor_last_frame: bool = true

func _ready() -> void:
	_ensure_references()
	
	# Configure physics collision layers
	collision_layer = 2 # Layer 2: player_body
	collision_mask = 1  # Layer 1: environment
	
	# Load baseline stats from CharacterData if provided
	if character_data != null:
		walk_speed = character_data.base_walk_speed
		jump_velocity = character_data.jump_velocity
	
	# Ensure capsule shape exists and is uniquely instanced
	_setup_collision_shape()
	if anim_player != null and not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
	
	# Initial state entry
	_enter_state(State.IDLE)

func _ensure_references() -> void:
	if skeleton == null:
		skeleton = get_node_or_null("Skeleton2D")
	if anim_player == null:
		anim_player = get_node_or_null("AnimationPlayer")
	if collision_shape == null:
		collision_shape = get_node_or_null("MovementCollision")

func _setup_collision_shape() -> void:
	_ensure_references()
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "MovementCollision"
		add_child(collision_shape)
	
	if collision_shape.shape is CapsuleShape2D:
		_capsule_shape = collision_shape.shape.duplicate()
	else:
		_capsule_shape = CapsuleShape2D.new()
		_capsule_shape.radius = collision_radius
		_capsule_shape.height = standing_height
	
	collision_shape.shape = _capsule_shape
	_set_standing_collision()

func _physics_process(delta: float) -> void:
	_ensure_references()
	
	# 1. Update facing direction
	_process_facing()
	
	# 2. Gather input
	var move_input: float = 0.0 if combat_motion_locked else _get_horizontal_input()
	var jump_requested: bool = false if combat_motion_locked else _is_jump_just_pressed()
	var crouch_requested: bool = false if combat_motion_locked else _is_crouch_pressed()
	# A crouched attack holds the crouch posture for its whole duration.
	if combat_motion_locked and combat_crouch_lock:
		crouch_requested = true
	var run_requested: bool = false if combat_motion_locked else _is_run_pressed()
	var on_floor: bool = _check_is_on_floor()
	
	# 3. Update Kinematics & State Machine
	update_kinematics(delta, move_input, jump_requested, crouch_requested, on_floor, run_requested)
	
	# 4. Apply physics movement and collision if physics space is valid
	var impact_velocity_y: float = velocity.y
	if is_inside_tree() and get_world_2d() != null:
		move_and_slide()
		on_floor = is_on_floor()
	
	# 5. Check landing transition
	var landed_this_frame: bool = not _was_on_floor_last_frame and on_floor
	if landed_this_frame:
		emit_signal("landed", maxf(impact_velocity_y, 0.0))
		velocity.y = 0.0
		if crouch_requested:
			_change_state(State.CROUCH)
		elif absf(move_input) > 0.05:
			_change_state(_get_movement_state(move_input))
		else:
			_change_state(State.IDLE)
	
	_was_on_floor_last_frame = on_floor
	is_grounded = on_floor
	
	# Keep the state and cycle phase tied to the velocity actually applied.
	if on_floor and not crouch_requested and not jump_requested:
		if absf(velocity.x) > 2.0:
			_change_state(_get_movement_state(signf(velocity.x)))
		else:
			velocity.x = 0.0
			_change_state(State.IDLE)
	_update_animation()
	if landed_this_frame and not external_animation_control:
		_play_animation("loco/jump_land", 0.04)

# --- Kinematics & State Calculation (Separated for Pure Testability) ---

func update_kinematics(delta: float, move_input: float, jump_requested: bool, crouch_requested: bool, on_floor: bool, run_requested: bool = false) -> void:
	is_running = false
	# A crouch release cannot grow the capsule into a ceiling or nearby platform.
	if on_floor and current_state == State.CROUCH and not crouch_requested and not _can_stand_up():
		crouch_requested = true
	# Vertical physics
	if not on_floor:
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)
		
		# Airborne state selection
		if velocity.y < 0.0:
			_change_state(State.JUMP)
		else:
			_change_state(State.FALL)
		
		# Air drift
		if absf(move_input) > 0.05:
			var target_vx: float = move_input * walk_speed
			velocity.x = move_toward(velocity.x, target_vx, air_acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, air_friction * delta)
		return
	
	# Grounded behavior
	if crouch_requested:
		# CROUCH: Strictly locks jump; V2 can use a guarded low step when enabled.
		_change_state(State.CROUCH)
		var crouch_target_speed: float = 0.0
		if enable_run_and_crouch_walk and absf(move_input) > 0.05:
			var crouch_move_state: State = _get_movement_state(move_input)
			crouch_target_speed = crouch_backward_speed if crouch_move_state == State.MOVE_BACKWARD else crouch_walk_speed
			crouch_target_speed *= signf(move_input)
		velocity.x = move_toward(velocity.x, crouch_target_speed, ground_acceleration * delta if crouch_target_speed != 0.0 else ground_friction * delta)
		return
	
	if jump_requested and current_state != State.CROUCH:
		# JUMP: Only allowed if grounded and not crouched
		velocity.y = jump_velocity
		_change_state(State.JUMP)
		return
	
	if absf(move_input) > 0.05:
		var new_state: State = _get_movement_state(move_input)
		_change_state(new_state)
		
		var max_speed: float = walk_speed if new_state == State.MOVE_FORWARD else walk_backward_speed
		if enable_run_and_crouch_walk and new_state == State.MOVE_FORWARD and run_requested:
			max_speed = run_speed
			is_running = true
		var target_vx: float = move_input * max_speed
		velocity.x = move_toward(velocity.x, target_vx, ground_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		if absf(velocity.x) > 2.0:
			_change_state(_get_movement_state(signf(velocity.x)))
		else:
			velocity.x = 0.0
			_change_state(State.IDLE)

func _check_is_on_floor() -> bool:
	if override_floor_detection:
		return sim_is_on_floor
	return is_on_floor()

# --- Input Handling ---

func _get_horizontal_input() -> float:
	if use_simulated_input:
		return clampf(sim_horizontal_axis, -1.0, 1.0)
	
	var input_x: float = 0.0
	if InputMap.has_action(action_right) and Input.is_action_pressed(action_right):
		input_x += 1.0
	if InputMap.has_action(action_left) and Input.is_action_pressed(action_left):
		input_x -= 1.0
	
	if input_x == 0.0:
		if InputMap.has_action(action_forward) and Input.is_action_pressed(action_forward):
			input_x += 1.0 if is_facing_right else -1.0
		if InputMap.has_action(action_backward) and Input.is_action_pressed(action_backward):
			input_x -= 1.0 if is_facing_right else -1.0
	
	return clampf(input_x, -1.0, 1.0)

func _is_jump_just_pressed() -> bool:
	if use_simulated_input:
		var pressed: bool = sim_jump_just_pressed
		sim_jump_just_pressed = false
		return pressed
	
	return InputMap.has_action(action_jump) and Input.is_action_just_pressed(action_jump)

func _is_crouch_pressed() -> bool:
	if use_simulated_input:
		return sim_crouch_pressed
	
	return InputMap.has_action(action_crouch) and Input.is_action_pressed(action_crouch)

func _is_run_pressed() -> bool:
	if use_simulated_input:
		return sim_run_requested
	return InputMap.has_action(action_run) and Input.is_action_pressed(action_run)

# --- Facing Logic ---

func _process_facing() -> void:
	if target_opponent != null:
		update_facing(target_opponent.global_position.x)

func update_facing(target_x: float) -> void:
	var should_face_right: bool = global_position.x <= target_x
	set_facing(should_face_right)

func set_facing(face_right: bool) -> void:
	_ensure_references()
	if is_facing_right != face_right:
		is_facing_right = face_right
		if skeleton != null:
			# Visual flip only: root CharacterBody2D remains unscaled Vector2(1, 1)
			skeleton.scale.x = visual_scale if is_facing_right else -visual_scale
			skeleton.scale.y = visual_scale
		emit_signal("facing_changed", is_facing_right)

# --- State Management & Transitions ---

func _get_movement_state(move_input: float) -> State:
	var moving_right: bool = move_input > 0.0
	if moving_right == is_facing_right:
		return State.MOVE_FORWARD
	else:
		return State.MOVE_BACKWARD

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	var old_state: State = current_state
	_exit_state(old_state)
	current_state = new_state
	_enter_state(new_state)
	emit_signal("state_changed", old_state, new_state)

func _enter_state(state: State) -> void:
	match state:
		State.CROUCH:
			_set_crouch_collision()
		State.IDLE, State.MOVE_FORWARD, State.MOVE_BACKWARD, State.JUMP, State.FALL:
			_set_standing_collision()

func _exit_state(state: State) -> void:
	match state:
		State.CROUCH:
			_set_standing_collision()

# --- Collision Resizing ---

func _set_standing_collision() -> void:
	_ensure_references()
	if _capsule_shape != null and collision_shape != null:
		_capsule_shape.height = standing_height
		_capsule_shape.radius = collision_radius
		collision_shape.position = Vector2(0.0, -standing_height * 0.5)

func _can_stand_up() -> bool:
	if current_state != State.CROUCH or collision_shape == null or _capsule_shape == null:
		return true
	_set_standing_collision()
	var blocked: bool = is_inside_tree() and get_world_2d() != null and test_move(global_transform, Vector2(0.0, -1.0))
	if blocked:
		_set_crouch_collision()
	return not blocked

func _set_crouch_collision() -> void:
	_ensure_references()
	if _capsule_shape != null and collision_shape != null:
		_capsule_shape.height = crouch_height
		_capsule_shape.radius = collision_radius
		collision_shape.position = Vector2(0.0, -crouch_height * 0.5)

# --- Animation Integration ---

func _update_animation() -> void:
	if external_animation_control:
		return
	_ensure_references()
	if anim_player == null or not anim_player.has_animation_library("loco"):
		return
	
	match current_state:
		State.IDLE:
			_play_animation("loco/idle")
		State.MOVE_FORWARD:
			_play_animation("loco/walk_fwd")
		State.MOVE_BACKWARD:
			_play_animation("loco/walk_bwd")
		State.CROUCH:
			_play_animation("loco/crouch")
		State.JUMP, State.FALL:
			_play_animation("loco/jump_air", 0.12)
	if current_state == State.MOVE_FORWARD or current_state == State.MOVE_BACKWARD:
		anim_player.speed_scale = clampf(absf(velocity.x) / walk_cycle_speed, 0.35, 3.0)
	else:
		anim_player.speed_scale = 1.0

func _play_animation(anim_name: String, blend_seconds: float = 0.12) -> void:
	_ensure_references()
	if anim_player != null:
		if anim_player.current_animation != anim_name or not anim_player.is_playing():
			anim_player.play(anim_name, blend_seconds)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"loco/jump_land":
		_update_animation()

# --- Helper Methods for Automated Unit Testing ---

func simulate_horizontal_input(axis: float) -> void:
	use_simulated_input = true
	sim_horizontal_axis = axis

func simulate_jump() -> void:
	use_simulated_input = true
	sim_jump_just_pressed = true

func simulate_crouch(crouched: bool) -> void:
	use_simulated_input = true
	sim_crouch_pressed = crouched

func simulate_run(running: bool) -> void:
	use_simulated_input = true
	sim_run_requested = running

func set_simulated_on_floor(on_floor: bool) -> void:
	override_floor_detection = true
	sim_is_on_floor = on_floor
	is_grounded = on_floor

func reset_simulated_input() -> void:
	use_simulated_input = false
	override_floor_detection = false
	sim_horizontal_axis = 0.0
	sim_jump_pressed = false
	sim_jump_just_pressed = false
	sim_crouch_pressed = false
	sim_run_requested = false
	sim_is_on_floor = true
