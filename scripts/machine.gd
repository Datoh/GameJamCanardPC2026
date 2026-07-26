class_name Machine
extends StaticBody3D

signal machine_attempt_succeeded(machine: Node)
signal machine_done(machine: Node)

enum StateMachine { IDLE, TRY_MACHINE, ROBOT_WORKING, ROBOT_DONE, TRY_MACHINE_OBJECT, TRY_MACHINE_OK, WAITING_UNLOCKED, UNLOCKED, SOLVED }

var machine_name: String = ""
var object_required: String = ""
var dialogue_demande: String = ""
var dialogue_resultat: String = ""
var robot_work_duration: float = 15.0

@export_group("Messages")
@export var message_not_enable: String = ""
@export var message_idle: String = ""
@export var message_robot_working: String = ""
@export var message_robot_done: String = ""
@export var message_try_machine: String = ""
@export var message_try_machine_object: String = ""
@export var message_try_machine_ok: String = ""
@export var message_waiting_unlocked: String = ""
@export var message_solved: String = ""

@export_group("Hints")
@export var hint_default: String = "hintInteract"
@export var hint_idle: String = ""
@export var hint_robot_working: String = ""
@export var hint_robot_done: String = ""
@export var hint_try_machine: String = ""
@export var hint_waiting_unlocked: String = ""
@export var hint_solved: String = ""


func interact() -> void:
  var state := GameData.state(machine_name)
  match state:
    StateMachine.IDLE:
      if not _can_try():
        GameData.show_message(message_not_enable, 3.0)
      else:
        GameData.show_message(message_idle, 3.0)
        GameData.set_state(machine_name, StateMachine.TRY_MACHINE)
        _on_try_machine(false)
    StateMachine.TRY_MACHINE:
      GameData.show_message(message_try_machine, 3.0)
      _on_try_machine(false)
    StateMachine.ROBOT_WORKING:
      GameData.show_message(message_robot_working, 3.0)
    StateMachine.ROBOT_DONE:
      GameData.show_message(message_robot_done, 3.0)
    StateMachine.TRY_MACHINE_OBJECT:
      _on_try_machine(false)
    StateMachine.TRY_MACHINE_OK:
      _on_try_machine(true)
    StateMachine.WAITING_UNLOCKED:
      GameData.show_message(message_waiting_unlocked, 3.0)
    StateMachine.UNLOCKED:
      GameData.show_message(message_solved, 3.0)
      GameData.set_state(machine_name, StateMachine.SOLVED)
      machine_done.emit(self)
    StateMachine.SOLVED:
      GameData.show_message(message_solved, 3.0)


func _can_try() -> bool:
  return false


func get_interaction_hint() -> String:
  var state := GameData.state(machine_name)
  var hint := ""
  match state:
    StateMachine.IDLE:
      hint = hint_idle
    StateMachine.TRY_MACHINE:
      hint = hint_try_machine
    StateMachine.ROBOT_WORKING:
      hint = hint_robot_working
    StateMachine.ROBOT_DONE:
      hint = hint_robot_done
    StateMachine.WAITING_UNLOCKED:
      hint = hint_waiting_unlocked
    StateMachine.UNLOCKED:
      hint = hint_solved
  return tr(hint_default) if hint.is_empty() else tr(hint)


func on_dialogue_completed(dialogue_id: String) -> void:
  if dialogue_demande.is_empty():
    return
  if dialogue_id == dialogue_demande:
    GameData.set_state(machine_name, StateMachine.ROBOT_WORKING)
    GameData.player.start_robot_work(self, robot_work_duration)
  elif dialogue_id == dialogue_resultat:
    GameData.set_state(machine_name, StateMachine.TRY_MACHINE_OBJECT)


func is_dialogue_locked(dialogue_id: String) -> bool:
  if not dialogue_demande.is_empty() and dialogue_id == dialogue_demande:
    return GameData.state(machine_name) != StateMachine.TRY_MACHINE
  if not dialogue_resultat.is_empty() and dialogue_id == dialogue_resultat:
    return GameData.state(machine_name) != StateMachine.ROBOT_DONE
  return false


func _on_try_machine(has_object: bool) -> void:
  _on_try_machine_done(has_object)


func _on_try_machine_done(won: bool) -> void:
  var state := GameData.state(machine_name)
  match state:
    StateMachine.TRY_MACHINE:
      GameData.show_message(message_try_machine, 3.0)
    StateMachine.TRY_MACHINE_OBJECT:
      GameData.show_message(message_try_machine_object, 3.0)
    StateMachine.TRY_MACHINE_OK:
      if won:
        machine_attempt_succeeded.emit(self)
      else:
        GameData.show_message(message_try_machine_ok, 3.0)
