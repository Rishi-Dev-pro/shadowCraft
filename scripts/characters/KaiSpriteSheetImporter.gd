extends SceneTree
## Deterministically slices generated Kai sprite sheets into aligned RGBA frames.

const FRAME_SIZE: int = 512
const PREVIEW_TILE_SIZE: int = 256
const OUTPUT_ROOT: String = "res://assets/characters/kai_v2"
var sheets: Array[Dictionary] = [
	{
		"source": "source/kai_turnaround_grid.png",
		"output": "views",
		"columns": 4,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["front_000", "front_three_quarter_045", "side_right_090", "back_three_quarter_135", "back_180", "back_three_quarter_225", "side_left_270", "front_three_quarter_315"])
	},
	{
		"source": "source/idle_signature_grid.png",
		"output": "animations/idle_signature",
		"columns": 4,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["idle_01", "idle_02", "idle_03", "idle_04", "idle_05", "idle_06", "idle_07", "idle_08"])
	},
	{
		"source": "source/walk_forward_grid.png",
		"output": "animations/walk_forward",
		"columns": 4,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["walk_forward_01", "walk_forward_02", "walk_forward_03", "walk_forward_04", "walk_forward_05", "walk_forward_06", "walk_forward_07", "walk_forward_08"])
	},
	{
		"source": "source/walk_backward_grid.png",
		"output": "animations/walk_backward",
		"columns": 4,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["walk_backward_01", "walk_backward_02", "walk_backward_03", "walk_backward_04", "walk_backward_05", "walk_backward_06", "walk_backward_07", "walk_backward_08"])
	},
	{
		"source": "source/run_grid.png",
		"output": "animations/run",
		"columns": 4,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["run_01", "run_02", "run_03", "run_04", "run_05", "run_06", "run_07", "run_08"])
	},
	{
		"source": "source/crouch_grid.png",
		"output": "animations/crouch",
		"columns": 2,
		"rows": 2,
		"target_height": 350,
		"names": PackedStringArray(["crouch_01", "crouch_02", "crouch_03", "crouch_04"])
	},
	{
		"source": "source/crouch_walk_grid.png",
		"output": "animations/crouch_walk",
		"columns": 4,
		"rows": 2,
		"target_height": 350,
		"names": PackedStringArray(["crouch_walk_01", "crouch_walk_02", "crouch_walk_03", "crouch_walk_04", "crouch_walk_05", "crouch_walk_06", "crouch_walk_07", "crouch_walk_08"])
	},
	{
		"source": "source/jump_grid.png",
		"output": "animations/jump",
		"columns": 2,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["jump_01", "jump_02", "jump_03", "jump_04"])
	},
	{
		"source": "source/landing_grid.png",
		"output": "animations/landing",
		"columns": 2,
		"rows": 2,
		"target_height": 460,
		"names": PackedStringArray(["landing_01", "landing_02", "landing_03", "landing_04"])
	}
]
var import_manifest: Dictionary = {
	"godot_version": "4.7.2",
	"frame_size": [FRAME_SIZE, FRAME_SIZE],
	"sources": [],
	"groups": []
}

func _init() -> void:
	var failed_count: int = 0
	for sheet: Dictionary in sheets:
		if not _slice_sheet(sheet):
			failed_count += 1
	_write_manifest()
	quit(1 if failed_count > 0 else 0)

func _slice_sheet(sheet: Dictionary) -> bool:
	var source_path: String = OUTPUT_ROOT.path_join(str(sheet["source"]))
	var source_image: Image = Image.new()
	var load_error: Error = source_image.load(ProjectSettings.globalize_path(source_path))
	if load_error != OK:
		push_error("Could not load sprite sheet: %s (%s)" % [source_path, error_string(load_error)])
		return false
	if source_image.is_empty() or source_image.get_format() != Image.FORMAT_RGBA8:
		push_error("Sprite sheet must be a non-empty RGBA8 PNG: %s" % source_path)
		return false
	var columns: int = int(sheet["columns"])
	var rows: int = int(sheet["rows"])
	var names: PackedStringArray = sheet["names"]
	if columns <= 0 or rows <= 0 or names.size() != columns * rows:
		push_error("Frame grid and frame-name count disagree for %s" % source_path)
		return false
	var output_dir: String = OUTPUT_ROOT.path_join(str(sheet["output"]))
	var absolute_output_dir: String = ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	var source_size: Vector2i = source_image.get_size()
	import_manifest["sources"].append({
		"path": source_path,
		"width": source_size.x,
		"height": source_size.y,
		"columns": columns,
		"rows": rows
	})
	var target_height: int = int(sheet["target_height"])
	var success: bool = true
	var generated_frames: Array[Image] = []
	var generated_paths: Array[String] = []
	for frame_index: int in range(names.size()):
		var column: int = frame_index % columns
		var row: int = frame_index / columns
		var left: int = roundi(float(source_size.x * column) / float(columns))
		var right: int = roundi(float(source_size.x * (column + 1)) / float(columns))
		var top: int = roundi(float(source_size.y * row) / float(rows))
		var bottom: int = roundi(float(source_size.y * (row + 1)) / float(rows))
		var cell: Image = source_image.get_region(Rect2i(left, top, right - left, bottom - top))
		_remove_tiny_alpha_components(cell)
		var used_rect: Rect2i = cell.get_used_rect()
		if used_rect.size.x <= 0 or used_rect.size.y <= 0:
			push_error("Empty generated frame %s/%s" % [output_dir, names[frame_index]])
			success = false
			continue
		var content: Image = cell.get_region(used_rect)
		var fit_scale: float = minf(float(target_height) / float(content.get_height()), float(FRAME_SIZE - 24) / float(content.get_width()))
		var final_width: int = maxi(1, roundi(float(content.get_width()) * fit_scale))
		var final_height: int = maxi(1, roundi(float(content.get_height()) * fit_scale))
		content.resize(final_width, final_height, Image.INTERPOLATE_LANCZOS)
		var resized_bounds: Rect2i = content.get_used_rect()
		if resized_bounds.size.x <= 0 or resized_bounds.size.y <= 0:
			push_error("Resized frame became empty: %s/%s" % [output_dir, names[frame_index]])
			success = false
			continue
		var normalized_frame: Image = Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
		var destination: Vector2i = Vector2i((FRAME_SIZE - resized_bounds.size.x) / 2, FRAME_SIZE - resized_bounds.size.y)
		normalized_frame.blit_rect(content, resized_bounds, destination)
		var destination_path: String = output_dir.path_join("%s.png" % names[frame_index])
		var save_error: Error = normalized_frame.save_png(ProjectSettings.globalize_path(destination_path))
		if save_error != OK:
			push_error("Could not save normalized frame: %s (%s)" % [destination_path, error_string(save_error)])
			success = false
		else:
			generated_frames.append(normalized_frame)
			generated_paths.append(destination_path)
			print("FRAME %s -> %s (%dx%d source, %dx%d normalized)" % [names[frame_index], destination_path, used_rect.size.x, used_rect.size.y, final_width, final_height])
	if success and generated_frames.size() == names.size():
		var preview_path: String = _write_contact_sheet(str(sheet["output"]).get_file(), generated_frames, columns, rows)
		import_manifest["groups"].append({
			"name": str(sheet["output"]).get_file(),
			"output_directory": output_dir,
			"frame_count": generated_paths.size(),
			"frame_paths": generated_paths,
			"contact_sheet": preview_path
		})
	else:
		success = false
	return success

