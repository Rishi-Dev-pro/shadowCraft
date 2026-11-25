"""Slice and normalize original Combat Phase 2 Step 2 punch sprite sheets.

This focused asset importer writes only the new Cross Punch and Heavy Punch
art packages. It never edits the existing SpriteFrames resources, attack data,
approved art, or character pipelines.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
FRAME_SIZE = 512
ALPHA_THRESHOLD = 24

SHEETS: tuple[dict[str, object], ...] = (
    {
        "character": "kai_v2",
        "animation": "cross_punch",
        "source": "assets/characters/kai_v2/source/combat_phase2_step2/cross_punch_3x2.png",
        "columns": 3,
        "rows": 2,
        "frames": 6,
        "target_height": 480,
        "ground_anchor_y": 496,
        "output": "assets/characters/kai_v2/animations/attacks/cross_punch",
        "preview": "assets/characters/kai_v2/previews/cross_punch_contact.png",
        "phase_map": ["guard", "anticipation", "drive", "contact", "follow_through", "recovery"],
        "description": "Precise rear-hand cross with grounded base, clear torso rotation, contact, follow-through and return to guard.",
    },
    {
        "character": "kai_v2",
        "animation": "heavy_punch",
        "source": "assets/characters/kai_v2/source/combat_phase2_step2/heavy_punch_5x2.png",
        "columns": 5,
        "rows": 2,
        "frames": 10,
        "target_height": 480,
        "ground_anchor_y": 496,
        "output": "assets/characters/kai_v2/animations/attacks/heavy_punch",
        "preview": "assets/characters/kai_v2/previews/heavy_punch_contact.png",
        "phase_map": ["guard", "anticipation", "deep_wind_up", "drive_start", "drive", "contact", "follow_through", "recoil", "recovery", "guard_return"],
        "description": "Committed rear-hand heavy cross with a longer load, leg drive, clear impact, controlled recoil and guarded recovery.",
    },
    {
        "character": "razen",
        "animation": "cross_punch",
        "source": "assets/characters/razen/source/animation_sheets/cross_punch_combat_4x2.png",
        "columns": 4,
        "rows": 2,
        "frames": 8,
        "target_height": 464,
        "ground_anchor_y": 488,
        "output": "assets/characters/razen/animations/cross_punch",
        "preview": "assets/characters/razen/previews/cross_punch_contact.png",
        "phase_map": ["guard", "anticipation", "weight_load", "drive_start", "extension", "contact", "follow_through", "recovery"],
        "description": "Disciplined, powerful cross with planted support, hip rotation, contact, short follow-through and guard recovery.",
    },
    {
        "character": "razen",
        "animation": "heavy_punch",
        "source": "assets/characters/razen/source/animation_sheets/heavy_punch_combat_6x2.png",
        "columns": 6,
        "rows": 2,
        "frames": 12,
        "target_height": 464,
        "ground_anchor_y": 488,
        "output": "assets/characters/razen/animations/heavy_punch",
        "preview": "assets/characters/razen/previews/heavy_punch_contact.png",
        "phase_map": ["guard", "weight_shift", "coil", "deep_wind_up", "drive_start", "extension", "contact", "follow_through", "recoil", "arm_recovery", "weight_settle", "guard_return"],
        "description": "Committed heavy cross with extended anticipation, grounded rear-foot drive, strong hip rotation, readable contact, controlled recoil and balanced return.",
    },
)


def _largest_component(alpha: bytes, width: int, height: int) -> tuple[bytearray, tuple[int, int, int, int]]:
    foreground = bytearray(1 if value > ALPHA_THRESHOLD else 0 for value in alpha)
    visited = bytearray(width * height)
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
        raise ValueError("Frame cell contains no visible character silhouette")

    component = bytearray(width * height)
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


def _normalize_cell(cell: Image.Image, target_height: int, anchor_y: int) -> tuple[Image.Image, dict[str, int]]:
    rgba = cell.convert("RGBA")
    width, height = rgba.size
    original_alpha = rgba.getchannel("A")
    component, bounds = _largest_component(original_alpha.tobytes(), width, height)
    mask = Image.frombytes("L", (width, height), bytes(255 if value else 0 for value in component))
    expanded = mask.filter(ImageFilter.MaxFilter(3))
    rgba.putalpha(Image.composite(original_alpha, Image.new("L", (width, height), 0), expanded))

    left, top, right, bottom = bounds
    content = rgba.crop((left, top, right, bottom))
    fit_scale = min(target_height / content.height, (FRAME_SIZE - 24) / content.width)
    fitted_width = max(1, round(content.width * fit_scale))
    fitted_height = max(1, round(content.height * fit_scale))
    content = content.resize((fitted_width, fitted_height), Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    destination = ((FRAME_SIZE - fitted_width) // 2, anchor_y - fitted_height)
    if destination[1] < 0:
        raise ValueError("Normalized frame would clip the character above the canvas")
    frame.alpha_composite(content, destination)
    visible = frame.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0).getbbox()
    if visible is None:
        raise ValueError("Normalized frame contains no visible character pixels")
    # Lanczos can leave a final resampled edge row below the alpha cutoff.
    # Align the actual visible silhouette, rather than the source crop's
    # threshold bounds, to the established character ground anchor.
    anchor_delta = anchor_y - visible[3]
    if visible[1] + anchor_delta < 0 or visible[3] + anchor_delta > FRAME_SIZE:
        raise ValueError("Visible character silhouette cannot fit at the requested ground anchor")
    if anchor_delta:
        anchored = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        anchored.alpha_composite(frame, (0, anchor_delta))
        frame = anchored
    visible = frame.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0).getbbox()
    if visible is None or visible[3] != anchor_y:
        raise ValueError("Normalized frame failed its ground-anchor check")
    return frame, {"source_width": width, "source_height": height, "target_width": fitted_width, "target_height": fitted_height}


def _write_preview(frames: list[Image.Image], columns: int, rows: int, path: Path) -> None:
    tile_size = 256
    sheet = Image.new("RGBA", (columns * tile_size, rows * tile_size), (24, 20, 29, 255))
    for index, frame in enumerate(frames):
        tile = frame.resize((tile_size, tile_size), Image.Resampling.LANCZOS)
        sheet.alpha_composite(tile, ((index % columns) * tile_size, (index // columns) * tile_size))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(path, quality=95)


def main() -> None:
    grouped: dict[str, list[dict[str, object]]] = {"kai_v2": [], "razen": []}
    for spec in SHEETS:
        source_path = ROOT / str(spec["source"])
        if not source_path.is_file():
            raise FileNotFoundError(source_path)
        source = Image.open(source_path).convert("RGBA")
        columns = int(spec["columns"])
        rows = int(spec["rows"])
        count = int(spec["frames"])
        if columns * rows != count:
            raise ValueError(f"Grid does not match frame count for {spec['animation']}")

        output_dir = ROOT / str(spec["output"])
        output_dir.mkdir(parents=True, exist_ok=True)
        paths: list[str] = []
        frames: list[Image.Image] = []
        for index in range(count):
            column = index % columns
            row = index // columns
            x0 = round(column * source.width / columns)
            x1 = round((column + 1) * source.width / columns)
            y0 = round(row * source.height / rows)
            y1 = round((row + 1) * source.height / rows)
            frame, fit = _normalize_cell(
                source.crop((x0, y0, x1, y1)),
                int(spec["target_height"]),
                int(spec["ground_anchor_y"]),
            )
            filename = f"{spec['animation']}_{index + 1:02d}.png"
            destination = output_dir / filename
            frame.save(destination, "PNG", optimize=True)
            paths.append(destination.relative_to(ROOT).as_posix())
            frames.append(frame)
            print(f"{spec['character']} {spec['animation']} {index + 1:02d}: {fit['target_width']}x{fit['target_height']} -> {paths[-1]}")

        preview_path = ROOT / str(spec["preview"])
        _write_preview(frames, columns, rows, preview_path)
        grouped[str(spec["character"])].append({
            "name": spec["animation"],
            "source_sheet": str(spec["source"]).replace("\\", "/"),
            "source_dimensions_px": list(source.size),
            "source_grid": [columns, rows],
            "frame_count": count,
            "frame_dimensions_px": [FRAME_SIZE, FRAME_SIZE],
            "format": "RGBA PNG",
            "transparent_background": True,
            "ground_anchor_y": int(spec["ground_anchor_y"]),
            "target_character_height_px": int(spec["target_height"]),
            "phase_map": spec["phase_map"],
            "description": spec["description"],
            "frame_paths": paths,
            "contact_sheet": str(spec["preview"]).replace("\\", "/"),
        })

    provenance = {
        "schema_version": 1,
        "asset_scope": "Combat Phase 2 Step 2 artwork only; not integrated into SpriteFrames or AttackData",
        "source_tool": "OpenAI ImageGen built-in",
        "generation_date": "2026-11-11",
        "reference_policy": "User-provided Combat Animation Sprite Sheet was used for pose rhythm and style guidance only; no reference pixels were cropped or reused. Character identity references were used only to preserve the approved Kai V2 and Razen designs. All new animation poses were generated as original artwork.",
        "normalization": "Row-major cell slicing; detached low-area components removed by keeping the largest alpha-connected silhouette; whole character cell uniformly fitted to established character height; anchored to character-specific ground baseline; transparent RGBA 512x512 frames.",
        "characters": grouped,
    }
    for character_id in ("kai_v2", "razen"):
        manifest_path = ROOT / "assets" / "characters" / character_id / "combat_phase2_step2_art_manifest.json"
        manifest_path.write_text(json.dumps({**provenance, "character": character_id, "animations": grouped[character_id]}, indent=2) + "\n", encoding="utf-8")
        print(f"MANIFEST {manifest_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
