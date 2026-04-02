extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENSITIVITY := 0.002

const _SutomMinigame = preload("res://scripts/sutom_minigame.gd")

const OBJECT_MESSAGES: Dictionary = {
  "Dictionnaire": "Ce dictionnaire est plein de mots. Des vrais, j'espère.",
  "Fromage":      "Je ne vois pas à quoi pourrait me servir ce fromage.",
  "Joint":        "Ce joint m'a l'air artisanal. Je le garde pour plus tard.",
  "Feutres":      "Des feutres mordus par LN R3p14y. Il mâchouille tous les capuchons.",
}

# Chaque dialogue :
#   id       : identifiant unique
#   label    : texte affiché sur le bouton joueur (vide si hidden)
#   hidden   : non affiché dans les choix, déclenché par code
#   requires : id du dialogue requis avant (ou "" si aucun)
#   once     : disparaît après avoir été joué
#   unlocks  : id du dialogue débloqué à la fin (ou "")
#   exchanges: Array de { "robot": String, "player": String (optionnel) }
#              robot  = réponse affichée du robot
#              player = bouton suivant proposé au joueur (absent = fin)
const DIALOGUES: Array[Dictionary] = [
  {
    "id":       "close",
    "label":    "Je n'ai rien à lui dire...",
  },
  {
    "id":       "bavardage_1",
    "label":    "Comment t'appelles-tu ?",
    "requires": "",
    "once":     true,
    "unlocks":  "bavardage_2",
    "exchanges": [
      {"robot": "LN R3p14y. Et toi ?", "player": "Cédric."},
      {"robot": "Quel magnifique prénom !"},
    ],
  },
  {
    "id":       "bavardage_2",
    "label":    "Comment ça va ?",
    "requires": "bavardage_1",
    "once":     true,
    "unlocks":  "bavardage_3",
    "exchanges": [
      {
        "robot":  "Ça va bien, merci ! Et toi, comment tu vas ? Je suis là si tu as besoin d'aide pour quoi que ce soit. Mais au fait, comment t'appelles-tu ?",
        "player": "Je te l'ai déjà dit... Cédric.",
      },
      {"robot": "Ah oui, tu as raison. Je vais m'en souvenir."},
    ],
  },
  {
    "id":       "bavardage_3",
    "label":    "Tu vas vraiment me rendre la vie plus facile ?",
    "requires": "bavardage_2",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "J'espère bien ! Dis-moi ce qui te prend le plus de temps ou ce qui te pèse, et on voit ensemble ce qu'on peut faire ! Mais au fait, comment t'appelles-tu ?",
        "player": "Faitchier Tim.",
      },
      {"robot": "Heureux de te connaître : Tim Faitchier !"},
    ],
  },
  {
    "id":       "sutom_demande",
    "label":    "Tu peux m'expliquer comment marche le SUTOM ?",
    "requires": "",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "Mais bien sûr ! Un SUTOM, ça, je connais parfaitement. Je peux résoudre ça en quelques secondes !",
        "player": "Vraiment ? Tu peux faire ça ?",
      },
      {"robot": "Sans aucun problème. Laisse-moi y jeter un œil tout de suite."},
    ],
  },
  {
    "id":       "sutom_resultat",
    "label":    "Alors, ce SUTOM ?",
    "requires": "sutom_demande",
    "once":     true,
    "unlocks":  "",
    "exchanges": [
      {
        "robot":  "J'ai étudié la question très, très sérieusement... et c'est beaucoup trop compliqué pour moi. Je t'encourage vivement à le faire toi-même !",
        "player": "...",
      },
      {"robot": "Je suis convaincu que tu vas trouver. Tu as vraiment l'air intelligent. Au fait, comment t'appelles-tu ?"},
    ],
  },
]

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
var _interaction_ray: RayCast3D
var _canvas: CanvasLayer
var _message_label: Label
var _message_timer: Timer
var _debug_label: Label
var _dialogue_panel: Panel
var _choices_container: VBoxContainer
var _robot_label: Label
var _continue_btn: Button
var _in_dialogue: bool = false

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

var _sutom_node: Node3D = null
var _robot: Node3D = null
var _sutom_timer: Timer
var _in_minigame: bool = false
var _sutom_state_before_minigame: SutomState = SutomState.IDLE
var _completed_dialogues: Array[String] = []
var _current_dialogue: Dictionary = {}
var _current_exchange: int = 0

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  _setup_raycast()
  _setup_ui()
  await get_tree().process_frame
  _robot = get_tree().get_first_node_in_group("robot")

