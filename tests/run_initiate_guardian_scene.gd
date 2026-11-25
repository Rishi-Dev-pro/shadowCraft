extends SceneTree

func _init() -> void:
	call_deferred("_start")

func _start() -> void:
	var test_scene: PackedScene = load("res://tests/unit/test_initiate_guardian.tscn") as PackedScene
	root.add_child(test_scene.instantiate())
