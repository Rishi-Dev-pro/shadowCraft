class_name CharacterData
extends Resource

@export_group("Identity")
@export var character_id: String = "kai"
@export var display_name: String = "Kai"
@export var title: String = "The Shadow Disciple"
@export var signature_color: Color = Color(0.66, 0.33, 0.97, 1.0) # Violet / Purple

@export_group("Base Attributes")
@export_range(50.0, 500.0, 1.0) var max_health: float = 100.0
@export_range(20.0, 300.0, 1.0) var max_poise: float = 100.0
@export_range(50.0, 600.0, 10.0) var base_walk_speed: float = 220.0
@export_range(100.0, 800.0, 10.0) var base_dash_speed: float = 450.0
@export var jump_velocity: float = -420.0
@export var weight_class: String = "agile"

@export_group("Visual Reference")
@export var portrait_icon: Texture2D
