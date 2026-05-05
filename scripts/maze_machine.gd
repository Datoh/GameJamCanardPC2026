extends Machine
class_name MachineMaze

signal robot_go_coffee

const NAME := "Maze"
@onready var _mouse: CharacterBody3D = %Mouse
var _timer_mouse := Timer.new()

func _ready() -> void:
  machine_name = NAME
  object_required = "Fromage"
  dialogue_demande = "labyrinthe_demande"
  dialogue_resultat = "labyrinthe_resultat"
  robot_work_duration = 15.0
  message_try_machine = "La souris ne trouve pas la sortie... je vais demander de l'aide à %s" % DialoguesData.robot_name + "."
  message_robot_working = "%s" % DialoguesData.robot_name + " est en train d'étudier le labyrinthe..."
  message_robot_done = "Je devrais parler à %s" % DialoguesData.robot_name + ", il a l'air d'avoir terminé."
  message_try_machine_object = "Il me faudrait quelque chose pour attirer la souris..."
  message_try_machine_ok = "Allez viens ma belle."
  message_waiting_unlocked = "Elle arrive..."
  message_solved = "Je n'ai plus rien à faire ici."
  hint_default = "[ESPACE] Observez le labyrinthe."
  add_child(_timer_mouse)
  _timer_mouse.timeout.connect(_on_timer_mouse_timeout)
  _timer_mouse.start(randf_range(2.0, 4.0))

func _can_try(_player: Node) -> bool:
  return true

func is_dialogue_locked(dialogue_id: String, player: Node) -> bool:
  if dialogue_id == "labyrinthe_seul":
    return player.state_machine.get(NAME, 0) != Machine.StateMachine.SOLVED
  return super.is_dialogue_locked(dialogue_id, player)

func on_dialogue_completed(dialogue_id: String, player: Node) -> void:
  super.on_dialogue_completed(dialogue_id, player)
  if dialogue_id == "labyrinthe_seul":
    robot_go_coffee.emit()

func _on_timer_mouse_timeout() -> void:
  if _mouse.visible:
    AudioManager.play(AudioData.AUDIO_MOUSE, _mouse.global_position, 8.0)
    _timer_mouse.start(randf_range(2.0, 4.0))
