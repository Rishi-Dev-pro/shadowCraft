extends Node2D
## Opt-in actor adapter for the existing Training Dojo instance.

const BASE_ARENA: String = "res://scenes/arenas/MovementTestArena.tscn"
const SURFACE = preload("res://experimental/kai_hybrid/training/training_surface.tscn")
const Motion = preload("res://experimental/kai_hybrid/training/training_motion.gd")
const Target = preload("res://experimental/kai_hybrid/training/training_target.gd")
const Attack = preload("res://experimental/kai_hybrid/attack_motion.gd")
const Dash = preload("res://experimental/kai_hybrid/dash_motion.gd")
const SPARK = preload("res://scenes/combat/hit_spark_2d.tscn")

# Fist / sole volumes registered to the approved 0.7-scale contact drawings.
const CONTACT_CENTER: Array[Vector2] = [Vector2(111, -256), Vector2(112, -255), Vector2(87, -237)]
const CONTACT_SIZE: Array[Vector2] = [Vector2(48, 36), Vector2(54, 40), Vector2(42, 47)]

var fighter: CharacterController2D
var target: Target
var motion: Motion
var display: Sprite2D
var _spawn: Vector2
var _floor_y: float
var _guard_input: bool = false
var _contact_shape: RectangleShape2D = RectangleShape2D.new()
var _hurtbox: Area2D
var _notice: Label
var _hint: Label
var _dummy_bar: ProgressBar
var _dummy_ghost: ProgressBar
var _dummy_value: Label
var _effect: HitSpark2D


