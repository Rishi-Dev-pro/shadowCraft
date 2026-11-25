class_name WorldMapController
extends Control

## ==============================================================================
## SHADOWCRAFT 2D — WORLD MAP HUB CONTROLLER (PHASE 6A)
## ==============================================================================
## Master orchestrator for responsive guardian markers, the route, and the
## existing progression information panel over the authored map background.
## ==============================================================================

const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const JourneyPanel = preload("res://scripts/ui/world_map/journey_panel.gd")
const LeftNavPanel = preload("res://scripts/ui/world_map/left_nav_panel.gd")
const GuardianMarker = preload("res://scripts/ui/world_map/guardian_marker.gd")

# Preloaded marker scene
const MARKER_SCENE: PackedScene = preload("res://scenes/ui/world_map/guardian_marker.tscn")
const GRIND_LOBBY_PATH: String = "res://scenes/ui/grind_lobby.tscn"

# Node references
var _bg_texture_rect: TextureRect
var _route_layer: Control
var _markers_container: Control
var _journey_panel: JourneyPanel
var _left_nav_panel: LeftNavPanel
var _grind_lobby: GrindLobby
var _grind_fade: ColorRect
var _grind_open: bool = false
var _grind_transitioning: bool = false

# Modals & Overlays
var _modal_overlay: ColorRect
var _modal_box: PanelContainer
var _modal_title: Label
var _modal_body: Label
var _modal_primary_btn: Button
var _modal_close_btn: Button

var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

# Markers collection: id -> GuardianMarker
var _markers: Dictionary = {}

# Active selection
var _selected_guardian_id: StringName = StoryProgressionState.GUARDIAN_INITIATE

# Normalized locations follow the visible buildings on the approved map art.
var _route_initiate_hunter: Array[Vector2] = [
	Vector2(0.207, 0.704), Vector2(0.235, 0.653), Vector2(0.278, 0.600),
	Vector2(0.316, 0.536), Vector2(0.308, 0.468), Vector2(0.306, 0.352)
]
var _route_hunter_executioner: Array[Vector2] = [
	Vector2(0.306, 0.352), Vector2(0.366, 0.376), Vector2(0.434, 0.420),
	Vector2(0.512, 0.445), Vector2(0.592, 0.425), Vector2(0.665, 0.390),
	Vector2(0.736, 0.350)
]
var _route_executioner_raezan: Array[Vector2] = [
	Vector2(0.736, 0.350), Vector2(0.716, 0.294), Vector2(0.675, 0.251),
	Vector2(0.625, 0.203), Vector2(0.568, 0.151), Vector2(0.512, 0.078)
]

var _pulse_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_scene_hierarchy()
	_setup_progression_listeners()
	_instantiate_markers()
	_update_all_markers_state()
	_select_guardian(StoryProgressionState.GUARDIAN_INITIATE)
	_layout_all_elements()

func _process(delta: float) -> void:
	_pulse_time += delta * 2.0
	if _route_layer != null:
		_route_layer.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_all_elements()

func _input(event: InputEvent) -> void:
	if _grind_transitioning:
		get_viewport().set_input_as_handled()
		return
	if not _grind_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9:
			_debug_advance_progression()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _left_nav_panel != null and _left_nav_panel.is_menu_open():
			if not _left_nav_panel.contains_screen_point(event.position):
				_left_nav_panel.close_menu()

