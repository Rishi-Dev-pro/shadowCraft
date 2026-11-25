class_name WindowController
extends Node

## ==============================================================================
## SHADOWCRAFT 2D — DISPLAY & WINDOW MANAGER
## ==============================================================================
## Manages seamless fullscreen / windowed mode toggling:
## - Primary Shortcut: Alt + Enter (universal PC standard).
## - Fallback Shortcuts: F11, Ctrl + Esc (if OS allows).
## - Windowed mode displays standard Windows title bar and window decorations.
## - Fullscreen restores borderless/exclusive fullscreen.
## - Does not reload scenes, preserves all game state.
## ==============================================================================

const BASE_WINDOW_SIZE: Vector2i = Vector2i(1280, 720)
var _windowed_size: Vector2i = BASE_WINDOW_SIZE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event: InputEventKey = event as InputEventKey

	var is_enter: bool = (
		key_event.keycode == KEY_ENTER 
		or key_event.physical_keycode == KEY_ENTER 
		or key_event.key_label == KEY_ENTER
		or key_event.keycode == KEY_KP_ENTER
		or key_event.physical_keycode == KEY_KP_ENTER
	)
	var is_alt: bool = key_event.alt_pressed or Input.is_key_pressed(KEY_ALT)
	var is_alt_enter: bool = is_enter and is_alt

	var is_f11: bool = (key_event.keycode == KEY_F11 or key_event.physical_keycode == KEY_F11)

	var is_esc: bool = (key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE)
	var is_ctrl: bool = key_event.ctrl_pressed or key_event.is_command_or_control_pressed() or Input.is_key_pressed(KEY_CTRL)
	var is_ctrl_esc: bool = is_esc and is_ctrl

	if is_alt_enter or is_f11 or is_ctrl_esc:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func is_fullscreen() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var mode: int = DisplayServer.window_get_mode()
	return mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())

func set_fullscreen(enable: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return

	if enable:
		if not is_fullscreen():
			var cur_size: Vector2i = DisplayServer.window_get_size()
			if cur_size.x >= 640 and cur_size.y >= 360:
				_windowed_size = cur_size
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

		var screen_id: int = DisplayServer.window_get_current_screen()
		var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_id)

		var target_w: int = _windowed_size.x
		var target_h: int = _windowed_size.y

		if usable_rect.size.x > 0 and usable_rect.size.y > 0:
			if target_w >= usable_rect.size.x or target_h >= usable_rect.size.y:
				target_w = int(float(usable_rect.size.x) * 0.85)
				target_h = int(float(usable_rect.size.y) * 0.85)

		var final_size: Vector2i = Vector2i(target_w, target_h)
		DisplayServer.window_set_size(final_size)

		if usable_rect.size.x > 0 and usable_rect.size.y > 0:
			var pos_x: int = usable_rect.position.x + (usable_rect.size.x - target_w) / 2
			var pos_y: int = usable_rect.position.y + (usable_rect.size.y - target_h) / 2
			DisplayServer.window_set_position(Vector2i(pos_x, pos_y))
