extends Node3D

const _TITLE_SCREEN := preload("res://scenes/title_screen.tscn")
const _END_SCREEN   := preload("res://scenes/end_screen.tscn")

@onready var _player: CharacterBody3D = %Player
@onready var _mouse: CharacterBody3D = %Mouse
@onready var _robot: CharacterBody3D = %Robot
@onready var _position_robot:     RayCast3D = %PositionRobot
@onready var _position_robot_end: RayCast3D = %PositionRobotEnd
@onready var _cheese_in_maze: Node3D = %CheeseInMaze
@onready var _camera_3d_end: Camera3D = %Camera3DEnd

@onready var _machines := {
  #MachineSutom.machine_name: %SutomMachine,
  MachineMaze.NAME: %MazeMachine,
  #MachineTV.machine_name: %TVMachine,
}

var _ivan_door_unlocked: bool = false

func _process(_delta: float) -> void:
  if _ivan_door_unlocked:
    return
  if _player.state_machine.get("Screen", Machine.StateMachine.IDLE) == Machine.StateMachine.SOLVED:
    _ivan_door_unlocked = true
    for door in get_tree().get_nodes_in_group("door_ivan"):
      door.unlock()

func _ready() -> void:
  _player.visible = false
  _player.set_hud_visible(false)
  _player.game_finished.connect(_on_game_finished)
  var ts := _TITLE_SCREEN.instantiate()
  ts.started.connect(_on_title_started)
  add_child(ts)

  %Ceil.visible = true
  for machine in _machines.values():
    machine.machine_try_ok.connect(_on_machine_try_ok)
    machine.machine_done.connect(_on_machine_done)

func _on_title_started() -> void:
  _player.visible = true
  _player.set_hud_visible(true)
  _player.activate_camera()
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_game_finished() -> void:
  _player.visible = false
  _player.set_hud_visible(false)
  _player.set_process_unhandled_input(false)
  _camera_3d_end.make_current()
  if is_instance_valid(_mouse):
    _mouse.visible = true
    _mouse.set_physics_process(true)
    _mouse.reset()
  var cast_dir := (_position_robot_end.global_basis * _position_robot_end.target_position).normalized()
  _robot.place(_position_robot_end.global_position, cast_dir)
  add_child(_END_SCREEN.instantiate())


func _on_machine_try_ok(machine: Node):
  match machine.machine_name:
    MachineMaze.NAME:
      AudioManager.play(AudioData.AUDIO_MOUSE_PICK, _mouse.global_position)
      _mouse.go_to_cheese()
      _cheese_in_maze.visible = true


func _on_machine_done(machine: Node):
  match machine.machine_name:
    MachineMaze.NAME:
      if is_instance_valid(_mouse):
        _player.inventory.append("souris")
        AudioManager.play(AudioData.AUDIO_MOUSE_PICK, _mouse.global_position)
        _player.show_message("Vous ramassez : souris.", 2.0)
        _mouse.visible = false
        _mouse.set_physics_process(false)


func _on_area_close_door_body_entered(_body: Node3D) -> void:
  for door in get_tree().get_nodes_in_group("door_ivan"):
    if door.is_opened():
      door.lock()
      %AreaCloseDoor.queue_free()


func _on_area_robot_inside_body_entered(body: Node3D) -> void:
  if body != _robot:
    return
  _robot.go_to_position(_position_robot.global_position)
  var cast_dir := (_position_robot.global_basis * _position_robot.target_position).normalized()
  _robot.face_direction(cast_dir)
