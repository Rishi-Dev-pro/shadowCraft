class_name KaiV2AnimationController
extends Node

@export var movement_controller_path: NodePath = NodePath("..")
@export var animated_sprite_path: NodePath = NodePath("../Skeleton2D/AnimatedSprite2D")

@onready var movement_controller: CharacterController2D = get_node(movement_controller_path) as CharacterController2D
@onready var animated_sprite: AnimatedSprite2D = get_node(animated_sprite_path) as AnimatedSprite2D

var _landing_animation_active: bool = false

func _ready() -> void:
	assert(movement_controller != null, "Kai V2 requires CharacterController2D")
	assert(animated_sprite != null, "Kai V2 requires AnimatedSprite2D")
	if not movement_controller.state_changed.is_connected(_on_state_changed):
		movement_controller.state_changed.connect(_on_state_changed)
	if not movement_controller.landed.is_connected(_on_landed):
		movement_controller.landed.connect(_on_landed)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	_sync_animation()

func _process(_delta: float) -> void:
	if _landing_animation_active:
		return
	_sync_animation()

func _sync_animation() -> void:
	if movement_controller == null or animated_sprite == null:
		return
	var desired_animation: StringName = _get_desired_animation()
	if animated_sprite.animation != desired_animation:
		animated_sprite.play(desired_animation)
	elif not animated_sprite.is_playing() and desired_animation != &"jump":
		animated_sprite.play(desired_animation)

func _get_desired_animation() -> StringName:
	match movement_controller.current_state:
		CharacterController2D.State.IDLE:
			return &"idle_signature"
		CharacterController2D.State.MOVE_FORWARD:
			return &"run" if movement_controller.is_running else &"walk_forward"
		CharacterController2D.State.MOVE_BACKWARD:
			return &"walk_backward"
		CharacterController2D.State.CROUCH:
			return &"crouch_walk" if absf(movement_controller.velocity.x) > 6.0 else &"crouch"
		CharacterController2D.State.JUMP, CharacterController2D.State.FALL:
			return &"jump"
	return &"idle_signature"

func _on_state_changed(_old_state: CharacterController2D.State, new_state: CharacterController2D.State) -> void:
	if new_state == CharacterController2D.State.JUMP:
		animated_sprite.play(&"jump")
		return
	if not _landing_animation_active:
		_sync_animation()

func _on_landed(_impact_velocity_y: float) -> void:
	_landing_animation_active = true
	animated_sprite.play(&"landing")

func _on_animation_finished() -> void:
	match animated_sprite.animation:
		&"jump":
			animated_sprite.pause()
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"jump") - 1
		&"landing":
			_landing_animation_active = false
			_sync_animation()
