extends Button

enum Finish { STEEL, VIOLET, SEALED, MENTOR }

const Stroke = preload("res://scripts/ui/grind_stroke.gd")
const FACE: Font = preload("res://assets/ui/grind/fonts/barlow_medium.ttf")
const COLORS: Array[Color] = [Color("#a6a6bf"), Color("#d0a6dc"), Color("#c69a79"), Color("#c7acd9")]
const FILLS: Array[Color] = [Color("#171621"), Color("#2b1c36"), Color("#211614"), Color("#21162b")]

var _caption: String
var _finish: Finish
var _source: BaseButton
var _reverse: bool
var _active: float
var _inset: float
var _sweep: float
var _impact: float
var _hover_tween: Tween
var _press_tween: Tween


func configure(caption: String, finish: Finish, source: BaseButton = null, reverse: bool = false) -> void:
	_caption = caption
	_finish = finish
	_source = source if source != null else self
	_reverse = reverse
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"focus", &"hover", &"pressed", &"disabled"]:
		add_theme_stylebox_override(state, empty)
	if _source == self:
		accessibility_name = caption
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
	else:
		mouse_filter = MOUSE_FILTER_IGNORE
		focus_mode = FOCUS_NONE
	var text_width: float = FACE.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	custom_minimum_size = Vector2(ceilf(text_width) + 55.0, 34.0)


func _ready() -> void:
	_source.mouse_entered.connect(_update_highlight)
	_source.mouse_exited.connect(_update_highlight)
	_source.focus_entered.connect(_update_highlight)
	_source.focus_exited.connect(_update_highlight)
	_source.button_down.connect(_set_pressed.bind(true))
	_source.button_up.connect(_set_pressed.bind(false))


func _update_highlight() -> void:
	var target: float = 1.0 if _source.is_hovered() or _source.has_focus() else 0.0
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_method(_set_highlight, _active, target, 0.19)
	_hover_tween.tween_method(_set_sweep, 0.0 if target > 0.0 else 1.0, 1.0, 0.43)


func _set_pressed(down: bool) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_press_tween.tween_method(_set_inset, _inset, 1.0 if down else 0.0, 0.07 if down else 0.16)
	_press_tween.tween_method(_set_impact, 1.0 if down else _impact, 0.0, 0.23)


func _set_highlight(value: float) -> void:
	_active = value
	queue_redraw()


func _set_sweep(value: float) -> void:
	_sweep = value
	queue_redraw()


func _set_inset(value: float) -> void:
	_inset = value
	queue_redraw()


func _set_impact(value: float) -> void:
	_impact = value
	queue_redraw()


func _draw() -> void:
	if size.x < 35 or size.y < 20:
		return
	var width: float = size.x
	var height: float = size.y
	var selected: bool = _source.has_focus() or (_source.toggle_mode and _source.button_pressed)
	var rim: Color = COLORS[_finish]
	var fill: Color = FILLS[_finish]
	var ink: Color = Color("#eee3ee")
	var glint: Color = Color("#f5e9ff") if _finish != Finish.SEALED else Color("#e4b696")
	if _source.disabled:
		rim = Color("#534b54")
		fill = Color("#141218")
		ink = Color("#847680")
	var shape: PackedVector2Array = [
		Vector2(0, 12), Vector2(12, 0), Vector2(width - 7, 0), Vector2(width, 7),
		Vector2(width, height - 11), Vector2(width - 11, height),
		Vector2(7, height), Vector2(0, height - 7),
	]
	var edge: PackedVector2Array = Stroke.closed(shape)
	var response: float = 0.0 if _source.disabled else _active
	draw_colored_polygon(shape, fill.lightened(response * 0.06).darkened(_inset * 0.25))
	draw_polyline(edge, rim.lerp(glint, response * 0.37), 1.4 if selected else 1.0, true)
	draw_line(Vector2(4, 14), Vector2(14, 4), rim, 1.3, true)
	draw_line(Vector2(width - 4, height - 13), Vector2(width - 13, height - 4), rim, 1.3, true)
	if not _source.disabled:
		Stroke.trace(self, edge, _sweep, glint)
	if _caption.is_empty():
		return
	var glyph_x: float = 20.0 if _reverse or _finish == Finish.MENTOR else width - 21.0
	var center: Vector2 = Vector2(glyph_x + response * 2.5 * (-1.0 if _reverse else 1.0), height * 0.5 + _inset * 1.8)
	var text_x: float = 36.0 if _reverse or _finish == Finish.MENTOR else 14.0
	var baseline: float = (height - FACE.get_height(14)) * 0.5 + FACE.get_ascent(14) + _inset * 1.8
	draw_string(FACE, Vector2(text_x + _inset * 0.8, baseline), _caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink.lerp(glint, response * 0.45))
	_draw_mark(center, rim.lerp(glint, response * 0.65))
	if _impact > 0.0:
		var flash: Color = rim
		flash.a = _impact * 0.48
		var slide: float = (1.0 - _impact) * 12.0
		draw_line(center + Vector2(-5, 6 + slide), center + Vector2(5, 2 + slide), flash, 1.1, true)
		draw_line(center + Vector2(3, -7 - slide), center + Vector2(10, -9 - slide), flash, 1.0, true)


func _draw_mark(center: Vector2, ink: Color) -> void:
	match _finish:
		Finish.MENTOR:
			Stroke.crest(self, center, 8.0, ink)
		Finish.SEALED:
			draw_polyline(Stroke.closed([
				center + Vector2(0, -7), center + Vector2(7, 0),
				center + Vector2(0, 7), center + Vector2(-7, 0),
			]), ink, 1.2, true)
			draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), ink, 1.3, true)
		_:
			var side: float = -1.0 if _reverse else 1.0
			draw_polyline([center + Vector2(-6 * side, -3), center + Vector2(8 * side, 0),
				center + Vector2(-5 * side, 4), center + Vector2(-2 * side, 0)], ink, 1.3, true)
