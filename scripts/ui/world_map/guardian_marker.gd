class_name GuardianMarker
extends Control

## ==============================================================================
## SHADOWCRAFT 2D — GUARDIAN MAP MARKER
## ==============================================================================
## Interactive map marker for the World Map Hub.
## Displays guardian status (Available, Locked, Defeated, Final Boss),
## badge icon, name plaque, and selection/hover micro-animations.
## ==============================================================================

signal marker_selected(marker_id: StringName)

@export var guardian_id: StringName = &"the_initiate"
@export var guardian_title: String = "The Initiate"
@export var guardian_category: String = "Guardian I"
@export var is_boss: bool = false
@export var normalized_position: Vector2 = Vector2.ZERO

var is_unlocked: bool = false
var is_defeated: bool = false
var is_selected: bool = false
var _is_hovered: bool = false

# Node references
var _container: HBoxContainer
var _badge_container: Control
var _pulse_ring: Panel
var _badge_icon: TextureRect
var _info_box: PanelContainer
var _title_label: Label
var _pill_panel: PanelContainer
var _category_label: Label
var _hit_button: Button

var _pulse_tween: Tween
var _hover_tween: Tween

const COLOR_PURPLE_GLOW: Color = Color(0.78, 0.45, 1.0, 0.85)
const COLOR_LOCKED: Color = Color(0.45, 0.4, 0.52, 0.6)
const COLOR_DEFEATED: Color = Color(0.4, 0.9, 0.65, 0.85)

func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 58.0)
	mouse_filter = MOUSE_FILTER_PASS
	_build_ui()
	_apply_label_side()
	_update_visual_state()

func set_marker_data(id: StringName, title: String, category: String, boss: bool, norm_pos: Vector2) -> void:
	custom_minimum_size = Vector2(220.0, 58.0)
	guardian_id = id
	guardian_title = title
	guardian_category = category
	is_boss = boss
	normalized_position = norm_pos
	if _title_label != null:
		_title_label.text = guardian_title
	if _category_label != null:
		_category_label.text = guardian_category

	# If marker is positioned in the right half, align label on the left of badge to avoid panel crowding
	_apply_label_side()

	_update_visual_state()

func set_status(unlocked: bool, defeated: bool) -> void:
	is_unlocked = unlocked
	is_defeated = defeated
	_update_visual_state()

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual_state()

func _apply_label_side() -> void:
	if _container == null or _info_box == null:
		return
	var label_on_left: bool = normalized_position.x > 0.55
	_container.move_child(_info_box, 0 if label_on_left else 1)
	if _title_label != null:
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if label_on_left else HORIZONTAL_ALIGNMENT_LEFT
	if _category_label != null:
		_category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if label_on_left else HORIZONTAL_ALIGNMENT_LEFT

func _build_ui() -> void:
	# Main layout: badge on left, title & category pill on right
	_container = HBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_container.add_theme_constant_override("separation", 10)
	_container.mouse_filter = MOUSE_FILTER_IGNORE
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_container)

	# 1. Badge container (circle badge with pulsing ring)
	_badge_container = Control.new()
	_badge_container.custom_minimum_size = Vector2(38.0, 38.0)
	_badge_container.mouse_filter = MOUSE_FILTER_IGNORE
	_container.add_child(_badge_container)

	# Pulse ring (animated glow halo)
	_pulse_ring = Panel.new()
	_pulse_ring.custom_minimum_size = Vector2(44.0, 44.0)
	_pulse_ring.position = Vector2(-3.0, -3.0)
	_pulse_ring.mouse_filter = MOUSE_FILTER_IGNORE
	var ring_style: StyleBoxFlat = StyleBoxFlat.new()
	ring_style.bg_color = Color(0, 0, 0, 0)
	ring_style.border_color = COLOR_PURPLE_GLOW
	ring_style.set_border_width_all(2)
	ring_style.set_corner_radius_all(22)
	_pulse_ring.add_theme_stylebox_override("panel", ring_style)
	_badge_container.add_child(_pulse_ring)

	# Badge Icon
	_badge_icon = TextureRect.new()
	_badge_icon.custom_minimum_size = Vector2(38.0, 38.0)
	_badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_badge_icon.mouse_filter = MOUSE_FILTER_IGNORE
	_badge_container.add_child(_badge_icon)

	# 2. Info Box (Title + Category Pill)
	_info_box = PanelContainer.new()
	_info_box.mouse_filter = MOUSE_FILTER_IGNORE
	var plaque_style: StyleBoxFlat = StyleBoxFlat.new()
	plaque_style.bg_color = Color(0.045, 0.025, 0.075, 0.78)
	plaque_style.border_color = Color(0.62, 0.32, 0.84, 0.56)
	plaque_style.set_border_width_all(1)
	plaque_style.set_corner_radius_all(8)
	plaque_style.content_margin_left = 8.0
	plaque_style.content_margin_right = 8.0
	plaque_style.content_margin_top = 3.0
	plaque_style.content_margin_bottom = 3.0
	_info_box.add_theme_stylebox_override("panel", plaque_style)
	_container.add_child(_info_box)
	var info_content: VBoxContainer = VBoxContainer.new()
	info_content.alignment = BoxContainer.ALIGNMENT_CENTER
	info_content.add_theme_constant_override("separation", 2)
	info_content.mouse_filter = MOUSE_FILTER_IGNORE
	_info_box.add_child(info_content)

	# Title Label
	_title_label = Label.new()
	_title_label.text = guardian_title
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.05, 0.9))
	_title_label.add_theme_constant_override("shadow_offset_x", 1)
	_title_label.add_theme_constant_override("shadow_offset_y", 1)
	_title_label.mouse_filter = MOUSE_FILTER_IGNORE
	info_content.add_child(_title_label)

	# Category Pill Panel
	_pill_panel = PanelContainer.new()
	_pill_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.08, 0.05, 0.12, 0.85)
	pill_style.border_color = Color(0.5, 0.35, 0.65, 0.6)
	pill_style.set_border_width_all(1)
	pill_style.set_corner_radius_all(6)
	pill_style.content_margin_left = 6.0
	pill_style.content_margin_right = 6.0
	pill_style.content_margin_top = 1.0
	pill_style.content_margin_bottom = 1.0
	_pill_panel.add_theme_stylebox_override("panel", pill_style)
	info_content.add_child(_pill_panel)

	_category_label = Label.new()
	_category_label.text = guardian_category
	_category_label.add_theme_font_size_override("font_size", 10)
	_category_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.95))
	_category_label.mouse_filter = MOUSE_FILTER_IGNORE
	_pill_panel.add_child(_category_label)

	# Invisible interactive button over entire marker
	_hit_button = Button.new()
	_hit_button.flat = true
	_hit_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	_hit_button.add_theme_stylebox_override("normal", empty_style)
	_hit_button.add_theme_stylebox_override("hover", empty_style)
	_hit_button.add_theme_stylebox_override("pressed", empty_style)
	_hit_button.add_theme_stylebox_override("focus", empty_style)
	add_child(_hit_button)

	_hit_button.pressed.connect(_on_button_pressed)
	_hit_button.mouse_entered.connect(_on_mouse_entered)
	_hit_button.mouse_exited.connect(_on_mouse_exited)

