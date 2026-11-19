"""Register the original painted poses and bake bidirectional displacement maps.

Run from the project root with the output directory of capture_handoffs.gd.
Pillow, NumPy and OpenCV are offline authoring tools only.
"""

import argparse
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[1] / "assets/characters/kai_v2/animations"
SIZE = 512
FLOW_RANGE = 152.0
GROUND = 503.0
CROUCH_FLOOR_OFFSETS = (0, 4, 7)


def register(path, scale, source_x, source_ground):
    sample = Image.open(SOURCE / path).convert("RGBA")
    # The same registration is used for every reference in a pose family.
    # Only a uniform scale and a floor-aligned translation are applied.
    return sample.transform(
        (SIZE, SIZE), Image.Transform.AFFINE,
        (1 / scale, 0, source_x - 256 / scale,
         0, 1 / scale, source_ground - GROUND / scale),
        Image.Resampling.BICUBIC,
    )


def features(image):
    pixels = np.asarray(image.convert("RGBA"), dtype=np.float32) / 255.0
    grey = pixels[:, :, :3] @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    # Visible painted folds and the alpha silhouette both guide correspondence.
    value = (grey * 0.71 + 0.24) * pixels[:, :, 3]
    return np.uint8(np.rint(value * 255))


PUNCH_CONTACTS = (
    # Winding and extended positions for the near elbow, forearm, and fist.
    ((221, 165), (342, 141), (24, 13)),
    ((273, 174), (390, 143), (27, 11)),
    ((323, 181), (430, 140), (23, 12)),
)


def constrain_punch(flow, reverse):
    """Resolve the near arm correspondence where it passes over the other fist."""
    y, x = np.mgrid[:SIZE, :SIZE]
    coverage = np.zeros((SIZE, SIZE), dtype=np.float32)
    guided = np.zeros_like(flow)
    for first, second, radius in PUNCH_CONTACTS:
        start, end = (second, first) if reverse else (first, second)
        dist = ((x - start[0]) / radius[0]) ** 2 + ((y - start[1]) / radius[1]) ** 2
        weight = np.float32(np.exp(-0.5 * dist))
        coverage += weight
        guided += weight[:, :, None] * np.subtract(end, start)
    influence = np.clip(coverage * 0.56, 0.0, 0.62)[:, :, None]
    return flow * (1.0 - influence) + guided / np.maximum(coverage[:, :, None], 0.0001) * influence


def flow_surface(first, second, punch_extension=False):
    a, b = features(first), features(second)
    flow = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    flow.setFinestScale(0)
    forward = flow.calc(a, b, None)
    reverse = flow.calc(b, a, None)
    if punch_extension:
        forward = constrain_punch(forward, False)
        reverse = constrain_punch(reverse, True)
    packed = np.concatenate((forward, reverse), axis=-1)
    values = np.uint8(np.rint(np.clip(packed / FLOW_RANGE, -1.0, 1.0) * 127 + 128))
    return Image.fromarray(values, "RGBA")


def floor_register(frame, offset):
    registered = Image.new("RGBA", frame.size)
    registered.paste(frame, (0, -offset))
    return registered


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("handoffs", type=Path)
    parser.add_argument("--crouch-only", action="store_true",
                        help="Rebake the crouch handoff and flow while preserving both painted keys and all punch files.")
    args = parser.parse_args()
    destination = ROOT / "corrections"
    destination.mkdir(exist_ok=True)
    families = {
        "punch": (
            2, 0.94, 252.0, 495.0,
            ("attacks/heavy_punch/heavy_punch_02.png", "attacks/heavy_punch/heavy_punch_04.png",
             "attacks/heavy_punch/heavy_punch_05.png"),
        ),
        "crouch": (
            3, 1.12, 255.0, 503.0,
            ("crouch/crouch_01.png", "crouch/crouch_03.png"),
        ),
    }
    for name, (pose, scale, center, floor, paths) in families.items():
        if args.crouch_only and name != "crouch":
            continue
        frames = [Image.open(args.handoffs / f"anchor_{pose}.png").convert("RGBA")]
        if args.crouch_only:
            frames.extend(Image.open(destination / f"crouch_{index}.png").convert("RGBA")
                          for index in (1, 2))
        else:
            frames.extend(register(path, scale, center, floor) for path in paths)
        for index, frame in enumerate(frames):
            if not args.crouch_only or index == 0:
                frame.save(destination / f"{name}_{index}.png", optimize=True)
        if name == "crouch":
            frames = [floor_register(frame, offset) for frame, offset in zip(frames, CROUCH_FLOOR_OFFSETS)]
        for index, (first, second) in enumerate(zip(frames, frames[1:])):
            flow_surface(first, second, name == "punch" and index == 2).save(
                destination / f"{name}_flow_{index}.png", optimize=True)


if __name__ == "__main__":
    main()
