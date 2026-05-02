extends StaticBody3D

func interact(player: Node) -> void:
  match player.state_machine[MachineMaze.machine_name]:
    player.StateMachine.IDLE:
      player._show_message("Du fromage un peu raçi, je vaux mieux que ça.", 3.0)
    player.StateMachine.ATTEMPTED:
      player._show_message("Ca pourrait servir.", 3.0)
      player.pickup(self, "Fromage")
      queue_free()

func get_interaction_hint(player: Node) -> String:
  return "[ESPACE] Prendre le Fromage"