func _setup_raycast() -> void:
  _interaction_ray = RayCast3D.new()
  _interaction_ray.target_position = Vector3(0, 0, -1.5)
  _interaction_ray.enabled = true
  _interaction_ray.add_exception(self)
  camera.add_child(_interaction_ray)

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

  _dialogue_panel = Panel.new()
  _dialogue_panel.anchor_left   = 0.2
  _dialogue_panel.anchor_right  = 0.8
  _dialogue_panel.anchor_top    = 0.55
  _dialogue_panel.anchor_bottom = 0.95
  _dialogue_panel.visible = false
  _canvas.add_child(_dialogue_panel)

  var vbox := VBoxContainer.new()
  vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
  vbox.add_theme_constant_override("separation", 8)
  vbox.offset_left   =  14.0
  vbox.offset_right  = -14.0
  vbox.offset_top    =  14.0
  vbox.offset_bottom = -14.0
  _dialogue_panel.add_child(vbox)

  _robot_label = Label.new()
  _robot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _robot_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
  _robot_label.visible = false
  vbox.add_child(_robot_label)

  _continue_btn = Button.new()
  _continue_btn.text = "Continuer"
  _continue_btn.visible = false
  _continue_btn.pressed.connect(_on_continue_pressed)
  vbox.add_child(_continue_btn)

  _choices_container = VBoxContainer.new()
  _choices_container.add_theme_constant_override("separation", 6)
  vbox.add_child(_choices_container)

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

func _get_available_dialogues() -> Array[Dictionary]:
  var result: Array[Dictionary] = []
  var close_entry: Dictionary = {}
  for d in DIALOGUES:
    if d["id"] == "close":
      close_entry = d
      continue
    if d.get("hidden", false):
      continue
    if d.get("once", false) and d["id"] in _completed_dialogues:
      continue
    var req: String = d.get("requires", "")
    if req != "" and req not in _completed_dialogues:
      continue
    # Conditions liées aux états des machines
    if d["id"] == "sutom_demande" and state_sutom != SutomState.FIRST_SEEN:
      continue
    if d["id"] == "sutom_resultat" and state_sutom != SutomState.ROBOT_DONE:
      continue
    result.append(d)
  if not close_entry.is_empty():
    result.append(close_entry)
  return result

func _start_dialogue_by_id(dialogue_id: String) -> void:
  for d in DIALOGUES:
    if d["id"] == dialogue_id:
      _current_dialogue = d
      _current_exchange = 0
      _in_dialogue = true
      Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
      _dialogue_panel.visible = true
      _choices_container.visible = false
      _show_robot_response()
      return

func _show_dialogue() -> void:
  _in_dialogue = true
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _show_player_choices()
  _dialogue_panel.visible = true

func _show_player_choices() -> void:
  _robot_label.visible = false
  _continue_btn.visible = false
  for child in _choices_container.get_children():
    child.queue_free()
  for d in _get_available_dialogues():
    var btn := Button.new()
    btn.text = d["label"]
    btn.pressed.connect(_on_choice_selected.bind(d["id"]))
    _choices_container.add_child(btn)

func _on_choice_selected(dialogue_id: String) -> void:
  if dialogue_id == "close":
    _close_dialogue()
    return
  for d in DIALOGUES:
    if d["id"] == dialogue_id:
      _current_dialogue = d
      _current_exchange = 0
      _show_robot_response()
      return

func _show_robot_response() -> void:
  var exchange: Dictionary = _current_dialogue["exchanges"][_current_exchange]
  _choices_container.visible = false
  _robot_label.text = "LN R3p14y : « %s »" % exchange["robot"]
  _robot_label.visible = true
  _continue_btn.visible = true

func _on_continue_pressed() -> void:
  var exchange: Dictionary = _current_dialogue["exchanges"][_current_exchange]
  if exchange.has("player"):
    _robot_label.visible = false
    _continue_btn.visible = false
    for child in _choices_container.get_children():
      child.queue_free()
    var btn := Button.new()
    btn.text = exchange["player"]
    btn.pressed.connect(_advance_exchange)
    _choices_container.add_child(btn)
    _choices_container.visible = true
  else:
    _complete_current_dialogue()

func _advance_exchange() -> void:
  _current_exchange += 1
  _show_robot_response()

func _complete_current_dialogue() -> void:
  var did: String = _current_dialogue.get("id", "")
  if did != "" and _current_dialogue.get("once", false):
    _completed_dialogues.append(did)

  if did == "sutom_demande":
    state_sutom = SutomState.ROBOT_WORKING
    robot_state_sutom = RobotSutomState.HELPING
    if _robot != null and _sutom_node != null:
      _robot.go_to_position(_sutom_node.global_position)
    _sutom_timer.start(20.0)
  elif did == "sutom_resultat":
    state_sutom = SutomState.NEED_TRY_MACHINE
    robot_state_sutom = RobotSutomState.GAVE_UP

  _close_dialogue()

