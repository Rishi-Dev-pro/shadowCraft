class_name Hitbox2D
extends Area2D

signal target_hit(target: Hurtbox2D, damage: float)

@export var attack_data: AttackData
@export var debug_draw: bool = false
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var attacker: Node2D
var current_active_frame: int = -1
var _hit_targets: Dictionary[int, bool] = {}
var _is_active: bool = false

func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 1 << 3
	collision_mask = 1 << 6
	attacker = get_parent() as Node2D
	area_entered.connect(_on_area_entered)
	_update_debug_draw()

func configure(data: AttackData, facing_right: bool) -> void:
	attack_data = data
	if data == null:
		return
	current_active_frame = -1
	_set_offset(data.hitbox_offset, facing_right)
	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle
	rectangle.size = data.hitbox_size
	_update_debug_draw()

func set_active_frame(frame_index: int, facing_right: bool) -> void:
	if attack_data == null:
		return
	current_active_frame = clampi(frame_index, 0, attack_data.active_frames - 1)
	_set_offset(attack_data.get_active_hitbox_offset(current_active_frame), facing_right)
	_update_debug_draw()

func _set_offset(offset: Vector2, facing_right: bool) -> void:
	var signed_x: float = absf(offset.x) * (1.0 if facing_right else -1.0)
	position = Vector2(signed_x, offset.y)

func set_active(active: bool) -> void:
	_is_active = active
	set_deferred("monitoring", active)
	collision_shape.set_deferred("disabled", not active)
	if active:
		_hit_targets.clear()
	_update_debug_draw()

func _on_area_entered(area: Area2D) -> void:
	if not _is_active or attack_data == null or not area is Hurtbox2D:
		return
	var hurtbox: Hurtbox2D = area as Hurtbox2D
	if hurtbox.get_parent() == attacker:
		return
	var target_id: int = hurtbox.get_instance_id()
	if _hit_targets.has(target_id):
		return
	var damage: float = hurtbox.receive_hit(attacker, attack_data)
	if damage > 0.0:
		_hit_targets[target_id] = true
		target_hit.emit(hurtbox, damage)

func _draw() -> void:
	if not debug_draw or not _is_active or attack_data == null:
		return
	draw_rect(Rect2(-attack_data.hitbox_size * 0.5, attack_data.hitbox_size), Color(1.0, 0.2, 0.35, 0.65), false, 2.0)

func _update_debug_draw() -> void:
	queue_redraw()
