extends CanvasLayer

signal started
signal options_requested

@onready var _new_game_btn: Button = %NewGameButton
@onready var _options_btn:  Button = %OptionsButton
@onready var _quit_btn:     Button = %QuitButton

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  _new_game_btn.pressed.connect(_on_new_game_pressed)
  _options_btn.pressed.connect(_on_options_pressed)
  _quit_btn.pressed.connect(get_tree().quit)
  _new_game_btn.grab_focus()

func _on_new_game_pressed() -> void:
  started.emit()
  queue_free()

func _on_options_pressed() -> void:
  options_requested.emit()
