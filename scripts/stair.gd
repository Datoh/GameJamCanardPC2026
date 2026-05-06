extends Node3D
class_name Stair

@export var step = 0

signal move()

func _on_area_3d_up_down_body_entered(_body: Node3D) -> void:
  move.emit()
