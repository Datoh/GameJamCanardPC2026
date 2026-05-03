extends CharacterBody3D

const SPEED := 2.5
const STOP_DISTANCE := 2.0
const ACCEL := 8.0
const ROTATION_SPEED := 5.0

const EYE_RADIUS := 0.08

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player: Node3D
var _forced_target: Vector3 = Vector3.ZERO
var _is_forced: bool = false
var _following: bool = false

@onready var _pupils: Array = [%Pupil0, %Pupil1]
@onready var _navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D

func _ready() -> void:
  _navigation_agent_3d.target_desired_distance = STOP_DISTANCE
  await get_tree().process_frame
  _player = get_tree().get_first_node_in_group("player")

func start_following() -> void:
  _following = true

func go_to_position(pos: Vector3) -> void:
  _forced_target = pos
  _is_forced = true

func resume_follow() -> void:
  _is_forced = false

var _debug_tick: int = 0

func _physics_process(delta: float) -> void:
  if not is_on_floor():
    velocity.y -= gravity * delta

  if _is_forced:
    _navigation_agent_3d.target_position = _forced_target
  elif _following and _player != null:
    _navigation_agent_3d.target_position = _player.global_position

  var should_move := (_is_forced or _following) and not _navigation_agent_3d.is_navigation_finished()

  _debug_tick += 1
  if _debug_tick % 60 == 0:
    print("[Robot] _following=%s _is_forced=%s should_move=%s nav_finished=%s target_reachable=%s" % [
      _following, _is_forced, should_move,
      _navigation_agent_3d.is_navigation_finished(),
      _navigation_agent_3d.is_target_reachable()
    ])
    print("[Robot] target_pos=%s current_pos=%s dist=%.2f" % [
      _navigation_agent_3d.target_position,
      global_position,
      global_position.distance_to(_navigation_agent_3d.target_position)
    ])
    if should_move:
      var np := _navigation_agent_3d.get_next_path_position()
      print("[Robot] next_path_pos=%s dir_len=%.3f" % [
        np, (np - global_position).length()
      ])

  if should_move:
    var next_pos := _navigation_agent_3d.get_next_path_position()
    var dir := next_pos - global_position
    dir.y = 0.0
    if dir.length() < 0.01:
      dir = _navigation_agent_3d.target_position - global_position
      dir.y = 0.0
    dir = dir.normalized()
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
