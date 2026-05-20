extends Node3D

@onready var _player:               CharacterBody3D = %Player
@onready var _mouse:                CharacterBody3D = %Mouse
@onready var _robot:                CharacterBody3D = %Robot
@onready var _position_robot:       RayCast3D       = %PositionRobot
@onready var _position_robot_end:   RayCast3D       = %PositionRobotEnd
@onready var _cheese_in_maze:       Node3D          = %CheeseInMaze
@onready var _camera_3d_end:        Camera3D        = %Camera3DEnd
@onready var _position_robot_cofee: RayCast3D       = %PositionRobotCofee

@onready var _title_screen: Control     = %TitleScreen
@onready var _end_screen:   Control     = %EndScreen
@onready var _options_menu: OptionsMenu = %OptionsMenu

var _ivan_door_unlocked: bool = false
var _prev_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
  if _ivan_door_unlocked:
    return
  if GameData.state(ScreenMachine.NAME) == Machine.StateMachine.SOLVED:
    _ivan_door_unlocked = true
    for door in get_tree().get_nodes_in_group(GameData.GROUP_DOOR_IVAN):
      door.unlock()


func _ready() -> void:
  _player.visible = false
  _player.set_hud_visible(false)
  _player.set_process_unhandled_input(false)
  _player.game_finished.connect(_on_game_finished)

  _options_menu.closed.connect(_on_options_closed)
  _title_screen.started.connect(_on_title_started)
  _title_screen.options_requested.connect(_on_title_options_requested)
  _end_screen.ended.connect(_on_end_screen_ended)

  %Ceil.visible = true

  for machine in get_tree().get_nodes_in_group(GameData.GROUP_MACHINE):
    machine.machine_attempt_succeeded.connect(_on_machine_attempt_succeeded)
    machine.machine_done.connect(_on_machine_done)

  %MazeMachine.robot_sent_for_coffee.connect(_on_robot_sent_for_coffee)


func _on_title_options_requested() -> void:
  _options_menu.show()


func _on_title_started() -> void:
  _title_screen.visible = false
  _player.visible = true
  _player.set_hud_visible(true)
  _player.set_process_unhandled_input(true)
  _player.activate_camera()
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_end_screen_ended() -> void:
  get_tree().reload_current_scene()


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
  _end_screen.show()


func _on_machine_attempt_succeeded(machine: Node) -> void:
  match machine.machine_name:
    MachineMaze.NAME:
      AudioManager.play(AudioData.AUDIO_MOUSE_PICK, _mouse.global_position)
      _mouse.go_to_cheese()
      _cheese_in_maze.visible = true


func _on_machine_done(machine: Node) -> void:
  match machine.machine_name:
    MachineMaze.NAME:
      if is_instance_valid(_mouse):
        _player.inventory.append("souris")
        AudioManager.play(AudioData.AUDIO_MOUSE_PICK, _mouse.global_position)
        GameData.show_message(tr("msgPickup") % "souris", 2.0)
        _mouse.visible = false
        _mouse.set_physics_process(false)
    MachineSutom.NAME:
      _robot.stop_coffee_mode()
      _player.suppress_dialogue("labyrinthe_seul")
    MachineOscillo.NAME:
      _player.suppress_dialogue("oscillo_done")
      _options_menu.reveal_dlss_option()


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


func _on_area_close_door_body_entered(_body: Node3D) -> void:
  for door in get_tree().get_nodes_in_group(GameData.GROUP_DOOR_IVAN):
    if door.is_opened():
      door.lock()
      %AreaCloseDoor.queue_free()


func _on_robot_sent_for_coffee() -> void:
  var cast_dir := (_position_robot_cofee.global_basis * _position_robot_cofee.target_position).normalized()
  _robot.set_coffee_mode(_position_robot_cofee.global_position, cast_dir)


func _on_area_robot_inside_body_entered(body: Node3D) -> void:
  if body != _robot:
    return
  _robot.go_to_position(_position_robot.global_position)
  var cast_dir := (_position_robot.global_basis * _position_robot.target_position).normalized()
  _robot.face_direction(cast_dir)
