extends SceneTree

const ASSET_ROOT: String = "res://assets/enemies/robotic_minion/"
const OUTPUT_PATH: String = ASSET_ROOT + "robotic_minion_sprite_frames.tres"
const ANIMATIONS: Array[Dictionary] = [
	{"name": "idle", "frame_count": 6, "fps": 8.0, "loop": true},
	{"name": "walk", "frame_count": 8, "fps": 12.0, "loop": true},
	{"name": "punch", "frame_count": 6, "fps": 12.0, "loop": false},
	{"name": "kick", "frame_count": 8, "fps": 12.0, "loop": false},
	{"name": "hit", "frame_count": 4, "fps": 12.0, "loop": false},
	{"name": "death", "frame_count": 8, "fps": 12.0, "loop": false},
]

func _initialize() -> void:
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	for animation_name: StringName in sprite_frames.get_animation_names():
		sprite_frames.remove_animation(animation_name)

	for animation: Dictionary in ANIMATIONS:
		var name: String = str(animation["name"])
		var directory: String = ASSET_ROOT + "animations/" + name + "/"
		if not sprite_frames.has_animation(name):
			sprite_frames.add_animation(name)
		sprite_frames.set_animation_speed(name, float(animation["fps"]))
		sprite_frames.set_animation_loop(name, bool(animation["loop"]))
		for frame_index: int in range(int(animation["frame_count"])):
			var frame_path: String = directory + "frame_%02d.png" % (frame_index + 1)
			var texture: Texture2D = ResourceLoader.load(frame_path) as Texture2D
			if texture == null:
				push_error("Missing robotic minion animation frame: " + frame_path)
				quit(1)
				return
			sprite_frames.add_frame(name, texture)

	var guard_texture: Texture2D = ResourceLoader.load(ASSET_ROOT + "sprites/robotic_minion_guard.png") as Texture2D
	if guard_texture == null:
		push_error("Could not load the approved robotic minion guard sprite")
		quit(1)
		return
	sprite_frames.add_animation("guard")
	sprite_frames.set_animation_speed("guard", 0.0)
	sprite_frames.set_animation_loop("guard", false)
	sprite_frames.add_frame("guard", guard_texture)

	var error: Error = ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save robotic minion SpriteFrames: " + error_string(error))
		quit(1)
		return
	print("Built 7 robotic minion animations with %d frames" % _count_frames(sprite_frames))
	quit(0)

func _count_frames(sprite_frames: SpriteFrames) -> int:
	var total: int = 0
	for animation_name: StringName in sprite_frames.get_animation_names():
		total += sprite_frames.get_frame_count(animation_name)
	return total
