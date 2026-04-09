extends Panel

# UI et flow d'un dialogue avec LN R3p14y.
#
# Le joueur passe une liste pré-filtrée de dialogues disponibles via open().
# Le contrôleur affiche les boutons de choix, puis joue les échanges robot/
# joueur de l'entrée sélectionnée jusqu'au bout.
#
# Signaux :
#   dialogue_completed(id) — un dialogue a été joué jusqu'à la fin
#   closed()               — le panneau est fermé (choix "close" ou Échap)

signal dialogue_completed(dialogue_id: String)
signal closed

const CLOSE_ID := "close"

var _robot_label: Label
var _continue_btn: Button
var _choices_container: VBoxContainer

var _current_dialogue: Dictionary = {}
var _current_exchange: int = 0

func _ready() -> void:
  anchor_left   = 0.2
  anchor_right  = 0.8
  anchor_top    = 0.55
  anchor_bottom = 0.95
  visible = false
  _build_ui()

func _build_ui() -> void:
  var vbox := VBoxContainer.new()
  vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
  vbox.add_theme_constant_override("separation", 8)
  vbox.offset_left   =  14.0
  vbox.offset_right  = -14.0
  vbox.offset_top    =  14.0
  vbox.offset_bottom = -14.0
  add_child(vbox)

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

# Ouvre le panneau avec la liste des dialogues proposés au joueur.
func open(available: Array) -> void:
  visible = true
  _show_choices(available)

func close() -> void:
  visible = false
  closed.emit()

func is_open() -> bool:
  return visible

func _show_choices(available: Array) -> void:
  _robot_label.visible = false
  _continue_btn.visible = false
  _choices_container.visible = true
  _clear_choices()
  for d in available:
    var btn := Button.new()
    btn.text = d["label"]
    btn.pressed.connect(_on_choice_selected.bind(d))
    _choices_container.add_child(btn)

func _clear_choices() -> void:
  for child in _choices_container.get_children():
    child.queue_free()

func _on_choice_selected(dialogue: Dictionary) -> void:
  if dialogue["id"] == CLOSE_ID:
    close()
    return
  _current_dialogue = dialogue
  _current_exchange = 0
  _show_robot_response()

func _show_robot_response() -> void:
  var exchange: Dictionary = _current_dialogue["exchanges"][_current_exchange]
  _choices_container.visible = false
  _robot_label.text = "LN R3p14y : « %s »" % exchange["robot"]
  _robot_label.visible = true
  _continue_btn.visible = true

func _on_continue_pressed() -> void:
  var exchange: Dictionary = _current_dialogue["exchanges"][_current_exchange]
  if exchange.has("player"):
    _show_player_reply(exchange["player"])
  else:
    _finish_current_dialogue()

func _show_player_reply(text: String) -> void:
  _robot_label.visible = false
  _continue_btn.visible = false
  _clear_choices()
  var btn := Button.new()
  btn.text = text
  btn.pressed.connect(_advance_exchange)
  _choices_container.add_child(btn)
  _choices_container.visible = true

func _advance_exchange() -> void:
  _current_exchange += 1
  _show_robot_response()

func _finish_current_dialogue() -> void:
  var id: String = _current_dialogue.get("id", "")
  _current_dialogue = {}
  _current_exchange = 0
  dialogue_completed.emit(id)
  close()
