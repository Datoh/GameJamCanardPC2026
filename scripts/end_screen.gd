extends CanvasLayer

func _ready() -> void:
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    get_tree().reload_current_scene()
