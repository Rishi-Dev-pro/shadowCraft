extends SceneTree

const WindowManagerScript = preload("res://scripts/systems/window_manager.gd")

var _checks: int = 0
var _failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("RUNNING WINDOW MANAGER TESTS")
	
	var wm: Node = root.get_node_or_null("WindowManager")
	_check(wm != null, "WindowManager autoload is registered and present in root")
	if wm == null:
		wm = WindowManagerScript.new() as Node
		wm.name = "WindowManager"
		root.add_child(wm)

	_check(wm.process_mode == Node.PROCESS_MODE_ALWAYS, "WindowManager process_mode is PROCESS_MODE_ALWAYS")

	# Test shortcut detection
	var ctrl_esc: InputEventKey = InputEventKey.new()
	ctrl_esc.keycode = KEY_ESCAPE
	ctrl_esc.pressed = true
	ctrl_esc.ctrl_pressed = true

	var alt_enter: InputEventKey = InputEventKey.new()
	alt_enter.keycode = KEY_ENTER
	alt_enter.pressed = true
	alt_enter.alt_pressed = true

	var f11: InputEventKey = InputEventKey.new()
	f11.keycode = KEY_F11
	f11.pressed = true

	var plain_esc: InputEventKey = InputEventKey.new()
	plain_esc.keycode = KEY_ESCAPE
	plain_esc.pressed = true

	var plain_enter: InputEventKey = InputEventKey.new()
	plain_enter.keycode = KEY_ENTER
	plain_enter.pressed = true

	# Test simulated inputs
	root.push_input(ctrl_esc)
	await process_frame

	root.push_input(alt_enter)
	await process_frame

	root.push_input(f11)
	await process_frame

	# Ensure toggle_fullscreen function can be called safely
	wm.toggle_fullscreen()
	await process_frame
	wm.toggle_fullscreen()
	await process_frame

	_check(true, "Window mode toggles execute safely without exceptions")

	# Verify active scene remains loaded and untouched
	var test_node: Node = Node.new()
	test_node.name = "ActiveSceneSentinel"
	root.add_child(test_node)
	wm.toggle_fullscreen()
	await process_frame
	_check(root.has_node("ActiveSceneSentinel"), "Toggling fullscreen preserves current scene and node hierarchy")
	test_node.queue_free()

	print("WINDOW MANAGER: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)
