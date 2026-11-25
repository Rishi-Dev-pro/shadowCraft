class_name WeaponData
extends Resource

enum Category { SWORD, AXE, SPEAR, MACE }
enum MaterialTier { WOOD, STONE, IRON, DIAMOND, NETHERITE }

@export var weapon_id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.AXE
@export var material_tier: MaterialTier = MaterialTier.STONE
@export var weapon_scene: PackedScene
@export var light_attack: AttackData
@export var heavy_attack: AttackData
@export var sweep_attack: AttackData
