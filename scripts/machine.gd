extends StaticBody3D
class_name Machine

enum StateMachine { IDLE, TRY_MACHINE, ROBOT_WORKING, ROBOT_DONE, TRY_MACHINE_OBJECT, TRY_MACHINE_OK, WAITING_UNLOCKED, UNLOCKED, SOLVED }

signal machine_try_ok(machine: Node)
signal machine_done(machine: Node)

var machine_name: String = ""
var object_required: String = ""
var dialogue_demande: String = ""
var dialogue_resultat: String = ""
var robot_work_duration: float = 15.0

@export_group("Messages")
@export var message_idle: String = ""
@export var message_robot_working: String = ""
@export var message_robot_done: String = ""
@export var message_try_machine: String = ""
@export var message_try_machine_object: String = ""
@export var message_try_machine_ok: String = ""
@export var message_waiting_unlocked: String = ""
@export var message_solved: String = ""

@export_group("Hints")
@export var hint_default: String = "[ESPACE] Interagir."
@export var hint_idle: String = ""
@export var hint_robot_working: String = ""
@export var hint_robot_done: String = ""
@export var hint_try_machine: String = ""
@export var hint_waiting_unlocked: String = ""
@export var hint_solved: String = ""

func interact(player: Node) -> void:
  var state = player.state_machine[machine_name]
  match state:
    StateMachine.IDLE:
      player.show_message(message_idle, 3.0)
      player.state_machine[machine_name] = StateMachine.TRY_MACHINE
      _on_try_machine(player, false)
    StateMachine.TRY_MACHINE:
      _on_try_machine(player, false)
    StateMachine.ROBOT_WORKING:
      player.show_message(message_robot_working, 3.0)
    StateMachine.ROBOT_DONE:
      player.show_message(message_robot_done, 3.0)
    StateMachine.TRY_MACHINE_OBJECT:
      _on_try_machine(player, false)
    StateMachine.TRY_MACHINE_OK:
      _on_try_machine(player, true)
    StateMachine.WAITING_UNLOCKED:
      player.show_message(message_waiting_unlocked, 3.0)
    StateMachine.UNLOCKED:
      player.show_message(message_solved, 3.0)
      player.state_machine[machine_name] = StateMachine.SOLVED
      machine_done.emit(self)
    StateMachine.SOLVED:
      player.show_message(message_solved, 3.0)

func get_interaction_hint(player: Node) -> String:
  var state = player.state_machine[machine_name]
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
  return hint_default if hint.is_empty() else hint

func _on_try_machine(player: Node, has_object: bool) -> void:
  _on_try_machine_done(player, has_object)

func _on_try_machine_done(player: Node, won: bool) -> void:
  var state = player.state_machine[machine_name]
  match state:
    StateMachine.TRY_MACHINE:
      player.show_message(message_try_machine, 3.0)
    StateMachine.TRY_MACHINE_OBJECT:
      player.show_message(message_try_machine_object, 3.0)
    StateMachine.TRY_MACHINE_OK:
      if won:
        machine_try_ok.emit(self)
      else:
        player.show_message(message_try_machine_ok, 3.0)

func on_dialogue_completed(dialogue_id: String, player: Node) -> void:
  if dialogue_demande.is_empty():
    return
  if dialogue_id == dialogue_demande:
    player.state_machine[machine_name] = StateMachine.ROBOT_WORKING
    player.start_robot_work(self, robot_work_duration)
  elif dialogue_id == dialogue_resultat:
    player.state_machine[machine_name] = StateMachine.TRY_MACHINE_OBJECT

func is_dialogue_locked(dialogue_id: String, player: Node) -> bool:
  if not dialogue_demande.is_empty() and dialogue_id == dialogue_demande:
    return player.state_machine.get(machine_name, 0) != StateMachine.TRY_MACHINE
  if not dialogue_resultat.is_empty() and dialogue_id == dialogue_resultat:
    return player.state_machine.get(machine_name, 0) != StateMachine.ROBOT_DONE
  return false
