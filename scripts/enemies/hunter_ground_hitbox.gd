extends Hitbox2D
## The ground pulse is confined to the current opponent's existing hurtbox.
var opponent: Hurtbox2D

func _on_area_entered(area: Area2D) -> void:
	if area == opponent:
		super._on_area_entered(area)

func check_contact() -> void:
	if not is_instance_valid(opponent) or not opponent.monitorable:
		return
	var target_shape: CollisionShape2D = opponent.get_node("CollisionShape2D")
	if not target_shape.disabled and collision_shape.shape.collide(collision_shape.global_transform,target_shape.shape,target_shape.global_transform):
		_on_area_entered(opponent)
