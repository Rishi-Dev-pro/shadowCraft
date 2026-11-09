extends Node2D

@onready var anim_idle: AnimationPlayer = $Fighters/Kai_Idle/AnimationPlayer
@onready var anim_walk_fwd: AnimationPlayer = $Fighters/Kai_WalkFwd/AnimationPlayer
@onready var anim_walk_bwd: AnimationPlayer = $Fighters/Kai_WalkBwd/AnimationPlayer
@onready var anim_crouch: AnimationPlayer = $Fighters/Kai_Crouch/AnimationPlayer

var screenshot_timer: float = 0.0
var screenshots_taken: bool = false

func _ready() -> void:
    # Start animations
    if anim_idle:
        anim_idle.play("loco/idle")
    if anim_walk_fwd:
        anim_walk_fwd.play("loco/walk_fwd")
    if anim_walk_bwd:
        anim_walk_bwd.play("loco/walk_bwd")
    if anim_crouch:
        anim_crouch.play("loco/crouch")

func _process(delta: float) -> void:
    screenshot_timer += delta
    # Allow 0.5s for initial layout, animation sampling, and texture rendering
    if screenshot_timer > 0.5 and not screenshots_taken:
        screenshots_taken = true
        _capture_screenshots()

func _capture_screenshots() -> void:
    var dir_path: String = "res://reports/screenshots"
    DirAccess.make_dir_recursive_absolute("res://reports/screenshots")
    
    var img: Image = get_viewport().get_texture().get_image()
    var full_path: String = "reports/screenshots/kai_preview_all_states.png"
    img.save_png(full_path)
    print("[KaiPreview] Saved composite preview screenshot: ", full_path)
    
    # Also capture individual cropped fighters for detailed inspection
    _capture_individual_fighters(img)

func _capture_individual_fighters(composite: Image) -> void:
    # 1. Idle (around x=480, y=360, w=180, h=320)
    # 2. Walk Fwd (around x=680)
    # 3. Walk Bwd (around x=880)
    # 4. Crouch (around x=1080)
    # Let's crop individual images
    var fighters_rects: Dictionary = {
        "reports/screenshots/kai_idle.png": Rect2i(430, 260, 180, 320),
        "reports/screenshots/kai_walk_fwd.png": Rect2i(630, 260, 180, 320),
        "reports/screenshots/kai_walk_bwd.png": Rect2i(830, 260, 180, 320),
        "reports/screenshots/kai_crouch.png": Rect2i(1030, 260, 180, 320),
        "reports/screenshots/kai_concept_art.png": Rect2i(80, 180, 300, 420)
    }
    
    for path: String in fighters_rects:
        var r: Rect2i = fighters_rects[path]
        # Clamp within image bounds
        r.position.x = clampi(r.position.x, 0, composite.get_width() - 1)
        r.position.y = clampi(r.position.y, 0, composite.get_height() - 1)
        r.size.x = clampi(r.size.x, 1, composite.get_width() - r.position.x)
        r.size.y = clampi(r.size.y, 1, composite.get_height() - r.position.y)
        var cropped: Image = composite.get_region(r)
        cropped.save_png(path)
        print("[KaiPreview] Saved screenshot: ", path)
