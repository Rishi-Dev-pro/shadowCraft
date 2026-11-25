class_name LogoScreen
extends Control

## ==============================================================================
## SHADOWCRAFT 2D — OFFICIAL LOGO REVEAL SCREEN
## ==============================================================================
## Displays the official logo on dark violet background with subtle purple
## particles and soft glow, holds for ~3 seconds, and smoothly fades into
## the World Map scene.
## ==============================================================================

const NEXT_SCENE_PATH: String = "res://scenes/ui/world_map.tscn"
const HOLD_DURATION: float = 3.2
const FADE_IN_DURATION: float = 0.8
const FADE_OUT_DURATION: float = 0.6

@onready var background: ColorRect = $Background
@onready var logo_texture: TextureRect = $LogoContainer/LogoTexture
@onready var glow_aura: ColorRect = $LogoContainer/GlowAura
@onready var particles: CPUParticles2D = $Particles
@onready var prompt_label: Label = $PromptLabel
@onready var fade_veil: ColorRect = $FadeVeil

var _transitioning: bool = false
var _hold_timer: float = 0.0
var _can_skip: bool = false

func _ready() -> void:
	var selection_state: CharacterSelectionState = get_node_or_null("/root/CharacterSelection") as CharacterSelectionState
	if selection_state != null:
		selection_state.select_character(&"kai")
	fade_veil.visible = true
	fade_veil.modulate.a = 1.0
	logo_texture.modulate.a = 0.0
	if prompt_label != null:
		prompt_label.modulate.a = 0.0

	_update_layout()
	if not get_viewport().size_changed.is_connected(_update_layout):
		get_viewport().size_changed.connect(_update_layout)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(fade_veil, "modulate:a", 0.0, FADE_IN_DURATION)
	tween.tween_property(logo_texture, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if glow_aura != null:
		glow_aura.modulate.a = 0.0
		tween.tween_property(glow_aura, "modulate:a", 0.35, FADE_IN_DURATION * 1.2)

	await tween.finished
	_can_skip = true
	if prompt_label != null:
		var prompt_tween: Tween = create_tween()
		prompt_tween.tween_property(prompt_label, "modulate:a", 0.5, 0.6)

func _process(delta: float) -> void:
	if _transitioning:
		return

	_hold_timer += delta
	if _hold_timer >= HOLD_DURATION:
		_transition_to_world_map()

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or not _can_skip:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		_transition_to_world_map()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
			_transition_to_world_map()
	elif event is InputEventMouseButton and event.pressed:
		_transition_to_world_map()

func _transition_to_world_map() -> void:
	if _transitioning:
		return
	_transitioning = true

	var tween: Tween = create_tween()
	tween.tween_property(fade_veil, "modulate:a", 1.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	var error: Error = get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	if error != OK:
		push_error("Could not transition to the World Map: %s" % error_string(error))

func _update_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	if particles != null:
		particles.position = Vector2(vp_size.x * 0.5, vp_size.y - 40.0)
		particles.emission_rect_extents = Vector2(vp_size.x * 0.45, 20.0)


