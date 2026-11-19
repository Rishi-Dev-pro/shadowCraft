extends SceneTree
## Render the two registered cutout poses used to generate the correction maps.

const BODY = preload("res://experimental/kai_hybrid/hybrid_body.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var directory: String = OS.get_environment("KAI_HYBRID_HANDOFF_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	var stage: SubViewport = SubViewport.new()
	stage.size = Vector2i(512, 512)
	stage.transparent_bg = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var body = BODY.instantiate()
	stage.add_child(body)
	for pose: int in [2, 3]:
		body.rig.set_repaired_artwork(pose == 3)
		body.apply_pose(pose, 1.0)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var pixels: Image = stage.get_texture().get_image()
		# A transparent Compatibility viewport returns premultiplied RGB.
		for y: int in range(pixels.get_height()):
			for x: int in range(pixels.get_width()):
				var pixel: Color = pixels.get_pixel(x, y)
				if pixel.a > 0.0:
					pixels.set_pixel(x, y, Color(pixel.r / pixel.a, pixel.g / pixel.a, pixel.b / pixel.a, pixel.a))
		if pixels.save_png(directory.path_join("anchor_%d.png" % pose)) != OK:
			quit(1)
			return
	quit()