func _build_scene_hierarchy() -> void:
	_bg_texture_rect = get_node("Background") as TextureRect
	assert(_bg_texture_rect != null and _bg_texture_rect.texture != null, "World Map requires its authored background")

	# The route is drawn over the map and below all guardian markers.
	_route_layer = Control.new()
	_route_layer.name = "RouteLayer"
	_route_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_route_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_route_layer.draw.connect(_on_route_layer_draw)
	add_child(_route_layer)

	_markers_container = Control.new()
	_markers_container.name = "MarkersContainer"
	_markers_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_markers_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_markers_container)

	_journey_panel = JourneyPanel.new()
	_journey_panel.name = "JourneyPanel"
	_journey_panel.anchor_left = 1.0
	_journey_panel.anchor_right = 1.0
	_journey_panel.anchor_bottom = 1.0
	_journey_panel.offset_left = -314.0
	_journey_panel.offset_top = 28.0
	_journey_panel.offset_right = -24.0
	_journey_panel.offset_bottom = -28.0
	add_child(_journey_panel)
	_journey_panel.battle_requested.connect(_on_battle_requested)
	_journey_panel.guardian_selected_from_list.connect(_on_guardian_selected_from_list)

	_left_nav_panel = LeftNavPanel.new()
	_left_nav_panel.name = "LeftCommandPanel"
	_left_nav_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	add_child(_left_nav_panel)
	_left_nav_panel.training_dojo_selected.connect(_on_training_dojo_requested)
	_left_nav_panel.world_map_selected.connect(_on_world_map_requested)
	_left_nav_panel.weapon_forge_selected.connect(_on_weapon_forge_requested)
	_left_nav_panel.grind_selected.connect(_on_grind_requested)

	_build_toast_ui()
	_build_modal_ui()

func _build_toast_ui() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	var t_style: StyleBoxFlat = StyleBoxFlat.new()
	t_style.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	t_style.border_color = Color(0.75, 0.45, 0.95, 0.85)
	t_style.set_border_width_all(1)
	t_style.set_corner_radius_all(10)
	t_style.content_margin_left = 24.0
	t_style.content_margin_right = 24.0
	t_style.content_margin_top = 10.0
	t_style.content_margin_bottom = 10.0
	_toast_panel.add_theme_stylebox_override("panel", t_style)
	add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 14)
	_toast_label.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0))
	_toast_panel.add_child(_toast_label)

func _show_toast(message: String) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast_label.text = message
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0

	var screen_sz: Vector2 = get_viewport_rect().size
	_toast_panel.reset_size()
	_toast_panel.position = Vector2((screen_sz.x - _toast_panel.size.x) * 0.5, screen_sz.y - 80.0)

	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func(): _toast_panel.visible = false)

func _build_modal_ui() -> void:
	_modal_overlay = ColorRect.new()
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.color = Color(0.02, 0.015, 0.035, 0.8)
	_modal_overlay.visible = false
	add_child(_modal_overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.add_child(center)

	_modal_box = PanelContainer.new()
	_modal_box.custom_minimum_size = Vector2(460.0, 300.0)
	var modal_style: StyleBoxFlat = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.05, 0.035, 0.08, 0.98)
	modal_style.border_color = Color(0.7, 0.45, 0.95, 0.8)
	modal_style.set_border_width_all(2)
	modal_style.set_corner_radius_all(16)
	modal_style.content_margin_left = 32.0
	modal_style.content_margin_right = 32.0
	modal_style.content_margin_top = 28.0
	modal_style.content_margin_bottom = 28.0
	_modal_box.add_theme_stylebox_override("panel", modal_style)
	center.add_child(_modal_box)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	_modal_box.add_child(col)

	_modal_title = Label.new()
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_title.add_theme_font_size_override("font_size", 20)
	_modal_title.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0))
	col.add_child(_modal_title)

	var sep: HSeparator = HSeparator.new()
	var sep_style: StyleBoxLine = StyleBoxLine.new()
	sep_style.color = Color(0.55, 0.35, 0.75, 0.5)
	sep.add_theme_stylebox_override("separator", sep_style)
	col.add_child(sep)

	_modal_body = Label.new()
	_modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_body.add_theme_font_size_override("font_size", 13)
	_modal_body.add_theme_color_override("font_color", Color(0.85, 0.8, 0.92))
	col.add_child(_modal_body)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	col.add_child(btn_row)

	_modal_primary_btn = Button.new()
	_modal_primary_btn.text = "ENTER TRAINING DOJO"
	_modal_primary_btn.custom_minimum_size = Vector2(200.0, 44.0)
	_modal_primary_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var p_style: StyleBoxFlat = StyleBoxFlat.new()
	p_style.bg_color = Color(0.25, 0.14, 0.38, 0.95)
	p_style.border_color = Color(0.85, 0.55, 1.0)
	p_style.set_border_width_all(1)
	p_style.set_corner_radius_all(8)
	_modal_primary_btn.add_theme_stylebox_override("normal", p_style)
	_modal_primary_btn.add_theme_stylebox_override("hover", p_style)
	btn_row.add_child(_modal_primary_btn)
	_modal_primary_btn.pressed.connect(_on_modal_primary_pressed)

	_modal_close_btn = Button.new()
	_modal_close_btn.text = "RETURN TO MAP"
	_modal_close_btn.custom_minimum_size = Vector2(140.0, 44.0)
	_modal_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var c_style: StyleBoxFlat = StyleBoxFlat.new()
	c_style.bg_color = Color(0.12, 0.08, 0.16, 0.8)
	c_style.border_color = Color(0.4, 0.35, 0.5, 0.5)
	c_style.set_border_width_all(1)
	c_style.set_corner_radius_all(8)
	_modal_close_btn.add_theme_stylebox_override("normal", c_style)
	_modal_close_btn.add_theme_stylebox_override("hover", c_style)
	btn_row.add_child(_modal_close_btn)
	_modal_close_btn.pressed.connect(func(): _modal_overlay.visible = false)

