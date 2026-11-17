extends ColorRect

const ShadowButton = preload("res://scripts/ui/shadowcraft_button.gd")
const Stroke = preload("res://scripts/ui/grind_stroke.gd")
const INK: Shader = preload("res://assets/ui/grind/dialog_ink.gdshader")
const DISPLAY: Font = preload("res://assets/ui/grind/fonts/shippori_mincho_bold_latin.ttf")
const TEXT: Color = Color("#eee2ee")

var _placement: CenterContainer
var _panel: Control
var _art: ColorRect
var _ink: ShaderMaterial = ShaderMaterial.new()
var _content: VBoxContainer
var _crest: Control
var _title: Label
var _body: Label
var _close: ShadowButton
var _animation: Tween
var _previous_focus: Control
var _opened: bool
var _reveal: float


func _ready() -> void:
	_placement = CenterContainer.new()
	_placement.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_placement)
	_placement.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_panel = Control.new()
	_panel.custom_minimum_size = Vector2(472, 330)
	_placement.add_child(_panel)

	_art = ColorRect.new()
	_art.mouse_filter = MOUSE_FILTER_IGNORE
	_art.show_behind_parent = true
	_ink.shader = INK
	_art.material = _ink
	_panel.add_child(_art)
	_art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_panel.draw.connect(_draw_binding)

	var margin: MarginContainer = MarginContainer.new()
	_panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: StringName in [&"left", &"right", &"top", &"bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 11)
	margin.add_child(_content)

	_crest = Control.new()
	_crest.custom_minimum_size.y = 54
	_crest.draw.connect(_draw_mentor_crest)
	_content.add_child(_crest)
	_title = _label(30)
	_title.add_theme_font_override("font", DISPLAY)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_title)
	_body = _label(18)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = SIZE_EXPAND_FILL
	_content.add_child(_body)
	_close = ShadowButton.new()
	_close.configure("RETURN TO LOBBY", ShadowButton.Finish.STEEL, null, true)
	_close.size_flags_horizontal = SIZE_SHRINK_BEGIN
	_close.pressed.connect(dismiss)
	# Keep directional and sequential navigation inside the dialogue.
	for property: StringName in [&"focus_next", &"focus_previous", &"focus_neighbor_left",
			&"focus_neighbor_right", &"focus_neighbor_top", &"focus_neighbor_bottom"]:
		_close.set(property, NodePath("."))
	_content.add_child(_close)


func present(title: String, body: String, mentor: bool = false) -> void:
	if _opened:
		return
	_stop_animation()
	if not visible:
		_previous_focus = get_viewport().gui_get_focus_owner()
	_opened = true
	_placement.set_anchor_and_offset(SIDE_LEFT, 0.53 if mentor else 0.0, 0)
	_panel.custom_minimum_size = Vector2(440, 360) if mentor else Vector2(472, 308)
	_crest.visible = mentor
	_title.text = title
	_body.text = body
	show()
	_close.grab_focus()
	_set_reveal(0.0)
	modulate.a = 0.0
	_content.modulate.a = 0.0
	_animation = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_animation.tween_property(self, "modulate:a", 1.0, 0.24)
	_animation.tween_method(_set_reveal, 0.0, 1.0, 0.39)
	_animation.tween_property(_content, "modulate:a", 1.0, 0.23).set_delay(0.14)


func dismiss(immediate: bool = false) -> void:
	if not visible or (not _opened and not immediate):
		return
	_opened = false
	_stop_animation()
	if immediate:
		_finish_close()
		return
	_animation = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_animation.tween_property(_content, "modulate:a", 0.0, 0.12)
	_animation.tween_method(_set_reveal, _reveal, 0.0, 0.24)
	_animation.tween_property(self, "modulate:a", 0.0, 0.24)
	_animation.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null


func _stop_animation() -> void:
	if _animation != null and _animation.is_valid():
		_animation.kill()


func _set_reveal(value: float) -> void:
	_reveal = value
	_ink.set_shader_parameter("reveal", value)
	_panel.queue_redraw()


func _draw_binding() -> void:
	var edge: Color = Color("#a385b1")
	edge.a *= smoothstep(0.38, 0.92, _reveal)
	var extent: Vector2 = _art.size
	_panel.draw_polyline([
		Vector2(1, 29), Vector2(1, 14), Vector2(15, 1), Vector2(extent.x - 1, 1),
		Vector2(extent.x - 1, extent.y - 14), Vector2(extent.x - 15, extent.y - 1),
		Vector2(1, extent.y - 1),
	], edge, 1.2, true)
	_panel.draw_line(Vector2(extent.x - 7, 14), Vector2(extent.x - 7, extent.y - 23), edge.darkened(0.38), 1.2, true)


func _draw_mentor_crest() -> void:
	var tone: Color = Color("#c4a7d5")
	Stroke.crest(_crest, Vector2(27, 25), 22, tone)
	_crest.draw_line(Vector2(63, 25), Vector2(210, 25), Color("#584365"), 1.0, true)


func _label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ShadowButton.FACE)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT)
	return label
