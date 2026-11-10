extends Node2D

@export var run_automatic_review: bool = true

@onready var razen: CharacterController2D = get_node("Razen") as CharacterController2D
@onready var sprite: AnimatedSprite2D = get_node("Razen/Skeleton2D/AnimatedSprite2D") as AnimatedSprite2D

const CLIP_NAMES: Array[StringName] = [&"idle_signature", &"walk_forward", &"walk_backward", &"run", &"crouch", &"crouch_walk", &"jump", &"landing", &"attack_presentation", &"combat_ready"]

func _ready() -> void:
	if run_automatic_review:
		get_node("Razen/AnimationController").set_process(false)
		call_deferred("_capture_review")

func _capture_review() -> void:
	var preview_dir: String = ProjectSettings.globalize_path("res://assets/characters/razen/previews/rendered")
	DirAccess.make_dir_recursive_absolute(preview_dir)
	for clip: StringName in CLIP_NAMES:
		sprite.play(clip)
		await get_tree().create_timer(0.16).timeout
		_capture_frame(preview_dir.path_join("razen_%s.png" % String(clip)))
		await get_tree().create_timer(0.28).timeout
	get_tree().quit()

func _capture_frame(path: String) -> void:
	var rendered: Image = get_viewport().get_texture().get_image()
	var error: Error = rendered.save_png(path)
	if error != OK:
		push_error("Could not capture Razen preview: " + error_string(error))
