extends SceneTree
## Exercises the preview clock and its input routes independently of render FPS.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Controller = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const Impact = preload("res://experimental/kai_hybrid/impact_motion.gd")
const HitStop = preload("res://experimental/kai_hybrid/hit_stop.gd")
const Dash = preload("res://experimental/kai_hybrid/dash_motion.gd")
const CLIPS: Array[String] = [
	"light", "heavy", "kick", "light_no_stop", "guard", "chain_light", "chain_heavy",
	"repeat", "standard_interrupt", "heavy_interrupt", "knockback_interrupt",
	"late_guard", "walk_attack", "dash_attack", "release_hold",
]

var _errors: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab: Lab = LAB.instantiate() as Lab
	root.add_child(lab)
	await process_frame
	_verify_controls(lab)
	_verify_clock(lab.controller)
	_verify_handoffs(lab.controller)
	if not OS.get_environment("KAI_FEEL_CAPTURE_DIR").is_empty() and DisplayServer.get_name() != "headless":
		await _capture_routes(lab)
	print("Combat feel verification failures: ", _errors)
	quit(int(_errors != 0))


func _verify_controls(lab: Lab) -> void:
	var row: HBoxContainer = lab.get_node("%HitStopControls")
	var toggle: CheckButton = row.get_child(0)
	toggle.button_pressed = false
	_check(not lab.controller.hit_stop.enabled, "Developer checkbox disables hit-stop")
	toggle.button_pressed = true
	for profile: HitStop.Profile in [HitStop.Profile.LIGHT, HitStop.Profile.HEAVY, HitStop.Profile.GUARD]:
		var field: SpinBox = row.get_child(2 + 2 * int(profile))
		var previous: float = field.value
		field.value = 50.0
		_check(is_equal_approx(lab.controller.hit_stop.duration(profile), 0.05), "Duration input updates profile %d" % profile)
		field.value = previous


func _verify_clock(controller: Controller) -> void:
	var own_clock: HitStop = HitStop.new()
	_check(own_clock.request(HitStop.Profile.LIGHT), "Clock starts light stop")
	_check(not own_clock.request(HitStop.Profile.HEAVY), "Overlapping request cannot extend the hold")
	_check(is_equal_approx(own_clock.consume(0.05), 0.018), "Clock returns unused frame budget")
	var scale: float = Engine.time_scale
	for kind: Attack.Kind in [Attack.Kind.LIGHT, Attack.Kind.HEAVY, Attack.Kind.KICK]:
		controller.select_pose(Controller.Pose.NEUTRAL)
		_check(controller.request_attack(kind), "Starts " + Attack.NAMES[kind])
		controller.stop_playback()
		var cue: float = Attack.IMPACT[kind]
		controller.advance_playback(cue + 0.004)
		var held: float = controller.hit_stop.remaining
		var profile: HitStop.Profile = HitStop.Profile.LIGHT if kind == Attack.Kind.LIGHT else HitStop.Profile.HEAVY
		var expected: float = controller.hit_stop.duration(profile)
		_check(is_equal_approx(held, expected - 0.004) and controller.attack_phase == Attack.Phase.IMPACT, "Samples exact contact before holding " + Attack.NAMES[kind])
		_check(not controller.request_attack(Attack.Kind.LIGHT), "Attack input during contact is ignored")
		_check(not controller.request_impact(Impact.Kind.STANDARD, Impact.SourceSide.FRONT), "Painted contact maintains the approved interruption policy")
		controller.advance_playback(held + Attack.TOTAL[kind] - cue + 0.001)
		_check(controller.idle_active and controller.hit_stop.remaining == 0.0, "Attack releases and completes after one hold")
	controller.select_pose(Controller.Pose.GUARD)
	controller.request_impact(Impact.Kind.GUARD, Impact.SourceSide.FRONT)
	controller.stop_playback()
	controller.advance_playback(Impact.CONTACT[Impact.Kind.GUARD])
	_check(is_equal_approx(controller.hit_stop.remaining, 0.041), "Guard uses its own hold duration")
	controller.hit_stop.enabled = false
	_check(controller.hit_stop.remaining == 0.0, "Disabling during a hold releases it")
	controller.advance_playback(1.0)
	_check(not controller.impact_active and not controller.idle_active, "Guard impact settles into Guard")
	controller.select_pose(Controller.Pose.NEUTRAL)
	controller.request_attack(Attack.Kind.LIGHT)
	controller.stop_playback()
	controller.advance_playback(Attack.TOTAL[Attack.Kind.LIGHT] + 0.001)
	_check(controller.idle_active and Engine.time_scale == scale, "Disabled playback stays immediate and app timing is unchanged")
	controller.hit_stop.enabled = true
	controller.select_pose(Controller.Pose.NEUTRAL)
	controller.request_attack(Attack.Kind.LIGHT)
	controller.advance_playback(Attack.IMPACT[Attack.Kind.LIGHT])
	controller.select_pose(Controller.Pose.NEUTRAL)
	_check(controller.hit_stop.remaining == 0.0 and not controller.attack_active, "Reset clears an active hold")


