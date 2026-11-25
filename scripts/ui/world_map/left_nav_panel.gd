class_name LeftNavPanel
extends Control

## Compact World Map command menu. Destinations are owned by WorldMapController.

signal training_dojo_selected()
signal world_map_selected()
signal weapon_forge_selected()
signal grind_selected()

const ICON_ROOT: String = "res://assets/ui/world_map/icons/"
const HEADER_HEIGHT: float = 40.0
const DROPDOWN_GAP: float = 2.0
const ACTIVE_INDEX: int = 1
const GRIND_INDEX: int = 3
const COLOR_VIOLET: Color = Color(0.57, 0.39, 0.72, 1.0)
const COLOR_HIGHLIGHT: Color = Color(0.82, 0.68, 0.91, 1.0)
const COLOR_TEXT: Color = Color(0.91, 0.87, 0.93, 1.0)
const COLOR_MUTED: Color = Color(0.62, 0.57, 0.66, 1.0)

var _header: PanelContainer
var _header_style: StyleBoxFlat
var _menu_button: Button
var _dropdown: PanelContainer
var _dropdown_style: StyleBoxFlat
var _cards: Array[PanelContainer] = []
var _card_styles: Array[StyleBoxFlat] = []
var _active_index: int = ACTIVE_INDEX
var _menu_open: bool = false
var _panel_width: float = 252.0
var _available_height: float = 420.0
var _menu_tween: Tween
var _hover_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	_set_active(ACTIVE_INDEX)
	_layout_menu()
	set_menu_open(false, false)


func set_responsive_size(width: float, available_height: float) -> void:
	_panel_width = maxf(width, 150.0)
	_available_height = maxf(available_height, HEADER_HEIGHT + 190.0)
	if _header == null:
		return
	_layout_menu()


func is_menu_open() -> bool:
	return _menu_open


func contains_screen_point(screen_point: Vector2) -> bool:
	var local_point: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
	return Rect2(Vector2.ZERO, size).has_point(local_point)


func close_menu() -> void:
	set_menu_open(false, true)


func set_grind_active(active: bool) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_set_active(GRIND_INDEX if active else ACTIVE_INDEX)


