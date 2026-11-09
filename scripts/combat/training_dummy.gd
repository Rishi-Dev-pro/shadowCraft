class_name TrainingDummy
extends CharacterBody2D

signal hit_taken(attack_name: String, damage: float)

@export var gravity: float = 980.0
@export var horizontal_friction: float = 900.0
@onready var health_component: HealthComponent = $HealthComponent
@onready var silhouette: Node2D = $Silhouette

var hitstun_frames: int = 0
var _hit_flash_frames: int = 0
var _normal_modulate: Color = Color.WHITE

func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 1
	health_component.defeated.connect(_on_defeated)
	_normal_modulate = silhouette.modulate

func _physics_process(delta: float) -> void:
	if _hit_flash_frames > 0:
		_hit_flash_frames -= 1
		silhouette.modulate = Color(1.5, 1.2, 1.7, 1.0) if _hit_flash_frames > 0 else _normal_modulate
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	velocity.x = move_toward(velocity.x, 0.0, horizontal_friction * delta)
	if hitstun_frames > 0:
		hitstun_frames -= 1
	move_and_slide()

func on_combat_hit(attacker: Node2D, attack: AttackData, damage: float) -> void:
	var direction: float = signf(global_position.x - attacker.global_position.x)
	if is_zero_approx(direction):
		direction = 1.0
	velocity.x = direction * attack.knockback.x
	velocity.y = -absf(attack.knockback.y)
	hitstun_frames = maxi(1, roundi(attack.hitstun_seconds * Engine.physics_ticks_per_second))
	_hit_flash_frames = 6
	silhouette.modulate = Color(1.5, 1.2, 1.7, 1.0)
	var recoil_angle: float = deg_to_rad(7.0 if attack.kind == AttackData.AttackKind.KICK else 4.0)
	silhouette.rotation = 0.0
	var recoil_tween: Tween = create_tween()
	recoil_tween.tween_property(silhouette, "rotation", -direction * recoil_angle, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(silhouette, "rotation", 0.0, 0.105).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	hit_taken.emit(attack.display_name, damage)

func _on_defeated() -> void:
	silhouette.modulate = Color(0.35, 0.27, 0.36, 0.7)
	velocity = Vector2.ZERO
	set_physics_process(false)
