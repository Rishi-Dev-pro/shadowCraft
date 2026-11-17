extends RefCounted


static func closed(points: PackedVector2Array) -> PackedVector2Array:
	var loop: PackedVector2Array = points.duplicate()
	loop.append(points[0])
	return loop


static func trace(canvas: CanvasItem, path: PackedVector2Array, progress: float, color: Color) -> void:
	if progress <= 0.0 or progress >= 1.0:
		return
	var length: float = 0.0
	for index: int in range(1, path.size()):
		length += path[index - 1].distance_to(path[index])
	var end: float = length * progress
	var start: float = end - length * 0.11
	var traveled: float = 0.0
	for index: int in range(1, path.size()):
		var from: Vector2 = path[index - 1]
		var to: Vector2 = path[index]
		var segment: float = from.distance_to(to)
		if segment > 0.0 and traveled < end and traveled + segment > start:
			var a: float = clampf((start - traveled) / segment, 0.0, 1.0)
			var b: float = clampf((end - traveled) / segment, 0.0, 1.0)
			canvas.draw_line(from.lerp(to, a), from.lerp(to, b), color, 1.7, true)
		traveled += segment


static func crest(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_arc(center, radius, 0.43, TAU - 0.43, 32, color, 1.2, true)
	canvas.draw_arc(center - Vector2(radius * 0.22, 0), radius * 0.70, 0.43, TAU - 0.43, 24, color, 1.0, true)
	var point: Vector2 = center + Vector2(radius * 0.46, 0)
	canvas.draw_colored_polygon([
		point + Vector2(0, -radius * 0.44), point + Vector2(radius * 0.19, 0),
		point + Vector2(0, radius * 0.44), point - Vector2(radius * 0.19, 0),
	], color)
