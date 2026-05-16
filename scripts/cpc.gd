extends StaticBody3D

@export var id := 0
@export var message := ""
@export var hint_look := ""
@export var hint_take := ""
@export var sound_pick: AudioStream = null

var _looked := false

func _ready() -> void:
  add_to_group(GameData.GROUP_INTERACTIVE)
  add_to_group(GameData.GROUP_CPC)
  set_collision_layer_value(4, true)

func interact() -> void:
  if not _looked:
    _looked = true
    GameData.show_message(message, 3.0)
  else:
    GameData.player.collect_cpc(id)
    GameData.show_message(tr("msgCpcFound") % id, 2.0)
    AudioManager.play(sound_pick, global_position)
    queue_free()

func get_interaction_hint() -> String:
  return hint_look if not _looked else hint_take
