class_name JourneyPanel
extends PanelContainer

## Cinematic guardian dossier used by the World Map's existing selection flow.

const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const PORTRAIT_ROOT: String = "res://assets/ui/world_map/portraits/"

signal battle_requested(guardian_id: StringName)
signal guardian_selected_from_list(guardian_id: StringName)

var current_guardian_id: StringName = &"razen_citadel"

var _content_box: VBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _emblem_label: Label
var _portrait_frame: PanelContainer
var _portrait_style: StyleBoxFlat
var _portrait_texture: TextureRect
var _lore_label: Label
var _overview_heading: Label
var _objective_heading: Label
var _progress_section: VBoxContainer
var _progress_count_label: Label
var _progress_bar: ProgressBar
var _progress_fill: StyleBoxFlat
var _guardians_list_box: VBoxContainer
var _guardian_details_box: VBoxContainer
var _req_label: Label
var _boss_unlock_card: PanelContainer
var _guardian_unlock_style: StyleBoxFlat
var _boss_unlock_style: StyleBoxFlat
var _boss_unlock_label: Label
var _status_panel: PanelContainer
var _status_badge: Label
var _objective_label: Label
var _action_button: Button
var _ambient_tween: Tween

const COLOR_PURPLE: Color = Color(0.76, 0.46, 1.0)
const COLOR_PURPLE_BRIGHT: Color = Color(0.92, 0.72, 1.0)
const COLOR_CRIMSON: Color = Color(0.95, 0.28, 0.43)
const COLOR_MUTED: Color = Color(0.68, 0.64, 0.76)
const COLOR_TEXT: Color = Color(0.95, 0.92, 1.0)
const COLOR_PANEL: Color = Color(0.025, 0.018, 0.045, 0.94)
const GUARDIAN_PORTRAITS: Dictionary = {
	StoryProgressionState.GUARDIAN_INITIATE: PORTRAIT_ROOT + "guardian_initiate_dossier.png",
	StoryProgressionState.GUARDIAN_HUNTER: PORTRAIT_ROOT + "guardian_hunter_portrait.png",
	StoryProgressionState.GUARDIAN_EXECUTIONER: PORTRAIT_ROOT + "guardian_executioner_portrait.png"
}


func _ready() -> void:
	custom_minimum_size = Vector2(290.0, 600.0)
	_build_ui()
	_start_ambient_glow()
	update_panel(current_guardian_id)


func update_panel(guardian_id: StringName) -> void:
	current_guardian_id = guardian_id
	if _content_box == null:
		return

	var is_boss: bool = guardian_id == StoryProgressionState.BOSS_RAEZEN
	var progression: Node = get_node_or_null("/root/StoryProgression")
	var is_unlocked: bool = false
	var is_defeated: bool = false
	if progression != null:
		is_unlocked = progression.is_guardian_unlocked(guardian_id)
		is_defeated = progression.is_guardian_defeated(guardian_id)

	if is_boss:
		_render_razen_view(progression, is_unlocked, is_defeated)
	else:
		_render_guardian_view(guardian_id, is_unlocked, is_defeated)


