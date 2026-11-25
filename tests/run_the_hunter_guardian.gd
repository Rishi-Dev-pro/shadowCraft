extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var test_scene: PackedScene = load("res://tests/unit/test_the_hunter_guardian.tscn") as PackedScene
	if test_scene == null:
		push_error("Could not load The Hunter Guardian test scene")
		quit(1)
		return
	root.add_child(test_scene.instantiate())
