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
  add_to_group(GameData.GROUP_INTERACTIVE)
  set_collision_layer_value(4, true)

func interact() -> void:
  if GameData.player.can_interact(id, machine):
    GameData.show_message(message_ok, 3.0)
    if pickable:
      GameData.player.pickup(self, id, machine)
      AudioManager.play(sound_pick, global_position)
  else:
    GameData.show_message(message_ko, 3.0)

func get_interaction_hint() -> String:
  return hint
