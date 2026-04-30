extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENSITIVITY := 0.002

const DialogueUI = preload("res://scripts/dialogue_ui.gd")

# ── États des machines ────────────────────────────────────────────────────────

enum SutomState        { IDLE, FIRST_SEEN, ROBOT_WORKING, ROBOT_DONE, NEED_TRY_MACHINE, NEEDS_DICTIONARY, UNLOCKED, SOLVED }
enum OscilloscopeState { IDLE, ATTEMPTED, UNLOCKED }
enum TeleState         { IDLE, CAPTCHA_PENDING, CAPTCHA_SOLVED, VIDEO_WATCHED }
enum LabyrinthState    { IDLE, ATTEMPTED, SOLVED }
enum PCState           { IDLE, ATTEMPTED, REPAIRED, MOUSE_CONNECTED, UNLOCKED }

# ── États du robot par machine ────────────────────────────────────────────────

enum RobotSutomState        { UNAWARE, HELPING, GAVE_UP }
enum RobotOscilloscopeState { UNAWARE }
enum RobotTeleState         { UNAWARE }
enum RobotLabyrinthState    { UNAWARE, ATTEMPTED }
enum RobotPCState           { UNAWARE }

@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var inventory: Array[String] = []
var puzzle_attempted: Dictionary = {
  "Dictionnaire": false,
  "Fromage":      false,
  "Joint":        false,
  "Feutres":      false,
}

var state_sutom:        SutomState        = SutomState.IDLE
var state_oscilloscope: OscilloscopeState = OscilloscopeState.IDLE
var state_tele:         TeleState         = TeleState.IDLE
var state_labyrinthe:   LabyrinthState    = LabyrinthState.IDLE
var state_pc:           PCState           = PCState.IDLE

var robot_state_sutom:        RobotSutomState        = RobotSutomState.UNAWARE
var robot_state_oscilloscope: RobotOscilloscopeState = RobotOscilloscopeState.UNAWARE
var robot_state_tele:         RobotTeleState         = RobotTeleState.UNAWARE
var robot_state_labyrinthe:   RobotLabyrinthState    = RobotLabyrinthState.UNAWARE
var robot_state_pc:           RobotPCState           = RobotPCState.UNAWARE

@onready var _interaction_ray: RayCast3D = %RayCast3D
var _canvas: CanvasLayer
var _message_label: Label
var _message_timer: Timer
var _debug_label: Label
var _dialogue_ui: DialogueUI

var _interaction_hint_label: Label

var _robot: Node3D = null
var _sutom_node: Node3D = null
var _sutom_timer: Timer
var _in_minigame: bool = false
var _completed_dialogues: Array[String] = []

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  _setup_ui()
  await get_tree().process_frame
  _robot = get_tree().get_first_node_in_group("robot")

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

  _sutom_timer = Timer.new()
  _sutom_timer.one_shot = true
  _sutom_timer.timeout.connect(_on_sutom_timer_timeout)
  add_child(_sutom_timer)

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
  _canvas.add_child(_dialogue_ui)

func _show_message(text: String, duration: float = 3.0) -> void:
  _message_label.text = text
  _message_label.visible = true
  _message_timer.start(duration)

func _get_debug_text() -> String:
  var ray_text: String
  var ray_object: Object = null
  if _interaction_ray != null and _interaction_ray.is_colliding():
    ray_object = _interaction_ray.get_collider()
  if is_instance_valid(ray_object):
    ray_text = "RAY: %s %s" % [ray_object.name, ray_object.get_groups()]
  else:
    ray_text = "RAY: rien"

  var m_text := "M  SUT=%s|OSC=%s|TEL=%s|LAB=%s|PC=%s" % [
    SutomState.keys()[state_sutom],
    OscilloscopeState.keys()[state_oscilloscope],
    TeleState.keys()[state_tele],
    LabyrinthState.keys()[state_labyrinthe],
    PCState.keys()[state_pc],
  ]
  var r_text := "R  SUT=%s|OSC=%s|TEL=%s|LAB=%s|PC=%s" % [
    RobotSutomState.keys()[robot_state_sutom],
    RobotOscilloscopeState.keys()[robot_state_oscilloscope],
    RobotTeleState.keys()[robot_state_tele],
    RobotLabyrinthState.keys()[robot_state_labyrinthe],
    RobotPCState.keys()[robot_state_pc],
  ]
  return "%s\n%s\n%s" % [ray_text, m_text, r_text]

# ── Dialogue ──────────────────────────────────────────────────────────────────

func _is_dialogue_available(d: Dictionary) -> bool:
  if d.get("hidden", false):
    return false
  if d.get("once", false) and d["id"] in _completed_dialogues:
    return false
  var req: String = d.get("requires", "")
  if req != "" and req not in _completed_dialogues:
    return false
  # Conditions liées aux états des machines
  if d["id"] == "sutom_demande" and state_sutom != SutomState.FIRST_SEEN:
    return false
  if d["id"] == "sutom_resultat" and state_sutom != SutomState.ROBOT_DONE:
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
  _dialogue_ui.open(_get_available_dialogues())

