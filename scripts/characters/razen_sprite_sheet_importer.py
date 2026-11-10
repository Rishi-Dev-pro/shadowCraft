"""Normalize Razen's generated source sheets into fixed-anchor PNG frames.

Uses Pillow only. The approved signature artwork is restored verbatim as the
ready state and as the clean endpoint of presentation clips.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PACKAGE_ROOT = PROJECT_ROOT / "assets" / "characters" / "razen"
SOURCE_ROOT = PACKAGE_ROOT / "source" / "animation_sheets"
OUTPUT_ROOT = PACKAGE_ROOT / "animations"
PREVIEW_ROOT = PACKAGE_ROOT / "previews"
SIGNATURE_PATH = PACKAGE_ROOT / "poses" / "signature_ready.png"
MANIFEST_PATH = PACKAGE_ROOT / "animation_manifest.json"
FRAME_SIZE = 512
GROUND_ANCHOR_Y = 488
ALPHA_THRESHOLD = 16


SHEETS: dict[str, dict[str, object]] = {
    "idle_signature": {
        "sheet": "idle_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 6.0, "loop": True, "anchor": "ground",
    },
    "walk_forward": {
        "sheet": "walk_forward_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 9.0, "loop": True, "anchor": "ground",
    },
    "walk_backward": {
        "sheet": "walk_backward_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 9.0, "loop": True, "anchor": "ground",
    },
    "run": {
        "sheet": "run_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 12.0, "loop": True,
        "anchor_y": [GROUND_ANCHOR_Y, GROUND_ANCHOR_Y, 464, 464,
                     GROUND_ANCHOR_Y, GROUND_ANCHOR_Y, 464, 464],
    },
    "crouch": {
        "sheet": "crouch_2x2.png", "columns": 2, "rows": 2, "count": 4,
        "fps": 6.0, "loop": True, "anchor": "ground",
    },
    "crouch_walk": {
        "sheet": "crouch_walk_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 8.0, "loop": True, "anchor": "ground",
    },
    "jump": {
        "sheet": "jump_2x2.png", "columns": 2, "rows": 2, "count": 4,
        "fps": 10.0, "loop": False,
        "anchor_y": [GROUND_ANCHOR_Y, 466, 446, GROUND_ANCHOR_Y],
    },
    "landing": {
        "sheet": "landing_2x2.png", "columns": 2, "rows": 2, "count": 4,
        "fps": 14.0, "loop": False, "anchor": "ground",
    },
    "attack_presentation": {
        "sheet": "attack_presentation_2x2.png", "columns": 2, "rows": 2, "count": 4,
        "fps": 10.0, "loop": False, "anchor": "ground",
    },
    "light_jab": {
        "sheet": "light_jab_combat_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 30.0, "loop": False, "anchor": "ground", "remove_near_white_background": True,
    },
    "front_kick": {
        "sheet": "front_kick_combat_4x2.png", "columns": 4, "rows": 2, "count": 8,
        "fps": 30.0, "loop": False, "anchor": "ground", "remove_near_white_background": True,
    },
}


def _largest_component(alpha: bytes, width: int, height: int) -> tuple[bytearray, tuple[int, int, int, int]]:
    """Return a mask and bounds for the largest alpha>threshold component."""
    pixel_count = width * height
    foreground = bytearray(pixel_count)
    for index, value in enumerate(alpha):
        if value > ALPHA_THRESHOLD:
            foreground[index] = 1

    visited = bytearray(pixel_count)
    best_seed = -1
    best_area = 0
    best_bounds = (0, 0, width, height)

    for seed, enabled in enumerate(foreground):
        if not enabled or visited[seed]:
            continue
        visited[seed] = 1
        stack = [seed]
        area = 0
        min_x = width
        min_y = height
        max_x = -1
        max_y = -1
        while stack:
            index = stack.pop()
            x = index % width
            y = index // width
            area += 1
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            for neighbor_y in range(max(0, y - 1), min(height, y + 2)):
                row_offset = neighbor_y * width
                for neighbor_x in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = row_offset + neighbor_x
                    if foreground[neighbor] and not visited[neighbor]:
                        visited[neighbor] = 1
                        stack.append(neighbor)
        if area > best_area:
            best_seed = seed
            best_area = area
            best_bounds = (min_x, min_y, max_x + 1, max_y + 1)

    if best_seed < 0:
        raise ValueError("No character silhouette found in sprite cell")

    component = bytearray(pixel_count)
    component[best_seed] = 1
    stack = [best_seed]
    while stack:
        index = stack.pop()
        x = index % width
        y = index // width
        for neighbor_y in range(max(0, y - 1), min(height, y + 2)):
            row_offset = neighbor_y * width
            for neighbor_x in range(max(0, x - 1), min(width, x + 2)):
                neighbor = row_offset + neighbor_x
                if foreground[neighbor] and not component[neighbor]:
                    component[neighbor] = 1
                    stack.append(neighbor)
    return component, best_bounds


def _remove_edge_connected_white_background(image: Image.Image) -> None:
    """Remove near-white pixels only where connected to the cell boundary."""
    width, height = image.size
    pixels = image.load()
    visited = bytearray(width * height)
    stack: list[int] = []

    def is_background(x: int, y: int) -> bool:
        red, green, blue, _alpha = pixels[x, y]
        return min(red, green, blue) >= 235 and max(red, green, blue) - min(red, green, blue) <= 20

    for x in range(width):
        stack.append(x)
        stack.append((height - 1) * width + x)
    for y in range(height):
        stack.append(y * width)
        stack.append(y * width + width - 1)

    while stack:
        index = stack.pop()
        if visited[index]:
            continue
        visited[index] = 1
        x = index % width
        y = index // width
        if not is_background(x, y):
            continue
        red, green, blue, _alpha = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        for neighbor_y in range(max(0, y - 1), min(height, y + 2)):
            for neighbor_x in range(max(0, x - 1), min(width, x + 2)):
                neighbor = neighbor_y * width + neighbor_x
                if not visited[neighbor]:
                    stack.append(neighbor)


def _clean_cell(cell: Image.Image, anchor_y: int | None, remove_white_background: bool = False) -> Image.Image:
    rgba = cell.convert("RGBA")
    if remove_white_background:
        _remove_edge_connected_white_background(rgba)
    original_alpha = rgba.getchannel("A")
    component, bounds = _largest_component(original_alpha.tobytes(), *rgba.size)
    component_image = Image.frombytes("L", rgba.size, bytes(255 if value else 0 for value in component))
    expanded = component_image.filter(ImageFilter.MaxFilter(3))
    clean_alpha = Image.composite(original_alpha, Image.new("L", rgba.size, 0), expanded)
    rgba.putalpha(clean_alpha)

    # Cells have a shared camera and frame center. Resize the full cell uniformly so
    # pose scale is stable; never scale/stretch body parts independently.
    frame = rgba.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.LANCZOS)
    if anchor_y is not None:
        frame_alpha = frame.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
        frame_bounds = frame_alpha.getbbox()
        if frame_bounds is None:
            raise ValueError("Normalized frame unexpectedly has no character pixels")
        offset_y = anchor_y - frame_bounds[3]
        translated = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        translated.alpha_composite(frame, (0, offset_y))
        frame = translated
    return frame


def _write_contact_sheet(animation_name: str, frame_paths: list[str]) -> None:
    columns = 4
    rows = (len(frame_paths) + columns - 1) // columns
    background = Image.new("RGBA", (columns * FRAME_SIZE, rows * FRAME_SIZE), (24, 20, 24, 255))
    for frame_index, relative_path in enumerate(frame_paths):
        frame = Image.open(PACKAGE_ROOT / relative_path).convert("RGBA")
        x = (frame_index % columns) * FRAME_SIZE
        y = (frame_index // columns) * FRAME_SIZE
        background.alpha_composite(frame, (x, y))
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    background.convert("RGB").save(PREVIEW_ROOT / f"{animation_name}_contact.png", quality=95)


def main() -> None:
    signature = Image.open(SIGNATURE_PATH).convert("RGBA")
    if signature.size != (FRAME_SIZE, FRAME_SIZE):
        raise ValueError("Approved signature pose must remain 512x512")
    manifest: dict[str, object] = {
        "frame_size": [FRAME_SIZE, FRAME_SIZE],
        "ground_anchor_y": GROUND_ANCHOR_Y,
        "source_tool": "OpenAI ImageGen built-in; generated 2026-11-10 from the approved signature sprite",
        "provenance": "Each animation source sheet is an original generation guided by the approved Razen identity and the user's reference. The supplied reference sheet was not cropped or sampled as sprite art. Frame cells are isolated, stray disconnected background pixels are masked, and whole cells are uniformly resized; no body parts are warped.",
        "animations": {},
    }

    animations: dict[str, dict[str, object]] = manifest["animations"]  # type: ignore[assignment]
    for animation_name, spec in SHEETS.items():
        sheet_path = SOURCE_ROOT / str(spec["sheet"])
        if not sheet_path.is_file():
            raise FileNotFoundError(sheet_path)
        sheet = Image.open(sheet_path).convert("RGBA")
        columns = int(spec["columns"])
        rows = int(spec["rows"])
        count = int(spec["count"])
        if columns * rows != count:
            raise ValueError(f"Grid/frame count mismatch for {animation_name}")

        output_directory = OUTPUT_ROOT / animation_name
        output_directory.mkdir(parents=True, exist_ok=True)
        frame_paths: list[str] = []
        anchors: list[int | None]
        if isinstance(spec.get("anchor_y"), list):
            anchors = [int(value) for value in spec["anchor_y"]]
        elif spec.get("anchor") == "ground":
            anchors = [GROUND_ANCHOR_Y] * count
        else:
            anchors = [None] * count

        for frame_index in range(count):
            if ((animation_name == "idle_signature" and frame_index == 0)
                    or (animation_name == "landing" and frame_index == count - 1)
                    or (animation_name == "attack_presentation" and frame_index in (0, count - 1))):
                frame = signature.copy()
            else:
                x0 = round((frame_index % columns) * sheet.width / columns)
                x1 = round(((frame_index % columns) + 1) * sheet.width / columns)
                y0 = round((frame_index // columns) * sheet.height / rows)
                y1 = round(((frame_index // columns) + 1) * sheet.height / rows)
                cell = sheet.crop((x0, y0, x1, y1))
                frame = _clean_cell(cell, anchors[frame_index], bool(spec.get("remove_near_white_background", False)))

            frame_filename = f"{animation_name}_{frame_index + 1:02d}.png"
            frame_path = output_directory / frame_filename
            frame.save(frame_path, "PNG", optimize=True)
            frame_paths.append(frame_path.relative_to(PACKAGE_ROOT).as_posix())

        animations[animation_name] = {
            "source_sheet": f"source/animation_sheets/{spec['sheet']}",
            "source_dimensions_px": [sheet.width, sheet.height],
            "source_grid": [columns, rows],
            "frame_count": count,
            "frame_dimensions_px": [FRAME_SIZE, FRAME_SIZE],
            "format": "RGBA PNG",
            "transparent_background": True,
            "anchor_policy": "per-frame authored vertical anchor" if isinstance(spec.get("anchor_y"), list) else "sole baseline y=488",
            "background_cleanup": "edge-connected near-white color key plus isolated-pixel mask" if spec.get("remove_near_white_background", False) else "low-alpha isolated-pixel mask",
            "fps": float(spec["fps"]),
            "loop": bool(spec["loop"]),
            "frame_paths": frame_paths,
        }
        _write_contact_sheet(animation_name, frame_paths)
        print(f"{animation_name}: {count} frames -> {output_directory.relative_to(PACKAGE_ROOT)}")

    animations["combat_ready"] = {
        "source_sheet": "poses/signature_ready.png",
        "frame_count": 1,
        "fps": 1.0,
        "loop": False,
        "frame_paths": ["poses/signature_ready.png"],
    }
    animations["attack_presentation"]["presentation_only"] = True
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote animation manifest: {MANIFEST_PATH.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
