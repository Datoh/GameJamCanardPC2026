extends Node

var _state_machine: Dictionary = {}
var player: Player

var minigame_name: String = "":
  set(value):
    minigame_name = value
    if player.crosshair:
      player.crosshair.visible = not value.is_empty()

var in_minigame: bool:
  get():
    return not minigame_name.is_empty()

var intro_done := false
var cpc_collected: Array[int] = []

func _ready() -> void:
  await get_tree().process_frame
  for a_player in get_tree().get_nodes_in_group("player"):
    player = a_player
  for machine in get_tree().get_nodes_in_group("machine"):
    _state_machine[machine.machine_name] = Machine.StateMachine.IDLE

func state(machine_name: String, default: Machine.StateMachine = Machine.StateMachine.IDLE) -> Machine.StateMachine:
  return _state_machine.get(machine_name, default)

func set_state(machine_name: String, value: Machine.StateMachine) -> void:
  _state_machine[machine_name] = value
