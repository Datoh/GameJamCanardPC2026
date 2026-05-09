extends StaticBody3D

@export var id := 0
@export var message := ""
@export var hint_look := ""
@export var hint_take := ""
@export var sound_pick: AudioStream = null

var _looked := false

func _ready() -> void:
  add_to_group("interactive")
  set_collision_layer_value(4, true)

func interact(player: Node) -> void:
  if not _looked:
    _looked = true
    player.show_message(message, 3.0)
  else:
    player.collect_cpc(id)
    player.show_message("Vous avez trouvé le Canard PC %d." % id, 2.0)
    AudioManager.play(sound_pick, global_position)
    queue_free()

func get_interaction_hint(_player: Node) -> String:
  return hint_look if not _looked else hint_take
