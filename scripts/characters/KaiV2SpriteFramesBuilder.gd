extends SceneTree

const MANIFEST_PATH: String = "res://assets/characters/kai_v2/import_manifest.json"
const OUTPUT_PATH: String = "res://assets/characters/kai_v2/kai_v2_sprite_frames.tres"

func _init() -> void:
	var manifest_file: FileAccess = FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.READ)
	if manifest_file == null:
		push_error("Kai V2 import manifest could not be opened: %s" % MANIFEST_PATH)
		quit(1)
		return
	var manifest_value: Variant = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()
	if not manifest_value is Dictionary:
		push_error("Kai V2 import manifest is not a JSON object")
		quit(1)
		return
	var manifest: Dictionary = manifest_value
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	for animation_name: StringName in sprite_frames.get_animation_names():
		sprite_frames.remove_animation(animation_name)
	var animation_settings: Dictionary = {
		"idle_signature": {"speed": 6.0, "loop": true},
		"walk_forward": {"speed": 9.0, "loop": true},
		"walk_backward": {"speed": 9.0, "loop": true},
		"run": {"speed": 12.0, "loop": true},
		"crouch": {"speed": 8.0, "loop": true},
		"crouch_walk": {"speed": 10.0, "loop": true},
		"jump": {"speed": 8.0, "loop": false},
		"landing": {"speed": 12.0, "loop": false},
		"light_jab": {"speed": 30.0, "loop": false},
		"front_kick": {"speed": 30.0, "loop": false}
	}
	var failed: bool = false
	for group_value: Variant in manifest.get("groups", []):
		if not group_value is Dictionary:
			continue
		var group: Dictionary = group_value
		var animation_name: String = str(group.get("name", ""))
		if not animation_settings.has(animation_name):
			continue
		var settings: Dictionary = animation_settings[animation_name]
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, float(settings["speed"]))
		sprite_frames.set_animation_loop(animation_name, bool(settings["loop"]))
		for frame_path_value: Variant in group.get("frame_paths", []):
			var frame_path: String = str(frame_path_value)
			var texture: Texture2D = ResourceLoader.load(frame_path) as Texture2D
			if texture == null:
				push_error("Could not load Kai V2 frame texture: %s" % frame_path)
				failed = true
				continue
			sprite_frames.add_frame(animation_name, texture)
		if sprite_frames.get_frame_count(animation_name) != int(group.get("frame_count", -1)):
			push_error("Kai V2 animation frame count mismatch: %s" % animation_name)
			failed = true
	var attack_definitions: Array[Dictionary] = [
		{"name": "light_jab", "path": "res://assets/characters/kai_v2/animations/attacks/light_jab_source.png"},
		{"name": "front_kick", "path": "res://assets/characters/kai_v2/animations/attacks/front_kick_source.png"}
	]
	for definition: Dictionary in attack_definitions:
		var animation_name: String = str(definition["name"])
		var sheet_path: String = str(definition["path"])
		var sheet: Texture2D = ResourceLoader.load(sheet_path) as Texture2D
		if sheet == null or sheet.get_width() != 1536 or sheet.get_height() != 1024:
			push_error("Combat sprite sheet must be 1536x1024: %s" % sheet_path)
			failed = true
			continue
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, 30.0)
		sprite_frames.set_animation_loop(animation_name, false)
		for frame_index: int in range(6):
			var atlas_frame: AtlasTexture = AtlasTexture.new()
			atlas_frame.atlas = sheet
			atlas_frame.region = Rect2((frame_index % 3) * 512, int(frame_index / 3) * 512, 512, 512)
			sprite_frames.add_frame(animation_name, atlas_frame)
	if failed or sprite_frames.get_animation_names().size() != animation_settings.size():
		push_error("Kai V2 SpriteFrames resource was not built completely")
		quit(1)
		return
	var save_error: Error = ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save Kai V2 SpriteFrames: %s" % error_string(save_error))
		quit(1)
		return
	print("Saved %d Kai V2 animations to %s" % [sprite_frames.get_animation_names().size(), OUTPUT_PATH])
	quit(0)
