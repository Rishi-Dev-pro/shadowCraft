class_name MovementTestArenaController
extends Node2D

const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/combat/hit_spark_2d.tscn")
const StoryProgressionState = preload("res://scripts/systems/story_progression.gd")
const INITIATE_JAB: AttackData = preload("res://resources/attacks/enemy/the_initiate_jab.tres")
const INITIATE_KICK: AttackData = preload("res://resources/attacks/enemy/the_initiate_kick.tres")
const HUNTER_PORTRAIT: Texture2D = preload("res://assets/enemies/the_hunter/portraits/the_hunter_portrait.png")
const EXECUTIONER_PORTRAIT: Texture2D = preload("res://assets/ui/world_map/portraits/guardian_executioner_portrait.png")
const RAEZAN_PORTRAIT: Texture2D = preload("res://assets/ui/world_map/portraits/raezen_battle_portrait.png")
const HIT_STOP_SCALE: float = 0.08

# ==============================================================================
# SHADOWCRAFT 2D — Movement Test Arena Controller
# ==============================================================================
# Owns arena HUD bindings and optional automated showcase sequences.
# ==============================================================================

@export var is_showcase_mode: bool = false
@export var arena_background: Texture2D

@onready var player: CharacterController2D = $Fighters/Kai
@onready var dummy_target: TrainingDummy = $Fighters/DummyTarget/TrainingDummy
@onready var combat: CombatController = $Fighters/Kai/CombatController
@onready var kai_health: HealthComponent = $Fighters/Kai/HealthComponent
@onready var dummy_health: HealthComponent = $Fighters/DummyTarget/TrainingDummy/HealthComponent
@onready var hitbox: Hitbox2D = $Fighters/Kai/PlayerHitbox
@onready var kai_bar: ProgressBar = $UI/KaiHealth
@onready var dummy_bar: ProgressBar = $UI/DummyHealth
@onready var player_health_value: Label = $UI/KaiHealthValue
@onready var dummy_health_value: Label = $UI/DummyHealthValue
@onready var player_name_label: Label = $UI/KaiHealthLabel
@onready var dummy_name_label: Label = $UI/DummyHealthLabel
@onready var kai_portrait: TextureRect = $UI/KaiPortrait
@onready var razen_portrait: TextureRect = $UI/RazenPortrait
@onready var minion_portrait: TextureRect = $UI/MinionPortrait
@onready var kai_ghost_bar: ProgressBar = $UI/KaiGhostHealth
@onready var dummy_ghost_bar: ProgressBar = $UI/DummyGhostHealth
@onready var player_sub_label: Label = $UI/PlayerSubLabel
@onready var opponent_sub_label: Label = $UI/OpponentSubLabel
@onready var ui_root: Control = $UI
@onready var dojo_bg: Sprite2D = $MoonlitDojoBackground
@onready var camera_2d: Camera2D = $Camera2D
@onready var center_identity_panel: Panel = $UI/CenterIdentityPanel
@onready var control_dock: Panel = $UI/ControlDock
@onready var center_emblem: Label = $UI/CenterIdentityPanel/CenterEmblem
@onready var round_markers: Label = $UI/CenterIdentityPanel/RoundMarkers

# Keycap node references for active visual feedback
@onready var key_combo_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Combo
@onready var key_heavy_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Heavy
@onready var key_kick_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Kick
@onready var key_move_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Move
@onready var key_run_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Run
@onready var key_jump_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Jump
@onready var key_crouch_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Crouch
@onready var key_pause_panel: PanelContainer = $UI/ControlDock/DockRow/Key_Pause

var _timer: float = 0.0
var _jump_triggered: bool = false
var _hit_stop_active: bool = false
var _previous_hit_stop_scale: float = 1.0
var _combat_showcase: bool = false
var _showcase_whiff_done: bool = false
var _showcase_jab_done: bool = false
var _showcase_kick_done: bool = false
var _showcase_summary_logged: bool = false
var _round_finished: bool = false
var _round_result_pending: bool = false
var _pending_player_win: bool = false
var _pending_round_detail: String = ""
var _round_result_layer: CanvasLayer
var _round_result_overlay: Control
var _round_result_title: Label
var _round_result_detail: Label
var _active_guardian_encounter: StringName = &""

