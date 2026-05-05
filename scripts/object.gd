extends StaticBody3D

@export var pickable := false
@export var notifiable := false
@export var id := ""
@export_enum("null", MachineSutom.NAME, MachineTV.NAME, MachineOrdinateur.NAME, MachineMaze.NAME) var machine: String = ""
@export var message_ko := ""
@export var message_ok := ""
@export var hint := ""
@export var sound_pick: AudioStream = null

func _ready() -> void:
  add_to_group("interactive")
  set_collision_layer_value(4, true)

func interact(player: Node) -> void:
  if player.can_interact(id, machine):
    player.show_message(message_ok, 3.0)
    if pickable:
      player.pickup(self, id, machine)
      AudioManager.play(sound_pick, global_position)
  else:
    player.show_message(message_ko, 3.0)

func _play_sound_pick():
  return

func get_interaction_hint(_player: Node) -> String:
  return hint
