"""Register cutouts from live Raezen paintings. Requires Pillow and NumPy."""

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

OUTPUT = Path(__file__).resolve().parent / "art"
BOSS = OUTPUT.parents[2] / "assets/characters/raezan_boss/frames"
MASTER = "idle/idle_01.png"
SIZE = 512

# Original frame-space pivots. The blade is registered beneath the near palm.
JOINTS = {
    "Root": ("", (256, 491)),
    "Pelvis": ("Root", (251, 231)),
    "Spine": ("Pelvis", (250, 201)),
    "Chest": ("Spine", (248, 161)),
    "Neck": ("Chest", (248, 126)),
    "Head": ("Neck", (251, 112)),
    "Hair": ("Head", (223, 102)),
    "HairTip": ("Hair", (147, 128)),
    "Scarf": ("Neck", (216, 120)),
    "ScarfTip": ("Scarf", (126, 174)),
    "ShoulderFar": ("Chest", (297, 153)),
    "ArmFar": ("ShoulderFar", (298, 169)),
    "ElbowFar": ("ArmFar", (312, 221)),
    "WristFar": ("ElbowFar", (335, 261)),
    "HandFar": ("WristFar", (342, 275)),
    "ShoulderNear": ("Chest", (209, 150)),
    "ArmNear": ("ShoulderNear", (205, 168)),
    "ElbowNear": ("ArmNear", (188, 204)),
    "WristNear": ("ElbowNear", (184, 249)),
    "HandNear": ("WristNear", (184, 263)),
    "HipFar": ("Pelvis", (273, 253)),
    "KneeFar": ("HipFar", (306, 365)),
    "FootFar": ("KneeFar", (312, 451)),
    "HipNear": ("Pelvis", (234, 253)),
    "KneeNear": ("HipNear", (199, 365)),
    "FootNear": ("KneeNear", (181, 449)),
    "Coat": ("Pelvis", (229, 244)),
    "CoatTip": ("Coat", (141, 328)),
    "Belt": ("Pelvis", (265, 234)),
}

# Polygons claim pixels from front to back and never change their original alpha.
MASKS = [
    ("near_glove", "HandNear", 33, [(171,247),(193,247),(202,260),(197,274),(183,287),(171,281),(166,268)]),
    ("blade", "BladePivot", 31, [(129,245),(139,241),(149,245),(154,251),(170,257),(188,263),(195,269),(207,273),(217,282),(227,291),(245,297),(264,304),(295,312),(320,322),(352,332),(386,342),(423,350),(463,348),(470,352),(450,362),(427,369),(398,369),(362,365),(331,359),(303,350),(275,340),(247,328),(227,317),(208,305),(196,307),(186,300),(190,289),(196,283),(165,272),(152,265),(143,269),(147,286),(152,303),(151,315),(132,316),(129,307),(134,286),(136,266),(129,257)]),
    ("face", "Head", 24, [(214,92),(219,70),(240,58),(270,54),(290,65),(297,88),(291,105),(278,126),(266,130),(250,125),(234,121),(216,116)]),
    ("near_pauldron", "ShoulderNear", 25, [(188,117),(209,120),(234,135),(239,151),(228,163),(217,176),(202,174),(181,184),(170,171),(179,159),(180,142)]),
    ("near_arm", "ArmNear", 23, [(176,167),(209,163),(223,174),(211,202),(194,211),(176,204),(171,190)]),
    ("near_bracer", "ElbowNear", 27, [(174,192),(196,193),(209,204),(202,226),(193,254),(171,254),(165,240),(172,216)]),
    ("far_pauldron", "ShoulderFar", 12, [(287,134),(312,143),(317,181),(304,194),(293,185),(288,163)]),
    ("far_glove", "HandFar", 14, [(329,257),(347,259),(357,267),(361,286),(354,307),(341,307),(332,288),(323,276)]),
    ("far_bracer", "ElbowFar", 12, [(305,213),(323,210),(338,235),(352,259),(342,273),(327,264),(310,240)]),
    ("far_arm", "ArmFar", 11, [(294,174),(306,174),(317,194),(325,216),(311,232),(297,220),(288,198)]),
    ("collar", "Neck", 22, [(221,118),(244,117),(265,128),(280,141),(301,143),(301,166),(286,181),(258,177),(234,162)]),
    ("belt", "Belt", 27, [(223,217),(253,211),(276,217),(296,227),(301,244),(287,255),(266,251),(247,243),(223,249),(218,240)]),
    ("front_sash", "Belt", 26, [(262,240),(277,238),(290,263),(296,305),(286,346),(285,381),(266,430),(247,417),(238,389),(248,358),(252,322),(250,287)]),
    ("near_boot", "FootNear", 17, [(168,440),(191,437),(199,457),(201,488),(154,491),(155,472)]),
    ("far_boot", "FootFar", 16, [(297,438),(324,436),(340,450),(366,478),(366,487),(289,487),(290,466)]),
    ("near_greave", "KneeNear", 16, [(184,354),(219,353),(220,375),(206,406),(195,449),(167,452),(161,426),(172,391)]),
    ("far_greave", "KneeFar", 13, [(291,343),(332,341),(337,375),(325,404),(331,451),(294,453),(286,415),(283,384)]),
    ("near_tassets", "HipNear", 15, [(226,242),(257,244),(267,277),(252,316),(229,347),(227,374),(193,385),(167,376),(180,344),(185,309),(203,271)]),
    ("far_tassets", "HipFar", 12, [(273,234),(298,242),(315,277),(337,316),(337,356),(319,376),(289,375),(283,343),(280,304)]),
    ("hair_tips", "Hair", 3, [(56,79),(146,89),(172,109),(163,133),(166,170),(130,207),(72,225),(44,205)]),
    ("hair", "Hair", 4, [(117,97),(214,82),(240,92),(225,128),(204,155),(178,196),(147,212),(117,201)]),
    ("scarf_tip", "Scarf", 2, [(41,169),(132,152),(151,174),(138,208),(97,243),(48,250),(38,230)]),
    ("scarf", "Scarf", 2, [(90,56),(157,52),(217,81),(238,97),(229,114),(198,108),(173,99),(127,80),(91,102),(85,155),(128,155),(191,145),(218,132),(220,171),(174,198),(138,204),(90,240),(66,238),(53,202)]),
    ("coat_tip", "CoatTip", 0, [(39,273),(155,268),(203,280),(167,333),(168,386),(141,431),(95,479),(47,477),(42,415)]),
    ("coat", "Coat", 1, [(119,282),(201,236),(274,237),(320,275),(355,334),(365,454),(323,475),(260,466),(220,450),(188,444),(162,461),(104,475),(71,422),(96,357)]),
    ("torso", "Chest", 10, [(170,100),(300,110),(320,160),(306,224),(269,240),(211,245),(205,208),(190,181)]),
]


