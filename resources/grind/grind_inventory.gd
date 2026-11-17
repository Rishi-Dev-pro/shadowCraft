class_name GrindInventory
extends Resource

@export_range(0, 999999, 1) var wood: int = 0
@export_range(0, 999999, 1) var stick: int = 0
@export_range(0, 999999, 1) var stone: int = 0


func quantities() -> Array[int]:
	return [maxi(wood, 0), maxi(stick, 0), maxi(stone, 0)]