func set_menu_open(open: bool, animate: bool = true) -> void:
	if _menu_open == open and _dropdown != null:
		return
	_menu_open = open
	if _menu_tween != null and _menu_tween.is_valid():
		_menu_tween.kill()
	if not animate:
		_dropdown.visible = open
		_dropdown.modulate.a = 1.0 if open else 0.0
		_dropdown.position.y = HEADER_HEIGHT + DROPDOWN_GAP
		size.y = _expanded_height() if open else HEADER_HEIGHT
		return
	if open:
		_dropdown.visible = true
		_dropdown.modulate.a = 0.0
		_dropdown.position.y = HEADER_HEIGHT + DROPDOWN_GAP - 8.0
		size.y = _expanded_height()
		_menu_tween = create_tween().set_parallel(true)
		_menu_tween.tween_property(_dropdown, "modulate:a", 1.0, 0.2)
		_menu_tween.tween_property(_dropdown, "position:y", HEADER_HEIGHT + DROPDOWN_GAP, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_menu_tween = create_tween().set_parallel(true)
		_menu_tween.tween_property(_dropdown, "modulate:a", 0.0, 0.14)
		_menu_tween.tween_property(_dropdown, "position:y", HEADER_HEIGHT + DROPDOWN_GAP - 5.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_menu_tween.set_parallel(false)
		_menu_tween.tween_callback(_finish_close)


func _build_ui() -> void:
	_header = PanelContainer.new()
	_header.position = Vector2.ZERO
	_header.size = Vector2(_panel_width, HEADER_HEIGHT)
	_header_style = StyleBoxFlat.new()
	_header_style.bg_color = Color(0.035, 0.027, 0.041, 0.94)
	_header_style.border_color = Color(0.42, 0.32, 0.5, 0.9)
	_header_style.set_border_width_all(1)
	_header_style.set_corner_radius_all(3)
	_header_style.shadow_color = Color(0.24, 0.12, 0.34, 0.14)
	_header_style.shadow_size = 4
	_header_style.content_margin_left = 9.0
	_header_style.content_margin_right = 6.0
	_header_style.content_margin_top = 3.0
	_header_style.content_margin_bottom = 3.0
	_header.add_theme_stylebox_override("panel", _header_style)
	add_child(_header)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 7)
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_header.add_child(header_row)
	var logo_mark: PanelContainer = PanelContainer.new()
	logo_mark.custom_minimum_size = Vector2(25.0, 25.0)
	var logo_style: StyleBoxFlat = StyleBoxFlat.new()
	logo_style.bg_color = Color(0.07, 0.045, 0.09, 0.92)
	logo_style.border_color = Color(0.58, 0.42, 0.66, 0.84)
	logo_style.set_border_width_all(1)
	logo_style.set_corner_radius_all(2)
	logo_mark.add_theme_stylebox_override("panel", logo_style)
	header_row.add_child(logo_mark)
	var logo_label: Label = Label.new()
	logo_label.text = "SC"
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo_label.add_theme_font_size_override("font_size", 12)
	logo_label.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	logo_mark.add_child(logo_label)
	var title: Label = Label.new()
	title.text = "SHADOWCRAFT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.add_theme_constant_override("outline_size", 1)
	header_row.add_child(title)

	_menu_button = Button.new()
	_menu_button.text = "≡"
	_menu_button.custom_minimum_size = Vector2(28.0, 30.0)
	_menu_button.add_theme_font_size_override("font_size", 21)
	_menu_button.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	_menu_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var menu_normal: StyleBoxFlat = _button_style(Color(0.035, 0.027, 0.041, 0.3), Color(0.42, 0.32, 0.5, 0.35))
	var menu_hover: StyleBoxFlat = _button_style(Color(0.12, 0.075, 0.15, 0.78), COLOR_VIOLET)
	_menu_button.add_theme_stylebox_override("normal", menu_normal)
	_menu_button.add_theme_stylebox_override("hover", menu_hover)
	_menu_button.add_theme_stylebox_override("pressed", menu_hover)
	header_row.add_child(_menu_button)
	_menu_button.pressed.connect(func() -> void: set_menu_open(not _menu_open))

	_dropdown = PanelContainer.new()
	_dropdown.visible = false
	_dropdown.position = Vector2(0.0, HEADER_HEIGHT + DROPDOWN_GAP)
	_dropdown_style = StyleBoxFlat.new()
	_dropdown_style.bg_color = Color(0.035, 0.027, 0.041, 0.97)
	_dropdown_style.border_color = Color(0.39, 0.3, 0.47, 0.88)
	_dropdown_style.set_border_width_all(1)
	_dropdown_style.set_corner_radius_all(3)
	_dropdown_style.shadow_color = Color(0.2, 0.1, 0.29, 0.18)
	_dropdown_style.shadow_size = 5
	_dropdown_style.content_margin_left = 7.0
	_dropdown_style.content_margin_right = 7.0
	_dropdown_style.content_margin_top = 5.0
	_dropdown_style.content_margin_bottom = 5.0
	_dropdown.add_theme_stylebox_override("panel", _dropdown_style)
	add_child(_dropdown)

	var menu_column: VBoxContainer = VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 0)
	_dropdown.add_child(menu_column)
	var menu_items: Array[Dictionary] = [
		{"title": "TRAINING", "subtitle": "Practice combat skills", "icon": ICON_ROOT + "nav_training_dojo.png"},
		{"title": "WORLD MAP", "subtitle": "Explore Kai's journey", "icon": ICON_ROOT + "nav_world_map.svg"},
		{"title": "WEAPON FORGE", "subtitle": "Craft and upgrade weapons", "icon": ICON_ROOT + "nav_weapon_forge.png"},
		{"title": "GRIND", "subtitle": "Replay battles and earn rewards", "icon": ICON_ROOT + "marker_swords_purple.svg"}
	]
	for index: int in range(menu_items.size()):
		var card: PanelContainer = _make_command_card(menu_items[index], index)
		_cards.append(card)
		menu_column.add_child(card)
		if index < menu_items.size() - 1:
			var divider: ColorRect = ColorRect.new()
			divider.color = Color(0.49, 0.36, 0.55, 0.28)
			divider.custom_minimum_size = Vector2(0.0, 1.0)
			divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
			menu_column.add_child(divider)


func _make_command_card(data: Dictionary, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 39.0)
	card.offset_transform_enabled = true
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(1)
	style.content_margin_left = 6.0
	style.content_margin_right = 5.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	card.add_theme_stylebox_override("panel", style)
	_card_styles.append(style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(21.0, 21.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(data["icon"]) as Texture2D if ResourceLoader.exists(data["icon"]) else null
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 1)
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_column)
	var title: Label = Label.new()
	title.text = data["title"]
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	text_column.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = data["subtitle"]
	subtitle.clip_text = true
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.add_theme_color_override("font_color", COLOR_MUTED)
	text_column.add_child(subtitle)
	var active_mark: ColorRect = ColorRect.new()
	active_mark.custom_minimum_size = Vector2(2.0, 22.0)
	active_mark.color = COLOR_VIOLET if index == _active_index else Color(0.0, 0.0, 0.0, 0.0)
	active_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(active_mark)

	var button: Button = Button.new()
	button.flat = true
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		button.add_theme_stylebox_override(state, empty)
	card.add_child(button)
	button.pressed.connect(func() -> void: _on_command_pressed(index))
	button.mouse_entered.connect(func() -> void: _set_hovered(index, true))
	button.mouse_exited.connect(func() -> void: _set_hovered(index, false))
	return card


