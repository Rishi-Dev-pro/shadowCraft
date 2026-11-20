extends Control

const Preview = preload("res://experimental/kai_hybrid/hybrid_controller.gd")
const DashMotion = preload("res://experimental/kai_hybrid/dash_motion.gd")
const AttackMotion = preload("res://experimental/kai_hybrid/attack_motion.gd")
const ImpactMotion = preload("res://experimental/kai_hybrid/impact_motion.gd")
const HitStop = preload("res://experimental/kai_hybrid/hit_stop.gd")
const GAME_SCALE: float = 0.7
const JUMP_HEADROOM: int = 160

@onready var controller: Preview = %Controller
@onready var _pause: Button = %Pause
@onready var _selected: Label = %Selected
@onready var _original_view: Node2D = %OriginalView
@onready var _hybrid_view: Node2D = %HybridView
@onready var _hybrid_stage: SubViewport = _hybrid_view.get_node("Stage")
@onready var _hybrid_preview: Sprite2D = _hybrid_view.get_node("Preview")
@onready var _stage_size: Vector2i = _hybrid_stage.size
var _dash_view_x: float = 0.0
var _jump_padding: int = 0


func _ready() -> void:
	for index: int in Preview.NAMES.size():
		var button: Button = Button.new()
		button.text = "Idle" if index == Preview.Pose.NEUTRAL else Preview.NAMES[index]
		button.pressed.connect(_select.bind(index))
		%PoseButtons.add_child(button)
	_add_walk_button("Forward Walk", 1)
	_add_walk_button("Backward Walk", -1)
	_add_walk_button("Stop", 0)
	var jump: Button = Button.new()
	jump.text = "Jump"
	jump.pressed.connect(_jump)
	%PoseButtons.add_child(jump)
	for index: int in DashMotion.NAMES.size():
		var dash_button: Button = Button.new()
		dash_button.text = DashMotion.NAMES[index]
		dash_button.pressed.connect(_dash.bind(index))
		%PoseButtons.add_child(dash_button)
	%Play.pressed.connect(_play)
	%Restart.pressed.connect(_restart)
	_pause.pressed.connect(_toggle_pause)
	%Reset.pressed.connect(_reset)
	%Speed.value_changed.connect(_set_speed)
	for index: int in AttackMotion.NAMES.size():
		var button: Button = Button.new()
		button.text = AttackMotion.NAMES[index]
		button.pressed.connect(_attack.bind(index))
		%Play.get_parent().add_child(button)
	var side: OptionButton = %ImpactSide
	side.add_item("From Front", ImpactMotion.SourceSide.FRONT)
	side.add_item("From Back", ImpactMotion.SourceSide.BACK)
	side.select(0)
	for index: int in ImpactMotion.NAMES.size():
		var button: Button = Button.new()
		button.text = ImpactMotion.NAMES[index]
		button.pressed.connect(_impact.bind(index))
		%ImpactControls.add_child(button)
	controller.walk_preview_changed.connect(queue_redraw)
	controller.idle_started.connect(_show_idle_label)
	controller.jump_status_changed.connect(_show_jump_status)
	controller.jump_preview_changed.connect(_set_jump_headroom)
	controller.dash_status_changed.connect(_show_jump_status)
	controller.dash_travel_changed.connect(_follow_dash_travel)
	controller.attack_status_changed.connect(_show_jump_status)
	controller.impact_status_changed.connect(_show_jump_status)
	_add_hit_stop_controls()
	resized.connect(_layout_stage)
	_layout_stage()
	_reset()


func _add_hit_stop_controls() -> void:
	var row: HBoxContainer = %HitStopControls
	var toggle: CheckButton = CheckButton.new()
	toggle.text = "Hit-stop"
	toggle.button_pressed = controller.hit_stop.enabled
	toggle.toggled.connect(_set_hit_stop_enabled)
	row.add_child(toggle)
	var names: Array[String] = ["Light", "Heavy", "Guard"]
	for index: int in names.size():
		var profile: HitStop.Profile = index as HitStop.Profile
		var label: Label = Label.new()
		label.text = names[index]
		row.add_child(label)
		var input: SpinBox = SpinBox.new()
		input.min_value = 0.0
		input.max_value = HitStop.MAX_SECONDS * 1000.0
		input.step = 1.0
		input.suffix = "ms"
		input.value = controller.hit_stop.duration(profile) * 1000.0
		input.tooltip_text = names[index] + " impact hold at 1× playback"
		input.value_changed.connect(_set_hit_stop_duration.bind(profile))
		row.add_child(input)


func _set_hit_stop_enabled(enabled: bool) -> void:
	controller.hit_stop.enabled = enabled


func _set_hit_stop_duration(milliseconds: float, profile: HitStop.Profile) -> void:
	controller.hit_stop.configure(profile, milliseconds / 1000.0)


func _select(pose: int) -> void:
	if controller.jump_active or controller.dash_active or controller.attack_active or controller.impact_active:
		if pose == Preview.Pose.NEUTRAL:
			controller.request_idle()
		elif pose == Preview.Pose.GUARD:
			controller.request_pose(Preview.Pose.GUARD)
		return
	if pose == Preview.Pose.NEUTRAL:
		controller.request_idle()
		_selected.text = "Idle"
	elif controller.walk_active and pose == Preview.Pose.GUARD:
		controller.request_walk(0, true)
		_selected.text = Preview.NAMES[pose]
	else:
		controller.request_pose(pose as Preview.Pose)
		_selected.text = Preview.NAMES[pose]
	_pause.text = "Pause"


