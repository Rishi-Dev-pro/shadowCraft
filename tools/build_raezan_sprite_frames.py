"""Build Raezan's frame-based SpriteFrames resource from the approved ordered PNGs."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FRAME_ROOT = ROOT / "assets/characters/raezan_boss/frames"
OUTPUT = ROOT / "assets/characters/raezan_boss/raezan_sprite_frames.tres"
ATTACK_DIR = ROOT / "resources/attacks/enemy"

# Keep the ordinary flinch controlled: the original full reaction sheet has a
# pronounced mid-sequence recoil intended for a heavier impact. Raezan's
# standard hitstun is short, so use its mild opening and recovery poses as a
# complete eight-frame reaction instead of cutting the 16-frame clip mid-fall.
FRAME_INDEX_OVERRIDES = {
	"hit": [0, 2, 4, 5, 6, 11, 13, 15],
	"guard_entry": [0, 1],
	"guard_hold": [1],
	"guard_impact": [2],
	"guard_release": [3],
}

ANIMATIONS = [
    ("idle", "idle", 8.0, True),
    ("walk", "walk_forward", 12.0, True),
    ("walk_forward", "walk_forward", 12.0, True),
    ("walk_backward", "walk_backward", 12.0, True),
    ("turn", "turn", 12.0, False),
    ("light_slash", "light_slash", 20.0, False),
    ("heavy_slash", "heavy_slash", 18.0, False),
    ("horizontal_slash", "horizontal_slash", 20.0, False),
    ("vertical_slash", "vertical_slash", 18.0, False),
    ("five_hit_combo", "five_hit_combo", 20.0, False),
    ("dash_attack", "dash_attack", 20.0, False),
    ("void_step", "void_step", 18.0, False),
    ("guard", "guard", 12.0, True),
    ("high_guard", "guard", 12.0, True),
    ("guard_entry", "guard_refinement", 12.0, False),
    ("guard_hold", "guard_refinement", 10.0, True),
    ("guard_impact", "guard_refinement", 12.0, False),
    ("guard_release", "guard_refinement", 12.0, False),
    ("parry", "parry", 20.0, False),
    ("counterattack", "counterattack", 20.0, False),
    ("void_burst", "void_burst", 18.0, False),
    ("hit", "hit_reaction", 16.0, False),
    ("knockback", "knockback", 16.0, False),
    ("death", "ko", 12.0, False),
    ("phase2_idle", "phase2_idle", 10.0, True),
    ("phase2_walk_forward", "phase2_walk_forward", 14.0, True),
    ("phase2_walk_backward", "phase2_walk_backward", 14.0, True),
    ("phase2_finisher", "phase2_finisher", 20.0, False),
    ("phase2_void_burst", "phase2_void_burst", 18.0, False),
]

ATTACKS = {
    "raezan_light_slash": ("Raezan Light Slash", 0, 10, 3, 21, 12.0, (190, 28), (150, 82), (166, -190), "light_slash", 0.045, 1.05),
    "raezan_heavy_slash": ("Raezan Heavy Slash", 0, 22, 4, 32, 21.0, (280, 78), (166, 108), (174, -200), "heavy_slash", 0.075, 1.32),
    "raezan_horizontal_slash": ("Raezan Horizontal Slash", 0, 17, 4, 27, 17.0, (230, 48), (170, 90), (174, -188), "horizontal_slash", 0.065, 1.2),
    "raezan_vertical_slash": ("Raezan Vertical Slash", 0, 20, 4, 29, 19.0, (250, 70), (132, 128), (166, -206), "vertical_slash", 0.07, 1.27),
    "raezan_dash_attack": ("Raezan Dash Slash", 0, 20, 4, 29, 18.0, (250, 40), (156, 96), (170, -190), "dash_attack", 0.065, 1.22),
    "raezan_five_hit": ("Raezan Five-Hit Sequence", 0, 7, 55, 8, 5.5, (175, 28), (148, 86), (164, -186), "five_hit_combo", 0.045, 1.08),
    "raezan_combo_1": ("Raezan Combo Opening Slash", 0, 1, 2, 1, 6.0, (190, 30), (150, 84), (162, -188), "five_hit_combo", 0.045, 1.05),
    "raezan_combo_2": ("Raezan Combo Reverse Slash", 0, 1, 2, 1, 6.0, (196, 32), (154, 86), (167, -186), "five_hit_combo", 0.045, 1.05),
    "raezan_combo_3": ("Raezan Combo Horizontal Slash", 0, 1, 2, 1, 6.5, (205, 38), (164, 90), (171, -188), "five_hit_combo", 0.05, 1.1),
    "raezan_combo_4": ("Raezan Combo Advancing Slash", 0, 1, 2, 1, 7.0, (214, 42), (170, 94), (178, -188), "five_hit_combo", 0.055, 1.14),
    "raezan_combo_5": ("Raezan Combo Finisher", 0, 1, 2, 1, 9.0, (245, 65), (184, 112), (184, -198), "five_hit_combo", 0.07, 1.25),
    "raezan_parry_counter": ("Raezan Parry Counter", 0, 13, 4, 29, 20.0, (300, 68), (176, 100), (180, -194), "counterattack", 0.08, 1.34),
    "raezan_void_burst": ("Raezan Void Burst", 0, 28, 5, 38, 20.0, (90, 12), (286, 244), (0, -176), "void_burst", 0.085, 1.45),
    "raezan_void_step": ("Raezan Void Step", 0, 1, 1, 1, 1.0, (90, 0), (72, 64), (0, -170), "void_step", 0.0, 1.0),
}


def build() -> None:
    ext_resources: list[str] = []
    animation_records: list[str] = []
    texture_id_by_path: dict[str, str] = {}
    next_id = 1

    for animation_name, source_folder, speed, looping in ANIMATIONS:
        folder = FRAME_ROOT / source_folder
        all_frames = sorted(folder.glob("*.png"))
        if not all_frames:
            raise FileNotFoundError(f"No frames in {folder}")
        indices = FRAME_INDEX_OVERRIDES.get(animation_name)
        frames = [all_frames[index] for index in indices] if indices is not None else all_frames
        frame_records: list[str] = []
        for frame in frames:
            relative_path = frame.relative_to(ROOT).as_posix()
            resource_id = texture_id_by_path.get(relative_path)
            if resource_id is None:
                resource_id = f"raezan_frame_{next_id:03d}"
                next_id += 1
                texture_id_by_path[relative_path] = resource_id
                ext_resources.append(
                    f'[ext_resource type="Texture2D" path="res://{relative_path}" id="{resource_id}"]'
                )
            frame_records.append(
                f'{{"duration": 1.0, "texture": ExtResource("{resource_id}")}}'
            )
        loop_value = 1 if looping else 0
        animation_records.append(
            '{"frames": [' + ", ".join(frame_records) + f'], "loop": {loop_value}, '
            f'"name": &"{animation_name}", "speed": {speed:.1f}' + "}"
        )

    text = (
        "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
        + "\n".join(ext_resources)
        + "\n\n[resource]\nanimations = ["
        + ",\n".join(animation_records)
        + "]\n"
    )
    OUTPUT.write_text(text, encoding="utf-8")
    write_attacks()
    print(f"Wrote {OUTPUT.relative_to(ROOT)} with {len(texture_id_by_path)} unique textures and {len(ANIMATIONS)} animations")


def write_attacks() -> None:
    script = 'res://resources/attacks/attack_data.gd'
    for attack_id, values in ATTACKS.items():
        display, kind, startup, active, recovery, damage, knockback, size, offset, animation, hitstop, impact = values
        output = ATTACK_DIR / f"{attack_id}.tres"
        if output.exists():
            # Existing authored data wins; the builder never overwrites it.
            continue
        text = (
            '[gd_resource type="Resource" script_class="AttackData" load_steps=2 format=3]\n\n'
            f'[ext_resource type="Script" path="{script}" id="1"]\n\n[resource]\n'
            'script = ExtResource("1")\n'
            f'attack_id = &"{attack_id}"\n'
            f'display_name = "{display}"\n'
            f'kind = {kind}\n'
            f'startup_frames = {startup}\nactive_frames = {active}\nrecovery_frames = {recovery}\n'
            f'base_damage = {damage:.1f}\n'
            f'knockback = Vector2({knockback[0]}, {knockback[1]})\n'
            'hitstun_seconds = 0.38\n'
            f'hitbox_size = Vector2({size[0]}, {size[1]})\n'
            f'hitbox_offset = Vector2({offset[0]}, {offset[1]})\n'
            f'animation_name = &"{animation}"\n'
            f'hit_reaction = {2 if damage >= 18 else 1}\n'
            f'hit_stop_seconds = {hitstop:.3f}\nimpact_scale = {impact:.2f}\n'
        )
        output.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    build()