func _build_ui() -> void:
	var outer_style: StyleBoxFlat = StyleBoxFlat.new()
	outer_style.bg_color = COLOR_PANEL
	outer_style.border_color = Color(0.58, 0.34, 0.82, 0.88)
	outer_style.set_border_width_all(2)
	outer_style.set_corner_radius_all(14)
	outer_style.shadow_color = Color(0.38, 0.12, 0.63, 0.22)
	outer_style.shadow_size = 14
	outer_style.shadow_offset = Vector2(0.0, 0.0)
	outer_style.content_margin_left = 13.0
	outer_style.content_margin_right = 13.0
	outer_style.content_margin_top = 13.0
	outer_style.content_margin_bottom = 13.0
	add_theme_stylebox_override("panel", outer_style)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 8)
	add_child(_content_box)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_box.add_child(header)

	var emblem_frame: PanelContainer = PanelContainer.new()
	emblem_frame.custom_minimum_size = Vector2(38.0, 38.0)
	var emblem_style: StyleBoxFlat = StyleBoxFlat.new()
	emblem_style.bg_color = Color(0.15, 0.075, 0.22, 0.82)
	emblem_style.border_color = Color(0.69, 0.4, 0.94, 0.85)
	emblem_style.set_border_width_all(1)
	emblem_style.set_corner_radius_all(19)
	emblem_frame.add_theme_stylebox_override("panel", emblem_style)
	header.add_child(emblem_frame)
	_emblem_label = Label.new()
	_emblem_label.text = "✦"
	_emblem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emblem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_emblem_label.add_theme_font_size_override("font_size", 22)
	_emblem_label.add_theme_color_override("font_color", COLOR_PURPLE_BRIGHT)
	emblem_frame.add_child(_emblem_label)

	var heading: VBoxContainer = VBoxContainer.new()
	heading.add_theme_constant_override("separation", 1)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", COLOR_TEXT)
	_title_label.clip_text = true
	heading.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 9)
	_subtitle_label.add_theme_color_override("font_color", COLOR_PURPLE)
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(_subtitle_label)

	_content_box.add_child(_make_separator(Color(0.62, 0.39, 0.83, 0.7), 1))

	_portrait_frame = PanelContainer.new()
	_portrait_frame.custom_minimum_size = Vector2(0.0, 176.0)
	_portrait_frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_portrait_style = StyleBoxFlat.new()
	_portrait_style.bg_color = Color(0.055, 0.035, 0.095, 0.98)
	_portrait_style.border_color = Color(0.69, 0.42, 0.91, 0.92)
	_portrait_style.set_border_width_all(1)
	_portrait_style.set_corner_radius_all(9)
	_portrait_style.shadow_color = Color(0.47, 0.16, 0.75, 0.24)
	_portrait_style.shadow_size = 8
	_portrait_style.content_margin_left = 4.0
	_portrait_style.content_margin_right = 4.0
	_portrait_style.content_margin_top = 4.0
	_portrait_style.content_margin_bottom = 4.0
	_portrait_frame.add_theme_stylebox_override("panel", _portrait_style)
	_content_box.add_child(_portrait_frame)

	_portrait_texture = TextureRect.new()
	_portrait_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait_texture)

	_overview_heading = _make_section_heading("✦  OVERVIEW")
	_content_box.add_child(_overview_heading)
	_lore_label = Label.new()
	_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lore_label.add_theme_font_size_override("font_size", 12)
	_lore_label.add_theme_color_override("font_color", Color(0.83, 0.79, 0.89))
	_content_box.add_child(_lore_label)

	_progress_section = VBoxContainer.new()
	_progress_section.add_theme_constant_override("separation", 7)
	_content_box.add_child(_progress_section)
	var progress_header: HBoxContainer = HBoxContainer.new()
	_progress_section.add_child(progress_header)
	var progress_title: Label = Label.new()
	progress_title.text = "GUARDIANS DEFEATED"
	progress_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_title.add_theme_font_size_override("font_size", 9)
	progress_title.add_theme_color_override("font_color", COLOR_MUTED)
	progress_header.add_child(progress_title)
	_progress_count_label = Label.new()
	_progress_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_count_label.add_theme_font_size_override("font_size", 12)
	_progress_count_label.add_theme_color_override("font_color", COLOR_PURPLE_BRIGHT)
	progress_header.add_child(_progress_count_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0.0, 7.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 3.0
	_progress_bar.show_percentage = false
	var progress_bg: StyleBoxFlat = StyleBoxFlat.new()
	progress_bg.bg_color = Color(0.14, 0.1, 0.18, 0.95)
	progress_bg.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("background", progress_bg)
	_progress_fill = StyleBoxFlat.new()
	_progress_fill.bg_color = COLOR_PURPLE
	_progress_fill.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("fill", _progress_fill)
	_progress_section.add_child(_progress_bar)
	_guardians_list_box = VBoxContainer.new()
	_guardians_list_box.add_theme_constant_override("separation", 4)
	_progress_section.add_child(_guardians_list_box)

	_guardian_details_box = VBoxContainer.new()
	_guardian_details_box.add_theme_constant_override("separation", 6)
	_content_box.add_child(_guardian_details_box)
	_objective_heading = _make_section_heading("◎  OBJECTIVE")
	_guardian_details_box.add_child(_objective_heading)
	_objective_label = Label.new()
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 11)
	_objective_label.add_theme_color_override("font_color", Color(0.83, 0.79, 0.89))
	_guardian_details_box.add_child(_objective_label)

	var unlock_card: PanelContainer = _make_unlock_card()
	_guardian_unlock_style = unlock_card.get_theme_stylebox("panel") as StyleBoxFlat
	_guardian_details_box.add_child(unlock_card)
	_req_label = Label.new()
	_req_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_req_label.add_theme_font_size_override("font_size", 11)
	_req_label.add_theme_color_override("font_color", COLOR_TEXT)
	unlock_card.get_child(0).add_child(_req_label)

	_status_panel = PanelContainer.new()
	var status_style: StyleBoxFlat = StyleBoxFlat.new()
	status_style.bg_color = Color(0.14, 0.08, 0.19, 0.86)
	status_style.border_color = Color(0.58, 0.34, 0.78, 0.52)
	status_style.set_border_width_all(1)
	status_style.set_corner_radius_all(5)
	status_style.content_margin_left = 8.0
	status_style.content_margin_right = 8.0
	status_style.content_margin_top = 5.0
	status_style.content_margin_bottom = 5.0
	_status_panel.add_theme_stylebox_override("panel", status_style)
	_guardian_details_box.add_child(_status_panel)
	_status_badge = Label.new()
	_status_badge.add_theme_font_size_override("font_size", 11)
	_status_panel.add_child(_status_badge)

	_boss_unlock_card = _make_unlock_card()
	_boss_unlock_style = _boss_unlock_card.get_theme_stylebox("panel") as StyleBoxFlat
	_content_box.add_child(_boss_unlock_card)
	_boss_unlock_label = Label.new()
	_boss_unlock_label.text = "Defeat all three Guardians to reach Raezen."
	_boss_unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_unlock_label.add_theme_font_size_override("font_size", 11)
	_boss_unlock_label.add_theme_color_override("font_color", COLOR_TEXT)
	_boss_unlock_card.get_child(0).add_child(_boss_unlock_label)
	_boss_unlock_card.visible = false

	var footer_spacer: Control = Control.new()
	footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(footer_spacer)
	_content_box.add_child(_make_separator(Color(0.42, 0.28, 0.57, 0.58), 1))
	_action_button = Button.new()
	_action_button.custom_minimum_size = Vector2(0.0, 46.0)
	_action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_action_button.add_theme_font_size_override("font_size", 14)
	_content_box.add_child(_action_button)
	_action_button.pressed.connect(_on_action_pressed)


