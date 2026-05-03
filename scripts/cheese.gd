extends StaticBody3D

func interact(player: Node) -> void:
  match player.state_machine[MachineMaze.NAME]:
    Machine.StateMachine.TRY_MACHINE_OBJECT:
      player.show_message("Ca pourrait servir.", 3.0)
      player.pickup(self, "Fromage", MachineMaze.NAME)
    _:
      player.show_message("Du fromage un peu raçi, je vaux mieux que ça.", 3.0)


func get_interaction_hint(_player: Node) -> String:
  return "[ESPACE] Prendre le Fromage"
