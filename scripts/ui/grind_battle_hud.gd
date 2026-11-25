extends Control

signal retry_requested
signal lobby_requested

const ButtonStyle = preload("res://scripts/ui/shadowcraft_button.gd")
const Stroke = preload("res://scripts/ui/grind_stroke.gd")
const DISPLAY: Font = preload("res://assets/ui/grind/fonts/shippori_mincho_bold_latin.ttf")
const SILVER: Color = Color("#eee0f0")
const VIOLET: Color = Color("#c7a3ea")

var _kai: Vector2 = Vector2(100, 100)
var _enemy: Vector2 = Vector2(90, 90)
var _cue: String = ""
var _opacity: float
var _cue_tween: Tween
var _experimental: bool


func _ready() -> void:
	resized.connect(queue_redraw)
	var back: ButtonStyle = _button("BACK TO GRIND", false, func() -> void: lobby_requested.emit())
	back.focus_mode = FOCUS_NONE
	add_child(back)
	back.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	back.offset_left = -203
	back.offset_top = -53
	back.offset_right = -23
	back.offset_bottom = -19


func show_experimental_controls() -> void:
	_experimental = true
	queue_redraw()


func set_kai_health(value: float, maximum: float) -> void:
	_kai = Vector2(value, maximum)
	queue_redraw()


func set_enemy_health(value: float, maximum: float) -> void:
	_enemy = Vector2(value, maximum)
	queue_redraw()


func announce(caption: String, hold: float) -> void:
	if _cue_tween != null and _cue_tween.is_valid():
		_cue_tween.kill()
	_cue = caption
	_cue_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_cue_tween.tween_method(_set_cue_opacity, 0.0, 1.0, 0.17)
	_cue_tween.tween_interval(hold)
	_cue_tween.tween_method(_set_cue_opacity, 1.0, 0.0, 0.27)