func _update_visual_state() -> void:
	if _badge_icon == null:
		return

	# Load appropriate badge icon texture
	var icon_path: String = ""
	if not is_unlocked:
		icon_path = "res://assets/ui/world_map/icons/marker_lock_purple.svg"
	else:
		icon_path = "res://assets/ui/world_map/icons/marker_swords_purple.svg"

	if ResourceLoader.exists(icon_path):
		_badge_icon.texture = load(icon_path)

	# Accent colors
	var accent_color: Color = COLOR_PURPLE_GLOW
	if not is_unlocked:
		accent_color = COLOR_LOCKED
	elif is_defeated:
		accent_color = COLOR_DEFEATED
	if _is_hovered:
		accent_color = accent_color.lightened(0.22)

	# Ring styling
	var ring_style: StyleBoxFlat = StyleBoxFlat.new()
	ring_style.bg_color = Color(0, 0, 0, 0)
	ring_style.border_color = accent_color
	ring_style.set_border_width_all(2 if not is_selected else 3)
	ring_style.set_corner_radius_all(22)
	_pulse_ring.add_theme_stylebox_override("panel", ring_style)

	# Pill styling
	var pill_bg: Color = Color(0.08, 0.05, 0.12, 0.88)
	if is_boss:
		pill_bg = Color(0.18, 0.04, 0.07, 0.9)
	elif is_defeated:
		pill_bg = Color(0.05, 0.14, 0.09, 0.9)

	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = pill_bg
	pill_style.border_color = accent_color
	pill_style.set_border_width_all(1)
	pill_style.set_corner_radius_all(8)
	pill_style.content_margin_left = 8.0
	pill_style.content_margin_right = 8.0
	pill_style.content_margin_top = 2.0
	pill_style.content_margin_bottom = 2.0
	_pill_panel.add_theme_stylebox_override("panel", pill_style)

	# Category text
	var status_text: String = guardian_category
	if is_defeated:
		status_text = guardian_category + " • DEFEATED"
	elif not is_unlocked:
		status_text = guardian_category + " • LOCKED"
	_category_label.text = status_text

	# Pulse tween for selected or active boss
	_start_pulse_animation()

func _start_pulse_animation() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if not is_unlocked and not is_selected:
		_pulse_ring.scale = Vector2.ONE
		_pulse_ring.modulate.a = 0.5
		return

	_pulse_tween = create_tween().set_loops()
	_pulse_ring.pivot_offset = _pulse_ring.size * 0.5
	var target_scale: Vector2 = Vector2(1.15, 1.15) if is_selected else Vector2(1.08, 1.08)
	var duration: float = 0.9 if is_boss else 1.2

	_pulse_tween.tween_property(_pulse_ring, "scale", target_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_pulse_ring, "modulate:a", 1.0, duration)
	_pulse_tween.tween_property(_pulse_ring, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.parallel().tween_property(_pulse_ring, "modulate:a", 0.45, duration)

func _on_mouse_entered() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_is_hovered = true
	_update_visual_state()
	_hover_tween = create_tween()
	pivot_offset = size * 0.5
	_hover_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _on_mouse_exited() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_is_hovered = false
	_update_visual_state()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0))

func _on_button_pressed() -> void:
	marker_selected.emit(guardian_id)