func _on_sutom_timer_timeout() -> void:
  state_sutom = SutomState.ROBOT_DONE
  if _robot != null:
    _robot.resume_follow()

func _close_dialogue() -> void:
  _in_dialogue = false
  _dialogue_panel.visible = false
  _choices_container.visible = true
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ── Interaction ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
  if _in_minigame:
    return

  if event.is_action_pressed("ui_cancel"):
    if _in_dialogue:
      _close_dialogue()
      return
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

  if not _in_dialogue and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
    rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
    camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
    camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

  if event.is_action_pressed("ui_accept") and not _in_dialogue:
    _try_interact()

func _try_interact() -> void:
  _interaction_ray.force_raycast_update()
  if not _interaction_ray.is_colliding():
    return

  var collider := _interaction_ray.get_collider()

  if collider.is_in_group("robot"):
    if state_sutom == SutomState.ROBOT_WORKING:
      _show_message("Le robot est en train de faire le SUTOM... je vais le laisser faire...", 3.0)
    else:
      _show_dialogue()
    return

  if collider.is_in_group("machines"):
    match collider.name:
      "SUTOM":        _interact_sutom(collider)
      "Oscilloscope": _interact_oscilloscope()
      "Tele":         _interact_tele()
      "Labyrinthe":   _interact_labyrinthe()
      "PC":           _interact_pc()
    return

  if not collider.is_in_group("objets"):
    return

  var obj_name: String = collider.name
  var can_pickup = puzzle_attempted.get(obj_name, false)
  if obj_name == "Dictionnaire" and state_sutom >= SutomState.NEEDS_DICTIONARY:
    can_pickup = true
  if can_pickup:
    _pickup(collider, obj_name)
  else:
    _show_message(OBJECT_MESSAGES.get(obj_name, "Hmm."))

func _interact_sutom(collider: Node) -> void:
  if _sutom_node == null:
    _sutom_node = collider
  match state_sutom:
    SutomState.IDLE, SutomState.FIRST_SEEN:
      state_sutom = SutomState.FIRST_SEEN
      puzzle_attempted["Dictionnaire"] = true
      _show_message("J'ai besoin d'aide... je vais en parler au robot.", 3.0)
    SutomState.ROBOT_WORKING:
      _show_message("Le robot est en train de faire le SUTOM... je vais le laisser faire...", 3.0)
    SutomState.ROBOT_DONE:
      _show_message("Je devrais d'abord parler au robot...", 2.0)
    SutomState.NEED_TRY_MACHINE, SutomState.NEEDS_DICTIONARY, SutomState.UNLOCKED:
      _open_sutom_minigame()
    SutomState.SOLVED:
      _show_message("Vous avez déjà résolu le SUTOM, ce n'est plus la peine !", 3.0)

func _interact_oscilloscope() -> void:
  if state_oscilloscope == OscilloscopeState.IDLE:
    state_oscilloscope = OscilloscopeState.ATTEMPTED
    _show_message("Cette machine a l'air compliquée.", 3.0)
  else:
    _use_machine("Oscilloscope")

func _interact_tele() -> void:
  if state_tele == TeleState.IDLE:
    state_tele = TeleState.CAPTCHA_PENDING
    puzzle_attempted["Feutres"] = true
    _show_message("Cette télé affiche quelque chose d'étrange.", 3.0)
  else:
    _use_machine("Tele")

func _interact_labyrinthe() -> void:
  if state_labyrinthe == LabyrinthState.IDLE:
    state_labyrinthe = LabyrinthState.ATTEMPTED
    puzzle_attempted["Fromage"] = true
    _show_message("Ce labyrinthe a l'air impossible...", 3.0)
  else:
    _use_machine("Labyrinthe")

func _interact_pc() -> void:
  if state_pc == PCState.IDLE:
    state_pc = PCState.ATTEMPTED
    puzzle_attempted["Joint"] = true
    _show_message("Ce PC semble en panne.", 3.0)
  else:
    _use_machine("PC")

func _open_sutom_minigame() -> void:
  _sutom_state_before_minigame = state_sutom
  _in_minigame = true
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  var game = _SutomMinigame.new()
  game.setup(state_sutom == SutomState.UNLOCKED)
  game.game_closed.connect(_on_sutom_minigame_closed)
  _canvas.add_child(game)

func _on_sutom_minigame_closed(won: bool) -> void:
  _in_minigame = false
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  if _sutom_state_before_minigame == SutomState.NEED_TRY_MACHINE:
    state_sutom = SutomState.NEEDS_DICTIONARY
  if won and state_sutom == SutomState.UNLOCKED:
    state_sutom = SutomState.SOLVED

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

  if not is_on_floor():
    velocity.y -= gravity * delta

  if not _in_dialogue and not _in_minigame:
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
