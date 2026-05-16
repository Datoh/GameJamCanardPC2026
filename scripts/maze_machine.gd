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
  message_try_machine_object = tr("msgNeedMouseBait")
  message_try_machine_ok = tr("msgComeMouse")
  message_waiting_unlocked = tr("msgMouseComing")
  message_solved = tr("msgMazeDone")
  hint_default = tr("hintObserveMaze")
  add_child(_timer_mouse)
  _timer_mouse.timeout.connect(_on_timer_mouse_timeout)
  _timer_mouse.start(randf_range(2.0, 4.0))
  _mouse.cheese_reached.connect(_on_mouse_cheese_reached)


func interact(player: Node) -> void:
  _player_ref = player
  message_try_machine = tr("msgMouseLost") % [DialoguesData.robot_name]
  message_robot_working = tr("msgRobotStudyingMaze") % [DialoguesData.robot_name]
  message_robot_done = tr("msgRobotSeemsDone") % [DialoguesData.robot_name]
  super.interact(player)


func _can_try(_player: Node) -> bool:
  return true


func is_dialogue_locked(dialogue_id: String, player: Node) -> bool:
  if dialogue_id == "labyrinthe_seul":
    return GameData.state(NAME) != Machine.StateMachine.SOLVED
  return super.is_dialogue_locked(dialogue_id, player)


func on_dialogue_completed(dialogue_id: String, player: Node) -> void:
  super.on_dialogue_completed(dialogue_id, player)
  if dialogue_id == "labyrinthe_seul":
    robot_sent_for_coffee.emit()


func _on_mouse_cheese_reached() -> void:
  GameData.set_state(NAME, Machine.StateMachine.UNLOCKED)


func _on_timer_mouse_timeout() -> void:
  if _mouse.visible:
    AudioManager.play(AudioData.AUDIO_MOUSE, _mouse.global_position, 8.0)
    _timer_mouse.start(randf_range(2.0, 4.0))