func _ready() -> void:
	call_deferred("_attach_hybrid_training")
	_build_round_result_overlay()
	if arena_background != null and dojo_bg != null:
		dojo_bg.texture = arena_background
	var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	if progression != null:
		_active_guardian_encounter = progression.active_guardian_encounter
	var is_initiate_encounter: bool = _active_guardian_encounter == StoryProgressionState.GUARDIAN_INITIATE
	var is_hunter_encounter: bool = _active_guardian_encounter == StoryProgressionState.GUARDIAN_HUNTER
	var is_executioner_encounter: bool = _active_guardian_encounter == StoryProgressionState.GUARDIAN_EXECUTIONER
	var is_raezan_encounter: bool = _active_guardian_encounter == StoryProgressionState.BOSS_RAEZEN
	var is_story_encounter: bool = is_initiate_encounter or is_hunter_encounter or is_executioner_encounter or is_raezan_encounter
	if is_story_encounter:
		await get_tree().process_frame
		dummy_target = get_node_or_null("Fighters/DummyTarget/TrainingDummy") as TrainingDummy
		dummy_health = get_node_or_null("Fighters/DummyTarget/TrainingDummy/HealthComponent") as HealthComponent
	if dummy_target != null:
		dummy_target.ai_enabled = is_story_encounter
		if is_initiate_encounter:
			dummy_target.approach_speed = 102.0
			dummy_target.attack_range = 158.0
			dummy_target.guard_damage_reduction = 0.35
			dummy_target.configure_attacks(INITIATE_JAB, INITIATE_KICK)
			dummy_name_label.text = "THE INITIATE"
			opponent_sub_label.text = "GUARDIAN I  •  VALLEY OF WHISPERS"
		elif is_hunter_encounter:
			dummy_target.approach_speed = 88.0
			dummy_target.attack_range = 190.0
			dummy_target.guard_damage_reduction = 0.32
			dummy_name_label.text = "THE HUNTER"
			opponent_sub_label.text = "GUARDIAN II  •  MIST WATERFALLS"
			minion_portrait.texture = HUNTER_PORTRAIT
			minion_portrait.visible = true
		elif is_executioner_encounter:
			dummy_target.approach_speed = 92.0
			dummy_target.attack_range = 246.0
			dummy_target.guard_damage_reduction = 0.5
			dummy_name_label.text = "THE EXECUTIONER"
			opponent_sub_label.text = "GUARDIAN III  •  CRIMSON BLADE CLIFFS"
			minion_portrait.texture = EXECUTIONER_PORTRAIT
			minion_portrait.visible = true
		elif is_raezan_encounter:
			dummy_target.approach_speed = 100.0
			dummy_target.attack_range = 260.0
			dummy_target.guard_damage_reduction = 0.52
			dummy_name_label.text = "RAEZAN"
			opponent_sub_label.text = "THE BETRAYER KING  •  FINAL BOSS"
			minion_portrait.texture = RAEZAN_PORTRAIT
			minion_portrait.visible = true
	if OS.get_cmdline_user_args().has("--showcase"):
		is_showcase_mode = true
	if player != null and dummy_target != null:
		player.target_opponent = dummy_target
		player.collision_mask |= 1 << 2
		if player.character_data != null and player_name_label != null:
			player_name_label.text = player.character_data.display_name.to_upper()
			player_name_label.add_theme_color_override("font_color", player.character_data.signature_color.lightened(0.2))
			var is_razen: bool = player.character_data.display_name.to_lower().contains("razen")
			kai_portrait.visible = not is_razen
			razen_portrait.visible = is_razen
			if player_sub_label != null:
				player_sub_label.text = "THE CRIMSON ASH" if is_razen else "THE SHADOW DISCIPLE"
	_animate_hud_entrance()
	if kai_health != null:
		kai_health.health_changed.connect(_update_kai_health)
		_update_kai_health(kai_health.current_health, kai_health.max_health)
	if dummy_health != null:
		dummy_health.health_changed.connect(_update_dummy_health)
		_update_dummy_health(dummy_health.current_health, dummy_health.max_health)
		if not dummy_health.defeated.is_connected(_on_bot_defeated):
			dummy_health.defeated.connect(_on_bot_defeated)
	if dummy_target != null and not dummy_target.defeat_animation_finished.is_connected(_on_bot_fall_finished):
		dummy_target.defeat_animation_finished.connect(_on_bot_fall_finished)
	if dummy_target != null and not dummy_target.enemy_hitbox.target_hit.is_connected(_on_opponent_hit_landed):
		dummy_target.enemy_hitbox.target_hit.connect(_on_opponent_hit_landed)
	if dummy_target is TheExecutioner and not (dummy_target as TheExecutioner).parry_succeeded.is_connected(_on_executioner_parry):
		(dummy_target as TheExecutioner).parry_succeeded.connect(_on_executioner_parry)
	if kai_health != null and not kai_health.defeated.is_connected(_on_player_defeated):
		kai_health.defeated.connect(_on_player_defeated)
	if combat != null and not combat.defeat_pose_reached.is_connected(_on_player_fall_finished):
		combat.defeat_pose_reached.connect(_on_player_fall_finished)
	combat.hit_landed.connect(_on_hit_landed)
	hitbox.debug_draw = OS.get_cmdline_user_args().has("--combat-debug")
	dummy_target.enemy_hitbox.debug_draw = hitbox.debug_draw
	if hitbox.debug_draw:
		hitbox.queue_redraw()
		dummy_target.enemy_hitbox.queue_redraw()
	_combat_showcase = OS.get_cmdline_user_args().has("--integration-showcase")
	if _combat_showcase:
		player.use_simulated_input = true
	if not get_viewport().size_changed.is_connected(_update_viewport_layout):
		get_viewport().size_changed.connect(_update_viewport_layout)
	_update_viewport_layout()

