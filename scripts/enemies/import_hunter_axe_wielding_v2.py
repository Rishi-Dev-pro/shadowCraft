"""Extract and normalize the axe-wielding Hunter animation sheets."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets" / "enemies" / "the_hunter"
SOURCE = BASE / "source" / "axe_wielding_v2"
OUTPUT = BASE / "frames_axe_wielding_v2"
PREVIEWS = BASE / "previews" / "axe_wielding_v2"
FRAME_SIZE = 512
GROUND_Y = 496
ALPHA_CUTOFF = 48

SHEETS: dict[str, tuple[str, int, int, int]] = {
	"idle": ("idle_sheet.png", 4, 2, 8),
	"walk": ("walk_forward_sheet.png", 4, 2, 8),
	"walk_backward": ("walk_backward_sheet.png", 4, 2, 8),
	"light_axe": ("light_axe_sheet.png", 3, 2, 6),
	"heavy_axe": ("heavy_axe_sheet.png", 4, 2, 8),
	"axe_sweep": ("axe_sweep_sheet.png", 4, 2, 8),
	"spin_axe": ("spin_axe_sheet.png", 5, 2, 10),
	"guard": ("guard_sheet.png", 2, 2, 4),
	"hit": ("hit_sheet.png", 3, 2, 6),
	"death": ("ko_sheet.png", 4, 2, 8),
}

DURATIONS: dict[str, list[int]] = {
	"death": [1] * 36 + [12],  # Let the grounded pose read before the K.O. overlay.
	# Duration units run at 60 fps, matching the existing AttackData frame windows.
	"light_axe": [5, 7, 8, 3, 10, 25],
	"heavy_axe": [5, 7, 9, 7, 8, 4, 12, 26],
	"axe_sweep": [7, 9, 8, 8, 4, 10, 10, 17],
	"spin_axe": [5, 7, 9, 10, 8, 8, 9, 9, 8, 13],
}


def largest_component(image: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
	"""Retain the principal connected Hunter-and-weapon cutout and its soft edge."""
	rgba = image.convert("RGBA")
	alpha = rgba.getchannel("A")
	width, height = rgba.size
	alpha_bytes = alpha.tobytes()
	mask = bytearray(1 if value > ALPHA_CUTOFF else 0 for value in alpha_bytes)
	visited = bytearray(width * height)
	best: list[int] = []
	for seed, enabled in enumerate(mask):
		if not enabled or visited[seed]:
			continue
		visited[seed] = 1
		stack = [seed]
		component: list[int] = []
		while stack:
			index = stack.pop()
			component.append(index)
			x, y = index % width, index // width
			for ny in range(max(0, y - 1), min(height, y + 2)):
				for nx in range(max(0, x - 1), min(width, x + 2)):
					neighbor = ny * width + nx
					if mask[neighbor] and not visited[neighbor]:
						visited[neighbor] = 1
						stack.append(neighbor)
		if len(component) > len(best):
			best = component
	if not best:
		raise ValueError("No visible Hunter silhouette found in sprite cell")
	component_mask = bytearray(width * height)
	for index in best:
		component_mask[index] = 255
	mask_image = Image.frombytes("L", (width, height), bytes(component_mask))
	# A small dilation keeps fine hair, scarf and weapon antialiasing while cutting haze.
	soft_mask = mask_image.filter(ImageFilter.MaxFilter(5))
	clean_alpha = Image.composite(alpha, Image.new("L", (width, height), 0), soft_mask)
	rgba.putalpha(clean_alpha)
	return rgba, mask_image.getbbox()


def crop_cell(sheet: Image.Image, columns: int, rows: int, index: int) -> Image.Image:
	column, row = index % columns, index // columns
	x0, x1 = round(column * sheet.width / columns), round((column + 1) * sheet.width / columns)
	y0, y1 = round(row * sheet.height / rows), round((row + 1) * sheet.height / rows)
	return sheet.crop((x0, y0, x1, y1))


def normalize_cell(cell: Image.Image) -> Image.Image:
	"""Scale the entire square-ish source cell uniformly, then anchor the actor to floor."""
	width, height = cell.size
	scale = min(FRAME_SIZE / width, FRAME_SIZE / height)
	new_size = (max(1, round(width * scale)), max(1, round(height * scale)))
	resized = cell.resize(new_size, Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
	canvas.alpha_composite(resized, ((FRAME_SIZE - new_size[0]) // 2, (FRAME_SIZE - new_size[1]) // 2))
	content, bounds = largest_component(canvas)
	# Place the lowest actual silhouette pixels on one shared floor line; preserve its scale.
	x0, y0, x1, y1 = bounds
	shift_y = GROUND_Y - y1
	frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
	frame.alpha_composite(content, (0, shift_y))
	return frame


def write_contact_sheet(frames: list[Image.Image], destination: Path) -> None:
	columns = min(5, len(frames))
	rows = (len(frames) + columns - 1) // columns
	tile = 256
	sheet = Image.new("RGBA", (columns * tile, rows * tile), (27, 22, 39, 255))
	draw = ImageDraw.Draw(sheet)
	for index, frame in enumerate(frames):
		x, y = (index % columns) * tile, (index // columns) * tile
		sheet.alpha_composite(frame.resize((tile, tile), Image.Resampling.LANCZOS), (x, y))
		draw.rectangle((x, y, x + tile - 1, y + tile - 1), outline=(106, 76, 139, 255), width=1)
	destination.parent.mkdir(parents=True, exist_ok=True)
	sheet.convert("RGB").save(destination, quality=95)


def write_sprite_frames(animation_frames: dict[str, list[Path]]) -> Path:
	speeds: dict[str, float] = {
		"idle": 6.0, "walk": 9.0, "walk_backward": 9.0,
		"light_axe": 60.0, "heavy_axe": 60.0, "axe_sweep": 60.0,
		"spin_axe": 60.0, "guard": 8.0, "hit": 18.0, "death": 30.0,
	}
	looped = {"idle", "walk", "walk_backward", "guard"}
	kneel = sorted((BASE / "kneeling_defeat").glob("kneel_*.png"))
	if len(kneel) != 37:
		raise ValueError("Hunter defeat requires the 37-frame skeletal kneel bake")
	animation_frames = {**animation_frames, "death": kneel}
	paths = [path for frames in animation_frames.values() for path in frames]
	ids = {path: f"tex_{index + 1}" for index, path in enumerate(paths)}
	lines = [f'[gd_resource type="SpriteFrames" load_steps={len(paths) + 1} format=3]', ""]
	for path, resource_id in ids.items():
		relative = path.relative_to(ROOT).as_posix()
		lines.append(f'[ext_resource type="Texture2D" path="res://{relative}" id="{resource_id}"]')
	lines.extend(["", "[resource]", "animations = ["])
	for animation_index, (name, frames) in enumerate(animation_frames.items()):
		lines.append("}, {" if animation_index else "{")
		lines.append('"frames": [')
		durations = DURATIONS.get(name, [1] * len(frames))
		for frame_index, path in enumerate(frames):
			lines.append("}, {" if frame_index else "{")
			lines.append(f'"duration": {float(durations[frame_index]):.1f},')
			lines.append(f'"texture": ExtResource("{ids[path]}")')
		lines.append("}],")
		lines.append(f'"loop": {1 if name in looped else 0},')
		lines.append(f'"name": &"{name}",')
		lines.append(f'"speed": {speeds[name]:.1f}')
	lines.append("}")
	lines.append("]")
	destination = BASE / "the_hunter_axe_wielding_v2_sprite_frames.tres"
	destination.write_text("\n".join(lines) + "\n", encoding="utf-8")
	return destination


def main() -> None:
	OUTPUT.mkdir(parents=True, exist_ok=True)
	all_frames: dict[str, list[Path]] = {}
	manifest_animations: list[dict[str, object]] = []
	for animation, (filename, columns, rows, count) in SHEETS.items():
		sheet_path = SOURCE / filename
		if not sheet_path.is_file():
			raise FileNotFoundError(sheet_path)
		sheet = Image.open(sheet_path).convert("RGBA")
		if columns * rows != count:
			raise ValueError(f"Invalid grid metadata for {animation}")
		frames: list[Image.Image] = []
		paths: list[Path] = []
		for index in range(count):
			frame = normalize_cell(crop_cell(sheet, columns, rows, index))
			if frame.size != (FRAME_SIZE, FRAME_SIZE) or frame.getchannel("A").getbbox() is None:
				raise ValueError(f"Invalid transparent frame {animation} {index + 1}")
			destination = OUTPUT / animation / f"{animation}_{index + 1:02d}.png"
			destination.parent.mkdir(parents=True, exist_ok=True)
			frame.save(destination, "PNG", optimize=True)
			frames.append(frame)
			paths.append(destination)
		all_frames[animation] = paths
		preview = PREVIEWS / f"{animation}_contact.png"
		write_contact_sheet(frames, preview)
		manifest_animations.append({
			"name": animation,
			"frame_count": count,
			"source_sheet": sheet_path.relative_to(ROOT).as_posix(),
			"frames": [path.relative_to(ROOT).as_posix() for path in paths],
			"contact_sheet": preview.relative_to(ROOT).as_posix(),
		})
	sprite_frames = write_sprite_frames(all_frames)
	manifest = {
		"schema_version": 1,
		"character": "The Hunter",
		"package": "axe_wielding_v2",
		"source_tool": "OpenAI Codex built-in image generation; no EvoLink requests used",
		"reference_character": "assets/enemies/the_hunter/frames/idle/idle_01.png",
		"canonical_weapon": "assets/weapons/stone_axe/stone_axe.png",
		"canonical_weapon_preserved": True,
		"frame_size_px": [FRAME_SIZE, FRAME_SIZE],
		"ground_anchor_y": GROUND_Y,
		"transparent_background": True,
		"source_processing": "Cell crop, alpha-connected silhouette isolation, uniform cell scaling, shared floor anchoring; original source sheets retained.",
		"sprite_frames": sprite_frames.relative_to(ROOT).as_posix(),
		"animations": manifest_animations,
	}
	manifest_path = SOURCE / "manifest.json"
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"Generated {sum(len(frames) for frames in all_frames.values())} frames")
	print(f"SpriteFrames: {sprite_frames.relative_to(ROOT).as_posix()}")
	print(f"Manifest: {manifest_path.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
	main()
