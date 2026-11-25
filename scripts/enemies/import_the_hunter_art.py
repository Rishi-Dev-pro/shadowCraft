"""Normalize original generated Hunter sheets into transparent 512px game frames."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets" / "enemies" / "the_hunter"
FRAME_SIZE = 512
GROUND_ANCHOR_Y = 496
TARGET_HEIGHT = 470
TARGET_WIDTH = 488
ALPHA_THRESHOLD = 24

SHEETS: dict[str, tuple[str, int, int, int]] = {
	"idle": ("idle_sheet.png", 4, 2, 8),
	"walk": ("walk_forward_sheet.png", 4, 2, 8),
	"walk_backward": ("walk_backward_sheet.png", 4, 2, 8),
	"light_axe": ("light_axe_sheet.png", 4, 2, 8),
	"heavy_axe": ("heavy_axe_sheet.png", 4, 2, 8),
	"axe_sweep": ("axe_sweep_sheet.png", 4, 2, 8),
	"guard": ("guard_sheet.png", 2, 2, 4),
	"hit": ("hit_knockdown_sheet.png", 4, 2, 4),
	"death": ("hit_knockdown_sheet.png", 4, 2, 4),
}

FRAME_DURATIONS: dict[str, list[int]] = {
	"light_axe": [4, 6, 8, 5, 4, 6, 8, 17],
	"heavy_axe": [5, 9, 12, 10, 4, 8, 12, 18],
	"axe_sweep": [5, 8, 10, 9, 5, 8, 12, 16],
}


def _background_candidate(pixel: tuple[int, int, int, int]) -> bool:
	r, g, b, alpha = pixel
	return alpha > 32 and min(r, g, b) > 150 and max(r, g, b) - min(r, g, b) < 90


def _clear_connected_light_background(image: Image.Image) -> Image.Image:
	"""Remove only light neutral regions connected to a cell edge (for opaque sheets)."""
	rgba = image.convert("RGBA")
	pixels = rgba.load()
	width, height = rgba.size
	if all(pixels[x, y][3] < 24 for x, y in [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]):
		return rgba
	visited = bytearray(width * height)
	queue: deque[tuple[int, int]] = deque()
	for x in range(width):
		for y in (0, height - 1):
			if _background_candidate(pixels[x, y]):
				queue.append((x, y))
	for y in range(height):
		for x in (0, width - 1):
			if _background_candidate(pixels[x, y]):
				queue.append((x, y))
	while queue:
		x, y = queue.popleft()
		index = y * width + x
		if visited[index] or not _background_candidate(pixels[x, y]):
			continue
		visited[index] = 1
		for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
			if 0 <= nx < width and 0 <= ny < height and not visited[ny * width + nx]:
				queue.append((nx, ny))
	for index, enabled in enumerate(visited):
		if enabled:
			x, y = index % width, index // width
			pixels[x, y] = (0, 0, 0, 0)
	return rgba


def _largest_component(image: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
	alpha = image.getchannel("A")
	width, height = image.size
	mask = bytearray(1 if value > ALPHA_THRESHOLD else 0 for value in alpha.tobytes())
	visited = bytearray(width * height)
	best_seed = -1
	best_area = 0
	for seed, enabled in enumerate(mask):
		if not enabled or visited[seed]:
			continue
		visited[seed] = 1
		stack = [seed]
		area = 0
		while stack:
			index = stack.pop()
			x, y = index % width, index // width
			area += 1
			for ny in range(max(0, y - 1), min(height, y + 2)):
				for nx in range(max(0, x - 1), min(width, x + 2)):
					neighbor = ny * width + nx
					if mask[neighbor] and not visited[neighbor]:
						visited[neighbor] = 1
						stack.append(neighbor)
		if area > best_area:
			best_seed, best_area = seed, area
	if best_seed < 0:
		raise ValueError("Sheet cell has no opaque Hunter silhouette")
	component = bytearray(width * height)
	component[best_seed] = 1
	stack = [best_seed]
	while stack:
		index = stack.pop()
		x, y = index % width, index // width
		for ny in range(max(0, y - 1), min(height, y + 2)):
			for nx in range(max(0, x - 1), min(width, x + 2)):
				neighbor = ny * width + nx
				if mask[neighbor] and not component[neighbor]:
					component[neighbor] = 1
					stack.append(neighbor)
	box = Image.frombytes("L", (width, height), bytes(255 if value else 0 for value in component))
	bounds = box.getbbox()
	if bounds is None:
		raise ValueError("Hunter component is empty")
	image.putalpha(Image.composite(image.getchannel("A"), Image.new("L", (width, height), 0), box))
	return image.crop(bounds), bounds


def _normalize(cell: Image.Image, anchor: bool = True) -> Image.Image:
	prepared = _clear_connected_light_background(cell)
	content, _bounds = _largest_component(prepared)
	width, height = content.size
	fit = min(TARGET_HEIGHT / height, TARGET_WIDTH / width)
	new_size = (max(1, round(width * fit)), max(1, round(height * fit)))
	content = content.resize(new_size, Image.Resampling.LANCZOS)
	frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
	x = (FRAME_SIZE - new_size[0]) // 2
	y = GROUND_ANCHOR_Y - new_size[1] if anchor else (FRAME_SIZE - new_size[1]) // 2
	frame.alpha_composite(content, (x, y))
	if frame.getchannel("A").getbbox() is None or frame.getchannel("A").getextrema()[0] != 0:
		raise ValueError("Normalized frame failed transparent canvas validation")
	return frame


def _crop_cell(sheet: Image.Image, grid: tuple[int, int], index: int) -> Image.Image:
	columns, rows = grid
	col, row = index % columns, index // columns
	x0, x1 = round(col * sheet.width / columns), round((col + 1) * sheet.width / columns)
	y0, y1 = round(row * sheet.height / rows), round((row + 1) * sheet.height / rows)
	return sheet.crop((x0, y0, x1, y1))


def _write_contact_sheet(frames: list[Image.Image], destination: Path) -> None:
	columns = min(4, len(frames))
	rows = (len(frames) + columns - 1) // columns
	tile = 256
	sheet = Image.new("RGBA", (columns * tile, rows * tile), (22, 17, 31, 255))
	draw = ImageDraw.Draw(sheet)
	for index, frame in enumerate(frames):
		x, y = (index % columns) * tile, (index // columns) * tile
		sheet.alpha_composite(frame.resize((tile, tile), Image.Resampling.LANCZOS), (x, y))
		draw.rectangle((x, y, x + tile - 1, y + tile - 1), outline=(93, 65, 120, 255), width=1)
	destination.parent.mkdir(parents=True, exist_ok=True)
	sheet.convert("RGB").save(destination, quality=94)


def _extract_frames() -> dict[str, list[Image.Image]]:
	all_frames: dict[str, list[Image.Image]] = {}
	for animation, (source_name, columns, rows, count) in SHEETS.items():
		source_path = BASE / "source" / source_name
		sheet = Image.open(source_path).convert("RGBA")
		if animation == "death":
			indices = list(range(columns, columns * rows))
		elif animation == "hit":
			indices = list(range(columns))
		else:
			indices = list(range(count))
		frames: list[Image.Image] = []
		frame_dir = BASE / "frames" / animation
		frame_dir.mkdir(parents=True, exist_ok=True)
		for out_index, source_index in enumerate(indices, start=1):
			frame = _normalize(_crop_cell(sheet, (columns, rows), source_index))
			destination = frame_dir / f"{animation}_{out_index:02d}.png"
			frame.save(destination, "PNG", optimize=True)
			frames.append(frame)
			print(f"{animation} frame {out_index}/{count}: {destination.relative_to(ROOT).as_posix()}")
		all_frames[animation] = frames
		_write_contact_sheet(frames, BASE / "previews" / f"{animation}_contact.png")
	return all_frames


def _write_axe() -> None:
	source = Image.open(BASE / "source" / "stone_axe_source.png").convert("RGBA")
	content, bounds = _largest_component(_clear_connected_light_background(source))
	width, height = content.size
	fit = min(360 / width, 460 / height)
	resized = content.resize((round(width * fit), round(height * fit)), Image.Resampling.LANCZOS)
	frame = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
	frame.alpha_composite(resized, ((512 - resized.width) // 2, 500 - resized.height))
	destination = ROOT / "assets" / "weapons" / "stone_axe" / "stone_axe.png"
	destination.parent.mkdir(parents=True, exist_ok=True)
	frame.save(destination, "PNG", optimize=True)
	print(f"weapon: {destination.relative_to(ROOT).as_posix()} source bounds={bounds}")


def _write_portrait() -> None:
	"""Make a portrait crop from original Hunter artwork, separate from game frames."""
	frame_path = BASE / "frames" / "idle" / "idle_01.png"
	frame = Image.open(frame_path).convert("RGBA")
	portrait_crop = frame.crop((40, 0, 472, 340))
	content, _bounds = _largest_component(portrait_crop)
	width, height = content.size
	fit = min(488 / width, 488 / height)
	content = content.resize((round(width * fit), round(height * fit)), Image.Resampling.LANCZOS)
	portrait = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
	portrait.alpha_composite(content, ((512 - content.width) // 2, (512 - content.height) // 2))
	destination = BASE / "portraits" / "the_hunter_portrait.png"
	destination.parent.mkdir(parents=True, exist_ok=True)
	portrait.save(destination, "PNG", optimize=True)
	print(f"portrait: {destination.relative_to(ROOT).as_posix()}")


def _write_sprite_frames() -> None:
	animations: list[dict[str, object]] = [
		{"name": "idle", "frames": "idle", "speed": 7.0, "loop": True},
		{"name": "walk", "frames": "walk", "speed": 9.0, "loop": True},
		{"name": "walk_backward", "frames": "walk_backward", "speed": 9.0, "loop": True},
		{"name": "light_axe", "frames": "light_axe", "speed": 60.0, "loop": False, "durations": FRAME_DURATIONS["light_axe"]},
		{"name": "heavy_axe", "frames": "heavy_axe", "speed": 60.0, "loop": False, "durations": FRAME_DURATIONS["heavy_axe"]},
		{"name": "axe_sweep", "frames": "axe_sweep", "speed": 60.0, "loop": False, "durations": FRAME_DURATIONS["axe_sweep"]},
		{"name": "guard", "frames": "guard", "speed": 8.0, "loop": True},
		{"name": "hit", "frames": "hit", "speed": 12.0, "loop": False},
		{"name": "death", "frames": "death", "speed": 8.0, "loop": False},
	]
	# Use explicit paths so variable frame counts stay visible and auditable.
	frame_counts = {"idle": 8, "walk": 8, "walk_backward": 8, "light_axe": 8, "heavy_axe": 8, "axe_sweep": 8, "guard": 4, "hit": 4, "death": 4}
	all_paths = [f"frames/{a['frames']}/{a['frames']}_{i:02d}.png" for a in animations for i in range(1, frame_counts[str(a['frames'])] + 1)]
	unique = list(dict.fromkeys(all_paths))
	ids = {path: f"tex_{index + 1}" for index, path in enumerate(unique)}
	lines = [f"[gd_resource type=\"SpriteFrames\" load_steps={len(unique) + 1} format=3]", ""]
	for path in unique:
		lines.append(f"[ext_resource type=\"Texture2D\" path=\"res://assets/enemies/the_hunter/{path}\" id=\"{ids[path]}\"]")
	lines.extend(["", "[resource]", "animations = ["])
	for animation_index, animation in enumerate(animations):
		lines.append("}, {" if animation_index else "{")
		name = str(animation["frames"])
		paths = [f"frames/{name}/{name}_{i:02d}.png" for i in range(1, frame_counts[name] + 1)]
		durations = animation.get("durations", [1.0] * len(paths))
		lines.append("\"frames\": [")
		for frame_index, path in enumerate(paths):
			lines.append("}, {" if frame_index else "{")
			lines.append(f"\"duration\": {float(durations[frame_index]):.1f},")
			lines.append(f"\"texture\": ExtResource(\"{ids[path]}\")")
		lines.append("}],")
		lines.append(f"\"loop\": {1 if animation['loop'] else 0},")
		lines.append(f"\"name\": &\"{animation['name']}\",")
		lines.append(f"\"speed\": {float(animation['speed']):.1f}")
	lines.append("}]")
	(BASE / "the_hunter_sprite_frames.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
	frames = _extract_frames()
	_write_axe()
	_write_portrait()
	_write_sprite_frames()
	manifest = {
		"schema_version": 1,
		"character": "The Hunter",
		"guardian": 2,
		"location": "Mist Waterfalls",
		"origin": "Original ShadowCraft character/pose/weapon illustrations generated with the built-in OpenAI ImageGen tool using the user-provided Hunter sheet as a style and design reference; no reference-sheet cells or pixels were imported as runtime animation frames.",
		"source_tool": "OpenAI ImageGen built-in; normalized by scripts/enemies/import_the_hunter_art.py",
		"reference_sheet": "assets/enemies/the_hunter/source/concept_reference_user.png",
		"license": "Original proprietary ShadowCraft artwork; user-provided image retained only as a reference",
		"frame_size_px": [FRAME_SIZE, FRAME_SIZE],
		"ground_anchor_y": GROUND_ANCHOR_Y,
		"transparent_background": True,
		"weapon_asset": "assets/weapons/stone_axe/stone_axe.png",
		"portrait_asset": "assets/enemies/the_hunter/portraits/the_hunter_portrait.png",
		"weapon_reuse": "WeaponData and Stone Axe scene keep one shared texture/scene for The Hunter and future Forge use; the axe is never baked into character frame textures.",
		"animations": [{"name": name, "frame_count": len(items), "frames": [f"assets/enemies/the_hunter/frames/{name}/{name}_{index:02d}.png" for index in range(1, len(items) + 1)], "contact_sheet": f"assets/enemies/the_hunter/previews/{name}_contact.png", "durations_at_60_fps": FRAME_DURATIONS.get(name, [])} for name, items in frames.items()],
	}
	(BASE / "asset_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"MANIFEST {BASE.relative_to(ROOT).as_posix()}/asset_manifest.json")
	print(f"SPRITEFRAMES {BASE.relative_to(ROOT).as_posix()}/the_hunter_sprite_frames.tres")


if __name__ == "__main__":
	main()
