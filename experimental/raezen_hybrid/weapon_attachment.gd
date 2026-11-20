extends Marker2D
## Coordinates are local to the primary palm. The blade owns its painted grip.

var pivot: Node2D
var offhand: Marker2D
var tip: Marker2D


func configure(offhand_offset: Vector2, tip_offset: Vector2) -> void:
	pivot = Node2D.new()
	pivot.name = "BladePivot"
	add_child(pivot)
	offhand = _marker(&"OffhandGrip", offhand_offset)
	tip = _marker(&"BladeTip", tip_offset)


func _marker(label: StringName, offset: Vector2) -> Marker2D:
	var marker: Marker2D = Marker2D.new()
	marker.name = label
	marker.position = offset
	pivot.add_child(marker)
	return marker


func set_pose(angle: float) -> void:
	pivot.rotation = deg_to_rad(angle)
