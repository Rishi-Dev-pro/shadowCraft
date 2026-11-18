class_name GrindDuelistData
extends Resource

@export var title: String = ""
@export_range(1.0, 500.0) var health: float = 100.0
@export_range(10.0, 600.0) var walk: float = 200.0
@export_range(10.0, 650.0) var run: float = 345.0
@export_range(0.0, 700.0) var jump: float = 0.0
@export var light: GrindStrike
@export var heavy: GrindStrike
