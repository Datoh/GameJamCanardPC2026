class_name Player
extends CharacterBody3D

signal game_finished()
signal dialogue_side_effect(dialogue_id: String)

const SPEED             := 5.0
const MOUSE_SENSITIVITY := 0.002

@export var _robot: Node3D = null

var gravity: float            = ProjectSettings.get_setting("physics/3d/default_gravity")
var inventory: Array[String]  = []
var camera: Camera3D:
  get: return _camera_3d

var _dialogue_is_with_robot: bool = false
var _cpc_count               := 0
var _completed_dialogues: Array[String] = []

@onready var crosshair:               TextureRect  = %Crosshair

@onready var _canvas_layer:           CanvasLayer  = %CanvasLayer
@onready var _interaction_ray:        RayCast3D    = %RayCast3D
@onready var _objective_label:        Label        = %ObjectiveLabel
@onready var _objective_cpc_label:    Label        = %ObjectiveCPCLabel
@onready var _quit_hint_label:        Label        = %QuitHintLabel
@onready var _camera_3d:              Camera3D     = %Camera3D
@onready var _message_label:          Label        = %MessageLabel
@onready var _message_timer:          Timer        = %MessageTimer
@onready var _machine_timer:          Timer        = %MachineTimer
@onready var _debug_label:            Label        = %DebugLabel
@onready var _interaction_hint_label: Label        = %InteractionHintLabel
@onready var _dialogue_ui:            DialogueUI   = %DialogueUI


func activate_camera() -> void:
  _camera_3d.current = true


func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  _debug_label.visible = OS.is_debug_build()
  _message_timer.timeout.connect(_message_label.hide)
  _machine_timer.timeout.connect(_on_machine_timer_timeout)
  _dialogue_ui.dialogue_completed.connect(_on_dialogue_completed)
  _dialogue_ui.closed.connect(_on_dialogue_closed)
  _dialogue_ui.branch_chosen.connect(_on_branch_chosen)
  _dialogue_ui.robot_started_talking.connect(func(): if _robot: _robot.start_talking())
  _dialogue_ui.robot_stopped_talking.connect(func(): if _robot: _robot.stop_talking())

  await get_tree().process_frame

  _robot = get_tree().get_first_node_in_group(GameData.GROUP_ROBOT)
  _cpc_count = get_tree().get_nodes_in_group(GameData.GROUP_CPC).size()


func set_hud_visible(value: bool) -> void:
  if _canvas_layer:
    _canvas_layer.visible = value


func show_message(text: String, duration: float = 3.0) -> void:
  if text.is_empty():
    return
  _message_label.text    = text
  _message_label.visible = true
  _message_timer.start(duration)


func can_interact(id_object: String, machine: String) -> bool:
  match id_object:
    "Feutres":      return GameData.state(machine) == Machine.StateMachine.TRY_MACHINE_OBJECT
    "Dictionnaire": return GameData.state(machine) == Machine.StateMachine.TRY_MACHINE_OBJECT
    "Fromage":      return GameData.state(machine) == Machine.StateMachine.TRY_MACHINE_OBJECT
    _: return true


func start_robot_work(machine: Machine, duration: float) -> void:
  if _robot:
    _robot.go_to_task(machine.global_position)
    _robot.start_working()
  _machine_timer.start(duration)


func _get_debug_text() -> String:
  var output: String
  var ray_object: Object = null
  if _interaction_ray != null and _interaction_ray.is_colliding():
    ray_object = _interaction_ray.get_collider()
  if is_instance_valid(ray_object):
    output = "RAY: %s %s\n" % [ray_object.name, ray_object.get_groups()]
  else:
    output = "RAY: rien\n"
  for key in GameData._state_machine.keys():
    output = "%s%s => %s | " % [output, key, Machine.StateMachine.keys()[GameData.state(key)]]
  return output


# ── Dialogue ──────────────────────────────────────────────────────────────────