func _write_contact_sheet(group_name: String, frames: Array[Image], columns: int, rows: int) -> String:
	var preview_dir: String = OUTPUT_ROOT.path_join("previews")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(preview_dir))
	var contact_sheet: Image = Image.create(columns * PREVIEW_TILE_SIZE, rows * PREVIEW_TILE_SIZE, false, Image.FORMAT_RGBA8)
	contact_sheet.fill(Color(0.035, 0.025, 0.055, 1.0))
	for frame_index: int in range(frames.size()):
		var tile: Image = frames[frame_index].duplicate()
		tile.resize(PREVIEW_TILE_SIZE, PREVIEW_TILE_SIZE, Image.INTERPOLATE_LANCZOS)
		var tile_position: Vector2i = Vector2i((frame_index % columns) * PREVIEW_TILE_SIZE, (frame_index / columns) * PREVIEW_TILE_SIZE)
		contact_sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), tile_position)
	var preview_path: String = preview_dir.path_join("%s_contact.png" % group_name)
	var save_error: Error = contact_sheet.save_png(ProjectSettings.globalize_path(preview_path))
	if save_error != OK:
		push_error("Could not save contact sheet: %s (%s)" % [preview_path, error_string(save_error)])
		return ""
	print("CONTACT %s" % preview_path)
	return preview_path

func _write_manifest() -> void:
	var manifest_path: String = OUTPUT_ROOT.path_join("import_manifest.json")
	var manifest_file: FileAccess = FileAccess.open(ProjectSettings.globalize_path(manifest_path), FileAccess.WRITE)
	if manifest_file == null:
		push_error("Could not write import manifest: %s" % manifest_path)
		return
	manifest_file.store_string(JSON.stringify(import_manifest, "\t"))
	manifest_file.close()
	print("MANIFEST %s" % manifest_path)

func _remove_tiny_alpha_components(image: Image) -> void:
	var image_size: Vector2i = image.get_size()
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(image_size.x * image_size.y)
	var component: PackedInt32Array = PackedInt32Array()
	var pending: Array[int] = []
	for y: int in range(image_size.y):
		for x: int in range(image_size.x):
			var start_index: int = y * image_size.x + x
			if visited[start_index] != 0 or image.get_pixel(x, y).a <= 0.08:
				continue
			component.clear()
			pending.clear()
			pending.append(start_index)
			visited[start_index] = 1
			while not pending.is_empty():
				var current_index: int = pending.pop_back()
				component.append(current_index)
				var current_x: int = current_index % image_size.x
				var current_y: int = current_index / image_size.x
				for offset_y: int in range(-1, 2):
					for offset_x: int in range(-1, 2):
						if offset_x == 0 and offset_y == 0:
							continue
						var neighbor_x: int = current_x + offset_x
						var neighbor_y: int = current_y + offset_y
						if neighbor_x < 0 or neighbor_y < 0 or neighbor_x >= image_size.x or neighbor_y >= image_size.y:
							continue
						var neighbor_index: int = neighbor_y * image_size.x + neighbor_x
						if visited[neighbor_index] != 0 or image.get_pixel(neighbor_x, neighbor_y).a <= 0.08:
							continue
						visited[neighbor_index] = 1
						pending.append(neighbor_index)
			if component.size() <= 8:
				for pixel_index: int in component:
					image.set_pixel(pixel_index % image_size.x, pixel_index / image_size.x, Color.TRANSPARENT)
