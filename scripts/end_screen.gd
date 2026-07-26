extends Control

signal ended

func _unhandled_input(event: InputEvent) -> void:
  if not visible:
    return
  var key_press: bool = event is InputEventKey and event.pressed and not event.echo
  var pad_press: bool = event is InputEventJoypadButton and event.pressed
  if key_press or pad_press:
    ended.emit()
