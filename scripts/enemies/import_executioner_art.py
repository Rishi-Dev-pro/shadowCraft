from __future__ import annotations

import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/characters/the_executioner/source/concept_and_sheets"
FRAME_ROOT = ROOT / "assets/characters/the_executioner/frames"
PREVIEW_ROOT = ROOT / "assets/characters/the_executioner/previews"
CELL_SIZE = 512
TARGET_HEIGHT = 438
GROUND_Y = 491

# (animation, source sheet, columns, rows, count, fps, loop)
SPECS = [
    ("idle", "idle_sheet_replacement.png", 4, 4, 16, 8.0, True),
    ("walk_forward", "walk_forward_sheet.png", 4, 4, 16, 12.0, True),
    ("walk_backward", "walk_backward_sheet.png", 4, 4, 16, 12.0, True),
    ("light_slash", "light_slash_sheet.png", 4, 4, 16, 18.0, False),
    ("heavy_overhead_slash", "heavy_slash_sheet.png", 5, 4, 20, 18.0, False),
    ("horizontal_slash", "horizontal_slash_sheet.png", 4, 4, 16, 18.0, False),
    ("dash_attack", "dash_attack_sheet.png", 5, 4, 20, 18.0, False),
    ("guard", "guard_sheet.png", 4, 3, 12, 8.0, True),
    ("high_guard", "high_guard_sheet.png", 4, 3, 12, 8.0, True),
    ("parry", "parry_sheet.png", 4, 4, 16, 20.0, False),
    ("counterattack", "counterattack_sheet.png", 5, 4, 20, 18.0, False),
    ("hit_reaction", "hit_reaction_sheet.png", 4, 3, 12, 14.0, False),
    ("ko", "ko_sheet.png", 4, 4, 16, 12.0, False),
    ("combo_hit_one", "combo_hit_one_sheet.png", 5, 2, 10, 20.0, False),
    ("combo_hit_two", "combo_hit_two_sheet.png", 5, 2, 10, 20.0, False),
    ("combo_hit_three", "combo_hit_three_sheet.png", 5, 2, 10, 20.0, False),
]


def split_cell(image: Image.Image, index: int, columns: int, rows: int) -> Image.Image:
    column = index % columns
    row = index // columns
    left = round(column * image.width / columns)
    right = round((column + 1) * image.width / columns)
    top = round(row * image.height / rows)
    bottom = round((row + 1) * image.height / rows)
    return image.crop((left, top, right, bottom))


def has_white_matte_background(array: np.ndarray) -> bool:
    rgb = array[:, :, :3].astype(np.int16)
    alpha = array[:, :, 3]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    partial = (alpha > 0) & (alpha < 236)
    if not np.any(partial):
        return False
    near_white = partial & (rgb.min(axis=2) > 220) & (chroma < 34)
    return float(np.count_nonzero(near_white)) / float(np.count_nonzero(partial)) > 0.7


def remove_light_matte(array: np.ndarray, white_matted: bool) -> np.ndarray:
    # The generated pose sheets contain a pale semi-transparent fringe around
    # the otherwise transparent character cutouts. Remove only near-neutral
    # bright edge pixels with partial alpha; keep opaque silver hair, mask and
    # sword highlights intact.
    rgb = array[:, :, :3].astype(np.int16)
    alpha = array[:, :, 3]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    background = (alpha < 236) & (rgb.min(axis=2) > 220) & (chroma < 34)
    array[background, 3] = 0
    if white_matted:
        # Recover colors from a white-composited source sheet before scaling.
        alpha = array[:, :, 3]
        partial_foreground = (alpha >= 18) & (alpha < 255)
        opacity = alpha[partial_foreground].astype(np.float32) / 255.0
        observed = array[:, :, :3][partial_foreground].astype(np.float32)
        recovered = (observed - ((1.0 - opacity)[:, None] * 255.0)) / opacity[:, None]
        array[:, :, :3][partial_foreground] = np.clip(np.rint(recovered), 0, 255).astype(np.uint8)
    array[array[:, :, 3] < 18, 3] = 0
    return array


