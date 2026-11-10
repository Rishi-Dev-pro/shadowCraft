extends SceneTree

const MANIFEST_PATH: String = "res://assets/characters/razen/animation_manifest.json"
const OUTPUT_PATH: String = "res://assets/characters/razen/razen_sprite_frames.tres"

func _init() -> void:
	var file: FileAccess = FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.READ)
	if file == null:
		push_error("Could not open Razen animation manifest")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not parsed.get("animations") is Dictionary:
		push_error("Razen animation manifest is malformed")
		quit(1)
		return
	var animations: Dictionary = parsed["animations"]
	var frames: SpriteFrames = SpriteFrames.new()
	for existing: StringName in frames.get_animation_names():
		frames.remove_animation(existing)
	for animation_value: Variant in animations.keys():
		var name: String = str(animation_value)
		var definition: Dictionary = animations[name]
		frames.add_animation(name)
		frames.set_animation_speed(name, float(definition["fps"]))
		frames.set_animation_loop(name, bool(definition["loop"]))
		for relative_path_value: Variant in definition["frame_paths"]:
			var relative_path: String = str(relative_path_value)
			var texture: Texture2D = ResourceLoader.load("res://assets/characters/razen/" + relative_path) as Texture2D
			if texture == null:
				push_error("Could not load Razen frame: " + relative_path)
				quit(1)
				return
			frames.add_frame(name, texture)
		if frames.get_frame_count(name) != int(definition["frame_count"]):
			push_error("Frame count mismatch for Razen animation: " + name)
			quit(1)
			return
	var error: Error = ResourceSaver.save(frames, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save Razen SpriteFrames: " + error_string(error))
		quit(1)
		return
	print("Saved %d Razen animations to %s" % [frames.get_animation_names().size(), OUTPUT_PATH])
	quit(0)
