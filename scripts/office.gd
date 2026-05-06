extends Node3D

const _TITLE_SCREEN  := preload("res://scenes/title_screen.tscn")
const _END_SCREEN    := preload("res://scenes/end_screen.tscn")
const _OPTIONS_MENU  := preload("res://scenes/options_menu.tscn")

@onready var _player: CharacterBody3D = %Player
@onready var _mouse: CharacterBody3D = %Mouse
@onready var _robot: CharacterBody3D = %Robot
@onready var _position_robot:     RayCast3D = %PositionRobot
@onready var _position_robot_end: RayCast3D = %PositionRobotEnd
@onready var _cheese_in_maze: Node3D = %CheeseInMaze
@onready var _camera_3d_end: Camera3D = %Camera3DEnd
@onready var _position_robot_cofee: RayCast3D = %PositionRobotCofee

@onready var _machines := {
  MachineSutom.NAME:  %SutomMachine,
  MachineMaze.NAME:   %MazeMachine,
  MachineOscillo.NAME: %OscilloMachine,
  #MachineTV.machine_name: %TVMachine,
}

var _ivan_door_unlocked: bool = false
var _options_canvas: CanvasLayer
var _options_menu: OptionsMenu
var _prev_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
  if _ivan_door_unlocked:
    return
  if _player.state_machine.get("Screen", Machine.StateMachine.IDLE) == Machine.StateMachine.SOLVED:
    _ivan_door_unlocked = true
    for door in get_tree().get_nodes_in_group("door_ivan"):
      door.unlock()

func _ready() -> void:
  _player.visible = false
  _player.set_hud_visible(false)
  _player.game_finished.connect(_on_game_finished)
  _player.dialogue_side_effect.connect(_on_dialogue_side_effect)
  _options_canvas = CanvasLayer.new()
  _options_canvas.layer = 20
  add_child(_options_canvas)
  _options_menu = _OPTIONS_MENU.instantiate()
  _options_menu.closed.connect(_on_options_closed)
  _options_canvas.add_child(_options_menu)

  var ts := _TITLE_SCREEN.instantiate()
  ts.started.connect(_on_title_started)
  ts.options_requested.connect(_on_title_options_requested)
  add_child(ts)

  %Ceil.visible = true
  for machine in _machines.values():
    machine.machine_try_ok.connect(_on_machine_try_ok)
    machine.machine_done.connect(_on_machine_done)
  %MazeMachine.robot_go_coffee.connect(_on_robot_go_coffee)

func _on_title_options_requested() -> void:
  _options_menu.show()

func _on_title_started() -> void:
  _player.visible = true
  _player.set_hud_visible(true)
  _player.activate_camera()
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_game_finished() -> void:
  _player.visible = false
  _player.set_hud_visible(false)
  _player.set_process_unhandled_input(false)
  _camera_3d_end.make_current()
  if is_instance_valid(_mouse):
    _mouse.visible = true
    _mouse.set_physics_process(true)
    _mouse.reset()
  var cast_dir := (_position_robot_end.global_basis * _position_robot_end.target_position).normalized()
  _robot.place(_position_robot_end.global_position, cast_dir)
  add_child(_END_SCREEN.instantiate())


func _on_machine_try_ok(machine: Node):
  match machine.machine_name:
    MachineMaze.NAME:
      AudioManager.play(AudioData.AUDIO_MOUSE_PICK, _mouse.global_position)
      _mouse.go_to_cheese()
      _cheese_in_maze.visible = true


func _on_machine_done(machine: Node):
  match machine.machine_name:
    MachineMaze.NAME:
      if is_instance_valid(_mouse):
        _player.inventory.append("souris")
        AudioManager.play(AudioData.AUDIO_MOUSE_PICK, _mouse.global_position)
        _player.show_message("Vous ramassez : souris.", 2.0)
        _mouse.visible = false
        _mouse.set_physics_process(false)
    MachineSutom.NAME:
      _robot.stop_coffee_mode()
      _player.suppress_dialogue("labyrinthe_seul")
    MachineOscillo.NAME:
      _player.suppress_dialogue("oscillo_done")


func _unhandled_input(event: InputEvent) -> void:
  if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1):
    return
  get_viewport().set_input_as_handled()
  if _options_menu.visible:
    _options_menu.hide()
    _on_options_closed()
  else:
    _prev_mouse_mode = Input.get_mouse_mode()
    _options_menu.show()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_options_closed() -> void:
  Input.set_mouse_mode(_prev_mouse_mode)

func _on_dialogue_side_effect(dialogue_id: String) -> void:
  if dialogue_id == "ordinateur_dlss5":
    _options_menu.reveal_dlss_option()

func _on_area_close_door_body_entered(_body: Node3D) -> void:
  for door in get_tree().get_nodes_in_group("door_ivan"):
    if door.is_opened():
      door.lock()
      %AreaCloseDoor.queue_free()


func _on_robot_go_coffee() -> void:
  var cast_dir := (_position_robot_cofee.global_basis * _position_robot_cofee.target_position).normalized()
  _robot.set_coffee_mode(_position_robot_cofee.global_position, cast_dir)


func _on_area_robot_inside_body_entered(body: Node3D) -> void:
  if body != _robot:
    return
  _robot.go_to_position(_position_robot.global_position)
  var cast_dir := (_position_robot.global_basis * _position_robot.target_position).normalized()
  _robot.face_direction(cast_dir)
