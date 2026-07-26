class_name GameDataObject
extends Node

const GROUP_INTERACTIVE := "interactive"
const GROUP_PLAYER := "player"
const GROUP_ROBOT := "robot"
const GROUP_MACHINE := "machine"
const GROUP_CPC := "cpc"
const GROUP_IVAN := "ivan"
const GROUP_DOOR_IVAN := "door_ivan"

signal intro_completed
signal objectives_changed
signal secondary_objective_added(key: String, params: Array)
signal machine_state_changed(machine_name: String, state: Machine.StateMachine)
signal pc_issues_found
signal password_unknown_found
signal minigame_closed(machine_name: String)

var _state_machine: Dictionary = {}
var player: Player

var minigame_name: String = "":
  set(value):
    var previous := minigame_name
    minigame_name = value
    if player.crosshair:
      player.crosshair.visible = value.is_empty()
    if value.is_empty() and not previous.is_empty():
      minigame_closed.emit(previous)

var in_minigame: bool:
  get():
    return not minigame_name.is_empty()

var intro_done := false:
  set(value):
    intro_done = value
    if value:
      intro_completed.emit()

var cpc_collected: Array[int] = []

var _objectives: Array = []
var _objective_counter: int = 0


func _ready() -> void:
  await get_tree().process_frame
  player = get_tree().get_first_node_in_group(GameData.GROUP_PLAYER)
  for machine in get_tree().get_nodes_in_group(GameData.GROUP_MACHINE):
    _state_machine[machine.machine_name] = Machine.StateMachine.IDLE


func state(machine_name: String, default: Machine.StateMachine = Machine.StateMachine.IDLE) -> Machine.StateMachine:
  return _state_machine.get(machine_name, default)


func set_state(machine_name: String, value: Machine.StateMachine) -> void:
  if _state_machine.get(machine_name) == value:
    return
  _state_machine[machine_name] = value
  machine_state_changed.emit(machine_name, value)


func notify_pc_issues_found() -> void:
  pc_issues_found.emit()


func notify_password_unknown_found() -> void:
  password_unknown_found.emit()


func show_message(text: String, duration: float = 3.0) -> void:
  if player:
    player.show_message(text, duration)


func add_objective(key: String, is_primary: bool, params: Array = []) -> void:
  _objectives.append({
    "key": key,
    "is_primary": is_primary,
    "is_done": false,
    "index": _objective_counter,
    "params": params,
  })
  _objective_counter += 1
  objectives_changed.emit()
  if not is_primary:
    secondary_objective_added.emit(key, params)


func complete_objective(key: String) -> void:
  for i in _objectives.size():
    if _objectives[i]["key"] == key and not _objectives[i]["is_done"]:
      _objectives[i]["is_done"] = true
      objectives_changed.emit()
      return


func has_objective(key: String) -> bool:
  for objective in _objectives:
    if objective["key"] == key:
      return true
  return false


func update_objective_params(key: String, params: Array) -> void:
  for i in _objectives.size():
    if _objectives[i]["key"] == key:
      _objectives[i]["params"] = params
      objectives_changed.emit()
      return


func get_objectives() -> Array:
  return _objectives
