"""Import original The Initiate 2x2 pose sheets into aligned runtime frames."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets" / "enemies" / "the_initiate"
FRAME_SIZE = 512
TARGET_HEIGHT = 480
GROUND_ANCHOR_Y = 496
ALPHA_THRESHOLD = 24

SHEETS: tuple[dict[str, object], ...] = (
    {"name": "idle", "source": "idle_guard_sheet.png", "frames": 4, "fps": 7.0, "loop": True,
     "phases": ["ready", "breathing", "guard_settle", "ready"]},
    {"name": "walk", "source": "walk_sheet.png", "frames": 4, "fps": 9.0, "loop": True,
     "phases": ["contact_left", "passing", "contact_right", "recovery"]},
    {"name": "punch", "source": "light_punch_sheet.png", "frames": 4, "fps": 60.0, "loop": False,
     "durations": [3, 7, 3, 21], "phases": ["guard", "anticipation", "contact", "recovery"]},
    {"name": "heavy_punch", "source": "heavy_punch_sheet.png", "frames": 4, "fps": 60.0, "loop": False,
     "durations": [7, 11, 3, 26], "phases": ["guard", "load", "contact", "follow_through_recovery"]},
    {"name": "kick", "source": "front_kick_sheet.png", "frames": 4, "fps": 60.0, "loop": False,
     "durations": [6, 11, 3, 24], "phases": ["guard", "knee_chamber", "extension_contact", "recoil_guard"]},
    {"name": "roundhouse", "source": "roundhouse_sheet.png", "frames": 4, "fps": 60.0, "loop": False,
     "durations": [7, 13, 3, 30], "phases": ["guard", "hip_load", "roundhouse_contact", "recoil_guard"]},
    {"name": "hit", "source": "hit_knockdown_sheet.png", "frames": 2, "fps": 12.0, "loop": False,
     "phases": ["impact_recoil", "stagger"]},
    {"name": "death", "source": "hit_knockdown_sheet.png", "frames": 4, "fps": 8.0, "loop": False,
     "phases": ["stagger", "fall", "ground_impact", "defeated_ground_pose"]},
)


def _write_sprite_frames_resource() -> None:
    animations = [
        {"name": "idle", "paths": [f"idle/idle_{i:02d}.png" for i in range(1, 5)], "fps": 7.0, "loop": True},
        {"name": "walk", "paths": [f"walk/walk_{i:02d}.png" for i in range(1, 5)], "fps": 9.0, "loop": True},
        {"name": "walk_backward", "paths": [f"walk/walk_{i:02d}.png" for i in range(4, 0, -1)], "fps": 9.0, "loop": True},
        {"name": "punch", "paths": [f"punch/punch_{i:02d}.png" for i in range(1, 5)], "fps": 60.0, "loop": False, "durations": [3, 7, 3, 21]},
        {"name": "heavy_punch", "paths": [f"heavy_punch/heavy_punch_{i:02d}.png" for i in range(1, 5)], "fps": 60.0, "loop": False, "durations": [7, 11, 3, 26]},
        {"name": "kick", "paths": [f"kick/kick_{i:02d}.png" for i in range(1, 5)], "fps": 60.0, "loop": False, "durations": [6, 11, 3, 24]},
        {"name": "roundhouse", "paths": [f"roundhouse/roundhouse_{i:02d}.png" for i in range(1, 5)], "fps": 60.0, "loop": False, "durations": [7, 13, 3, 30]},
        {"name": "guard", "paths": ["idle/idle_01.png"], "fps": 8.0, "loop": True},
        {"name": "hit", "paths": ["hit/hit_01.png", "hit/hit_02.png"], "fps": 12.0, "loop": False},
        {"name": "death", "paths": [f"death/death_{i:02d}.png" for i in range(1, 5)], "fps": 8.0, "loop": False},
    ]
    unique_paths = list(dict.fromkeys(path for animation in animations for path in animation["paths"]))
    ids = {path: f"texture_{index + 1}" for index, path in enumerate(unique_paths)}
    lines = [f"[gd_resource type=\"SpriteFrames\" load_steps={len(unique_paths) + 1} format=3]", ""]
    for path in unique_paths:
        resource_path = (BASE / "frames" / path).relative_to(ROOT).as_posix()
        lines.append(f"[ext_resource type=\"Texture2D\" path=\"res://{resource_path}\" id=\"{ids[path]}\"]")
    lines.extend(["", "[resource]", "animations = ["])
    for animation_index, animation in enumerate(animations):
        lines.append("}, {" if animation_index > 0 else "{")
        durations = animation.get("durations", [1.0] * len(animation["paths"]))
        lines.append("\"frames\": [")
        for frame_index, path in enumerate(animation["paths"]):
            lines.append("}, {" if frame_index > 0 else "{")
            lines.append(f"\"duration\": {float(durations[frame_index]):.1f},")
            lines.append(f"\"texture\": ExtResource(\"{ids[path]}\")")
        lines.append("}],")
        lines.append(f"\"loop\": {1 if animation['loop'] else 0},")
        lines.append(f"\"name\": &\"{animation['name']}\",")
        lines.append(f"\"speed\": {float(animation['fps']):.1f}")
    lines.append("}]")
    (BASE / "the_initiate_sprite_frames.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")


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
        left, top, right, bottom = width, height, -1, -1
        while stack:
            index = stack.pop()
            x, y = index % width, index // width
            area += 1
            left, top = min(left, x), min(top, y)
            right, bottom = max(right, x), max(bottom, y)
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = ny * width + nx
                    if foreground[neighbor] and not visited[neighbor]:
                        visited[neighbor] = 1
                        stack.append(neighbor)
        if area > best_area:
            best_seed, best_area = seed, area
            best_bounds = (left, top, right + 1, bottom + 1)
    if best_seed < 0:
        raise ValueError("Frame cell contains no visible character silhouette")

    component = bytearray(width * height)
    component[best_seed] = 1
    stack = [best_seed]
    while stack:
        index = stack.pop()
        x, y = index % width, index // width
        for ny in range(max(0, y - 1), min(height, y + 2)):
            for nx in range(max(0, x - 1), min(width, x + 2)):
                neighbor = ny * width + nx
                if foreground[neighbor] and not component[neighbor]:
                    component[neighbor] = 1
                    stack.append(neighbor)
    return component, best_bounds


def _normalize_cell(cell: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
    rgba = cell.convert("RGBA")
    width, height = rgba.size
    original_alpha = rgba.getchannel("A")
    component, bounds = _largest_component(original_alpha.tobytes(), width, height)
    mask = Image.frombytes("L", (width, height), bytes(255 if value else 0 for value in component))
    expanded = mask.filter(ImageFilter.MaxFilter(3))
    rgba.putalpha(Image.composite(original_alpha, Image.new("L", (width, height), 0), expanded))
    left, top, right, bottom = bounds
    content = rgba.crop((left, top, right, bottom))
    fit_scale = min(TARGET_HEIGHT / content.height, (FRAME_SIZE - 24) / content.width)
    fitted_width = max(1, round(content.width * fit_scale))
    fitted_height = max(1, round(content.height * fit_scale))
    content = content.resize((fitted_width, fitted_height), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    frame.alpha_composite(content, ((FRAME_SIZE - fitted_width) // 2, GROUND_ANCHOR_Y - fitted_height))
    visible = frame.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0).getbbox()
    if visible is None:
        raise ValueError("Normalized frame is empty")
    return frame, (fitted_width, fitted_height, visible[2] - visible[0], visible[3])


def _write_contact_sheet(frames: list[Image.Image], destination: Path) -> None:
    columns = min(4, len(frames))
    rows = (len(frames) + columns - 1) // columns
    tile = 256
    sheet = Image.new("RGBA", (columns * tile, rows * tile), (23, 17, 32, 255))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame.resize((tile, tile), Image.Resampling.LANCZOS),
                              ((index % columns) * tile, (index // columns) * tile))
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(destination, quality=95)


def main() -> None:
    manifest: dict[str, object] = {
        "schema_version": 1,
        "character": "The Initiate",
        "origin": "Original character and pose artwork generated with OpenAI ImageGen built-in from the user-provided Guardian portrait and existing robotic minion artwork as identity/design references; no reference pixels were used as frame content.",
        "license": "Original proprietary ShadowCraft artwork",
        "character_reference": "assets/enemies/the_initiate/source/guardian_ready_reference.png",
        "reference_note": "The ready reference retains the robotic guardian silhouette, purple armor, and visor while integrating a feminine athletic frame, ponytail, and sakura shoulder insignia.",
        "frame_size_px": [FRAME_SIZE, FRAME_SIZE],
        "ground_anchor_y": GROUND_ANCHOR_Y,
        "source_tool": "scripts/enemies/import_the_initiate_art.py",
        "transparent_background": True,
        "animations": [],
    }
    animations: list[dict[str, object]] = []
    for spec in SHEETS:
        source_path = BASE / "source" / str(spec["source"])
        source = Image.open(source_path).convert("RGBA")
        count = int(spec["frames"])
        frame_dir = BASE / "frames" / str(spec["name"])
        frame_dir.mkdir(parents=True, exist_ok=True)
        frames: list[Image.Image] = []
        paths: list[str] = []
        dimensions: list[list[int]] = []
        for index in range(count):
            col, row = index % 2, index // 2
            x0, x1 = round(col * source.width / 2), round((col + 1) * source.width / 2)
            y0, y1 = round(row * source.height / 2), round((row + 1) * source.height / 2)
            frame, size_data = _normalize_cell(source.crop((x0, y0, x1, y1)))
            destination = frame_dir / f"{spec['name']}_{index + 1:02d}.png"
            frame.save(destination, "PNG", optimize=True)
            paths.append(destination.relative_to(ROOT).as_posix())
            dimensions.append([FRAME_SIZE, FRAME_SIZE])
            frames.append(frame)
            print(f"{spec['name']} frame {index + 1}: fit={size_data[:2]}, visible={size_data[2:]}, file={paths[-1]}")
        preview_path = BASE / "previews" / f"{spec['name']}_contact.png"
        _write_contact_sheet(frames, preview_path)
        animation: dict[str, object] = {
            "name": str(spec["name"]),
            "source_sheet": f"assets/enemies/the_initiate/source/{spec['source']}",
            "source_dimensions_px": list(source.size),
            "grid": [2, 2],
            "frame_count": count,
            "frame_dimensions_px": dimensions[0],
            "format": "RGBA PNG",
            "transparent_background": True,
            "ground_anchor_y": GROUND_ANCHOR_Y,
            "fps": float(spec["fps"]),
            "loop": bool(spec["loop"]),
            "phase_map": spec["phases"],
            "frame_paths": paths,
            "contact_sheet": preview_path.relative_to(ROOT).as_posix(),
        }
        if "durations" in spec:
            animation["frame_durations_at_60_fps"] = spec["durations"]
        animations.append(animation)
    manifest["animations"] = animations
    (BASE / "asset_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    _write_sprite_frames_resource()
    print(f"MANIFEST {BASE.relative_to(ROOT).as_posix()}/asset_manifest.json")
    print(f"SPRITEFRAMES {BASE.relative_to(ROOT).as_posix()}/the_initiate_sprite_frames.tres")


if __name__ == "__main__":
    main()
