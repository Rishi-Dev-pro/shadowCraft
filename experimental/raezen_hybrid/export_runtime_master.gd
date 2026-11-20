extends SceneTree
## Export the active imported reference without changing the campaign asset.

const MASTER: String = "res://assets/characters/raezan_boss/frames/idle/idle_01.png"


func _initialize() -> void:
	var path: String = OS.get_environment("RAEZEN_RUNTIME_MASTER")
	var texture: Texture2D = load(MASTER)
	if path.is_empty() or texture == null:
		push_error("Set RAEZEN_RUNTIME_MASTER to a writable PNG path.")
		quit(1)
		return
	quit(int(texture.get_image().save_png(path) != OK))
