extends Control

signal ended

func _unhandled_input(event: InputEvent) -> void:
  if visible and (event is InputEventKey and event.pressed and not event.echo):
    ended.emit()
