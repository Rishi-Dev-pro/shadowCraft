"""Import the two user-selected Raezan Phase 2 action sheets as runtime frames.

The source PNGs remain untouched. Each regular sheet cell is uniformly resized
to 512x512 and bottom-aligned to Raezan's established ground line.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "assets/characters/raezan_boss"
SOURCE = PACKAGE / "source/batches/batch_08_selected"
FRAMES = PACKAGE / "frames"
PREVIEWS = PACKAGE / "previews"
MANIFEST = PACKAGE / "production_manifest.json"
FRAME_SIZE = 512
GROUND_LINE_Y = 491
SHEETS = (
    ("phase2_finisher", "phase2_finisher_selected.png", 4, 4),
    ("phase2_void_burst", "phase2_void_burst_selected.png", 5, 4),
)


def _bottom_align(frame: Image.Image) -> Image.Image:
    alpha = frame.getchannel("A").point(lambda value: 255 if value > 16 else 0)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Selected frame contains no visible pixels")
    offset_y = GROUND_LINE_Y - bounds[3]
    result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    source_y0 = max(0, -offset_y)
    target_y0 = max(0, offset_y)
    copy_height = min(FRAME_SIZE - source_y0, FRAME_SIZE - target_y0)
    if copy_height > 0:
        result.alpha_composite(
            frame.crop((0, source_y0, FRAME_SIZE, source_y0 + copy_height)),
            (0, target_y0),
        )
    return result


def _write_contact_sheet(name: str, frames: list[Image.Image]) -> None:
    columns = 4
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * FRAME_SIZE, rows * FRAME_SIZE), (23, 18, 30, 255))
    draw = ImageDraw.Draw(sheet)
    for index, frame in enumerate(frames):
        x = (index % columns) * FRAME_SIZE
        y = (index // columns) * FRAME_SIZE
        sheet.alpha_composite(frame, (x, y))
        draw.text((x + 8, y + 8), f"{index + 1:02d}", fill=(245, 225, 255, 255))
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(PREVIEWS / f"{name}_contact.png", quality=95)


def _extract(name: str, filename: str, columns: int, rows: int) -> int:
    source_path = SOURCE / filename
    sheet = Image.open(source_path).convert("RGBA")
    output_dir = FRAMES / name
    output_dir.mkdir(parents=True, exist_ok=True)
    frames: list[Image.Image] = []

    for index in range(columns * rows):
        column = index % columns
        row = index // columns
        x0 = round(column * sheet.width / columns)
        x1 = round((column + 1) * sheet.width / columns)
        y0 = round(row * sheet.height / rows)
        y1 = round((row + 1) * sheet.height / rows)
        cell = sheet.crop((x0, y0, x1, y1))
        frame = cell.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.LANCZOS)
        frame = _bottom_align(frame)
        output_path = output_dir / f"{name}_{index + 1:02d}.png"
        frame.save(output_path, "PNG", optimize=True)
        frames.append(frame)

    if len({frame.tobytes() for frame in frames}) != len(frames):
        raise ValueError(f"{name} contains duplicate extracted frames")
    _write_contact_sheet(name, frames)
    print(f"{name}: imported {len(frames)} frames from {source_path.relative_to(ROOT)}")
    return len(frames)


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    imported: dict[str, int] = {}
    for name, filename, columns, rows in SHEETS:
        imported[name] = _extract(name, filename, columns, rows)
    selections: list[dict[str, object]] = manifest.setdefault("selected_replacements", [])
    selections[:] = [
        entry for entry in selections
        if entry.get("source_directory") != "source/batches/batch_08_selected/"
    ]
    selections.append(
        {
            "batch": 8,
            "selection": "User-selected previously generated Phase 2 sheets",
            "pipeline": "Frame-based SpriteFrames; originals preserved",
            "source_directory": "source/batches/batch_08_selected/",
            "animations": imported,
            "frame_size_px": [FRAME_SIZE, FRAME_SIZE],
            "ground_line_y": GROUND_LINE_Y,
            "alpha": "Original RGBA alpha retained; no chroma key or edge removal",
        }
    )
    manifest["total_frames"] = int(manifest.get("total_frames", 0))
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
