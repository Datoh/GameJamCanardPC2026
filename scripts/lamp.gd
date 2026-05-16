extends StaticBody3D

@export var light: Node = null

func _ready() -> void:
  add_to_group(GameData.GROUP_INTERACTIVE)
  set_collision_layer_value(4, true)

func interact() -> void:
  if light:
    AudioManager.play(AudioData.AUDIO_LAMP, global_position)
    light.visible = not light.visible

func get_interaction_hint() -> String:
  return tr("hintToggleLight")
