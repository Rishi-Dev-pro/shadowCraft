extends Node

@export var movement_controller_path: NodePath = NodePath("..")
@export var animated_sprite_path: NodePath = NodePath("../Skeleton2D/AnimatedSprite2D")
@export var combat_controller_path: NodePath = NodePath("../CombatController")

@onready var movement_controller: CharacterController2D = get_node(movement_controller_path) as CharacterController2D
@onready var animated_sprite: AnimatedSprite2D = get_node(animated_sprite_path) as AnimatedSprite2D
@onready var combat_controller: CombatController = get_node_or_null(combat_controller_path) as CombatController

var _landing_active: bool = false

func _ready() -> void:
	assert(movement_controller != null, "Razen requires CharacterController2D")
	assert(animated_sprite != null, "Razen requires AnimatedSprite2D")
	movement_controller.state_changed.connect(_on_state_changed)
	movement_controller.landed.connect(_on_landed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_sync_animation()

func _process(_delta: float) -> void:
	if combat_controller != null and combat_controller.is_animation_locked():
		if animated_sprite.animation != &"landing":
			_landing_active = false
		return
	if not _landing_active:
		_sync_animation()

func _sync_animation() -> void:
	var desired: StringName = _desired_animation()
	if animated_sprite.animation != desired or (not animated_sprite.is_playing() and desired != &"jump"):
		animated_sprite.play(desired)

func _desired_animation() -> StringName:
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
	if combat_controller != null and combat_controller.is_animation_locked():
		return
	if new_state == CharacterController2D.State.JUMP:
		animated_sprite.play(&"jump")
	elif not _landing_active:
		_sync_animation()

func _on_landed(_impact_velocity_y: float) -> void:
	if combat_controller != null and combat_controller.is_animation_locked():
		return
	_landing_active = true
	animated_sprite.play(&"landing")

func _on_animation_finished() -> void:
	if animated_sprite.animation == &"jump":
		animated_sprite.pause()
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"jump") - 1
	elif animated_sprite.animation == &"landing":
		_landing_active = false
		_sync_animation()