func _verify_handoffs(controller: Controller) -> void:
	controller.select_pose(Controller.Pose.NEUTRAL)
	controller.request_walk(1)
	controller.stop_playback()
	controller.advance_preview(0.19)
	_check(controller.request_attack(Attack.Kind.KICK), "Walk queues one attack")
	_check(not controller.request_attack(Attack.Kind.HEAVY), "A second request cannot replace the queued handoff")
	controller.advance_preview(0.20)
	_check(controller.walk_active and not controller.attack_active, "Attack waits for the final walk contact")
	controller.advance_preview(0.75)
	_check(controller.attack_active and controller.attack_kind == Attack.Kind.KICK and not controller.walk_active, "Walk settles into the requested attack")
	controller.select_pose(Controller.Pose.NEUTRAL)
	controller.reset_dash_origin()
	controller.request_dash(Dash.Kind.FORWARD)
	controller.stop_playback()
	_check(controller.request_attack(Attack.Kind.LIGHT), "Dash queues an attack during preparation")
	controller.advance_preview(0.24)
	_check(controller.dash_active and not controller.attack_active, "Queued attack leaves the dash burst intact")
	controller.advance_preview(0.4)
	_check(controller.attack_active and is_equal_approx(controller.dash_world_x, Dash.DISTANCE[Dash.Kind.FORWARD]), "Dash finishes travel and recovery before the attack")
	controller.select_pose(Controller.Pose.NEUTRAL)
	controller.reset_dash_origin()
	controller.request_attack(Attack.Kind.HEAVY)
	controller.stop_playback()
	controller.advance_preview(Attack.RECOVERY[Attack.Kind.HEAVY] + 0.015)
	controller.request_pose(Controller.Pose.GUARD)
	controller.advance_preview(0.22)
	_check(controller.walk_active and not controller.attack_active, "Late Guard transitions through the ground blend")
	controller.advance_preview(0.30)
	_check(not controller.walk_active and controller.get("_pose") == Controller.Pose.GUARD, "Late Guard settles to the approved pose")


func _capture_routes(lab: Lab) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var directory: String = OS.get_environment("KAI_FEEL_CAPTURE_DIR")
	var controller: Controller = lab.controller
	lab.get_node("%Reset").pressed.emit()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(directory.path_join("lab_controls.png")) == OK, "Captured the complete lab controls at gameplay scale")
	if OS.get_cmdline_user_args().has("controls-only"):
		return
	for name: String in CLIPS:
		lab.get_node("%Reset").pressed.emit()
		controller.hit_stop.enabled = name != "light_no_stop"
		match name:
			"guard":
				controller.select_pose(Controller.Pose.GUARD)
				controller.request_impact(Impact.Kind.GUARD, Impact.SourceSide.FRONT)
			"heavy":
				controller.request_attack(Attack.Kind.HEAVY)
			"late_guard":
				controller.request_attack(Attack.Kind.HEAVY)
			"kick":
				controller.request_attack(Attack.Kind.KICK)
			"walk_attack":
				controller.request_walk(1)
			"dash_attack":
				controller.request_dash(Dash.Kind.FORWARD)
			_:
				controller.request_attack(Attack.Kind.LIGHT)
		controller.stop_playback()
		for index: int in (118 if name in ["walk_attack", "knockback_interrupt", "heavy_interrupt"] else 99):
			_apply_clip_input(controller, name, index)
			await RenderingServer.frame_post_draw
			var pixels: Image = root.get_texture().get_image().get_region(Rect2i(700, 284, 477, 394))
			if pixels.save_png(directory.path_join("%s_%03d.png" % [name, index])) != OK:
				_check(false, "Could not save " + name)
			controller.advance_playback(1.0 / 60.0)
			controller.stop_playback()
		print("Captured ", name)


func _apply_clip_input(controller: Controller, name: String, frame: int) -> void:
	if frame == 17:
		match name:
			"chain_light", "repeat":
				_check(controller.request_attack(Attack.Kind.LIGHT), name + " queues Light during recovery")
			"chain_heavy":
				_check(controller.request_attack(Attack.Kind.HEAVY), "Light queues Heavy during recovery")
			"standard_interrupt":
				_check(controller.request_impact(Impact.Kind.STANDARD, Impact.SourceSide.FRONT), "Standard hit interrupts skeletal recovery")
			"heavy_interrupt":
				_check(controller.request_impact(Impact.Kind.HEAVY, Impact.SourceSide.BACK), "Heavy hit interrupts skeletal recovery")
			"knockback_interrupt":
				_check(controller.request_impact(Impact.Kind.KNOCKBACK, Impact.SourceSide.FRONT), "Knockback interrupts skeletal recovery")
	if name == "repeat" and frame == 41:
		_check(controller.request_attack(Attack.Kind.LIGHT), "A second recovery accepts one further Light")
	if name == "late_guard" and frame == 35:
		controller.request_pose(Controller.Pose.GUARD)
	if name in ["walk_attack", "dash_attack"] and frame == 11:
		_check(controller.request_attack(Attack.Kind.LIGHT), name + " accepts a grounded handoff")
	if name == "release_hold" and frame == 8:
		_check(controller.hit_stop.remaining > 0.0, "Live toggle interrupts a contact hold")
		controller.hit_stop.enabled = false


func _check(valid: bool, description: String) -> void:
	if valid:
		print("PASS ", description)
	else:
		_errors += 1
		push_error(description)