func _is_dialogue_available(d: Dictionary) -> bool:
  if d.get("hidden", false):
    return false
  if d.get("once", false) and d["id"] in _completed_dialogues:
    return false
  var req: String = d.get("requires", "")
  if req != "" and req not in _completed_dialogues:
    return false
  for m in get_tree().get_nodes_in_group(GameData.GROUP_MACHINE):
    if m is Machine and (m as Machine).is_dialogue_locked(d["id"]):
      return false
  if _robot and _robot.is_dialogue_locked(d["id"]):
    return false
  return true


func _get_available_dialogues() -> Array:
  var result: Array = []
  var close_entry: Dictionary = {}
  for d in DialoguesData.get_dialogues():
    if d["id"] == "close":
      close_entry = d
      continue
    if _is_dialogue_available(d):
      result.append(d)
  if not close_entry.is_empty():
    result.append(close_entry)
  return result


func _open_dialogue() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _dialogue_is_with_robot = true
  _dialogue_ui.open(_get_available_dialogues())


func _on_dialogue_completed(dialogue_id: String) -> void:
  if dialogue_id == "ivan_intro":
    GameData.intro_done = true
    return
  var dialogue := DialoguesData.find_by_id(dialogue_id)
  if dialogue.get("once", false) and dialogue_id not in _completed_dialogues:
    _completed_dialogues.append(dialogue_id)
  _apply_dialogue_side_effects(dialogue_id)


func _apply_dialogue_side_effects(dialogue_id: String) -> void:
  for m in get_tree().get_nodes_in_group(GameData.GROUP_MACHINE):
    if m is Machine:
      (m as Machine).on_dialogue_completed(dialogue_id)
  if dialogue_id == "ivan_final":
    game_finished.emit()
  dialogue_side_effect.emit(dialogue_id)


func _on_dialogue_closed() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  if _dialogue_is_with_robot and _robot:
    _dialogue_is_with_robot = false
    _robot.start_following()


func _on_branch_chosen(action: String) -> void:
  match action:
    "robot_ln":
      DialoguesData.robot_name = "LN R3p14y"
      if _robot: _robot.set_skin("LN R3p14y")
    "robot_1f5":
      DialoguesData.robot_name = "1F5"
      if _robot: _robot.set_skin("1F5")


func _on_machine_timer_timeout() -> void:
  for key in GameData._state_machine.keys():
    if GameData.state(key) == Machine.StateMachine.ROBOT_WORKING:
      GameData.set_state(key, Machine.StateMachine.ROBOT_DONE)
      break
  if _robot != null:
    _robot.stop_working()
    _robot.resume_follow()


# ── Interaction ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
  if GameData.in_minigame:
    return

  if event.is_action_pressed("ui_cancel"):
    if _dialogue_ui.is_open():
      _dialogue_ui.close()
      return

  if not _dialogue_ui.is_open() and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
    var sens     := MOUSE_SENSITIVITY * OptionsMenu.mouse_sensitivity
    var invert_y := -1.0 if OptionsMenu.mouse_invert_y else 1.0
    rotate_y(-event.relative.x * sens)
    _camera_3d.rotate_x(-event.relative.y * sens * invert_y)
    _camera_3d.rotation.x = clamp(_camera_3d.rotation.x, deg_to_rad(-80), deg_to_rad(80))

  if event.is_action_pressed("ui_accept") and not _dialogue_ui.is_open():
    _try_interact()


func _open_ivan_dialogue() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _dialogue_ui.open_direct(DialoguesData.find_by_id("ivan_intro"))


func _open_ivan_final_dialogue() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _dialogue_is_with_robot = false
  _dialogue_ui.open_direct(DialoguesData.find_by_id("ivan_final"))


