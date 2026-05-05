extends Control
class_name OptionsMenu

signal closed

const BUS_MASTER := 0

@onready var _volume_slider: HSlider  = %VolumeSlider
@onready var _volume_value:  Label    = %VolumeValue
@onready var _dlss_check:    CheckBox = %DLSSCheck
@onready var _validate_btn:  Button   = %ValidateButton

func _ready() -> void:
  _volume_slider.value_changed.connect(_on_volume_changed)
  _validate_btn.pressed.connect(_on_validate_pressed)
  _dlss_check.toggled.connect(_on_dlss_toggled)
  _on_volume_changed(_volume_slider.value)

func _on_volume_changed(value: float) -> void:
  _volume_value.text = str(int(value))
  AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(value / 10.0))

func _on_dlss_toggled(enabled: bool) -> void:
  var robot := get_tree().get_first_node_in_group("robot")
  if not robot:
    return
  robot.set_skin_dlss5(DialoguesData.robot_name, enabled)

func _on_validate_pressed() -> void:
  hide()
  closed.emit()

func _unhandled_input(event: InputEvent) -> void:
  if not visible:
    return
  if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
    get_viewport().set_input_as_handled()
    hide()
    closed.emit()