func _instantiate_markers() -> void:
	var markers_spec: Array[Dictionary] = [
		{
			"id": StoryProgressionState.GUARDIAN_INITIATE,
			"title": "The Initiate",
			"category": "Guardian I",
			"boss": false,
			"norm_pos": Vector2(0.207, 0.704)
		},
		{
			"id": StoryProgressionState.GUARDIAN_HUNTER,
			"title": "The Hunter",
			"category": "Guardian II",
			"boss": false,
			"norm_pos": Vector2(0.306, 0.352)
		},
		{
			"id": StoryProgressionState.GUARDIAN_EXECUTIONER,
			"title": "The Executioner",
			"category": "Guardian III",
			"boss": false,
			"norm_pos": Vector2(0.736, 0.350)
		},
		{
			"id": StoryProgressionState.BOSS_RAEZEN,
			"title": "Raezen's Citadel",
			"category": "Final Boss",
			"boss": true,
			"norm_pos": Vector2(0.512, 0.078)
		}
	]

	for spec: Dictionary in markers_spec:
		var marker: GuardianMarker = MARKER_SCENE.instantiate() as GuardianMarker
		marker.set_marker_data(spec["id"], spec["title"], spec["category"], spec["boss"], spec["norm_pos"])
		marker.marker_selected.connect(_on_marker_selected)
		_markers_container.add_child(marker)
		_markers[spec["id"]] = marker

func _setup_progression_listeners() -> void:
	var sp = get_node_or_null("/root/StoryProgression")
	if sp != null and sp.has_signal(&"progression_updated"):
		if not sp.progression_updated.is_connected(_on_progression_updated):
			sp.progression_updated.connect(_on_progression_updated)

func _on_progression_updated() -> void:
	_update_all_markers_state()
	_journey_panel.update_panel(_selected_guardian_id)
	if _route_layer != null:
		_route_layer.queue_redraw()

func _update_all_markers_state() -> void:
	var sp = get_node_or_null("/root/StoryProgression")
	for id: StringName in _markers:
		var marker: GuardianMarker = _markers[id]
		var unlocked: bool = (sp != null and sp.is_guardian_unlocked(id))
		var defeated: bool = (sp != null and sp.is_guardian_defeated(id))
		marker.set_status(unlocked, defeated)
		marker.set_selected(id == _selected_guardian_id)

func _select_guardian(guardian_id: StringName) -> void:
	_selected_guardian_id = guardian_id
	for id: StringName in _markers:
		var marker: GuardianMarker = _markers[id]
		marker.set_selected(id == _selected_guardian_id)

	_journey_panel.update_panel(_selected_guardian_id)

func _on_marker_selected(marker_id: StringName) -> void:
	_select_guardian(marker_id)

func _on_guardian_selected_from_list(guardian_id: StringName) -> void:
	_select_guardian(guardian_id)

