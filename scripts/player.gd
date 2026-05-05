extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENSITIVITY := 0.002

const DialogueUI = preload("res://scripts/dialogue_ui.gd")

# ── États des machines ────────────────────────────────────────────────────────

@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var inventory: Array[String] = []
var notified: Array[String] = []

var state_machine: Dictionary = {}

@onready var _interaction_ray: RayCast3D = %RayCast3D
var _canvas: CanvasLayer
var _message_label: Label
var _message_timer: Timer
var _debug_label: Label
var _dialogue_ui: DialogueUI

var _interaction_hint_label: Label

@export var _robot: Node3D = null

var _machine_timer: Timer
@onready var _crosshair:        TextureRect = %Crosshair
@onready var _objective_label:  Label       = %ObjectiveLabel
@onready var _quit_hint_label:  Label       = %QuitHintLabel

var minigame_name: String = ""
var _intro_done: bool = false
var _dialogue_is_with_robot: bool = false

var in_minigame: bool = false:
  set(value):
    in_minigame = value
    if _crosshair:
      _crosshair.visible = not value
var _completed_dialogues: Array[String] = []

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  _setup_ui()

  await get_tree().process_frame

  _robot = get_tree().get_first_node_in_group("robot")

  for machine in get_tree().get_nodes_in_group("machine"):
    state_machine[machine.NAME] = Machine.StateMachine.IDLE

# ── Setup ─────────────────────────────────────────────────────────────────────

func _setup_ui() -> void:
  _canvas = CanvasLayer.new()
  add_child(_canvas)

  _message_label = Label.new()
  _message_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
  _message_label.offset_top = -80.0
  _message_label.offset_bottom = -20.0
  _message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _message_label.visible = false
  _canvas.add_child(_message_label)

  _message_timer = Timer.new()
  _message_timer.one_shot = true
  _message_timer.timeout.connect(_message_label.hide)
  add_child(_message_timer)

  _machine_timer = Timer.new()
  _machine_timer.one_shot = true
  _machine_timer.timeout.connect(_on_machine_timer_timeout)
  add_child(_machine_timer)

  _debug_label = Label.new()
  _debug_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
  _debug_label.position = Vector2(10, 10)
  _debug_label.add_theme_color_override("font_color", Color(0, 1, 0))
  _canvas.add_child(_debug_label)

  _interaction_hint_label = Label.new()
  _interaction_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
  _interaction_hint_label.offset_top = -140.0
  _interaction_hint_label.offset_bottom = -90.0
  _interaction_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _interaction_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _interaction_hint_label.visible = false
  _canvas.add_child(_interaction_hint_label)

  _dialogue_ui = DialogueUI.new()
  _dialogue_ui.dialogue_completed.connect(_on_dialogue_completed)
  _dialogue_ui.closed.connect(_on_dialogue_closed)
  _dialogue_ui.robot_started_talking.connect(func(): if _robot: _robot.start_talking())
  _dialogue_ui.robot_stopped_talking.connect(func(): if _robot: _robot.stop_talking())
  _canvas.add_child(_dialogue_ui)

func show_message(text: String, duration: float = 3.0) -> void:
  if text.is_empty():
    return
  _message_label.text = text
  _message_label.visible = true
  _message_timer.start(duration)

func can_interact(id_object: String, machine: String) -> bool:
  match id_object:
    "Feutres": return state_machine[machine] == Machine.StateMachine.TRY_MACHINE_OBJECT
    "Dictionnaire": return state_machine[machine] == Machine.StateMachine.TRY_MACHINE_OBJECT
    "Fromage": return state_machine[machine] == Machine.StateMachine.TRY_MACHINE_OBJECT
    _: return true

func start_robot_work(machine: Machine, duration: float) -> void:
  if _robot:
    _robot.go_to_position(machine.global_position)
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

  for key in state_machine.keys():
    output = "%s%s => %s | " % [output, key, Machine.StateMachine.keys()[state_machine[key]]]
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
  for m in get_tree().get_nodes_in_group("machine"):
    if m is Machine and (m as Machine).is_dialogue_locked(d["id"], self):
      return false
  return true

func _get_available_dialogues() -> Array:
  var result: Array = []
  var close_entry: Dictionary = {}
  for d in DialoguesData.DIALOGUES:
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
    _intro_done = true
    return
  var dialogue := DialoguesData.find_by_id(dialogue_id)
  if dialogue.get("once", false) and dialogue_id not in _completed_dialogues:
    _completed_dialogues.append(dialogue_id)
  _apply_dialogue_side_effects(dialogue_id)