func show_result(victory: bool) -> void:
	var result: ColorRect = ColorRect.new()
	result.color = Color(0.03, 0.017, 0.05, 0.82)
	add_child(result)
	result.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	result.add_child(center)
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var frame: PanelContainer = PanelContainer.new()
	frame.custom_minimum_size = Vector2(520, 0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#1a1223")
	style.border_color = Color("#896a9f")
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 27
	style.content_margin_bottom = 27
	frame.add_theme_stylebox_override("panel", style)
	center.add_child(frame)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	frame.add_child(column)
	column.add_child(_label("THE GAUNTLET   /   FIRST ENCOUNTER", 14, VIOLET))
	column.add_child(_label("Victory" if victory else "Defeat", 49, SILVER, true))
	column.add_child(_label(
		"Agile Ninja defeated  ·  1 / 1 prototype bouts complete" if victory else "Kai has fallen. The first encounter remains open.",
		18, SILVER))
	column.add_child(_label("Reward preview  ·  Materials pending trial completion.\nInventory change  ·  None", 16, VIOLET))
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	var retry: ButtonStyle = _button("REMATCH", true, func() -> void: retry_requested.emit())
	actions.add_child(retry)
	actions.add_child(_button("BACK TO GRIND", false, func() -> void: lobby_requested.emit()))
	retry.grab_focus()
	result.modulate.a = 0.0
	create_tween().tween_property(result, "modulate:a", 1.0, 0.24)


func _draw() -> void:
	var width: float = minf(454.0, (size.x - 260.0) * 0.5)
	if width < 20.0:
		return
	var right: float = size.x - width - 31.0
	_meter(Vector2(31, 56), width, _kai, Color("#9962d1"), false)
	_meter(Vector2(right, 56), width, _enemy, Color("#c2567d"), true)
	draw_string(DISPLAY, Vector2(33, 42), "KAI", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, SILVER)
	draw_string(DISPLAY, Vector2(right, 42), "AGILE NINJA", HORIZONTAL_ALIGNMENT_RIGHT, width, 29, SILVER)
	draw_string(ButtonStyle.FACE, Vector2(33, 101), ("SKELETAL PROTOTYPE" if _experimental else "SHADOW DISCIPLE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VIOLET)
	draw_string(ButtonStyle.FACE, Vector2(right, 101), "QUICK-BLADE DUELIST", HORIZONTAL_ALIGNMENT_RIGHT, width, 14, Color("#ed9fb9"))
	var middle: float = size.x * 0.5
	var badge: PackedVector2Array = [
		Vector2(middle - 92, 25), Vector2(middle + 92, 25), Vector2(middle + 86, 74),
		Vector2(middle + 72, 87), Vector2(middle - 72, 87), Vector2(middle - 86, 74),
	]
	draw_colored_polygon(badge, Color(0.08, 0.052, 0.115, 0.95))
	draw_polyline(Stroke.closed(badge), Color("#a380b9"), 1.3, true)
	Stroke.crest(self, Vector2(middle, 45), 9, VIOLET)
	draw_string(ButtonStyle.FACE, Vector2(middle - 84, 71), "G A U N T L E T   /   R O U N D   1", HORIZONTAL_ALIGNMENT_CENTER, 168, 11, SILVER)
	var hints: String = "A / D  MOVE     SHIFT  RUN     W  JUMP     SPACE  GUARD     Z  LIGHT     C  HEAVY"
	var hints_width: float = ButtonStyle.FACE.get_string_size(hints, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 42.0
	var strip: Rect2 = Rect2(Vector2(middle - hints_width * 0.5, size.y - 51), Vector2(hints_width, 34))
	draw_rect(strip, Color(0.07, 0.046, 0.097, 0.89))
	draw_line(strip.position, strip.position + Vector2(strip.size.x, 0), Color("#80679a"), 1, true)
	draw_string(ButtonStyle.FACE, strip.position + Vector2(0, 22), hints, HORIZONTAL_ALIGNMENT_CENTER, hints_width, 14, SILVER)
	if _experimental:
		var extra: Rect2 = Rect2(middle - 223.0, size.y - 81.0, 446.0, 29.0)
		draw_rect(extra, Color(0.07, 0.046, 0.097, 0.89))
		draw_string(ButtonStyle.FACE, extra.position + Vector2(0, 19),
			"S  CROUCH     X  FRONT KICK     Q  BACK DASH     E  FORWARD DASH",
			HORIZONTAL_ALIGNMENT_CENTER, extra.size.x, 13, SILVER)
	if _opacity > 0.0:
		var y: float = size.y * 0.34
		draw_rect(Rect2(0, y - 56, size.x, 84), Color(0.05, 0.033, 0.07, 0.66 * _opacity))
		draw_string(DISPLAY, Vector2(0, y), _cue, HORIZONTAL_ALIGNMENT_CENTER, size.x, 42, Color(SILVER, _opacity))


func _meter(origin: Vector2, width: float, health: Vector2, tint: Color, mirrored: bool) -> void:
	var base: PackedVector2Array = [Vector2.ZERO, Vector2(width, 0), Vector2(width - 13, 21), Vector2(0, 21)]
	var ratio: float = clampf(health.x / maxf(1.0, health.y), 0.0, 1.0)
	var fill: float = (width - 6.0) * ratio
	var tip: float = minf(9.0, fill * 0.5)
	var body: PackedVector2Array = [Vector2(3, 3), Vector2(3 + fill, 3), Vector2(3 + fill - tip, 18), Vector2(3, 18)]
	for i: int in range(base.size()):
		if mirrored:
			base[i].x = width - base[i].x
			body[i].x = width - body[i].x
		base[i] += origin
		body[i] += origin
	draw_colored_polygon(base, Color("#15101e"))
	if fill > 1.0:
		draw_colored_polygon(body, tint)
		draw_line(body[0], body[1], tint.lightened(0.55), 1, true)
	draw_polyline(Stroke.closed(base), Color("#c29acf"), 1.25, true)
	draw_string(ButtonStyle.FACE, origin + Vector2(4, 15), "%d / %d" % [ceili(health.x), int(health.y)], HORIZONTAL_ALIGNMENT_CENTER, width - 8.0, 14, SILVER)


func _button(caption: String, primary: bool, callback: Callable) -> ButtonStyle:
	var button: ButtonStyle = ButtonStyle.new()
	button.configure(caption, ButtonStyle.Finish.VIOLET if primary else ButtonStyle.Finish.STEEL, null, not primary)
	button.pressed.connect(callback)
	return button


func _label(value: String, font_size: int, color: Color, title: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_override("font", DISPLAY if title else ButtonStyle.FACE)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _set_cue_opacity(opacity: float) -> void:
	_opacity = opacity
	queue_redraw()
