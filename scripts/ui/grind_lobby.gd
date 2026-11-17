class_name GrindLobby
extends Control

signal world_map_requested()

const MissionPanel = preload("res://scripts/ui/grind_mission_panel.gd")
const ShadowButton = preload("res://scripts/ui/shadowcraft_button.gd")
const Petals = preload("res://scripts/ui/grind_petals.gd")
const Dialogue = preload("res://scripts/ui/grind_dialog.gd")
const DISPLAY: Font = preload("res://assets/ui/grind/fonts/shippori_mincho_bold_latin.ttf")
const MIST: Shader = preload("res://assets/ui/grind/lobby_mist.gdshader")
const ENTRANCE: StringName = &"grind_entrance"
const BACKDROP_ART: Texture2D = preload("res://assets/ui/grind/training_division.webp")
const TRIAL_ART: Texture2D = preload("res://assets/ui/grind/combat_trials.webp")
const PRACTICE_ART: Texture2D = preload("res://assets/ui/grind/practice_grounds.webp")
const FORGE_ART: Texture2D = preload("res://assets/ui/grind/weapon_forge.webp")
const MATERIAL_NAMES: PackedStringArray = ["Wood", "Stick", "Stone"]
const MATERIAL_ICONS: Array[Texture2D] = [
	preload("res://assets/ui/grind/wood.png"),
	preload("res://assets/ui/grind/stick.png"),
	preload("res://assets/ui/grind/stone.png"),
]
const TEXT: Color = Color("#f4eafa")
const MUTED: Color = Color("#c9bbd3")
const VIOLET: Color = Color("#cfb1f6")
const LOCKED: Color = Color("#f5c195")
const LOCK_MESSAGE: String = "Awaiting Sensei's instruction."
const WORLD_MAP_PATH: String = "res://scenes/ui/world_map.tscn"
const RECIPE: String = "Wooden Sword  ·  2 Wood + 1 Stick"
const TRIAL_FORMAT: String = "3 opponents  ·  Consecutive battles\nHealth is shared across all rounds."
const TRIAL_REWARD: String = "Trial reward  ·  2 Wood + 1 Stick"
const GUIDANCE: Dictionary[StringName, String] = {
	&"initial": "Strength is not earned in a single battle, Shadow. Train your body, gather what you need, and prepare for the path ahead.",
}

@export var inventory: GrindInventory

@onready var _header: HBoxContainer = %Header
@onready var _destinations: Control = %Destinations
@onready var _guidance: HBoxContainer = %Guidance
@onready var _dialog: Dialogue = %Veil
@onready var _entrance: AnimationPlayer = %Entrance
@onready var _front_petals: Petals = %FrontPetals
@onready var _rear_petals: Petals = %RearPetals

var _tracking: FontVariation = FontVariation.new()
var _mist: ShaderMaterial = ShaderMaterial.new()
var _sequence: Animation = Animation.new()
var _missions: Array[MissionPanel] = []
var _inventory_button: ShadowButton
var _materials: HBoxContainer
var _counts: Array[Label] = []
var _atmosphere_time: float
var _atmosphere_step: float


func _ready() -> void:
	assert(inventory != null, "Grind lobby requires an inventory resource")
	_tracking.base_font = ShadowButton.FACE
	_tracking.spacing_glyph = 1
	%BackdropArt.texture = BACKDROP_ART
	_mist.shader = MIST
	%Mist.material = _mist
	_build_header()
	_build_destinations()
	_build_guidance()
	_build_entrance()
	visibility_changed.connect(_on_visibility_changed)
	get_window().focus_entered.connect(_update_atmosphere)
	get_window().focus_exited.connect(_update_atmosphere)
	refresh_inventory()
	_on_visibility_changed()


func refresh_inventory() -> void:
	var quantities: Array[int] = inventory.quantities()
	for index: int in range(quantities.size()):
		_counts[index].text = str(quantities[index])
	_inventory_button.custom_minimum_size.x = _materials.get_combined_minimum_size().x + 24


func show_forge_requirement() -> void:
	_dialog.present("Weapon Forge", "%s\n\nUnlocks when Sensei gives the instruction through the story.\n\n%s" % [LOCK_MESSAGE, RECIPE])


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _dialog.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_dialog.dismiss()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		_request_world_map()
		get_viewport().set_input_as_handled()


func _on_visibility_changed() -> void:
	_update_atmosphere()
	if is_visible_in_tree():
		_entrance.play(ENTRANCE)
		_entrance.advance(0.0)
	else:
		_entrance.stop()
		_dialog.dismiss(true)


func _update_atmosphere() -> void:
	var run: bool = is_visible_in_tree() and get_window().has_focus()
	set_process(run)
	_front_petals.set_running(run)
	_rear_petals.set_running(run)


func _process(delta: float) -> void:
	_atmosphere_time += delta
	_atmosphere_step += delta
	if _atmosphere_step < 1.0 / 24.0:
		return
	_atmosphere_step = fmod(_atmosphere_step, 1.0 / 24.0)
	_mist.set_shader_parameter("atmosphere", _atmosphere_time)
	for mission: MissionPanel in _missions:
		mission.set_atmosphere_time(_atmosphere_time)


