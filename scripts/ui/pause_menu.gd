extends CanvasLayer

const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")

var _panel: PanelContainer
var _resume_button: Button
var _world_map_button: Button
var _change_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()
	visible = false

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene != null and scene.has_meta(&"round_finished"):
		return
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT):
		return
	if InputMap.has_action("pause_menu") and Input.is_action_just_pressed("pause_menu"):
		_toggle_pause()

func _build_menu() -> void:
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.015, 0.01, 0.025, 0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(400.0, 280.0)
	_panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	_panel.add_child(column)
	var heading: Label = Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color(0.92, 0.82, 1.0))
	column.add_child(heading)
	_resume_button = _make_button("RESUME")
	_world_map_button = _make_button("WORLD MAP")
	_change_button = _make_button("CHANGE CHARACTER")
	column.add_child(_resume_button)
	column.add_child(_world_map_button)
	column.add_child(_change_button)
	_resume_button.pressed.connect(_resume)
	_world_map_button.pressed.connect(_open_world_map)
	_change_button.pressed.connect(_change_character)

func _make_button(text_value: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(320.0, 54.0)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.09, 0.065, 0.12), Color(0.62, 0.4, 0.82)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.17, 0.09, 0.23), Color(0.88, 0.66, 1.0)))
	return button

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style

func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.035, 0.065, 0.98)
	style.border_color = Color(0.57, 0.35, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	return style

func _toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_resume_button.grab_focus()

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _open_world_map() -> void:
	visible = false
	get_tree().paused = false
	var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	if progression != null:
		progression.end_guardian_encounter()
	var error: Error = get_tree().change_scene_to_file("res://scenes/ui/world_map.tscn")
	if error != OK:
		push_error("Could not return to world map: " + error_string(error))

func _change_character() -> void:
	visible = false
	get_tree().paused = false
	var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	if progression != null:
		progression.end_guardian_encounter()
	var error: Error = get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	if error != OK:
		push_error("Could not return to character selection: " + error_string(error))
