extends StaticBody3D
class_name Door

@export var _pivot: Node3D = null
@export var _direction: bool = true
@export var _locked: bool = false
@export var _angle: float = 90.0
@export var _speed: float = 5.0

var _target_angle: float = 0.0

func _process(delta: float) -> void:
  if _pivot == null:
    return
  _pivot.rotation_degrees.y = lerp(_pivot.rotation_degrees.y, _target_angle, _speed * delta)

func interact(player: Node) -> void:
  if _is_animating():
    return
  if _locked:
    player.show_message("La porte est vérouillée.", 3.0)
    return
  _target_angle = 0.0 if _is_opened() else _angle * (1.0 if _direction else -1.0)

func _is_animating() -> bool:
  if _pivot == null:
    return false
  return abs(_pivot.rotation_degrees.y - _target_angle) > 0.5

func _is_opened() -> bool:
  return _target_angle != 0.0

func get_interaction_hint(_player: Node) -> String:
  if _is_animating():
    return ""
  return "[ESPACE] Fermer" if _is_opened() else "[ESPACE] Ouvrir"