func _try_interact() -> void:
  _interaction_ray.force_raycast_update()
  if not _interaction_ray.is_colliding():
    return

  var collider := _interaction_ray.get_collider()

  if not GameData.intro_done:
    if collider.is_in_group(GameData.GROUP_IVAN):
      _open_ivan_dialogue()
    return

  if collider.is_in_group(GameData.GROUP_IVAN):
    if GameData.state(ScreenMachine.NAME) == Machine.StateMachine.SOLVED \
       and "ivan_final" not in _completed_dialogues:
      _open_ivan_final_dialogue()
    return

  if collider.is_in_group(GameData.GROUP_INTERACTIVE):
    collider.interact()
    return

  if collider.is_in_group(GameData.GROUP_ROBOT):
    var working_on := ""
    for key in GameData._state_machine.keys():
      if GameData.state(key) == Machine.StateMachine.ROBOT_WORKING:
        working_on = key
        break
    if not working_on.is_empty():
      match working_on:
        "Maze":       working_on = tr("wordMaze")
        "Ordinateur": working_on = tr("wordWiring")
      show_message(tr("msgRobotWorking") % [DialoguesData.robot_name, working_on], 3.0)
    else:
      _open_dialogue()
    return


# ── Objectif ─────────────────────────────────────────────────────────────────

func _update_objective() -> void:
  if not GameData.intro_done:
    _objective_label.visible = false
    return
  _objective_label.visible = true
  if GameData.state(ScreenMachine.NAME) == Machine.StateMachine.SOLVED:
    _objective_label.text = tr("objectiveTalkIvan")
  else:
    _objective_label.text = tr("objectiveWriteArticle")


# ── Mini-jeux & ramassage ─────────────────────────────────────────────────────

func suppress_dialogue(dialogue_id: String) -> void:
  if dialogue_id not in _completed_dialogues:
    _completed_dialogues.append(dialogue_id)


func collect_cpc(id: int) -> void:
  if not GameData.cpc_collected.has(id):
    GameData.cpc_collected.append(id)
    GameData.cpc_collected.sort()
    _objective_cpc_label.text = tr("cpcFoundLabel") + ", ".join(GameData.cpc_collected)
    print("%d = %d" % [GameData.cpc_collected.size(), _cpc_count])
    if GameData.cpc_collected.size() == _cpc_count:
      await get_tree().create_timer(0.5).timeout
      show_message(tr("msgAllCpcFound"), 3.0)
      AudioManager.play(AudioData.AUDIO_CABLE_VALIDATE_ALL, global_position)


func is_cpc_collected(id: int) -> bool:
  return GameData.cpc_collected.has(id)


func pickup(obj: Node, obj_name: String, machine_name: String = "") -> void:
  if not machine_name.is_empty():
    GameData.set_state(machine_name, Machine.StateMachine.TRY_MACHINE_OK)
  inventory.append(obj_name)
  show_message(tr("msgPickup") % obj_name.replace("_", " "), 2.0)
  obj.queue_free()


# ── Physique ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
  _debug_label.text = _get_debug_text()
  _update_objective()
  _quit_hint_label.visible = GameData.in_minigame

  var hint := ""
  if not GameData.in_minigame and not _dialogue_ui.is_open() and _interaction_ray.is_colliding():
    var collider := _interaction_ray.get_collider()
    if collider:
      if not GameData.intro_done and collider.is_in_group(GameData.GROUP_IVAN):
        hint = tr("hintTalkIvan")
      elif GameData.intro_done and collider.is_in_group(GameData.GROUP_IVAN) \
           and GameData.state(ScreenMachine.NAME) == Machine.StateMachine.SOLVED \
           and "ivan_final" not in _completed_dialogues:
        hint = tr("hintTalkIvan")
      elif GameData.intro_done and collider.is_in_group(GameData.GROUP_ROBOT):
        hint = tr("hintTalkRobot") % DialoguesData.robot_name
      elif GameData.intro_done and collider.is_in_group(GameData.GROUP_INTERACTIVE):
        hint = collider.get_interaction_hint()
  _interaction_hint_label.text    = hint
  _interaction_hint_label.visible = not hint.is_empty()

  if not is_on_floor():
    velocity.y -= gravity * delta

  var locked := _dialogue_ui.is_open() or GameData.in_minigame or not GameData.intro_done
  if not locked:
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
      velocity.x = direction.x * SPEED
      velocity.z = direction.z * SPEED
    else:
      velocity.x = move_toward(velocity.x, 0, SPEED)
      velocity.z = move_toward(velocity.z, 0, SPEED)
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED)
    velocity.z = move_toward(velocity.z, 0, SPEED)

  move_and_slide()
