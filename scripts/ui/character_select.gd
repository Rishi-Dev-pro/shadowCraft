extends Control

const CHARACTER_IDS: Array[StringName] = [&"kai", &"razen"]
const KAI_PURPLE: Color = Color(0.68, 0.35, 0.98, 1.0)
const RAZEN_RED: Color = Color(0.92, 0.16, 0.23, 1.0)

@onready var kai_preview: AnimatedSprite2D = $PreviewLayer/KaiPreview
@onready var razen_preview: AnimatedSprite2D = $PreviewLayer/RazenPreview
@onready var selection_state: CharacterSelectionState = get_node("/root/CharacterSelection") as CharacterSelectionState

var selected_index: int = 0
var kai_button: Button
var razen_button: Button
var play_button: Button
var _card_styles: Dictionary = {}
var _positioned_nodes: Array[Dictionary] = []

func _ready() -> void:
	selected_index = 1 if selection_state.selected_character_id == &"razen" else 0
	kai_preview.play(&"idle_signature")
	razen_preview.play(&"idle_signature")
	_build_interface()
	_update_selection()
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode in [KEY_LEFT, KEY_A]:
			_set_selected_index(0)
			get_viewport().set_input_as_handled()
		elif key_event.keycode in [KEY_RIGHT, KEY_D]:
			_set_selected_index(1)
			get_viewport().set_input_as_handled()
		elif key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			_start_game()

func _build_interface() -> void:
	_positioned_nodes.clear()
	_positioned_nodes.append({"node": kai_preview, "base_pos": kai_preview.position})
	_positioned_nodes.append({"node": razen_preview, "base_pos": razen_preview.position})

	_add_label("SHADOWCRAFT 2D", Vector2(0.0, 24.0), Vector2(1280.0, 42.0), 30, Color(0.96, 0.94, 1.0), HORIZONTAL_ALIGNMENT_CENTER, true)
	_add_label("CHOOSE YOUR FIGHTER", Vector2(0.0, 72.0), Vector2(1280.0, 24.0), 15, Color(0.72, 0.68, 0.78), HORIZONTAL_ALIGNMENT_CENTER, true)

	kai_button = _add_card_button("KAI", Rect2(44.0, 128.0, 582.0, 456.0), 0)
	razen_button = _add_card_button("RAZEN", Rect2(654.0, 128.0, 582.0, 456.0), 1)
	
	_add_label("KAI V2", Vector2(72.0, 150.0), Vector2(526.0, 38.0), 26, KAI_PURPLE, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("THE SHADOW DISCIPLE", Vector2(72.0, 188.0), Vector2(526.0, 24.0), 14, Color(0.84, 0.77, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("AGILE  ·  PRECISE  ·  COUNTER-FOCUSED", Vector2(68.0, 534.0), Vector2(534.0, 25.0), 13, Color(0.78, 0.69, 0.91), HORIZONTAL_ALIGNMENT_CENTER)

	_add_label("RAZEN", Vector2(682.0, 150.0), Vector2(526.0, 38.0), 26, RAZEN_RED, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("THE CRIMSON WARLORD", Vector2(682.0, 188.0), Vector2(526.0, 24.0), 14, Color(0.97, 0.78, 0.79), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("POWERFUL  ·  DISCIPLINED  ·  PRESSURE", Vector2(678.0, 534.0), Vector2(534.0, 25.0), 13, Color(0.93, 0.71, 0.73), HORIZONTAL_ALIGNMENT_CENTER)

	play_button = Button.new()
	play_button.text = "PLAY"
	play_button.position = Vector2(510.0, 616.0)
	play_button.size = Vector2(260.0, 58.0)
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color.WHITE)
	play_button.add_theme_stylebox_override("normal", _button_style(Color(0.26, 0.12, 0.37), KAI_PURPLE, 2))
	play_button.add_theme_stylebox_override("hover", _button_style(Color(0.36, 0.18, 0.48), Color(0.92, 0.77, 1.0), 2))
	play_button.add_theme_stylebox_override("pressed", _button_style(Color(0.17, 0.08, 0.26), KAI_PURPLE, 2))
	play_button.pressed.connect(_start_game)
	add_child(play_button)
	_positioned_nodes.append({"node": play_button, "base_pos": play_button.position})

	_add_label("A / ←   KAI       D / →   RAZEN       ENTER   PLAY", Vector2(0.0, 685.0), Vector2(1280.0, 20.0), 12, Color(0.64, 0.61, 0.69), HORIZONTAL_ALIGNMENT_CENTER, true)

func _add_label(text_value: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment, is_full_width: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	_positioned_nodes.append({"node": label, "base_pos": at, "full_width": is_full_width})
	return label

func _add_card_button(button_name: String, bounds: Rect2, index: int) -> Button:
	var button: Button = Button.new()
	button.name = button_name + "Card"
	button.position = bounds.position
	button.size = bounds.size
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_card_pressed.bind(index))
	button.mouse_entered.connect(_set_selected_index.bind(index))
	add_child(button)
	_card_styles[index] = button
	_positioned_nodes.append({"node": button, "base_pos": bounds.position})
	return button

func _on_card_pressed(index: int) -> void:
	if selected_index == index:
		_start_game()
	else:
		_set_selected_index(index)

func _on_viewport_resized() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var center_offset: float = (vp_size.x - 1280.0) * 0.5
	for item: Dictionary in _positioned_nodes:
		var node: CanvasItem = item.get("node") as CanvasItem
		if node == null:
			continue
		var base_pos: Vector2 = item.get("base_pos", Vector2.ZERO)
		if item.get("full_width", false) and node is Control:
			var ctrl: Control = node as Control
			ctrl.position.x = 0.0
			ctrl.size.x = vp_size.x
		else:
			node.position.x = base_pos.x + center_offset

func _set_selected_index(index: int) -> void:
	selected_index = clampi(index, 0, CHARACTER_IDS.size() - 1)
	_update_selection()

func _update_selection() -> void:
	selection_state.select_character(CHARACTER_IDS[selected_index])
	_update_card_style(kai_button, selected_index == 0, KAI_PURPLE)
	_update_card_style(razen_button, selected_index == 1, RAZEN_RED)

func _update_card_style(button: Button, is_selected: bool, accent: Color) -> void:
	if button == null:
		return
	var border: Color = accent if is_selected else Color(0.42, 0.39, 0.46, 0.9)
	var thickness: int = 4 if is_selected else 1
	button.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.028, 0.048, 0.06), border, thickness))
	button.add_theme_stylebox_override("hover", _button_style(Color(accent.r, accent.g, accent.b, 0.08), accent, 4))
	button.add_theme_stylebox_override("pressed", _button_style(Color(accent.r, accent.g, accent.b, 0.12), accent, 4))

func _button_style(fill_color: Color, border_color: Color, border_size: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_size)
	style.set_corner_radius_all(16)
	return style

func _start_game() -> void:
	selection_state.select_character(CHARACTER_IDS[selected_index])
	get_tree().paused = false
	var error: Error = get_tree().change_scene_to_file("res://scenes/ui/world_map.tscn")
	if error != OK:
		push_error("Could not enter the world map hub: " + error_string(error))
