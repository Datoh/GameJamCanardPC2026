class_name MachineMaze
extends Machine

signal robot_sent_for_coffee()

const NAME := "Maze"

@onready var _mouse: CharacterBody3D = %Mouse

var _player_ref: Node = null
var _timer_mouse := Timer.new()


func _ready() -> void:
  machine_name = NAME
  object_required = "Fromage"
  dialogue_demande = "labyrinthe_demande"
  dialogue_resultat = "labyrinthe_resultat"
  robot_work_duration = 15.0
  message_try_machine_object = "Il me faudrait quelque chose pour attirer la souris..."
  message_try_machine_ok = "Allez viens ma belle."
  message_waiting_unlocked = "Elle arrive..."
  message_solved = "Je n'ai plus rien à faire ici."
  hint_default = "[ESPACE] Observez le labyrinthe."
  add_child(_timer_mouse)
  _timer_mouse.timeout.connect(_on_timer_mouse_timeout)
  _timer_mouse.start(randf_range(2.0, 4.0))
  _mouse.cheese_reached.connect(_on_mouse_cheese_reached)


func interact(player: Node) -> void:
  _player_ref = player
  message_try_machine = "La souris ne trouve pas la sortie... je vais demander de l'aide à %s" % DialoguesData.robot_name + "."
  message_robot_working = "%s" % DialoguesData.robot_name + " est en train d'étudier le labyrinthe..."
  message_robot_done = "Je devrais parler à %s" % DialoguesData.robot_name + ", il a l'air d'avoir terminé."
  super.interact(player)


func _can_try(_player: Node) -> bool:
  return true


func is_dialogue_locked(dialogue_id: String, player: Node) -> bool:
  if dialogue_id == "labyrinthe_seul":
    return player.state_machine.get(NAME, 0) != Machine.StateMachine.SOLVED
  return super.is_dialogue_locked(dialogue_id, player)


func on_dialogue_completed(dialogue_id: String, player: Node) -> void:
  super.on_dialogue_completed(dialogue_id, player)
  if dialogue_id == "labyrinthe_seul":
    robot_sent_for_coffee.emit()


func _on_mouse_cheese_reached() -> void:
  if _player_ref != null:
    _player_ref.state_machine[NAME] = Machine.StateMachine.UNLOCKED


func _on_timer_mouse_timeout() -> void:
  if _mouse.visible:
    AudioManager.play(AudioData.AUDIO_MOUSE, _mouse.global_position, 8.0)
    _timer_mouse.start(randf_range(2.0, 4.0))
