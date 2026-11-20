extends "res://experimental/kai_hybrid/hybrid_controller.gd"
## Runs the same pose clock against the dojo's existing CharacterBody2D.

const DISPLAY_SCALE: float = 0.7
const MARGIN: float = 0.025

var fighter: CharacterBody2D
var facing: float = 1.0
var confirm_attack: Callable


func _process(_delta: float) -> void:
	# The training adapter advances the clock in its physics callback.
	pass


func advance_walk(delta: float) -> void:
	var previous: float = walk_cycle.travel()
	super.advance_walk(delta)
	var displacement: float = (walk_cycle.travel() - previous) * DISPLAY_SCALE * facing
	if not is_zero_approx(displacement):
		fighter.move_and_collide(Vector2(displacement, 0.0), false, MARGIN)


func _plan_ground_travel(desired: float) -> float:
	var collision: KinematicCollision2D = fighter.move_and_collide(Vector2(desired * facing, 0.0), true, MARGIN)
	return desired if collision == null else collision.get_travel().x * facing


func _sweep_ground_motion(target_x: float) -> bool:
	var requested: float = target_x - dash_world_x
	if is_zero_approx(requested):
		return false
	var previous: float = fighter.global_position.x
	var collision: KinematicCollision2D = fighter.move_and_collide(Vector2(requested * facing, 0.0), false, MARGIN)
	dash_world_x += (fighter.global_position.x - previous) * facing
	return collision != null and absf(target_x - dash_world_x) > 0.05


func _uses_contact_events() -> bool:
	return true


func _accept_contact() -> bool:
	return not attack_active or (confirm_attack.is_valid() and bool(confirm_attack.call(attack_kind)))


func pose_lift() -> float:
	return _body.position.y * DISPLAY_SCALE


func guarding() -> bool:
	return _pose == Pose.GUARD and not _at_neutral and not walk_active


func bracing() -> bool:
	return walk_active and _guard_requested


func train_guard() -> void:
	idle_active = false
	_idle_exit = IdleExit.NONE
	_return_to_idle = false
	request_walk(0, true)
