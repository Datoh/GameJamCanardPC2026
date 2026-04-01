extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENSITIVITY := 0.002

const OBJECT_MESSAGES: Dictionary = {
  "Dictionnaire": "Ce dictionnaire est plein de mots. Des vrais, j'espère.",
  "Fromage":      "Je ne vois pas à quoi pourrait me servir ce fromage.",
  "Joint":        "Ce joint m'a l'air artisanal. Je le garde pour plus tard.",
  "Feutres":      "Des feutres mordus par LN R3p14y. Il mâchouille tous les capuchons.",
}

# Chaque dialogue :
#   id       : identifiant unique
#   label    : texte affiché sur le bouton joueur
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
]

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
var _completed_dialogues: Array[String] = []
var _current_dialogue: Dictionary = {}
var _current_exchange: int = 0

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  _setup_raycast()
  _setup_ui()

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

# ── Dialogue ──────────────────────────────────────────────────────────────────

func _get_available_dialogues() -> Array[Dictionary]:
  var result: Array[Dictionary] = []
  for d in DIALOGUES:
    if d["id"] == "close":
      result.append(d)
      continue
    if d.get("once", false) and d["id"] in _completed_dialogues:
      continue
    var req: String = d.get("requires", "")
    if req != "" and req not in _completed_dialogues:
      continue
    result.append(d)
  return result

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
    # Proposer la réplique suivante du joueur comme unique bouton
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
  _close_dialogue()

func _close_dialogue() -> void:
  _in_dialogue = false
  _dialogue_panel.visible = false
  _choices_container.visible = true
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ── Interaction ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
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
    _show_dialogue()
    return

  if not collider.is_in_group("objets"):
    return

  var obj_name: String = collider.name
  if puzzle_attempted.get(obj_name, false):
    _pickup(collider, obj_name)
  else:
    _show_message(OBJECT_MESSAGES.get(obj_name, "Hmm."))

func _pickup(obj: Node, obj_name: String) -> void:
  inventory.append(obj_name)
  _show_message("Vous ramassez : %s." % obj_name.replace("_", " "), 2.0)
  obj.queue_free()

# ── Physique ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
  if _interaction_ray != null:
    if _interaction_ray.is_colliding():
      var c := _interaction_ray.get_collider()
      _debug_label.text = "RAY: %s %s" % [c.name, c.get_groups()]
    else:
      _debug_label.text = "RAY: rien"

  if not is_on_floor():
    velocity.y -= gravity * delta

  if not _in_dialogue:
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
