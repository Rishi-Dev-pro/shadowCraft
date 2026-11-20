extends SceneTree
## Exercise the lab controls and capture Godot's gameplay-scale output at 60 Hz.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Motion = preload("res://experimental/kai_hybrid/impact_motion.gd")
const Controller = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const Dash = preload("res://experimental/kai_hybrid/dash_motion.gd")
const STEP: float = 1.0 / 60.0
const CASES: Dictionary[String, Vector3i] = {
	"standard_front": Vector3i(0, 0, 0), "standard_back": Vector3i(0, 1, 0),
	"heavy_front": Vector3i(1, 0, 0), "heavy_back": Vector3i(1, 1, 0),
	"knockback_front": Vector3i(2, 0, 0), "knockback_back": Vector3i(2, 1, 0),
	"guard_impact": Vector3i(3, 0, 1), "heavy_to_guard": Vector3i(1, 0, 2),
	"interrupt_light": Vector3i(0, 1, 3), "repeat_heavy": Vector3i(1, 1, 4),
	"guard_to_idle": Vector3i(3, 0, 5),
}

var _errors: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var destination: String = OS.get_environment("KAI_IMPACT_CAPTURE_DIR")
	if destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var lab: Lab = LAB.instantiate() as Lab
	root.add_child(lab)
	await process_frame
	var controller: Controller = lab.controller
	var controls: HBoxContainer = lab.get_node("%ImpactControls")
	var side: OptionButton = lab.get_node("%ImpactSide")
	var reset: Button = lab.get_node("%Reset")
	var guard: Button = lab.get_node("%PoseButtons").get_child(1)
	var body: Node2D = lab.get_node("%HybridBody")
	var skeleton: Skeleton2D = body.find_child("Skeleton2D") as Skeleton2D
	var rear: Bone2D = skeleton.find_child("RightFoot") as Bone2D
	var front: Bone2D = skeleton.find_child("LeftFoot") as Bone2D
	var rest_rear: Vector2 = rear.global_position
	var rest_front: Vector2 = front.global_position
	for name: String in CASES:
		var config: Vector3i = CASES[name]
		reset.pressed.emit()
		side.select(config.y)
		if config.z in [1, 5]:
			guard.pressed.emit()
		elif config.z == 3:
			controller.request_attack(Attack.Kind.LIGHT)
			controller.advance_preview(0.248)
			_check(controller.request_attack(Attack.Kind.HEAVY), "Light attack accepts a queued Heavy Attack")
		var trigger: Button = controls.get_child(config.x + 1)
		trigger.pressed.emit()
		_check(controller.impact_active and not controller.attack_active, name + " owns the animation")
		controller.stop_playback()
		var events: Array[int] = []
		var worst: float = 0.0
		var step_limit: float = 0.0
		var last_x: float = 0.0
		var rigid: bool = true
		var frames: int = 115 if config.z == 4 else 62
		for frame: int in frames:
			if frame == 7:
				_check(not controller.request_impact(Motion.Kind.HEAVY, Motion.SourceSide.FRONT), name + " rejects repeat during recoil")
				_check(not controller.request_attack(Attack.Kind.LIGHT) and not controller.request_dash(Dash.Kind.FORWARD), name + " rejects attack and dash")
				controller.request_jump()
				controller.request_walk(1)
				_check(not controller.jump_active and not controller.walk_active, name + " rejects jump and walk")
			if config.z == 2 and frame == 21:
				guard.pressed.emit()
			if config.z == 5 and frame == 6:
				controller.request_idle()
			if config.z == 4 and frame == 56:
				trigger.pressed.emit()
				_check(controller.impact_active, name + " accepts a subsequent impact after recovery")
				controller.stop_playback()
			if controller.impact_active:
				var current: int = controller.impact.phase()
				if events.is_empty() or events.back() != current:
					events.append(current)
				var rear_target: Vector2 = rest_rear + controller.impact.foot(true)
				var front_target: Vector2 = rest_front + controller.impact.foot(false)
				worst = maxf(worst, maxf(rear.global_position.distance_to(rear_target), front.global_position.distance_to(front_target)))
				rigid = rigid and body.scale == Vector2.ONE and is_zero_approx(body.position.y)
				for bone: int in skeleton.get_bone_count():
					rigid = rigid and skeleton.get_bone(bone).scale.is_equal_approx(Vector2.ONE)
				step_limit = maxf(step_limit, absf(controller.dash_world_x - last_x))
				last_x = controller.dash_world_x
			await RenderingServer.frame_post_draw
			var pixels: Image = root.get_texture().get_image().get_region(Rect2i(700, 284, 477, 394))
			if pixels.save_png(destination.path_join("%s_%03d.png" % [name, frame])) != OK:
				_check(false, name + " capture failed")
			controller.advance_preview(STEP)
			controller.stop_playback()
		var expects_stagger: bool = config.x in [Motion.Kind.HEAVY, Motion.Kind.KNOCKBACK]
		var expects_guard: bool = config.z in [1, 2]
		_check(events.has(Motion.Phase.IMPACT) and events.has(Motion.Phase.RECOIL) and events.has(Motion.Phase.STAGGER) == expects_stagger and events.has(Motion.Phase.RECOVERY), name + " visits the expected phases")
		_check(not controller.impact_active and not controller.attack_active and controller.idle_active != expects_guard, name + " returns to its selected grounded exit")
		_check(worst < 0.14 and rigid, "%s maximum boot error %.5f px; unit scale %s" % [name, worst, rigid])
		var travel: float = Motion.PUSH_DISTANCE * (-1.0 if config.y == 0 else 1.0) if config.x == Motion.Kind.KNOCKBACK else 0.0
		_check(is_equal_approx(controller.dash_world_x, travel) and step_limit < 10.0,
			"%s reaches %.2f px without next-frame teleport" % [name, travel])
	reset.pressed.emit()
	_check(not controller.request_impact(Motion.Kind.GUARD, Motion.SourceSide.FRONT), "Guard impact requires approved guard")
	guard.pressed.emit()
	_check(not controller.request_impact(Motion.Kind.GUARD, Motion.SourceSide.BACK), "Back attack cannot be blocked with forward guard")
	reset.pressed.emit()
	controller.request_attack(Attack.Kind.LIGHT)
	controller.advance_preview(0.12)
	_check(not controller.request_impact(Motion.Kind.STANDARD, Motion.SourceSide.BACK) and controller.attack_active,
		"Painted contact finishes without an incompatible skeletal interruption")
	reset.pressed.emit()
	controller.request_jump()
	_check(not controller.request_impact(Motion.Kind.STANDARD, Motion.SourceSide.FRONT), "Airborne reaction is rejected")
	await _test_walls(lab)
	print("Impact verification failures: ", _errors)
	quit(int(_errors != 0))


