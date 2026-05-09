extends Node3D
class_name Stair

@export var _step_label: Node3D = null

@export var id := 1

var _labels := [
  preload("res://assets/textures/wall_stencil_0.png"),
  preload("res://assets/textures/wall_stencil_1.png"),
  preload("res://assets/textures/wall_stencil_2.png"),
  preload("res://assets/textures/wall_stencil_3.png"),
  preload("res://assets/textures/wall_stencil_4.png"),
  preload("res://assets/textures/wall_stencil_5.png"),
  preload("res://assets/textures/wall_stencil_6.png"),
  preload("res://assets/textures/wall_stencil_7.png"),
  preload("res://assets/textures/wall_stencil_8.png"),
  preload("res://assets/textures/wall_stencil_9.png"),
]

signal move()

var step_offset := 0:
  set(value):
    step_offset = value
    _update_stair()
var step: int = 0:
  set(value):
    step = value
    _update_stair()

func _update_stair():
    if _step_label:
      var numbers := _step_label.get_child_count()
      var step_label := "%*d" % [numbers, (step - step_offset) % floori(pow(10, numbers))]
      var index := 0
      for c in step_label:
        var node := _step_label.get_child(index)
        node.visible = c != " "
        if node.visible:
          var mat = node.get_surface_override_material(0).duplicate()
          mat.albedo_texture = _labels[int(c)]
          node.set_surface_override_material(0, mat)
        index += 1

func _on_area_3d_up_down_body_entered(_body: Node3D) -> void:
  move.emit()
