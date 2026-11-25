"""Extract and floor-align the four approved Raezan guard poses."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/characters/raezan_boss/source/batches/guard_refinement/guard_refinement_2x2.png"
OUTPUT_DIR = ROOT / "assets/characters/raezan_boss/frames/guard_refinement"
PREVIEW = ROOT / "assets/characters/raezan_boss/previews/guard_refinement_contact.png"
FRAME_SIZE = 512
TARGET_GROUND_Y = 491
TARGET_CHARACTER_HEIGHT = 434


def _core_bbox(alpha: Image.Image) -> tuple[int, int, int, int]:
    """Ignore low-alpha edge haze when aligning the solid character silhouette."""
    mask = alpha.point(lambda value: 255 if value > 32 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Guard cell has no visible character pixels")
    return bounds


def build() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    if source.width != source.height or source.width % 2 != 0:
        raise ValueError(f"Expected an even square 2x2 sheet, found {source.size}")

    cell_size = source.width // 2
    cells = [
        source.crop((column * cell_size, row * cell_size, (column + 1) * cell_size, (row + 1) * cell_size))
        for row in range(2)
        for column in range(2)
    ]
    core_bounds = [_core_bbox(cell.getchannel("A")) for cell in cells]
    core_heights = [bottom - top for _, top, _, bottom in core_bounds]
    common_scale = TARGET_CHARACTER_HEIGHT / (sum(core_heights) / len(core_heights))
    resized_size = round(cell_size * common_scale)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview = Image.new("RGBA", (FRAME_SIZE * 2, FRAME_SIZE * 2), (20, 14, 30, 255))

    for index, (cell, bounds) in enumerate(zip(cells, core_bounds, strict=True), start=1):
        left, top, right, bottom = bounds
        cell_left_margin = left
        cell_top_margin = top
        cell_right_margin = cell_size - right
        cell_bottom_margin = cell_size - bottom
        if min(cell_left_margin, cell_top_margin, cell_right_margin, cell_bottom_margin) < 2:
            raise ValueError(f"Guard pose {index} is cropped at its cell edge: {bounds}")

        resized = cell.resize((resized_size, resized_size), Image.Resampling.LANCZOS)
        core_center_x = ((left + right) * 0.5) * common_scale
        core_bottom_y = bottom * common_scale
        offset_x = round(FRAME_SIZE * 0.5 - core_center_x)
        offset_y = round(TARGET_GROUND_Y - core_bottom_y)

        frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        frame.alpha_composite(resized, (offset_x, offset_y))
        frame_path = OUTPUT_DIR / f"guard_refinement_{index:02d}.png"
        frame.save(frame_path, optimize=True)

        preview_x = ((index - 1) % 2) * FRAME_SIZE
        preview_y = ((index - 1) // 2) * FRAME_SIZE
        preview.alpha_composite(frame, (preview_x, preview_y))

    preview.save(PREVIEW, optimize=True)
    print(f"Extracted 4 aligned 512x512 guard poses to {OUTPUT_DIR.relative_to(ROOT)}")
    print(f"Wrote contact sheet {PREVIEW.relative_to(ROOT)}")


if __name__ == "__main__":
    build()