func _on_dialogue_completed(dialogue_id: String) -> void:
  var dialogue := DialoguesData.find_by_id(dialogue_id)
  if dialogue.get("once", false) and dialogue_id not in _completed_dialogues:
    _completed_dialogues.append(dialogue_id)
  _apply_dialogue_side_effects(dialogue_id)

func _apply_dialogue_side_effects(dialogue_id: String) -> void:
  match dialogue_id:
    "sutom_demande":
      state_sutom = SutomState.ROBOT_WORKING
      robot_state_sutom = RobotSutomState.HELPING
      if _sutom_node == null:
        for m in get_tree().get_nodes_in_group("machine"):
          if m.has_signal("game_finished"):
            _sutom_node = m
            break
      if _robot != null and _sutom_node != null:
        _robot.go_to_position((_sutom_node as Node3D).global_position)
      _sutom_timer.start(20.0)
    "sutom_resultat":
      state_sutom = SutomState.NEED_TRY_MACHINE
      robot_state_sutom = RobotSutomState.GAVE_UP

func _on_dialogue_closed() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_sutom_timer_timeout() -> void:
  state_sutom = SutomState.ROBOT_DONE
  if _robot != null:
    _robot.resume_follow()

# ── Interaction ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
  if _in_minigame:
    return

  if event.is_action_pressed("ui_cancel"):
    if _dialogue_ui.is_open():
      _dialogue_ui.close()
      return
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

  if not _dialogue_ui.is_open() and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
    rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
    camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

  if event.is_action_pressed("ui_accept") and not _dialogue_ui.is_open():
    _try_interact()

func _try_interact() -> void:
  _interaction_ray.force_raycast_update()
  if not _interaction_ray.is_colliding():
    return

  var collider := _interaction_ray.get_collider()

  if collider.is_in_group("interactive"):
    collider.interact(self)
    return

  if collider.is_in_group("robot"):
    if state_sutom == SutomState.ROBOT_WORKING:
      _show_message("Le robot est en train de faire le SUTOM... je vais le laisser faire...", 3.0)
    else:
      _open_dialogue()
    return

  if collider.is_in_group("machines"):
    match collider.name:
      "Oscilloscope":
        if state_oscilloscope == OscilloscopeState.IDLE:
          state_oscilloscope = OscilloscopeState.ATTEMPTED
          _show_message("Cette machine a l'air compliquée.", 3.0)
        else:
          _use_machine("Oscilloscope")
      "Labyrinthe":
        if state_labyrinthe == LabyrinthState.IDLE:
          state_labyrinthe = LabyrinthState.ATTEMPTED
          puzzle_attempted["Fromage"] = true
          _show_message("Ce labyrinthe a l'air impossible...", 3.0)
        else:
          _use_machine("Labyrinthe")
    return

  if collider.is_in_group("objets"):
    _try_pickup(collider)

func _try_pickup(collider: Node) -> void:
  var obj_name: String = collider.name
  var can_pickup: bool = puzzle_attempted.get(obj_name, false)
  if obj_name == "Dictionnaire" and state_sutom >= SutomState.NEEDS_DICTIONARY:
    can_pickup = true
  if can_pickup:
    _pickup(collider, obj_name)
  else:
    _show_message(DialoguesData.OBJECT_MESSAGES.get(obj_name, "Hmm."))

# ── Mini-jeux & ramassage ─────────────────────────────────────────────────────

func _use_machine(machine_name: String) -> void:
  # TODO: ouvrir le mini-jeu correspondant
  _show_message("[%s] Mini-jeu à venir..." % machine_name, 2.0)

func _pickup(obj: Node, obj_name: String) -> void:
  inventory.append(obj_name)
  _show_message("Vous ramassez : %s." % obj_name.replace("_", " "), 2.0)
  obj.queue_free()
  if obj_name == "Dictionnaire" and state_sutom == SutomState.NEEDS_DICTIONARY:
    state_sutom = SutomState.UNLOCKED

# ── Physique ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
  _debug_label.text = _get_debug_text()

  var hint := ""
  if not _in_minigame and not _dialogue_ui.is_open() and _interaction_ray.is_colliding():
    var collider := _interaction_ray.get_collider()
    if collider and collider.is_in_group("interactive"):
      hint = collider.get_interaction_hint(self)
  _interaction_hint_label.text = hint
  _interaction_hint_label.visible = not hint.is_empty()

  if not is_on_floor():
    velocity.y -= gravity * delta

  var locked := _dialogue_ui.is_open() or _in_minigame
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
