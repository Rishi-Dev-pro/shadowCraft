extends Node2D

const Rig = preload("res://experimental/raezen_hybrid/raezen_rig.gd")
const Player = preload("res://experimental/raezen_hybrid/motion_player.gd")
const SOURCE: String = "res://assets/characters/raezan_boss/raezan_sprite_frames.tres"
const HERO_SCALE: float = 0.72
const GROUND: float = 491.0
const PADDING: float = 88.0

var original_stage: SubViewport
var hybrid_stage: SubViewport
var source: SpriteFrames
var player: Player
var selected: OptionButton
var status: Label
var scrub: HSlider
var source_toggle: CheckButton
var blend_gauge: ProgressBar
var _original_display: Sprite2D
var _hybrid_display: Sprite2D


func _ready() -> void:
	source = load(SOURCE)
	original_stage = _stage()
	hybrid_stage = _stage()
	var original: Sprite2D = Sprite2D.new()
	original.centered = false
	original.texture = source.get_frame_texture(&"idle", 0)
	original_stage.add_child(original)
	var rig: Rig = Rig.new()
	hybrid_stage.add_child(rig)
	var paint: Sprite2D = Sprite2D.new()
	paint.centered = false
	hybrid_stage.add_child(paint)
	player = Player.new()
	add_child(player)
	player.configure(rig, paint, source)
	_original_display = _display(original_stage)
	_hybrid_display = _display(hybrid_stage)
	_controls()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_update_status()


func _stage() -> SubViewport:
	var view: SubViewport = SubViewport.new()
	view.size = Vector2i(512, 512 + int(PADDING))
	view.world_2d = World2D.new()
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(view)
	view.canvas_transform = Transform2D(0.0, Vector2(0.0, PADDING))
	return view


func _display(view: SubViewport) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = view.get_texture()
	sprite.scale = Vector2.ONE * HERO_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var composite: CanvasItemMaterial = CanvasItemMaterial.new()
	composite.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	sprite.material = composite
	add_child(sprite)
	return sprite


func _controls() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(20, 14)
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var title: Label = Label.new()
	title.text = "RAEZEN  /  MOTION REVIEW"
	title.add_theme_font_size_override("font_size", 25)
	column.add_child(title)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	selected = OptionButton.new()
	for profile: Dictionary in player.profiles:
		selected.add_item(profile["title"])
	selected.item_selected.connect(_select)
	row.add_child(selected)
	_add_button(row, "Play", _play)
	_add_button(row, "Transition", _play_transition)
	_add_button(row, "Pause / Resume", _pause)
	_add_button(row, "Reset", _reset)
	var rate: SpinBox = SpinBox.new()
	rate.min_value = 0.25
	rate.max_value = 2.0
	rate.step = 0.25
	rate.value = 1.0
	rate.suffix = "×"
	rate.value_changed.connect(_speed)
	row.add_child(rate)
	var options: HBoxContainer = HBoxContainer.new()
	options.add_theme_constant_override("separation", 10)
	column.add_child(options)
	source_toggle = CheckButton.new()
	source_toggle.text = "Source steps"
	source_toggle.toggled.connect(_toggle_source)
	options.add_child(source_toggle)
	_add_button(options, "‹ Frame", _step.bind(-1))
	_add_button(options, "Frame ›", _step.bind(1))
	var fps: OptionButton = OptionButton.new()
	for cap: int in [0, 30, 60, 120]:
		fps.add_item("Uncapped" if cap == 0 else "%d FPS cap" % cap, cap)
	fps.item_selected.connect(func(index: int) -> void: Engine.max_fps = fps.get_item_id(index))
	options.add_child(fps)
	blend_gauge = ProgressBar.new()
	blend_gauge.custom_minimum_size.x = 92.0
	blend_gauge.max_value = 1.0
	blend_gauge.tooltip_text = "Transition progress"
	options.add_child(blend_gauge)
	scrub = HSlider.new()
	scrub.step = 0.005
	scrub.max_value = 1.0
	scrub.custom_minimum_size.x = 200.0
	scrub.value_changed.connect(_seek)
	options.add_child(scrub)
	status = Label.new()
	column.add_child(status)


func _add_button(row: HBoxContainer, label: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = label
	button.pressed.connect(action)
	row.add_child(button)


func _select(index: int) -> void:
	if player.source_mode:
		player.inspect_pose(index, float(player.profiles[index]["sample"]))
	_update_status()


func _play() -> void:
	player.play_profile(selected.selected, true)
	_update_status()


func _play_transition() -> void:
	if player.source_mode:
		status.text = "Switch to smooth playback to transition between motions."
		return
	if not player.play_profile(selected.selected):
		status.text = "Transition unavailable from %s. Finish the current action or use Play to preview separately." % player.active["title"]
		return
	_update_status()


func _toggle_source(enabled: bool) -> void:
	player.source_mode = enabled
	player.inspect_pose(selected.selected, float(scrub.value))
	_update_status()


func _step(direction: int) -> void:
	player.source_mode = true
	source_toggle.set_pressed_no_signal(true)
	player.step_source(selected.selected, direction)
	_update_status()


func _pause() -> void:
	player.playing = not player.playing and player.progress() < 1.0


func _seek(value: float) -> void:
	player.inspect_pose(selected.selected, value)
	_update_status()


func _reset() -> void:
	selected.select(0)
	player.inspect_pose(0, 0.0)
	_update_status()


func _speed(value: float) -> void:
	player.speed = value


func _process(delta: float) -> void:
	if player.playing:
		player.advance(delta)
		_update_status()


func _update_status() -> void:
	var width: int = 512
	if player.correction.visible:
		width = maxi(width, player.correction.texture.get_width())
	if hybrid_stage.size.x != width:
		# Padded painted frames keep their source pixels beyond the old crop.
		hybrid_stage.size = Vector2i(width, hybrid_stage.size.y)
	_hybrid_display.offset.x = player.world_x + player.paint_shift_x - player.paint_origin_x
	scrub.set_value_no_signal(player.progress())
	blend_gauge.value = player.transition_fraction()
	var frame: String = " · source %02d" % (player.source_frame + 1) if player.source_frame >= 0 else ""
	status.text = "%s · %s · %.2f / %.2f s%s%s" % [
		player.active["title"], "Layered rig" if player.rig.visible else "Painted correction",
		player.clock, float(player.active["seconds"]), frame,
		" · " + player.last_event if not player.last_event.is_empty() else "",
	]
	if player.queued_profile >= 0:
		status.text += " · queued " + String(player.profiles[player.queued_profile]["title"])


func _layout() -> void:
	var size: Vector2 = get_viewport_rect().size
	var floor_y: float = size.y - 68.0
	_original_display.position = Vector2(size.x * 0.26 - 256 * HERO_SCALE, floor_y - (GROUND + PADDING) * HERO_SCALE)
	_hybrid_display.position = Vector2(size.x * 0.74 - 256 * HERO_SCALE, _original_display.position.y)
	queue_redraw()


func _draw() -> void:
	var size: Vector2 = get_viewport_rect().size
	var floor_y: float = size.y - 68.0
	draw_rect(Rect2(Vector2.ZERO, size), Color("#22212a"))
	draw_line(Vector2(36.0, floor_y + 6.0), Vector2(size.x - 36.0, floor_y + 6.0), Color("#6d586f"))
	draw_line(Vector2(size.x * 0.5, 174), Vector2(size.x * 0.5, floor_y + 6), Color("#443848"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.26 - 99, 192), "CAMPAIGN NEUTRAL")
	draw_string(font, Vector2(size.x * 0.74 - 98, 192), "HYBRID MOTION TEST")