static func attach(arena: Node2D) -> void:
	var selection: Node = arena.get_node_or_null("/root/CharacterSelection")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if arena.scene_file_path != BASE_ARENA or arena.get_tree().current_scene != arena:
		return
	if selection == null or selection.get_selected_character() != &"kai":
		return
	if args.has("--legacy-training") or args.has("--showcase") or args.has("--integration-showcase") or arena.get("is_showcase_mode"):
		return
	var player: CharacterController2D = arena.get_node_or_null("Fighters/Kai") as CharacterController2D
	var dummy: TrainingDummy = arena.get_node_or_null("Fighters/DummyTarget/TrainingDummy") as TrainingDummy
	if player == null or dummy == null or dummy.get("ai_enabled") == true:
		return
	var sprite: AnimatedSprite2D = dummy.get_node_or_null("Silhouette/MinionSprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"hit"):
		return
	var adapter = new()
	adapter.name = "HybridTraining"
	adapter.fighter = player
	adapter.target = Target.new(dummy, sprite)
	arena.add_child(adapter)


func _ready() -> void:
	_spawn = fighter.global_position
	_floor_y = _spawn.y
	_hurtbox = target.dummy.get_node("Hurtbox")
	# Leave the existing player slot and collision shape available to the
	# shared arena, while the Hybrid controller owns movement and presentation.
	fighter.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	fighter.process_mode = Node.PROCESS_MODE_DISABLED
	fighter.hide()
	fighter.velocity = Vector2.ZERO
	var surface: Node2D = SURFACE.instantiate()
	add_child(surface)
	var stage: SubViewport = surface.get_node("Stage")
	stage.canvas_transform = Transform2D(0.0, Vector2(0.0, 160.0))
	motion = surface.get_node("Motion")
	motion.fighter = fighter
	motion.confirm_attack = _confirm_attack
	display = surface.get_node("Display")
	_face_target()
	_project_pose()
	motion.request_idle()
	_connect_hud()
	_update_feedback()


func _physics_process(delta: float) -> void:
	_face_target()
	_drive_input()
	motion.advance_playback(delta)
	var requested_y: float = _floor_y + motion.pose_lift()
	if not is_equal_approx(requested_y, fighter.global_position.y):
		fighter.move_and_collide(Vector2(0.0, requested_y - fighter.global_position.y), false, Motion.MARGIN)
	target.synchronize_hold(motion.hit_stop.remaining > 0.0)
	_project_pose()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_E:
			motion.request_dash(Dash.Kind.FORWARD)
		KEY_Q:
			motion.request_dash(Dash.Kind.BACKWARD)
		KEY_SHIFT:
			motion.request_dash(Dash.Kind.EVASIVE)
		KEY_R:
			reset_training()
		_:
			return
	get_viewport().set_input_as_handled()


func _drive_input() -> void:
	var guard: bool = Input.is_physical_key_pressed(KEY_F)
	if guard != _guard_input:
		_guard_input = guard
		if guard:
			if motion.attack_active or motion.impact_active or motion.dash_active or motion.jump_active:
				motion.request_pose(Motion.Pose.GUARD)
			else:
				motion.train_guard()
		elif motion.attack_active or motion.impact_active or motion.guarding():
			motion.request_idle()
		elif motion.bracing():
			motion.request_walk(0)
	if Input.is_action_just_pressed("jump"):
		motion.request_jump()
	for kind: Attack.Kind in [Attack.Kind.LIGHT, Attack.Kind.HEAVY, Attack.Kind.KICK]:
		var action: StringName = [&"light_attack", &"heavy_attack", &"kick_attack"][kind]
		if Input.is_action_just_pressed(action):
			motion.request_attack(kind)
	if motion.dash_active or motion.jump_active or motion.attack_active or motion.impact_active:
		return
	if guard:
		if not motion.guarding() and not motion.bracing():
			motion.train_guard()
		return
	var axis: int = roundi(Input.get_axis("move_left", "move_right") * motion.facing)
	if motion.walk_active:
		if motion.walk_cycle.requested_direction != axis:
			motion.request_walk(axis)
	elif axis != 0:
		motion.request_walk(axis)
	elif motion.guarding():
		motion.request_idle()


func _face_target() -> void:
	if motion.attack_active or motion.dash_active or motion.jump_active or motion.impact_active or motion.walk_active:
		return
	if not is_equal_approx(fighter.global_position.x, target.dummy.global_position.x):
		motion.facing = signf(target.dummy.global_position.x - fighter.global_position.x)
	target.sprite.flip_h = motion.facing > 0.0


func _project_pose() -> void:
	var factor: float = Motion.DISPLAY_SCALE
	display.scale = Vector2(motion.facing * factor, factor)
	display.global_position = fighter.global_position - Vector2(256.0 * factor * motion.facing, 663.0 * factor + motion.pose_lift())


func _confirm_attack(kind: Attack.Kind) -> bool:
	var forward: float = motion.facing
	if (target.dummy.global_position.x - fighter.global_position.x) * forward <= 0.0:
		return false
	_contact_shape.size = CONTACT_SIZE[kind]
	var center: Vector2 = fighter.global_position + CONTACT_CENTER[kind] * Vector2(forward, 1.0)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _contact_shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = _hurtbox.collision_layer
	query.collide_with_bodies = false
	query.collide_with_areas = true
	for overlap: Dictionary in fighter.get_world_2d().direct_space_state.intersect_shape(query):
		if overlap["collider"] == _hurtbox:
			target.strike(kind, fighter)
			_show_confirmation(kind, center)
			return true
	return false


func reset_training() -> void:
	motion.select_pose(Motion.Pose.NEUTRAL)
	motion.dash_world_x = 0.0
	motion.dash_displacement = 0.0
	motion.dash_blocked = false
	fighter.global_position = _spawn
	fighter.velocity = Vector2.ZERO
	_guard_input = false
	target.reset()
	if is_instance_valid(_effect):
		_effect.queue_free()
	_face_target()
	_project_pose()
	motion.request_idle()
	_update_feedback()


func _connect_hud() -> void:
	var ui: Control = get_parent().get_node("UI")
	_dummy_bar = ui.get_node("DummyHealth")
	_dummy_ghost = ui.get_node_or_null("DummyGhostHealth")
	_dummy_value = ui.get_node_or_null("DummyHealthValue")
	var opponent: Label = ui.get_node_or_null("OpponentSubLabel")
	if opponent != null:
		opponent.text = "PRACTICE TARGET · DURABILITY"
	var round_label: Label = ui.get_node_or_null("RoundIndicator")
	if round_label != null:
		round_label.text = "—  P R A C T I C E  —"
	var dock: Control = ui.get_node_or_null("ControlDock")
	if dock != null:
		dock.hide()
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_bottom = -13.0
	bottom.add_theme_constant_override("separation", 18)
	ui.add_child(bottom)
	_hint = Label.new()
	_hint.text = "A/D Move  ·  Space Jump  ·  Q Back Dash  ·  E Forward Dash  ·  Shift Evade  ·  F Guard  ·  Z/C/X Strike  ·  Esc Pause"
	_hint.add_theme_color_override("font_color", Color("#e4d3f2"))
	_hint.add_theme_color_override("font_outline_color", Color("#1a1027"))
	_hint.add_theme_constant_override("outline_size", 6)
	bottom.add_child(_hint)
	var reset: Button = Button.new()
	reset.name = "ResetDummy"
	reset.text = "RESET  [R]"
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(reset_training)
	bottom.add_child(reset)
	_notice = Label.new()
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_notice.offset_top = 126.0
	_notice.offset_bottom = 154.0
	_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_color_override("font_color", Color("#f0dbff"))
	_notice.add_theme_color_override("font_outline_color", Color("#1a1027"))
	_notice.add_theme_constant_override("outline_size", 6)
	ui.add_child(_notice)


func _show_confirmation(kind: Attack.Kind, center: Vector2) -> void:
	if is_instance_valid(_effect):
		_effect.queue_free()
	_effect = SPARK.instantiate() as HitSpark2D
	add_child(_effect)
	_effect.global_position = center
	_effect.play(AttackData.AttackKind.KICK if kind == Attack.Kind.KICK else AttackData.AttackKind.PUNCH)
	_update_feedback(Attack.NAMES[kind].to_upper() + "  ·  ")


func _update_feedback(prefix: String = "") -> void:
	_dummy_bar.max_value = target.maximum
	_dummy_bar.value = target.durability
	if _dummy_ghost != null:
		_dummy_ghost.value = target.durability
	if _dummy_value != null:
		_dummy_value.text = "%d / %d" % [roundi(target.durability), roundi(target.maximum)]
	_notice.text = "%s%d %s" % [prefix, target.hits, "HIT" if target.hits == 1 else "HITS"] if target.hits > 0 else "HYBRID KAI  ·  PRACTICE"