func _reset() -> void:
	controller.select_pose(Preview.Pose.NEUTRAL)
	controller.reset_dash_origin()
	_selected.text = "Neutral"
	_pause.text = "Pause"


func _show_idle_label() -> void:
	_selected.text = "Idle"
	_pause.text = "Pause"


func _add_walk_button(label: String, direction: int) -> void:
	var button: Button = Button.new()
	button.text = label
	button.pressed.connect(_walk.bind(direction, label))
	%PoseButtons.add_child(button)


func _walk(direction: int, label: String) -> void:
	if controller.attack_active or controller.impact_active:
		return
	if direction == 0 and not controller.walk_active and not controller.jump_active and not controller.dash_active:
		return
	controller.request_walk(direction)
	if controller.jump_active or controller.dash_active:
		return
	_selected.text = label
	_pause.text = "Pause"


func _jump() -> void:
	controller.request_jump()
	_pause.text = "Pause"


func _dash(kind: int) -> void:
	if controller.request_dash(kind as DashMotion.Kind):
		_pause.text = "Pause"


func _attack(kind: int) -> void:
	var was_active: bool = controller.attack_active
	if controller.request_attack(kind as AttackMotion.Kind) and not was_active:
		_pause.text = "Pause"


func _impact(kind: int) -> void:
	var side: OptionButton = %ImpactSide
	if controller.request_impact(kind as ImpactMotion.Kind, side.get_selected_id() as ImpactMotion.SourceSide):
		_pause.text = "Pause"
	elif kind == ImpactMotion.Kind.GUARD and not controller.impact_active and not controller.jump_active and not controller.dash_active and not controller.attack_active:
		_selected.text = "Select Guard and From Front to preview a block."


func _show_jump_status(status: String) -> void:
	_selected.text = status


func _set_jump_headroom(active: bool) -> void:
	_jump_padding = JUMP_HEADROOM if active else 0
	_hybrid_stage.size = _stage_size + Vector2i(0, _jump_padding)
	_hybrid_stage.canvas_transform = Transform2D(0.0, Vector2(_dash_view_x, _jump_padding))
	_hybrid_preview.position.y = -_jump_padding


func _follow_dash_travel() -> void:
	# Keep both comparison subjects visible after many dashes. The floor keeps
	# tracking world travel when the preview starts following the fighter.
	_dash_view_x = 71.0 * tanh(controller.dash_world_x / 74.0)
	_hybrid_stage.canvas_transform = Transform2D(0.0, Vector2(_dash_view_x, _jump_padding))
	if controller.dash_active:
		%DashDistance.text = "Dash  %.1f / %.0f px%s" % [
			absf(controller.dash_displacement), absf(DashMotion.DISTANCE[controller.dash.kind]),
			" · blocked" if controller.dash_blocked else "",
		]
	elif is_zero_approx(controller.dash_displacement):
		%DashDistance.text = ""
	queue_redraw()


func _play() -> void:
	controller.play_transition()
	_pause.text = "Pause"


func _restart() -> void:
	controller.restart_preview()
	_pause.text = "Pause"


func _toggle_pause() -> void:
	_pause.text = "Resume" if controller.toggle_pause() else "Pause"


func _set_speed(value: float) -> void:
	controller.playback_speed = value
	%SpeedLabel.text = "%.2f×" % value


func _layout_stage() -> void:
	var stage_scale: float = minf(GAME_SCALE, minf(size.x / 1070.0, (size.y - 175.0) / 540.0))
	var floor_y: float = size.y - 58.0
	_original_view.scale = Vector2.ONE * stage_scale
	_hybrid_view.scale = _original_view.scale
	_original_view.position = Vector2(roundf(size.x * 0.27 - 256.0 * stage_scale), roundf(floor_y - 503.0 * stage_scale))
	_hybrid_view.position = Vector2(roundf(size.x * 0.73 - 256.0 * stage_scale), _original_view.position.y)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("24222c"))
	draw_line(Vector2(size.x * 0.08, size.y - 57), Vector2(size.x * 0.92, size.y - 57), Color("5f5569"), 1.0)
	draw_line(Vector2(size.x * 0.5, 164), Vector2(size.x * 0.5, size.y - 58), Color("393340"), 1.0)
	if controller != null and (controller.walk_active or controller.dash_active or not is_zero_approx(controller.dash_world_x)):
		var span: float = 36.0 * _hybrid_view.scale.x
		var walk: float = controller.walk_cycle.travel() if controller.walk_active else 0.0
		var shift: float = fposmod((controller.dash_world_x - _dash_view_x + walk) * _hybrid_view.scale.x, span)
		for index: int in range(1, 12):
			var x: float = size.x * 0.73 + span * (index - 6) - shift
			draw_line(Vector2(x, size.y - 57), Vector2(x, size.y - 52), Color("796681"), 1.0)
