"""Register the existing painted attack keys and bake attack-only correction maps."""

import argparse
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from prepare_corrections import ROOT, SOURCE, flow_surface, register


# Optical flow alone confuses the overlapping legs during the chamber.
KICK_LOAD = (
    (216, 84), (157, 153), (208, 178), (269, 138), (237, 238),
    (204, 275), (213, 370), (118, 457), (108, 490), (151, 490),
    (294, 343), (276, 446), (308, 483), (145, 111), (92, 360),
)
KICK_CHAMBER = (
    (165, 76), (114, 142), (166, 162), (219, 121), (163, 220),
    (144, 259), (148, 372), (128, 460), (108, 490), (180, 490),
    (251, 221), (234, 317), (267, 352), (93, 95), (58, 356),
)
KICK_RETRACTION = (
    (157, 76), (109, 146), (159, 167), (225, 128), (155, 224),
    (136, 261), (148, 366), (124, 457), (108, 490), (180, 490),
    (252, 222), (232, 318), (269, 351), (91, 102), (53, 355),
)
KICK_EXTENSION = (
    (164, 76), (111, 142), (164, 163), (220, 126), (155, 216),
    (151, 258), (148, 372), (128, 460), (108, 490), (180, 490),
    (292, 219), (351, 218), (379, 182), (93, 91), (56, 353),
)
KICK_STANCE = (
    (252, 78), (181, 153), (225, 177), (313, 137), (237, 240),
    (209, 276), (176, 368), (125, 454), (108, 490), (152, 490),
    (322, 363), (329, 453), (367, 488), (169, 100), (92, 361),
)
GUIDES = {
    ("kick", 1): (KICK_LOAD, KICK_CHAMBER),
    ("kick", 2): (KICK_CHAMBER, KICK_EXTENSION),
    ("kick", 4): (KICK_RETRACTION, KICK_LOAD),
    ("kick", 5): (KICK_LOAD, KICK_STANCE),
}
STEPPED = {"jab": (1, 4), "heavy": (5,), "kick": (3,)}


def landmark_flow(start, end):
    """Interpolate a smooth displacement through registered painted landmarks."""
    border = ((0, 0), (256, 0), (511, 0), (511, 250), (511, 511), (0, 511), (0, 250))
    source = np.array((*start, *border), dtype=np.float64) / 512
    target = np.array((*end, *border), dtype=np.float64) / 512

    def kernel(points):
        distances = np.square(points[:, None, :] - source).sum(axis=2)
        return distances * np.log(np.maximum(distances, 1e-12))

    basis = np.column_stack((np.ones(len(source)), source))
    matrix = np.block([[kernel(source), basis], [basis.T, np.zeros((3, 3))]])
    weights = np.linalg.solve(matrix, np.vstack((target - source, np.zeros((3, 2)))))
    y, x = np.mgrid[:512, :512]
    grid = np.column_stack((x.ravel(), y.ravel())) / 512
    result = np.column_stack((kernel(grid), np.ones(len(grid)), grid)) @ weights
    return result.reshape((512, 512, 2)) * 512


def guided_flow(start, end):
    directions = np.concatenate((landmark_flow(start, end), landmark_flow(end, start)), axis=-1)
    values = np.uint8(np.rint(np.clip(directions / 224.0, -1.0, 1.0) * 127 + 128))
    return Image.fromarray(values, "RGBA")


def sheet_pose(sheet, index, heel, floor):
    x, y = index % 3 * 512, index // 3 * 512
    frame = sheet.crop((x, y, x + 512, y + 512))
    # The extracted cell contains sparse stray alpha beyond the painted figure.
    pixels = np.array(frame)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(
        (pixels[:, :, 3] > 24).astype(np.uint8)
    )
    foreground = np.uint8(labels == 1 + np.argmax(stats[1:count, cv2.CC_STAT_AREA]))
    mask = cv2.dilate(foreground, np.ones((5, 5), dtype=np.uint8))
    pixels[mask == 0] = 0
    frame = Image.fromarray(pixels)
    scale = 0.94
    return frame.transform(
        (512, 512), Image.Transform.AFFINE,
        (1 / scale, 0, heel - 108 / scale, 0, 1 / scale, floor - 503 / scale),
        Image.Resampling.BICUBIC,
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("anchors", type=Path)
    args = parser.parse_args()
    output = ROOT / "attack_corrections"
    output.mkdir(exist_ok=True)
    jab = Image.open(SOURCE / "attacks/light_jab_source.png").convert("RGBA")
    kick = Image.open(SOURCE / "attacks/front_kick_source.png").convert("RGBA")
    kick_heels = (109, 131, 175, 167, 165, 110)
    kick_floors = (497, 497, 497, 498, 498, 498)
    families = {
        "jab": [sheet_pose(jab, key, 110, 496) for key in (1, 2, 3, 3, 4, 5)],
        "heavy": [
            Image.open(ROOT / "corrections/punch_3.png").convert("RGBA") if key == 5
            else register(f"attacks/heavy_punch/heavy_punch_{key:02d}.png", 0.94, 252.0, 495.0)
            for key in (2, 3, 4, 5, 7, 8, 9, 10)
        ],
        "kick": [
            sheet_pose(kick, key, kick_heels[key], kick_floors[key])
            for key in (1, 2, 3, 4, 1, 5)
        ],
    }
    for name, painted in families.items():
        anchor = Image.open(args.anchors / f"{name}_0.png").convert("RGBA")
        frames = [anchor, *painted, anchor]
        for index, frame in enumerate(frames[:-1]):
            if (name, index) not in {("heavy", 4), ("jab", 4), ("kick", 5)}:
                frame.save(output / f"{name}_{index}.png", optimize=True)
        for index, (first, second) in enumerate(zip(frames, frames[1:])):
            if index in STEPPED[name]:
                continue
            guide = GUIDES.get((name, index))
            flow = guided_flow(*guide) if guide else flow_surface(first, second)
            flow.save(output / f"{name}_flow_{index}.png", optimize=True)


if __name__ == "__main__":
    main()
