extends StaticBody3D

@export var light: Node = null

func _ready() -> void:
  add_to_group("interactive")
  set_collision_layer_value(4, true)

func interact(_player: Node) -> void:
  if light:
    light.visible = not light.visible

func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Allumer/Eteindre"
