extends Panel

# UI et flow d'un dialogue.
#
# Signaux :
#   dialogue_completed(id) — un dialogue a été joué jusqu'à la fin
#   closed()               — le panneau est fermé (choix "close" ou Échap)

signal dialogue_completed(dialogue_id: String)
signal closed
signal robot_started_talking
signal robot_stopped_talking
signal branch_chosen(action: String)

const CLOSE_ID := "close"

const COLOR_PLAYER := Color(0.33, 0.60, 1.00)
const COLOR_ROBOT  := Color(0.20, 0.80, 0.35)
const COLOR_IVAN   := Color(0.85, 0.22, 0.22)

var _speaker_label: RichTextLabel
var _text_label: Label
var _continue_btn: Button
var _choices_container: VBoxContainer

var _current_dialogue: Dictionary = {}
var _current_exchange: int = 0
var _waiting_player_advance: bool = false

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
  vbox.add_theme_constant_override("separation", 6)
  vbox.offset_left   =  14.0
  vbox.offset_right  = -14.0
  vbox.offset_top    =  14.0
  vbox.offset_bottom = -14.0
  add_child(vbox)

  _speaker_label = RichTextLabel.new()
  _speaker_label.bbcode_enabled = true
  _speaker_label.fit_content = true
  _speaker_label.scroll_active = false
  _speaker_label.add_theme_font_size_override("normal_font_size", 18)
  _speaker_label.add_theme_font_size_override("bold_font_size", 18)
  _speaker_label.visible = false
  vbox.add_child(_speaker_label)

  _text_label = Label.new()
  _text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _text_label.visible = false
  vbox.add_child(_text_label)

  var spacer := Control.new()
  spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
  vbox.add_child(spacer)

  _continue_btn = Button.new()
  _continue_btn.text = "Continuer"
  _continue_btn.visible = false
  _continue_btn.pressed.connect(_on_continue_pressed)
  vbox.add_child(_continue_btn)

  _choices_container = VBoxContainer.new()
  _choices_container.add_theme_constant_override("separation", 6)
  vbox.add_child(_choices_container)


# ── Ouverture ─────────────────────────────────────────────────────────────────

func open(available: Array) -> void:
  visible = true
  _show_choices(available)

func open_direct(dialogue: Dictionary) -> void:
  visible = true
  _current_dialogue = dialogue
  _current_exchange = 0
  _waiting_player_advance = false
  _show_npc_line()

func close() -> void:
  visible = false
  robot_stopped_talking.emit()
  closed.emit()

func is_open() -> bool:
  return visible

func _unhandled_input(event: InputEvent) -> void:
  if not visible:
    return
  if not event.is_action_pressed("ui_accept"):
    return
  if _continue_btn.visible:
    get_viewport().set_input_as_handled()
    _on_continue_pressed()
  elif _choices_container.visible and _choices_container.get_child_count() == 1:
    get_viewport().set_input_as_handled()
    (_choices_container.get_child(0) as Button).emit_signal("pressed")


# ── Choix ─────────────────────────────────────────────────────────────────────

func _show_choices(available: Array) -> void:
  _speaker_label.visible = false
  _text_label.visible    = false
  _continue_btn.visible  = false
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
  _waiting_player_advance = false
  _show_npc_line()

func _on_branch_selected(action: String) -> void:
  _clear_choices()
  _choices_container.visible = false
  branch_chosen.emit(action)
  _current_exchange += 1
  if _current_exchange < _current_dialogue["exchanges"].size():
    _show_npc_line()
  else:
    _finish_current_dialogue()


# ── Échanges ──────────────────────────────────────────────────────────────────

func _show_npc_line() -> void:
  var exchange: Dictionary = _current_dialogue["exchanges"][_current_exchange]
  var speaker: String = exchange.get("speaker", _current_dialogue.get("speaker", DialoguesData.robot_name))
  _choices_container.visible = false
  _set_speaker(speaker)
  _text_label.text    = "« %s »" % exchange["robot"]
  _text_label.visible = true
  if speaker == "Ivan Gaudé":
    robot_stopped_talking.emit()
  else:
    robot_started_talking.emit()
  if exchange.has("branches"):
    _continue_btn.visible = false
    _clear_choices()
    for branch in exchange["branches"]:
      var btn := Button.new()
      btn.text = branch["label"]
      btn.pressed.connect(_on_branch_selected.bind(branch["action"]))
      _choices_container.add_child(btn)
    _choices_container.visible = true
  else:
    _continue_btn.text    = "Continuer"
    _continue_btn.visible = true

func _show_player_line(text: String) -> void:
  _waiting_player_advance = true
  _set_speaker("Moi")
  _text_label.text      = "« %s »" % text
  _text_label.visible   = true
  _continue_btn.text    = "Continuer"
  _continue_btn.visible = true
  _choices_container.visible = false
  robot_stopped_talking.emit()

func _on_continue_pressed() -> void:
  if _waiting_player_advance:
    _waiting_player_advance = false
    _current_exchange += 1
    _show_npc_line()
    return
  var exchange: Dictionary = _current_dialogue["exchanges"][_current_exchange]
  if exchange.has("player"):
    _show_player_line(exchange["player"])
  else:
    _finish_current_dialogue()

func _finish_current_dialogue() -> void:
  var id: String = _current_dialogue.get("id", "")
  _current_dialogue = {}
  _current_exchange = 0
  _waiting_player_advance = false
  dialogue_completed.emit(id)
  close()


# ── Couleurs ──────────────────────────────────────────────────────────────────

func _set_speaker(speaker_name: String) -> void:
  var col: Color
  match speaker_name:
    "Moi":        col = COLOR_PLAYER
    "Ivan Gaudé": col = COLOR_IVAN
    _:            col = COLOR_ROBOT
  _speaker_label.parse_bbcode("[b][color=#%s]%s[/color][/b]" % [col.to_html(false), speaker_name])
  _speaker_label.visible = true
