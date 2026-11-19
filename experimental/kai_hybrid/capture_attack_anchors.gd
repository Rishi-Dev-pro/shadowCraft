extends SceneTree
## Render attack-only handoff anchors through the same rig and renderer as the lab.

const LAB = preload("res://experimental/kai_hybrid/kai_hybrid_lab.tscn")
const Body = preload("res://experimental/kai_hybrid/hybrid_body.gd")
const Motion = preload("res://experimental/kai_hybrid/attack_motion.gd")


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	var destination: String = OS.get_environment("KAI_ATTACK_ANCHOR_DIR")
	if destination.is_empty() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	var lab: Node = LAB.instantiate()
	root.add_child(lab)
	var body: Body = lab.get_node("%HybridBody")
	var stage: SubViewport = body.get_parent() as SubViewport
	body.rig.set_repaired_artwork(true)
	for kind: Motion.Kind in [Motion.Kind.LIGHT, Motion.Kind.HEAVY, Motion.Kind.KICK]:
		body.apply_attack_anchor(kind, 1.0, true)
		await RenderingServer.frame_post_draw
		var pixels: Image = stage.get_texture().get_image()
		for y: int in pixels.get_height():
			for x: int in pixels.get_width():
				var pixel: Color = pixels.get_pixel(x, y)
				if pixel.a > 0.0:
					pixels.set_pixel(x, y, Color(pixel.r / pixel.a, pixel.g / pixel.a, pixel.b / pixel.a, pixel.a))
		if pixels.save_png(destination.path_join(Motion.FAMILIES[kind] + "_0.png")) != OK:
			quit(1)
			return
	quit()