func _on_battle_requested(guardian_id: StringName) -> void:
	var sp: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	var is_unlocked: bool = (sp != null and sp.is_guardian_unlocked(guardian_id))
	if not is_unlocked:
		_show_toast("🔒 Locked: Defeat prior guardians to unlock this encounter.")
		return
	if guardian_id in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER, StoryProgressionState.BOSS_RAEZEN]:
		if sp == null or not sp.begin_guardian_encounter(guardian_id):
			_show_toast("This guardian trial could not be started.")
			return
		get_tree().paused = false
		var arena_scene_path: String = _arena_scene_path_for_guardian(guardian_id)
		var error: Error = get_tree().change_scene_to_file(arena_scene_path)
		if error != OK:
			sp.end_guardian_encounter()
			var guardian_name: String = "The Initiate"
			if guardian_id == StoryProgressionState.GUARDIAN_HUNTER:
				guardian_name = "The Hunter"
			elif guardian_id == StoryProgressionState.GUARDIAN_EXECUTIONER:
				guardian_name = "The Executioner"
			elif guardian_id == StoryProgressionState.BOSS_RAEZEN:
				guardian_name = "Raezan, The Betrayer King"
			_show_toast("Could not enter %s's trial: %s" % [guardian_name, error_string(error)])
		return

	# Show encounter modal
	var guardian_name: String = "The Guardian"
	match guardian_id:
		StoryProgressionState.GUARDIAN_INITIATE:
			guardian_name = "The Initiate"
		StoryProgressionState.GUARDIAN_HUNTER:
			guardian_name = "The Hunter"
		StoryProgressionState.GUARDIAN_EXECUTIONER:
			guardian_name = "The Executioner"
		StoryProgressionState.BOSS_RAEZEN:
			guardian_name = "Raezen (Final Boss)"

	_modal_title.text = "⚔ ENCOUNTER: " + guardian_name.to_upper()
	_modal_body.text = "Guardian combat arenas and AI encounters arrive in Phase 6B!\n\nYou can enter the Training Dojo now to test Kai and Raezen's full movesets against the training dummy."
	_modal_overlay.visible = true

func _arena_scene_path_for_guardian(guardian_id: StringName) -> String:
	match guardian_id:
		StoryProgressionState.GUARDIAN_HUNTER:
			return "res://scenes/arenas/MistfallCrossing.tscn"
		StoryProgressionState.GUARDIAN_EXECUTIONER:
			return "res://scenes/arenas/CrimsonSanctum.tscn"
		StoryProgressionState.BOSS_RAEZEN:
			return "res://scenes/arenas/RaezenCitadel.tscn"
		_:
			return "res://scenes/arenas/MovementTestArena.tscn"

func _on_modal_primary_pressed() -> void:
	_modal_overlay.visible = false
	_on_training_dojo_requested()

func _on_training_dojo_requested() -> void:
	get_tree().paused = false
	var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	if progression != null:
		progression.end_guardian_encounter()
	var scene_error: Error = get_tree().change_scene_to_file("res://scenes/arenas/MovementTestArena.tscn")
	if scene_error != OK:
		_show_toast("Failed to load the Training Dojo arena.")

func _on_world_map_requested() -> void:
	if _grind_open:
		_transition_grind(false)
		return
	var active_scene: Node = get_tree().current_scene
	if active_scene == null or active_scene.scene_file_path != "res://scenes/ui/world_map.tscn":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/world_map.tscn")

func _on_weapon_forge_requested() -> void:
	if _grind_open:
		_grind_lobby.show_forge_requirement()
		return
	_show_toast("Weapon Forge — Coming Soon")

func _on_grind_requested() -> void:
	_transition_grind(true)

