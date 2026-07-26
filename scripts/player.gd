class_name Player
extends CharacterBody3D

signal game_finished()
signal dialogue_side_effect(dialogue_id: String)
signal object_picked(obj_name: String)
signal cpc_collected_changed(count: int, total: int)

const SPEED             := 5.0
const MOUSE_SENSITIVITY := 0.002
const JOY_LOOK_SPEED    := 2.5
const NOTIF_CHAR_TIME   := 0.04
const NOTIF_HOLD_TIME   := 3.0
const NOTIF_FADE_TIME   := 0.6

@export var _robot: Node3D = null

var gravity: float            = ProjectSettings.get_setting("physics/3d/default_gravity")
var inventory: Array[String]  = []
var camera: Camera3D:
  get: return _camera_3d

var _dialogue_is_with_robot: bool = false
var _cpc_count               := 0
var _completed_dialogues: Array[String] = []
var _pending_robot_dialogue: String = ""
var _notif_queue: Array[String] = []
var _notif_active             := false

var _debug_accept_count: int = 0
var _debug_interact_count: int = 0
var _debug_last_event: String = "aucun"
var _debug_last_console_line: String = ""

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
@onready var _secondary_notif_label:  Label        = %SecondaryNotifLabel


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
  GameData.objectives_changed.connect(_update_objective)
  GameData.secondary_objective_added.connect(_on_secondary_objective_added)
  _update_objective()

  await get_tree().process_frame

  _robot = get_tree().get_first_node_in_group(GameData.GROUP_ROBOT)
  _cpc_count = get_tree().get_nodes_in_group(GameData.GROUP_CPC).size()


func set_hud_visible(value: bool) -> void:
  if _canvas_layer:
    _canvas_layer.visible = value


func show_message(text: String, duration: float = 3.0) -> void:
  if text.is_empty():
    return
  _message_label.text    = InputDevice.adapt(text)
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
  var focus_owner := get_viewport().gui_get_focus_owner()
  output += "FOCUS: %s | dlg_open=%s\n" % [
    String(focus_owner.name) if focus_owner else "aucun",
    _dialogue_ui.is_open()
  ]
  var console_line := "FOCUS=%s dlg_open=%s accept_count=%d interact_count=%d last_event=%s" % [
    String(focus_owner.name) if focus_owner else "aucun",
    _dialogue_ui.is_open(),
    _debug_accept_count, _debug_interact_count, _debug_last_event
  ]
  output += console_line + "\n"
  if console_line != _debug_last_console_line:
    _debug_last_console_line = console_line
    print(console_line)
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
  if event is InputEventJoypadButton and event.pressed:
    _debug_last_event = "JoypadButton idx=%d in_minigame=%s" % [event.button_index, GameData.in_minigame]

  if GameData.in_minigame:
    return

  if event.is_action_pressed("ui_cancel"):
    if _dialogue_ui.is_open():
      _dialogue_ui.close()
      return

  if not _dialogue_ui.is_open() and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
    var sens     := MOUSE_SENSITIVITY * OptionsMenu.mouse_sensitivity
    var invert_y := -1.0 if OptionsMenu.mouse_invert_y else 1.0
    _apply_look(-event.relative.x * sens, -event.relative.y * sens * invert_y)

  if event.is_action_pressed("ui_accept"):
    _debug_accept_count += 1
    if not _dialogue_ui.is_open():
      _try_interact()


