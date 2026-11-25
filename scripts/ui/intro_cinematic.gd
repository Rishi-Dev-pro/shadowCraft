class_name IntroCinematic
extends Control

## ==============================================================================
## SHADOWCRAFT 2D — CINEMATIC GAME STARTUP
## ==============================================================================
## Plays opening cinematic automatically in 16:9 fullscreen with audio.
## Provides an unobtrusive skip option and seamlessly transitions to the logo screen.
## ==============================================================================

const LOGO_SCENE_PATH: String = "res://scenes/ui/logo_screen.tscn"
const SKIP_PROMPT_FADE_IN_DELAY: float = 1.2

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_pill: PanelContainer = $SkipPrompt
@onready var fade_veil: ColorRect = $FadeVeil

var _transitioning: bool = false
var _elapsed_time: float = 0.0

func _ready() -> void:
	fade_veil.visible = true
	fade_veil.modulate.a = 1.0
	if skip_pill != null:
		skip_pill.modulate.a = 0.0

	var entrance_tween: Tween = create_tween()
	entrance_tween.tween_property(fade_veil, "modulate:a", 0.0, 0.45)

	if video_player != null:
		if not video_player.finished.is_connected(_on_video_finished):
			video_player.finished.connect(_on_video_finished)
		_update_video_cover_fit()
		if not get_viewport().size_changed.is_connected(_update_video_cover_fit):
			get_viewport().size_changed.connect(_update_video_cover_fit)
		video_player.play()

func _update_video_cover_fit() -> void:
	if video_player == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var video_aspect: float = 16.0 / 9.0
	var vp_aspect: float = vp_size.x / vp_size.y
	var target_size: Vector2 = vp_size
	if vp_aspect > video_aspect:
		target_size.x = vp_size.x
		target_size.y = vp_size.x / video_aspect
	else:
		target_size.y = vp_size.y
		target_size.x = vp_size.y * video_aspect

	video_player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	video_player.size = target_size
	video_player.position = (vp_size - target_size) * 0.5

func _process(delta: float) -> void:
	if _transitioning:
		return

	_elapsed_time += delta
	if skip_pill != null and _elapsed_time >= SKIP_PROMPT_FADE_IN_DELAY and skip_pill.modulate.a < 0.65:
		skip_pill.modulate.a = move_toward(skip_pill.modulate.a, 0.65, delta * 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		_trigger_skip()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
			_trigger_skip()
	elif event is InputEventMouseButton and event.pressed:
		_trigger_skip()

func _on_video_finished() -> void:
	_transition_to_logo()

func _trigger_skip() -> void:
	if _transitioning:
		return
	if skip_pill != null:
		skip_pill.modulate = Color(1.2, 0.9, 1.4, 1.0)
	_transition_to_logo()

func _transition_to_logo() -> void:
	if _transitioning:
		return
	_transitioning = true

	var tween: Tween = create_tween()
	tween.tween_property(fade_veil, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if video_player != null and video_player.is_playing():
		tween.parallel().tween_property(video_player, "volume_db", -24.0, 0.35)

	await tween.finished
	if video_player != null:
		video_player.stop()

	var error: Error = get_tree().change_scene_to_file(LOGO_SCENE_PATH)
	if error != OK:
		push_error("Could not transition to logo screen: %s" % error_string(error))

