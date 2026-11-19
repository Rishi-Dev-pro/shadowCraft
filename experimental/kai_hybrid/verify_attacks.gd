extends SceneTree
## Exercise the actual lab buttons and capture gameplay-scale renders at 60 Hz.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Lab = preload("res://experimental/kai_hybrid/kai_hybrid_lab.gd")
const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const STEP: float = 1.0 / 60.0
const CASES: Dictionary[String, Vector3i] = {
	"light": Vector3i(0, -1, 0), "guard_light": Vector3i(0, -1, 1),
	"light_light": Vector3i(0, 0, 0), "light_heavy": Vector3i(0, 1, 0),
	"heavy": Vector3i(1, -1, 0), "kick": Vector3i(2, -1, 0),
	"kick_guard": Vector3i(2, -1, 2),
}

var _errors: int = 0
var _starts: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var destination: String = OS.get_environment("KAI_ATTACK_CAPTURE_DIR")
	if destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var lab: Lab = LAB.instantiate() as Lab
	root.add_child(lab)
	await process_frame
	var controller = lab.controller
	controller.attack_started.connect(_starts.append)
	var controls: Node = lab.get_node("%Play").get_parent()
	var first_attack: int = controls.get_child_count() - Attack.NAMES.size()
	var guard: Button = lab.get_node("%PoseButtons").get_child(1)
	var reset: Button = lab.get_node("%Reset")
	var body: Node2D = lab.get_node("%HybridBody")
	var correction: Sprite2D = lab.get_node("%AttackCorrection")
	for name: String in CASES:
		var info: Vector3i = CASES[name]
		_starts.clear()
		reset.pressed.emit()
		if info.z == 1:
			guard.pressed.emit()
		(controls.get_child(first_attack + info.x) as Button).pressed.emit()
		_check(controller.attack_active, name + " starts from the selected pose")
		_check(not controller.request_attack(Attack.Kind.HEAVY), name + " rejects early repeat")
		controller.stop_playback()
		var showed_impact: bool = false
		var showed_recovery: bool = false
		var single_surface: bool = true
		for frame: int in (69 if info.y >= 0 else 53):
			if info.y >= 0 and frame == 15:
				(controls.get_child(first_attack + info.y) as Button).pressed.emit()
				_check(not controller.request_attack(Attack.Kind.HEAVY), name + " rejects a second buffered request")
			if info.z == 2 and frame == 14:
				guard.pressed.emit()
			if controller.attack_active:
				showed_impact = showed_impact or controller.attack_phase == Attack.Phase.IMPACT
				showed_recovery = showed_recovery or controller.attack_phase == Attack.Phase.RECOVERY
				single_surface = single_surface and body.visible != correction.visible
			var pixels: Image
			await RenderingServer.frame_post_draw
			pixels = root.get_texture().get_image().get_region(Rect2i(706, 285, 460, 390))
			if pixels.save_png(destination.path_join("%s_%03d.png" % [name, frame])) != OK:
				_check(false, name + " capture failed")
			controller.advance_preview(STEP)
			controller.stop_playback()
		var expected: Array[int] = [info.x]
		if info.y >= 0:
			expected.append(info.y)
		_check(_starts == expected, name + " plays exactly the requested attacks")
		_check(showed_impact and showed_recovery and single_surface, name + " visits impact and recovery on a single artwork surface")
		_check(not controller.attack_active and controller.idle_active == (info.z != 2), name + " releases cleanly to idle or guard")
	reset.pressed.emit()
	controller.request_attack(Attack.Kind.LIGHT)
	controller.advance_preview(0.25)
	_check(controller.request_attack(Attack.Kind.LIGHT), "Late light buffers another light")
	reset.pressed.emit()
	_check(not controller.attack_active and not correction.visible and not controller.idle_active, "Reset clears the route and queued attack")
	controller.request_jump()
	_check(not controller.request_attack(Attack.Kind.KICK), "Attack input is rejected during a jump")
	print("Attack verification failures: ", _errors)
	quit(int(_errors != 0))


func _check(valid: bool, description: String) -> void:
	if valid:
		print("PASS ", description)
	else:
		_errors += 1
		push_error(description)