func _update_viewport_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	# Cover-fit background (aspect ratio preserved, no distortion, fills viewport)
	if dojo_bg != null and dojo_bg.texture != null:
		var tex_size: Vector2 = dojo_bg.texture.get_size()
		var scale_factor: float = maxf(vp_size.x / tex_size.x, vp_size.y / tex_size.y)
		dojo_bg.scale = Vector2(scale_factor, scale_factor)
		dojo_bg.position = Vector2(640.0, 360.0)

	# Camera stays centered on the combat arena midpoint
	if camera_2d != null:
		camera_2d.position = Vector2(640.0, 360.0)

	# UI root matches full viewport bounds
	if ui_root != null:
		ui_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
		ui_root.position = Vector2(640.0 - vp_size.x * 0.5, 360.0 - vp_size.y * 0.5)
		ui_root.size = vp_size

func _build_round_result_overlay() -> void:
	_round_result_layer = CanvasLayer.new()
	_round_result_layer.name = "RoundResultLayer"
	_round_result_layer.layer = 20
	_round_result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_round_result_layer)
	_round_result_overlay = Control.new()
	_round_result_overlay.name = "RoundResultOverlay"
	_round_result_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_round_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_round_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_round_result_overlay.visible = false
	_round_result_layer.add_child(_round_result_overlay)
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.015, 0.008, 0.025, 0.7)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_round_result_overlay.add_child(veil)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_round_result_overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 300.0)
	panel.add_theme_stylebox_override("panel", _round_panel_style())
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	_round_result_title = Label.new()
	_round_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_result_title.add_theme_font_size_override("font_size", 52)
	column.add_child(_round_result_title)
	_round_result_detail = Label.new()
	_round_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_result_detail.add_theme_font_size_override("font_size", 18)
	column.add_child(_round_result_detail)
	var retry_button: Button = _round_result_button("REMATCH")
	retry_button.pressed.connect(_restart_round)
	column.add_child(retry_button)
	var world_map_button: Button = _round_result_button("WORLD MAP")
	world_map_button.pressed.connect(_return_to_world_map)
	column.add_child(world_map_button)

func _round_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.025, 0.055, 0.98)
	style.border_color = Color(0.55, 0.32, 0.72, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	style.content_margin_top = 26.0
	style.content_margin_bottom = 26.0
	return style

func _round_result_button(button_text: String) -> Button:
	var button: Button = Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(340.0, 46.0)
	button.add_theme_font_size_override("font_size", 17)
	return button

func _on_bot_defeated() -> void:
	if _active_guardian_encounter in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER, StoryProgressionState.BOSS_RAEZEN]:
		var guardian_name: String = _guardian_display_name()
		_queue_round_result(true, "%s HAS FALLEN" % guardian_name)
		return
	var winner_name: String = player.character_data.display_name if player.character_data != null else "PLAYER"
	_queue_round_result(true, "%s WINS THE ROUND" % winner_name.to_upper())

