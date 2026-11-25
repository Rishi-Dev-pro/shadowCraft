extends SceneTree
func _initialize() -> void:
	call_deferred("_run_test_scene")
func _run_test_scene() -> void:
	var packed: PackedScene = load("res://tests/unit/test_the_executioner_guardian.tscn") as PackedScene
	if packed == null:
		printerr("Failed to load Executioner regression scene")
		quit(1)
		return
	root.add_child(packed.instantiate())
