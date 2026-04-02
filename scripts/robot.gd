extends CharacterBody3D

const SPEED := 2.5
const STOP_DISTANCE := 2.0
const ACCEL := 8.0
const ROTATION_SPEED := 5.0

const EYE_RADIUS := 0.08

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player: Node3D
var _pupils: Array = []
var _forced_target: Vector3 = Vector3.ZERO
var _is_forced: bool = false

func _ready() -> void:
  await get_tree().process_frame
  _player = get_tree().get_first_node_in_group("player")
  for i in range(2):
    var pupil = get_node_or_null("Eye%d/Pupil" % i)
    if pupil:
      _pupils.append(pupil)

func go_to_position(pos: Vector3) -> void:
  _forced_target = pos
  _is_forced = true

func resume_follow() -> void:
  _is_forced = false

func _physics_process(delta: float) -> void:
  if not is_on_floor():
    velocity.y -= gravity * delta

  var move_target: Vector3
  var has_target := false

  if _is_forced:
    move_target = _forced_target
    has_target = true
  elif _player != null:
    move_target = _player.global_position
    has_target = true

  if has_target:
    var to_target := move_target - global_position
    to_target.y = 0.0
    var distance := to_target.length()

    if distance > STOP_DISTANCE:
      var dir := to_target.normalized()
      velocity.x = lerp(velocity.x, dir.x * SPEED, delta * ACCEL)
      velocity.z = lerp(velocity.z, dir.z * SPEED, delta * ACCEL)
      rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * ROTATION_SPEED)
    else:
      velocity.x = lerp(velocity.x, 0.0, delta * ACCEL)
      velocity.z = lerp(velocity.z, 0.0, delta * ACCEL)

  if _player != null:
    var player_eye_pos := _player.global_position + Vector3(0, 0.7, 0)
    for pupil in _pupils:
      var eye_pos: Vector3 = pupil.get_parent().global_position
      var dir: Vector3 = (player_eye_pos - eye_pos).normalized()
      pupil.global_position = eye_pos + dir * EYE_RADIUS

  move_and_slide()
