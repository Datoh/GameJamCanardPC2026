extends Node3D

@onready var _player: CharacterBody3D = %Player
@onready var _mouse: CharacterBody3D = %Mouse
@onready var _robot: CharacterBody3D = %Robot
@onready var _position_robot: RayCast3D = %PositionRobot
@onready var _cheese_in_maze: Node3D = %CheeseInMaze

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
  %Ceil.visible = true
  for machine in _machines.values():
    machine.machine_try_ok.connect(_on_machine_try_ok)
    machine.machine_done.connect(_on_machine_done)


func _on_machine_try_ok(machine: Node):
  match machine.machine_name:
    MachineMaze.NAME:
      _mouse.go_to_cheese()
      _cheese_in_maze.visible = true


func _on_machine_done(machine: Node):
  match machine.machine_name:
    MachineMaze.NAME:
      if _mouse:
        _player.pickup(_mouse, "souris")


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