func _layout_menu() -> void:
	_panel_width = minf(_panel_width, 226.0)
	var compact: bool = _panel_width < 205.0 or _available_height < 330.0
	var item_height: float = 36.0 if compact else 39.0
	var dropdown_padding: float = 10.0
	var requested_menu_height: float = item_height * 4.0 + 3.0 + dropdown_padding
	var available_menu_height: float = maxf(182.0, _available_height - HEADER_HEIGHT - DROPDOWN_GAP - 8.0)
	var menu_height: float = minf(requested_menu_height, available_menu_height)
	_header.size = Vector2(_panel_width, HEADER_HEIGHT)
	_dropdown.position.x = 0.0
	_dropdown.size = Vector2(_panel_width, menu_height)
	_dropdown.custom_minimum_size = Vector2(_panel_width, menu_height)
	size.x = _panel_width
	size.y = _expanded_height() if _menu_open else HEADER_HEIGHT
	for card: PanelContainer in _cards:
		card.custom_minimum_size.y = item_height
		var row: HBoxContainer = card.get_child(0) as HBoxContainer
		row.add_theme_constant_override("separation", 6 if compact else 8)
		var icon: TextureRect = row.get_child(0) as TextureRect
		icon.custom_minimum_size = Vector2(18.0, 18.0) if compact else Vector2(20.0, 20.0)
		var text_column: VBoxContainer = row.get_child(1) as VBoxContainer
		var title: Label = text_column.get_child(0) as Label
		var subtitle: Label = text_column.get_child(1) as Label
		title.add_theme_font_size_override("font_size", 9 if compact else 10)
		subtitle.add_theme_font_size_override("font_size", 7)


func _expanded_height() -> float:
	return minf(_available_height, HEADER_HEIGHT + DROPDOWN_GAP + _dropdown.size.y)


func _finish_close() -> void:
	_dropdown.visible = false
	_dropdown.modulate.a = 1.0
	size.y = HEADER_HEIGHT


func _on_command_pressed(index: int) -> void:
	close_menu()
	match index:
		0:
			_set_active(0)
			training_dojo_selected.emit()
		1:
			_set_active(1)
			world_map_selected.emit()
		2:
			weapon_forge_selected.emit()
		GRIND_INDEX:
			grind_selected.emit()


func _set_active(index: int) -> void:
	_active_index = index
	for card_index: int in range(_cards.size()):
		var selected: bool = card_index == _active_index
		var style: StyleBoxFlat = _card_styles[card_index]
		style.bg_color = Color(0.16, 0.105, 0.19, 0.42) if selected else Color(0.0, 0.0, 0.0, 0.0)
		style.border_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_border_width_all(0)
		var row: HBoxContainer = _cards[card_index].get_child(0) as HBoxContainer
		var mark: ColorRect = row.get_child(2) as ColorRect
		mark.color = COLOR_VIOLET if selected else Color(0.0, 0.0, 0.0, 0.0)


func _set_hovered(index: int, hovered: bool) -> void:
	if index < 0 or index >= _cards.size():
		return
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	var card: PanelContainer = _cards[index]
	var style: StyleBoxFlat = _card_styles[index]
	var selected: bool = index == _active_index
	var target_bg: Color = Color(0.19, 0.13, 0.23, 0.5) if hovered else (Color(0.16, 0.105, 0.19, 0.42) if selected else Color(0.0, 0.0, 0.0, 0.0))
	var row: HBoxContainer = card.get_child(0) as HBoxContainer
	var mark: ColorRect = row.get_child(2) as ColorRect
	var title: Label = (row.get_child(1) as VBoxContainer).get_child(0) as Label
	var target_title: Color = COLOR_HIGHLIGHT if hovered else COLOR_TEXT
	var target_mark: Color = COLOR_HIGHLIGHT if hovered else (COLOR_VIOLET if selected else Color(0.0, 0.0, 0.0, 0.0))
	title.add_theme_color_override("font_color", target_title)
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(style, "bg_color", target_bg, 0.15)
	_hover_tween.tween_property(mark, "color", target_mark, 0.15)
	_hover_tween.tween_property(card, "offset_transform_position", Vector2(2.0, 0.0) if hovered else Vector2.ZERO, 0.15)


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
