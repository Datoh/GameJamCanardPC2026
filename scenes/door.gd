extends MeshInstance3D
class_name Door

@export var pivot: Node3D = null
@export var direction: bool = true
@export var angle: float = 90.0
@export var speed: float = 5.0

var _target_angle: float = 0.0

func _process(delta: float) -> void:
  if pivot == null:
    return
  pivot.rotation_degrees.y = lerp(pivot.rotation_degrees.y, _target_angle, speed * delta)

func open_close() -> void:
  if is_animating():
    return
  _target_angle = 0.0 if is_opened() else angle * (1.0 if direction else -1.0)

func is_animating() -> bool:
  if pivot == null:
    return false
  return abs(pivot.rotation_degrees.y - _target_angle) > 0.5

func is_opened() -> bool:
  return _target_angle != 0.0