def keep_largest_component(array: np.ndarray) -> np.ndarray:
    """Remove detached pose-sheet spill while preserving the fighter silhouette."""
    mask = array[:, :, 3] > 24
    height, width = mask.shape
    visited = np.zeros(mask.shape, dtype=np.bool_)
    largest: list[tuple[int, int]] = []
    for y, x in np.argwhere(mask):
        if visited[y, x]:
            continue
        component: list[tuple[int, int]] = []
        queue: deque[tuple[int, int]] = deque([(int(y), int(x))])
        visited[y, x] = True
        while queue:
            current_y, current_x = queue.popleft()
            component.append((current_y, current_x))
            for neighbor_y in range(max(0, current_y - 1), min(height, current_y + 2)):
                for neighbor_x in range(max(0, current_x - 1), min(width, current_x + 2)):
                    if mask[neighbor_y, neighbor_x] and not visited[neighbor_y, neighbor_x]:
                        visited[neighbor_y, neighbor_x] = True
                        queue.append((neighbor_y, neighbor_x))
        if len(component) > len(largest):
            largest = component
    if not largest:
        return array
    keep = np.zeros(mask.shape, dtype=np.bool_)
    component_y, component_x = zip(*largest)
    keep[np.asarray(component_y), np.asarray(component_x)] = True
    # Preserve a one-pixel antialiased edge around the high-confidence core.
    expanded = keep.copy()
    expanded[1:, :] |= keep[:-1, :]
    expanded[:-1, :] |= keep[1:, :]
    expanded[:, 1:] |= keep[:, :-1]
    expanded[:, :-1] |= keep[:, 1:]
    expanded[1:, 1:] |= keep[:-1, :-1]
    expanded[1:, :-1] |= keep[:-1, 1:]
    expanded[:-1, 1:] |= keep[1:, :-1]
    expanded[:-1, :-1] |= keep[1:, 1:]
    array[~expanded, 3] = 0
    return array


def normalize(
    cell: Image.Image,
    animation: str,
    white_matted: bool,
    remove_matte: bool = True,
    flip_horizontally: bool = True,
) -> Image.Image:
    array = np.array(cell.convert("RGBA"), dtype=np.uint8)
    if remove_matte:
        array = remove_light_matte(array, white_matted)
    else:
        array[array[:, :, 3] < 18, 3] = 0
    if animation == "ko" or not remove_matte:
        array = keep_largest_component(array)
    alpha = array[:, :, 3]
    ys, xs = np.where(alpha > 24)
    if len(xs) == 0:
        raise ValueError(f"Empty extracted cell in {animation}")
    # Keep soft source alpha within the detected silhouette, but remove any remote artifacts.
    x0, x1 = max(0, int(xs.min()) - 4), min(array.shape[1], int(xs.max()) + 5)
    # Keep a little headroom, but let the final opaque foot pixel meet the
    # shared ground anchor instead of leaving the old five-pixel bottom pad.
    y0, y1 = max(0, int(ys.min()) - 4), min(array.shape[0], int(ys.max()) + 1)
    cropped = Image.fromarray(array[y0:y1, x0:x1], "RGBA")
    scale = min(TARGET_HEIGHT / cropped.height, 448.0 / cropped.width)
    resized = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    x = (CELL_SIZE - resized.width) // 2
    y = GROUND_Y - resized.height
    canvas.alpha_composite(resized, (x, y))
    # Most authored sheets face left; the approved idle replacement faces right.
    return canvas.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip_horizontally else canvas