func _on_player_defeated() -> void:
	if _active_guardian_encounter in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER, StoryProgressionState.BOSS_RAEZEN]:
		var guardian_name: String = _guardian_display_name()
		_queue_round_result(false, "%s WINS THE ROUND" % guardian_name)
		return
	_queue_round_result(false, "THE TRAINING MINION WINS THE ROUND")

func _queue_round_result(player_won: bool, detail: String) -> void:
	if _round_finished or _round_result_pending:
		return
	_round_result_pending = true
	_pending_player_win = player_won
	_pending_round_detail = detail

func _on_bot_fall_finished() -> void:
	if _round_result_pending and _pending_player_win:
		if _active_guardian_encounter in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER, StoryProgressionState.BOSS_RAEZEN]:
			var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
			if progression != null:
				progression.record_guardian_victory(_active_guardian_encounter)
		_show_round_result(true, _pending_round_detail)

func _on_player_fall_finished() -> void:
	if _round_result_pending and not _pending_player_win:
		_show_round_result(false, _pending_round_detail)

func _show_round_result(player_won: bool, detail: String) -> void:
	if _round_finished:
		return
	_round_finished = true
	if get_tree().current_scene != null:
		get_tree().current_scene.set_meta(&"round_finished", true)
	_round_result_title.text = "K.O." if player_won else "DEFEAT"
	_round_result_title.add_theme_color_override("font_color", Color(0.78, 0.48, 1.0) if player_won else Color(1.0, 0.35, 0.32))
	_round_result_detail.text = detail
	_round_result_detail.add_theme_color_override("font_color", Color(0.88, 0.84, 0.94))
	_round_result_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _restart_round() -> void:
	get_tree().paused = false
	var error: Error = get_tree().reload_current_scene()
	if error != OK:
		push_error("Could not restart the round: %s" % error_string(error))

func _return_to_world_map() -> void:
	get_tree().paused = false
	var progression: StoryProgressionState = get_node_or_null("/root/StoryProgression") as StoryProgressionState
	if progression != null:
		progression.end_guardian_encounter()
	var error: Error = get_tree().change_scene_to_file("res://scenes/ui/world_map.tscn")
	if error != OK:
		push_error("Could not return to the World Map: %s" % error_string(error))

func _physics_process(delta: float) -> void:
	if (is_showcase_mode or _combat_showcase) and player != null:
		_process_showcase(delta)