func _apply_dialogue_side_effects(dialogue_id: String) -> void:
  for m in get_tree().get_nodes_in_group("machine"):
    if m is Machine:
      (m as Machine).on_dialogue_completed(dialogue_id, self)

func _on_dialogue_closed() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  if _dialogue_is_with_robot and _robot:
    _dialogue_is_with_robot = false
    _robot.start_following()

func _on_machine_timer_timeout() -> void:
  for key in state_machine.keys():
    if state_machine[key] == Machine.StateMachine.ROBOT_WORKING:
      state_machine[key] = Machine.StateMachine.ROBOT_DONE
      break
  if _robot != null:
    _robot.resume_follow()

# ── Interaction ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
  if in_minigame:
    return

  if event.is_action_pressed("ui_cancel"):
    if _dialogue_ui.is_open():
      _dialogue_ui.close()
      return

  if not _dialogue_ui.is_open() and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
    rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
    camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

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

  if not _intro_done:
    if collider.is_in_group("ivan"):
      _open_ivan_dialogue()
    return

  if collider.is_in_group("ivan"):
    if state_machine.get("Screen", Machine.StateMachine.IDLE) == Machine.StateMachine.SOLVED \
       and "ivan_final" not in _completed_dialogues:
      _open_ivan_final_dialogue()
    return

  if collider.is_in_group("interactive"):
    collider.interact(self)
    return

  if collider.is_in_group("robot"):
    var working_on := ""
    for key in state_machine:
      if state_machine[key] == Machine.StateMachine.ROBOT_WORKING:
        working_on = key
        break
    if not working_on.is_empty():
      match working_on:
        "Maze": working_on = "labyrinthe"
        "Ordinateur": working_on = "câblage"
      show_message("LN R3p14y est en train de faire le %s... je vais le laisser faire..." % working_on, 3.0)
    else:
      _open_dialogue()
    return

# ── Objectif ─────────────────────────────────────────────────────────────────

func _update_objective() -> void:
  if not _intro_done:
    _objective_label.visible = false
    return
  _objective_label.visible = true
  if state_machine.get("Screen", Machine.StateMachine.IDLE) == Machine.StateMachine.SOLVED:
    _objective_label.text = "Objectif : parler à Ivan"
  else:
    _objective_label.text = "Objectif : écrire un article avec le PC du petit bureau"

# ── Mini-jeux & ramassage ─────────────────────────────────────────────────────

func notify(notify_name: String) -> void:
  if not notified.has(notify_name):
    notified.append(notify_name)

func is_notified(notify_name: String) -> bool:
  return notified.has(notify_name)

func pickup(obj: Node, obj_name: String, machine_name: String = "") -> void:
  if not machine_name.is_empty():
    state_machine[machine_name] = Machine.StateMachine.TRY_MACHINE_OK
  inventory.append(obj_name)
  show_message("Vous ramassez : %s." % obj_name.replace("_", " "), 2.0)
  obj.queue_free()

# ── Physique ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
  _debug_label.text = _get_debug_text()
  _update_objective()
  _quit_hint_label.visible = not minigame_name.is_empty()

  var hint := ""
  if not in_minigame and not _dialogue_ui.is_open() and _interaction_ray.is_colliding():
    var collider := _interaction_ray.get_collider()
    if collider:
      if not _intro_done and collider.is_in_group("ivan"):
        hint = "[ESPACE] Parler à Ivan"
      elif _intro_done and collider.is_in_group("ivan") \
           and state_machine.get("Screen", Machine.StateMachine.IDLE) == Machine.StateMachine.SOLVED \
           and "ivan_final" not in _completed_dialogues:
        hint = "[ESPACE] Parler à Ivan"
      elif _intro_done and collider.is_in_group("robot"):
        hint = "[ESPACE] Parler à LN R3p14y"
      elif _intro_done and collider.is_in_group("interactive"):
        hint = collider.get_interaction_hint(self)
  _interaction_hint_label.text = hint
  _interaction_hint_label.visible = not hint.is_empty()

  if not is_on_floor():
    velocity.y -= gravity * delta

  var locked := _dialogue_ui.is_open() or in_minigame or not _intro_done
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
