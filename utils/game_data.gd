class_name GameDataObject
extends Node

const GROUP_INTERACTIVE := "interactive"
const GROUP_PLAYER := "player"
const GROUP_ROBOT := "robot"
const GROUP_MACHINE := "machine"
const GROUP_CPC := "cpc"
const GROUP_IVAN := "ivan"
const GROUP_WORLD_ENVIRONMENT := "world_environment"
const GROUP_DOOR_IVAN := "door_ivan"

var _state_machine: Dictionary = {}
var player: Player

var minigame_name: String = "":
  set(value):
    minigame_name = value
    if player.crosshair:
      player.crosshair.visible = value.is_empty()

var in_minigame: bool:
  get():
    return not minigame_name.is_empty()

var intro_done := false
var cpc_collected: Array[int] = []

func _ready() -> void:
  await get_tree().process_frame
  player = get_tree().get_first_node_in_group(GameData.GROUP_PLAYER)
  for machine in get_tree().get_nodes_in_group(GameData.GROUP_MACHINE):
    _state_machine[machine.machine_name] = Machine.StateMachine.IDLE

func state(machine_name: String, default: Machine.StateMachine = Machine.StateMachine.IDLE) -> Machine.StateMachine:
  return _state_machine.get(machine_name, default)

func set_state(machine_name: String, value: Machine.StateMachine) -> void:
  _state_machine[machine_name] = value


func show_message(text: String, duration: float = 3.0) -> void:
  if player:
    player.show_message(text, duration)
