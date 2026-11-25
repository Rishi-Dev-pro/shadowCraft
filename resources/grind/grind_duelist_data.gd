class_name GrindDuelistData
extends Resource

@export var title: String = ""
@export_range(1.0, 500.0) var health: float = 100.0
@export_range(10.0, 600.0) var walk: float = 200.0
@export_range(10.0, 650.0) var run: float = 345.0
@export_range(0.0, 700.0) var jump: float = 0.0
@export var light: GrindStrike
@export var heavy: GrindStrike

@export var cross: GrindStrike
@export var kick: GrindStrike
@export var crouch_enabled: bool = false
@export_range(0.0, 0.4) var landing_recovery: float = 0.0
@export_range(0.0, 1.0) var combo_window: float = 0.0
@export_range(0.0, 1000.0) var dash_speed: float = 0.0
@export_range(0.07, 0.5) var dash_duration: float = 0.22
@export_range(0.0, 0.4) var dash_recovery: float = 0.12
@export_range(0.0, 3.0) var dash_cooldown: float = 0.65