def image(path):
    return Image.open(BOSS / path).convert("RGBA")


def polygon(points):
    stamp = Image.new("L", (SIZE, SIZE))
    ImageDraw.Draw(stamp).polygon(points, fill=255)
    return np.asarray(stamp) > 0


def artwork(runtime_master):
    raw = np.asarray(image(MASTER))
    master = Image.open(runtime_master).convert("RGBA")
    rgba = np.array(master)
    # Godot's imported frame recolours RGB only at the very low-alpha edge.
    # Match the campaign texture exactly without accepting a changed silhouette
    # or any difference to the painted interior.
    if not np.array_equal(raw[..., 3], rgba[..., 3]) or not np.array_equal(raw[raw[..., 3] >= 20], rgba[raw[..., 3] >= 20]):
        raise ValueError("Runtime master disagrees with the approved source RGBA")
    interior = rgba[..., 3] >= 248
    remaining = rgba[..., 3] > 0
    layers = {}
    images = {}
    registered = []
    OUTPUT.mkdir(parents=True, exist_ok=True)

    def add(name, joint, depth, mask, pixels, hidden=False):
        canvas = np.zeros_like(rgba)
        canvas[mask] = pixels[mask]
        art = Image.fromarray(canvas)
        crop = art.getbbox()
        if crop is None:
            raise ValueError(f"Layer has no registered artwork: {name}")
        if name in ("hair", "scarf"):
            crop = (crop[0], crop[1] - 4, crop[2], crop[3] + 4)
        images[name] = art.crop(crop)
        layers[name] = (canvas, mask, depth, hidden)
        registered.append({"name": name, "joint": joint, "depth": depth, "origin": list(crop[:2]), "underlay": hidden})

    for name, joint, depth, outline in MASKS:
        visible = remaining & polygon(outline)
        add(name, joint, depth, visible, rgba)
        remaining &= ~visible
    add("base_cloth", "Pelvis", 0, remaining, rgba)
    for name, tip, joint, depth in (("hair", "hair_tips", "Hair", 4), ("scarf", "scarf_tip", "Scarf", 2)):
        combined = layers[name][1] | layers[tip][1]
        for retired in (name, tip):
            layers.pop(retired)
            images.pop(retired)
            registered[:] = [layer for layer in registered if layer["name"] != retired]
        add(name, joint, depth, combined, rgba)

    donor_idle = np.array(image("idle/idle_05.png"))
    donor_guard = np.array(image("guard_refinement/guard_refinement_01.png"))
    donor_raised = np.array(image("guard_refinement/guard_refinement_02.png"))
    donor_walk = np.array(image("walk_forward/walk_forward_06.png"))

    def restore(name, joint, depth, blockers, outline, donor):
        behind = np.logical_or.reduce([layers[blocker][1] for blocker in blockers])
        mask = behind & interior & (donor[..., 3] > 128) & polygon(outline)
        add(name, joint, depth, mask, donor, hidden=True)

    restore("behind_blade_near", "HipNear", 10, ["blade"],
            [(193,268),(250,276),(258,341),(225,345),(192,318)], donor_raised)
    restore("behind_blade_sash", "Belt", 20, ["blade"],
            [(241,288),(295,304),(295,362),(241,350)], donor_raised)
    restore("behind_blade_far", "HipFar", 9, ["blade"],
            [(285,307),(331,317),(349,366),(285,368)], donor_raised)
    restore("under_near_hip", "Pelvis", 7, ["near_tassets","front_sash"],
            [(191,258),(270,246),(282,329),(238,353),(219,358),(190,350)], donor_raised)
    restore("under_far_hip", "Pelvis", 7, ["far_tassets","front_sash"],
            [(266,253),(315,255),(347,342),(316,378),(270,354)], donor_raised)
    restore("under_pauldron", "Chest", 9, ["near_pauldron","near_arm"],
            [(195,138),(235,135),(235,201),(195,201)], donor_guard)
    restore("under_near_elbow", "ArmNear", 22, ["near_bracer"],
            [(172,192),(206,192),(208,217),(172,217)], donor_walk)
    # Register the raised guard's inner knee fold to the neutral joint. Keep the
    # painted knee plate on the shin and reveal cloth behind it as the leg flexes.
    near_knee_fold = np.roll(donor_raised, shift=(6, -16), axis=(0, 1))
    restore("under_near_knee", "HipNear", 14, ["near_greave"],
            [(190,348),(229,345),(219,384),(191,389)], near_knee_fold)
    near_knee_lap = np.roll(donor_idle, shift=(-13, 1), axis=(0, 1))
    restore("near_greave_lap", "KneeNear", 13, ["near_tassets"],
            [(183,336),(217,335),(219,365),(184,370)], near_knee_lap)
    restore("under_far_knee", "HipFar", 11, ["far_greave"],
            [(290,343),(332,343),(331,378),(294,381)], donor_guard)
    restore("under_near_ankle", "KneeNear", 15, ["near_boot"],
            [(166,438),(196,437),(195,467),(163,465)], donor_idle)
    restore("under_far_ankle", "KneeFar", 12, ["far_boot"],
            [(293,435),(324,435),(326,465),(292,461)], donor_idle)
    # Continue the painted wrap under the opaque glove without altering its outline.
    grip_wrap = np.roll(rgba, shift=(9, 23), axis=(0, 1))
    restore("grip_wrap", "BladePivot", 30, ["near_glove"],
            [(172,258),(195,268),(195,281),(172,270)], grip_wrap)

    assembled = Image.new("RGBA", (SIZE, SIZE))
    for canvas, _, _, hidden in sorted(layers.values(), key=lambda layer: layer[2]):
        if not hidden:
            assembled.alpha_composite(Image.fromarray(canvas))
    before, after = np.asarray(master), np.asarray(assembled)
    visible = (before[..., 3] > 0) | (after[..., 3] > 0)
    delta = np.abs(before.astype(np.int16) - after.astype(np.int16))
    assert np.max(delta[visible]) == 0, "Neutral RGB/A changed"
    for name, cropped in images.items():
        cropped.save(OUTPUT / f"{name}.png", optimize=True)
    (OUTPUT / "registration.json").write_text(json.dumps({
        "master": f"res://assets/characters/raezan_boss/frames/{MASTER}",
        "canvas": SIZE, "ground_y": 491, "world_scale": 0.72, "footline_offset": -6,
        "joints": JOINTS, "layers": sorted(registered, key=lambda layer: layer["depth"]),
        "primary_grip": [184, 263], "offhand_grip": [173, 258], "blade_tip": [460, 350],
    }, indent=2) + "\n", encoding="utf-8")
    print(f"{len(layers)} layers, exact neutral across {int(visible.sum())} visible pixels")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("runtime_master", type=Path, help="PNG exported by export_runtime_master.gd")
    artwork(parser.parse_args().runtime_master)