func _render_razen_view(progression: Node, is_unlocked: bool, is_defeated: bool) -> void:
	_title_label.text = "RAEZEN"
	_subtitle_label.text = "FINAL GUARDIAN  •  CRIMSON CITADEL"
	_subtitle_label.add_theme_color_override("font_color", COLOR_CRIMSON)
	_emblem_label.add_theme_color_override("font_color", COLOR_CRIMSON)
	_lore_label.text = "The Crimson Warlord waits beyond the three guardian seals."
	_set_portrait(PORTRAIT_ROOT + "raezen_battle_portrait.png", TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_progress_section.visible = true
	_guardian_details_box.visible = false
	_boss_unlock_card.visible = true

	var defeated_count: int = 0
	if progression != null:
		defeated_count = progression.get_guardians_defeated_count()
	_progress_count_label.text = "%d / 3" % defeated_count
	_progress_bar.value = defeated_count
	_set_boss_accent()
	_rebuild_guardians_list(progression)

	if is_defeated:
		_action_button.text = "⚔  REMATCH"
		_action_button.tooltip_text = "Fight Raezen again"
	else:
		_action_button.text = "⚔  FIGHT RAEZEN" if is_unlocked else "🔒  FIGHT RAEZEN"
		_action_button.tooltip_text = ""
	_style_action_button(is_unlocked, is_defeated, true, true)


func _render_guardian_view(guardian_id: StringName, is_unlocked: bool, is_defeated: bool) -> void:
	_progress_section.visible = false
	_guardian_details_box.visible = true
	_boss_unlock_card.visible = false

	var guardian_name: String = ""
	var rank_and_territory: String = ""
	var lore: String = ""
	var requirement: String = ""
	var portrait_path: String = ""
	match guardian_id:
		StoryProgressionState.GUARDIAN_INITIATE:
			guardian_name = "The Initiate"
			rank_and_territory = "GUARDIAN I  •  VALLEY OF WHISPERS"
			lore = "A disciplined sentinel of the valley waters, sworn to guard the first seal."
			requirement = "UNLOCK  •  No prior trial required"
			portrait_path = GUARDIAN_PORTRAITS[guardian_id]
		StoryProgressionState.GUARDIAN_HUNTER:
			guardian_name = "The Hunter"
			rank_and_territory = "GUARDIAN II  •  MIST WATERFALLS"
			lore = "A swift predator of the upper cataracts who answers every opening with precision."
			requirement = "UNLOCK  •  Defeat The Initiate"
			portrait_path = GUARDIAN_PORTRAITS[guardian_id]
		StoryProgressionState.GUARDIAN_EXECUTIONER:
			guardian_name = "The Executioner"
			rank_and_territory = "GUARDIAN III  •  FROZEN PASS"
			lore = "An armored colossus guarding the frozen mill pass, feared for punishing overreach."
			requirement = "UNLOCK  •  Defeat The Hunter"
			portrait_path = GUARDIAN_PORTRAITS[guardian_id]

	_title_label.text = guardian_name
	_subtitle_label.text = rank_and_territory
	_lore_label.text = lore
	_set_portrait(portrait_path, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_req_label.text = "No prior trial required." if guardian_id == StoryProgressionState.GUARDIAN_INITIATE else requirement.replace("UNLOCK  •  ", "")
	_objective_label.text = "Win this trial to break the ward and open the next territory."
	_set_guardian_accent()

	var status_style: StyleBoxFlat = _status_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if is_defeated:
		_status_badge.text = "✦  DEFEATED"
		_status_badge.add_theme_color_override("font_color", Color(0.52, 0.91, 0.7))
		status_style.bg_color = Color(0.055, 0.15, 0.105, 0.9)
		status_style.border_color = Color(0.35, 0.74, 0.53, 0.7)
	elif is_unlocked:
		_status_badge.text = "✦  AVAILABLE"
		_status_badge.add_theme_color_override("font_color", COLOR_PURPLE_BRIGHT)
		status_style.bg_color = Color(0.16, 0.08, 0.23, 0.92)
		status_style.border_color = Color(0.72, 0.43, 0.96, 0.85)
	else:
		_status_badge.text = "⌑  LOCKED"
		_status_badge.add_theme_color_override("font_color", Color(0.62, 0.57, 0.69))
		status_style.bg_color = Color(0.07, 0.055, 0.09, 0.9)
		status_style.border_color = Color(0.31, 0.27, 0.36, 0.65)
	_status_panel.add_theme_stylebox_override("panel", status_style)

	var supports_rematch: bool = guardian_id in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER]
	if is_defeated and supports_rematch:
		_action_button.text = "⚔  REMATCH"
		_action_button.tooltip_text = "Fight this guardian again"
	else:
		_action_button.text = "DEFEATED" if is_defeated else ("⚔  ENTER BATTLE" if is_unlocked else "🔒  GUARDIAN LOCKED")
		_action_button.tooltip_text = ""
	_style_action_button(is_unlocked, is_defeated, false, supports_rematch)


func _set_portrait(path: String, stretch_mode: TextureRect.StretchMode) -> void:
	_portrait_texture.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_portrait_texture.stretch_mode = stretch_mode


func _rebuild_guardians_list(progression: Node) -> void:
	for child: Node in _guardians_list_box.get_children():
		child.queue_free()

	var guardian_rows: Array[Dictionary] = [
		{"id": StoryProgressionState.GUARDIAN_INITIATE, "name": "The Initiate", "rank": "GUARDIAN I", "portrait": GUARDIAN_PORTRAITS[StoryProgressionState.GUARDIAN_INITIATE]},
		{"id": StoryProgressionState.GUARDIAN_HUNTER, "name": "The Hunter", "rank": "GUARDIAN II", "portrait": GUARDIAN_PORTRAITS[StoryProgressionState.GUARDIAN_HUNTER]},
		{"id": StoryProgressionState.GUARDIAN_EXECUTIONER, "name": "The Executioner", "rank": "GUARDIAN III", "portrait": GUARDIAN_PORTRAITS[StoryProgressionState.GUARDIAN_EXECUTIONER]}
	]
	for data: Dictionary in guardian_rows:
		var guardian_id: StringName = data["id"]
		var unlocked: bool = progression != null and progression.is_guardian_unlocked(guardian_id)
		var defeated: bool = progression != null and progression.is_guardian_defeated(guardian_id)
		var row: PanelContainer = _make_guardian_row(data, unlocked, defeated)
		_guardians_list_box.add_child(row)


func _make_guardian_row(data: Dictionary, unlocked: bool, defeated: bool) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	var row_style: StyleBoxFlat = StyleBoxFlat.new()
	row_style.bg_color = Color(0.07, 0.045, 0.1, 0.85)
	row_style.border_color = Color(0.36, 0.27, 0.47, 0.55)
	row_style.set_border_width_all(1)
	row_style.set_corner_radius_all(5)
	row_style.content_margin_left = 0.0
	row_style.content_margin_right = 8.0
	row_style.content_margin_top = 0.0
	row_style.content_margin_bottom = 0.0
	row.add_theme_stylebox_override("panel", row_style)
	var contents: HBoxContainer = HBoxContainer.new()
	contents.add_theme_constant_override("separation", 8)
	row.add_child(contents)
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(82.0, 54.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = load(data["portrait"]) as Texture2D if ResourceLoader.exists(data["portrait"]) else null
	contents.add_child(portrait)
	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 0)
	contents.add_child(text_column)
	var name_label: Label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	text_column.add_child(name_label)
	var rank_label: Label = Label.new()
	rank_label.text = data["rank"]
	rank_label.add_theme_font_size_override("font_size", 8)
	rank_label.add_theme_color_override("font_color", COLOR_MUTED)
	text_column.add_child(rank_label)
	var status_label: Label = Label.new()
	status_label.text = "DEFEATED" if defeated else ("OPEN" if unlocked else "🔒 LOCKED")
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(0.52, 0.91, 0.7) if defeated else (COLOR_PURPLE if unlocked else COLOR_MUTED))
	contents.add_child(status_label)
	var row_button: Button = Button.new()
	row_button.flat = true
	row_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		row_button.add_theme_stylebox_override(state, empty_style)
	row.add_child(row_button)
	var guardian_id: StringName = data["id"]
	row_button.pressed.connect(func() -> void: guardian_selected_from_list.emit(guardian_id))
	return row


