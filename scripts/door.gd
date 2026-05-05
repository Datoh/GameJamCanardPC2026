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
  AudioManager.play(AudioData.AUDIO_DOOR_CLOSE if is_opened() else AudioData.AUDIO_DOOR_OPEN, global_position)
  _target_angle = 0.0 if is_opened() else _angle * (1.0 if _direction else -1.0)

func lock():
  if is_opened():
    AudioManager.play(AudioData.AUDIO_DOOR_CLOSE, global_position)
  _target_angle = 0.0
  _locked = true

func unlock():
  _locked = false

func _is_animating() -> bool:
  if _pivot == null:
    return false
  return abs(_pivot.rotation_degrees.y - _target_angle) > 0.5

func is_opened() -> bool:
  return _target_angle != 0.0

func get_interaction_hint(_player: Node) -> String:
  if _is_animating():
    return ""
  return "[ESPACE] Fermer" if is_opened() else "[ESPACE] Ouvrir"