func _transition_grind(open: bool) -> void:
	if _grind_transitioning or open == _grind_open:
		return
	if open and _grind_lobby == null:
		var lobby_scene: PackedScene = load(GRIND_LOBBY_PATH) as PackedScene
		if lobby_scene == null:
			_show_toast("Could not open the Grind lobby.")
			return
		_grind_lobby = lobby_scene.instantiate() as GrindLobby
		_grind_lobby.hide()
		add_child(_grind_lobby)
		move_child(_grind_lobby, _left_nav_panel.get_index())
		_grind_lobby.world_map_requested.connect(_on_world_map_requested)

		_grind_fade = ColorRect.new()
		_grind_fade.color = Color("#0d0912")
		add_child(_grind_fade)
		_grind_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_grind_transitioning = true
	_grind_fade.modulate.a = 0.0
	_grind_fade.show()
	var fade_out: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(_grind_fade, "modulate:a", 1.0, 0.16)
	await fade_out.finished

	_grind_open = open
	set_process(not open)
	_bg_texture_rect.visible = not open
	_route_layer.visible = not open
	_markers_container.visible = not open
	_journey_panel.visible = not open
	_toast_panel.hide()
	_left_nav_panel.set_grind_active(open)
	_grind_lobby.visible = open
	if open:
		_grind_lobby.refresh_inventory()

	var fade_in: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(_grind_fade, "modulate:a", 0.0, 0.22)
	await fade_in.finished
	_grind_fade.hide()
	_grind_transitioning = false

func _debug_advance_progression() -> void:
	var sp = get_node_or_null("/root/StoryProgression")
	if sp == null:
		return
	if not sp.is_guardian_defeated(StoryProgressionState.GUARDIAN_INITIATE):
		sp.record_guardian_victory(StoryProgressionState.GUARDIAN_INITIATE)
		_show_toast("Debug [F9]: The Initiate Defeated -> The Hunter Unlocked!")
	elif not sp.is_guardian_defeated(StoryProgressionState.GUARDIAN_HUNTER):
		sp.record_guardian_victory(StoryProgressionState.GUARDIAN_HUNTER)
		_show_toast("Debug [F9]: The Hunter Defeated -> The Executioner Unlocked!")
	elif not sp.is_guardian_defeated(StoryProgressionState.GUARDIAN_EXECUTIONER):
		sp.record_guardian_victory(StoryProgressionState.GUARDIAN_EXECUTIONER)
		_show_toast("Debug [F9]: The Executioner Defeated -> Raezen's Citadel Unlocked!")
	else:
		sp.reset_progress()
		_show_toast("Debug [F9]: Progression Reset to Fresh State.")

# ==============================================================================
# GEOMETRY & LAYOUT POSITIONING
# ==============================================================================

func _get_covered_texture_rect() -> Rect2:
	var viewport_sz: Vector2 = get_viewport_rect().size
	if viewport_sz.x <= 0 or viewport_sz.y <= 0:
		viewport_sz = Vector2(1920.0, 1080.0)

	var texture_size: Vector2 = _bg_texture_rect.texture.get_size()
	var cover_scale: float = maxf(viewport_sz.x / texture_size.x, viewport_sz.y / texture_size.y)
	var rendered_sz: Vector2 = texture_size * cover_scale
	var offset: Vector2 = (viewport_sz - rendered_sz) * 0.5
	return Rect2(offset, rendered_sz)

func _norm_to_screen(norm: Vector2) -> Vector2:
	var r: Rect2 = _get_covered_texture_rect()
	return r.position + Vector2(norm.x * r.size.x, norm.y * r.size.y)

func _layout_all_elements() -> void:
	var viewport_sz: Vector2 = get_viewport_rect().size
	if viewport_sz.x <= 0 or viewport_sz.y <= 0:
		return

	if _left_nav_panel != null:
		var compact_layout: bool = viewport_sz.x < 900.0 or viewport_sz.y < 600.0
		var panel_width: float = minf(252.0, viewport_sz.x * 0.18)
		var panel_height: float = minf(420.0, viewport_sz.y * 0.49)
		if compact_layout:
			panel_width = minf(180.0, viewport_sz.x * 0.19)
			panel_height = minf(270.0, viewport_sz.y - 32.0)
		_left_nav_panel.set_responsive_size(panel_width, panel_height)
		_left_nav_panel.position = Vector2(12.0, 12.0 if compact_layout else 16.0)

	# Position markers
	for id: StringName in _markers:
		var marker: GuardianMarker = _markers[id]
		var screen_pt: Vector2 = _norm_to_screen(marker.normalized_position)
		if marker.normalized_position.x > 0.55:
			# Label on left, badge on right: center badge at screen_pt
			marker.position = Vector2(screen_pt.x - marker.size.x + 19.0, screen_pt.y - 19.0)
		else:
			# Badge on left: center badge at screen_pt
			marker.position = screen_pt - Vector2(19.0, 19.0)

	if _route_layer != null:
		_route_layer.queue_redraw()