func _style_action_button(unlocked: bool, defeated: bool, is_boss: bool, supports_rematch: bool = false) -> void:
	var accent: Color = COLOR_CRIMSON if is_boss else COLOR_PURPLE
	var can_enter: bool = unlocked and (not defeated or supports_rematch)
	_action_button.disabled = not can_enter
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.055, 0.19, 0.96) if can_enter else Color(0.07, 0.055, 0.09, 0.92)
	normal_style.border_color = accent if can_enter else Color(0.31, 0.27, 0.36, 0.66)
	normal_style.set_border_width_all(2 if can_enter else 1)
	normal_style.set_corner_radius_all(8)
	normal_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.28) if can_enter else Color.TRANSPARENT
	normal_style.shadow_size = 8 if can_enter else 0
	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.22, 0.11, 0.31, 1.0)
	hover_style.border_color = COLOR_TEXT
	_action_button.add_theme_stylebox_override("normal", normal_style)
	_action_button.add_theme_stylebox_override("hover", hover_style)
	_action_button.add_theme_stylebox_override("pressed", hover_style)
	_action_button.add_theme_stylebox_override("disabled", normal_style)
	_action_button.add_theme_color_override("font_color", COLOR_TEXT)
	_action_button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	_action_button.add_theme_color_override("font_disabled_color", COLOR_MUTED)


