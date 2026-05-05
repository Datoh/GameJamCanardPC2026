extends CanvasLayer

signal started

@onready var _press_label: Label = %PressLabel

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  var tween := create_tween().set_loops()
  tween.tween_property(_press_label, "modulate:a", 0.0, 0.55)
  tween.tween_property(_press_label, "modulate:a", 1.0, 0.55)

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    get_viewport().set_input_as_handled()
    started.emit()
    queue_free()