def make_contact_sheet(name: str, frames: list[Path]) -> None:
    columns = min(8, len(frames))
    rows = (len(frames) + columns - 1) // columns
    tile_w, tile_h = 180, 190
    sheet = Image.new("RGB", (columns * tile_w, rows * tile_h), (19, 13, 27))
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(frames):
        frame = Image.open(path).convert("RGBA")
        frame.thumbnail((tile_w - 12, tile_h - 30), Image.Resampling.LANCZOS)
        x = (index % columns) * tile_w + (tile_w - frame.width) // 2
        y = (index // columns) * tile_h + 4
        sheet.paste(frame, (x, y), frame)
        draw.text(((index % columns) * tile_w + 7, (index // columns) * tile_h + tile_h - 20), f"{index + 1:02d}", fill=(235, 220, 255))
    sheet.save(PREVIEW_ROOT / f"{name}_contact.png")


def main() -> None:
    FRAME_ROOT.mkdir(parents=True, exist_ok=True)
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, object] = {
        "character": "The Executioner",
        "provenance": "Original animation pose sheets and independent sword generated with OpenAI built-in image generation using the user-provided Executioner reference. No EvoLink used. Source sheets retained in source/concept_and_sheets.",
        "frame_size": [CELL_SIZE, CELL_SIZE],
        "ground_line_y": GROUND_Y,
        "preprocessing": [
            "Detects and removes white-matted background pixels, then decontaminates partially transparent idle-sheet edges.",
            "Keeps only the primary connected silhouette in KO cells to discard detached neighboring-pose sheet spill.",
        ],
        "animations": {},
        "weapon": "res://assets/weapons/iron_sword/iron_sword.png",
    }
    all_frames: list[Path] = []
    animation_resources: list[tuple[str, list[Path], float, bool]] = []
    for animation, filename, columns, rows, count, fps, loop in SPECS:
        source_path = SOURCE / filename
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        source_image = Image.open(source_path).convert("RGBA")
        white_matted = has_white_matte_background(np.array(source_image, dtype=np.uint8))
        if columns * rows < count:
            raise ValueError(f"Grid too small for {animation}")
        output_dir = FRAME_ROOT / animation
        output_dir.mkdir(parents=True, exist_ok=True)
        frame_paths: list[Path] = []
        for index in range(count):
            cell = split_cell(source_image, index, columns, rows)
            preserve_approved_alpha = filename == "idle_sheet_replacement.png"
            frame = normalize(cell, animation, white_matted, not preserve_approved_alpha, not preserve_approved_alpha)
            frame_path = output_dir / f"{animation}_{index + 1:02d}.png"
            frame.save(frame_path, optimize=True)
            frame_paths.append(frame_path)
        make_contact_sheet(animation, frame_paths)
        all_frames.extend(frame_paths)
        animation_resources.append((animation, frame_paths, fps, loop))
        manifest["animations"][animation] = {
            "source_sheet": f"source/concept_and_sheets/{filename}",
            "frame_count": count,
            "fps": fps,
            "loop": loop,
            "frames": [path.relative_to(ROOT).as_posix() for path in frame_paths],
        }
    combo_frames: list[Path] = []
    for part in ("combo_hit_one", "combo_hit_two", "combo_hit_three"):
        combo_frames.extend(sorted((FRAME_ROOT / part).glob("*.png")))
    animation_resources.append(("three_hit_combo", combo_frames, 20.0, False))
    animation_resources.append(("walk", sorted((FRAME_ROOT / "walk_forward").glob("*.png")), 12.0, True))
    animation_resources.append(("hit", sorted((FRAME_ROOT / "hit_reaction").glob("*.png")), 14.0, False))
    animation_resources.append(("death", sorted((FRAME_ROOT / "ko").glob("*.png")), 12.0, False))
    manifest["animations"]["three_hit_combo"] = {
        "source_sheets": ["combo_hit_one_sheet.png", "combo_hit_two_sheet.png", "combo_hit_three_sheet.png"],
        "frame_count": len(combo_frames), "fps": 20.0, "loop": False,
        "frames": [path.relative_to(ROOT).as_posix() for path in combo_frames],
    }
    sprite_frames_path = ROOT / "assets/characters/the_executioner/executioner_sprite_frames.tres"
    ext_resources: list[str] = []
    animations: list[str] = []
    resource_index = 1
    for animation, frames, fps, loop in animation_resources:
        frame_records: list[str] = []
        for frame_path in frames:
            resource_id = f"frame_{resource_index:03d}"
            ext_resources.append(f'[ext_resource type="Texture2D" path="res://{frame_path.relative_to(ROOT).as_posix()}" id="{resource_id}"]')
            frame_records.append(f'{{"duration": 1.0, "texture": ExtResource("{resource_id}")}}')
            resource_index += 1
        animations.append(
            '{"frames": [' + ", ".join(frame_records) + f'], "loop": {1 if loop else 0}, "name": &"{animation}", "speed": {fps:.1f}' + '}'
        )
    sprite_frames_text = "[gd_resource type=\"SpriteFrames\" format=3]\n\n" + "\n".join(ext_resources) + "\n\n[resource]\nanimations = [" + ",\n".join(animations) + "]\n"
    sprite_frames_path.write_text(sprite_frames_text, encoding="utf-8")
    manifest["sprite_frames_resource"] = "res://assets/characters/the_executioner/executioner_sprite_frames.tres"
    manifest["total_unique_frames"] = len(all_frames)
    make_contact_sheet("all_animations", all_frames)
    (ROOT / "assets/characters/the_executioner/animation_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Generated {len(all_frames)} frames across {len(SPECS)} animations")


if __name__ == "__main__":
    main()
