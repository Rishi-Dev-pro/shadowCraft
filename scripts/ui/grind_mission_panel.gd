extends Button

enum Destination { GAUNTLET, DOJO, FORGE }

const Stroke = preload("res://scripts/ui/grind_stroke.gd")
const PAINT_SHADER: Shader = preload("res://assets/ui/grind/mission_paint.gdshader")

const GAUNTLET: PackedVector2Array = [
	Vector2(0, 0.11), Vector2(0.059, 0), Vector2(0.883, 0), Vector2(1, 0.19),
	Vector2(0.957, 0.795), Vector2(0.879, 1), Vector2(0.042, 1), Vector2(0, 0.924),
]
const DOJO: PackedVector2Array = [
	Vector2(0, 0.135), Vector2(0.026, 0.101), Vector2(0.214, 0.076), Vector2(0.50, 0),
	Vector2(0.786, 0.076), Vector2(0.974, 0.101), Vector2(1, 0.135), Vector2(0.928, 0.161),
	Vector2(0.928, 0.925), Vector2(0.968, 0.952), Vector2(0.968, 1), Vector2(0.032, 1),
	Vector2(0.032, 0.952), Vector2(0.072, 0.925), Vector2(0.072, 0.161),
]
const FORGE: PackedVector2Array = [
	Vector2(0, 0.205), Vector2(0.04, 0), Vector2(0.273, 0), Vector2(0.29, 0.082),
	Vector2(0.925, 0.082), Vector2(0.949, 0.21), Vector2(1, 0.21), Vector2(1, 0.82),
	Vector2(0.959, 1), Vector2(0.038, 1), Vector2(0, 0.81),
]

var _kind: Destination
var _art: Texture2D
var _rim: Color
var _outline: PackedVector2Array
var _painting: Node2D
var _material: ShaderMaterial = ShaderMaterial.new()
var _atmosphere: float
var _sweep: float
var _depressed: bool
var _points: PackedVector2Array
var _interaction: float = 0.0
var _tween: Tween

var entrance: float = 1.0:
	set(value):
		entrance = value
		_material.set_shader_parameter("reveal", value)
		queue_redraw()


func configure(kind: Destination, art: Texture2D, rim: Color, caption: String) -> void:
	_kind = kind
	_art = art
	_rim = rim
	accessibility_name = caption
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	flat = true
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"focus", &"hover", &"pressed"]:
		add_theme_stylebox_override(state, empty)
	match _kind:
		Destination.GAUNTLET:
			_outline = GAUNTLET
		Destination.DOJO:
			_outline = DOJO
		Destination.FORGE:
			_outline = FORGE
	_material.shader = PAINT_SHADER
	_material.set_shader_parameter("destination", int(_kind))


func _ready() -> void:
	_painting = Node2D.new()
	_painting.show_behind_parent = true
	_painting.material = _material
	_painting.draw.connect(_draw_painting)
	add_child(_painting)
	resized.connect(_update_polygon)
	mouse_entered.connect(_update_interaction)
	mouse_exited.connect(_update_interaction)
	focus_entered.connect(_update_interaction)
	focus_exited.connect(_update_interaction)
	button_down.connect(_respond_to_press.bind(true))
	button_up.connect(_respond_to_press.bind(false))
	_update_polygon()


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _points)


func _update_polygon() -> void:
	_points = _scale_points(_outline)
	_material.set_shader_parameter("panel_size", size)
	_painting.queue_redraw()
	queue_redraw()


func set_atmosphere_time(seconds: float) -> void:
	_atmosphere = seconds
	_material.set_shader_parameter("atmosphere", seconds)
	if _kind == Destination.FORGE:
		queue_redraw()


func _respond_to_press(down: bool) -> void:
	_depressed = down
	_update_interaction()


func _update_interaction() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target: float = -0.44 if _depressed else (1.0 if is_hovered() or has_focus() else 0.0)
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_interaction, _interaction, target, 0.09 if _depressed else 0.22)
	var start: float = 0.0 if target > 0.0 and _interaction < 0.2 else _sweep
	_tween.tween_method(_set_sweep, start, 1.0, 0.47)


func _set_interaction(value: float) -> void:
	_interaction = value
	_material.set_shader_parameter("response", value)
	queue_redraw()


func _set_sweep(value: float) -> void:
	_sweep = value
	queue_redraw()


func _draw_painting() -> void:
	if _points.size() < 3 or size.x <= 0 or size.y <= 0:
		return
	var aspect: float = size.aspect() / _art.get_size().aspect()
	var uv_window: Vector2 = Vector2(minf(aspect, 1.0), minf(1.0 / aspect, 1.0))
	var art_uv: PackedVector2Array = []
	for point: Vector2 in _outline:
		art_uv.append((point - Vector2(0.5, 0.5)) * uv_window + Vector2(0.5, 0.5))
	_painting.draw_colored_polygon(_points, Color.WHITE, art_uv, _art)