func _make_separator(color: Color, thickness: int) -> HSeparator:
	var separator: HSeparator = HSeparator.new()
	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = color
	line.thickness = thickness
	separator.add_theme_stylebox_override("separator", line)
	return separator


func _start_ambient_glow() -> void:
	var panel_style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	_ambient_tween = create_tween().set_loops()
	_ambient_tween.tween_property(panel_style, "border_color", Color(0.77, 0.52, 0.98, 0.96), 1.8)
	_ambient_tween.tween_property(panel_style, "border_color", Color(0.48, 0.27, 0.68, 0.82), 1.8)


func _make_section_heading(text: String) -> Label:
	var heading: Label = Label.new()
	heading.text = text
	heading.add_theme_font_size_override("font_size", 11)
	heading.add_theme_color_override("font_color", COLOR_PURPLE_BRIGHT)
	return heading


func _make_unlock_card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.045, 0.12, 0.84)
	style.border_color = Color(0.72, 0.42, 0.91, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	card.add_theme_stylebox_override("panel", style)
	var text_stack: VBoxContainer = VBoxContainer.new()
	text_stack.add_theme_constant_override("separation", 4)
	card.add_child(text_stack)
	var heading: Label = _make_section_heading("♙  UNLOCK REQUIREMENT")
	text_stack.add_child(heading)
	return card


func _set_guardian_accent() -> void:
	var panel_style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	panel_style.border_color = Color(0.58, 0.34, 0.82, 0.88)
	panel_style.shadow_color = Color(0.38, 0.12, 0.63, 0.22)
	_guardian_unlock_style.border_color = Color(0.72, 0.42, 0.91, 0.82)
	_progress_fill.bg_color = COLOR_PURPLE
	_subtitle_label.add_theme_color_override("font_color", COLOR_PURPLE)
	_emblem_label.add_theme_color_override("font_color", COLOR_PURPLE_BRIGHT)
	_portrait_style.border_color = Color(0.69, 0.42, 0.91, 0.92)
	_portrait_style.shadow_color = Color(0.47, 0.16, 0.75, 0.24)
	_pulse_panel_glow(Color(0.77, 0.52, 0.98, 0.96), Color(0.48, 0.27, 0.68, 0.82))


func _set_boss_accent() -> void:
	var panel_style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	panel_style.border_color = Color(0.74, 0.24, 0.39, 0.9)
	panel_style.shadow_color = Color(0.62, 0.08, 0.22, 0.3)
	_boss_unlock_style.border_color = Color(0.84, 0.25, 0.4, 0.85)
	_progress_fill.bg_color = COLOR_CRIMSON
	_portrait_style.border_color = Color(0.89, 0.3, 0.45, 0.92)
	_portrait_style.shadow_color = Color(0.62, 0.08, 0.22, 0.34)
	_pulse_panel_glow(Color(0.98, 0.38, 0.52, 0.96), Color(0.58, 0.14, 0.28, 0.84))


func _pulse_panel_glow(bright: Color, dim: Color) -> void:
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	var panel_style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	_ambient_tween = create_tween().set_loops()
	_ambient_tween.tween_property(panel_style, "border_color", bright, 1.8)
	_ambient_tween.tween_property(panel_style, "border_color", dim, 1.8)


func _on_action_pressed() -> void:
	if _action_button.disabled:
		return
	battle_requested.emit(current_guardian_id)