func _build_header() -> void:
	var nav_space: Control = Control.new()
	nav_space.custom_minimum_size.x = 220
	_header.add_child(nav_space)
	var title: Label = _label("GRIND", 28, TEXT, true)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	_header.add_child(title)
	_build_inventory()
	var back: ShadowButton = _button("BACK TO WORLD MAP", ShadowButton.Finish.STEEL, null, true)
	back.size_flags_vertical = SIZE_SHRINK_CENTER
	back.pressed.connect(_request_world_map)
	_header.add_child(back)


func _request_world_map() -> void:
	if get_tree().current_scene == self:
		var error: Error = get_tree().change_scene_to_file(WORLD_MAP_PATH)
		if error != OK:
			push_error("Could not return to the World Map: %s" % error_string(error))
		return
	world_map_requested.emit()


func _build_inventory() -> void:
	_inventory_button = _button("", ShadowButton.Finish.STEEL)
	_inventory_button.tooltip_text = "Open materials inventory"
	_inventory_button.accessibility_name = "View materials inventory"
	_inventory_button.size_flags_vertical = SIZE_SHRINK_CENTER
	_inventory_button.pressed.connect(_show_inventory)
	_header.add_child(_inventory_button)

	_materials = HBoxContainer.new()
	_materials.mouse_filter = MOUSE_FILTER_IGNORE
	_materials.alignment = BoxContainer.ALIGNMENT_CENTER
	_materials.add_theme_constant_override("separation", 15)
	_inventory_button.add_child(_materials)
	_place(_materials, Vector4(0, 0, 1, 1), Vector4(10, 0, -10, 0))
	for index: int in range(MATERIAL_NAMES.size()):
		var material: HBoxContainer = HBoxContainer.new()
		material.mouse_filter = MOUSE_FILTER_IGNORE
		material.add_theme_constant_override("separation", 4)
		_materials.add_child(material)
		var icon: TextureRect = _icon(MATERIAL_ICONS[index], 19)
		material.add_child(icon)
		material.add_child(_label(MATERIAL_NAMES[index], 12, MUTED))
		var count: Label = _label("", 14, TEXT)
		count.custom_minimum_size.x = 14
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		material.add_child(count)
		_counts.append(count)


func _build_destinations() -> void:
	var gauntlet: MissionPanel = _mission(
		MissionPanel.Destination.GAUNTLET, TRIAL_ART, Color("#9768a7"),
		"The Gauntlet – Enter Combat Trial", Vector4(0, 0, 0.681, 0.697), _show_trial
	)
	var trial: VBoxContainer = _mission_copy(gauntlet, Vector4(0, 0.46, 0.79, 1), Vector4(42, 0, 0, -22))
	trial.add_child(_category("COMBAT TRIALS  /  AVAILABLE", Color("#e7b0d9")))
	trial.add_child(_label("THE GAUNTLET", 49, TEXT, true))
	trial.add_child(_label(TRIAL_FORMAT, 16, MUTED))
	trial.add_child(_category("TRIAL REWARD   2 WOOD + 1 STICK", VIOLET))
	trial.add_child(_button("ENTER TRIAL", ShadowButton.Finish.VIOLET, gauntlet))
	_score_mission(gauntlet, trial, 0.04, 0.62, 0.35)

	var dojo: MissionPanel = _mission(
		MissionPanel.Destination.DOJO, PRACTICE_ART, Color("#7e8ba8"),
		"The Dojo – Enter Practice Grounds", Vector4(0.69, 0.005, 1, 1), _show_practice
	)
	var practice: VBoxContainer = _mission_copy(dojo, Vector4(0, 0.56, 1, 1), Vector4(48, 0, -48, -38))
	practice.add_child(_category("PRACTICE GROUNDS  /  AVAILABLE", Color("#bdcce7")))
	practice.add_child(_label("THE DOJO", 40, TEXT, true))
	practice.add_child(_wrapped("Practice movement, attacks, combos and defense.", 16))
	practice.add_child(_button("ENTER PRACTICE", ShadowButton.Finish.STEEL, dojo))
	_score_mission(dojo, practice, 0.12, 0.79, 0.48)

	var forge: MissionPanel = _mission(
		MissionPanel.Destination.FORGE, FORGE_ART, Color("#aa7657"),
		"The Forge – View unlock requirement", Vector4(0.013, 0.72, 0.673, 1), show_forge_requirement
	)
	var smithy: VBoxContainer = _mission_copy(forge, Vector4(0, 0, 0.56, 1), Vector4(42, 11, 0, -13))
	smithy.alignment = BoxContainer.ALIGNMENT_CENTER
	smithy.add_theme_constant_override("separation", 3)
	smithy.add_child(_category("WEAPON FORGE  /  SEALED", LOCKED))
	smithy.add_child(_label("THE FORGE", 35, TEXT, true))
	smithy.add_child(_label(RECIPE, 16, Color("#efd3bf")))
	smithy.add_child(_label(LOCK_MESSAGE, 15, LOCKED))
	var requirement: ShadowButton = _button("VIEW REQUIREMENT", ShadowButton.Finish.SEALED, forge)
	forge.add_child(requirement)
	_place(requirement, Vector4(1, 1, 1, 1), Vector4(-242, -57, -42, -22))
	_score_mission(forge, smithy, 0.21, 0.88, 0.51)
	_fade_copy(requirement, 0.53)