func _test_walls(lab: Lab) -> void:
	var collider: CharacterBody2D = lab.get_node("%DashCollider")
	var wall: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(2.0, 176.0)
	shape.shape = rectangle
	wall.add_child(shape)
	collider.get_parent().add_child(wall)
	for side: Motion.SourceSide in [Motion.SourceSide.FRONT, Motion.SourceSide.BACK]:
		lab.get_node("%Reset").pressed.emit()
		var sign_x: float = -1.0 if side == Motion.SourceSide.FRONT else 1.0
		var origin: Vector2 = collider.global_position
		wall.global_position = origin + Vector2(sign_x * 59.0, -88.0)
		await physics_frame
		await process_frame
		_check(lab.controller.request_impact(Motion.Kind.KNOCKBACK, side), "Starts knockback near thin wall")
		lab.controller.advance_preview(Motion.PUSH_TIME)
		lab.controller.stop_playback()
		var distance: float = (collider.global_position.x - origin.x) * sign_x
		_check(lab.controller.impact.blocked and distance > 25.0 and distance <= 27.001 and collider.global_position.y == origin.y,
			"Swept wall stop %.2f px with fixed floor height" % distance)
		lab.controller.advance_preview(1.0)
		_check(is_equal_approx((collider.global_position.x - origin.x) * sign_x, distance), "Blocked displacement holds through recovery")
	wall.queue_free()


func _check(valid: bool, description: String) -> void:
	if valid:
		print("PASS ", description)
	else:
		_errors += 1
		push_error(description)