# ==============================================================================
# ROUTE DRAWING
# ==============================================================================

func _on_route_layer_draw() -> void:
	if _route_layer == null:
		return
	var waypoints: Array[Vector2] = _route_initiate_hunter.duplicate()
	for index: int in range(1, _route_hunter_executioner.size()):
		waypoints.append(_route_hunter_executioner[index])
	for index: int in range(1, _route_executioner_raezan.size()):
		waypoints.append(_route_executioner_raezan[index])
	var route_points: PackedVector2Array = _smooth_route(waypoints)
	if route_points.size() < 2:
		return

	_route_layer.draw_polyline(route_points, Color(0.77, 0.28, 1.0, 0.22), 9.0, true)
	_route_layer.draw_polyline(route_points, Color(0.88, 0.48, 1.0, 0.38), 3.0, true)

	var dot_spacing: float = 17.0
	var distance_to_next_dot: float = 0.0
	var dot_index: int = 0
	for index: int in range(route_points.size() - 1):
		var start: Vector2 = route_points[index]
		var finish: Vector2 = route_points[index + 1]
		var segment_length: float = start.distance_to(finish)
		if segment_length <= 0.001:
			continue
		while distance_to_next_dot <= segment_length:
			var dot_position: Vector2 = start.lerp(finish, distance_to_next_dot / segment_length)
			var pulse: float = 0.5 + 0.5 * sin(_pulse_time - float(dot_index) * 0.22)
			var radius: float = 2.0 + pulse * 1.25
			_route_layer.draw_circle(dot_position, radius + 2.0, Color(0.92, 0.48, 1.0, 0.11 + pulse * 0.1))
			_route_layer.draw_circle(dot_position, radius, Color(1.0, 0.82, 1.0, 0.72 + pulse * 0.25))
			dot_index += 1
			distance_to_next_dot += dot_spacing
		distance_to_next_dot -= segment_length

	for checkpoint: Vector2 in [
		_route_initiate_hunter.front(),
		_route_hunter_executioner.front(),
		_route_executioner_raezan.front(),
		_route_executioner_raezan.back()
	]:
		var center: Vector2 = _norm_to_screen(checkpoint)
		_route_layer.draw_circle(center, 10.0, Color(0.82, 0.35, 1.0, 0.15))
		_route_layer.draw_arc(center, 11.0, 0.0, TAU, 32, Color(0.94, 0.63, 1.0, 0.86), 2.0, true)

func _smooth_route(waypoints: Array[Vector2]) -> PackedVector2Array:
	var sampled: PackedVector2Array = PackedVector2Array()
	if waypoints.size() < 2:
		return sampled
	const SAMPLES_PER_SEGMENT: int = 14
	for segment_index: int in range(waypoints.size() - 1):
		var p0: Vector2 = waypoints[maxi(segment_index - 1, 0)]
		var p1: Vector2 = waypoints[segment_index]
		var p2: Vector2 = waypoints[segment_index + 1]
		var p3: Vector2 = waypoints[mini(segment_index + 2, waypoints.size() - 1)]
		for sample_index: int in range(SAMPLES_PER_SEGMENT + 1):
			if segment_index > 0 and sample_index == 0:
				continue
			var t: float = float(sample_index) / float(SAMPLES_PER_SEGMENT)
			var t_squared: float = t * t
			var t_cubed: float = t_squared * t
			var point: Vector2 = 0.5 * (
				2.0 * p1
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t_squared
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t_cubed
			)
			sampled.append(_norm_to_screen(point))
	return sampled