func _apply_look(yaw: float, pitch: float) -> void:
  rotate_y(yaw)
  _camera_3d.rotate_x(pitch)
  _camera_3d.rotation.x = clamp(_camera_3d.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func _apply_stick_look(delta: float) -> void:
  var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
  if look == Vector2.ZERO:
    return
  var sens     := JOY_LOOK_SPEED * OptionsMenu.mouse_sensitivity * delta
  var invert_y := -1.0 if OptionsMenu.mouse_invert_y else 1.0
  _apply_look(-look.x * sens, -look.y * sens * invert_y)


func _open_ivan_dialogue() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _dialogue_ui.open_direct(DialoguesData.find_by_id("ivan_intro"))


func _open_ivan_final_dialogue() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _dialogue_is_with_robot = false
  _dialogue_ui.open_direct(DialoguesData.find_by_id("ivan_final"))


func _try_interact() -> void:
  _debug_interact_count += 1
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
    if _robot and _robot.is_love_mode():
      show_message(tr("msgRobotInLove") % [DialoguesData.robot_name], 5.0)
      return
    if not _pending_robot_dialogue.is_empty():
      var pending := DialoguesData.find_by_id(_pending_robot_dialogue)
      _pending_robot_dialogue = ""
      if not pending.is_empty():
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        _dialogue_is_with_robot = true
        _dialogue_ui.open_direct(pending)
        return
    var working_on := ""
    for key in GameData._state_machine.keys():
      if GameData.state(key) == Machine.StateMachine.ROBOT_WORKING:
        working_on = key
        break
    if not working_on.is_empty():
      match working_on:
        "Maze":       working_on = tr("wordMaze")
        "Ordinateur": working_on = tr("wordWiring")
        "TV":         working_on = tr("wordCaptcha")
      show_message(tr("msgRobotWorking") % [DialoguesData.robot_name, working_on], 3.0)
    else:
      _open_dialogue()
    return


# ── Objectif ─────────────────────────────────────────────────────────────────

func _update_objective() -> void:
  var active: Array = GameData.get_objectives().filter(
    func(e: Dictionary) -> bool: return e["is_primary"] and not e["is_done"]
  )
  _objective_label.visible = not active.is_empty()
  if not active.is_empty():
    _objective_label.text = "\n".join(
      active.map(func(e: Dictionary) -> String:
        var raw := tr(e["key"])
        var params: Array = e.get("params", [])
        return raw % params if not params.is_empty() else raw
    )
  )


func _on_secondary_objective_added(key: String, params: Array) -> void:
  var raw := tr(key)
  _notif_queue.append(raw % params if not params.is_empty() else raw)
  if not _notif_active:
    _play_notif_queue()


func _play_notif_queue() -> void:
  _notif_active = true
  while not _notif_queue.is_empty():
    var text: String = tr("newObjective") + "\n" + _notif_queue.pop_front()
    var full := text.length()
    _secondary_notif_label.text             = text
    _secondary_notif_label.visible_characters = 0
    _secondary_notif_label.modulate         = Color.WHITE
    _secondary_notif_label.visible          = true
    var type_tween := create_tween()
    type_tween.tween_property(
      _secondary_notif_label, "visible_characters", full, full * NOTIF_CHAR_TIME
    )
    await type_tween.finished
    await get_tree().create_timer(NOTIF_HOLD_TIME).timeout
    var fade_tween := create_tween()
    fade_tween.tween_property(_secondary_notif_label, "modulate:a", 0.0, NOTIF_FADE_TIME)
    await fade_tween.finished
  _secondary_notif_label.visible = false
  _notif_active = false


# ── Mini-jeux & ramassage ─────────────────────────────────────────────────────

func suppress_dialogue(dialogue_id: String) -> void:
  if dialogue_id not in _completed_dialogues:
    _completed_dialogues.append(dialogue_id)


func set_pending_robot_dialogue(dialogue_id: String) -> void:
  _pending_robot_dialogue = dialogue_id


func collect_cpc(id: int) -> void:
  if not GameData.cpc_collected.has(id):
    GameData.cpc_collected.append(id)
    GameData.cpc_collected.sort()
    cpc_collected_changed.emit(GameData.cpc_collected.size(), _cpc_count)
    _objective_cpc_label.text = tr("cpcFoundLabel") + ", ".join(GameData.cpc_collected)
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
  object_picked.emit(obj_name)
  obj.queue_free()


# ── Physique ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
  _debug_label.text = _get_debug_text()
  _quit_hint_label.visible = GameData.in_minigame
  if _quit_hint_label.visible:
    _quit_hint_label.text = InputDevice.adapt(tr("escQuit"))

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
  _interaction_hint_label.text    = InputDevice.adapt(hint)
  _interaction_hint_label.visible = not hint.is_empty()

  if not is_on_floor():
    velocity.y -= gravity * delta

  var look_locked := _dialogue_ui.is_open() or GameData.in_minigame \
    or Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
  if not look_locked:
    _apply_stick_look(delta)

  var locked := look_locked or not GameData.intro_done
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
