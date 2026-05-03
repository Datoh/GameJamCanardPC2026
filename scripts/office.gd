extends Node3D

@onready var _player: CharacterBody3D = %Player
@onready var _mouse: CharacterBody3D = %Mouse
@onready var _cheese_in_maze: Node3D = %CheeseInMaze

@onready var _machines := {
  #MachineSutom.machine_name: %SutomMachine,
  MachineMaze.NAME: %MazeMachine,
  #MachineTV.machine_name: %TVMachine,
}

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
      _player.pickup(_mouse, "souris")
