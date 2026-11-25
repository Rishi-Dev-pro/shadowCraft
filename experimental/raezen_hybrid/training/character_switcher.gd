extends Node2D
## Training-only selection. The arena's fighter and dummy are never re-instanced.

const Raezen = preload("res://experimental/raezen_hybrid/training/raezen_training.gd")
const KAI_PORTRAIT = preload("res://assets/ui/portraits/kai_hud_portrait.png")
const RAEZEN_PORTRAIT = preload("res://assets/ui/world_map/portraits/raezen_battle_portrait.png")
const RAEZEN_HINT: String = "A/D Move  ·  Ctrl Run  ·  Hold S to Backstep  ·  Space Jump  ·  E Dash  ·  Shift Void Step  ·  F Guard  ·  Z/C/X Strike  ·  U/I Burst"
const PRACTICE_HINT: String = "1 Hit  ·  2 Heavy hit  ·  3 Front impact  ·  4 Rear impact  ·  5 Knockdown  ·  G Get up"

var use_raezen: bool = false
var is_open: bool = false
var raezen: Raezen
var _host: Node
var _ui: Control
var _popup: Control
var _buttons: Array[Button] = []
var _hint: Label
var _extra_hint: Label
var _kai_hint: String
var _portrait: TextureRect
var _kai_texture: Texture2D
var _nameplate: Label
var _kai_label: String
var _subtitle: Label
var _kai_subtitle: String


func setup(host: Node, ui: Control, hint: Label) -> void:
	_host = host
	_ui = ui
	_hint = hint
	_kai_hint = hint.text
	_portrait = ui.get_node_or_null("KaiPortrait") as TextureRect
	_nameplate = ui.get_node_or_null("KaiHealthLabel") as Label
	_subtitle = ui.get_node_or_null("PlayerSubLabel") as Label
	if _portrait != null:
		_kai_texture = _portrait.texture
	if _nameplate != null:
		_kai_label = _nameplate.text
	if _subtitle != null:
		_kai_subtitle = _subtitle.text
	var switch: Button = Button.new()
	switch.name = "SwitchCharacter"
	switch.text = "Switch Character"
	switch.focus_mode = Control.FOCUS_NONE
	ui.add_child(switch)
	switch.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	switch.offset_left = -78
	switch.offset_right = 78
	switch.offset_top = 81
	switch.offset_bottom = 114
	switch.pressed.connect(_open)
	_extra_hint = Label.new()
	_extra_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_extra_hint.text = PRACTICE_HINT
	_extra_hint.add_theme_color_override("font_color", Color("#e4d3f2"))
	_extra_hint.add_theme_color_override("font_outline_color", Color("#1a1027"))
	_extra_hint.add_theme_constant_override("outline_size", 5)
	ui.add_child(_extra_hint)
	_extra_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_extra_hint.offset_left = -430
	_extra_hint.offset_right = 430
	_extra_hint.offset_top = -73
	_extra_hint.offset_bottom = -47
	_extra_hint.hide()
	_build_selection()


func _build_selection() -> void:
	_popup = ColorRect.new()
	(_popup as ColorRect).color = Color(0.04, 0.02, 0.08, 0.72)
	_popup.name = "TrainingCharacterSelection"
	_popup.z_index = 100
	_ui.add_child(_popup)
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	_popup.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -204
	panel.offset_right = 204
	panel.offset_top = -148
	panel.offset_bottom = 148
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#1c1328")
	style.border_color = Color("#695479")
	style.set_border_width_all(1)
	style.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading: Label = Label.new()
	heading.text = "Training character"
	heading.add_theme_font_size_override("font_size", 24)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for i: int in 2:
		var slot: VBoxContainer = VBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slot)
		var picture: TextureRect = TextureRect.new()
		picture.texture = KAI_PORTRAIT if i == 0 else RAEZEN_PORTRAIT
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(160, 146)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(picture)
		var choice: Button = Button.new()
		choice.custom_minimum_size.y = 36.0
		choice.name = "SelectKai" if i == 0 else "SelectRaezen"
		choice.pressed.connect(select_character.bind(i == 1))
		slot.add_child(choice)
		_buttons.append(choice)
	var close: Button = Button.new()
	close.text = "Close"
	close.pressed.connect(_close)
	column.add_child(close)
	_popup.hide()


func _open() -> void:
	is_open = true
	if raezen != null:
		raezen.menu_open = true
	_buttons[0].text = "Kai  ·  Selected" if not use_raezen else "Kai"
	_buttons[1].text = "Raezen  ·  Selected" if use_raezen else "Raezen"
	_popup.show()
	_buttons[int(use_raezen)].grab_focus()


func _close() -> void:
	is_open = false
	if raezen != null:
		raezen.menu_open = false
	_popup.hide()


func select_character(selected_raezen: bool) -> void:
	_close()
	if use_raezen == selected_raezen:
		return
	_host.park_training_actor()
	if selected_raezen and raezen == null:
		raezen = Raezen.new()
		raezen.name = "RaezenTraining"
		add_child(raezen)
		raezen.setup(_host.fighter, _host.target, _host.training_floor_y(), _host.report_raezen)
	use_raezen = selected_raezen
	raezen.set_active(use_raezen)
	_host.show_kai_training(not use_raezen)
	_hint.text = RAEZEN_HINT if use_raezen else _kai_hint
	_extra_hint.visible = use_raezen
	if _portrait != null:
		_portrait.texture = RAEZEN_PORTRAIT if use_raezen else _kai_texture
	if _nameplate != null:
		_nameplate.text = "RAEZEN" if use_raezen else _kai_label
	if _subtitle != null:
		_subtitle.text = "HYBRID  ·  TRAINING" if use_raezen else _kai_subtitle
	_host.report_raezen("")