func _draw() -> void:
	if _points.size() < 3 or size.x <= 0 or size.y <= 0:
		return
	var metal: Color = _rim.lerp(Color("#e8d7f1"), clampf(_interaction * 0.43, 0.0, 1.0))
	var settlement: float = sin(PI * entrance) * smoothstep(0.21, 0.6, entrance)
	metal = metal.lerp(Color("#d1b4cd"), settlement * 0.47)
	metal.a = lerpf(0.12, 1.0, entrance)
	var edge: PackedVector2Array = Stroke.closed(_points)
	draw_polyline(edge, Color("#08060c"), 5, true)
	draw_polyline(edge, metal, 1.6 if not has_focus() else 2.3, true)
	var detail: Color = Color(metal, metal.a * smoothstep(0.18, 0.8, entrance))
	match _kind:
		Destination.GAUNTLET:
			_draw_gauntlet(detail)
		Destination.DOJO:
			_draw_dojo(detail)
		Destination.FORGE:
			_draw_forge(detail)
			_draw_embers()
	var glint: Color = Color("#e9d4f4") if _kind != Destination.FORGE else Color("#e4b696")
	Stroke.trace(self, edge, _sweep, glint)


func _draw_gauntlet(metal: Color) -> void:
	# The two rails follow the profile of the angled steel plate.
	_stroke([Vector2(0.012, 0.184), Vector2(0.012, 0.123), Vector2(0.064, 0.028), Vector2(0.40, 0.028)], metal, 2)
	_stroke([Vector2(0.815, 0.037), Vector2(0.873, 0.037), Vector2(0.980, 0.21), Vector2(0.939, 0.786), Vector2(0.866, 0.965), Vector2(0.69, 0.965)], metal.darkened(0.25), 2)
	_stroke([Vector2(0.918, 0.746), Vector2(0.91, 0.818), Vector2(0.857, 0.939), Vector2(0.78, 0.939)], Color(Color("#9d4d70"), metal.a), 3)
	_stroke([Vector2(0.044, 0.933), Vector2(0.063, 0.966), Vector2(0.24, 0.966)], metal.darkened(0.36), 2)
	Stroke.crest(self, Vector2(0.080, 0.14) * size, 18, Color(metal, metal.a * 0.60))


func _draw_dojo(metal: Color) -> void:
	# Broad eaves sit above twin posts and a shallow stone sill.
	_stroke([Vector2(0.047, 0.131), Vector2(0.217, 0.099), Vector2(0.50, 0.024), Vector2(0.783, 0.099), Vector2(0.953, 0.131)], metal, 2)
	_stroke([Vector2(0.084, 0.159), Vector2(0.916, 0.159)], Color(Color("#171621"), metal.a), 8)
	_stroke([Vector2(0.098, 0.167), Vector2(0.902, 0.167)], metal.darkened(0.27), 2)
	for position: float in [0.093, 0.907]:
		_stroke([Vector2(position, 0.168), Vector2(position, 0.944)], Color(Color("#1c1929"), metal.a), 5)
		_stroke([Vector2(position, 0.234), Vector2(position, 0.909)], metal.darkened(0.25), 1)
	_stroke([Vector2(0.054, 0.958), Vector2(0.946, 0.958)], metal, 2)


func _draw_forge(metal: Color) -> void:
	# Short stepped flanges and rivets give the sill the weight of a casting.
	_stroke([Vector2(0.013, 0.25), Vector2(0.047, 0.053), Vector2(0.264, 0.053), Vector2(0.281, 0.138)], metal, 2)
	_stroke([Vector2(0.737, 0.133), Vector2(0.915, 0.133), Vector2(0.941, 0.268), Vector2(0.986, 0.268)], metal, 2)
	_stroke([Vector2(0.048, 0.947), Vector2(0.949, 0.947), Vector2(0.985, 0.775)], metal.darkened(0.27), 3)
	for rivet: Vector2 in [Vector2(0.025, 0.30), Vector2(0.025, 0.77), Vector2(0.974, 0.36), Vector2(0.974, 0.72)]:
		draw_circle(rivet * size, 3.5, Color(Color("#141017"), metal.a), true)
		draw_circle(rivet * size, 1.8, metal, true)


func _draw_embers() -> void:
	for index: int in range(5):
		var phase: float = fposmod(_atmosphere * (0.44 + index * 0.054) + index * 0.271, 1.0)
		var point: Vector2 = Vector2(0.675 + index * 0.025 + sin(phase * 2.9 + index) * 0.020, 0.62 - phase * 0.43)
		var warmth: float = sin(phase * PI) * entrance
		var coal: Color = Color(1.0, 0.57, 0.32, warmth * 0.68)
		draw_line(point * size, point * size + Vector2(1.5, 3.7), coal, 1.3, true)


func _stroke(points: PackedVector2Array, tone: Color, width: float) -> void:
	draw_polyline(_scale_points(points), tone, width, true)


func _scale_points(points: PackedVector2Array) -> PackedVector2Array:
	var scaled: PackedVector2Array = []
	for point: Vector2 in points:
		scaled.append(point * size)
	return scaled
