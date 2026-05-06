extends Control
class_name OptionsMenu

signal closed

const BUS_MASTER := 0

const RESOLUTIONS: Array[Vector2i] = [
  Vector2i(640,  360),
  Vector2i(854,  480),
  Vector2i(1024, 576),
  Vector2i(1280, 720),
  Vector2i(1366, 768),
  Vector2i(1600, 900),
  Vector2i(1920, 1080),
]

@onready var _volume_slider:     HSlider      = %VolumeSlider
@onready var _volume_value:      Label        = %VolumeValue
@onready var _dlss_check:        CheckBox     = %DLSSCheck
@onready var _sdfgi_check:       CheckBox     = %SDFGICheck
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _fullscreen_check:  CheckBox     = %FullscreenCheck
@onready var _validate_btn:      Button       = %ValidateButton

func _ready() -> void:
  _volume_slider.value_changed.connect(_on_volume_changed)
  _validate_btn.pressed.connect(_on_validate_pressed)
  _dlss_check.toggled.connect(_on_dlss_toggled)
  _sdfgi_check.toggled.connect(_on_sdfgi_toggled)
  _resolution_option.item_selected.connect(_on_resolution_selected)
  _fullscreen_check.toggled.connect(_on_fullscreen_toggled)

  _build_resolution_list()
  _detect_best_resolution()

  var mode := DisplayServer.window_get_mode()
  _fullscreen_check.set_pressed_no_signal(
    mode == DisplayServer.WINDOW_MODE_FULLSCREEN or
    mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
  )
  _resolution_option.disabled = _fullscreen_check.button_pressed

  _on_volume_changed(_volume_slider.value)

  var world_env := get_tree().root.find_child("WorldEnvironment", true, false)
  if world_env and world_env.environment:
    _sdfgi_check.set_pressed_no_signal(world_env.environment.sdfgi_enabled)

func _build_resolution_list() -> void:
  _resolution_option.clear()
  for res in RESOLUTIONS:
    _resolution_option.add_item("%d × %d" % [res.x, res.y])

func _detect_best_resolution() -> void:
  var default_res := Vector2i(1280, 720)
  var best_idx := RESOLUTIONS.find(default_res)
  if best_idx < 0:
    best_idx = 3
  _resolution_option.select(best_idx)
  var mode := DisplayServer.window_get_mode()
  if mode != DisplayServer.WINDOW_MODE_FULLSCREEN and mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
    _apply_resolution(best_idx)

func _apply_resolution(idx: int) -> void:
  var res  := RESOLUTIONS[idx]
  var mode := DisplayServer.window_get_mode()
  DisplayServer.window_set_size(res)
  if mode == DisplayServer.WINDOW_MODE_WINDOWED or mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
    var screen := DisplayServer.screen_get_size()
    DisplayServer.window_set_position((screen - res) / 2.0)

func _on_volume_changed(value: float) -> void:
  _volume_value.text = str(int(value))
  AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(value / 10.0))

func _on_dlss_toggled(enabled: bool) -> void:
  var robot := get_tree().get_first_node_in_group("robot")
  if not robot:
    return
  robot.set_skin_dlss5(DialoguesData.robot_name, enabled)

func _on_sdfgi_toggled(enabled: bool) -> void:
  var world_env := get_tree().get_first_node_in_group("world_environment")
  if not world_env:
    world_env = get_tree().root.find_child("WorldEnvironment", true, false)
  if world_env and world_env.environment:
    world_env.environment.sdfgi_enabled = enabled

func _on_resolution_selected(idx: int) -> void:
  _apply_resolution(idx)

func _on_fullscreen_toggled(enabled: bool) -> void:
  if enabled:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
  else:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    _apply_resolution(_resolution_option.selected)
  _resolution_option.disabled = enabled

func _on_validate_pressed() -> void:
  hide()
  closed.emit()

func reveal_dlss_option() -> void:
  _dlss_check.get_parent().visible = true

func _unhandled_input(event: InputEvent) -> void:
  if not visible:
    return
  if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
    get_viewport().set_input_as_handled()
    hide()
    closed.emit()