func _process_showcase(delta: float) -> void:
	if _combat_showcase:
		_process_combat_showcase(delta)
		return
	_timer += delta
	if _timer < 1.0:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 2.0:
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 3.0:
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(false)
		player.simulate_run(true)
	elif _timer < 4.0:
		player.simulate_horizontal_input(-1.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 5.0:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(true)
		player.simulate_run(false)
	elif _timer < 6.0:
		player.simulate_horizontal_input(1.0)
		player.simulate_crouch(true)
		player.simulate_run(false)
	elif _timer < 6.1:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	elif _timer < 6.2:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
		if not _jump_triggered:
			player.simulate_jump()
			_jump_triggered = true
	elif _timer < 7.1:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
	else:
		player.reset_simulated_input()

func _process_combat_showcase(delta: float) -> void:
	_timer += delta
	if _timer < 0.65:
		player.simulate_horizontal_input(1.0)
		player.simulate_run(true)
	elif _timer < 0.95:
		player.simulate_horizontal_input(-1.0)
		player.simulate_run(false)
	elif _timer < 1.05:
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.12:
		dummy_target.global_position.x = 1200.0
		player.simulate_horizontal_input(0.0)
		if not _showcase_whiff_done and combat.start_attack(combat.get_light_attack()):
			_showcase_whiff_done = true
			print("[IntegrationShowcase] Jab whiff at Kai %s, target %s" % [player.global_position, dummy_target.global_position])
	elif _timer < 1.45:
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.50:
		dummy_target.global_position.x = 960.0
		player.simulate_horizontal_input(0.0)
	elif _timer < 1.62:
		player.simulate_crouch(true)
	elif _timer < 1.82:
		player.simulate_crouch(false)
	elif _timer < 2.20:
		player.simulate_horizontal_input(0.0)
	elif _timer < 2.36:
		player.simulate_horizontal_input(0.0)
		if not _showcase_jab_done and combat.start_attack(combat.get_light_attack()):
			_showcase_jab_done = true
			print("[IntegrationShowcase] Jab at Kai %s, target %s, floor=%s" % [player.global_position, dummy_target.global_position, player.is_on_floor()])
	elif _timer < 2.63:
		pass
	elif _timer < 2.78:
		if not _showcase_kick_done and combat.start_attack(combat.get_kick_attack()):
			_showcase_kick_done = true
			print("[IntegrationShowcase] Kick at Kai %s, target %s, floor=%s" % [player.global_position, dummy_target.global_position, player.is_on_floor()])
	elif _timer < 2.98:
		pass
	elif _timer < 3.06:
		player.simulate_horizontal_input(0.0)
		if not _jump_triggered:
			player.simulate_jump()
			_jump_triggered = true
	elif _timer < 3.2:
		player.simulate_horizontal_input(0.0)
	else:
		player.simulate_horizontal_input(0.0)
		player.simulate_crouch(false)
		player.simulate_run(false)
		if _timer > 3.2:
			player.reset_simulated_input()
		if not _showcase_summary_logged:
			_showcase_summary_logged = true
			print("[IntegrationShowcase] End. Dummy health %.1f / %.1f; Kai pos=%s" % [dummy_health.current_health, dummy_health.max_health, player.global_position])

var _hud_pulse_timer: float = 0.0

func _process(delta: float) -> void:
	_update_dock_keycaps()
	_update_hud_pulse(delta)

func _update_kai_health(current: float, maximum: float) -> void:
	kai_bar.max_value = maximum
	kai_bar.value = current
	player_health_value.text = "%d / %d" % [roundi(current), roundi(maximum)]
	if kai_ghost_bar != null:
		kai_ghost_bar.max_value = maximum
		if current < kai_ghost_bar.value:
			_flash_node(kai_bar, Color(1.5, 1.3, 1.8, 1.0))
			var tween: Tween = create_tween()
			tween.tween_interval(0.22)
			tween.tween_property(kai_ghost_bar, "value", current, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			kai_ghost_bar.value = current

func _update_dummy_health(current: float, maximum: float) -> void:
	dummy_bar.max_value = maximum
	dummy_bar.value = current
	dummy_health_value.text = "%d / %d" % [roundi(current), roundi(maximum)]
	if dummy_ghost_bar != null:
		dummy_ghost_bar.max_value = maximum
		if current < dummy_ghost_bar.value:
			_flash_node(dummy_bar, Color(1.8, 1.2, 1.3, 1.0))
			var tween: Tween = create_tween()
			tween.tween_interval(0.22)
			tween.tween_property(dummy_ghost_bar, "value", current, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			dummy_ghost_bar.value = current

func _flash_node(target: CanvasItem, flash_color: Color) -> void:
	if target == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate", flash_color, 0.06)
	tween.tween_property(target, "modulate", Color.WHITE, 0.16)

func _animate_hud_entrance() -> void:
	if ui_root == null:
		return
	ui_root.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(ui_root, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_dock_keycaps() -> void:
	if control_dock == null:
		return
	var is_combo: bool = Input.is_action_pressed("light_attack")
	var is_heavy: bool = Input.is_action_pressed("heavy_attack")
	var is_kick: bool = Input.is_action_pressed("kick_attack")
	var is_move: bool = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")
	var is_run: bool = Input.is_action_pressed("run")
	var is_jump: bool = Input.is_action_pressed("jump")
	var is_crouch: bool = Input.is_action_pressed("crouch")
	var is_pause: bool = Input.is_action_pressed("ui_cancel")

	_set_keycap_active(key_combo_panel, is_combo, Color(0.85, 0.55, 1.0))
	_set_keycap_active(key_heavy_panel, is_heavy, Color(1.0, 0.5, 0.7))
	_set_keycap_active(key_kick_panel, is_kick, Color(0.7, 0.6, 1.0))
	_set_keycap_active(key_move_panel, is_move, Color(0.75, 0.75, 1.0))
	_set_keycap_active(key_run_panel, is_run, Color(0.9, 0.65, 1.0))
	_set_keycap_active(key_jump_panel, is_jump, Color(0.8, 0.7, 1.0))
	_set_keycap_active(key_crouch_panel, is_crouch, Color(0.8, 0.7, 1.0))
	_set_keycap_active(key_pause_panel, is_pause, Color(1.0, 0.4, 0.4))

func _set_keycap_active(panel: PanelContainer, active: bool, active_modulate: Color) -> void:
	if panel == null:
		return
	panel.modulate = active_modulate if active else Color.WHITE

func _update_hud_pulse(delta: float) -> void:
	_hud_pulse_timer += delta
	var pulse: float = 0.94 + 0.06 * sin(_hud_pulse_timer * 2.2)
	if center_emblem != null:
		center_emblem.modulate.a = pulse
	if round_markers != null:
		round_markers.modulate.a = pulse

func _on_hit_landed(attack: AttackData, _target: Hurtbox2D, damage: float) -> void:
	if _combat_showcase:
		print("[IntegrationShowcase] Confirmed %s hit for %.1f damage" % [attack.display_name, damage])
	_play_confirmed_hit_feedback(attack, hitbox.global_position)

func _on_opponent_hit_landed(_target: Hurtbox2D, _damage: float) -> void:
	if _active_guardian_encounter not in [StoryProgressionState.GUARDIAN_INITIATE, StoryProgressionState.GUARDIAN_HUNTER, StoryProgressionState.GUARDIAN_EXECUTIONER, StoryProgressionState.BOSS_RAEZEN]:
		return
	if dummy_target == null or dummy_target.enemy_hitbox == null or dummy_target.enemy_hitbox.attack_data == null:
		return
	_play_confirmed_hit_feedback(dummy_target.enemy_hitbox.attack_data, dummy_target.enemy_hitbox.global_position)

func _guardian_display_name() -> String:
	match _active_guardian_encounter:
		StoryProgressionState.GUARDIAN_INITIATE:
			return "THE INITIATE"
		StoryProgressionState.GUARDIAN_HUNTER:
			return "THE HUNTER"
		StoryProgressionState.GUARDIAN_EXECUTIONER:
			return "THE EXECUTIONER"
		StoryProgressionState.BOSS_RAEZEN:
			return "RAEZAN"
	return "THE GUARDIAN"

func _on_executioner_parry(_attacker: Node2D, contact_position: Vector2) -> void:
	var spark: HitSpark2D = HIT_SPARK_SCENE.instantiate() as HitSpark2D
	if spark == null:
		return
	add_child(spark)
	spark.global_position = contact_position
	spark.play(AttackData.AttackKind.PUNCH, 0.78)

func _play_confirmed_hit_feedback(attack: AttackData, effect_position: Vector2) -> void:
	await _apply_hit_stop(attack)
	var spark: HitSpark2D = HIT_SPARK_SCENE.instantiate() as HitSpark2D
	if spark == null:
		return
	add_child(spark)
	spark.global_position = effect_position
	spark.play(attack.kind, attack.get_impact_scale())

func _apply_hit_stop(attack: AttackData) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	_previous_hit_stop_scale = Engine.time_scale
	Engine.time_scale = minf(_previous_hit_stop_scale, HIT_STOP_SCALE)
	var duration: float = attack.get_hit_stop_seconds()
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = _previous_hit_stop_scale
	_hit_stop_active = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _hit_stop_active:
		Engine.time_scale = _previous_hit_stop_scale
		_hit_stop_active = false

func _attach_hybrid_training() -> void:
	if scene_file_path != "res://scenes/arenas/MovementTestArena.tscn":
		return
	var progression: Node = get_node_or_null("/root/StoryProgression")
	if progression != null and progression.get("active_guardian_encounter") != &"":
		return
	var integration: GDScript = load("res://experimental/kai_hybrid/training/hybrid_training.gd")
	integration.attach(self)
