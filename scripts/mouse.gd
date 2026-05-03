extends CharacterBody3D


const SPEED = 1.0
const ROTATION_SPEED = 30.0

@onready var _navigation_agent_mouse: NavigationAgent3D = $NavigationAgentMouse
@onready var _point_to_reaches: Node3D = %PointToReaches
@onready var _marker_out_maze: Marker3D = %MarkerOutMaze
@export var _player: CharacterBody3D = null

var _go_to_cheese := false

func go_to_cheese():
  _go_to_cheese = true
  _assign_next_target()

func _ready() -> void:
  _navigation_agent_mouse.path_desired_distance = 0.01
  _navigation_agent_mouse.target_desired_distance = 0.02

  # Différé : le NavigationServer doit être initialisé avant la première requête
  _assign_next_target.call_deferred()

func _assign_next_target() -> void:
  if not _go_to_cheese:
    _navigation_agent_mouse.target_position = _point_to_reaches.get_child(
      randi_range(0, _point_to_reaches.get_child_count() - 1)
    ).global_position
  else:
    _navigation_agent_mouse.target_position = _marker_out_maze.global_position

func _physics_process(delta: float) -> void:
  if _navigation_agent_mouse.is_navigation_finished():
    if _go_to_cheese:
      _player.state_machine[MachineMaze.NAME] = Machine.StateMachine.UNLOCKED
    else:
      _assign_next_target()
    return
  var destination := _navigation_agent_mouse.get_next_path_position()
  var direction = (destination - global_position).normalized()
  direction.y = 0.0
  if direction.length_squared() > 0.001:
    var target_angle := atan2(direction.x, direction.z)
    rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)
  velocity = direction * SPEED
  move_and_slide()