func _mission(
	kind: MissionPanel.Destination, art: Texture2D, rim: Color, caption: String,
	bounds: Vector4, action: Callable
) -> MissionPanel:
	var mission: MissionPanel = MissionPanel.new()
	mission.configure(kind, art, rim, caption)
	_destinations.add_child(mission)
	_place(mission, bounds, Vector4.ZERO)
	mission.pressed.connect(action)
	_missions.append(mission)
	return mission


func _mission_copy(panel: Button, bounds: Vector4, offsets: Vector4) -> VBoxContainer:
	var copy: VBoxContainer = VBoxContainer.new()
	copy.mouse_filter = MOUSE_FILTER_IGNORE
	copy.alignment = BoxContainer.ALIGNMENT_END
	copy.add_theme_constant_override("separation", 4)
	panel.add_child(copy)
	_place(copy, bounds, offsets)
	copy.grow_vertical = GROW_DIRECTION_BEGIN
	return copy


func _category(caption: String, tone: Color) -> Label:
	var label: Label = _label(caption, 12, tone)
	label.add_theme_font_override("font", _tracking)
	return label


func _button(
	caption: String, finish: ShadowButton.Finish, source: BaseButton = null,
	reverse: bool = false
) -> ShadowButton:
	var button: ShadowButton = ShadowButton.new()
	button.configure(caption, finish, source, reverse)
	button.size_flags_horizontal = SIZE_SHRINK_BEGIN
	return button


func _build_guidance() -> void:
	var button: ShadowButton = _button("SENSEI’S GUIDANCE", ShadowButton.Finish.MENTOR)
	button.pressed.connect(_show_guidance)
	_guidance.add_child(button)


func _score_mission(panel: MissionPanel, copy: Control, start: float, end: float, caption_at: float) -> void:
	_animate(panel, "entrance", 0.0, 1.0, start, end)
	_fade_copy(copy, caption_at)


func _fade_copy(copy: Control, start: float) -> void:
	_animate(copy, "modulate:a", 0.0, 1.0, start, start + 0.28)


func _animate(node: Node, property: String, from: float, to: float, start: float, end: float) -> void:
	var track: int = _sequence.add_track(Animation.TYPE_VALUE)
	_sequence.track_set_path(track, NodePath(String(get_path_to(node)) + ":" + property))
	_sequence.track_insert_key(track, 0.0, from)
	_sequence.track_insert_key(track, start, from, 0.44)
	_sequence.track_insert_key(track, end, to)


func _build_entrance() -> void:
	_sequence.length = 0.90
	var clips: AnimationLibrary = AnimationLibrary.new()
	clips.add_animation(ENTRANCE, _sequence)
	_entrance.add_animation_library(&"", clips)


func _place(control: Control, bounds: Vector4, offsets: Vector4) -> void:
	# Set the far edges first so Godot doesn't clamp the near anchors to zero.
	control.set_anchor_and_offset(SIDE_RIGHT, bounds.z, offsets.z)
	control.set_anchor_and_offset(SIDE_BOTTOM, bounds.w, offsets.w)
	control.set_anchor_and_offset(SIDE_LEFT, bounds.x, offsets.x)
	control.set_anchor_and_offset(SIDE_TOP, bounds.y, offsets.y)


func _show_inventory() -> void:
	var amounts: Array[int] = inventory.quantities()
	_dialog.present("Materials Inventory", "Wood    %d\nStick      %d\nStone   %d" % amounts)


func _show_trial() -> void:
	_dialog.present("Combat Trial Preparation", "%s\n%s\n\nComing in the next milestone." % [TRIAL_FORMAT, TRIAL_REWARD])


func _show_practice() -> void:
	_dialog.present("Practice Grounds", "A place to practice movement, attacks, combos and defense without entering a resource trial.\n\nComing in the next milestone.")


func _show_guidance() -> void:
	_dialog.present("Sensei's Guidance", "“%s”" % GUIDANCE[&"initial"], true)


func _label(value: String, font_size: int, tone: Color, heading: bool = false) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.text = value
	_style_label(label, font_size, tone)
	if heading:
		label.add_theme_font_override("font", DISPLAY)
	else:
		label.add_theme_font_override("font", ShadowButton.FACE)
	return label


func _style_label(label: Label, font_size: int, tone: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tone)


func _wrapped(value: String, font_size: int, tone: Color = MUTED) -> Label:
	var label: Label = _label(value, font_size, tone)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _icon(texture: Texture2D, extent: float) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	return icon
